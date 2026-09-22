# Architecture

Why Kitaza is built the way it is. Read `IMPLEMENTATION_PLAN.md` for what gets
built when.

---

## The central decision: local-first

Every write goes to SQLite on the device and returns immediately. Every read,
including the dashboard's aggregates, comes from SQLite. The cloud's job is to
keep that local copy current — never to serve a screen.

```
    tap "Save sale"
          │
          ▼
   ┌──────────────┐   one transaction
   │ SQLite       │   sale + lines + stock + outbox row
   └──────┬───────┘
          │ UI updates here, ~instantly
          ▼
   ┌──────────────┐
   │ outbox       │   sync_queue table
   └──────┬───────┘
          │ background: on a timer, and the moment connectivity returns
          ▼
   ┌──────────────┐  push (idempotent upserts)   ┌───────────┐
   │ Kitaza API   │ ◄──────────────────────────► │ Postgres  │
   │ (Rust/axum)  │  pull (rows since cursor)    └───────────┘
   └──────┬───────┘
          │ WebSocket
          ▼
   other devices in the same store
```

This follows from the users. A sari-sari store runs on a cheap Android phone
with intermittent prepaid data. An app that spins while a customer waits will
be abandoned for the notebook it replaced. Making offline the *default* path
rather than a fallback means there is no second, less-tested code path to rot.

The cost is real and worth naming: business logic exists twice. The health
score and the anomaly rule are implemented in both Rust and Dart with matching
weights and matching tests. Changing one without the other is the most likely
way to introduce a bug here.

---

## Backend

**axum + sqlx + Postgres + Redis.**

### Feature slices

`src/features/<name>/` holds that feature's routes, handlers, service,
repository and payloads as separate files. Dependencies point one way:

```
routes → handlers → service → repository → database
                       ↑
                    payloads
```

Handlers do HTTP and nothing else. Services hold the business rules. The
repository is the only thing that writes SQL. A feature never reaches into
another feature's repository — it depends on the exported service.

### Authorisation is structural

`StoreScope` is an axum extractor that resolves `/stores/{store_id}/...`,
verifies the caller owns that store, and hands the handler a verified store id.
A handler that takes `StoreScope` is authorised by construction; there is no
check to forget. Confirmed owner/store pairs are memoised, since ownership does
not change.

### Money

`NUMERIC(14,2)` in Postgres, `rust_decimal::Decimal` in Rust. JSON is the only
place a float appears, and it is converted at the request boundary
(`money_from_f64`) so nothing downstream sees one.

### Idempotency

Rows carry client-generated UUIDs, and every write is an upsert on that id.
Replaying a sync batch is therefore harmless — which matters, because a phone
losing signal mid-push is the normal case, not the edge case.

Sales need extra care: a plain upsert would re-run the stock deduction. So
`SaleRepository::record` checks whether the sale id already exists and, if so,
restores the stock its previous lines took out before applying the new ones.
Re-pushing an unchanged sale nets to zero; a genuine edit is applied correctly.

### Redis is optional by design

The cache handle can be empty. Dashboard caching, cross-instance realtime
fan-out and login rate limiting all degrade to no-ops when Redis is
unreachable, and the API logs a warning and carries on. Availability beats
throttling for a store that needs to ring up a sale.

### Realtime

Each store gets its own in-process broadcast channel, so a busy store never
wakes another store's listeners. When Redis is present, events are also
published to a channel that sibling instances mirror back in — without that
bridge, two replicas behind a load balancer would each only see their own
writes. Slow clients that fall behind are sent a `dashboard_stale` nudge rather
than being silently starved.

---

## Frontend

**Flutter + Riverpod + go_router + sqflite.** No code generation: the build
stays fast and the code stays greppable.

### Layers

```
features/   screens and controllers, one directory per feature
   │
data/repositories/   business operations; write local, enqueue sync
   │
data/local/dao/      SQL      data/remote/   HTTP + WebSocket
   │
data/models/         plain immutable classes
```

Screens never touch a DAO. Repositories never build widgets.

### Refresh

One `dataRevisionProvider` counter is bumped by any write — local, pulled from
the cloud, or announced over the WebSocket. Read-side providers watch it and
recompute. This is considerably easier to follow than a stream subscription per
table, and on a dataset this size the recompute is cheap.

### Money, again

SQLite stores integer centavos. `Centavos` is the single place that converts
between centavos, pesos and JSON, and it is directly tested against the classic
floating-point traps.

### Performance choices

- `itemExtent` on the product picker so long lists do not measure every row.
- Debounced search, so a low-end phone is not querying on every keystroke.
- WAL journal mode, so a slow report query cannot block a sale being written.
- A hand-drawn `CustomPaint` trend chart rather than a charting package — one
  measure, one axis, a few dozen bars, and no dependency weight on every build.

---

## Theme and accessibility

One description generates both themes, so light and dark cannot drift apart.

The palette is chosen for a shop counter, not a screenshot: deep teal reads as
trustworthy and survives daylight, with a warm amber accent. Body text starts
at 16pt and money never drops below 20pt, because small type is the most
common reason an owner hands the phone to someone younger. Tap targets have a
52px floor. System text scaling is honoured up to 1.4×.

**Colour is never the only signal.** The health rating ships with an icon, the
word Good / Average / Warning, a numeric score and written reasons.

The trend chart's colours were picked with the palette validator rather than by
eye, which caught a real problem: the obvious green/red pair fails
colour-vision-deficiency separation badly (deutan ΔE 4.2, where 8 is the
floor). Teal/red clears it comfortably — ΔE 14.0 in light mode, 11.7 in dark —
and both pairs pass lightness, chroma and contrast against their own surface.
Dark mode uses separately chosen mid-tone steps, not lightened versions of the
light ones. Sign is additionally carried by which side of the baseline a bar
sits on.

---

## Data model

```
owners ──< stores ──< products ──< stock_movements
                 │
                 ├──< sales ──< sale_items
                 ├──< expenses
                 └──< owner_withdrawals
```

Every business table carries `updated_at` and a nullable `deleted_at`.

- **Soft deletes**, because sync needs to propagate a deletion, and because a
  voided sale should be recoverable.
- **`updated_at` as the sync cursor.** Pull asks for everything changed since a
  timestamp; no separate change-log table to keep consistent.
- **Last write wins**, with the server as the authority. Sufficient for a
  business where one or two people record entries and genuine concurrent edits
  to the same row are rare.

`sale_items` stores `product_name` and `unit_cost` as they were at the time of
sale. Renaming a product or changing its cost price must not silently rewrite
last month's profit.
