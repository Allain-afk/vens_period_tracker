import Foundation
import UserNotifications

class NotificationCategories {
    static let shared = NotificationCategories()
    
    // Register all notification categories with the system
    func registerCategories() {
        let categories: Set<UNNotificationCategory> = [
            createPeriodReminderCategory(),
            createMedicationReminderCategory(),
            createFertilityAlertCategory()
        ]
        
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
    
    // Period Reminder Category
    private func createPeriodReminderCategory() -> UNNotificationCategory {
        let markAction = UNNotificationAction(
            identifier: "MARK_AS_TRACKED",
            title: "Mark as Tracked",
            options: .foreground
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 hour",
            options: .destructive
        )
        
        return UNNotificationCategory(
            identifier: "PERIOD_REMINDER",
            actions: [markAction, remindLaterAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    // Medication Reminder Category
    private func createMedicationReminderCategory() -> UNNotificationCategory {
        let takenAction = UNNotificationAction(
            identifier: "MEDICATION_TAKEN",
            title: "Taken",
            options: .foreground
        )
        
        let skipAction = UNNotificationAction(
            identifier: "MEDICATION_SKIP",
            title: "Skip",
            options: .destructive
        )
        
        let remindAction = UNNotificationAction(
            identifier: "MEDICATION_REMIND",
            title: "Remind in 30 minutes",
            options: .destructive
        )
        
        return UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, skipAction, remindAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
    
    // Fertility Alert Category
    private func createFertilityAlertCategory() -> UNNotificationCategory {
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_FERTILITY_DETAILS",
            title: "View Details",
            options: .foreground
        )
        
        return UNNotificationCategory(
            identifier: "FERTILITY_ALERT",
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
    }
} 