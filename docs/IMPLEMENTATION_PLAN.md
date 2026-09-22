# Kitaza — Implementation Plan

This is the build order for Kitaza, from the scaffold that exists today through
to a product small businesses pay for monthly. Phases 0–3 are **done and
verified**; 4 onward are planned.

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

## Phase 4 — Sync hardening

The sync path exists and is idempotent, but it has not been tested against a
real network doing real network things.

- [ ] Integration tests against a live Postgres: push the same batch twice and
      assert stock moves once. *(The re-push guard is written but only covered
      by reasoning, not by a test — this is the biggest hole in the codebase.)*
- [ ] Exponential backoff and a cap on retries for permanently rejected rows.
- [ ] A "sync problems" screen showing what was rejected and why, with a fix
      action — rejected rows currently sit in the outbox with their reason
      recorded but no way for the owner to see it.
- [ ] Multi-device conflict soak test: two devices editing the same product
      offline, then both reconnecting.
- [ ] Upgrade path from local to cloud mode, keeping existing local ids so the
      first sync uploads the full history rather than starting empty.
- [ ] WebSocket end-to-end test: sale on the counter tablet appears on the
      owner's phone.

**Exit criteria:** a week of simulated flaky-network trading ends with both
devices and the server holding identical totals.

---

## Phase 5 — Ready to hand to a real store

Everything needed before a stranger uses it unsupervised.

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
