import SwiftUI
import Foundation
import Combine
import MapKit
import CoreLocation

// Include UserSettings class directly
class UserSettings: ObservableObject {
    enum UnitSystem: String, CaseIterable, Identifiable {
        case metric
        case imperial
        
        var id: String { self.rawValue }
        
        var speedUnit: String {
            switch self {
            case .metric: return "km/h"
            case .imperial: return "mph"
            }
        }
        
        var distanceUnit: String {
            switch self {
            case .metric: return "km"
            case .imperial: return "mi"
            }
        }
        
        var altitudeUnit: String {
            switch self {
            case .metric: return "m"
            case .imperial: return "ft"
            }
        }
    }
    
    @Published var unitSystem: UnitSystem
    
    init() {
        // Get from UserDefaults or default to metric
        let storedValue = UserDefaults.standard.string(forKey: "unitSystem") ?? UnitSystem.metric.rawValue
        self.unitSystem = UnitSystem(rawValue: storedValue) ?? .metric
    }
    
    func setUnitSystem(_ system: UnitSystem) {
        self.unitSystem = system
        UserDefaults.standard.set(system.rawValue, forKey: "unitSystem")
    }
    
    // Conversion functions
    func convertDistance(_ distanceKm: Double) -> Double {
        switch unitSystem {
        case .metric:
            return distanceKm
        case .imperial:
            return distanceKm * 0.621371 // km to miles
        }
    }
    
    func convertSpeed(_ speedKmh: Double) -> Double {
        switch unitSystem {
        case .metric:
            return speedKmh
        case .imperial:
            return speedKmh * 0.621371 // km/h to mph
        }
    }
    
    func convertAltitude(_ altitudeMeters: Double) -> Double {
        switch unitSystem {
        case .metric:
            return altitudeMeters
        case .imperial:
            return altitudeMeters * 3.28084 // meters to feet
        }
    }
    
    func formatDistance(_ distanceKm: Double) -> String {
        let converted = convertDistance(distanceKm)
        return String(format: "%.2f %@", converted, unitSystem.distanceUnit)
    }
    
    func formatSpeed(_ speedKmh: Double) -> String {
        let converted = convertSpeed(speedKmh)
        return String(format: "%.1f %@", converted, unitSystem.speedUnit)
    }
    
    func formatAltitude(_ altitudeMeters: Double) -> String {
        let converted = convertAltitude(altitudeMeters)
        return String(format: "%.0f %@", converted, unitSystem.altitudeUnit)
    }
}

// Forward declaration of the NavigationManager class to avoid circular dependencies
@objc class NavigationManager: NSObject, ObservableObject {
    var locationManager: LocationManager?
}

@main
struct MotoTrackerApp: App {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @StateObject private var rideManager = RideManager()
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var userSettings = UserSettings()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(rideManager)
                .environmentObject(navigationManager)
                .environmentObject(userSettings)
                .onAppear {
                    self.navigationManager.locationManager = self.locationManager
                }
        }
    }
} 