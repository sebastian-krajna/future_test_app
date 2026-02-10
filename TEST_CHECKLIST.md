# 📋 Test Execution Checklist

Print this and check off as you complete each test!

---

## Pre-Test Setup

- [ ] Flutter version checked: `flutter --version`
- [ ] Device/emulator connected: `flutter devices`
- [ ] Project built successfully
- [ ] Opened native log viewer (adb logcat / Xcode Console)

---

## Android DEBUG Mode

**Command:** `flutter run`

- [ ] **TEST 1** - Future Never Resolved
  - Expected: Timeout after 5s ⏱️
  - Actual: _____________________
  
- [ ] **TEST 2** - Throws Error (WITH try/catch)
  - Expected: Error caught ✅
  - Actual: _____________________
  
- [ ] **TEST 3** - Returns Null
  - Expected: null received ✅
  - Actual: _____________________
  
- [ ] **TEST 4** - Tealium Bug Simulation
  - Expected: Timeout after 5s ⏱️
  - Actual: _____________________
  
- [ ] **TEST 5** - ⚠️ NO try/catch
  - Expected: Red screen or crash 💥
  - App crashed? ⬜ YES  ⬜ NO
  - Red screen showed? ⬜ YES  ⬜ NO
  
- [ ] **TEST 6** - Fire & Forget (unawaited)
  - Expected: No immediate crash ✅
  - App crashed? ⬜ YES  ⬜ NO
  
- [ ] **TEST 7** - .then() Pattern
  - Expected: Error caught ✅
  - Actual: _____________________
  
- [ ] **TEST 8** - Multiple Rapid Calls (10x)
  - Expected: All timeout ~20s ⏱️
  - Actual: _____________________
  
- [ ] **TEST 9** - Future.wait() Mixed
  - Expected: Complete in ~3s ✅
  - Actual: _____________________

- [ ] **Copied logs to clipboard** (📋 button)
- [ ] **Saved native logs** to file

---

## Android RELEASE Mode

**Command:** `flutter run --release`

- [ ] **TEST 1** - Future Never Resolved
  - Actual: _____________________
  
- [ ] **TEST 2** - Throws Error (WITH try/catch)
  - Actual: _____________________
  
- [ ] **TEST 3** - Returns Null
  - Actual: _____________________
  
- [ ] **TEST 4** - Tealium Bug Simulation
  - Actual: _____________________
  
- [ ] **TEST 5** - ⚠️ NO try/catch
  - App crashed? ⬜ YES  ⬜ NO
  - Different from DEBUG? ⬜ YES  ⬜ NO
  
- [ ] **TEST 6** - Fire & Forget (unawaited)
  - App crashed? ⬜ YES  ⬜ NO
  - Different from DEBUG? ⬜ YES  ⬜ NO
  
- [ ] **TEST 7** - .then() Pattern
  - Actual: _____________________
  
- [ ] **TEST 8** - Multiple Rapid Calls (10x)
  - Actual: _____________________
  
- [ ] **TEST 9** - Future.wait() Mixed
  - Actual: _____________________

- [ ] **Copied logs to clipboard**
- [ ] **Saved native logs** to file

---

## iOS DEBUG Mode

**Command:** `flutter run -d iPhone`

- [ ] Xcode Console opened and filtered `FutureTest`

- [ ] **TEST 1** - Actual: _____________________
- [ ] **TEST 2** - Actual: _____________________
- [ ] **TEST 3** - Actual: _____________________
- [ ] **TEST 4** - Actual: _____________________
- [ ] **TEST 5** - Crashed? ⬜ YES  ⬜ NO
- [ ] **TEST 6** - Crashed? ⬜ YES  ⬜ NO
- [ ] **TEST 7** - Actual: _____________________
- [ ] **TEST 8** - Actual: _____________________
- [ ] **TEST 9** - Actual: _____________________

- [ ] **Copied logs to clipboard**
- [ ] **Saved Xcode Console logs**

---

## iOS RELEASE Mode

**Command:** `flutter run --release -d iPhone`

- [ ] **TEST 1** - Actual: _____________________
- [ ] **TEST 2** - Actual: _____________________
- [ ] **TEST 3** - Actual: _____________________
- [ ] **TEST 4** - Actual: _____________________
- [ ] **TEST 5** - Crashed? ⬜ YES  ⬜ NO
- [ ] **TEST 6** - Crashed? ⬜ YES  ⬜ NO
- [ ] **TEST 7** - Actual: _____________________
- [ ] **TEST 8** - Actual: _____________________
- [ ] **TEST 9** - Actual: _____________________

- [ ] **Copied logs to clipboard**
- [ ] **Saved Xcode Console logs**

---

## Post-Test Analysis

- [ ] Filled out `TEST_RESULTS_TEMPLATE.md`
- [ ] Compared DEBUG vs RELEASE results
- [ ] Took screenshots of critical tests (TEST 5, TEST 6)
- [ ] Analyzed native logs

---

## Critical Questions

### Is it a breaking change?

**TEST 5 (awaited with no try/catch):**
- Android DEBUG crashed? ⬜ YES  ⬜ NO
- Android RELEASE crashed? ⬜ YES  ⬜ NO
- iOS DEBUG crashed? ⬜ YES  ⬜ NO
- iOS RELEASE crashed? ⬜ YES  ⬜ NO

**TEST 6 (unawaited - fire & forget):**
- Android DEBUG crashed? ⬜ YES  ⬜ NO
- Android RELEASE crashed? ⬜ YES  ⬜ NO
- iOS DEBUG crashed? ⬜ YES  ⬜ NO
- iOS RELEASE crashed? ⬜ YES  ⬜ NO

### Conclusion

⬜ **YES - BREAKING CHANGE** (if any of the above crashed)

⬜ **NO - NOT BREAKING** (if none crashed, only red screen in debug)

⬜ **MAYBE - DEPENDS** (if behavior differs between debug/release or awaited/unawaited)

---

## Recommendation

⬜ **Option A:** Return null when not found

⬜ **Option B:** Throw errors when not found

⬜ **Option C:** Wait for v3.0

**Reasoning:**

_______________________________________
_______________________________________
_______________________________________
_______________________________________

---

## Share with Team

- [ ] Results template filled
- [ ] All logs collected
- [ ] Screenshots prepared
- [ ] Recommendation documented
- [ ] Scheduled meeting to present findings

**Meeting Date:** _______________

**Attendees:** ________________________________

---

## Notes

_______________________________________
_______________________________________
_______________________________________
_______________________________________
_______________________________________
_______________________________________
