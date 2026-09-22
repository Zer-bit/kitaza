CREATE TABLE sales (
    id              UUID PRIMARY KEY,
    store_id        UUID          NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    reference       TEXT,
    payment_method  TEXT          NOT NULL DEFAULT 'cash',
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    cost_amount     NUMERIC(14,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    note            TEXT,
    occurred_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ,
    CONSTRAINT sales_payment_method_check
        CHECK (payment_method IN ('cash', 'gcash', 'maya', 'bank_transfer', 'utang'))
);

CREATE INDEX sales_store_occurred_idx ON sales (store_id, occurred_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX sales_store_updated_idx ON sales (store_id, updated_at);

CREATE TABLE sale_items (
    id           UUID PRIMARY KEY,
    sale_id      UUID          NOT NULL REFERENCES sales (id) ON DELETE CASCADE,
    product_id   UUID REFERENCES products (id) ON DELETE SET NULL,
    product_name TEXT          NOT NULL,
    quantity     NUMERIC(14,3) NOT NULL,
    unit_price   NUMERIC(14,2) NOT NULL,
    unit_cost    NUMERIC(14,2) NOT NULL DEFAULT 0,
    line_total   NUMERIC(14,2) NOT NULL
);

CREATE INDEX sale_items_sale_id_idx ON sale_items (sale_id);
CREATE INDEX sale_items_product_id_idx ON sale_items (product_id);
