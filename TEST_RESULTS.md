# Future Resolution Test Results

## Task Context

**Issue:** Some async method channel methods (Flutter ↔ Kotlin/Swift) do not resolve the returned `Future` in all code paths.

**Example:** `getFromDataLayer(String key)` is defined in Dart as:

```dart
static Future<dynamic> getFromDataLayer(String key) async {
  return await _channel.invokeMethod('getFromDataLayer', {'key': key});
}
```

The Kotlin implementation only calls `result.success(...)` when the key exists in the data layer. If the key is not found, or the Tealium instance is null, `result` is never called, so the Flutter `Future` never completes.

**Scope:** The same pattern appears in other methods; behaviour should be consistent across methods and platforms (Kotlin and Swift). Possible strategies:

- **Resolve with errors** (e.g. `result.error(...)`) for invalid/missing params and uninitialized Tealium — preferred if not behaviourally breaking.
- **Resolve with null** where the return type allows it (not possible for `Future<String>` e.g. `getVisitorId`, `getConsentStatus`).

**Note:** Resolving with errors may be behaviourally breaking: callers that `await` without try/catch could see `PlatformException` and potentially crash. Consistency and shared error constants across methods are desired.

---

## Test Environment

**Date:** 2025-02-10  
**Platform:** Android (Kotlin)  
**App:** future_test_app (method channel `com.example.future_test`)

**Note:** Run 1 and Run 2 are **DEBUG**; Run 3 is **RELEASE** (Android).

---

## Test Results Summary

### Run 1: With try/catch (Debug)

| Test # | Test Name              | Result   | Finding |
|--------|------------------------|----------|---------|
| 1      | neverResolves          | TIMEOUT  | Native never calls `result()` → Future never resolves (confirms bug). |
| 2      | throwsError            | CAUGHT   | Native calls `result.error()` → Flutter receives PlatformException; try/catch works. |
| 3      | returnsNull            | SUCCESS  | Native calls `result.success(null)` → Future resolves with null. |
| 4      | nativeThrow            | CAUGHT   | Method not implemented → Flutter gets `MissingPluginException` (not `result.error()`). |

### Run 2: Without try/catch (Debug)

| Test # | Test Name     | Result              | Finding |
|--------|---------------|---------------------|---------|
| 1      | neverResolves | TIMEOUT             | Same as Run 1; timeout works. |
| 2      | throwsError   | Unhandled Exception | `PlatformException` logged to console; **no red screen** observed. |
| 3      | returnsNull   | SUCCESS             | Same as Run 1. |
| 4      | nativeThrow   | Unhandled Exception | Kotlin `RuntimeException` → Flutter gets `PlatformException`; **no red screen** observed. |

**Conclusion (Run 2):** In **debug**, with **no try/catch** around `await platform.invokeMethod(...)`, unhandled `PlatformException`s are printed to the console (`E/flutter: Unhandled Exception: PlatformException(...)`), but **no red error screens** were observed. The app continued to run; further tests could be triggered.

### Run 3: Release — without try/catch (Android)

**Setup:** Same as Run 2 (no try/catch in Flutter). Build: `flutter run --release` on **sdk gphone64 arm64** (Android 16 emulator). Each button was pressed **twice**.

| Test # | Test Name     | Result              | Finding |
|--------|---------------|---------------------|---------|
| 1      | neverResolves | TIMEOUT             | Same as debug; timeout works. |
| 2      | throwsError   | Unhandled Exception | `PlatformException` logged; **no red screen**, **no crash**. |
| 3      | returnsNull   | SUCCESS             | Same as debug. |
| 4      | nativeThrow   | Unhandled Exception | Kotlin `RuntimeException` → Flutter `PlatformException`; **no red screen**, **no crash**. |

**Conclusion (Run 3):** In **release**, unhandled `PlatformException`s are again only printed to the console. **No red error screen** and **no app crash** were observed. Behaviour matches debug: the app kept running and all tests (including second round) could be executed. Resolving with errors from the native side does **not** cause a crash in release when the Dart caller does not use try/catch.

