# Tether iOS TestFlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Build an English-only, iPhone-only Tether v0.1 that supports one habit, Done/Light/Rest check-ins, Tether and Reconnect calculations, 30-day history, local reminders, settings, reset, and installation through TestFlight for one-person dogfooding.

**Architecture:** Use a SwiftUI app with pure Swift domain logic, SwiftData behind a small store protocol, feature-scoped observable view models, and UserNotifications behind a scheduler protocol. Keep date/Tether calculations independent from UI and persistence so boundary behavior can be exhaustively tested. Persist only source records; derive Current Tether, Best Tether, phases, counts, and history rows.

**Tech Stack:** Xcode 26.5, Swift 6.3, SwiftUI, SwiftData, Observation, UserNotifications, Swift Testing for unit/integration tests, XCTest/XCUIAutomation for UI tests, iOS 17 minimum, no third-party packages.

## Global Constraints

- Product requirements are defined in docs/product/tether-prd-v0.1.md.
- Target iPhone only; set TARGETED_DEVICE_FAMILY to 1.
- Set IPHONEOS_DEPLOYMENT_TARGET to 17.0.
- Use Swift 6 language mode and complete concurrency checking.
- UI and user-visible dates must be English only.
- Format visible dates with Locale(identifier: "en_US") while calendar-day boundaries continue to use the device's current Calendar and time zone.
- Display name is Tether.
- Initial bundle identifier is com.fredjeong.tether; change it only if the Apple Developer portal reports that it is unavailable.
- Support exactly zero or one active habit.
- Done, Light, and Rest all maintain the connection; Missed is derived and cannot be entered.
- Only today's check-in can be created or changed; past dates are read-only.
- Store Habit and DailyCheckIn source records only. Never persist Current Tether or Best Tether.
- All core flows must work offline.
- Do not add accounts, CloudKit, analytics, third-party crash SDKs, widgets, multiple habits, or any feature listed as excluded in the PRD.
- Use only Apple frameworks.
- Notification permission is requested only when the user enables a reminder.
- Do not claim tests pass if Simulator services are unavailable. Request permission to run them outside the sandbox when necessary.
- One task below equals one Codex implementation session. Do not combine adjacent tasks into a larger session.
- Each session must start from the prior session's completed commit, run the existing test suite before editing, and finish with its own verification and commit.

---

## Session Map

| Session | Deliverable | Depends on |
|---:|---|---|
| 1 | Xcode project, domain types, test harness | Approved PRD |
| 2 | LocalDay and Tether calculation engine | Session 1 |
| 3 | SwiftData persistence and reset | Session 2 |
| 4 | Root navigation and onboarding | Session 3 |
| 5 | Today check-in experience | Session 4 |
| 6 | History summary and 30-day list | Session 5 |
| 7 | Habit settings, editing, and full reset | Session 6 |
| 8 | Reminder planning and notification service | Session 7 |
| 9 | Reminder UI and lifecycle reconciliation | Session 8 |
| 10 | Date/lifecycle edge cases and error resilience | Session 9 |
| 11 | Accessibility, English copy, icon, and visual polish | Session 10 |
| 12 | Acceptance automation and TestFlight release preparation | Session 11 |
| 13 | Archive, upload, install, and dogfooding handoff | Session 12 |

Each session should be dispatched with this instruction:

~~~text
Implement only Session N from docs/superpowers/plans/2026-08-16-tether-ios-testflight-implementation.md.
Read docs/product/tether-prd-v0.1.md and the plan's Global Constraints first.
Run the pre-existing tests before editing. Follow the session's TDD steps, verify its stop condition,
commit only that session's changes, mark only that session's checkboxes complete, and stop.
~~~

## Planned File Structure

~~~text
Tether.xcodeproj/
Tether/
  App/
    TetherApp.swift
    AppEnvironment.swift
    AppModel.swift
    RootView.swift
  Core/
    Date/
      DayProviding.swift
      LocalDay.swift
    Habit/
      Habit.swift
      HabitDraft.swift
    CheckIn/
      CheckInState.swift
      DailyCheckIn.swift
    Tether/
      ConnectionPhase.swift
      TetherCalculator.swift
      TetherSnapshot.swift
    History/
      HistoryBuilder.swift
      HistoryDay.swift
      HistorySummary.swift
  Data/
    Models/
      HabitModel.swift
      DailyCheckInModel.swift
    TetherSchema.swift
    TetherStore.swift
    SwiftDataTetherStore.swift
  Services/
    Reminders/
      NotificationPermission.swift
      ReminderPlan.swift
      ReminderPlanBuilder.swift
      ReminderScheduling.swift
      ReminderSettings.swift
      ReminderSettingsStoring.swift
      UserDefaultsReminderSettingsStore.swift
      UserNotificationReminderScheduler.swift
  Features/
    Onboarding/
      WelcomeView.swift
      HabitSetupView.swift
      OnboardingViewModel.swift
    Today/
      CheckInButton.swift
      TodayView.swift
      TodayViewModel.swift
    History/
      HistoryDayRow.swift
      HistoryView.swift
      HistoryViewModel.swift
    Settings/
      HabitEditView.swift
      SettingsView.swift
      SettingsViewModel.swift
  Shared/
    AppCopy.swift
    AppTheme.swift
    ErrorBanner.swift
  Resources/
    Assets.xcassets/
    PrivacyInfo.xcprivacy
TetherTests/
  Core/
  Data/
  Features/
  Services/
TetherUITests/
  OnboardingUITests.swift
  TodayUITests.swift
  HistoryUITests.swift
  SettingsUITests.swift
docs/
  development/
    dogfooding-journal.md
    testflight-checklist.md
~~~

## Stable Interfaces Between Sessions

The following names and signatures are the contract between session tasks. A later session may add behavior but must not silently rename these types.

~~~swift
enum CheckInState: String, Codable, CaseIterable, Sendable {
    case done
    case light
    case rest
}

struct Habit: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var doneMeaning: String
    var lightMeaning: String
    let createdAt: Date
    var updatedAt: Date
}

struct HabitDraft: Equatable, Sendable {
    var name: String
    var doneMeaning: String
    var lightMeaning: String

    func validated() throws -> HabitDraft
}

struct DailyCheckIn: Identifiable, Equatable, Sendable {
    let id: UUID
    let habitID: UUID
    let day: LocalDay
    var state: CheckInState
    let createdAt: Date
    var updatedAt: Date
}

struct LocalDay: Hashable, Comparable, Codable, Sendable {
    let era: Int
    let year: Int
    let month: Int
    let day: Int

