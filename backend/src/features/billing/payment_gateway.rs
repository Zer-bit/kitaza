use hmac::{Hmac, KeyInit, Mac};
use serde_json::{Value, json};
use sha2::Sha256;
use uuid::Uuid;

use crate::config::{BillingMode, BillingSettings};
use crate::shared::{ApiError, ApiResult};

use super::plan::Plan;

const PAYMONGO_CHECKOUT: &str = "https://api.paymongo.com/v1/checkout_sessions";

/// GCash and Maya first: they are how this market pays. Cards are accepted
/// for the owners who have one.
const PAYMENT_METHODS: [&str; 3] = ["gcash", "paymaya", "card"];

pub struct CheckoutRequest {
    pub payment_id: Uuid,
    pub plan: Plan,
    pub months: u32,
    pub amount_centavos: i64,
}

pub struct Checkout {
    /// The gateway's id for this checkout, which its webhook quotes back.
    pub reference: String,
    /// Where the owner's phone opens to pay.
    pub url: String,
}

/// A checkout the gateway says was paid.
#[derive(Debug, PartialEq, Eq)]
pub struct PaidCheckout {
    pub reference: String,
    pub method: Option<String>,
}

/// Takes the money. An enum rather than a trait object: there are two, and
/// neither needs to be swapped at runtime.
#[derive(Clone)]
pub enum PaymentGateway {
    /// Checkout is a page on this server. Nothing is charged.
    Test {
        public_url: String,
    },
    PayMongo(PayMongoGateway),
}

impl PaymentGateway {
    /// None when billing is off.
    pub fn from_settings(settings: &BillingSettings) -> Option<Self> {
        match &settings.mode {
            BillingMode::Off => None,
            BillingMode::Test => Some(PaymentGateway::Test {
                public_url: settings.public_url.clone(),
            }),
            BillingMode::PayMongo {
                secret_key,
                webhook_secret,
            } => Some(PaymentGateway::PayMongo(PayMongoGateway::new(
                secret_key.clone(),
                webhook_secret.clone(),
                settings.public_url.clone(),
            ))),
        }
    }

    pub async fn create_checkout(&self, request: &CheckoutRequest) -> ApiResult<Checkout> {
        match self {
            PaymentGateway::Test { public_url } => Ok(Checkout {
                reference: format!("test_{}", request.payment_id),
                url: format!("{public_url}/billing/test-checkout/{}", request.payment_id),
            }),
            PaymentGateway::PayMongo(gateway) => gateway.create_checkout(request).await,
        }
    }
}

#[derive(Clone)]
pub struct PayMongoGateway {
    client: reqwest::Client,
    secret_key: String,
    webhook_secret: String,
    public_url: String,
}

impl PayMongoGateway {
    pub fn new(secret_key: String, webhook_secret: String, public_url: String) -> Self {
        // The server links rustls with the `ring` backend already (through
        // sqlx); using it here too avoids a second crypto library and its
        // native build step.
        let _ = rustls::crypto::ring::default_provider().install_default();
        Self {
            client: reqwest::Client::new(),
            secret_key,
            webhook_secret,
            public_url,
        }
    }

    async fn create_checkout(&self, request: &CheckoutRequest) -> ApiResult<Checkout> {
        let response = self
            .client
            .post(PAYMONGO_CHECKOUT)
            .basic_auth(&self.secret_key, Some(""))
            .json(&checkout_body(request, &self.public_url))
            .send()
            .await
            .map_err(|error| ApiError::Internal(error.into()))?;

        let status = response.status();
        let body: Value = response
            .json()
            .await
            .map_err(|error| ApiError::Internal(error.into()))?;
        if !status.is_success() {
            return Err(ApiError::Internal(anyhow::anyhow!(
                "paymongo refused the checkout ({status}): {body}"
            )));
        }

        let reference = body["data"]["id"].as_str();
        let url = body["data"]["attributes"]["checkout_url"].as_str();
        match (reference, url) {
            (Some(reference), Some(url)) => Ok(Checkout {
                reference: reference.to_owned(),
                url: url.to_owned(),
            }),
            _ => Err(ApiError::Internal(anyhow::anyhow!(
                "unexpected paymongo checkout response: {body}"
            ))),
        }
    }

    /// Checks a webhook really came from PayMongo, and says which checkout
    /// it reports paid. Other events are verified and then ignored.
    pub fn verify_webhook(
        &self,
        signature_header: &str,
        raw_body: &[u8],
    ) -> ApiResult<Option<PaidCheckout>> {
        verify_signature(&self.webhook_secret, signature_header, raw_body)?;

        let event: Value = serde_json::from_slice(raw_body)
            .map_err(|_| ApiError::BadRequest("webhook body is not JSON".into()))?;
        let attributes = &event["data"]["attributes"];
        if attributes["type"] != "checkout_session.payment.paid" {
            return Ok(None);
        }

        let checkout = &attributes["data"];
        let reference = checkout["id"]
            .as_str()
            .ok_or_else(|| ApiError::BadRequest("paid event names no checkout".into()))?;
        let method = checkout["attributes"]["payment_method_used"]
            .as_str()
            .map(str::to_owned);

        Ok(Some(PaidCheckout {
            reference: reference.to_owned(),
            method,
        }))
    }
}