---

## Detailed Results

### TEST 1: neverResolves

**Purpose:** Simulate the Tealium bug where the native side never calls `result()` (e.g. key not found or Tealium null).

**Expected:** Future never resolves; test times out after 5s; app does not crash.

**Actual:**

- **Status:** TIMEOUT  
- **Details:** Future never resolved.

**Flutter log:**
```
TEST 1: neverResolves
Status: STARTED — Calling method that never calls result()
...
Status: TIMEOUT — Future never resolved
```

**Kotlin log:**
```
KOTLIN: Method called: neverResolves
KOTLIN: Arguments: null
KOTLIN: ⚠️ BUG SIMULATION - NOT resolving the Future
KOTLIN: This mimics the Tealium bug where result() is never called
```

**Conclusion:** Confirms that when the native side does not call `result.success()` or `result.error()`, the Flutter `Future` never completes and the test correctly detects a timeout.

---

### TEST 2: throwsError

**Purpose:** Native calls `result.error(...)` (e.g. Tealium not initialized); Flutter uses try/catch.

**Expected:** PlatformException is caught; app does not crash.

**Actual:**

- **Status:** CAUGHT  
- **Details:** PlatformException: TEALIUM_NOT_INITIALIZED - Tealium instance is null

**Flutter log:**
```
TEST 2: throwsError
Status: STARTED — Calling method that throws PlatformException (with try/catch)
...
Status: CAUGHT — PlatformException: TEALIUM_NOT_INITIALIZED - Tealium instance is null
```

**Kotlin log:**
```
KOTLIN: Method called: throwsError
KOTLIN: ✅ Throwing PlatformException (proper error handling)
KOTLIN: ✅ result.error() called - Future will resolve with error
```

**Conclusion:** When the native side calls `result.error()`, the Future resolves with an error and Flutter can handle it with try/catch. This is the desired pattern for error cases.

---

### TEST 3: returnsNull

**Purpose:** Native calls `result.success(null)` (e.g. key not found, return “no value”).

**Expected:** Future resolves with null.

**Actual:**

- **Status:** SUCCESS  
- **Details:** Received: null (type: Null)

**Flutter log:**
```
TEST 3: returnsNull
Status: STARTED — Calling method that returns null
...
Status: SUCCESS — Received: null (type: Null)
```

**Kotlin log:**
```
KOTLIN: Method called: returnsNull
KOTLIN: ✅ Returning null
KOTLIN: ✅ result.success(null) called - Future resolved
```

**Conclusion:** Resolving with null works when the Dart API allows a nullable return type. Not applicable for methods that must return a non-null type (e.g. `getVisitorId`, `getConsentStatus`).

---

### TEST 4: nativeThrow

**Purpose:** Native code throws (e.g. RuntimeException) without calling `result()`.

**Expected:** Some form of error propagates to Flutter (implementation-dependent).

**Actual:**

- **Status:** CAUGHT  
- **Details:** Exception: MissingPluginException(No implementation found for method nativeThrow on channel com.example.future_test)

**Flutter log:**
```
TEST 4: nativeThrow
Status: STARTED — Native code will throw (RuntimeException/NSException), no result()
...
Status: CAUGHT — Exception: MissingPluginException(No implementation found for method nativeThrow on channel com.example.future_test)
```

**Kotlin log:**
```
KOTLIN: Method called: nativeThrow
KOTLIN: Method not implemented: nativeThrow
```

**Conclusion:** In this run, `nativeThrow` was not implemented on the Kotlin side, so Flutter received `MissingPluginException` rather than a native crash or `result.error()`. For a real “native throws without calling result” scenario, behaviour on Android/iOS would need to be verified separately (e.g. whether the engine reports it as an error or the Future still hangs).

---

## Run 2: Without try/catch (Debug)

**Setup:** Flutter tests were changed to remove all try/catch around `platform.invokeMethod(...)`. Kotlin side: `throwsError` calls `result.error(...)`; `nativeThrow` throws `RuntimeException` (no `result()` call).

**Findings:**