    init(date: Date, calendar: Calendar)
    var storageKey: String { get }
    func adding(days: Int, calendar: Calendar) -> LocalDay
}

enum ConnectionPhase: Equatable, Sendable {
    case start
    case active
    case reconnect
}

struct TetherSnapshot: Equatable, Sendable {
    let current: Int
    let best: Int
    let phase: ConnectionPhase
    let isCheckedInToday: Bool
}

enum TetherCalculator {
    static func snapshot(
        habitCreatedOn: LocalDay,
        checkIns: [DailyCheckIn],
        today: LocalDay,
        calendar: Calendar
    ) -> TetherSnapshot
}

@MainActor
protocol TetherStore: AnyObject {
    func loadHabit() throws -> Habit?
    func createHabit(from draft: HabitDraft, now: Date) throws -> Habit
    func updateHabit(id: UUID, from draft: HabitDraft, now: Date) throws -> Habit
    func loadCheckIns(habitID: UUID) throws -> [DailyCheckIn]
    func upsertCheckIn(
        habitID: UUID,
        day: LocalDay,
        state: CheckInState,
        now: Date
    ) throws -> DailyCheckIn
    func resetAll() throws
}

struct ReminderSettings: Equatable, Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static let defaultValue = ReminderSettings(
        isEnabled: false,
        hour: 20,
        minute: 0
    )
}

enum NotificationPermission: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
protocol ReminderScheduling: AnyObject {
    func permission() async -> NotificationPermission
    func requestAuthorization() async throws -> Bool
    func reconcile(
        settings: ReminderSettings,
        now: Date,
        calendar: Calendar,
        checkedDays: Set<LocalDay>
    ) async throws
    func cancelAll() async
}

protocol ReminderSettingsStoring: AnyObject {
    func load() -> ReminderSettings
    func save(_ settings: ReminderSettings)
    func reset()
}
~~~

---

### Task 1: Project Foundation and Domain Types

**Session outcome:** A buildable iPhone app project exists, core value types validate inputs, and unit tests run.

**Files:**

- Create: Tether.xcodeproj/project.pbxproj
- Create: Tether/App/TetherApp.swift
- Create: Tether/App/RootView.swift
- Create: Tether/Core/CheckIn/CheckInState.swift
- Create: Tether/Core/Habit/Habit.swift
- Create: Tether/Core/Habit/HabitDraft.swift
- Create: Tether/Shared/AppCopy.swift
- Create: TetherTests/Core/HabitDraftTests.swift
- Create: TetherUITests/TetherUITests.swift
- Modify: .gitignore

**Interfaces:**

- Produces: CheckInState, Habit, and HabitDraft.

- [x] **Step 1: Establish the repository and project**

If the workspace still has no Git repository, initialize main and preserve the approved documents:

~~~bash
git init -b main
git add AGENTS.md docs/product/tether-prd-v0.1.md docs/superpowers/plans/2026-08-16-tether-ios-testflight-implementation.md
git commit -m "docs: define Tether MVP"
~~~

Create an iOS App project named Tether in the workspace root with:

- Interface: SwiftUI
- Language: Swift
- Testing: Swift Testing with XCTest UI Tests
- Storage: none in the template; Session 3 adds SwiftData explicitly
- Deployment: iOS 17.0
- Devices: iPhone
- Bundle identifier: com.fredjeong.tether

Delete generated sample models and ContentView.
Move the generated Assets.xcassets into Tether/Resources/Assets.xcassets and keep its target membership.

- [x] **Step 2: Add project-level settings**

Set:

- SWIFT_VERSION = 6.0
- SWIFT_STRICT_CONCURRENCY = complete
- IPHONEOS_DEPLOYMENT_TARGET = 17.0
- TARGETED_DEVICE_FAMILY = 1
- DEVELOPMENT_LANGUAGE = en
- GENERATE_INFOPLIST_FILE = YES
- PRODUCT_NAME = Tether

Add .gitignore entries for DerivedData, xcuserdata, .DS_Store, and local signing state.

- [x] **Step 3: Write failing validation tests**

~~~swift
import Testing
@testable import Tether

struct HabitDraftTests {
    @Test func trimsValidInput() throws {
        let result = try HabitDraft(
            name: "  Workout  ",
            doneMeaning: "  Full workout ",
            lightMeaning: " Move for 10 minutes  "
        ).validated()

        #expect(result.name == "Workout")
        #expect(result.doneMeaning == "Full workout")
        #expect(result.lightMeaning == "Move for 10 minutes")
    }

    @Test(arguments: [
        HabitDraft(name: " ", doneMeaning: "Done", lightMeaning: "Light"),
        HabitDraft(name: "Workout", doneMeaning: " ", lightMeaning: "Light"),
        HabitDraft(name: "Workout", doneMeaning: "Done", lightMeaning: " ")
    ])
    func rejectsEmptyRequiredFields(_ draft: HabitDraft) {
        #expect(throws: HabitDraft.ValidationError.self) {
            try draft.validated()
        }
    }

    @Test func enforcesCharacterLimits() {
        #expect(throws: HabitDraft.ValidationError.self) {
            try HabitDraft(
                name: String(repeating: "a", count: 41),
                doneMeaning: "Done",
                lightMeaning: "Light"
            ).validated()
        }
    }
}
~~~

- [x] **Step 4: Run tests and confirm the expected failure**

~~~bash
xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16 Pro' -only-testing:TetherTests/HabitDraftTests
~~~

Expected: compilation fails because the domain types are not implemented.

- [x] **Step 5: Implement the domain types**

HabitDraft validation must:

- Trim whitespace and newlines.
- Require all three values.
- Enforce 1–40 characters for name.
- Enforce 1–80 characters for Done and Light meanings.
- Throw ValidationError.emptyField or ValidationError.tooLong.

Create AppCopy as the single location for finalized English strings from PRD section 14. RootView should show a temporary English Tether title only.

- [x] **Step 6: Verify build and tests**

~~~bash
xcodebuild build -project Tether.xcodeproj -scheme Tether -destination 'generic/platform=iOS Simulator'
xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16 Pro' -only-testing:TetherTests
~~~

Expected: build succeeds and HabitDraftTests pass.

- [x] **Step 7: Commit**

~~~bash
git add .gitignore Tether.xcodeproj Tether TetherTests TetherUITests
git commit -m "build: scaffold Tether iOS app"
~~~

**Stop condition:** The app launches to a simple English Tether foundation screen and the domain validation tests pass.

---

### Task 2: Local Calendar Day and Tether Engine

**Session outcome:** All Start, Active, Reconnect, Current, Best, and midnight rules are implemented as pure tested logic.

**Files:**

