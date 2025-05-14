import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        // Handle the notification content
        self.label?.text = notification.request.content.body
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        // Handle user's action on the notification
        if response.actionIdentifier == "MARK_AS_TRACKED" {
            // Logic to mark period as tracked
            completion(.dismissAndForwardAction)
        } else if response.actionIdentifier == "REMIND_LATER" {
            // Logic to reschedule notification
            completion(.dismissAndForwardAction)
        } else {
            completion(.dismissAndForwardAction)
        }
    }
} 