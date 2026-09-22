# Kitaza

**Know where every peso goes.**

A budget-friendly POS, expense tracker and business-health dashboard for
sari-sari stores, carinderias, mini groceries, market vendors and other small
Philippine businesses.

Most small business owners know how much cash is in the drawer today. They do
not know where it went, which products actually earn, or whether the business
is genuinely profitable. Kitaza answers those three questions from entries that
take about five seconds each.

---

## What it does

| Feature | Notes |
|---|---|
| **Record a sale** | Tap an amount or pick products. Cash, GCash, Maya, bank transfer or utang. |
| **Record an expense** | Nine categories covering what a small store actually spends on. |
| **Profit** | Daily, weekly and monthly. Sales − cost of goods − expenses. |
| **Owner withdrawals** | Tracked separately from expenses, so profit stays honest. |
| **Business health score** | Green / Yellow / Red, always with the reasons in words. |
| **Inventory** | Stock in and out, automatic deduction on sale, low-stock warnings. |
| **Reports** | Profit trend, which products earn, where money goes, unusual spending. |
| **Offline or cloud** | Chosen at setup. Both are fully usable with no signal. |

## The three things that shape the whole design

**1. Every write is local first.** A sale is written to SQLite on the device and
returned to the UI immediately; syncing to the cloud is a separate, background
concern. Nothing in the app ever blocks on a network call. Reads come from
SQLite too — including the dashboard, which recomputes its own totals rather
than asking the server. A phone in airplane mode behaves identically to one on
wifi.

**2. Stock is a ledger, not a number.** Deliveries, counts and sales are all
movements, replayed in the order they happened. That is what lets two phones
sell the same product offline and still agree on the count afterwards.

**3. Sign in once per device.** A refresh token valid for six months lives in
the platform keystore. On launch the app restores the session from local
storage and goes straight to the dashboard; the access token is renewed
silently by an HTTP interceptor on the first request that needs it. In offline
mode there is no account and no password at all.

---

## Repository layout

```
kitaza/
├── backend/            Rust API — axum, sqlx/Postgres, Redis, WebSocket
│   ├── migrations/     Versioned SQL, applied on boot
│   └── src/
│       ├── application/    Router, state wiring, startup
│       ├── config/         Environment-driven settings
│       ├── features/       One directory per feature, vertically sliced
│       ├── infrastructure/ Database, cache, realtime, tracing
│       └── shared/         Errors, money, date ranges, validation
├── frontend/           Flutter app — Riverpod, go_router, SQLite
│   └── lib/
│       ├── app/            Entry point, router, theme host
│       ├── core/           Theme, formatting, storage, config, utils
│       ├── data/           Models, local DAOs, remote APIs, repositories
│       ├── features/       One directory per feature, screens + controllers
│       └── shared/         Reusable widgets
├── docs/
│   ├── IMPLEMENTATION_PLAN.md   Phased build plan
│   └── ARCHITECTURE.md          How the pieces fit and why
└── docker-compose.yml  Postgres + Redis + API
```

Both codebases are organised **by feature, not by layer**, and every feature
splits its routes, handlers, service, repository and payloads into separate
files. Finding the code for "expenses" means opening the `expenses` directory,
not grepping four parallel trees.

---

## Running it

### The app alone (offline mode — no backend needed)

```bash
cd frontend
flutter pub get
flutter run
```

Choose **"Just this phone"** at setup. Everything works: sales, expenses,
profit, reports, inventory. Nothing leaves the device.

### The full stack

```bash
cp backend/.env.example backend/.env       # then set KITAZA_JWT_SECRET
docker compose up --build
```

This starts Postgres, Redis and the API on `http://localhost:8080`. Migrations
run automatically on boot.

Point the app at it:

```bash
cd frontend
flutter run \
  --dart-define=KITAZA_API_URL=http://10.0.2.2:8080/api/v1 \
  --dart-define=KITAZA_WS_URL=ws://10.0.2.2:8080
```

`10.0.2.2` is how the Android emulator reaches the host. Use your machine's LAN
IP for a physical device.

### Using Supabase as the cloud database

Supabase is a managed Postgres, so it slots in as the API's database with no
code change — point `DATABASE_URL` at the Supabase connection pooler:

```bash
DATABASE_URL="postgres://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres"
```

The Kitaza API stays the single writer, which keeps every business rule
(profit maths, stock deduction, idempotent sync) in one place instead of being
half-enforced by row-level security. Deploy the API container anywhere — Fly,
Railway, a VPS — and keep Redis alongside it.

---

## Verifying

```bash
make check              # unit tests, clippy, analyzer, formatting — no services needed
make test-integration   # 15 backend tests against a real Postgres
make test-contract      # two simulated phones syncing through a running API
```

| Suite | Tests | Needs |
|---|---|---|
| Rust unit | 22 | nothing |
| Rust integration | 15 | Postgres (`TEST_DATABASE_URL`, defaults to the compose one) |
| Flutter | 62 | nothing — SQLite runs in memory |
| Sync contract | 1 | a running API (`CONTRACT_API`) |

The integration and contract suites are what prove sync works: pushes replay
safely, stock counts converge across devices, and a new device receives every
row. See `docs/IMPLEMENTATION_PLAN.md` for the defects they caught.

---

## Logo and splash screen

The current logo is a **placeholder**: a storefront with an awning. Every icon,
splash and in-app logo is generated from one file:

```
frontend/assets/brand/source/kitaza_glyph.svg
```

To use a real logo, replace that SVG with a single-colour, square artwork on a
transparent background and run:

```bash
make brand
```

This regenerates the Android (including adaptive and Android 12+ splash), iOS
and web launcher icons and native splash screens. It needs `rsvg-convert` and
ImageMagick 7. The brand colour and backgrounds are set at the top of
`frontend/tool/generate_brand_assets.sh` and in `flutter_native_splash.yaml`.

---

## Configuration

Backend settings all come from the environment — see `backend/.env.example`.
The ones that matter:

| Variable | Default | Why |
|---|---|---|
| `KITAZA_JWT_SECRET` | *(required)* | Must be ≥32 characters. `openssl rand -hex 32`. |
| `DATABASE_URL` | *(required)* | Postgres, including Supabase. |
| `REDIS_URL` | `redis://127.0.0.1:6379` | Optional — the API degrades gracefully without it. |
| `KITAZA_REFRESH_TOKEN_DAYS` | `180` | How long a device stays signed in. |
| `KITAZA_ALLOWED_ORIGINS` | `*` | Set to real origins in production. |
| `KITAZA_SYNC_SETTLE_MS` | `2000` | Holds back rows still being committed from a pull. |
| `KITAZA_SYNC_PAGE_SIZE` | `500` | Rows per table per pull; devices keep pulling while `has_more`. |

Frontend settings are `--dart-define` values, so one binary can target staging
or production: `KITAZA_API_URL`, `KITAZA_WS_URL`.
