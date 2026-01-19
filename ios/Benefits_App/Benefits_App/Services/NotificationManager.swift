import UserNotifications
import UIKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendBonusCompletionNotification(cardName: String, earned: Double, type: String) {
        let content = UNMutableNotificationContent()
        content.title = "Congrats! Sign Up Bonus Complete"
        
        let earnedStr: String
        if type.lowercased().contains("point") || type.lowercased().contains("mile") {
             earnedStr = "\(Int(earned)) Points"
        } else {
             // Usually bonuses are round numbers, but could be $.2f
             if earned.truncatingRemainder(dividingBy: 1) != 0 {
                  earnedStr = String(format: "$%.2f", earned)
             } else {
                  earnedStr = String(format: "$%.0f", earned)
             }
        }
        
        content.body = "On \(cardName), you earned \(earnedStr)!"
        content.sound = .default
        
        // Immediate trigger
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    func sendPriceDropNotification(item: String, saved: Double, foundPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Price Drop Detected! 📉"
        content.body = "Found a lower price for \(item). New Price: $\(String(format: "%.2f", foundPrice)). You save $\(String(format: "%.2f", saved))!"
        content.sound = .default
        
        // Immediate trigger
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}