- Create: Tether/Core/Date/DayProviding.swift
- Create: Tether/Core/Date/LocalDay.swift
- Create: Tether/Core/CheckIn/DailyCheckIn.swift
- Create: Tether/Core/Tether/ConnectionPhase.swift
- Create: Tether/Core/Tether/TetherSnapshot.swift
- Create: Tether/Core/Tether/TetherCalculator.swift
- Create: TetherTests/Core/LocalDayTests.swift
- Create: TetherTests/Core/TetherCalculatorTests.swift
- Modify: Tether/Core/CheckIn/DailyCheckIn.swift

**Interfaces:**

- Produces: LocalDay, DayProviding, SystemDayProvider, FixedDayProvider, DailyCheckIn, ConnectionPhase, TetherSnapshot, TetherCalculator.snapshot.
- Consumes: Habit and CheckInState from Task 1.

- [ ] **Step 1: Run the Task 1 test suite**

Use the full TetherTests target and stop if the baseline is not green.

- [ ] **Step 2: Write LocalDay tests**

Cover:

- Two times on the same local calendar day compare equal.
- Consecutive days across month and year boundaries.
- Spring daylight-saving transitions using America/Los_Angeles.
- storageKey is stable and zero padded.

Example:

~~~swift
@Test func addsOneCalendarDayAcrossDST() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let day = LocalDay(era: 1, year: 2026, month: 3, day: 8)

    #expect(day.adding(days: 1, calendar: calendar)
        == LocalDay(era: 1, year: 2026, month: 3, day: 9))
}
~~~

- [ ] **Step 3: Write TetherCalculator tests**

Create helpers that build check-ins for exact LocalDay values. Test:

- No check-ins produces current 0, best 0, Start.
- Today Done produces current 1, best 1, Active.
- Done, Light, Rest on consecutive days produces current 3, best 3.
- Today pending with yesterday checked preserves the current chain.
- A missed day followed by no today check-in produces Reconnect and current 0.
- A missed day followed by today's Rest produces current 1 and Active.
- Best remains the longest historical segment.
- Habit creation dates before the first check-in do not inflate or penalize the count.
- Duplicate input days use the most recently updated check-in.

Example:

~~~swift
@Test func allThreeStatesMaintainConnection() {
    let checkIns = [
        makeCheckIn(day: day(1), state: .done),
        makeCheckIn(day: day(2), state: .light),
        makeCheckIn(day: day(3), state: .rest)
    ]

    let result = TetherCalculator.snapshot(
        habitCreatedOn: day(1),
        checkIns: checkIns,
        today: day(3),
        calendar: calendar
    )

    #expect(result == TetherSnapshot(
        current: 3,
        best: 3,
        phase: .active,
        isCheckedInToday: true
    ))
}
~~~

- [ ] **Step 4: Confirm tests fail**

Run LocalDayTests and TetherCalculatorTests. Expected: compilation failure for missing APIs.

- [ ] **Step 5: Implement LocalDay**

LocalDay must:

- Build components with the injected Calendar.
- Format storageKey as era-yyyy-MM-dd.
- Reconstruct a noon Date before adding calendar days to avoid DST midnight ambiguity.
- Compare era, year, month, then day.
- Throw no runtime errors for dates created from the app's own Calendar.

DayProviding must expose now and calendar. SystemDayProvider uses Date() and Calendar.autoupdatingCurrent. FixedDayProvider is compiled into the app module so feature tests can inject time without changing the device clock.

- [ ] **Step 6: Implement TetherCalculator**

Algorithm:

1. Discard check-ins before habitCreatedOn and after today.
2. Collapse duplicate days by choosing the greatest updatedAt.
3. Sort unique days ascending.
4. Scan consecutive segments to compute Best.
5. If no records exist, phase is Start and Current is 0.
6. If today exists, Current is the segment ending today.
7. Otherwise, if yesterday exists, Current is the segment ending yesterday and Active remains pending.
8. Otherwise, Current is 0 and phase is Reconnect.

- [ ] **Step 7: Verify and commit**

Run the full TetherTests target, then:

~~~bash
git add Tether/Core TetherTests/Core
git commit -m "feat: add calendar-safe Tether engine"
~~~

**Stop condition:** Every PRD Tether example and date boundary case is expressed as a passing pure unit test.

---

### Task 3: SwiftData Persistence

**Session outcome:** One Habit and one check-in per habit/day persist across contexts, can be updated, and can be fully reset.

**Files:**

- Create: Tether/Data/Models/HabitModel.swift
- Create: Tether/Data/Models/DailyCheckInModel.swift
- Create: Tether/Data/TetherSchema.swift
- Create: Tether/Data/TetherStore.swift
- Create: Tether/Data/SwiftDataTetherStore.swift
- Create: TetherTests/Data/SwiftDataTetherStoreTests.swift
- Modify: Tether/App/TetherApp.swift

**Interfaces:**

- Produces: TetherStore and SwiftDataTetherStore matching the Stable Interfaces section.
- Produces: TetherSchema.makeContainer(inMemory:).
- Consumes: Habit, HabitDraft, DailyCheckIn, LocalDay, CheckInState.

- [ ] **Step 1: Add failing in-memory persistence tests**

Test:

- Empty store returns no Habit.
- Creating one Habit returns and reloads it.
- Creating a second Habit throws TetherStoreError.habitAlreadyExists.
- Updating Habit preserves id and createdAt.
- Upserting a state for the same day updates one record rather than inserting a duplicate.
- Different days remain separate records.
- resetAll removes Habit and check-ins.
- Recreating a ModelContext over the same in-memory container reads saved records.

Example:

~~~swift
@Test @MainActor
func upsertChangesStateWithoutDuplicatingDay() throws {
    let fixture = try StoreFixture()
    let habit = try fixture.store.createHabit(
        from: .init(name: "Workout", doneMeaning: "Gym", lightMeaning: "Walk"),
        now: fixture.now
    )
    let day = LocalDay(date: fixture.now, calendar: fixture.calendar)

    _ = try fixture.store.upsertCheckIn(
        habitID: habit.id, day: day, state: .done, now: fixture.now
    )
    _ = try fixture.store.upsertCheckIn(
        habitID: habit.id, day: day, state: .rest, now: fixture.now.addingTimeInterval(60)
    )

    let records = try fixture.store.loadCheckIns(habitID: habit.id)
    #expect(records.count == 1)
    #expect(records.first?.state == .rest)
}
~~~

- [ ] **Step 2: Confirm persistence tests fail**

Expected: missing TetherStore and model types.

- [ ] **Step 3: Implement SwiftData models**

HabitModel fields must mirror Habit. DailyCheckInModel stores:

