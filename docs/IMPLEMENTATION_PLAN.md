# Kitaza — Implementation Plan

This is the build order for Kitaza, from the scaffold that exists today through
to a product small businesses pay for monthly. Phases 0–4 are **done and
verified**; 5 onward are planned.

Each phase ends at something demonstrable, because the biggest risk in this
product is not technical — it is that store owners keep using their notebook.
Every phase should be showable to a real owner.

---

## Phase 0 — Foundations ✅ Done

Infrastructure that everything else assumes, so it never has to be retrofitted.

- Rust workspace: axum router, layered config from the environment, structured
  error type that never leaks internals, tracing, graceful shutdown.
- Postgres schema in versioned migrations, applied on boot.
- Redis wired for dashboard caching and login rate limiting, **optional** — the
  API boots and serves traffic when Redis is down, it just loses caching.
- Flutter app: theme system, routing, Riverpod wiring, SQLite schema.
- Docker Compose for Postgres + Redis + API.

**Key decision: money is never a float.** Postgres stores `NUMERIC(14,2)` and
Rust reads it as `Decimal`; SQLite stores integer centavos and Dart converts at
the edges. A rounding error in a profit total destroys the only thing this
product sells — trust in the number.

**Exit criteria:** `cargo test`, `flutter test`, `flutter analyze` and
`cargo clippy` all clean. ✅

---

## Phase 1 — Identity and the offline/online choice ✅ Done

The first screen decides the whole shape of a user's experience, so it comes
before any business feature.

- Argon2id password hashing on a blocking thread pool.
- Short-lived JWT access tokens plus opaque, revocable, rotating refresh tokens
  stored as SHA-256 digests.
- Refresh token lifetime of **180 days**, so a device signs in once and never
  again. Tokens live in the platform keystore.
- Dio interceptor that renews an expired access token and replays the request,
  sharing one refresh across concurrent 401s.
- Login rate limiting that **fails open** — a store that cannot ring up a sale
  because Redis is unhappy is worse than an unthrottled login endpoint.
- Onboarding: "Just this phone" (no account, no password) or "Save to the
  cloud", explained in terms of what the owner gets, not in terms of sync.

**Why local mode has no password:** there is no remote account to protect, and
a forgotten password would lock an owner out of their own books. The device
lock screen is the real security boundary.

**Exit criteria:** a fresh install reaches the dashboard in two taps; a
reinstalled cloud device restores its session without a prompt. ✅

---

## Phase 2 — The MVP loop ✅ Done

Record Sales · Record Expenses · Daily/Weekly/Monthly Profit · Owner
Withdrawals · Simple Dashboard.

- **Sales.** Quick-amount keypad for a five-second entry, or product picker for
  a basket. Server recomputes every total from the line items — the client is
  never trusted with money arithmetic. Sale, lines, stock deduction and stock
  ledger all write in one transaction.
- **Expenses.** Nine categories, chosen as a closed list so reports stay
  meaningful, with `other` so nobody is ever blocked.
- **Owner withdrawals.** Separate from expenses. This one distinction is what
  makes most small-business books honest: taking cash home is not a cost of
  doing business, and mixing the two hides whether the store earns.
- **Dashboard.** Sales, expenses, profit and cash-kept, for today / this week /
  this month, computed locally from SQLite so it opens instantly offline.

**Exit criteria:** an owner can record a day of trading and see a correct
profit figure with no network. ✅

---

## Phase 3 — Inventory, health score and insights ✅ Done

- Stock movements (in, out, adjustment, spoilage) with a running total kept in
  the same transaction as the ledger row.
- Low-stock warnings driven by a per-product reorder level.
- **Business health score**: 0–100 from four signals an owner can act on — are
  you profitable, is the margin healthy, are you trending up, are you
  withdrawing more than you earn. Rendered as Green / Yellow / Red **with an
  icon, a word and written reasons**, never colour alone.
- **Unusual expense detection**: flags spending ≥2.5× the store's own average
  for that category, once there are at least four samples.
