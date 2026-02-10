# Future resolution – test results summary

Four scenarios were tested in a Flutter app using MethodChannel. Each test invokes a native method with **no** try/catch on the Dart side.

## Test scenarios

### TEST 1: neverResolves
- **Native:** never calls `result()` / `result.success()` / `result.error()`.
- **Result:** The Future never resolves. After 5 s timeout a marker is returned; the test logs TIMEOUT.
- **Takeaway:** Callers can end up with "hanging" Futures – this is the problem to fix (e.g. getFromDataLayer).

### TEST 2: throwsError
- **Native:** calls `result.error("TEALIUM_NOT_INITIALIZED", "Tealium instance is null", null)`.
- **Result:** On the Flutter side the Future "rejects" as a PlatformException. With no try/catch, logs show "Unhandled Exception: PlatformException(...)".

### TEST 3: returnsNull
- **Native:** calls `result.success(null)` / `result(nil)`.
- **Result:** The Future resolves correctly; value is null (`runtimeType: Null`). No exceptions.

### TEST 4: nativeThrow
- **Native:** throws a real exception (RuntimeException on Android, NSException on iOS) without calling result.
- **Result:** Flutter receives a PlatformException (the platform channel forwards the native exception).

## Results by platform and build mode

| Platform | Build mode | TEST 1 | TEST 2 | TEST 3 | TEST 4 | Notes |
|----------|-----------|---------|---------|---------|---------|-------|
| **Android** | Debug | ✅ TIMEOUT | ✅ Unhandled Exception* | ✅ SUCCESS | ✅ Unhandled Exception* | *Shows error in logs, app continues running |
| **Android** | Release | ✅ TIMEOUT | ✅ Unhandled Exception* | ✅ SUCCESS | ✅ Unhandled Exception* | *Shows error in logs, app continues running |
| **iOS** | Debug | ✅ TIMEOUT | ✅ Unhandled Exception* | ✅ SUCCESS | ❌ **CRASH** | **App terminates** ("Lost connection to device") |
| **iOS** | Release | ❓ Not tested | ❓ Not tested | ❓ Not tested | ❓ Not tested | - |

### Key findings

**Android (both debug and release):**
- All tests complete without crashing the app
- TEST 2 and TEST 4 show "Unhandled Exception" in logs but app continues running
- No difference in behavior between debug and release modes

**iOS (debug only tested):**
- TEST 1, 2, 3 behave as expected
- TEST 2 shows "Unhandled Exception" in console but app continues
- **TEST 4 (nativeThrow) crashes the app** – process terminates with "Lost connection to device"
- This is a **real crash**, not just a red screen or log message

## Answers to the team's questions

### 1) "Is resolving with errors a breaking change?"

- When `result.error(...)` is used on the native side: in Dart the Future "rejects" and `await` without try/catch receives a PlatformException.
- **Android (debug & release):** No crash – only "Unhandled Exception" in logs; the app continues.
- **iOS (debug):** TEST 2 (`result.error()`) shows exception but app continues. However, TEST 4 (native exception thrown without calling result) **crashes the app entirely**.
- The distinction matters: using `result.error()` appears safer than allowing native exceptions to propagate uncaught.

### 2) "Consistency across methods and platforms"

- Consistency is recommended: if `result.error()` is used for "Tealium not initialized" in one method, the same should apply everywhere; same for missing/invalid parameters.
- Shared error constants (codes/messages) would help keep behavior consistent.
- **Important:** Ensure native code always calls a result method rather than throwing uncaught exceptions, especially on iOS where this can crash the app.

### 3) "Resolve with null vs error where possible"

- `getVisitorId()` / `getConsentStatus()` must return a concrete type (e.g. String), so "resolve with null" is not an option – it is either `result.success(value)` or `result.error(...)`.
- For those methods the choice is: consistent `result.error()` for errors, or (worse) not calling result at all and leaving the Future unresolved.

### 4) What was not tested

- **iOS release build** – behavior may differ from debug (crash in TEST 4 might not occur).
- **Edge cases** – other types of native exceptions or specific error conditions.

## Recommendation

Based on these results:
1. Always call `result.error()` or `result.success()` from native code – never leave Futures unresolved
2. Wrap native code in try/catch and use `result.error()` rather than letting exceptions propagate (TEST 4 crashes on iOS)
3. Use `result.error()` consistently for error conditions (Tealium not initialized, missing params, etc.)
4. Consider testing iOS release mode to confirm TEST 4 behavior