- id
- habitID
- dayKey
- dayEra, dayYear, dayMonth, dayValue
- stateRawValue
- createdAt
- updatedAt
- uniqueDayKey

Mark uniqueDayKey with @Attribute(.unique). Build it as lowercasedHabitUUID + "|" + LocalDay.storageKey. Do not use a SwiftData relationship for v0.1; habitID is sufficient and keeps reset/fetch behavior explicit.

- [ ] **Step 4: Implement schema and store**

TetherSchema.makeContainer(inMemory:) must configure HabitModel and DailyCheckInModel. The app gets a persistent container; tests get isStoredInMemoryOnly true.

Every mutating store method must call ModelContext.save() explicitly and surface errors. resetAll fetches and deletes both model types, then saves.

- [ ] **Step 5: Attach the persistent ModelContainer to the app**

TetherApp must create one container for the process and pass its mainContext into SwiftDataTetherStore. Do not use a second container in features.

- [ ] **Step 6: Verify persistence and regression tests**

Run all unit tests twice to expose accidental shared state between tests. Then commit:

~~~bash
git add Tether/Data Tether/App/TetherApp.swift TetherTests/Data
git commit -m "feat: persist habits and check-ins with SwiftData"
~~~

**Stop condition:** Persistence tests pass in memory, the app relaunches against a persistent container, and no derived Tether number is stored.

---

### Task 4: Root Navigation and Onboarding

**Session outcome:** A fresh install can understand Tether, create one valid habit, and reach a stable main shell.

**Files:**

- Create: Tether/App/AppEnvironment.swift
- Create: Tether/App/AppModel.swift
- Modify: Tether/App/RootView.swift
- Create: Tether/Features/Onboarding/WelcomeView.swift
- Create: Tether/Features/Onboarding/HabitSetupView.swift
- Create: Tether/Features/Onboarding/OnboardingViewModel.swift
- Create: TetherTests/Features/OnboardingViewModelTests.swift
- Create: TetherUITests/OnboardingUITests.swift

**Interfaces:**

- Produces: AppEnvironment with store and dayProvider. Task 8 extends it with reminder dependencies.
- Produces: AppModel.Route.onboarding and AppModel.Route.main.
- Consumes: TetherStore, HabitDraft, SystemDayProvider, AppCopy.

- [ ] **Step 1: Write failing OnboardingViewModel tests**

Test:

- canSubmit is false for any empty field.
- canSubmit is true for valid inputs.
- submit trims values, creates exactly one Habit, and reports the created Habit.
- storage errors set user-visible error text and do not route to main.
- a pre-existing Habit routes RootView directly to main.

- [ ] **Step 2: Add one failing onboarding UI test**

Launch with argument -ui-testing-reset. Assert:

1. Headline is visible.
2. Set up my habit opens the form.
3. Enter Workout, A full workout, Move for 10 minutes.
4. Start my tether reaches the main tab shell.

Give fields stable accessibility identifiers:

- onboarding.start
- habit.name
- habit.doneMeaning
- habit.lightMeaning
- habit.submit
- tab.today

- [ ] **Step 3: Confirm tests fail**

Run OnboardingViewModelTests and OnboardingUITests.

- [ ] **Step 4: Implement AppModel and routing**

AppModel loads one Habit at startup:

~~~swift
@MainActor
@Observable
final class AppModel {
    enum Route {
        case onboarding
        case main
    }

    private(set) var route: Route = .onboarding
    private(set) var habit: Habit?

    func load() throws
    func didCreateHabit(_ habit: Habit)
    func didReset()
}
~~~

RootView displays onboarding when no Habit exists. Main is a TabView whose initial Today and History destinations clearly identify the upcoming features without exposing broken controls; Tasks 5 and 6 replace those destinations. Settings is opened from a toolbar button added in Task 7.

- [ ] **Step 5: Implement Welcome and Habit Setup**

Use the exact PRD copy. Welcome is one screen, not a carousel. HabitSetup:

- Enforces 40/80/80 character limits while typing.
- Uses textContentType nil and autocorrection appropriate for plain English phrases.
- Keeps keyboard submission order.
- Shows a neutral ErrorBanner if saving fails.
- Does not include reminder controls yet; Task 9 adds them after the notification service exists.

- [ ] **Step 6: Add deterministic UI-test reset**

Only when the launch argument -ui-testing-reset exists, clear the test container before RootView loads. This path must not be exposed in normal UI.

- [ ] **Step 7: Verify and commit**

Run unit tests, onboarding UI test, and app build. Then:

~~~bash
git add Tether/App Tether/Features/Onboarding TetherTests/Features TetherUITests/OnboardingUITests.swift
git commit -m "feat: add Tether onboarding"
~~~

**Stop condition:** A clean app install creates one Habit and reaches the main shell; relaunch skips onboarding.

---

### Task 5: Today Check-in Experience

**Session outcome:** The user can see Start/Active/Reconnect, select Done/Light/Rest in one tap, and change today's state.

**Files:**

- Create: Tether/Features/Today/TodayViewModel.swift
- Create: Tether/Features/Today/TodayView.swift
- Create: Tether/Features/Today/CheckInButton.swift
- Create: Tether/Shared/ErrorBanner.swift
- Create: TetherTests/Features/TodayViewModelTests.swift
- Create: TetherUITests/TodayUITests.swift
- Modify: Tether/App/RootView.swift
- Modify: Tether/Shared/AppCopy.swift

**Interfaces:**

- Produces: TodayViewModel.load(), select(_:), and refresh().
- Consumes: TetherStore, DayProviding, and TetherCalculator.

- [ ] **Step 1: Write failing TodayViewModel tests**

Test with an in-memory store and FixedDayProvider:

- No records yields Start your tether today and Current 0.
- Selecting Done creates today's record and Current 1.
- Selecting Light and Rest each maintain the connection.
- Selecting a second state updates today's record without duplication.
- Yesterday's record with today pending preserves Current.
- An older record separated by a Missed day yields Reconnect.
- Store errors do not show a false success state.

- [ ] **Step 2: Write failing Today UI tests**

Seed a Habit through launch arguments. Test:

- Three buttons are visible with labels and helpers.
- One tap on Done shows You're still connected.
- Change followed by Rest changes the selected state.
- Relaunch keeps Rest selected.

Accessibility identifiers:

- today.tetherStatus
- checkin.done
- checkin.light
- checkin.rest
- checkin.change
- today.error

- [ ] **Step 3: Confirm tests fail**

Run TodayViewModelTests and TodayUITests.

- [ ] **Step 4: Implement TodayViewModel**

State:

