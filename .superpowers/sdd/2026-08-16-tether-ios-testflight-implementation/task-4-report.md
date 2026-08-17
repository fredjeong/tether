# Task 4 Report — Root Navigation and Onboarding

## Status

Completed Task 4 only. The app now routes a new install through a one-screen welcome and validated habit setup, persists exactly one created Habit, and shows a stable Today/History tab shell on success or later startup.

## What Changed

- Added `AppEnvironment` and observable `AppModel` routing for `.onboarding` and `.main`, including model-owned Habit Setup presentation state that is cleared after creation or reset.
- Made `RootView` load the persisted Habit before its first route is displayed, show the welcome/setup flow when absent, and show non-interactive Today and History placeholders when present.
- Added the welcome screen with the PRD product name, one-liner, headline, supporting copy, Done/Light/Rest descriptions, and setup CTA.
- Added habit setup with 40/80/80 live limits, trimmed validation through `HabitDraft`, standard keyboard order, plain-English text input settings, and neutral save-error presentation.
- Added reusable `ErrorBanner` because it was not present in the project.
- Added the `-ui-testing-reset` launch-only path, clearing SwiftData before `RootView` is created.
- Added focused onboarding unit/UI coverage and made the pre-existing launch UI test use the deterministic reset path so tests cannot leak state between one another.
- Marked only Task 4 checklist items complete.

## Files Changed

- `Tether.xcodeproj/project.pbxproj`
- `Tether/App/AppEnvironment.swift`
- `Tether/App/AppModel.swift`
- `Tether/App/RootView.swift`
- `Tether/App/TetherApp.swift`
- `Tether/Features/Onboarding/WelcomeView.swift`
- `Tether/Features/Onboarding/HabitSetupView.swift`
- `Tether/Features/Onboarding/OnboardingViewModel.swift`
- `Tether/Shared/AppCopy.swift`
- `Tether/Shared/ErrorBanner.swift`
- `TetherTests/Features/OnboardingViewModelTests.swift`
- `TetherUITests/OnboardingUITests.swift`
- `TetherUITests/TetherUITests.swift`
- `docs/superpowers/plans/2026-08-16-tether-ios-testflight-implementation.md`

## TDD and Test Evidence

### RED

1. Command:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:TetherTests/OnboardingViewModelTests`

   Expected failure observed before production implementation: `cannot find type 'AppModel' in scope`, `cannot find type 'AppEnvironment' in scope`, and `cannot find type 'OnboardingViewModel' in scope`.

2. Command:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:TetherUITests/OnboardingUITests`

   Expected failure observed before production implementation: the scheme builds the unit-test target as well, so it failed for the same missing onboarding types and cancelled UI execution.

3. Additional PRD-copy RED after review:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,id=2938D0B3-E5EE-49D2-A6CB-A3DF3DB3DF5B' -only-testing:TetherUITests/OnboardingUITests`

   Expected failure observed: the assertion for `A habit tracker where rest counts.` failed before the welcome one-liner was added.

4. Navigation-state regression RED after code review:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:TetherTests/OnboardingViewModelTests`

   Expected failure observed before the model state was added: `AppModel has no member 'presentHabitSetup'` and `AppModel has no member 'isPresentingHabitSetup'`. The test states the observable navigation contract: opening setup, then completing onboarding or resetting, must leave setup unpresented. This is the state that prevents a newly recreated `NavigationStack` from reopening Habit Setup after reset.

### GREEN

1. Focused unit tests:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:TetherTests/OnboardingViewModelTests`

   Result: `** TEST SUCCEEDED **`.

2. Focused UI test:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,id=2938D0B3-E5EE-49D2-A6CB-A3DF3DB3DF5B' -only-testing:TetherUITests/OnboardingUITests`

   Result: 1 test executed with 0 failures; `** TEST SUCCEEDED **`.

3. Full suite:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,id=2938D0B3-E5EE-49D2-A6CB-A3DF3DB3DF5B' -resultBundlePath /private/tmp/tether-session4-full-green.xcresult -quiet`

   Result: finalized result bundle reports `TetherUITests`, `TetherTests`, and root `Tether` all `Passed`.

4. App build:

   `xcodebuild build -project Tether.xcodeproj -scheme Tether -destination 'generic/platform=iOS Simulator' -quiet`

   Result: exit code 0.

5. Final focused UI regression verification after the navigation-state fix:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,id=2938D0B3-E5EE-49D2-A6CB-A3DF3DB3DF5B' -only-testing:TetherUITests/OnboardingUITests`

   Result: `testOnboardingCreatesAHabitAndReachesTheMainTabShell()` passed.

6. Final complete-suite verification after the navigation-state fix:

   `xcodebuild test -project Tether.xcodeproj -scheme Tether -destination 'platform=iOS Simulator,id=2938D0B3-E5EE-49D2-A6CB-A3DF3DB3DF5B' -resultBundlePath /private/tmp/tether-session4-final-full.xcresult -quiet`

   Result: after confirming bundle finalization, `xcresulttool` reported root `Tether`, `TetherTests`, and `TetherUITests` as `Passed`, including `completingOrResettingOnboardingClearsHabitSetupPresentation()`.

7. Final app build after the navigation-state fix:

   `xcodebuild build -project Tether.xcodeproj -scheme Tether -destination 'generic/platform=iOS Simulator' -quiet`

   Result: exit code 0.

## Verification Investigation

The first full-suite command initially appeared to return before its result bundle finalized. Process inspection showed `xcodebuild` and `TetherUITests-Runner` were still active while the bundle was staged; after a bounded wait, `Info.plist` appeared and the bundle finalized. Its actual failure was deterministic state leakage: `OnboardingUITests` created a Habit, then the legacy launch test expected the welcome screen. The targeted correction was to launch that legacy test with `-ui-testing-reset`. A clean rerun with an explicit booted simulator ID and separate result path passed every suite.

Code review later identified a separate, load-bearing navigation-state defect: a local `RootView` presentation boolean could remain true after `didReset`, causing a recreated onboarding navigation stack to reopen Habit Setup. The focused red test introduced model-observable setup presentation state, then the minimal correction moved that state into `AppModel` and clears it in both `didCreateHabit` and `didReset`. The final focused UI, full suite, and app build above verified the correction.

## Self-Review

- Scope: limited to Session 4 routing, onboarding, reset support, placeholder main shell, required tests, and the checklist update; no Today check-in, History implementation, Settings, or reminder behavior was added.
- Requirements: welcome is a single screen; exact finalized PRD copy and the PRD one-liner are visible; field IDs and tab ID are stable; setup has no reminder control; character limits are enforced while typing.
- Persistence/routing: SwiftData remains the source of truth; `AppModel` routes a pre-existing Habit to main, routes save errors nowhere, and owns/clears transient Habit Setup navigation state when onboarding completes or resets.
- Test quality: unit tests exercise draft validation and store state through a small deterministic test store; the UI test covers reset, welcome, form entry, save, and the main tab shell. No mock-call assertions were used.
- Swift 6: all store, environment, model, and view-model interactions remain main-actor isolated; `DayProviding` remains Sendable.
- Hygiene: `git diff --check` was clean before final review.

## Concerns

No product or code concerns. The Xcode CLI runner can continue producing a staged result bundle after this environment reports the command cell complete; verification therefore waited for the result bundle to finalize and read it with `xcresulttool` rather than relying on the early command-cell output.
