# Event Budget on Google Play

Everything the Play Console asks for, in the order it asks. Signing and
building the upload are in [RELEASING.md](../RELEASING.md).

## Store listing

The text, icon (512 × 512), feature graphic (1024 × 500) and screenshots are
in `fastlane/metadata/android/en-US/`. Copy them into **Grow → Store presence → Main store
listing**, or upload them with `fastlane supply` if you use fastlane.

| Field | Answer |
| --- | --- |
| App or game | App |
| Category | Productivity |
| Tags | Event planning, Budgeting |
| Free or paid | Free |
| Privacy policy | https://kidus.pro.et/privacy/event-budget/ |

The privacy policy is a page on the portfolio site (`frontend/` in the
Kstore repo). The URL above works once the portfolio is deployed at
kidus.pro.et; if it's hosted elsewhere, use that address with
`/privacy/event-budget/`.

## Data safety

**Does your app collect or share any of the required user data types?** No.

Event Budget has no internet permission. Events, expenses, guests (including
any names, numbers and emails typed in), vendors and receipt photos are
stored only on the phone. Sharing a summary or CSV goes through Android's
share sheet at the person's request, which Google doesn't count as sharing
by the app.

## Permissions

| Permission | Why | Console |
| --- | --- | --- |
| None declared | Receipt photos come from the camera app or the system photo picker, which need no permission | Nothing to declare |

## Content rating (IARC questionnaire)

Category **Utility, Productivity, Communication or other**. Answer **No** to every question. Expected rating: **Everyone / PEGI 3**.

## Target audience

**18 and over** (or 13 and over).

## Store settings

| Field | Answer |
| --- | --- |
| Contact email | kidyoh789@gmail.com |
| Website | https://kidus.pro.et |
| Ads | No, the app has no ads |
| App access | All functionality is available without special access (no login) |
| Government app | No |
| Financial features | None |
| Health | None |

## Notes

- Category: **Productivity** (or **Finance**; Finance brings in the financial features declaration, so Productivity is simpler).