~~~swift
@MainActor
@Observable
final class TodayViewModel {
    private(set) var habit: Habit?
    private(set) var selectedState: CheckInState?
    private(set) var snapshot = TetherSnapshot(
        current: 0, best: 0, phase: .start, isCheckedInToday: false
    )
    private(set) var errorMessage: String?

    func load()
    func refresh()
    func select(_ state: CheckInState)
}
~~~

load and select always recompute from persisted check-ins. Never increment a UI counter optimistically.

- [ ] **Step 5: Implement TodayView**

Layout order:

1. English-formatted date.
2. Habit name.
3. Start, N days tethered, or Reconnect headline.
4. Supporting copy.
5. How was today?
6. Done/Light/Rest buttons.
7. Saved state and Change affordance after selection.

Each CheckInButton includes text plus a system symbol:

- Done: checkmark.circle
- Light: leaf
- Rest: moon

Do not use a flame.

- [ ] **Step 6: Verify 3-second path**

The normal path after launch must require exactly one tap to save a check-in. There must be no confirmation sheet, note field, or celebration that blocks interaction.

- [ ] **Step 7: Run tests and commit**

~~~bash
git add Tether/Features/Today Tether/Shared Tether/App/RootView.swift TetherTests/Features/TodayViewModelTests.swift TetherUITests/TodayUITests.swift
git commit -m "feat: add daily Tether check-in"
~~~

**Stop condition:** Today is fully usable offline and all three states behave identically in Tether math.

---

### Task 6: History Summary and 30-Day List

**Session outcome:** History shows accurate Current, Best, state counts, and up to 30 reverse-chronological day rows.

**Files:**

- Create: Tether/Core/History/HistoryDay.swift
- Create: Tether/Core/History/HistorySummary.swift
- Create: Tether/Core/History/HistoryBuilder.swift
- Create: Tether/Features/History/HistoryViewModel.swift
- Create: Tether/Features/History/HistoryView.swift
- Create: Tether/Features/History/HistoryDayRow.swift
- Create: TetherTests/Core/HistoryBuilderTests.swift
- Create: TetherTests/Features/HistoryViewModelTests.swift
- Create: TetherUITests/HistoryUITests.swift
- Modify: Tether/App/RootView.swift

**Interfaces:**

- Produces: HistoryBuilder.build(habit:checkIns:today:calendar:limit:).
- Consumes: TetherCalculator and TetherStore.

- [ ] **Step 1: Write failing HistoryBuilder tests**

HistoryDay:

~~~swift
struct HistoryDay: Identifiable, Equatable, Sendable {
    var id: String { day.storageKey }
    let day: LocalDay
    let state: CheckInState?
}
~~~

HistorySummary contains current, best, doneCount, lightCount, and restCount.

Test:

- Rows start at today and descend one calendar day at a time.
- Rows stop at Habit creation or 30 rows, whichever occurs first.
- Missing days have nil state.
- Counts use all records, not only the 30 visible rows.
- Duplicate days choose latest updatedAt consistently with TetherCalculator.
- No future or pre-creation records are counted.

- [ ] **Step 2: Confirm History tests fail**

Run only HistoryBuilderTests.

- [ ] **Step 3: Implement HistoryBuilder**

Use one normalized dictionary of day to latest DailyCheckIn, then:

- Call TetherCalculator for Current and Best.
- Count normalized all-time records by state.
- Generate reverse day rows from today with Calendar arithmetic.
- Cap at 30.

- [ ] **Step 4: Implement HistoryViewModel and HistoryView**

HistoryViewModel loads from TetherStore on appearance and when AppModel signals a change.

HistoryView:

- Two metric cards: Current Tether and Best Tether.
- Three small state count rows or cards.
- A plain reverse-chronological List.
- English date formatting.
- State text and symbol; color is secondary.
- Empty state copy exactly as in the PRD.

Accessibility identifiers:

- history.current
- history.best
- history.doneCount
- history.lightCount
- history.restCount
- history.list

- [ ] **Step 5: Write and run a History UI test**

Seed Done, Light, Rest, and one missing day. Assert each label is visible and Current/Best values match the seed.

- [ ] **Step 6: Run all tests and commit**

~~~bash
git add Tether/Core/History Tether/Features/History TetherTests/Core/HistoryBuilderTests.swift TetherTests/Features/HistoryViewModelTests.swift TetherUITests/HistoryUITests.swift Tether/App/RootView.swift
git commit -m "feat: add Tether history"
~~~

**Stop condition:** History matches domain calculations and never treats No check-in as a stored state.

---

### Task 7: Habit Settings, Editing, and Full Reset

**Session outcome:** The user can edit the one Habit, see the app version, and safely reset all local product data.

**Files:**

- Create: Tether/Features/Settings/SettingsViewModel.swift
- Create: Tether/Features/Settings/SettingsView.swift
- Create: Tether/Features/Settings/HabitEditView.swift
- Create: TetherTests/Features/SettingsViewModelTests.swift
- Create: TetherUITests/SettingsUITests.swift
- Modify: Tether/App/AppModel.swift
- Modify: Tether/App/RootView.swift
- Modify: Tether/Shared/AppCopy.swift

**Interfaces:**

- Produces: SettingsViewModel.saveHabit() and resetAll().
- Consumes: TetherStore and AppModel.didReset().
- Task 9 extends SettingsViewModel with reminder properties without changing habit/reset APIs.

- [ ] **Step 1: Write failing SettingsViewModel tests**

Test:

- Existing Habit values load.
- Save applies HabitDraft validation.
- Editing preserves id, createdAt, and all check-ins.
- Store failure shows Couldn't save your changes. Please try again.
- resetAll clears Habit and check-ins then calls AppModel.didReset.
- reset failure remains in Settings and reports an error.

- [ ] **Step 2: Implement Settings UI**

RootView Today toolbar opens Settings as a sheet. Settings contains:

- Habit section with Edit habit.
- About section with app version and build from Bundle.
- Data section with Reset all data in destructive styling.

HabitEditView uses the same limits and copy as onboarding. Save is disabled until valid and changed.

- [ ] **Step 3: Implement reset confirmation**

Use:

- Title: Reset Tether?
- Body: This will permanently delete your habit and all check-ins from this iPhone.
- Destructive action: Reset
- Cancel action: Cancel

After a successful reset, dismiss Settings and route to Welcome. Do not retain the previous Habit in any feature view model.

- [ ] **Step 4: Add Settings UI tests**

Test edit persistence and reset routing. Use identifiers:

- settings.open
- settings.editHabit
- settings.reset
- settings.resetConfirm
- settings.version

- [ ] **Step 5: Verify and commit**

