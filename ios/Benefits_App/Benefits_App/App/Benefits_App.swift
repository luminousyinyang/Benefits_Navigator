import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  let locationManager = LocationManager.shared

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Setup Notifications
    UNUserNotificationCenter.current().delegate = self
    locationManager.startTracking()
    
    return true
  }
  
  // Handle Notification when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.banner, .sound])
  }
  
  // Handle Notification Tap
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
      let userInfo = response.notification.request.content.userInfo
      if let storeName = userInfo["store"] as? String {
          // Post notification for SwiftUI to handle
          NotificationCenter.default.post(name: NSNotification.Name("ShoppingDetection"), object: nil, userInfo: ["store": storeName])
      }
      completionHandler()
  }
  
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      Task {
          let result = await ActionManager.shared.performBackgroundFetch()
          completionHandler(result)
      }
  }
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
      return .portrait
  }
}

@main
struct CreditCardOptimizerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
