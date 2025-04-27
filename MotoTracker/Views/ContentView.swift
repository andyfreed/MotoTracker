import SwiftUI

struct ContentView: View {
    // Re-enable SupabaseManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @State private var isRecording = false
    @State private var selectedTab = 0
    
    var body: some View {
        // Re-enable authentication flow
        Group {
            if supabaseManager.currentUser == nil {
                SignInView()
            } else {
                mainTabView
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            VStack {
                MapViewWithControls(
                    locationManager: locationManager,
                    isRecording: $isRecording
                )
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(0)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(1)
            
            // Stats Tab
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(2)
            
            // Profile & Settings Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            locationManager.requestLocationPermissions()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationManager())
            .environmentObject(RideManager())
            .environmentObject(UserSettings())
            .environmentObject(SupabaseManager.shared)
    }
} 