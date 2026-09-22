# HTTP API

Base path `/api/v1`. All responses are JSON. Authenticated endpoints take
`Authorization: Bearer <access_token>`.

Errors share one shape:

```json
{ "error": { "code": "bad_request", "message": "amount must be greater than zero" } }
```

Codes: `bad_request`, `unauthorized`, `forbidden`, `not_found`, `conflict`,
`too_many_requests`, `internal_error`.

## Health

| Method | Path | Notes |
|---|---|---|
| GET | `/health` | Liveness. Unprefixed. |
| GET | `/health/ready` | Readiness. 503 if Postgres is unreachable; Redis is reported but never fails the probe. |

## Authentication

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/register` | Creates the owner and their first store in one transaction. |
| POST | `/auth/login` | Rate limited per email. |
| POST | `/auth/refresh` | Rotates the refresh token; the old one is revoked on use. |
| POST | `/auth/logout` | Revokes one refresh token. |
| GET | `/auth/me` | Current owner and their stores. |

`register` and `login` return:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_in_seconds": 3600,
  "owner":  { "id": "...", "email": "...", "full_name": "..." },
  "stores": [ { "id": "...", "name": "...", "business_type": "sari_sari", "currency_code": "PHP" } ]
}
```

## Store-scoped endpoints

Every path below is prefixed `/stores/{store_id}`, and ownership is verified
before the handler runs.

| Method | Path | Notes |
|---|---|---|
| GET/POST | `/products` | `POST` upserts on a client-supplied `id`. |
| GET | `/products/low-stock` | At or below the reorder level. |
| GET/DELETE | `/products/{product_id}` | Delete is a soft delete. |
| GET/POST | `/stock-movements` | `stock_in`, `stock_out`, `adjustment`, `spoilage`. |
| GET | `/inventory/valuation` | Stock value at cost and at selling price. |
| GET/POST | `/sales` | Totals are recomputed server-side from the line items. |
| GET/DELETE | `/sales/{sale_id}` | Voiding restores stock. |
| GET/POST | `/expenses` | |
| DELETE | `/expenses/{expense_id}` | |
| GET/POST | `/withdrawals` | |
| DELETE | `/withdrawals/{withdrawal_id}` | |
| GET | `/dashboard` | `?period=today\|week\|month&utc_offset_minutes=480` |
| GET | `/reports/summary` | Everything the weekly summary screen needs, in one call. |
| GET | `/reports/profit-trend` | `?days=14` |
| GET | `/reports/top-products` | Ranked by profit, not revenue. |
| GET | `/reports/expense-breakdown` | |
| GET | `/reports/unusual-expenses` | |
| POST | `/sync/push` | |
| GET | `/sync/pull` | `?since=<ISO8601>` |

`GET /expense-categories` (not store-scoped) returns the closed category list.

### Why `utc_offset_minutes`

"Today" means the owner's calendar day, not the server's. The client sends its
offset in minutes east of UTC and the server resolves the window against it, so
an 11pm sale in Manila lands on the right day.

## Sync

**Push** sends everything queued while offline. Each list is processed
independently, so one bad row never blocks the batch:

```json
{ "products": [...], "sales": [...], "expenses": [...], "withdrawals": [...] }
```

```json
{
  "applied":  ["<uuid>", "..."],
  "rejected": [ { "entity": "sale", "id": "<uuid>", "reason": "product not found" } ],
  "server_time": "2026-09-22T04:10:00Z"
}
```

Writes are upserts on client-generated ids, so replaying a batch is safe.

**Pull** returns every row changed after `since`, plus a `cursor` to send next
time. Omitting `since` downloads everything. The cursor is read *before* the
queries run, so a row written mid-pull is picked up next time rather than
skipped.

## WebSocket

```
ws://host/ws/store/{store_id}?token=<access_token>
```

The token is a query parameter because browsers cannot set headers on a
websocket handshake — use TLS in production. Frames:

```json
{ "store_id": "...", "topic": "sale_recorded", "entity_id": "...", "emitted_at": "..." }
```

Topics: `sale_recorded`, `sale_voided`, `expense_recorded`, `expense_removed`,
`withdrawal_recorded`, `product_changed`, `stock_low`, `dashboard_stale`.

The server pings every 25 seconds. A client that falls behind receives
`dashboard_stale` and should re-pull rather than assume it has everything.