- Reports: 14-day profit trend, products ranked by *profit* rather than
  revenue, and an expense breakdown.

**Why a rule and not a model.** The "ML insights" in the brief are served
better, for now, by transparent arithmetic. It works from day one with no
training data, the owner can check it themselves, and it cannot embarrass you
by being confidently wrong. Revisit once there is real cross-store data — see
Phase 8.

**Both implementations are duplicated on purpose.** The score and the anomaly
rule exist in Rust *and* in Dart, with matching weights and matching tests, so
an offline device shows the same rating as an online one. Any change to one
must change the other.

**Exit criteria:** health score and insights identical online and offline. ✅

---

## Phase 4 — Sync hardening ✅ Done

Phases 0–3 had only ever been compiled and unit-tested. Phase 4 ran the whole
system for the first time — the API against a real Postgres, and the Flutter
data layer against that API — and fixed what that exposed.

- [x] **Integration tests against a live Postgres.** 15 tests drive the real
      router over HTTP, one freshly migrated database per test
      (`make test-integration`).
- [x] **Idempotent replay.** Pushing the same batch twice changes nothing the
      second time — for sales *and* for stock movements.
- [x] **Stock as a ledger.** Stock only changes through movements and sales,
      replayed on the server in the order they happened. A counted-stock
      correction records the counted total, so it stays right however many
      sales arrive around it.
- [x] **Deletions sync.** Voids and removals made offline reach the server,
      and repeating one is harmless.
- [x] **Keyset pull pagination.** A new device receives every row however many
      pages it takes, including rows that share a timestamp.
- [x] **Retry cap and backoff.** A row the server refuses five times is parked
      rather than resent forever; transport failures back off from 30 seconds
      to 15 minutes, and reconnecting or tapping *Sync now* skips the wait.
- [x] **Sync problems screen** listing refused entries with the server's
      reason, and *Try again* / *Keep on phone only*.
- [x] **Local → cloud upgrade.** A store that lived on one phone moves into a
      new or existing account with its full history, stock ledger included.
- [x] **Live updates wired in.** The WebSocket connects while signed in to the
      cloud; an event triggers a normal sync, so there is one path for data
      to arrive by.
- [x] **Two-device contract test.** Two simulated phones, each with its own
      SQLite, trade through the real API and end with identical books
      (`make test-contract`).
- [x] **Placeholder logo and splash screen**, generated from one source SVG
      (`make brand`). The in-app splash matches the native one exactly, so the
      hand-off is invisible.

### Defects found and fixed

Recorded because each one would have reached a real store.

| Defect | Effect | Caught by |
|---|---|---|
| JWT crypto backend never enabled | **Every sign-up and sign-in crashed the request** | First real run of the API |
| Product stock sent on the product and ignored on update | Correcting a count was silently reverted by the next sync | Reading the sync path |
| Stock movements not idempotent | A retried push counted a delivery twice | Integration test |
| Pull cursor jumped to "now" on a full page | A second device only received the oldest 2,000 sales | Integration test |
| Voids and removals never pushed | Other devices kept counting voided sales | Reading the sync path |
| Server minted new sale-line ids | A device pulling its own sale back held every line twice | Reading the sync path |
| Outbox cleared by entity id | An edit made during an upload was deleted unsent | Coordinator test |
| Pulled data never refreshed the screens | Updates from other devices stayed invisible | Coordinator test |
| Active store cached for the app's lifetime | After switching accounts, writes went to the previous owner's store | Reading the code |
| Sign-out left the outbox behind | The next person to sign in uploaded the previous owner's entries | Reading the code |
| Offline treated as a hard failure | Sync status showed an error instead of "offline" | Coordinator test |
| Stock pre-filled rounded to whole units | Saving a 2.5 kg product untouched recorded a count of 3 | Reading the editor |
| Router rebuilt on every auth change | Navigation reset; would have made the splash flicker | Reading the code |
| Redis connect retried for ~10 s | Boot stalled whenever Redis was down | First real run of the API |

