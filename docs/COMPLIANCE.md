# Compliance

What the code does about Philippine law, and what it cannot do for you.

> **This is engineering, not legal advice.** The documents in the app are
> drafts written to be honest about what Kitaza actually does. Before you take
> money from a stranger, have a Philippine lawyer read them, and read this
> page. Several things below can only be done by the person who owns the
> business.

---

## Before launch: what only you can do

| | Why |
|---|---|
| **Register the business** and put its real name and address into `legalOperator` in both `.arb` files | Every privacy notice must say who holds the data. `make release-apk` refuses to build while the placeholder is there. |
| **Appoint a Data Protection Officer** and put their address into `legalContact` | Required of every personal information controller by NPC Circular 16-01. It may be you. |
| **Register with the National Privacy Commission** at register.privacy.gov.ph | Required once you process the personal data of 1,000 or more people, or employ 250+. Do it before you reach that, not after. |
| **Host the privacy notice on a public web page** | Google Play will not accept an app that handles personal data without a policy URL, and the URL must work before review. |
| **Have a lawyer read the terms**, especially refunds and the liability limit | A limitation of liability that overreaches is unenforceable, and the Consumer Act (RA 7394) does not let you contract out of everything. |
| **Write down your breach procedure**: who decides, who notifies, within 72 hours | The law sets the deadline; nothing in the code can meet it for you. |
| **Read PayMongo's terms** and keep your merchant records | They are the payment processor. Their obligations are theirs; yours are yours. |

---

## What the code already does

### Consent (RA 10173 §3(b), §12)

Registration is **refused** without the version of the privacy notice and the
terms the person was shown. It is not recorded with a shrug and sorted out
later: an account made without consent is one there is no lawful basis to
hold.

- `consent_records` stores what was agreed, which version, and when.
- Raising `LegalDocument::current_version` on the server and
  `LegalDocument.currentVersion` on the phone puts every account into
  `outstanding`, and the app asks again.
- The box is never pre-ticked, and both documents open from beside it.

### Right to be informed (§16(a))

The privacy notice ships **inside the app**, in English and Filipino, and is
readable without signing in and without signal. Settings → Your data and
privacy shows where the records are and what was agreed to, and when.

### Right to access and to portability (§16(c), §18)

Settings → Download my records.

- An **offline** store shares its own backup file. Nothing was ever sent to us.
- A **cloud** store gets `GET /account/export`: every table keyed to that
  owner, as indented JSON. Plain JSON on purpose - a copy you can only open in
  Kitaza is not really a copy.

### Right to erasure (§16(e))

Settings → Close my account, confirmed by typing the store's name.

- Deleting a year of books on one tap would be its own disaster, so it is
  scheduled, not immediate: `KITAZA_DELETION_GRACE_DAYS`, 30 by default. The
  owner can call it off for the whole window.
- After that the retention sweep deletes the `owners` row, and everything
  cascades: stores, products, sales, expenses, staff, devices, activity,
  consent records, error reports.
- What survives is `accounting_records`: amount, date, plan and gateway
  reference, **with no owner column at all**. A business must be able to
  account for money it received. A test asserts that table can never name a
  person.

### Retention limits (§11(e))

A sweep runs every six hours and enforces these:

| Record | Kept for | Setting |
|---|---|---|
| Business records | While the account is open | — |
| Activity log | 2 years | `KITAZA_KEEP_ACTIVITY_DAYS` |
| Error reports | 90 days | `KITAZA_KEEP_ERROR_REPORTS_DAYS` |
| Signed-out devices | 1 year | `KITAZA_KEEP_DEVICES_DAYS` |
| Closed accounts | 30 days, then purged | `KITAZA_DELETION_GRACE_DAYS` |

### Data minimisation (§11(c))

The thing Kitaza does best here is **not collect**:

- **No customer data at all.** A sale is an amount and its items; `utang` is a
  payment method, not a person. No customer name, number or address is asked
  for or stored anywhere. This is worth knowing, because it is what keeps a
  store owner from becoming a personal information controller for their
  customers just by using the app.
- **No payment details.** Card numbers and GCash credentials go to PayMongo.
  The server is told a payment succeeded and for how much.
- **No location, contacts or device scanning.** The camera is used while the
  barcode scanner is open and not otherwise.
- **An offline store sends nothing.** Not a setting we could reverse; there is
  no account on a server at all.

### Anonymity in the comparisons (§3(l))

Benchmarks publish medians only, per business type and size band, across at
least 20 other sharing stores. Sharing is opt-out in Settings, and switching
it off also switches off seeing everyone else's. A test asserts the threshold.

### Security (§20)

Passwords are Argon2 hashes. Access tokens carry a session id resolved on
every request, so revoking a device ends it within seconds. Traffic is TLS.
The activity log records who did what, which is what a breach investigation
needs.

---

## What is not done, and is not pretended to be

- **Nobody has reviewed these documents legally.** They are drafts.
- **No NPC registration exists.** Nor a DPO, nor a published policy URL.
- **The breach procedure is written here, not practised.** Seventy-two hours
  is not long to work out who to ring.
- **No Data Protection Impact Assessment** has been done. The NPC expects one
  where processing is likely to pose a risk; the benchmark pooling is the part
  worth assessing.
- **The Filipino text has not been read by a lawyer or a native speaker**,
  and it is the version most owners will read.
- **BIR is out of scope**, deliberately and loudly. The app says in its own
  terms that it is not a filing tool and its figures are not a return. If that
  ever stops being true, this page is the first thing that has to change.