- **TEST 1 (neverResolves):** TIMEOUT as before; no crash.
- **TEST 2 (throwsError):** Native calls `result.error()`. Flutter receives unhandled `PlatformException(TEALIUM_NOT_INITIALIZED, Tealium instance is null, null, null)`. Logged to console; **no red screen** in debug.
- **TEST 3 (returnsNull):** SUCCESS as before.
- **TEST 4 (nativeThrow):** Kotlin throws `RuntimeException: Native exception test`. Flutter engine turns it into `PlatformException(error, Native exception test, null, ...)` and delivers it to Dart. Unhandled exception logged to console; **no red screen** in debug.

**Raw log (Run 2, excerpt):**

```
I/flutter: FLUTTER TEST LOG #3 — TEST 1: neverResolves — Status: TIMEOUT — Details: Future never resolved
I/flutter: FLUTTER TEST LOG #4 — TEST 1: neverResolves — Status: STARTED — Details: Calling method that never calls result()
D/FutureTestApp: KOTLIN: Method called: neverResolves
W/FutureTestApp: KOTLIN: NOT resolving Future
I/flutter: FLUTTER TEST LOG #5 — TEST 2: throwsError — Status: STARTED — Details: Calling method that throws PlatformException (NO try/catch)
D/FutureTestApp: KOTLIN: Method called: throwsError
D/FutureTestApp: KOTLIN: result.error() called
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(TEALIUM_NOT_INITIALIZED, Tealium instance is null, null, null)
E/flutter: #0      StandardMethodCodec.decodeEnvelope ...
E/flutter: #2      _MyHomePageState._testThrowsError (package:future_test_app/main.dart:112:20)
...
I/flutter: FLUTTER TEST LOG #6 — TEST 1: neverResolves — Status: TIMEOUT
I/flutter: FLUTTER TEST LOG #7–8 — TEST 3: returnsNull — STARTED → SUCCESS — Received: null (type: Null)
D/FutureTestApp: KOTLIN: result.success(null) called
I/flutter: FLUTTER TEST LOG #9 — TEST 4: nativeThrow — Status: STARTED — NO try/catch
D/FutureTestApp: KOTLIN: Method called: nativeThrow
W/FutureTestApp: KOTLIN: Throwing RuntimeException (native throw)
E/MethodChannel#com.example.future_test: Failed to handle method call
E/MethodChannel#com.example.future_test: java.lang.RuntimeException: Native exception test
E/flutter: Unhandled Exception: PlatformException(error, Native exception test, null, java.lang.RuntimeException: ...)
E/flutter: #2      _MyHomePageState._testNativeThrow (package:future_test_app/main.dart:138:5)
...
I/flutter: FLUTTER TEST LOG #15 — TEST 1: neverResolves — Status: TIMEOUT
```

**Summary:** In **debug**, unhandled platform exceptions do **not** show a red screen; they are only printed to the console and the app keeps running. All of the above is for **debug** only. **Next step: release build** to verify whether behaviour (e.g. crash vs. silent log) differs.

**Raw log Run 2 (full):**

