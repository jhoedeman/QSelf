# Quantified Self Tracker — Project Brief for Claude Code

This document is the source of truth for building the Quantified Self Tracker iOS app. Read it
fully before writing any code. It captures all design decisions, data model definitions,
architecture choices, freemium gating rules, and MVP build order.

---

## What this app is

A personal health tracking app for people who actively manage their wellbeing through
supplements, peptides, injectables, and lifestyle interventions. The core loop is:

1. Receive a notification, log mental and physical state in ~30 seconds
2. Mark regimen doses as taken throughout the day
3. Log bloodwork when drawn
4. Review trends charts that correlate wellbeing scores with regimen events and lab levels

This is a single-user, privacy-first app. All data lives in the user's iCloud private
container. No backend, no server, no third-party analytics.

---

## Tech stack

- **Swift + SwiftUI** — iOS 17+ minimum (required for SwiftData)
- **SwiftData** — persistence, with CloudKit sync via `.cloudKitDatabase: .automatic`
- **SwiftCharts** — trends visualisation
- **StoreKit 2** — one-time purchase for Pro tier
- **UserNotifications** — daily log reminders, injection-day nudges, labs-due nudge
- **PDFKit / Vision** — PDF lab import (post-MVP, do not build in v1)

---

## Freemium model

**One-time purchase**, not a subscription. Single StoreKit 2 product:
`com.app.quantifiedself.pro.lifetime`

Store unlock state in `UserDefaults.standard.bool(forKey: "isPro")`.
Support restore purchases. No server-side receipt validation needed for a one-time IAP.

### Free tier
- Up to **15 active regimen items**, drawn from the 15 free catalog items only
- Up to **3 active custom medications** — user-created items in the `.medication` category
  (see "Custom medications" below). This is a separate counter from the 15 catalog slots.
- All 12 wellbeing metrics (show/hide/reorder is available to all users)
- All mood tags
- Lab tracking (number of panels TBD — do not gate labs in MVP, discuss separately)
- Basic trends charts (7 metrics, up to 12-week window)

