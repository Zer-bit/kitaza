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

**axum + sqlx + Postgres + Redis.** The crate is a library with a thin binary,
so the integration tests in `backend/tests/` can drive the real router against
a real database.

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

Anything that *moves stock* needs more than an upsert, because re-running it
would move stock again:

- `SaleRepository::record` checks whether the sale already exists and, if so,
  restores the stock its previous lines took before applying the new ones. An
  unchanged re-push nets to zero; a genuine edit lands correctly.
- `StockRepository::record_movement` locks the product row, inserts the
  ledger row with `ON CONFLICT DO NOTHING`, and only moves stock if that
  insert actually happened.

### Stock is a ledger

Stock is never a number that devices overwrite. It is the sum of the stock
movements and the sales, and it only changes through them:

- A new product with opening stock is a `stock_in` movement.
- Correcting the count is an `adjustment` carrying the **counted total**, not
  a difference, so it stays right however many sales arrive around it.
- Products are pushed with `opening_stock: 0`; stock never travels on the
  product itself.

On a push, sales and movements are replayed in the order they *happened*
(`occurred_at`), not the order they were listed. This is what lets two phones
sell the same product offline and still agree on the count when they
reconnect — proven by the two-device contract test.

### Pull pagination

A pull pages each table on `(updated_at, id)` rather than "everything since a
timestamp". A timestamp-only cursor has two failure modes, both reproduced in
the integration tests before being fixed: a full page moves the cursor past
rows that were never sent, and rows written in one transaction share a
timestamp and get split across a gap. The id breaks the tie.

A short settle window holds back rows younger than two seconds. `updated_at`
is set when a transaction starts, not when it commits, and without the margin
a slow transaction could commit behind a cursor that has already moved on.

### Redis is optional by design

The cache handle can be empty. Dashboard caching, cross-instance realtime
fan-out and login rate limiting all degrade to no-ops when Redis is
unreachable, and the API logs a warning and carries on. Availability beats
throttling for a store that needs to ring up a sale.

### Realtime

The WebSocket carries nudges, not data. An event makes the device run an
ordinary sync, and the pull brings the rows. There is one path for data to
arrive by, and a missed event costs nothing but a slightly later refresh.

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

### The outbox

Every local write also lands in `sync_queue`, in the same transaction. The
sync coordinator:

- **pushes in batches until the outbox is empty**, then **pulls pages until
  the server reports `has_more: false`**;
- **clears exactly the rows it sent**, by row id. Re-queuing an entity
  replaces its row with a new id, so an edit made while an upload is in flight
  survives that upload;
- **parks a row after five refusals** instead of resending it forever, and
  shows it on the *Sync problems* screen with the server's reason;
- **backs off** from 30 seconds to 15 minutes after transport failures, but
  goes immediately when connectivity returns or the owner taps *Sync now*.

A local-only device queues too. That outbox is what makes the cloud upgrade
work: the store's rows are re-scoped to the cloud store's id, and the first
sync uploads the complete history through the ordinary push path.

### Sessions and store scope

The active store and storage mode are Riverpod state, set by the auth
controller on every session change, and every store-scoped provider rebuilds
when they change. An earlier version read them once and cached them for the
app's lifetime, so switching accounts kept writing to the previous store.

**Signing out always clears the device.** In cloud mode the records come back
with a full download on the next sign-in. Leaving them — and the outbox —
behind would let the next person to sign in upload the previous owner's unsent
entries into their own store. The sign-out dialog tries a final sync and says
how many unsent changes would be lost.

### Refresh

One `dataRevisionProvider` counter is watched by every read-side provider.
`localWrite()` bumps it and schedules a push a moment later, coalescing a
burst of entries into one upload; a pull that wrote anything bumps it too.
This is considerably easier to follow than a stream subscription per table,
and on a dataset this size the recompute is cheap.

### Startup and the splash

The router is created once and re-runs its redirect when auth changes. The
decision itself is a pure function, `resolveRoute`, tested directly.

The native splash (generated by `flutter_native_splash`) shows until Flutter's
first frame. That frame is `SplashScreen`, drawn to match it exactly — same
background per *system* brightness, same logo, same 120dp size — so the
hand-off cannot be seen. It stays until the stored session is read, then
routes to the dashboard or the welcome screen. A spinner appears only if that
takes longer than 700ms.

