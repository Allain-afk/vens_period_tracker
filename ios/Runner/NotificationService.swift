import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here
            
            // For period reminders - add category for actionable notifications
            if let category = request.content.userInfo["category"] as? String, 
               category == "period_reminder" {
                bestAttemptContent.categoryIdentifier = "PERIOD_REMINDER"
                bestAttemptContent.interruptionLevel = .timeSensitive
            }
            
            // Handle background data refresh notifications
            if let needsRefresh = request.content.userInfo["refresh_data"] as? Bool, 
               needsRefresh == true {
                // Set badge to indicate refresh is needed
                bestAttemptContent.badge = 1
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
} 