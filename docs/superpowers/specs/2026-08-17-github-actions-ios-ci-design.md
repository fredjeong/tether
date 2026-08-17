# Tether iOS GitHub Actions CI Design

**Date:** 2026-08-17
**Status:** Approved for implementation
**Scope:** Continuous integration for Tether Sessions 5 through 10

## Context

Tether is a small, English-only iPhone app built with Swift 6, SwiftUI, and SwiftData. Sessions 5 through 10 add UI, persistence, notifications, and lifecycle behavior. The implementation plan requires every session to run the existing test suite before editing and to finish with a successful full test run.

Codex cloud can create branches and pull requests but cannot run Xcode or an iOS Simulator in its Linux container. The public `fredjeong/tether` repository can instead use a standard GitHub-hosted macOS runner to provide the missing Xcode verification.

The local project currently uses Xcode 26.5. The selected GitHub `macos-26` image provides Xcode 26.5 and an iPhone 17 Pro simulator running iOS 26.5, so CI can reproduce the local toolchain without using `latest` aliases.

## Goals

- Run the complete `TetherTests` and `TetherUITests` suites for every pull request targeting `main`.
- Run the same verification after changes land on `main`.
- Allow a manual run from GitHub Actions on a phone or web browser.
- Keep the Xcode, iOS runtime, and simulator destination deterministic.
- Make CI failures diagnosable without requiring access to the original runner.
- Give Sessions 5 through 10 a reliable green check before each sequential merge.

## Non-goals

- App Store signing, archiving, notarization, or TestFlight upload.
- Apple Developer certificates, provisioning profiles, or repository secrets.
- Testing multiple Xcode, iOS, or device combinations.
- Automatically retrying failed tests.
- Automatically merging pull requests.
- Replacing the real-device, accessibility, and release checks in Sessions 11 through 13.

## Selected Approach

Use one macOS job that performs a clean build and runs the full unit and UI test suite. This is preferred over a split unit/UI pipeline because the app is currently small and the session completion criteria require both suites. A device and OS matrix would add runtime, flakiness, and maintenance without serving the one-device MVP.

The implementation will add two files:

- `.github/workflows/ios-ci.yml` owns GitHub triggers, runner selection, permissions, concurrency, timeout, Xcode selection, and failure artifact upload.
- `scripts/ci-test.sh` owns the repository-local `xcodebuild` invocation so the same command can be reproduced on a developer Mac.

## Workflow Triggers and Concurrency

The workflow will run on:

- `pull_request` events targeting `main`;
- pushes to `main` after a merge; and
- `workflow_dispatch` for manual verification.

The concurrency group will combine the workflow name and Git ref. `cancel-in-progress: true` will cancel an obsolete run when a newer commit is pushed to the same pull request or branch. Independent pull requests will not cancel one another.

## Runner and Toolchain

The job will use:

- runner label `macos-26`;
- `/Applications/Xcode_26.5.app` selected explicitly with `xcode-select`;
- `platform=iOS Simulator,OS=26.5,name=iPhone 17 Pro` as the exact destination;
- a 30-minute job timeout; and
- `CODE_SIGNING_ALLOWED=NO` because simulator tests do not require signing.

A preflight step will print the selected Xcode version and confirm the requested simulator destination exists. If GitHub later removes the pinned Xcode or runtime, CI will fail with an environment-specific message instead of silently switching toolchains.

## Test Command Contract

`scripts/ci-test.sh` will:

1. Resolve the repository root from the script location rather than the caller's working directory.
2. Accept `RESULT_BUNDLE_PATH` as an optional environment variable and otherwise create a unique temporary result location.
3. Execute a clean full test run for `Tether.xcodeproj` and the shared `Tether` scheme.
4. Target the pinned iPhone 17 Pro/iOS 26.5 simulator.
5. Write an `.xcresult` bundle and preserve the original `xcodebuild` exit status.

The command will run both test targets through the shared scheme. It will not use `-only-testing`, `OS=latest`, test retries, or signing credentials.

## Diagnostics and Failure Handling

The workflow log will retain raw `xcodebuild` output. On failure or cancellation, an official GitHub artifact action will upload the `.xcresult` bundle with seven-day retention. Successful bundles will not be uploaded to avoid accumulating unnecessary artifacts.

Only GitHub-maintained actions will be used for checkout and artifact upload, pinned to current stable major versions. The workflow will grant only `contents: read` permission and will not expose secrets.

CI will not retry failures automatically. A failed test must be investigated as either a product regression, a deterministic test issue, or simulator flakiness. A maintainer can then use the manual workflow or rerun the failed job after addressing the cause.

## Branch and Session Flow

The initial rollout will add CI on top of the completed `codex/session-4` branch and publish that branch. Its pull request into `main` will provide the first hosted verification of Sessions 1 through 4.

After the first successful run:

1. Merge Session 4 and CI into `main`.
2. Configure `main` to require the `iOS CI` check before merge.
3. Start Session 5 from the updated `main`.
4. Let Codex cloud create the implementation and pull request.
5. Merge only after the full CI check succeeds.
6. Repeat from the new `main` through Session 10.

Automatic merging remains disabled. The user retains the final merge decision from GitHub Mobile or the web UI.

## Security and Repository Policy

The workflow executes untrusted repository code on an ephemeral GitHub-hosted runner, with read-only repository contents and no Apple or deployment secrets. Pull requests do not receive additional credentials. The CI scope is build and test only.

The repository is public, so its complete source and Git history are intentionally public. No local credentials, generated test data, `.xcresult` bundles, or developer-specific Xcode state will be committed.

## Acceptance Criteria

- GitHub recognizes `.github/workflows/ios-ci.yml` without a syntax error.
- A pull request targeting `main` starts exactly one current CI run per ref; newer commits cancel obsolete runs.
- CI reports Xcode 26.5 and resolves iPhone 17 Pro on iOS 26.5.
- A clean `xcodebuild test` runs all `TetherTests` and `TetherUITests` with signing disabled.
- The completed Session 4 suite passes on the GitHub-hosted runner.
- A failed run preserves an `.xcresult` artifact for seven days.
- The workflow can be started manually after it exists on `main`.
- No Apple credentials or repository write permission are required.
- `main` can be configured to require the successful `iOS CI` check before merge.

## Maintenance

The runner label, Xcode path, iOS runtime, and simulator name are intentionally pinned. Update them together in a dedicated maintenance change after confirming the replacement combination is installed on GitHub's runner image and passes the full suite locally or in a test pull request.
