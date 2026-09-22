# Operations

For whoever runs the Kitaza server: backups, restores, and reading the error
reports phones send in.

---

## Backups

### Server

The `backup` service in `docker-compose.yml` runs `infra/backup/backup.sh`
once a day and keeps 14 days of dumps in `./backups` on the host.

```bash
make backup                              # take one now
ls backups/                              # kitaza-20260922-073359.dump ...
```

Each dump is written under a temporary name and renamed only after
`pg_restore --list` has read it back, so a file named `kitaza-*.dump` is always
complete.

| Variable | Default | |
|---|---|---|
| `BACKUP_DATABASE_URL` | the compose Postgres | Point at Supabase to back up a hosted database. |
| `BACKUP_RETENTION_DAYS` | `14` | |
| `BACKUP_INTERVAL_HOURS` | `24` | |

**Supabase.** Supabase takes its own daily backups on paid plans, with
point-in-time recovery as an add-on. Running this service against Supabase as
well gives you copies you hold yourself, which is worth having.

**Copy dumps off the server.** A backup on the same disk as the database does
not survive the disk. Sync `./backups` to object storage or another machine.

### Restoring the server

```bash
make restore DUMP=backups/kitaza-20260922-073359.dump
```

This replaces **everything** in the target database with the dump's contents,
so the script refuses to run without `--yes-replace-everything`, which the make
target passes only when `DUMP` is given. To inspect a dump without touching
production, restore into a scratch database instead:

```bash
createdb kitaza_check
infra/backup/restore.sh backups/kitaza-....dump postgres://.../kitaza_check --yes-replace-everything
```

The restore runs in a single transaction: it either completes or changes
nothing. The migration history is part of the dump, so the API will not try to
re-run migrations against a restored database.

### Phones

Offline stores have no server copy at all, so the app protects them itself:

- **Automatic:** one copy a day on the phone, the last seven kept. Protects
  against a corrupted database, not a lost phone.
- **Export:** Settings → *Save a backup copy* sends a `.kitaza` file anywhere
  the owner chooses — Messenger, Drive, email. This is what survives a lost
  phone; encourage owners to do it weekly.
- **Restore:** Settings → *Restore from a backup file*, or on a new phone,
  *Restore from a backup file* on the welcome screen. The app shows the
  store name, the number of sales and the date of the last entry before
  replacing anything.

Cloud stores need none of this — the server is their backup — but can still
export a copy.

---

## Error reports

Phones record errors nobody handled. Cloud stores upload them after each sync;
offline stores can send them from Settings. Reports hold the error type,
message and stack, the app version and the phone's OS — no sales, amounts,
names or customer details. They are kept for 90 days.

What is breaking most in the current release:

```sql
SELECT app_version,
       error_type,
       left(message, 80)        AS message,
       COUNT(DISTINCT owner_id) AS stores_affected,
       SUM(occurrences)         AS times
FROM client_error_reports
WHERE last_seen > now() - interval '7 days'
GROUP BY app_version, fingerprint, error_type, left(message, 80)
ORDER BY stores_affected DESC, times DESC
LIMIT 20;
```

The full stack for one of them:

```sql
SELECT stack FROM client_error_reports
WHERE fingerprint = '<fingerprint>' ORDER BY last_seen DESC LIMIT 1;
```

Rank by `stores_affected` rather than `times`: one phone in a crash loop can
produce thousands of occurrences of a bug that affects nobody else.

---

## Taking payments

`KITAZA_BILLING` decides:

| Value | Meaning |
|---|---|
| `off` | Nothing is charged; every cloud account has every feature. The default outside Docker. |
| `test` | Plans are enforced, and checkout is a page on this server with a pay button. The Docker Compose default, for trying the flow. Never in production. |
| `paymongo` | Real payments. Needs `KITAZA_PAYMONGO_SECRET_KEY` and `KITAZA_PAYMONGO_WEBHOOK_SECRET`. |

For PayMongo:

1. In the PayMongo dashboard, enable GCash, Maya and cards on the account.
2. Create a webhook pointing at
   `<KITAZA_PUBLIC_URL>/api/v1/billing/webhooks/paymongo` for the event
   `checkout_session.payment.paid`, and put its secret in
   `KITAZA_PAYMONGO_WEBHOOK_SECRET`.
3. Set `KITAZA_PUBLIC_URL` to the address phones reach the server at; the
   checkout returns the owner's browser to `/billing/return` there.
4. Start with the test keys (`sk_test_…`) and pay a test checkout before
   switching to live keys.

If a webhook is missed, the payment shows in PayMongo but the owner's plan
has not moved. Re-send the event from the PayMongo dashboard: the handler
extends the subscription, and ignores an event it has already acted on, so
re-sending is always safe. Payments still waiting on their webhook:

```sql
SELECT id, owner_id, plan, months, amount, provider_reference, created_at
FROM payments WHERE status = 'pending' ORDER BY created_at DESC;
```

A pending row can also be a checkout the owner opened and abandoned; those
are harmless and never extend anything.

`KITAZA_TRIAL_DAYS` (30) and `KITAZA_GRACE_DAYS` (7) tune the trial and the
grace week. Accounts that existed before billing was added were given a
30-day trial by migration 7.

---

## Devices and staff

Owners manage both from the app: *Settings → Stores and staff*. Support rarely
needs to, but when an owner cannot reach a phone at all:

```sql
-- Every phone signed in to an owner's account, newest activity first.
SELECT s.id, s.device_name, st.display_name AS staff, s.last_seen_at
FROM device_sessions s
JOIN owners o ON o.id = s.owner_id
LEFT JOIN staff_members st ON st.id = s.staff_id
WHERE lower(o.email) = lower('<email>') AND s.revoked_at IS NULL
ORDER BY s.last_seen_at DESC;

-- Sign one out. Its refresh tokens die with it.
UPDATE device_sessions SET revoked_at = now() WHERE id = '<session id>';
UPDATE refresh_tokens  SET revoked_at = now() WHERE session_id = '<session id>';
```

Each API instance remembers who a session belongs to for 20 seconds, so on a
multi-instance deployment a revoke can take that long to reach every
instance. The phone finds out on its next request and shows its signed-out
screen; nothing on it is deleted.

**Upgrading a server from before Phase 6** runs migration 6, which turns every
live refresh token into a device session and drops dead ones. Phones already
signed in stay signed in: their next request is refused once for lacking a
session id, and they renew silently.

---

## Running the tests that need services

```bash
make test-integration TEST_DATABASE_URL=postgres://...   # needs CREATEDB
make test-contract CONTRACT_API=http://localhost:8080/api/v1
```

Neither needs Redis: the API degrades gracefully without it, and so do the
tests.
