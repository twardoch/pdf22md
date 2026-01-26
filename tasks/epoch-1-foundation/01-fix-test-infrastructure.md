# Task 1.1: Fix Test Infrastructure

## Problem

The XCTest module cannot be found when running `swift test`. This blocks all automated testing.

## Root Cause (Diagnosed)

`xcode-select` is pointing to Command Line Tools instead of full Xcode:
```
/Library/Developer/CommandLineTools  ❌ No XCTest
```

XCTest is only available in full Xcode, not Command Line Tools.

## Solution

Switch xcode-select to use Xcode.app (requires admin/sudo):

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Verify with:
```bash
xcode-select -p
# Should show: /Applications/Xcode.app/Contents/Developer
```

## Acceptance Criteria

- [ ] `xcode-select -p` points to Xcode.app, not CommandLineTools
- [ ] `swift test` runs without "No such module 'XCTest'" error
- [ ] Existing test file compiles and executes
- [ ] At least one test passes to verify infrastructure works

## Technical Details

- The Package.swift test target configuration is correct
- The test file imports are correct (XCTest, @testable import PDF22MD)
- The issue is environmental (system SDK selection)
- No code changes needed - just toolchain configuration

## Verification

```bash
# 1. Fix toolchain (one-time, requires sudo)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 2. Verify tests run
cd pdf22md && swift test
```

Expected: Tests compile and run (may have failures, but XCTest import works).
