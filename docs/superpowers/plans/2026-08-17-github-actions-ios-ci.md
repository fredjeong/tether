# Tether iOS GitHub Actions CI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deterministic GitHub-hosted Xcode build and full test verification so Codex cloud pull requests for Tether Sessions 5 through 10 can be merged only after unit and UI tests pass.

**Architecture:** A small repository script owns the reproducible `xcodebuild clean test` command, while one GitHub Actions workflow owns triggers, macOS/Xcode selection, permissions, cancellation, and failure artifact upload. The completed Session 4 branch supplies the first hosted test run before CI becomes a required `main` check.

**Tech Stack:** Bash 3.2+, GitHub Actions, GitHub-hosted `macos-26`, Xcode 26.5, iOS 26.5 Simulator, `xcodebuild`, `gh` CLI

## Global Constraints

- Work from `/Users/fredjeong/tether/.worktrees/session-4` on `codex/session-4`; do not create another worktree.
- Keep deployment target iOS 17.0, Swift language version 6.0, and the existing shared `Tether` scheme unchanged.
- Pin runner `macos-26`, Xcode `/Applications/Xcode_26.5.app`, and destination `platform=iOS Simulator,OS=26.5,name=iPhone 17 Pro`.
- Run both `TetherTests` and `TetherUITests` through one clean scheme test; do not add `-only-testing`, automatic retries, or an OS/device matrix.
- Disable simulator signing with `CODE_SIGNING_ALLOWED=NO` and add no Apple credentials, provisioning profiles, or repository secrets.
- Give the workflow only `contents: read`; use only GitHub-maintained checkout and artifact actions.
- Upload `.xcresult` only for failed or cancelled runs and retain it for seven days.
- Do not enable automatic pull request merging.
- Preserve all unrelated user changes and stop if the worktree is not clean before Task 1.

---

### Task 1: Reproducible Xcode Test Driver

**Files:**
- Create: `scripts/ci-test.sh`

**Interfaces:**
- Consumes: `Tether.xcodeproj`, shared scheme `Tether`, optional environment variable `RESULT_BUNDLE_PATH` containing an unused `.xcresult` path.
- Produces: executable `scripts/ci-test.sh`; a full-suite `xcodebuild` exit status; an `.xcresult` bundle at the selected path.

- [ ] **Step 1: Confirm the branch is ready**

Run:

```bash
git status --short --branch
test "$(git branch --show-current)" = "codex/session-4"
test -z "$(git status --porcelain)"
```

Expected: branch is `codex/session-4` and the worktree is clean.

- [ ] **Step 2: Run the missing-driver contract and verify RED**

Run:

```bash
test -x scripts/ci-test.sh
```

Expected: exit status 1 because `scripts/ci-test.sh` does not exist.

- [ ] **Step 3: Create the minimal test driver**

Create `scripts/ci-test.sh` with exactly this behavior:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -n "${RESULT_BUNDLE_PATH:-}" ]]; then
  result_bundle_path="$RESULT_BUNDLE_PATH"
else
  result_directory="$(mktemp -d "${TMPDIR:-/tmp}/tether-ci.XXXXXX")"
  result_bundle_path="$result_directory/TetherCI.xcresult"
fi

cd "$REPO_ROOT"

echo "Xcode result bundle: $result_bundle_path"

xcodebuild clean test \
  -project Tether.xcodeproj \
  -scheme Tether \
  -destination "platform=iOS Simulator,OS=26.5,name=iPhone 17 Pro" \
  -resultBundlePath "$result_bundle_path" \
  CODE_SIGNING_ALLOWED=NO
```

Make it executable:

```bash
chmod +x scripts/ci-test.sh
```

- [ ] **Step 4: Run static contract checks and verify GREEN**

Run:

```bash
bash -n scripts/ci-test.sh
test -x scripts/ci-test.sh
rg -n 'xcodebuild clean test|OS=26\.5,name=iPhone 17 Pro|CODE_SIGNING_ALLOWED=NO|RESULT_BUNDLE_PATH' scripts/ci-test.sh
```

Expected: syntax validation and executable check pass; `rg` prints all four contract elements.

- [ ] **Step 5: Run the driver against the local simulator**

Create an unused result path and run:

```bash
CI_RESULT_DIRECTORY="$(mktemp -d /private/tmp/tether-ci-local.XXXXXX)"
RESULT_BUNDLE_PATH="$CI_RESULT_DIRECTORY/TetherCI.xcresult" ./scripts/ci-test.sh
xcrun xcresulttool get test-results summary --path "$CI_RESULT_DIRECTORY/TetherCI.xcresult"
```

Expected: `xcodebuild` exits 0; the summary reports zero failed tests and includes both unit and UI test runs.

- [ ] **Step 6: Commit the driver**

```bash
git add scripts/ci-test.sh
git commit -m "test: add reproducible iOS CI driver"
```

---

### Task 2: GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/ios-ci.yml`
- Reuse: `scripts/ci-test.sh`