Every fix is covered by a test, and the key server tests were checked by
re-introducing the bug and confirming the test fails.

### Still open

- The WebSocket **transport** (handshake, reconnect) has no automated test.
  The broadcaster is verified — a synced sale reaches its store's listeners
  and no other store's — but not the socket carrying it.
- Cross-instance event fan-out through Redis is untested; no Redis was
  available to test against.
- The Docker image has not been rebuilt since the crate became a library plus
  a binary. The Dockerfile was updated for it but not exercised.
- A local-only device keeps its outbox forever, since that outbox is what the
  cloud upgrade uploads. Fine at small-store volumes; compact it if storage
  ever becomes a complaint.

**Exit criteria:** two devices trading offline end with identical stock and
totals. ✅ Proven by the contract test against the live API.

---

## Phase 5 — Ready to hand to a real store

Everything needed before a stranger uses it unsupervised.

- [ ] A real logo to replace the placeholder — edit
      `frontend/assets/brand/source/kitaza_glyph.svg` and run `make brand`.
- [ ] Onboarding that seeds ~20 common sari-sari products so the catalogue is
      not empty on day one.
- [ ] Barcode scanning for products.
- [ ] Receipt printing / sharing (thermal Bluetooth printers are common).
- [ ] Widget tests for the record-sale and record-expense flows.
- [ ] Crash and error reporting.
- [ ] Filipino (Tagalog) localisation. The UI already speaks in the owner's
      terms — *puhunan*, *utang* — but the interface language itself is English.
- [ ] Accessibility audit: screen reader labels, verified contrast, layout at
      1.4× text scale.
- [ ] Automated database backup and a restore path.

**Exit criteria:** five real stores using it for two weeks without the founder
in the room.

---

## Phase 6 — Multi-device and staff

- [ ] Multiple stores per owner (the schema already supports it; the UI assumes
      one).
- [ ] Staff accounts with limited permissions — record sales, but not view
      profit or delete history.
- [ ] Audit log of who recorded and who voided what.
- [ ] A "signed-in devices" screen with remote revoke. Refresh tokens already
      carry a device tag for exactly this.

---

## Phase 7 — Revenue

- [ ] Subscription plans: Basic ₱99/month, Pro ₱199/month.
- [ ] Free tier that is genuinely useful — local-only mode, unlimited. Cloud
      sync, multi-device and staff accounts are what people pay for.
- [ ] GCash and Maya billing; card payments are rare in this market.
- [ ] Grace periods that never lock an owner out of their **own** records.
      Losing access to your sales history because a payment failed is the
      fastest way to lose a customer permanently.

---

## Phase 8 — Genuine intelligence

Only once there is enough real data to learn from.

- [ ] Demand forecasting per product to drive restock suggestions.
- [ ] Price recommendations from observed margin and turnover.
- [ ] Seasonality (payday cycles, fiestas, school openings — these dominate
      sari-sari demand).
- [ ] Anonymised benchmarks: "stores your size keep 18% margin on beverages".

Each of these must degrade to the Phase 3 rules when data is thin, and must
always show its reasoning.

---

## Risks and how the build answers them

| Risk from the brief | How this plan answers it |
|---|---|
| Owners dislike complex systems | Three buttons on the dashboard: Add sale, Expense, Profit. Five navigation destinations, no more. |
| Data entry discipline | Quick-amount keypad, no required fields beyond the amount, no network wait. |
| Competitors (Loyverse, Square, Shopify) | Offline-first on cheap Android hardware, peso-native, Filipino payment methods including utang, ₱99 pricing. |
| Owners prefer notebooks | Phase 5 exists entirely for this. Nothing else matters if the first week is confusing. |

## Non-goals, for now

Deliberately out of scope so they do not creep in: full accounting and BIR
filing, e-commerce, supplier ordering, payroll, and a customer loyalty
programme. Each is a product of its own.
