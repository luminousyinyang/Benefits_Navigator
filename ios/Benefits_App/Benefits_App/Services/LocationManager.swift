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
    
    private var isGeocoding = false
    
    override init() {
        super.init()
        setupLocationManager()
        // No need for lifecycle observers anymore as CLVisit works automatically in background
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        // Significant Change & Visits are very power efficient.
        // We don't need high accuracy "always" unless the user is actively navigating (which we aren't doing here).
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        
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
        // CLVisit is the most efficient way to detect "Places" user stops at.
        locationManager.startMonitoringVisits()
        
        // Also keep significant changes as a backup/helper for general location updates if needed for UI
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        // We no longer manually check dwell here. We wait for didVisit.
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // arrivalDate == distantPast means we don't know when they arrived (pre-existing)
        // departureDate == distantFuture means they exist currently at this location (still there)
        
        if visit.departureDate == Date.distantFuture {
            print("Arrival detected at \(visit.coordinate)")
            let location = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
            
            // Check if we already notified for this visit recently?
            // For now, let's just trigger the flow.
            
            reverseGeocode(location: location) { [weak self] name in
                guard let self = self, let name = name else { return }
                self.triggerShoppingNotification(storeName: name)
            }
        } else {
            print("Departure detected from \(visit.coordinate)")
            // Could use this to clear state if needed
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
    
    // MARK: - Geocoding
    
    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        guard !isGeocoding else { return }
        isGeocoding = true
        
        // Use MapKit to find Points of Interest (POI) to filter out residential places
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 100)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .bakery, .bank, .brewery, .cafe, .carRental, .foodMarket,
            .gasStation, .hotel, .laundry, .movieTheater, .museum, .nightlife,
            .park, .pharmacy, .restaurant, .store, .winery, .fitnessCenter
        ])
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            defer { self?.isGeocoding = false }
            
            if let error = error {
                print("POI Search: No matching business found (likely residential). Notification suppressed. Error: \(error.localizedDescription)")
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
    
    func simulateVisit(at location: CLLocation) {
        // Create a mock visit behavior by manually calling the logic
        // We can't easily create a CLVisit instance, so we'll just replicate the flow
        print("Simulating Visit at \(location.coordinate)")
        reverseGeocode(location: location) { [weak self] name in
            guard let self = self, let name = name else { return }
            self.triggerShoppingNotification(storeName: name)
        }
    }
}
