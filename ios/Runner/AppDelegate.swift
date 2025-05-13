import Flutter
import UIKit
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )
    
    application.registerForRemoteNotifications()
    
    // Set up Flutter notification channel method
    let controller = self.window.rootViewController as! FlutterViewController
    let notificationChannel = FlutterMethodChannel(
      name: "com.vens/notifications",
      binaryMessenger: controller.binaryMessenger
    )
    
    notificationChannel.setMethodCallHandler { (call, result) in
      if call.method == "scheduleNotification" {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let title = args["title"] as? String,
              let body = args["body"] as? String,
              let timestamp = args["timestamp"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", 
                             message: "Invalid arguments for scheduling notification", 
                             details: nil))
          return
        }
        
        self.scheduleNotification(id: id, title: title, body: body, timestamp: timestamp)
        result(true)
      } else if call.method == "cancelNotification" {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", 
                             message: "Invalid arguments for canceling notification", 
                             details: nil))
          return
        }
        
        self.cancelNotification(id: id)
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Schedule a notification
  private func scheduleNotification(id: Int, title: String, body: String, timestamp: Int) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(timestamp), 
      repeats: false
    )
    
    let request = UNNotificationRequest(
      identifier: "notification_\(id)",
      content: content,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error)")
      }
    }
  }
  
  // Cancel a notification
  private func cancelNotification(id: Int) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["notification_\(id)"]
    )
  }
}