```
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #3
I/flutter ( 1474): Time: 15:47:46.746
I/flutter ( 1474): Test: TEST 1: neverResolves
I/flutter ( 1474): Status: TIMEOUT
I/flutter ( 1474): Details: Future never resolved
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #4
I/flutter ( 1474): Time: 15:47:47.444
I/flutter ( 1474): Test: TEST 1: neverResolves
I/flutter ( 1474): Status: STARTED
I/flutter ( 1474): Details: Calling method that never calls result()
I/flutter ( 1474): ════════════════════════════════════════════════════════════
D/FutureTestApp( 1474): KOTLIN: Method called: neverResolves
W/FutureTestApp( 1474): KOTLIN: NOT resolving Future
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #5
I/flutter ( 1474): Time: 15:47:50.344
I/flutter ( 1474): Test: TEST 2: throwsError
I/flutter ( 1474): Status: STARTED
I/flutter ( 1474): Details: Calling method that throws PlatformException (NO try/catch)
I/flutter ( 1474): ════════════════════════════════════════════════════════════
D/FutureTestApp( 1474): KOTLIN: Method called: throwsError
D/FutureTestApp( 1474): KOTLIN: result.error() called
E/flutter ( 1474): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(TEALIUM_NOT_INITIALIZED, Tealium instance is null, null, null)
E/flutter ( 1474): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653:7)
E/flutter ( 1474): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367:18)
E/flutter ( 1474): <asynchronous suspension>
E/flutter ( 1474): #2      _MyHomePageState._testThrowsError (package:future_test_app/main.dart:112:20)
E/flutter ( 1474): <asynchronous suspension>
E/flutter ( 1474):
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #6
I/flutter ( 1474): Time: 15:47:52.446
I/flutter ( 1474): Test: TEST 1: neverResolves
I/flutter ( 1474): Status: TIMEOUT
I/flutter ( 1474): Details: Future never resolved
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #7
I/flutter ( 1474): Time: 15:47:58.283
I/flutter ( 1474): Test: TEST 3: returnsNull
I/flutter ( 1474): Status: STARTED
I/flutter ( 1474): Details: Calling method that returns null
I/flutter ( 1474): ════════════════════════════════════════════════════════════
D/FutureTestApp( 1474): KOTLIN: Method called: returnsNull
D/FutureTestApp( 1474): KOTLIN: result.success(null) called
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #8
I/flutter ( 1474): Time: 15:47:58.285
I/flutter ( 1474): Test: TEST 3: returnsNull
I/flutter ( 1474): Status: SUCCESS
I/flutter ( 1474): Details: Received: null (type: Null)
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #9
I/flutter ( 1474): Time: 15:48:03.195
I/flutter ( 1474): Test: TEST 4: nativeThrow
I/flutter ( 1474): Status: STARTED
I/flutter ( 1474): Details: Native code will throw (RuntimeException/NSException), NO try/catch
I/flutter ( 1474): ════════════════════════════════════════════════════════════
D/FutureTestApp( 1474): KOTLIN: Method called: nativeThrow
W/FutureTestApp( 1474): KOTLIN: Throwing RuntimeException (native throw)
E/MethodChannel#com.example.future_test( 1474): Failed to handle method call
E/MethodChannel#com.example.future_test( 1474): java.lang.RuntimeException: Native exception test
E/MethodChannel#com.example.future_test( 1474): 	at com.example.future_test_app.MainActivity.configureFlutterEngine$lambda$0(MainActivity.kt:41)
[... Android stack trace ...]
E/flutter ( 1474): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(error, Native exception test, null, java.lang.RuntimeException: Native exception test
E/flutter ( 1474): 	at com.example.future_test_app.MainActivity.configureFlutterEngine$lambda$0(MainActivity.kt:41)
[...]
E/flutter ( 1474): )
E/flutter ( 1474): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653:7)
E/flutter ( 1474): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367:18)
E/flutter ( 1474): <asynchronous suspension>
E/flutter ( 1474): #2      _MyHomePageState._testNativeThrow (package:future_test_app/main.dart:138:5)
E/flutter ( 1474): <asynchronous suspension>
E/flutter ( 1474):
I/flutter ( 1474): ════════════════════════════════════════════════════════════
I/flutter ( 1474): FLUTTER TEST LOG #10
I/flutter ( 1474): Time: 15:48:12.792
I/flutter ( 1474): Test: TEST 1: neverResolves
I/flutter ( 1474): Status: STARTED
[...]
I/flutter ( 1474): FLUTTER TEST LOG #15
I/flutter ( 1474): Time: 15:48:17.795
I/flutter ( 1474): Test: TEST 1: neverResolves
I/flutter ( 1474): Status: TIMEOUT
I/flutter ( 1474): Details: Future never resolved
I/flutter ( 1474): ════════════════════════════════════════════════════════════
```

---

## Run 3: Release — full log (each button pressed twice, no try/catch)

**Build:** `flutter run --release` → sdk gphone64 arm64 (Android 16 emulator).

**Raw log:**