~~~bash
git add Tether/Features/Settings Tether/App Tether/Shared/AppCopy.swift TetherTests/Features/SettingsViewModelTests.swift TetherUITests/SettingsUITests.swift
git commit -m "feat: add habit settings and reset"
~~~

**Stop condition:** Habit edits preserve history and Reset returns to a genuinely clean onboarding state.

---

### Task 8: Reminder Planning and Notification Service

**Session outcome:** A tested service can request permission, generate a 30-day rolling reminder plan, reconcile pending notifications, and cancel all reminders.

**Files:**

- Create: Tether/Services/Reminders/NotificationPermission.swift
- Create: Tether/Services/Reminders/ReminderSettings.swift
- Create: Tether/Services/Reminders/ReminderPlan.swift
- Create: Tether/Services/Reminders/ReminderPlanBuilder.swift
- Create: Tether/Services/Reminders/ReminderScheduling.swift
- Create: Tether/Services/Reminders/ReminderSettingsStoring.swift
- Create: Tether/Services/Reminders/UserDefaultsReminderSettingsStore.swift
- Create: Tether/Services/Reminders/UserNotificationReminderScheduler.swift
- Create: TetherTests/Services/ReminderPlanBuilderTests.swift
- Create: TetherTests/Services/UserDefaultsReminderSettingsStoreTests.swift
- Modify: Tether/App/AppEnvironment.swift

**Interfaces:**

- Produces: all reminder interfaces in Stable Interfaces.
- ReminderPlan is a pure value with identifier and DateComponents.
- UserNotificationReminderScheduler owns the prefix tether.daily.

- [ ] **Step 1: Write failing ReminderPlanBuilder tests**

The planner schedules 30 one-shot notifications so reminders continue even if the app is not reopened. Test:

- Disabled settings produce no plans.
- Before today's reminder time includes today.
- After today's reminder time starts tomorrow.
- A checked today skips today.
- Exactly 30 future plans are produced.
- DST and month boundaries use Calendar addition.
- Identifiers are tether.daily. plus LocalDay.storageKey.
- Every plan uses title A moment for your habit and body Was today Done, Light, or Rest?

- [ ] **Step 2: Write failing settings-store tests**

Use a unique UserDefaults suite. Verify default is off at 20:00, save/load round-trips, and reset returns to default.

- [ ] **Step 3: Implement pure reminder types and settings store**

UserDefaults keys:

- reminder.enabled
- reminder.hour
- reminder.minute

No other settings belong in UserDefaults. This storage is app-only and will be declared with privacy reason CA92.1 in Task 12.

- [ ] **Step 4: Implement UserNotificationReminderScheduler**

Behavior:

1. permission maps UNAuthorizationStatus into the three app states.
2. requestAuthorization requests alert, badge, and sound; do not request provisional or critical alerts.
3. reconcile removes pending requests whose identifier starts with tether.daily.
4. If disabled or permission is denied, stop after removal.
5. Build 30 plans and add one non-repeating UNCalendarNotificationTrigger per plan.
6. cancelAll removes all Tether-prefixed pending requests.

Use one-shot calendar triggers rather than a repeating trigger because today's completed reminder must be removable without disabling future days.

- [ ] **Step 5: Add an in-memory FakeReminderScheduler**

Tests and previews use a fake that records authorization requests, reconcile inputs, and cancellation. Do not call UNUserNotificationCenter from feature tests.

- [ ] **Step 6: Verify and commit**

Run all service and regression tests. Then:

~~~bash
git add Tether/Services/Reminders Tether/App/AppEnvironment.swift TetherTests/Services
git commit -m "feat: add local reminder service"
~~~

**Stop condition:** Reminder dates are fully pure-tested and the live adapter contains only UserNotifications translation and scheduling.

---

### Task 9: Reminder UI and Lifecycle Reconciliation

**Session outcome:** Onboarding and Settings can enable reminders correctly, Today cancels today's reminder after check-in, and foreground refresh repairs schedules.

**Files:**

- Modify: Tether/Features/Onboarding/HabitSetupView.swift
- Modify: Tether/Features/Onboarding/OnboardingViewModel.swift
- Modify: Tether/Features/Settings/SettingsView.swift
- Modify: Tether/Features/Settings/SettingsViewModel.swift
- Modify: Tether/Features/Today/TodayViewModel.swift
- Modify: Tether/App/AppModel.swift
- Modify: Tether/App/RootView.swift
- Create: TetherTests/Features/ReminderIntegrationTests.swift
- Modify: TetherUITests/OnboardingUITests.swift
- Modify: TetherUITests/SettingsUITests.swift

**Interfaces:**

- Consumes: ReminderScheduling, ReminderSettingsStoring, TetherStore, DayProviding.
- Does not expose UserNotifications types to views.

- [ ] **Step 1: Write failing reminder integration tests**

Test:

- Reminder toggle defaults off.
- Enabling from notDetermined requests permission exactly once.
- Authorized enable persists settings and reconciles.
- Denied enable remains off and exposes Open iOS Settings copy.
- Changing time persists and reconciles.
- Turning off cancels pending reminders.
- Selecting today's check-in reconciles with today in checkedDays.
- Reset clears reminder settings and cancels all.
- Foreground refresh reloads Today and reconciles the rolling window.

- [ ] **Step 2: Extend onboarding**

Add optional Daily reminder toggle and time picker. Turning it on requests permission. Habit creation must still succeed if notification scheduling fails; show the scheduling error after entering the main app and keep reminder disabled.

Accessibility identifiers:

- reminder.toggle
- reminder.time
- reminder.permissionMessage
- reminder.openSettings

- [ ] **Step 3: Extend Settings**

Add Reminder section:

- Toggle
- Time picker when enabled
- Current permission explanation
- Open iOS Settings button when denied

Opening iOS Settings uses UIApplication.openSettingsURLString.

- [ ] **Step 4: Integrate Today and lifecycle**

After a successful check-in:

1. Reload all checked days.
2. Reconcile reminder plans.
3. Do not roll back the saved check-in if notification scheduling fails.
4. Show a reminder-specific non-blocking error only when reminders are enabled.

On scenePhase active and NSCalendarDayChanged:

- Refresh AppModel and Today.
- Refresh History on its next appearance.
- Reconcile reminders.

- [ ] **Step 5: Update UI tests**

UI tests must use FakeReminderScheduler through launch configuration; do not automate the system permission alert in the full suite. Add one narrowly scoped permission-alert test if the simulator supports resetting notification permissions deterministically.

- [ ] **Step 6: Verify and commit**

~~~bash
git add Tether/Features Tether/App TetherTests/Features/ReminderIntegrationTests.swift TetherUITests
git commit -m "feat: connect reminders to daily flow"
~~~