pub fn checkout_body(request: &CheckoutRequest, public_url: &str) -> Value {
    let period = if request.months == 12 {
        "1 year"
    } else {
        "1 month"
    };
    json!({
        "data": { "attributes": {
            "line_items": [{
                "name": format!("{}, {period}", request.plan.label()),
                "amount": request.amount_centavos,
                "currency": "PHP",
                "quantity": 1,
            }],
            "payment_method_types": PAYMENT_METHODS,
            "description": format!("{}, {period}", request.plan.label()),
            "reference_number": request.payment_id.to_string(),
            "success_url": format!("{public_url}/billing/return?paid=1"),
            "cancel_url": format!("{public_url}/billing/return"),
            "metadata": { "payment_id": request.payment_id.to_string() },
        }}
    })
}

/// `Paymongo-Signature: t=<unix time>,te=<test mode hex>,li=<live mode hex>`
/// signs `<t>.<raw body>` with the webhook's secret. Only one of `te` and
/// `li` is filled in, depending on the mode the event came from.
///
/// The timestamp's age is not checked: acting on a paid event twice changes
/// nothing, so a replay gains an attacker nothing.
fn verify_signature(secret: &str, header: &str, raw_body: &[u8]) -> ApiResult<()> {
    let field = |name: &str| {
        header
            .split(',')
            .filter_map(|part| part.trim().split_once('='))
            .find(|(key, _)| *key == name)
            .map(|(_, value)| value)
            .filter(|value| !value.is_empty())
    };
    let refused = || ApiError::Unauthorized("webhook signature does not match".into());

    let timestamp = field("t").ok_or_else(refused)?;
    let expected = field("li").or_else(|| field("te")).ok_or_else(refused)?;
    let expected = hex::decode(expected).map_err(|_| refused())?;

    let mut mac = Hmac::<Sha256>::new_from_slice(secret.as_bytes()).map_err(|_| refused())?;
    mac.update(timestamp.as_bytes());
    mac.update(b".");
    mac.update(raw_body);
    mac.verify_slice(&expected).map_err(|_| refused())
}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: &str = "whsk_test_secret";

    fn signed(body: &str, field: &str) -> String {
        let mut mac = Hmac::<Sha256>::new_from_slice(SECRET.as_bytes()).unwrap();
        mac.update(format!("1700000000.{body}").as_bytes());
        let signature = hex::encode(mac.finalize().into_bytes());
        match field {
            "li" => format!("t=1700000000,te=,li={signature}"),
            _ => format!("t=1700000000,te={signature},li="),
        }
    }

    fn gateway() -> PayMongoGateway {
        PayMongoGateway::new(
            "sk_test".into(),
            SECRET.into(),
            "https://kitaza.test".into(),
        )
    }

    fn paid_event() -> String {
        json!({ "data": { "id": "evt_1", "attributes": {
            "type": "checkout_session.payment.paid",
            "livemode": false,
            "data": { "id": "cs_123", "attributes": { "payment_method_used": "gcash" } },
        }}})
        .to_string()
    }

    #[test]
    fn a_correctly_signed_paid_event_names_its_checkout() {
        let body = paid_event();
        let paid = gateway()
            .verify_webhook(&signed(&body, "te"), body.as_bytes())
            .unwrap();

        assert_eq!(
            paid,
            Some(PaidCheckout {
                reference: "cs_123".into(),
                method: Some("gcash".into()),
            })
        );
    }

    #[test]
    fn live_mode_signatures_are_accepted_too() {
        let body = paid_event();
        assert!(
            gateway()
                .verify_webhook(&signed(&body, "li"), body.as_bytes())
                .is_ok()
        );
    }

    #[test]
    fn a_forged_or_altered_event_is_refused() {
        let body = paid_event();
        let header = signed(&body, "te");
        let altered = body.replace("cs_123", "cs_999");

        assert!(
            gateway()
                .verify_webhook(&header, altered.as_bytes())
                .is_err()
        );
        assert!(
            gateway()
                .verify_webhook("t=1700000000,te=deadbeef", body.as_bytes())
                .is_err()
        );
        assert!(gateway().verify_webhook("", body.as_bytes()).is_err());
    }

    #[test]
    fn other_events_are_acknowledged_and_ignored() {
        let body = json!({ "data": { "attributes": { "type": "payment.failed" } } }).to_string();
        let paid = gateway()
            .verify_webhook(&signed(&body, "te"), body.as_bytes())
            .unwrap();
        assert_eq!(paid, None);
    }

    #[test]
    fn a_checkout_offers_gcash_and_maya_at_the_plan_price() {
        let body = checkout_body(
            &CheckoutRequest {
                payment_id: Uuid::nil(),
                plan: Plan::Pro,
                months: 12,
                amount_centavos: Plan::Pro.price_centavos(12),
            },
            "https://kitaza.test",
        );
        let attributes = &body["data"]["attributes"];

        assert_eq!(attributes["line_items"][0]["amount"], 199_000);
        assert_eq!(attributes["line_items"][0]["currency"], "PHP");
        assert_eq!(attributes["line_items"][0]["name"], "Kitaza Pro, 1 year");
        assert_eq!(
            attributes["payment_method_types"],
            json!(["gcash", "paymaya", "card"])
        );
        assert_eq!(attributes["reference_number"], Uuid::nil().to_string());
        assert_eq!(
            attributes["success_url"],
            "https://kitaza.test/billing/return?paid=1"
        );
    }
}
