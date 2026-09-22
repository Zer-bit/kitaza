use chrono::Utc;
use uuid::Uuid;

use crate::features::products::ProductRepository;
use crate::infrastructure::cache::DashboardCache;
use crate::infrastructure::realtime::{EventBroadcaster, RealtimeEvent, RealtimeTopic};
use crate::shared::{
    ApiError, ApiResult, Money, PageRequest, money_from_f64, money_zero, quantity_from_f64,
};

use super::sale_payloads::{RecordSaleRequest, SaleDetail, SaleFilter, SaleLineRequest, SaleView};
use super::sale_repository::{PreparedLine, PreparedSale, SaleRepository};

const ALLOWED_PAYMENT_METHODS: [&str; 5] = ["cash", "gcash", "maya", "bank_transfer", "utang"];
const QUICK_SALE_LABEL: &str = "Quick sale";

#[derive(Clone)]
pub struct SaleService {
    sales: SaleRepository,
    products: ProductRepository,
    cache: DashboardCache,
    broadcaster: EventBroadcaster,
}

impl SaleService {
    pub fn new(
        sales: SaleRepository,
        products: ProductRepository,
        cache: DashboardCache,
        broadcaster: EventBroadcaster,
    ) -> Self {
        Self {
            sales,
            products,
            cache,
            broadcaster,
        }
    }

    pub async fn record(
        &self,
        store_id: Uuid,
        request: RecordSaleRequest,
    ) -> ApiResult<SaleDetail> {
        let payment_method = normalise_payment_method(request.payment_method.as_deref())?;
        let sale_id = request.id.unwrap_or_else(Uuid::new_v4);

        let mut lines = Vec::with_capacity(request.items.len());
        let mut gross = money_zero();
        let mut cost = money_zero();

        for item in &request.items {
            let line = self.resolve_line(store_id, item).await?;
            gross += line.line_total;
            cost += line.unit_cost * line.quantity;
            lines.push(line);
        }

        let discount = money_from_f64(request.discount_amount).min(gross);
        let total = gross - discount;

        let prepared = PreparedSale {
            id: sale_id,
            store_id,
            payment_method,
            total_amount: total,
            cost_amount: cost,
            discount_amount: discount,
            note: request
                .note
                .map(|note| note.trim().to_owned())
                .filter(|n| !n.is_empty()),
            occurred_at: request.occurred_at.unwrap_or_else(Utc::now),
            lines,
        };

        let stored = self.sales.record(prepared).await?;
        let items = self.sales.lines_for(stored.id).await?;

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::SaleRecorded,
                Some(stored.id),
            ))
            .await;
        self.announce_low_stock(store_id).await;

        Ok(SaleDetail::new(stored, items))
    }

    pub async fn list(
        &self,
        store_id: Uuid,
        filter: SaleFilter,
        page: PageRequest,
    ) -> ApiResult<Vec<SaleView>> {
        self.sales.list(store_id, &filter, page).await
    }

    pub async fn detail(&self, store_id: Uuid, sale_id: Uuid) -> ApiResult<SaleDetail> {
        let sale = self
            .sales
            .find(store_id, sale_id)
            .await?
            .ok_or(ApiError::NotFound("sale"))?;
        let items = self.sales.lines_for(sale_id).await?;

        Ok(SaleDetail::new(sale, items))
    }

    pub async fn void(&self, store_id: Uuid, sale_id: Uuid) -> ApiResult<()> {
        if !self.sales.void(store_id, sale_id).await? {
            return Err(ApiError::NotFound("sale"));
        }

        self.cache.invalidate_store(store_id).await;
        self.broadcaster
            .publish(RealtimeEvent::new(
                store_id,
                RealtimeTopic::SaleVoided,
                Some(sale_id),
            ))
            .await;

        Ok(())
    }

    /// Prices come from the catalogue unless the client overrides them, so a
    /// cashier tapping a product never has to retype the price.
    async fn resolve_line(
        &self,
        store_id: Uuid,
        item: &SaleLineRequest,
    ) -> ApiResult<PreparedLine> {
        let quantity = quantity_from_f64(item.quantity);

        let (name, unit_price, unit_cost) = match item.product_id {
            Some(product_id) => {
                let product = self
                    .products
                    .find(store_id, product_id)
                    .await?
                    .ok_or(ApiError::NotFound("product"))?;

                (
                    product.name.clone(),
                    item.unit_price
                        .map(money_from_f64)
                        .unwrap_or(product.selling_price),
                    item.unit_cost
                        .map(money_from_f64)
                        .unwrap_or(product.cost_price),
                )
            }
            None => {
                let price = item
                    .unit_price
                    .map(money_from_f64)
                    .ok_or_else(|| ApiError::BadRequest("a quick sale needs an amount".into()))?;

                (
                    item.product_name
                        .as_deref()
                        .map(str::trim)
                        .filter(|name| !name.is_empty())
                        .unwrap_or(QUICK_SALE_LABEL)
                        .to_owned(),
                    price,
                    item.unit_cost
                        .map(money_from_f64)
                        .unwrap_or_else(money_zero),
                )
            }
        };

        Ok(PreparedLine {
            id: Uuid::new_v4(),
            product_id: item.product_id,
            product_name: name,
            quantity,
            unit_price,
            unit_cost,
            line_total: round_money(unit_price * quantity),
        })
    }

    async fn announce_low_stock(&self, store_id: Uuid) {
        let Ok(low) = self.products.list_low_stock(store_id).await else {
            return;
        };
        if low.is_empty() {
            return;
        }

        let names: Vec<&str> = low.iter().take(3).map(|p| p.name.as_str()).collect();
        self.broadcaster
            .publish(
                RealtimeEvent::new(store_id, RealtimeTopic::StockLow, None)
                    .with_message(format!("Running low: {}", names.join(", "))),
            )
            .await;
    }
}

fn round_money(value: Money) -> Money {
    value.round_dp(2)
}

fn normalise_payment_method(raw: Option<&str>) -> ApiResult<String> {
    let method = raw
        .map(str::trim)
        .filter(|m| !m.is_empty())
        .unwrap_or("cash")
        .to_lowercase();

    if !ALLOWED_PAYMENT_METHODS.contains(&method.as_str()) {
        return Err(ApiError::BadRequest(format!(
            "unsupported payment method '{method}'"
        )));
    }

    Ok(method)
}