**Stop condition:** A check-in before reminder time prevents that day's reminder while the next 30 eligible days remain scheduled.

---

### Task 10: Date, Lifecycle, and Error Resilience

**Session outcome:** Midnight, foreground, time-zone, duplicate-data, and save-failure behavior is deterministic and covered by regression tests.

**Files:**

- Modify: Tether/App/AppModel.swift
- Modify: Tether/App/RootView.swift
- Modify: Tether/Features/Today/TodayViewModel.swift
- Modify: Tether/Features/History/HistoryViewModel.swift
- Modify: Tether/Features/Settings/SettingsViewModel.swift
- Modify: TetherTests/Core/LocalDayTests.swift
- Modify: TetherTests/Core/TetherCalculatorTests.swift
- Create: TetherTests/Features/LifecycleRegressionTests.swift

**Interfaces:**

- No public interface changes.
- Any production fix begins with a failing regression test.

- [ ] **Step 1: Add failing lifecycle regression tests**

Cover:

- App remains open across midnight and refreshes Today.
- Foreground after a missed day changes Active pending to Reconnect.
- A time-zone change affects new LocalDay values but never rewrites stored LocalDay fields.
- Duplicate corrupt day records choose latest updatedAt.
- Store failure never shows You're still connected.
- Notification scheduling failure never rolls back a saved check-in.
- Reset failure does not route away from Settings.

- [ ] **Step 2: Add a deterministic lifecycle test harness**

Use FixedDayProvider with a mutable now/calendar test implementation. Route scene activation and NSCalendarDayChanged through one AppModel.refreshForCurrentDay() method so tests do not need NotificationCenter.

- [ ] **Step 3: Implement the smallest fixes**

On every refresh:

1. Read current date from DayProviding.
2. Reload Habit and check-ins.
3. Recompute Today snapshot.
4. Invalidate HistoryViewModel so its next appearance reloads.
5. Reconcile reminders without blocking UI state.

Persistence errors and reminder errors remain separate messages.

- [ ] **Step 4: Manually exercise injected edge states**

With debug launch arguments:

- Start immediately before midnight and advance to the next day.
- Seed one missed day and confirm Reconnect.
- Inject store save failure and confirm retry copy.
- Disable network and confirm no core flow changes.

Do not ship a hidden time-travel UI; the injection path is test/debug-only.

- [ ] **Step 5: Verify and commit**

Run all unit and integration tests plus Today and History UI tests. Then:

~~~bash
git add Tether/App Tether/Features TetherTests
git commit -m "fix: harden Tether date and error handling"
~~~

**Stop condition:** Every PRD edge case has a regression test and foreground/midnight refresh cannot produce a stale Tether.

---

### Task 11: Accessibility, English Copy, Icon, and Visual Polish

**Session outcome:** The complete product is accessible, visually coherent, and contains no unintended Korean UI or asset warnings.

**Files:**

- Create: Tether/Shared/AppTheme.swift
- Create: Tether/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
- Modify: all feature views
- Modify: Tether/Shared/AppCopy.swift
- Create: TetherTests/Features/EnglishCopyTests.swift
- Create: TetherUITests/AccessibilitySmokeTests.swift

**Interfaces:**

- No domain or persistence interface changes.

- [ ] **Step 1: Centralize and test user-visible strings**

AppCopy must contain every visible static English phrase. Add tests for the required PRD copy and singular/plural formatting:

~~~swift
@Test func tetherDayCountUsesCorrectPluralization() {
    #expect(AppCopy.daysTethered(1) == "1 day tethered")
    #expect(AppCopy.daysTethered(2) == "2 days tethered")
}
~~~

Run:

~~~bash
rg -n '[가-힣]' Tether --glob '*.swift'
~~~

Expected: no Korean strings or comments in the app source.

- [ ] **Step 2: Apply the visual system**

AppTheme:

- Background: warm off-white.
- Primary text: dark navy.
- Done accent: restrained green.
- Light accent: muted amber.
- Rest accent: muted indigo.
- No red for Missed.
- Rounded cards, standard system font, no custom font dependency.

Apply it consistently to Welcome, Habit Setup, Today, History, Settings, ErrorBanner, and destructive confirmation.

- [ ] **Step 3: Complete accessibility behavior**

All controls:

- Minimum 44 by 44 point touch targets.
- Dynamic Type without truncating state meanings.
- VoiceOver label includes state, helper text, and selected status.
- Color is never the sole state indicator.
- Reduce Motion removes nonessential transitions.
- Landscape does not clip, while portrait remains the primary composition.

- [ ] **Step 4: Add a minimal app icon**

Create a 1024 by 1024 icon with no text:

- Dark navy background.
- One warm off-white continuous loop or tether mark.
- High contrast and generous safe margins.
- No gradients that reduce small-size clarity.

Populate the AppIcon asset set and verify there are no asset catalog warnings.

- [ ] **Step 5: Add accessibility smoke tests**

Use an extra-extra-extra-large content size launch argument. Verify Welcome, Today, History, and Settings primary actions remain visible and hittable. Assert accessible labels for all three check-in buttons and all four History states.

- [ ] **Step 6: Verify and commit**

Run all tests and build with warnings treated as errors for the app target. Then:

~~~bash
git add Tether TetherTests/Features/EnglishCopyTests.swift TetherUITests/AccessibilitySmokeTests.swift
git commit -m "feat: polish and accessible Tether UI"
~~~

**Stop condition:** Accessibility smoke tests pass, assets compile without warnings, and every user-visible phrase is English.

---

### Task 12: Acceptance Automation and TestFlight Release Preparation

**Session outcome:** The app passes one clean acceptance suite and contains the privacy/release artifacts required before upload.

**Files:**

- Create: Tether/Resources/PrivacyInfo.xcprivacy
- Create: docs/development/testflight-checklist.md
- Create: docs/development/dogfooding-journal.md
- Create: TetherUITests/AcceptanceUITests.swift
- Modify: Tether.xcodeproj/project.pbxproj
- Modify: Tether/Info.plist only if the project stops generating it

**Interfaces:**

- No product behavior changes except fixes driven by failing acceptance tests.

- [ ] **Step 1: Add one end-to-end acceptance UI test**

The test performs:

1. Fresh reset.
2. Welcome to Habit setup.
3. Create Workout.
4. Select Done.
5. Change to Rest.
6. Open History and verify Rest count 1.
7. Edit Habit name to Training.
8. Return Today and verify Training.
9. Reset all data.
10. Verify Welcome is visible.

Take screenshots after Today, History, and Reset for review artifacts.

