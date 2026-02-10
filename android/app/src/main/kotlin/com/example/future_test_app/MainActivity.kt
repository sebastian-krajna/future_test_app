package com.example.future_test_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.future_test"
    private val TAG = "FutureTestApp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "KOTLIN: Method called: ${call.method}")

            when (call.method) {
                "neverResolves" -> {
                    // Don't call result() - Future will NEVER resolve
                    Log.w(TAG, "KOTLIN: NOT resolving Future")
                }

                "throwsError" -> {
                    result.error(
                        "TEALIUM_NOT_INITIALIZED",
                        "Tealium instance is null",
                        null
                    )
                    Log.d(TAG, "KOTLIN: result.error() called")
                }

                "returnsNull" -> {
                    result.success(null)
                    Log.d(TAG, "KOTLIN: result.success(null) called")
                }

                "nativeThrow" -> {
                    // Real throw - no result.error(), native code throws exception
                    Log.w(TAG, "KOTLIN: Throwing RuntimeException (native throw)")
                    throw RuntimeException("Native exception test")
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
