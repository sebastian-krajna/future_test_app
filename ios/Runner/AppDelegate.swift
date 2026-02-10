import Flutter
import UIKit
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let logger = OSLog(subsystem: "com.example.future_test_app", category: "FutureTest")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
        name: "com.example.future_test",
        binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        os_log("SWIFT: Method called: %{public}@", log: self?.logger ?? OSLog.default, type: .default, call.method)

        switch call.method {
        case "neverResolves":
            // Don't call result() - Future will NEVER resolve
            os_log("SWIFT: NOT resolving Future", log: self?.logger ?? OSLog.default, type: .default)

        case "throwsError":
            result(FlutterError(
                code: "TEALIUM_NOT_INITIALIZED",
                message: "Tealium instance is null",
                details: nil
            ))
            os_log("SWIFT: result(FlutterError) called", log: self?.logger ?? OSLog.default, type: .default)

        case "returnsNull":
            result(nil)
            os_log("SWIFT: result(nil) called", log: self?.logger ?? OSLog.default, type: .default)

        case "nativeThrow":
            // Real throw - no result(), native code throws NSException
            os_log("SWIFT: Throwing NSException (native throw)", log: self?.logger ?? OSLog.default, type: .default)
            NSException(name: NSExceptionName("NativeException"), reason: "Native exception test", userInfo: nil).raise()

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