- [ ] **Step 2: Run the complete clean test suite**

~~~bash
xcodebuild clean test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16 Pro'
~~~

If Simulator access is blocked, request the necessary permission and rerun. Do not substitute a build-only check.

- [ ] **Step 3: Add PrivacyInfo.xcprivacy**

Declare:

- NSPrivacyTracking = false
- NSPrivacyTrackingDomains = empty
- NSPrivacyCollectedDataTypes = empty because no data leaves the device
- NSPrivacyAccessedAPITypes includes NSPrivacyAccessedAPICategoryUserDefaults
- Reason includes CA92.1 because reminder preferences are app-only

Generate Xcode's privacy report and confirm it matches the manifest.

- [ ] **Step 4: Set release configuration**

Set:

- MARKETING_VERSION = 0.1.0
- CURRENT_PROJECT_VERSION = 1
- CODE_SIGN_STYLE = Automatic
- Display name = Tether
- Supported orientations = iPhone portrait and landscape
- No background modes
- No HealthKit, iCloud, push, App Groups, or tracking entitlements

Select the user's existing Apple Developer Team in Signing & Capabilities. This is the only account-specific value intentionally not hard-coded in the repository.

- [ ] **Step 5: Create the TestFlight checklist**

docs/development/testflight-checklist.md must contain:

- Apple Developer membership active.
- App ID com.fredjeong.tether available and registered.
- App Store Connect app record created.
- SKU tether-ios-v01.
- Internal testing group Self Dogfood created.
- Version 0.1.0, build 1.
- Export compliance answered accurately; the app adds no encryption beyond Apple system frameworks.
- What to Test: Daily Done, Light, and Rest check-ins; Tether and Reconnect behavior; History; reminder; reset.
- Known limitations: one Habit, one iPhone, local-only data, no backup/sync.
- Unit/integration/UI tests green.
- Archive validation green.
- Installed from TestFlight on the target iPhone.

- [ ] **Step 6: Create the 14-day journal**

Create one table row per day with:

- Date
- State and reason
- Did I avoid opening the app?
- Was the state choice ambiguous?
- Did Rest feel intentional or avoidant?
- Any unnecessary interaction?
- Reconnect notes

Include day 14 decision questions from PRD sections 4, 25, and 26.

- [ ] **Step 7: Archive validation without upload**

Create an Any iOS Device archive and run Xcode Organizer validation. Fix warnings that affect upload. Do not upload in this session.

- [ ] **Step 8: Commit**

~~~bash
git add Tether/Resources/PrivacyInfo.xcprivacy Tether.xcodeproj TetherUITests/AcceptanceUITests.swift docs/development
git commit -m "chore: prepare Tether for TestFlight"
~~~

**Stop condition:** Clean acceptance tests and archive validation pass, and the only remaining action is the authorized upload/install workflow.

---

### Task 13: TestFlight Upload, Install, and Dogfooding Handoff

**Session outcome:** Build 1 is installed from TestFlight on the user's iPhone and the 14-day validation can start.

**Files:**

- Modify: docs/development/testflight-checklist.md
- Modify: docs/development/dogfooding-journal.md
- Modify: Tether.xcodeproj/project.pbxproj only if build number must increase after a rejected upload

**Interfaces:**

- No source-code changes unless upload validation exposes a real defect.
- Any defect fix starts with a regression test and receives a separate commit.

- [ ] **Step 1: Confirm external prerequisites**

Verify the signed-in Apple Developer account, App ID, App Store Connect record, agreements, and Self Dogfood internal testing group. Ask the user only for account actions that cannot be performed without their authorization.

- [ ] **Step 2: Re-run release verification**

Run the clean full suite and create a fresh Release archive from the exact committed state. Record the commit hash in the checklist.

- [ ] **Step 3: Upload through Xcode Organizer**

Distribute App → App Store Connect → Upload. Use automatic signing and symbol upload. Do not enable external testing.

- [ ] **Step 4: Resolve App Store Connect processing**

Wait for processing to complete. Address only actionable upload errors. If a new binary is required, increment CURRENT_PROJECT_VERSION from 1 to 2, commit that change, rerun verification, and upload build 2. Do not reuse a rejected build number.

- [ ] **Step 5: Assign to Self Dogfood**

Add the processed build to the internal testing group and enter the What to Test copy from the checklist.

- [ ] **Step 6: Install and perform real-device smoke test**

Install using TestFlight on the target iPhone. Verify:

- Fresh onboarding.
- One-tap check-in.
- App relaunch persistence.
- History update.
- Reminder permission and delivery timing.
- Offline launch and check-in.
- Reset confirmation.

Do not reset after the final smoke setup if the 14-day run starts immediately.

- [ ] **Step 7: Start the journal**

Record:

- Installed build number.
- Git commit.
- iPhone model and iOS version.
- Validation start date.
- Selected Habit and Done/Light meanings.
- Any known issue accepted for the run.

- [ ] **Step 8: Mark handoff complete**

Update the checklist with upload, install, and smoke-test results. Commit documentation only:

~~~bash
git add docs/development
git commit -m "docs: start Tether dogfooding"
~~~

**Stop condition:** Tether is running from TestFlight on the real iPhone and day 1 of the 14-day journal has a defined start date.

---

## Plan-wide Verification Matrix

| PRD requirement | Owning session | Primary verification |
|---|---:|---|
| One Habit | 3, 4 | Store and onboarding tests |
| Done/Light/Rest | 2, 5 | Calculator and Today tests |
| Today-only edits | 3, 5 | Store and UI tests |
| Current/Best | 2, 6 | Pure calculator tests |
| Missed/Reconnect | 2, 5, 10 | Date and UI regression tests |
| 30-day History | 6 | HistoryBuilder and UI tests |
| Local reminder | 8, 9 | Planner and integration tests |
| Edit Habit | 7 | Settings tests |
| Reset all | 3, 7, 9 | Store, Settings, reminder tests |
| Offline/local-only | 3, 13 | Architecture plus device smoke |
| English-only | 1, 11 | Copy tests and source scan |
| Accessibility | 5, 6, 7, 11 | Labels and smoke tests |
| Privacy manifest | 12 | Xcode privacy report |
| TestFlight install | 13 | Real-device smoke test |

## Implementation References

- Apple SwiftData ModelContainer: https://developer.apple.com/documentation/swiftdata/modelcontainer
- Apple SwiftData ModelContext: https://developer.apple.com/documentation/swiftdata/modelcontext
- Apple local calendar notification trigger: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
- Apple testing guidance: https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project
- Apple privacy manifest overview: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Apple required-reason API guidance: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Apple TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