**Interfaces:**
- Consumes: executable `scripts/ci-test.sh`; GitHub `pull_request`, `push`, and `workflow_dispatch` events.
- Produces: workflow `iOS CI`; required-check candidate named `iOS CI`; failure artifact named `tether-test-results-<run attempt>`.

- [ ] **Step 1: Run the missing-workflow contract and verify RED**

Run:

```bash
test -f .github/workflows/ios-ci.yml
```

Expected: exit status 1 because the workflow does not exist.

- [ ] **Step 2: Create the workflow**

Create `.github/workflows/ios-ci.yml` with:

```yaml
name: iOS CI

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: iOS CI
    runs-on: macos-26
    timeout-minutes: 30
    env:
      RESULT_BUNDLE_PATH: ${{ runner.temp }}/TetherCI.xcresult

    steps:
      - name: Check out repository
        uses: actions/checkout@v6

      - name: Select Xcode 26.5
        run: sudo xcode-select -s /Applications/Xcode_26.5.app/Contents/Developer

      - name: Verify toolchain and simulator
        run: |
          xcodebuild -version
          xcrun simctl list devices available | grep -F "iPhone 17 Pro"
          xcrun simctl list runtimes | grep -F "iOS 26.5"

      - name: Build and test
        run: ./scripts/ci-test.sh

      - name: Upload failed test result
        if: ${{ failure() || cancelled() }}
        uses: actions/upload-artifact@v4
        with:
          name: tether-test-results-${{ github.run_attempt }}
          path: ${{ env.RESULT_BUNDLE_PATH }}
          if-no-files-found: warn
          retention-days: 7
```

- [ ] **Step 3: Validate YAML syntax and workflow contracts**

Run:

```bash
ruby -e 'require "yaml"; YAML.safe_load_file(ARGV.fetch(0), aliases: true)' .github/workflows/ios-ci.yml
rg -n 'pull_request:|push:|workflow_dispatch:|contents: read|cancel-in-progress: true' .github/workflows/ios-ci.yml
rg -n 'macos-26|Xcode_26\.5|iPhone 17 Pro|iOS 26\.5|timeout-minutes: 30' .github/workflows/ios-ci.yml
rg -n 'failure\(\) \|\| cancelled\(\)|actions/upload-artifact@v4|retention-days: 7' .github/workflows/ios-ci.yml
```

Expected: Ruby exits 0 and each `rg` command prints every required contract line.

- [ ] **Step 4: Run repository verification after workflow integration**

Run:

```bash
bash -n scripts/ci-test.sh
git diff --check
CI_RESULT_DIRECTORY="$(mktemp -d /private/tmp/tether-ci-workflow.XXXXXX)"
RESULT_BUNDLE_PATH="$CI_RESULT_DIRECTORY/TetherCI.xcresult" ./scripts/ci-test.sh
xcrun xcresulttool get test-results summary --path "$CI_RESULT_DIRECTORY/TetherCI.xcresult"
```

Expected: all commands exit 0; summary reports zero failed tests.

- [ ] **Step 5: Commit the workflow**

```bash
git add .github/workflows/ios-ci.yml
git commit -m "ci: test Tether on GitHub macOS runner"
```

---

### Task 3: First Hosted Pull Request Verification

**Files:**
- No new files.
- Verify: `.github/workflows/ios-ci.yml`, `scripts/ci-test.sh`, and the full Session 4 source tree.

**Interfaces:**
- Consumes: local `codex/session-4` commits and authenticated `gh`/Git remote access.
- Produces: published `codex/session-4`; pull request into `main`; hosted Xcode check named `iOS CI`.

- [ ] **Step 1: Verify the exact state being published**

Run:

```bash
git status --short --branch
git log --oneline --decorate origin/main..HEAD
git diff --check origin/main...HEAD
gh auth status
gh repo view fredjeong/tether --json nameWithOwner,visibility,defaultBranchRef,url
```

