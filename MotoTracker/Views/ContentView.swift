import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isRecording = false
    @State private var selectedTab = 0
    
    var body: some View {
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
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            locationManager.requestLocationPermissions()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 