All brand imagery — launcher icons, splash, in-app logo — is generated from
one SVG, `frontend/assets/brand/source/kitaza_glyph.svg`, by `make brand`.

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

## Languages

English and Filipino, from ARB files in `frontend/lib/l10n/`, reached through
`context.l10n`. Two rules keep it honest:

- **The data layer never produces display text.** A health reason is a typed
  value (`SpentMoreThanSold(1200)`), an expense category an enum, and the
  words are chosen at the screen. The alternative — English sentences built
  deep in the data layer — cannot be translated.
- **Stored data is never translated.** A keypad sale is saved as the fixed
  name `Quick sale` and shown as *Mabilisang benta* to a Filipino reader,
  because the same row syncs to devices set to different languages.

Server errors reach the owner through their machine-readable `code`
(`conflict`, `too_many_requests`...), mapped to translated text on the phone.

One trap worth knowing: in Filipino grammar the plural category *one* covers
1, 2, 3, 5, 7, 8, 11, 23… So an ICU branch written as `=1{1 benta}` displays
"1" for most counts. Filipino messages use only `other{{count} …}`, and a test
renders every count message for 1–30 in both languages.

---

## Schema migrations (phone)

`SchemaMigrations` holds every change since version 1 as a numbered step. A
new install builds version 1 and runs the same steps an upgrading phone runs,
so the two can never diverge — a test compares a fresh schema with an upgraded
one statement by statement. Released steps are never edited.

---

## Backups

The phone copies its own database: daily (a week kept), on demand for export,
and back in on restore.

- **Checkpoint, copy, verify.** `VACUUM INTO` needs SQLite 3.27 and Android 10
  ships 3.22, so the write-ahead log is folded into the main file, the file is
  copied, and the copy must pass `integrity_check`. A test proves the
  checkpoint matters: without it, copies miss recent writes and even whole
  tables.
- **Inspect before replacing.** A candidate file is opened read-only from a
  scratch copy and must have Kitaza's tables, a schema version this app can
  read, and a clean integrity check. The owner sees the store name, sale count
  and last entry before confirming.
- **Restore by restart.** Every provider holds the open database, so rather
  than patch each one, `AppRestarter` closes it, swaps the file, reopens and
  rebuilds the app from scratch — the same path as a fresh launch.

The server side is `pg_dump` on a schedule; see `OPERATIONS.md`.

---

## Error reports

`ErrorReporter` takes over Flutter's and the platform's uncaught-error hooks.
It must never throw and never recurse, so every write is guarded and a failure
to record is dropped. Reports are fingerprinted by error type plus the app's
own top stack frames (frame numbers stripped, so async gaps do not split one
bug in two), repeats increment a counter, and at most fifty are kept. Cloud
phones upload after a successful sync and delete only what the server
accepted; the endpoint upserts on fingerprint and version, so retries are
harmless.

---

## Receipts and scanning

A receipt is laid out once, as fixed-width lines, and both outputs start from
that layout: shared text keeps the ₱ sign; the printer path swaps it for "P"
and transliterates to ASCII, because thermal printers use single-byte
character sets. The ESC/POS encoder uses only the commands every printer
supports, and the exact bytes are tested.

The camera and the Bluetooth printer sit behind providers
(`barcodeScannerProvider`, `receiptPrinterProvider`), so every flow around them
is tested with fakes. The hardware links themselves are the only untested
parts.

---

## Theme and accessibility

One description generates both themes, so light and dark cannot drift apart.

The palette is chosen for a shop counter, not a screenshot: deep teal reads as
trustworthy and survives daylight, with a warm amber accent. Body text starts
at 16pt and money never drops below 20pt, because small type is the most
common reason an owner hands the phone to someone younger. Tap targets have a
52px floor. System text scaling is honoured up to 1.4×.

The audit is automated: every main screen is rendered on a 360×640 phone at
1.4× text, in both themes and both languages, empty and full of data, and
checked against Flutter's tap-target, labelling and text-contrast guidelines.
A separate test measures the contrast ratio of every text/background pair in
the palette. Taps in tests that land on nothing fail the test outright, so a
button scrolled off screen can never pass by accident.

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
