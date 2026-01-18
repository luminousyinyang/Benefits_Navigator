import CoreLocation
import UserNotifications
import SwiftUI
import Combine
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var locationName: String?
    
    // Config
    private let dwellTimeThreshold: TimeInterval = 5 * 60 // 5 minutes
    private let distanceFilter: CLLocationDistance = 100 // 100 meters
    private let dwellDistanceThreshold: CLLocationDistance = 100 // 100 meters
    
    // State Persistence Keys
    private let kLastLocationLat = "lastLocationLat"
    private let kLastLocationLon = "lastLocationLon"
    private let kLastLocationTime = "lastLocationTime"
    private let kIsShoppingNotificationPending = "isShoppingNotificationPending"
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter // Only update if moved 100m
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true // Let OS save battery when stationary
        locationManager.showsBackgroundLocationIndicator = false // Hide the blue pill
        
        requestPermissions()
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startTracking() {
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        
        checkDwell(currentLocation: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
    
    // MARK: - Dwell Detection Logic
    
    private func checkDwell(currentLocation: CLLocation) {
        let defaults = UserDefaults.standard
        let lastLat = defaults.double(forKey: kLastLocationLat)
        let lastLon = defaults.double(forKey: kLastLocationLon)
        let lastTime = defaults.double(forKey: kLastLocationTime)
        
        // Save current as last for next check (if significant move)
        // But for dwell, we want to see if we STAYED.
        
        let lastLocation = CLLocation(latitude: lastLat, longitude: lastLon)
        let timeDiff = Date().timeIntervalSince1970 - lastTime
        let distance = currentLocation.distance(from: lastLocation)
        
        // Logic:
        // 1. If we are CLOSE to the last location (< 100m)
        // 2. AND it has been > 5 minutes since that last record
        // 3. AND we haven't already notified for this "stay" (optional, simplified here)
        
        if lastTime > 0 && distance < dwellDistanceThreshold && timeDiff > dwellTimeThreshold {
            // Potential Dwell!
            print("Dwell Detected! Time: \(timeDiff), Dist: \(distance)")
            
            // CRITICAL: Update timestamp IMMEDIATELY to prevent rapid-fire triggers while geocoding runs
            defaults.set(Date().timeIntervalSince1970, forKey: kLastLocationTime)
            
            // Reverse Geocode
            reverseGeocode(location: currentLocation) { [weak self] name in
                guard let self = self, let name = name else { return }
                
                // Trigger Notification
                self.triggerShoppingNotification(storeName: name)
            }
            
        } else {
            // User is moving or this is the first point
            if distance > dwellDistanceThreshold || lastTime == 0 {
                // Update "anchor" point
                defaults.set(currentLocation.coordinate.latitude, forKey: kLastLocationLat)
                defaults.set(currentLocation.coordinate.longitude, forKey: kLastLocationLon)
                defaults.set(Date().timeIntervalSince1970, forKey: kLastLocationTime)
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        // Use MapKit to find Points of Interest (POI) to filter out residential places
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 100)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .bakery, .bank, .brewery, .cafe, .carRental, .foodMarket, 
            .gasStation, .hotel, .laundry, .movieTheater, .museum, .nightlife, 
            .park, .pharmacy, .restaurant, .store, .winery, .fitnessCenter
        ])
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                // Code 4 is "Placemark Not Found", which is expected for residential areas/apartments
                // when filtering for businesses.
                print("POI Search: No matching business found (likely residential). Notification suppressed.")
                completion(nil)
                return
            }
            
            if let item = response?.mapItems.first {
                // Return the name of the business
                completion(item.name)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Notifications
    
    func triggerShoppingNotification(storeName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Shopping Detection"
        content.body = "Are you shopping at \(storeName) right now?"
        content.sound = .default
        content.userInfo = ["store": storeName]
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Immediate
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Testing
    
    func simulateDwell(at storeName: String) {
        // Force trigger
        triggerShoppingNotification(storeName: storeName)
    }
}
