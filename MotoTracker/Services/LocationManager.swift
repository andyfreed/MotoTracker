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
        center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var isTrackingLocation = false
    @Published var isLocationAuthorized = false
    @Published var locationErrorMessage: String?
    
    // For tracking a collection of locations during a ride
    @Published var currentLocationPoints: [LocationPoint] = []
    
    override init() {
        super.init()
        
        // Configure location manager with the best accuracy
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 5 // Update every 5 meters
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.showsBackgroundLocationIndicator = true
        self.locationManager.activityType = .automotiveNavigation
        
        // Start immediately
        self.checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus
        locationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isLocationAuthorized = true
            locationErrorMessage = nil
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            isLocationAuthorized = false
            locationErrorMessage = "Location permissions not determined"
        case .denied, .restricted:
            isLocationAuthorized = false
            locationErrorMessage = "Location access denied"
        @unknown default:
            isLocationAuthorized = false
            locationErrorMessage = "Unknown location authorization status"
        }
    }
    
    func requestLocationPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        isTrackingLocation = true
        currentLocationPoints.removeAll()
        
        // Set up location manager for tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update more frequently during active tracking
        locationManager.startUpdatingLocation()
        
        // Start updating heading for compass
        locationManager.startUpdatingHeading()
    }
    
    func stopTracking() {
        isTrackingLocation = false
        
        // Reset to more battery-friendly settings when not actively tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 10
        locationManager.stopUpdatingHeading()
    }
    
    func centerOnUserLocation() {
        guard let location = lastLocation else { return }
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        self.currentRegion = region
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if error != nil {
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
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only record location if it's accurate enough
        guard location.horizontalAccuracy >= 0 && 
              location.horizontalAccuracy < 100 else { return }
        
        lastLocation = location
        
        // Update the map region to follow user when tracking
        if isTrackingLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self.currentRegion = region
        }
        
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
        // Handle common location errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // User denied location permissions
                isLocationAuthorized = false
                locationErrorMessage = "Location access denied by user"
                
            case .locationUnknown:
                // GPS signal might be temporarily unavailable
                locationErrorMessage = "Current location unavailable, please try outdoors or in an area with better GPS signal"
                
            default:
                locationErrorMessage = "Location error: \(clError.localizedDescription)"
            }
        }
    }
} 