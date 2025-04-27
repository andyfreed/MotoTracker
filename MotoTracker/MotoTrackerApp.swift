import SwiftUI

@main
struct MotoTrackerApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var rideManager = RideManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(rideManager)
        }
    }
} 