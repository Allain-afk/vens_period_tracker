import Flutter
import UIKit
import UserNotifications
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )
    
    application.registerForRemoteNotifications()
    
    // Register notification categories
    NotificationCategories.shared.registerCategories()
    
    // Register background tasks
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.vens.periodtracker.refresh",
      using: nil
    ) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
    
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
              let timestamp = args["timestamp"] as? Int,
              let isExact = args["isExact"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGUMENTS", 
                             message: "Invalid arguments for scheduling notification", 
                             details: nil))
          return
        }
        
        self.scheduleNotification(id: id, title: title, body: body, timestamp: timestamp, isExact: isExact)
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
      } else if call.method == "scheduleBackgroundTask" {
        self.scheduleBackgroundRefresh()
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Schedule a notification
  private func scheduleNotification(id: Int, title: String, body: String, timestamp: Int, isExact: Bool) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    // Set time-sensitive flag for exact alarms
    if isExact {
      content.interruptionLevel = .timeSensitive
    }
    
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    
    // Use calendar trigger for exact timing
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
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
  
  // Schedule background refresh task
  private func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.vens.periodtracker.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
    
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule background task: \(error)")
    }
  }
  
  // Handle background refresh task
  private func handleAppRefresh(task: BGAppRefreshTask) {
    // Schedule the next background refresh
    scheduleBackgroundRefresh()
    
    // Create a task to handle any pending notifications
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    
    let operation = BlockOperation {
      // Process any pending notifications here
    }
    
    // Set expiration handler to avoid task termination
    task.expirationHandler = {
      queue.cancelAllOperations()
    }
    
    // Mark task complete when operation is done
    operation.completionBlock = {
      task.setTaskCompleted(success: !operation.isCancelled)
    }
    
    queue.addOperation(operation)
  }
  
  // Respond to receipt of a remote notification
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Handle push notification
    completionHandler(.newData)
  }
}