### Pro tier (unlocked by purchase)
- **Unlimited** active regimen items
- Full catalog: peptides, nootropics, injectables, hormonal support, longevity compounds
- **Custom regimen items** — user-defined name, dose, schedule, any category
- **Unlimited custom medications** (no separate cap — the free tier's 3-item limit simply
  doesn't apply)
- Advanced chart window (up to 1 year)
- Appointment summary PDF export

### Custom medications (available to all tiers)

Free users normally cannot create custom (non-catalog) regimen items at all — that's a Pro
feature. **Custom medications are the one carve-out.** Prescription/psychoactive drugs (SSRIs,
stimulants, mood stabilizers, etc.) aren't in the static catalog and don't belong there, but
users need to log them regardless of tier to correlate against mental-state metrics — that's
a core use case for this app, not a premium add-on.

- A custom medication is a `RegimenItem` with `catalogId == nil` and `category == .medication`
- Free tier: capped at `RegimenLimits.maxFreeCustomMedications` (3) active custom medications
- Pro tier: unlimited (no check — same as the rest of Pro's unlimited items)
- Gate the count with `DataService.activeCustomMedicationCount(context:)` before allowing
  creation; when a free user hits the cap, the "+ Add" button on the custom-medication form
  opens the upgrade prompt (not an error)
- This limit is independent of the 15-item free catalog cap — a free user can have 15 catalog
  items *and* 3 custom medications at once

### Gating rules in the UI
- Locked catalog items are **always visible** — show with a lock badge
- Tapping a locked item opens an upgrade prompt sheet, not an error message
- The free slot counter ("X of 15 slots used") is shown at the top of the catalog screen
- The free custom-medication counter ("X of 3 custom medications") is shown wherever custom
  medications are added/managed
- When the user hits either limit, the "+ Add" button opens an upgrade prompt
- Never hide Pro features entirely — letting the user see what they're missing is intentional

---

## App structure — 5 tabs

```
TabView
├── Log          (pencil icon)     — daily wellbeing check-in
├── Regimen      (pill icon)       — today's compliance + manage items
├── Labs         (testpipe icon)   — bloodwork tracking
├── Trends       (chart.line icon) — swimlane correlation charts
└── Settings     (settings icon)   — notifications, metric layout, account, IAP
```

---

## Data model

All SwiftData models are in `QS_Models.swift`. Key architectural decisions:

- All stored properties must be **optional or have defaults** for CloudKit compatibility
- Computed properties cannot sync — store derived values explicitly and recompute on save
- `WellbeingMetric` is an enum in code; `MetricValue` records store values per log
- Metric **visibility and order** are stored in `UserDefaults` (not SwiftData) as
  `MetricPreferences` — these are device-local display preferences, not synced data
- The regimen **catalog** is static data compiled into the app (`QS_RegimenCatalog.swift`),
  not stored in SwiftData. `RegimenItem.catalogId` references a catalog entry by ID.

### Model summary

| Model | Purpose |
|---|---|
| `DailyLog` | One per calendar day; owns MetricValues and MoodTags |
| `MetricValue` | One per WellbeingMetric per DailyLog |
| `MoodTag` | Pre-seeded tags, many-to-many with DailyLog |
| `RegimenItem` | One supplement/peptide/injectable in the user's protocol |
| `DoseSlot` | One dose event per day owned by a RegimenItem |
| `ComplianceRecord` | One per DoseSlot per day — taken / missed / skipped / partial |
| `LabResult` | One per individual lab value; grouped by date in the UI |

### Schedule types on RegimenItem

```
.daily          — taken every day (most supplements)
.daysOfWeek     — taken on specific weekdays (scheduledWeekdays: [Int], 1=Sun)
.cyclic         — N days on, M days off (cycleDaysOn, cycleDaysOff, cycleAnchorDate)
```

On top of the short-cycle schedule, a **long-cycle protocol** can be layered
(hasLongCycle = true): e.g. 8 weeks active / 4 weeks rest. The short-cycle schedule
applies only within an active long-cycle window.

`RegimenItem.isScheduled(on:)` encapsulates all this logic — call it for any date
to determine if a dose is expected.

---

## Compliance fill job

This is the most important background job in the app. It runs every time the app
becomes active (foreground).

**Algorithm:**
1. Fetch all `RegimenItem` records where `isActive == true`
2. For each item, determine the date range to fill:
   - Start: `max(item.startDate, today - 30 days)` (cap at 30 days to avoid unbounded writes)
   - End: `today - 1 day` (today's slots are handled by the UI, not the fill job)
3. For each date in range, call `item.isScheduled(on: date)`
4. If scheduled: for each `DoseSlot`, check if a `ComplianceRecord` already exists
   - If a record exists AND `editedByUser == true`: skip — never overwrite user edits
   - If no record exists: create one with `status: .missed`, `isRetroactive: true`
5. For the next 7 days: create `ComplianceRecord` records with `status: .pending`
   (so the regimen tab can display upcoming doses)

Run this job in a Swift concurrency `Task` off the main actor to avoid blocking the UI.
Use a `@AppStorage` key to track the last fill date and skip the job if it already ran today.

---

## Screen specifications

### Log tab

The daily check-in screen. One `DailyLog` per calendar day.
If a log exists for today, pre-populate the form (edit mode). Otherwise create on save.

**Sections:**
1. **Mental metrics card** — shows visible metrics in the Mental group, in user-defined order.
   Each row: drag handle (reorder in Edit mode), metric name, slider, value.
   Hidden metrics are shown dimmed at the bottom of their card with a note.
2. **Physical metrics card** — same, for Physical group metrics.
3. **Mood tags** — pre-seeded 23 tags as multi-select pills.
4. **Note** — optional free-text textarea.
5. **Save button**

**Edit mode** (triggered by "Edit" button in header):
- Rows become draggable (Long-press + drag reorder)
- Each row has a show/hide toggle
- Changes save to `MetricPreferences` in UserDefaults on dismiss

**Metric list (12 total):**

| Key | Display name | Group | Scale | Higher = better |
|---|---|---|---|---|
| mood | Mood | Mental | 1–10 | ✓ |
| focus | Focus | Mental | 1–10 | ✓ |
| motivation | Motivation | Mental | 1–10 | ✓ |
| anxiety | Anxiety | Mental | 1–10 | ✗ |
| stress | Stress | Mental | 1–10 | ✗ |
| energy | Energy | Physical | 1–10 | ✓ |
| recovery | Recovery | Physical | 1–10 | ✓ |
| physicalPerformance | Performance | Physical | 1–10 | ✓ |
| sleepQuality | Sleep quality | Physical | 1–10 | ✓ |
| sleepHours | Sleep hours | Physical | 3–12 | ✓ |
| jointPain | Joint pain | Physical | 0–10 | ✗ |
| libido | Libido | Physical | 1–10 | ✓ |

**Default visible:** energy, mood, focus, recovery, sleepQuality, sleepHours, jointPain

### Regimen tab

Two sub-views: today's compliance view (default) and a manage/history view.

**Today's compliance view:**
- Date bar at top showing today's date and "X of Y taken" compliance count
- Items grouped by `DoseSlot.timeOfDay` (Morning / Pre-workout / Post-workout / Afternoon / Evening / Before bed)
- Each item row: icon (by category), name, dose + timing, check circle
  - Check circle states: pending (outline) → tap → taken (filled green)
  - Long-press on a taken item → sheet with options: Mark as skipped / Adjust dose / Add note
- Injectables show their next scheduled date when not due today (dimmed row)
- "Not today" section for items scheduled on other days
- "+ Add" button in header → catalog screen

**Compliance check circles — tap logic:**
- pending → taken (one tap)
- taken → long-press → skipped or partial (never one-tap back to missed —
  the user actively chose to take it)

**Manage view** (tab or segmented control within Regimen tab):
- List of all active regimen items
- Tap to edit: schedule, dose slots, cycle protocol, notes
- Swipe to archive (sets endDate = today, isActive = false)
- History section showing archived items

**Add injection sheet** (for isInjectable items, shown when marking as taken):
- Site picker (Left thigh / Right thigh / Left glute / Right glute / Abdomen / Other)
- Shows last used site as a hint
- Saves site to `RegimenItem.lastInjectionSite`

### Labs tab

Identical concept to the TRT app's Labs tab but not pre-populated with a specific panel.
The set of standard lab panels for this app is TBD — do not pre-populate in v1;
let users add any test manually.

- Lab results grouped by draw date, most recent first
- Each result row: test name, value, unit, range dot (green/red)
- "+ Add draw" button → sheet with date, lab name, and dynamic test rows
- Each test row: name, value input, unit, live range dot, reference range
- `isInRange` computed on save
- "Export for appointment" → PDF (Pro feature, same approach as TRT app)
- PDF import: disabled button with "Coming soon" label

### Trends tab

Same swimlane architecture as the TRT app (`TrendsCharts.swift` in that project is a
reference implementation), adapted for this app's richer data.

**Swimlane 1 — Wellbeing scores:**
- `LineMark` per visible metric, `.catmullRom` interpolation
- Metric colour coded by type (mental = purple family, physical = green/teal family)
- Regimen events shown as vertical `RuleMark` lines, coloured by item category
  - Rather than just "dose change" markers, show any regimen item's start/stop dates
  - Optionally filter by item using a picker above the chart
- Y-axis: 0–10 (sleepHours 0–12)

**Swimlane 2 — Lab results:**
- Same normalised % of reference range approach as TRT app
- Y-axis: −20 to 120
- Green band at 0–100% = in-range zone
- `PointMark` per result, dashed connecting line per test series
- Dose/regimen event rules shared with swimlane 1

**Window selector:** 4 wks / 12 wks / 6 mo / 1 yr
(1 yr is Pro-only — show with lock badge in free tier)

**Correlation hint** (Pro only):
"Average [metric] was X in the 4 weeks before [event] and Y in the 4 weeks after."
Descriptive, not diagnostic.

### Settings tab

Sections:

**Notifications:**
- Daily log reminders: on/off, frequency (1/2/3 per day), active window (start/end time)
- Injection day reminders: on/off, time
- Labs due nudge: on/off (fires ~90 days after last LabResult date)
- Notification preview showing lock-screen appearance

**Metrics:**
- Shortcut to the same Edit mode available from the Log tab header
- Show/hide toggles and drag-to-reorder for all 12 metrics

**Pro / Account:**
- If free: "Upgrade to Pro" with feature list and price
- If Pro: "Pro — purchased [date]" and "Restore purchases" button
- Always show "Restore purchases" link

---

## Onboarding flow

Full-screen modal gated by `UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")`.

**Screen 1 — Welcome:**
App icon, title, 3-feature summary, privacy statement ("your data stays on your device and
iCloud, never shared"), "Get started" CTA.

**Screen 2 — What are you tracking? (optional framing):**
Simple question helping the user understand the app's scope. Not a filter — everyone
gets the same app. Just sets expectations. Skip button.

**Screen 3 — Build your regimen:**
- Catalog browser (free tier only until purchase)
- User picks their first 1–5 items with dose confirmation
- "Skip — I'll set this up later" ghost button

**Screen 4 — Notifications:**
- Frequency picker + time window (same as Settings tab)
- "Enable reminders" → `UNUserNotificationCenter.requestAuthorization`
- "Skip" ghost button

**Screen 5 — All set:**
- Summary of items added
- "Log today" CTA → dismisses to Log tab

On completion: set `hasCompletedOnboarding = true`, seed `MoodTag` records (idempotent).

---

## Architecture notes

### ProGate view modifier

Create a `ProGate` modifier that wraps any view in an upgrade prompt overlay when
`isPro == false`. Used for: catalog items, the 1yr chart window, correlation hint,
appointment export button.

```swift
struct ProGateModifier: ViewModifier {
    @AppStorage("isPro") var isPro = false
    let feature: String

    func body(content: Content) -> some View {
        if isPro {
            content
        } else {
            content.overlay(UpgradePromptView(feature: feature))
        }
    }
}
```

### ComplianceService

Extract the fill job and compliance querying into a `ComplianceService` actor:

```swift
actor ComplianceService {
    func runFillJob(context: ModelContext) async
    func complianceRate(for item: RegimenItem, in range: ClosedRange<Date>, context: ModelContext) async -> Double
    func todaysRecords(context: ModelContext) async -> [ComplianceRecord]
}
```

### DataService

Same pattern as the TRT app — a service layer owning common queries so views stay thin:

```swift
func todaysLog(context: ModelContext) throws -> DailyLog?
func logs(in range: ClosedRange<Date>, context: ModelContext) throws -> [DailyLog]
func labResults(for testName: String, context: ModelContext) throws -> [LabResult]
func activeRegimenItems(context: ModelContext) throws -> [RegimenItem]
func regimenEvents(in range: ClosedRange<Date>, context: ModelContext) throws -> [RegimenEvent]
```

`RegimenEvent` is a value type (not a model) representing a regimen item's start, stop, or
cycle transition — synthesised from `RegimenItem` records for use in the trends chart.

### StoreKit 2 purchase flow

```swift
// In PurchaseService
func purchase() async throws {
    let products = try await Product.products(for: ["com.app.quantifiedself.pro.lifetime"])
    guard let product = products.first else { return }
    let result = try await product.purchase()
    if case .success(let verification) = result,
       case .verified(let transaction) = verification {
        UserDefaults.standard.set(true, forKey: "isPro")
        await transaction.finish()
    }
}

func restorePurchases() async {
    for await result in Transaction.currentEntitlements {
        if case .verified(let transaction) = result,
           transaction.productID == "com.app.quantifiedself.pro.lifetime" {
            UserDefaults.standard.set(true, forKey: "isPro")
        }
    }
}
```

### SwiftUI previews

Pass `cloudKit: false` and `isStoredInMemoryOnly: true` in all `#Preview` blocks.
Create a `PreviewData` helper that inserts a realistic set of `RegimenItem`,
`ComplianceRecord`, `DailyLog`, and `LabResult` records so every screen previews
with real data.

### Migration plan

Create a `MigrationPlan` enum from day one, even with a single schema version.
Additive changes (new optional field with default) use lightweight migrations.

---

## First-launch seed data

**MoodTag seeds** (23 tags — check count > 0 before inserting, idempotent):
```
Good, Calm, Motivated, Focused, Confident, Optimistic, Sharp, Content, Grateful,
Irritable, Anxious, Restless, Overwhelmed, Stressed,
Flat, Tired, Brain fog, Low mood, Burnt out,
Sore, Inflamed, Wired, Crashed
```

**Default metric visibility** (from `WellbeingMetric.defaultVisible`):
energy, mood, focus, recovery, sleepQuality, sleepHours, jointPain

---

## MVP build order

Build and test each item before starting the next.

1. **Project setup** — Xcode project, CloudKit entitlement, StoreKit configuration file,
   `makeContainer` in App entry point, MoodTag seed, MigrationPlan stub
2. **Log tab** — the core habit loop; MetricPreferences in UserDefaults, Edit mode
3. **Onboarding** — required before regimen is usable
4. **Regimen tab** — catalog browser, add items, today's compliance view, ComplianceService fill job
5. **Settings tab** — notifications (UNUserNotificationCenter), metric edit, Pro/IAP
6. **Labs tab** — add draw sheet (manual entry only), results list
7. **Trends tab** — swimlane charts (reference `TrendsCharts.swift` from the TRT project)
8. **Pro IAP** — StoreKit 2 purchase + restore, ProGate modifier, slot counter enforcement
9. **Appointment export** — PDF generation (Pro only)

Do not build: PDF lab import, wearable HRV sync, social/sharing features.

---

## Files in this project

| File | Status | Notes |
|---|---|---|
| `QS_CLAUDE.md` | ✅ Complete | This file |
| `QS_Models.swift` | ✅ Complete | All SwiftData models + makeContainer + MetricPreferences |
| `QS_RegimenCatalog.swift` | ✅ Complete | 15 free + 22 Pro catalog items with defaults |
| `ComplianceService.swift` | 🔲 Not started | Fill job + compliance query actor |
| `DataService.swift` | 🔲 Not started | Common SwiftData query layer |
| `PurchaseService.swift` | 🔲 Not started | StoreKit 2 one-time purchase + restore |
| `ProGate.swift` | 🔲 Not started | ViewModifier for gating Pro features |
| `LogView.swift` | 🔲 Not started | Log tab + Edit mode |
| `RegimenView.swift` | 🔲 Not started | Today's compliance + manage view |
| `CatalogView.swift` | 🔲 Not started | Add items catalog with tier gating |
| `LabsView.swift` | 🔲 Not started | Labs tab + add draw sheet |
| `TrendsView.swift` | 🔲 Not started | Swimlane charts |
| `SettingsView.swift` | 🔲 Not started | Notifications, metrics, IAP |
| `OnboardingView.swift` | 🔲 Not started | 5-screen onboarding flow |
| `NotificationService.swift` | 🔲 Not started | UNUserNotificationCenter scheduling |
| `AppointmentSummaryView.swift` | 🔲 Not started | PDF export (Pro) |
| `MigrationPlan.swift` | 🔲 Not started | SwiftData schema versioning |
| `PreviewData.swift` | 🔲 Not started | Sample data for SwiftUI previews |
