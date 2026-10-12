# Event Budget

A Flutter app for planning events and keeping their budgets under control. It
targets Android and iOS, uses a Material 3 design with light and dark themes,
and stores everything locally on the device (SQLite).

## Features

- **Events**: weddings, birthdays, conferences, corporate events, parties and
  festivals, each with dates, a location, a status, a colour and a total budget.
  The home screen shows a countdown and budget progress for each event, plus
  totals across all active events.
- **Budget**: split the total into categories with allocated amounts. New events
  can start from a suggested split for their type. For each category you see
  committed and paid amounts and anything over budget.
- **Expenses and payments**: record the full cost of each expense, link it to a
  category and a vendor, set a due date and attach a receipt photo. Payments can
  be recorded in instalments (deposits, partial payments). Each expense is
  marked unpaid, partially paid, paid or overdue.
- **Overview dashboard**: a budget ring, spending by category (donut chart),
  alerts for overspending and overdue items, upcoming payments, task progress,
  RSVP counts and vendors booked.
- **Tasks**: a checklist grouped into overdue, upcoming, anytime and completed,
  with due dates and priorities. Swipe a task to delete it; undo is available.
- **Notes**: coloured, pinnable, searchable notes for each event.
- **Guests**: RSVP tracking, plus-ones, headcount, groups, tables and dietary
  needs, and one-tap call, text or email.
- **Vendors**: contact details, quotes, booking status and ratings, and the
  total committed to each vendor.
- **Export**: share an event's expenses as a CSV file.
- **Settings**: theme (system, light or dark), accent colour, currency (14
  currencies), sample data and a "delete all data" option.

## Getting started

```sh
flutter pub get
flutter run
```

On first launch, tap **Explore a sample event** to load a fully filled-in
wedding.

## Project layout

```
lib/
  main.dart, app.dart      entry point, opens the DB and shared preferences
  core/                    theme, formatting, money, palette, shared widgets
  data/
    models/                plain Dart models with toMap/fromMap
    database.dart          SQLite schema (foreign keys, cascades)
    daos.dart              queries; every write notifies the UI
    event_overview.dart    dashboard calculations (pure Dart)
    budget_templates.dart  suggested category splits per event type
    sample_data.dart       demo event
    csv_export.dart
  state/                   Riverpod providers and settings
  features/                one folder per screen or tab
test/                      model, database (real SQLite via FFI) and widget tests
```

### How data flows

The DAOs write to SQLite and then bump `dataRevisionProvider`. Every query
provider watches that counter, so any write refreshes whatever is on screen.
The screens never need to invalidate providers by hand.

## Tests

```sh
flutter analyze
flutter test
```

The widget test walks through the empty state, loads the sample event and
opens every tab. It runs on a large phone in light mode and a small phone in
dark mode.
