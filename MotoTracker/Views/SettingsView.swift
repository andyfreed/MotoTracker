import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @StateObject private var userSettings = UserSettings()
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Measurement System")) {
                    Picker("Units", selection: $userSettings.unitSystem) {
                        Text("Metric (km, km/h)").tag(UserSettings.UnitSystem.metric)
                        Text("Imperial (mi, mph)").tag(UserSettings.UnitSystem.imperial)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Units:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("Distance:")
                            Spacer()
                            Text(userSettings.unitSystem.distanceUnit)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Speed:")
                            Spacer()
                            Text(userSettings.unitSystem.speedUnit)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Altitude:")
                            Spacer()
                            Text(userSettings.unitSystem.altitudeUnit)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Location")) {
                    HStack {
                        Image(systemName: locationManager.isLocationAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(locationManager.isLocationAuthorized ? .green : .red)
                        
                        Text("Location Access")
                        
                        Spacer()
                        
                        if !locationManager.isLocationAuthorized {
                            Button("Request") {
                                locationManager.requestLocationPermissions()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    NavigationLink(destination: LocationAccuracyView()) {
                        Text("Location Accuracy")
                    }
                }
                
                Section(header: Text("Map")) {
                    NavigationLink(destination: MapSettingsView()) {
                        Text("Map Display Settings")
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Ride Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    NavigationLink(destination: Text("Notifications settings would go here")) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: Text("Privacy settings would go here")) {
                        Label("Privacy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: Text("Support information would go here")) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // Open app store review
                        if let url = URL(string: "https://apps.apple.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Rate the App", systemImage: "star")
                    }
                    
                    Button(action: {
                        // Share the app
                        // This would normally use UIActivityViewController
                    }) {
                        Label("Share the App", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingClearDataAlert) {
                Alert(
                    title: Text("Clear All Data?"),
                    message: Text("This action cannot be undone. All your ride history will be permanently deleted."),
                    primaryButton: .destructive(Text("Delete All Data")) {
                        // TODO: Implement clear data functionality
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .environmentObject(userSettings)
    }
}

struct LocationAccuracyView: View {
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        Form {
            Section(header: Text("Current Accuracy")) {
                if let location = locationManager.lastLocation {
                    HStack {
                        Text("Horizontal")
                        Spacer()
                        Text("\(Int(location.horizontalAccuracy)) meters")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Vertical")
                        Spacer()
                        Text("\(Int(location.verticalAccuracy)) meters")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No location data available")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Information"), footer: Text("Higher accuracy may use more battery power")) {
                Text("Location accuracy indicates how precise the GPS position data is. Lower values indicate better accuracy.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Location Accuracy")
    }
}

struct MapSettingsView: View {
    @State private var showTraffic = false
    @State private var mapType = 0
    
    var body: some View {
        Form {
            Section(header: Text("Map Type")) {
                Picker("Map Style", selection: $mapType) {
                    Text("Standard").tag(0)
                    Text("Satellite").tag(1)
                    Text("Hybrid").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Toggle("Show Traffic", isOn: $showTraffic)
            }
        }
        .navigationTitle("Map Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(LocationManager())
        }
    }
} 