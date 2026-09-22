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
| GET/POST | `/stock-movements` | `stock_in`, `stock_out`, `adjustment`, `spoilage`. Idempotent on `id`. |
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
| GET | `/sync/pull` | `?cursor=<opaque>` |

`GET /expense-categories` (not store-scoped) returns the closed category list.

### Why `utc_offset_minutes`

"Today" means the owner's calendar day, not the server's. The client sends its
offset in minutes east of UTC and the server resolves the window against it, so
an 11pm sale in Manila lands on the right day.

## Sync

Devices write locally first and reconcile through these two endpoints. The
contract is exercised end to end by `frontend/test/contract/`.

### Push

Everything a device queued while offline:

```json
{
  "products":        [ { "id": "…", "name": "Coke", "cost_price": 15, "selling_price": 20, "opening_stock": 0, "reorder_level": 6 } ],
  "stock_movements": [ { "id": "…", "product_id": "…", "movement": "stock_in", "quantity": 24, "unit_cost": 15, "occurred_at": "…" } ],
  "sales":           [ { "id": "…", "occurred_at": "…", "items": [ { "id": "…", "product_id": "…", "quantity": 3 } ] } ],
  "expenses":        [ … ],
  "withdrawals":     [ … ],
  "deletions":       [ { "entity": "sale", "id": "…" } ]
}
```

Rules the server applies:

- **Every row carries a client-generated id**, and every write is an upsert
  on it. Replaying a batch changes nothing the second time — including stock.
- **Products first**, since a sale or movement may reference a product
  created offline in the same batch.
- **Stock never travels on the product.** Devices send `opening_stock: 0` and
  move stock only through `stock_movements` and sales.
- **Sales and stock movements are replayed in `occurred_at` order**, however
  the device lists them. An `adjustment` carries a *counted total* (which may
  be zero), so order decides the outcome: sell 2, count 10, sell 1 must end
  at 9.
- **Sale lines keep the device's ids** when sent, so pulling a sale back never
  duplicates its lines.
- **Deletions run last.** `entity` is `sale` (voids and restores stock),
  `expense`, `withdrawal` or `product`. Deleting something already gone is a
  success.
- **Rows are independent.** One refused row never blocks the rest.

```json
{
  "applied":  [ { "entity": "sale", "id": "…" }, { "entity": "deletion", "id": "…" } ],
  "rejected": [ { "entity": "sale", "id": "…", "reason": "product not found" } ],
  "server_time": "2026-09-22T04:10:00Z"
}
```

`entity` is one of `product`, `stock_movement`, `sale`, `expense`,
`withdrawal`, `deletion` — so a device can tell a sale from the deletion of
that same sale. Unexpected server errors are reported with a generic reason;
the detail goes to the server log, not the owner's screen.

### Pull

```
GET /stores/{store_id}/sync/pull?cursor=<opaque>
```

Omit `cursor` for a full download. Keep pulling with the returned cursor while
`has_more` is true.

```json
{
  "products": [ … ], "sales": [ … ], "sale_items": [ … ],
  "expenses": [ … ], "withdrawals": [ … ], "stock_movements": [ … ],
  "cursor": "7b22…",
  "has_more": false
}
```

- **The cursor is opaque.** Internally it tracks a `(updated_at, id)`
  position per table; clients store it and send it back unchanged. An
  unreadable cursor falls back to a full download, which is slow but never
  wrong.
- **Keyset pagination** means a full page never skips rows, and rows that
  share a timestamp — everything written in one transaction — are never split
  across a gap.
- **`sale_items` holds every line of every sale in `sales`.** Replace a
  pulled sale's lines wholesale rather than merging them.
- **Deleted rows are included** with `deleted_at` set, so deletions
  propagate.
- **Rows younger than the settle window** (`KITAZA_SYNC_SETTLE_MS`, default
  2 s) are held back until the next pull. `updated_at` is set when a
  transaction starts, not when it commits; without the margin, a slow
  transaction could commit behind a cursor that has already moved past it.

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
