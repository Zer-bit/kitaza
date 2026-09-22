# Kitaza — Implementation Plan

This is the build order for Kitaza, from the scaffold that exists today through
to a product small businesses pay for monthly. Phases 0–6 are **done and
verified** as far as they can be without real phones and real stores (Phases
5 and 6 list exactly what that leaves); 7 onward are planned.

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

## Phase 5 — Ready to hand to a real store ✅ Done (pending field trial)

Everything needed before a stranger uses it unsupervised.

- [x] **Filipino localisation.** Every screen in English and Filipino, chosen
      automatically from the phone or set in Settings. Owner-facing server
      errors (wrong password, email taken, too many attempts) are translated
      on the phone from the server's error codes.
- [x] **Accessibility audit.** Every main screen is checked on a 360×640 phone
      at 1.4× text, in light and dark, in both languages, empty and full of
      data, against Flutter's tap-target, labelling and contrast guidelines —
      60 checks — plus 31 measured colour-pair contrast ratios. The profit
      chart, health banner and keypad have spoken descriptions.
- [x] **Widget tests for the sale and expense flows**, driven through the
      real screens against a real database, in both languages.
- [x] **Starter catalogue.** 23 common sari-sari items offered as a reviewable
      checklist, with a clear warning that the prices are typical, not the
      owner's. Offered on the dashboard and the empty product list.
- [x] **Barcode scanning.** Checkout scanning with the camera held open,
      scanning a product's code in the editor, unknown codes offered as new
      products, and USB/Bluetooth barcode guns through the product search.
- [x] **Receipts.** Shared as text to Messenger/Viber/SMS, or printed on a
      Bluetooth ESC/POS thermal printer (58 or 80 mm), chosen in Settings.
- [x] **Crash and error reporting.** Uncaught errors kept on the phone,
      de-duplicated and capped; uploaded by cloud stores to our own endpoint,
      shareable to support from offline stores. No third-party service.
- [x] **Backups.** On the phone: a daily automatic copy (a week kept), an
      exported copy to send anywhere, and restore — including onto a new
      phone from the welcome screen. On the server: a scheduled `pg_dump`
      service with 14-day retention and a guarded restore script.
- [ ] **A real logo** — yours to provide. Replace
      `frontend/assets/brand/source/kitaza_glyph.svg` and run `make brand`.

### Defects found and fixed

| Defect | Effect | Caught by |
|---|---|---|
| Record-sale screen overflowed 94 px on a 360×640 phone | **Save button unreachable** on common budget phones | Sale flow test |
| Scan button squeezed the app bar title at large text | "Add sale" faded to invisible (contrast 1.00:1) | Contrast guideline |
| A wrong password showed "Your session expired" | Confusing sign-in errors | Reading the error path |
| Filipino plurals: "1" shown for 2, 3, 5, 7, 8, 11, 23… | "1 benta" on the dashboard for 3 sales | Starter catalogue test |
| Editing a product reset its unit to "pc" and wiped its barcode | A per-kilo item became per-piece after a price change | Reading the editor |
| Light-mode Good/Average health headlines at 4.42 and 4.44:1 | Under the WCAG AA minimum the docs claimed was met | Measured contrast test |
| Empty states, stat cards, health banner, product rows overflowed at large text | Clipped text for older owners | Accessibility audit |
| A plain file copy of the database missed recent writes | **Backups silently incomplete**, even missing tables | Backup test, confirmed by removing the fix |

### What is not verified, and why

These need hardware or people this environment does not have. None is a known
problem; each is simply untested.

- **On a real phone.** There is no Android SDK or device here. The app has
  been compiled (release web build), analysed and tested against a real
  SQLite engine, but never launched on Android or iOS.
- **Live camera scanning.** The scanning logic is tested; the camera screen
  has only been compiled.
- **Bluetooth printing.** The receipt layout and the exact ESC/POS bytes are
  tested; the Bluetooth link to a physical printer is not.
