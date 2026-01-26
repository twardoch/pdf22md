# Task 1.4: Setup CI Pipeline

## Problem

No automated CI to catch regressions. Manual testing is error-prone.

## Acceptance Criteria

- [ ] GitHub Actions workflow for macOS builds
- [ ] Runs on push to main and PRs
- [ ] Builds release configuration
- [ ] Runs test suite
- [ ] Runs example.sh functional tests

## Workflow Steps

1. Checkout code
2. Setup Swift toolchain (macOS runner has it)
3. Run `swift build -c release`
4. Run `swift test`
5. Run `./example.sh -q` (quiet mode)
6. Report results

## File Location

`.github/workflows/ci.yml`

## Verification

Push a commit and verify GitHub Actions runs successfully.
