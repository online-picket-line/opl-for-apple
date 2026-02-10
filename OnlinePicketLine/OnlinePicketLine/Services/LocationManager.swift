import Foundation
import CoreLocation
import UserNotifications

/// Manages GPS location monitoring and geofence proximity alerts.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var nearbyGeofences: [GeofenceItem] = []

    private let manager = CLLocationManager()
    private var isMonitoring = false

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100 // Update every 100m
        manager.allowsBackgroundLocationUpdates = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        guard CLLocationManager.locationServicesEnabled() else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            isMonitoring = true
        case .notDetermined:
            requestPermission()
        default:
            break
        }
    }

    func stopMonitoring() {
        manager.stopUpdatingLocation()
        isMonitoring = false
    }

    func getCurrentLocation() async -> CLLocation? {
        manager.requestLocation()
        // Wait briefly for location update
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return lastLocation
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location

        Task { @MainActor in
            // Check if we need to refresh data based on movement
            let appState = AppState.shared
            if appState.shouldRefreshForLocation(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude
            ) {
                await appState.refreshData()
            }

            // Check geofence proximity
            checkGeofenceProximity(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location errors are non-fatal; we keep using cached data
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startMonitoring()
        }
    }

    // MARK: - Geofence Checking

    private func checkGeofenceProximity(_ location: CLLocation) {
        guard let geofences = AppState.shared.mobileData?.geofences.all else { return }

        let hits = geofences.filter { geofence in
            let dist = LocationManager.distance(
                from: (location.coordinate.latitude, location.coordinate.longitude),
                to: (geofence.coordinates.lat, geofence.coordinates.lng)
            )
            return dist <= Double(geofence.notificationRadius)
        }.sorted { $0.distance < $1.distance }

        // Post notification for new geofence entries
        let previousIds = Set(nearbyGeofences.map { $0.id })
        let newHits = hits.filter { !previousIds.contains($0.id) }

        for geofence in newHits {
            sendProximityNotification(geofence)
        }

        nearbyGeofences = hits
    }

    private func sendProximityNotification(_ geofence: GeofenceItem) {
        let content = UNMutableNotificationContent()
        content.title = "Active \(geofence.actionType.capitalized) Nearby"
        content.body = "Workers at \(geofence.employerName) have an active \(geofence.actionType). You are near \(geofence.location ?? "a picket location")."
        content.sound = .default
        content.categoryIdentifier = "STRIKE_PROXIMITY"

        let request = UNNotificationRequest(
            identifier: "geofence-\(geofence.id)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Distance Calculation

    static func distance(from: (Double, Double), to: (Double, Double)) -> Double {
        let loc1 = CLLocation(latitude: from.0, longitude: from.1)
        let loc2 = CLLocation(latitude: to.0, longitude: to.1)
        return loc1.distance(from: loc2)
    }
}