- **The Filipino wording.** Written for how owners talk at the counter, but it
  needs review by a native speaker before real stores see it.
- **The Docker backup service.** The scripts were run for real against
  Postgres 18 (backup, restore, identical content afterwards); the compose
  service wrapping them was validated but not run, as Docker is unavailable.

**Exit criteria:** five real stores using it for two weeks without the founder
in the room. Everything above is ready for that trial; the trial itself is
yours to run.

---

## Phase 6 — Multi-device and staff ✅ Done

All of it needs a cloud account; an offline store's Settings says so and
links to the cloud upgrade. That matches Phase 7, where these are what people
pay for.

- [x] **Multiple stores per owner.** Add and rename stores in Settings, switch
      from the store name on the dashboard. Every store's records stay on the
      phone, so switching is instant and works offline. Each queued change
      remembers its store and uploads there even after a switch; each store
      has its own download cursor.
- [x] **Staff accounts.** The owner adds someone by name and gets a one-time
      join code (`ABCDE-FGHJK`, one phone, one day). No email or password.
      Staff always sell; four switches add managing products, recording
      expenses, seeing profit and costs, and voiding or deleting.
- [x] **Enforced by the server, not just hidden.** Every sync row is checked
      against the sender's permissions. A phone without profit access is
      never sent a cost figure, an expense or a withdrawal, and its sales are
      costed from the catalogue so the owner's profit stays right. Staff may
      retry their own entries but never rewrite someone else's.
- [x] **Activity log.** Who recorded, changed, counted, voided and deleted
      what, on which phone and when it happened, with a "voids and
      deletions" filter. Written once per real change, so retries are not
      double-counted.
- [x] **Signed-in devices** with remote sign-out. Revoking a phone, removing a
      staff member or changing a permission takes effect on the next request,
      not when the access token expires.
- [x] **A signed-out phone says so.** It shows how many entries never reached
      the cloud and offers the way back in; the same person signing back in
      keeps those entries, anyone else starts clean.

### Defects found and fixed

| Defect | Effect | Caught by |
|---|---|---|
| Upserts matched on id alone | **A phone could overwrite another store's product, sale, expense or withdrawal** by sending its id | Reading the push path, now tested |
| A voided sale sent again was re-applied | A live stock deduction for a sale that no longer exists: the ledger disagreed with the stock count | Test, confirmed by removing the fix |
| Any failed session renewal wiped the phone's tokens | **An owner on weak signal was signed out** when their hourly token lapsed | Reading the interceptor, confirmed by removing the fix |
| A renewal whose answer was lost locked the phone out | The server had retired the token the phone still held | Reading the refresh path |
| A phone whose session ended had no way back | Syncing failed silently; after a restart, signing in as someone else **uploaded the previous person's unsent entries into the new account** | Reading session restore |
| Three count messages were missing from the plural check | Their wording was right, but nothing guarded it | A new check that lists every count message |

One more was caught in my own change before it shipped: moving a local store
to the cloud did not re-address its queued changes to the cloud store.

### What is not verified, and why

- **On a real phone**, as in Phase 5, including the device names shown in the
  device list.
- **More than one server instance.** A revoke or permission change reaches
  other instances within 20 seconds by design; only one instance was run.
- **The live socket.** The `access_changed` nudge and closing a revoked
  phone's socket are built and their parts tested, but not over a real
  WebSocket.
- **The Filipino wording** of the 115 new strings, which needs the same
  native review as Phase 5's.
- **The Docker image**, still not rebuilt since Phase 4.

Not built, deliberately: deleting a store (its history would go with it), and
switching between owner and staff on one shared phone.

**Exit criteria:** an owner and a cashier on separate phones trade for a day,
the owner's books are right to the centavo, and the log names who did what.
✅ Proven by the contract test against the live API: the cashier's phone
never holds a cost, its sale is costed correctly, its forbidden edits are
refused, and signing it out stops it.

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
