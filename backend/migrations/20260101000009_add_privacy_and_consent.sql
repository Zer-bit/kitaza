-- What each owner agreed to, and when. The Data Privacy Act asks a controller
-- to be able to show that consent was given for a specific thing; a version
-- and a timestamp is that evidence.
CREATE TABLE consent_records (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id  UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    document  TEXT        NOT NULL,
    version   TEXT        NOT NULL,
    agreed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT consent_records_document_check
        CHECK (document IN ('privacy_notice', 'terms'))
);

CREATE INDEX consent_records_owner_idx
    ON consent_records (owner_id, document, agreed_at DESC);

-- A deletion the owner asked for, and the moment it stops being reversible.
-- Erasure is a right, but a mis-tap that wipes a year of books on the spot
-- would be its own disaster, so it is asked for now and done later.
ALTER TABLE owners
    ADD COLUMN deletion_requested_at TIMESTAMPTZ,
    ADD COLUMN delete_after          TIMESTAMPTZ;

CREATE INDEX owners_awaiting_deletion_idx
    ON owners (delete_after) WHERE delete_after IS NOT NULL;

-- What outlives a purge: the money, with nobody attached to it. A business
-- has to be able to account for payments it received, and this names no
-- person - the gateway holds the record that does.
CREATE TABLE accounting_records (
    id                 UUID PRIMARY KEY,
    plan               TEXT          NOT NULL,
    months             INTEGER       NOT NULL,
    amount             NUMERIC(10,2) NOT NULL,
    currency           TEXT          NOT NULL,
    provider           TEXT          NOT NULL,
    provider_reference TEXT,
    paid_at            TIMESTAMPTZ,
    retained_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX accounting_records_paid_idx ON accounting_records (paid_at);
