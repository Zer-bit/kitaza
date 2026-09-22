CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE owners (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT        NOT NULL,
    password_hash TEXT        NOT NULL,
    full_name     TEXT        NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Emails are stored lower-cased by the application; the index enforces that contract.
CREATE UNIQUE INDEX owners_email_unique ON owners (lower(email));

CREATE TABLE stores (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id      UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    name          TEXT        NOT NULL,
    business_type TEXT        NOT NULL DEFAULT 'sari_sari',
    currency_code TEXT        NOT NULL DEFAULT 'PHP',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX stores_owner_id_idx ON stores (owner_id);

CREATE TABLE refresh_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id   UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    token_hash TEXT        NOT NULL UNIQUE,
    device_tag TEXT        NOT NULL DEFAULT 'unknown',
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX refresh_tokens_owner_id_idx ON refresh_tokens (owner_id);
