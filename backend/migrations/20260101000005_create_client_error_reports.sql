-- Errors reported by the app, for the team to find and fix. Holds no business
-- data: an error's type, message and stack, and where it happened.
CREATE TABLE client_error_reports (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    fingerprint TEXT        NOT NULL,
    error_type  TEXT        NOT NULL,
    message     TEXT        NOT NULL,
    stack       TEXT,
    occurrences BIGINT      NOT NULL DEFAULT 1,
    first_seen  TIMESTAMPTZ NOT NULL,
    last_seen   TIMESTAMPTZ NOT NULL,
    app_version TEXT        NOT NULL,
    platform    TEXT        NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per distinct error per owner per build; repeats add to the count.
CREATE UNIQUE INDEX client_error_reports_identity
    ON client_error_reports (owner_id, fingerprint, app_version);

-- "What is breaking most in this release?" and the 90-day clean-up.
CREATE INDEX client_error_reports_by_fingerprint ON client_error_reports (fingerprint, app_version);
CREATE INDEX client_error_reports_last_seen ON client_error_reports (last_seen);
