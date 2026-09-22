-- One row per owner. Staff are covered by their owner's subscription.
CREATE TABLE subscriptions (
    owner_id      UUID PRIMARY KEY REFERENCES owners (id) ON DELETE CASCADE,
    -- The plan last paid for. A trial is always Pro, whatever this says.
    plan          TEXT        NOT NULL DEFAULT 'pro',
    trial_ends_at TIMESTAMPTZ,
    paid_through  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT subscriptions_plan_check CHECK (plan IN ('basic', 'pro'))
);

-- Everyone already using the cloud starts a trial today, so nobody is cut
-- off by the release that introduces paying.
INSERT INTO subscriptions (owner_id, plan, trial_ends_at)
SELECT id, 'pro', now() + INTERVAL '30 days' FROM owners;

-- Prepaid periods, not recurring charges: GCash and Maya payments through a
-- gateway are one-off, and owners here are used to paying ahead.
CREATE TABLE payments (
    id                 UUID PRIMARY KEY,
    owner_id           UUID          NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    plan               TEXT          NOT NULL,
    months             INTEGER       NOT NULL,
    amount             NUMERIC(10,2) NOT NULL,
    currency           TEXT          NOT NULL DEFAULT 'PHP',
    provider           TEXT          NOT NULL,
    provider_reference TEXT UNIQUE,
    status             TEXT          NOT NULL DEFAULT 'pending',
    method             TEXT,
    -- What this payment extended the subscription to, for the receipt.
    paid_through       TIMESTAMPTZ,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    paid_at            TIMESTAMPTZ,
    CONSTRAINT payments_plan_check CHECK (plan IN ('basic', 'pro')),
    CONSTRAINT payments_months_check CHECK (months IN (1, 12)),
    CONSTRAINT payments_status_check CHECK (status IN ('pending', 'paid'))
);

CREATE INDEX payments_owner_idx ON payments (owner_id, created_at DESC);
