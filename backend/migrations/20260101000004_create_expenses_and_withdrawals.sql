CREATE TABLE expenses (
    id          UUID PRIMARY KEY,
    store_id    UUID          NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    category    TEXT          NOT NULL,
    description TEXT,
    amount      NUMERIC(14,2) NOT NULL,
    occurred_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ,
    CONSTRAINT expenses_category_check CHECK (category IN (
        'inventory', 'utilities', 'salary', 'transportation',
        'rent', 'supplies', 'repairs', 'taxes_permits', 'other'
    ))
);

CREATE INDEX expenses_store_occurred_idx ON expenses (store_id, occurred_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX expenses_store_updated_idx ON expenses (store_id, updated_at);

CREATE TABLE owner_withdrawals (
    id          UUID PRIMARY KEY,
    store_id    UUID          NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    amount      NUMERIC(14,2) NOT NULL,
    reason      TEXT,
    occurred_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX owner_withdrawals_store_occurred_idx
    ON owner_withdrawals (store_id, occurred_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX owner_withdrawals_store_updated_idx ON owner_withdrawals (store_id, updated_at);
