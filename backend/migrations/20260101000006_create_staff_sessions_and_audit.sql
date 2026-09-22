-- Staff: people an owner lets use a store without sharing the owner's
-- account. They sign in with a one-time join code, never a password.
CREATE TABLE staff_members (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id            UUID        NOT NULL REFERENCES stores (id) ON DELETE CASCADE,
    display_name        TEXT        NOT NULL,
    can_manage_products BOOLEAN     NOT NULL DEFAULT FALSE,
    can_record_expenses BOOLEAN     NOT NULL DEFAULT FALSE,
    can_view_profit     BOOLEAN     NOT NULL DEFAULT FALSE,
    can_delete_records  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    removed_at          TIMESTAMPTZ
);

CREATE INDEX staff_members_store_idx ON staff_members (store_id) WHERE removed_at IS NULL;

CREATE TABLE staff_invites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id    UUID        NOT NULL REFERENCES staff_members (id) ON DELETE CASCADE,
    code_hash   TEXT        NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    redeemed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX staff_invites_staff_idx ON staff_invites (staff_id);

-- One row per signed-in device. Refresh tokens rotate constantly; the session
-- is the stable thing an owner sees in "signed-in devices" and can revoke.
CREATE TABLE device_sessions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id     UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    staff_id     UUID REFERENCES staff_members (id) ON DELETE CASCADE,
    device_name  TEXT        NOT NULL DEFAULT 'Unknown device',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at   TIMESTAMPTZ
);

CREATE INDEX device_sessions_owner_idx ON device_sessions (owner_id) WHERE revoked_at IS NULL;
CREATE INDEX device_sessions_staff_idx ON device_sessions (staff_id) WHERE revoked_at IS NULL;

-- Every live refresh token becomes its own session, reusing the token's id so
-- the backfill needs no join. Dead tokens are dropped: nothing can use them.
DELETE FROM refresh_tokens WHERE revoked_at IS NOT NULL OR expires_at <= now();

INSERT INTO device_sessions (id, owner_id, device_name, created_at, last_seen_at)
SELECT id, owner_id, device_tag, created_at, created_at FROM refresh_tokens;

ALTER TABLE refresh_tokens
    ADD COLUMN session_id UUID REFERENCES device_sessions (id) ON DELETE CASCADE,
    -- Set when a token is exchanged for a new one. Kept apart from
    -- `revoked_at` so a phone whose refresh response was lost in transit can
    -- still recover (see AuthService::refresh).
    ADD COLUMN rotated_at TIMESTAMPTZ;

UPDATE refresh_tokens SET session_id = id;

ALTER TABLE refresh_tokens ALTER COLUMN session_id SET NOT NULL;

CREATE INDEX refresh_tokens_session_idx ON refresh_tokens (session_id);

-- Who rang up a sale or recorded an expense. NULL means the owner. Set by the
-- server from the signed-in session, never taken from the device.
ALTER TABLE sales
    ADD COLUMN recorded_by_staff_id UUID REFERENCES staff_members (id) ON DELETE SET NULL;
ALTER TABLE expenses
    ADD COLUMN recorded_by_staff_id UUID REFERENCES staff_members (id) ON DELETE SET NULL;

-- An append-only record of who did what. Names are copied in at write time so
-- the history still reads correctly after someone is renamed or removed.
CREATE TABLE audit_events (
    seq          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id     UUID        NOT NULL REFERENCES owners (id) ON DELETE CASCADE,
    -- NULL for account-wide events such as signing out a device.
    store_id     UUID REFERENCES stores (id) ON DELETE CASCADE,
    staff_id     UUID REFERENCES staff_members (id) ON DELETE SET NULL,
    actor_name   TEXT        NOT NULL,
    device_name  TEXT        NOT NULL,
    action       TEXT        NOT NULL,
    entity_id    UUID,
    details      JSONB       NOT NULL DEFAULT '{}'::jsonb,
    -- When it happened on the device, which for an offline sale can be hours
    -- before the server hears about it.
    occurred_at  TIMESTAMPTZ NOT NULL,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX audit_events_store_idx ON audit_events (store_id, seq DESC);
CREATE INDEX audit_events_owner_idx ON audit_events (owner_id, seq DESC);