```
I/flutter ( 2408): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #0
I/flutter ( 2408): Time: 16:01:11.132
I/flutter ( 2408): Test: TEST 1: neverResolves
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that never calls result()
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #1
I/flutter ( 2408): Time: 16:01:16.138
I/flutter ( 2408): Test: TEST 1: neverResolves
I/flutter ( 2408): Status: TIMEOUT
I/flutter ( 2408): Details: Future never resolved
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #2
I/flutter ( 2408): Time: 16:01:19.644
I/flutter ( 2408): Test: TEST 2: throwsError
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that throws PlatformException (NO try/catch)
I/flutter ( 2408): ════════════════════════════════════════════════════════════
E/flutter ( 2408): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(TEALIUM_NOT_INITIALIZED, Tealium instance is null, null, null)
E/flutter ( 2408): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653)
E/flutter ( 2408): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408): #2      _MyHomePageState._testThrowsError (package:future_test_app/main.dart:112)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408):
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #3
I/flutter ( 2408): Time: 16:01:32.501
I/flutter ( 2408): Test: TEST 3: returnsNull
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that returns null
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #4
I/flutter ( 2408): Time: 16:01:32.503
I/flutter ( 2408): Test: TEST 3: returnsNull
I/flutter ( 2408): Status: SUCCESS
I/flutter ( 2408): Details: Received: null (type: Null)
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #5
I/flutter ( 2408): Time: 16:01:45.399
I/flutter ( 2408): Test: TEST 4: nativeThrow
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Native code will throw (RuntimeException/NSException), NO try/catch
I/flutter ( 2408): ════════════════════════════════════════════════════════════
E/flutter ( 2408): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(error, Native exception test, null, java.lang.RuntimeException: Native exception test
E/flutter ( 2408):      at B.a.e(SourceFile:79)
E/flutter ( 2408):      at C.a.l(SourceFile:28)
E/flutter ( 2408):      at G.c.run(SourceFile:128)
E/flutter ( 2408):      at android.os.Handler.handleCallback(Handler.java:995)
E/flutter ( 2408):      at android.os.Handler.dispatchMessage(Handler.java:103)
E/flutter ( 2408):      at android.os.Looper.loopOnce(Looper.java:248)
E/flutter ( 2408):      at android.os.Looper.loop(Looper.java:338)
E/flutter ( 2408):      at android.app.ActivityThread.main(ActivityThread.java:9067)
E/flutter ( 2408):      at java.lang.reflect.Method.invoke(Native Method)
E/flutter ( 2408):      at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:593)
E/flutter ( 2408):      at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:932)
E/flutter ( 2408): )
E/flutter ( 2408): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653)
E/flutter ( 2408): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408): #2      _MyHomePageState._testNativeThrow (package:future_test_app/main.dart:138)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408):
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #6
I/flutter ( 2408): Time: 16:01:57.117
I/flutter ( 2408): Test: TEST 1: neverResolves
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that never calls result()
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #7
I/flutter ( 2408): Time: 16:01:59.079
I/flutter ( 2408): Test: TEST 2: throwsError
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that throws PlatformException (NO try/catch)
I/flutter ( 2408): ════════════════════════════════════════════════════════════
E/flutter ( 2408): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(TEALIUM_NOT_INITIALIZED, Tealium instance is null, null, null)
E/flutter ( 2408): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653)
E/flutter ( 2408): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408): #2      _MyHomePageState._testThrowsError (package:future_test_app/main.dart:112)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408):
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #8
I/flutter ( 2408): Time: 16:02:00.065
I/flutter ( 2408): Test: TEST 3: returnsNull
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Calling method that returns null
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #9
I/flutter ( 2408): Time: 16:02:00.065
I/flutter ( 2408): Test: TEST 3: returnsNull
I/flutter ( 2408): Status: SUCCESS
I/flutter ( 2408): Details: Received: null (type: Null)
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #10
I/flutter ( 2408): Time: 16:02:00.760
I/flutter ( 2408): Test: TEST 4: nativeThrow
I/flutter ( 2408): Status: STARTED
I/flutter ( 2408): Details: Native code will throw (RuntimeException/NSException), NO try/catch
I/flutter ( 2408): ════════════════════════════════════════════════════════════
E/flutter ( 2408): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(error, Native exception test, null, java.lang.RuntimeException: Native exception test
E/flutter ( 2408):      at B.a.e(SourceFile:79)
E/flutter ( 2408):      at C.a.l(SourceFile:28)
E/flutter ( 2408):      at G.c.run(SourceFile:128)
E/flutter ( 2408):      at android.os.Handler.handleCallback(Handler.java:995)
E/flutter ( 2408):      at android.os.Handler.dispatchMessage(Handler.java:103)
E/flutter ( 2408):      at android.os.Looper.loopOnce(Looper.java:248)
E/flutter ( 2408):      at android.os.Looper.loop(Looper.java:338)
E/flutter ( 2408):      at android.app.ActivityThread.main(ActivityThread.java:9067)
E/flutter ( 2408):      at java.lang.reflect.Method.invoke(Native Method)
E/flutter ( 2408):      at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:593)
E/flutter ( 2408):      at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:932)
E/flutter ( 2408): )
E/flutter ( 2408): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653)
E/flutter ( 2408): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408): #2      _MyHomePageState._testNativeThrow (package:future_test_app/main.dart:138)
E/flutter ( 2408): <asynchronous suspension>
E/flutter ( 2408):
I/flutter ( 2408): ════════════════════════════════════════════════════════════
I/flutter ( 2408): FLUTTER TEST LOG #11
I/flutter ( 2408): Time: 16:02:02.118
I/flutter ( 2408): Test: TEST 1: neverResolves
I/flutter ( 2408): Status: TIMEOUT
I/flutter ( 2408): Details: Future never resolved
I/flutter ( 2408): ════════════════════════════════════════════════════════════
```

