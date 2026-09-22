# HTTP API

Base path `/api/v1`. All responses are JSON. Authenticated endpoints take
`Authorization: Bearer <access_token>`.

Errors share one shape:

```json
{ "error": { "code": "bad_request", "message": "amount must be greater than zero" } }
```

Codes: `bad_request`, `unauthorized`, `forbidden`, `not_found`, `conflict`,
`too_many_requests`, `subscription_required`, `upgrade_required`,
`internal_error`. The two billing codes come with `402 Payment Required`.

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
| POST | `/auth/join` | A staff member's phone joining with a join code. `{ "code": "ABCDE-FGHJK" }`, typed any way. |
| POST | `/auth/refresh` | New token pair within the same device session. |
| POST | `/auth/logout` | Ends this device's session and every token it holds. |
| GET | `/auth/me` | Who this device is signed in as: stores and access. Staff included. |

`register`, `login`, `join` and `refresh` all send `device_tag` and
`device_name` (optional, shown in the owner's device list) and return:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_in_seconds": 3600,
  "session_id": "...",
  "owner":  { "id": "...", "email": "...", "full_name": "..." },
  "stores": [ { "id": "...", "name": "...", "business_type": "sari_sari", "currency_code": "PHP" } ],
  "access": { "role": "owner", "display_name": "Nena", "permissions": ["manage_products", "record_expenses", "view_profit", "delete_records"] }
}
```

For staff, `access.role` is `staff`, `access.staff_id` is set, `stores` holds
their one store, and `owner.email` is left out.

Every account description also carries the owner's `subscription`, staff
included, so a phone knows whether its uploads will be taken:

```json
"subscription": {
  "status": "trial", "plan": "pro",
  "period_ends_at": "...", "pauses_at": "...",
  "store_limit": 5, "allows_staff": true
}
```

`status` is `unlimited` (billing off), `trial`, `active`, `grace` or `paused`.

**Sessions.** Each sign-in opens a device session; the access token names
it, and the server looks it up on every request (remembered for up to 20
seconds per instance). Revoking a device, removing a staff member or changing
their permissions therefore takes effect on the next request, not when the
hour-long access token expires.

**Refresh** exchanges a refresh token for a new pair in the same session. The
old token keeps working for 24 hours after it was exchanged, so a phone whose
refresh response was lost in transit can ask again instead of being locked
out. Signing out or revoking the device ends every token at once.

## Permissions

Owners can do everything. Staff can always record sales, plus whatever the
owner grants:

| Permission | Allows |
|---|---|
| `manage_products` | Save and remove products, record stock movements. |
| `record_expenses` | Record expenses. |
| `view_profit` | Cost prices, profit, expenses, withdrawals, dashboard and reports. |
| `delete_records` | Void sales and delete expenses. |

Withdrawals, stores, staff, devices and the activity log are owner-only. A
refusal is `403 forbidden` with a message starting `only the owner`.

## Billing

| Method | Path | Notes |
|---|---|---|
| GET | `/billing` | Owner only. Where the account stands, the plans and prices, and past payments. |
| POST | `/billing/checkout` | Owner only. `{ "plan": "pro", "months": 1 }` (1 or 12). Returns `checkout_url` to open in the browser. |
| POST | `/billing/webhooks/paymongo` | PayMongo's webhook. Verified by its `Paymongo-Signature` header; acts on `checkout_session.payment.paid`. |

Unprefixed pages for the phone's browser: `GET /billing/return` (where a
checkout comes back to) and, in test mode only, `GET|POST
/billing/test-checkout/{payment_id}` (a pay button, no money).

**Plans.** Basic ₱99 a month: cloud sync for one store. Pro ₱199 a month: up
to five stores and staff. A year costs ten months. Offline use needs no plan.

**Payments are prepaid periods**, not recurring charges: GCash and Maya
payments through a gateway are one-off. A payment extends the subscription
from whichever is later, now or the end of what is already bought; paying
during a trial starts after the trial; time left on one plan is converted to
the other at the price ratio. The gateway may report a payment more than
once; it is counted once.

**What each standing allows:**

| | Uploads | Downloads (owner) | Staff | Stores taking entries |
|---|---|---|---|---|
| trial | yes | yes | yes | 5 |
| active / grace | yes | yes | Pro only | 1 (Basic) or 5 (Pro) |
| paused | **no** | **yes** | no | none |

Grace lasts 7 days after a trial or paid period ends. While paused, uploads
are refused with `subscription_required` and wait on the phones; nothing is
deleted, the owner can still download everything, rename stores, and remove
staff or devices. A store past the plan's limit (the newest ones first) is
read-only, refused with `upgrade_required`. So is adding a store or staff
member the plan does not cover.

## Stores

| Method | Path | Notes |
|---|---|---|
| POST | `/stores` | Owner only. `{ "name": "...", "business_type": "carinderia" }` |
| PATCH | `/stores/{store_id}` | Owner only. Rename: `{ "name": "..." }` |

An owner's stores are listed by `/auth/me`.

## Staff

All owner-only, under `/stores/{store_id}`:

| Method | Path | Notes |
|---|---|---|
| GET | `/staff` | Each with `permissions`, `signed_in_devices` and `invite_expires_at` if a code is outstanding. |
| POST | `/staff` | `{ "display_name": "Liza", "permissions": [] }`. Returns the staff member and an `invite` with a `code`. |
| PATCH | `/staff/{staff_id}` | Same body. Applies to their phones on the next request. |
| DELETE | `/staff/{staff_id}` | Removes them and signs out their phones in the same transaction. |
| POST | `/staff/{staff_id}/invite` | A new code for a new phone. Any earlier unused code stops working. |

Join codes are ten characters from an alphabet without look-alikes
(`ABCDE-FGHJK`), work once, expire after 24 hours, and are stored hashed.

## Devices

Owner-only:

| Method | Path | Notes |
|---|---|---|
| GET | `/devices` | Every live session on the owner's account and their staff's, the caller's marked `is_current`. |
| DELETE | `/devices/{session_id}` | Signs that device out. |

## Activity

```
GET /stores/{store_id}/activity?before=<id>&limit=50&filter=removals
```

Owner-only. Newest first; pass `next_before` back as `before` for older
entries. `filter=removals` keeps only voids and deletions.

```json
{
  "events": [ {
    "id": 812, "action": "sale_voided", "actor_name": "Liza", "is_staff": true,
    "device_name": "Samsung SM-A125F", "entity_id": "...",
    "details": { "total": 150.0, "sold_at": "..." },
    "occurred_at": "...", "recorded_at": "..."
  } ],
  "next_before": 790
}
```

Actions: `sale_recorded`, `sale_voided`, `expense_recorded`, `expense_deleted`,
`withdrawal_recorded`, `withdrawal_deleted`, `product_added`,
`product_changed` (with `details.changes`), `product_removed`,
`stock_received`, `stock_removed`, `stock_counted` (with `counted` and
`change`), `stock_spoiled`, `staff_added`, `staff_changed`, `staff_removed`,
`staff_invited`, `staff_joined`, `device_signed_out`, `store_added`,
`store_renamed`, `subscription_paid`. Entries are written when something
actually changes, so a retried push is logged once. `occurred_at` is when it happened on the phone.

## Store-scoped endpoints

Every path below is prefixed `/stores/{store_id}`, and access to the store is
verified before the handler runs: owners reach their own stores, staff only
theirs. Reads that show costs or profit need `view_profit`; product reads are
open to all staff with `cost_price` zeroed for those without it.

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
- **Each row is checked against the sender's permissions.** A staff phone
  that queued something it may not do gets that row refused with a reason
  starting `only the owner`.
- **Staff may retry their own rows but not rewrite anyone else's.** A sale
  or expense id that already exists is only overwritten by the owner or by
  whoever recorded it first.
- **An id belonging to another store is refused**, never overwritten.
- **A voided sale is final.** Sending it again changes nothing and is not an
  error.
- **Cost figures from a phone without `view_profit` are ignored**: a sale is
  costed from the catalogue, and a product keeps the cost the owner set.

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
- **Staff without `view_profit` get no costs.** `cost_price`, `cost_amount`
  and `unit_cost` arrive as 0, and `expenses` and `withdrawals` are empty.
  Their cursor does not advance past those two tables, so granting the
  permission later brings them in full; the phone also restarts its download
  from scratch when the permission changes, to replace the zeroed costs.

## Diagnostics

| Method | Path | Notes |
|---|---|---|
| POST | `/diagnostics/errors` | Error reports from a signed-in phone, owner's or staff's. |

```json
{
  "reports": [{
    "fingerprint": "3f9a1c7e",
    "error_type": "StateError",
    "message": "Bad state: No element",
    "stack": "#0 ...",
    "occurrences": 3,
    "first_seen": "2026-09-22T01:00:00Z",
    "last_seen": "2026-09-22T04:10:00Z",
    "app_version": "1.0.0+1",
    "platform": "android 14"
  }]
}
```

Returns `202 {"accepted": n}`. One to twenty reports per request; the message
is capped at 2,000 characters and the stack at 16,000. A report for a
fingerprint and app version the owner has sent before adds to the existing
count rather than creating a new row, so a retried upload is harmless. Rate
limited per owner (30 requests an hour), separately from sign-in, so a phone
in a crash loop cannot lock its owner out.

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
`withdrawal_recorded`, `product_changed`, `stock_low`, `dashboard_stale`,
`access_changed` (a staff member's permissions changed or they were removed:
re-read `/auth/me`).

Staff may only open their own store's socket. The session is re-checked on
every keepalive, so a signed-out device stops hearing events within about
half a minute.

The server pings every 25 seconds. A client that falls behind receives
`dashboard_stale` and should re-pull rather than assume it has everything.
