CREATE TABLE products (
    id             UUID PRIMARY KEY,
    store_id       UUID          NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    name           TEXT          NOT NULL,
    barcode        TEXT,
    unit_label     TEXT          NOT NULL DEFAULT 'pc',
    cost_price     NUMERIC(14,2) NOT NULL DEFAULT 0,
    selling_price  NUMERIC(14,2) NOT NULL DEFAULT 0,
    stock_quantity NUMERIC(14,3) NOT NULL DEFAULT 0,
    reorder_level  NUMERIC(14,3) NOT NULL DEFAULT 0,
    is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at     TIMESTAMPTZ
);

CREATE INDEX products_store_updated_idx ON products (store_id, updated_at);
CREATE INDEX products_store_active_idx ON products (store_id, is_active) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX products_store_barcode_unique ON products (store_id, barcode) WHERE barcode IS NOT NULL;

CREATE TABLE stock_movements (
    id          UUID PRIMARY KEY,
    store_id    UUID          NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    product_id  UUID          NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    movement    TEXT          NOT NULL,
    quantity    NUMERIC(14,3) NOT NULL,
    unit_cost   NUMERIC(14,2) NOT NULL DEFAULT 0,
    note        TEXT,
    occurred_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ,
    CONSTRAINT stock_movements_movement_check
        CHECK (movement IN ('stock_in', 'stock_out', 'sale', 'adjustment', 'spoilage'))
);

CREATE INDEX stock_movements_store_updated_idx ON stock_movements (store_id, updated_at);
CREATE INDEX stock_movements_product_idx ON stock_movements (product_id, occurred_at DESC);
