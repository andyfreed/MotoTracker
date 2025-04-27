import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var currentAddress: String = "Unknown Location"
    @Published var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3323, longitude: -122.0312),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var isTrackingLocation = false
    
    // For tracking a collection of locations during a ride
    @Published var currentLocationPoints: [LocationPoint] = []
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // Update location every 10 meters
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.showsBackgroundLocationIndicator = true
        
        self.checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationStatus = locationManager.authorizationStatus
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            locationStatus = .notDetermined
        case .denied, .restricted:
            locationStatus = locationManager.authorizationStatus
        @unknown default:
            break
        }
    }
    
    func startTracking() {
        isTrackingLocation = true
        currentLocationPoints.removeAll()
        
        // Set up location manager for tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTrackingLocation = false
        
        // Reset to more battery-friendly settings when not actively tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                self.currentAddress = "Unknown Location"
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")
                
                self.currentAddress = address.isEmpty ? "Unknown Location" : address
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only record location if it's accurate enough
        guard location.horizontalAccuracy >= 0 && 
              location.horizontalAccuracy < 50 else { return }
        
        lastLocation = location
        
        // Update the map region to follow user
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: self.currentRegion.span
        )
        self.currentRegion = region
        
        // Handle reverse geocoding occasionally (not on every update to save API calls)
        if currentAddress == "Unknown Location" {
            reverseGeocode(location: location)
        }
        
        // If we're tracking a ride, add this point to our collection
        if isTrackingLocation {
            let locationPoint = LocationPoint(location: location)
            currentLocationPoints.append(locationPoint)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
} 