Expected: worktree is clean; the commit list contains Sessions 1 through 4, the CI design/plan, driver, and workflow; repository is `fredjeong/tether`, `PUBLIC`, default branch `main`.

- [ ] **Step 2: Publish the branch**

Run:

```bash
git push -u origin codex/session-4
```

Expected: GitHub creates or updates `origin/codex/session-4` at local `HEAD`.

- [ ] **Step 3: Open the rollout pull request**

Run:

```bash
gh pr create \
  --repo fredjeong/tether \
  --base main \
  --head codex/session-4 \
  --title "Build Tether through Session 4 and add iOS CI" \
  --body "Implements Tether Sessions 1 through 4 and adds deterministic Xcode 26.5 full-suite verification for future Codex cloud pull requests."
```

Expected: one open pull request URL targeting `main` from `codex/session-4`.

- [ ] **Step 4: Wait for the hosted check**

Run:

```bash
gh pr checks --repo fredjeong/tether --watch --fail-fast
```

Expected: required-check candidate `iOS CI` completes successfully. If it fails, do not merge; inspect the job logs with `gh run view --log-failed` and apply `superpowers:systematic-debugging` plus `github:gh-fix-ci` before continuing.

- [ ] **Step 5: Confirm the check covers both test targets**

Run:

```bash
RUN_ID="$(gh run list --repo fredjeong/tether --workflow ios-ci.yml --branch codex/session-4 --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run view "$RUN_ID" --repo fredjeong/tether --log | rg 'TetherTests|TetherUITests|TEST SUCCEEDED'
```

Expected: logs contain both test target names and `TEST SUCCEEDED`.

---

### Task 4: Merge Gate and Manual Run

**Files:**
- No new files.
- External configuration: `main` branch protection for `fredjeong/tether`.

**Interfaces:**
- Consumes: green Session 4 pull request and check context `iOS CI`.
- Produces: Session 4 plus CI on `main`; required `iOS CI` status check; verified manual workflow dispatch.

- [ ] **Step 1: Merge only the green pull request**

Run:

```bash
gh pr merge --repo fredjeong/tether --merge --delete-branch=false
```

Expected: pull request is merged with its individual Session commits preserved; `main` contains `ios-ci.yml` and `ci-test.sh`.

- [ ] **Step 2: Require the hosted check on `main`**

Run:

```bash
gh api \
  --method PUT \
  repos/fredjeong/tether/branches/main/protection \
  -F 'required_status_checks[strict]=true' \
  -f 'required_status_checks[contexts][]=iOS CI' \
  -F enforce_admins=false \
  -F required_pull_request_reviews=null \
  -F restrictions=null
```

Expected: HTTP 200 response; required status contexts contain `iOS CI`. Automatic merge remains disabled.

- [ ] **Step 3: Verify branch protection**

Run:

```bash
gh api repos/fredjeong/tether/branches/main/protection \
  --jq '{strict: .required_status_checks.strict, contexts: .required_status_checks.contexts, enforce_admins: .enforce_admins.enabled}'
```

Expected:

```json
{"strict":true,"contexts":["iOS CI"],"enforce_admins":false}
```

- [ ] **Step 4: Verify manual dispatch from `main`**

Run:

```bash
gh workflow run ios-ci.yml --repo fredjeong/tether --ref main
RUN_ID="$(gh run list --repo fredjeong/tether --workflow ios-ci.yml --branch main --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID" --repo fredjeong/tether --exit-status
```

Expected: manual `main` run completes successfully.

- [ ] **Step 5: Final verification**

Run:

```bash
gh repo view fredjeong/tether --json visibility,defaultBranchRef,url
gh workflow view ios-ci.yml --repo fredjeong/tether
gh run list --repo fredjeong/tether --workflow ios-ci.yml --limit 3
git status --short --branch
```

Expected: repository remains public; `main` is the default branch; workflow is active; latest PR, push, and manual runs are successful; local worktree is clean.

## Completion Criteria

- `scripts/ci-test.sh` reproduces a clean full-suite test locally and returns the original `xcodebuild` status.
- `.github/workflows/ios-ci.yml` passes local syntax and contract checks.
- Hosted `macos-26` selects Xcode 26.5 and runs all Session 4 unit and UI tests on iPhone 17 Pro/iOS 26.5.
- Session 4 and CI are merged into `main` only after the hosted check is green.
- `main` requires the `iOS CI` context and manual dispatch from `main` passes.
- No signing credentials, repository secrets, automatic retry, automatic merge, or unrelated project changes are introduced.
