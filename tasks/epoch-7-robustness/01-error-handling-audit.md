# Task 7.1: Error Handling Audit

## Problem

Error handling may be inconsistent across the codebase. Need comprehensive review.

## Acceptance Criteria

- [ ] Audit all error handling code paths
- [ ] Ensure no empty catch blocks
- [ ] Ensure errors have helpful messages
- [ ] User-facing errors are actionable
- [ ] Internal errors logged with context

## Error Categories

### User Errors (actionable)
- File not found → "Cannot find PDF: {path}. Check the path and try again."
- Password required → "PDF is encrypted. Use -p to provide password."
- Invalid format → "Not a valid PDF file: {path}"

### System Errors (informative)
- Memory issues → "Out of memory processing page {n}. Try --low-memory mode."
- Permission denied → "Cannot write to {path}. Check permissions."

### Internal Errors (debug)
- Logged with stack trace
- Hidden from user unless --verbose

## Verification

Test each error condition and verify messages are helpful.