**Observed:** No red error screen, no app crash. Same as debug.

---

## Conclusions (from Run 1)

1. **Unresolved Futures:** When the native plugin never calls `result.success()` or `result.error()`, the Flutter `Future` never completes (TEST 1). This matches the reported Tealium `getFromDataLayer` (and similar) behaviour and should be fixed by ensuring every code path calls `result` once.
2. **Error path:** Calling `result.error(...)` on the native side correctly resolves the Future with an error that can be caught in Dart (TEST 2). Using this for “missing param” and “Tealium not initialized” is consistent and preferable where it is not a breaking change.
3. **Null path:** Calling `result.success(null)` is valid where the Dart API is nullable (TEST 3). It is not a solution for methods that must return a non-null type.
4. **Swift:** The same expectations (always resolve or error, consistent handling) should be verified on iOS; a separate ticket or duplicate for the other platform is suggested.

---

## Raw Log (reference)

```
Restarted application in 564ms.
I/flutter: ════════════════════════════════════════════════════════════
I/flutter: FLUTTER TEST LOG #0
I/flutter: Time: 15:40:44.111
I/flutter: Test: TEST 1: neverResolves
I/flutter: Status: STARTED
I/flutter: Details: Calling method that never calls result()
I/flutter: ════════════════════════════════════════════════════════════
D/FutureTestApp: KOTLIN: Method called: neverResolves
D/FutureTestApp: KOTLIN: Arguments: null
W/FutureTestApp: KOTLIN: ⚠️ BUG SIMULATION - NOT resolving the Future
W/FutureTestApp: KOTLIN: This mimics the Tealium bug where result() is never called
I/flutter: FLUTTER TEST LOG #1 — TEST 1: neverResolves — Status: TIMEOUT — Details: Future never resolved
...
I/flutter: TEST 2: throwsError — Status: CAUGHT — Details: PlatformException: TEALIUM_NOT_INITIALIZED - Tealium instance is null
...
I/flutter: TEST 3: returnsNull — Status: SUCCESS — Details: Received: null (type: Null)
...
I/flutter: TEST 4: nativeThrow — Status: CAUGHT — Details: Exception: MissingPluginException(No implementation found for method nativeThrow on channel com.example.future_test)
```
