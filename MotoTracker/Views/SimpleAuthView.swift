import SwiftUI

struct SimpleAuthView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        // Since we're not using authentication right now, just show the main content
        ContentView()
            .environmentObject(locationManager)
            .environmentObject(rideManager)
            .environmentObject(userSettings)
    }
}

struct SimpleAuthView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleAuthView()
            .environmentObject(LocationManager())
            .environmentObject(RideManager())
            .environmentObject(UserSettings())
    }
} 