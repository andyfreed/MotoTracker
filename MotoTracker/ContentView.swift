import SwiftUI
import UIKit
import MapKit

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @State private var selectedTab = 0
    @State private var showLocationPermissionAlert = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Active Ride Tab
            NavigationView {
                if rideManager.isRecording {
                    ActiveRideView()
                } else {
                    VStack {
                        ExtendedMapView(region: $locationManager.currentRegion)
                            .ignoresSafeArea(edges: .top)
                            .frame(height: 300)
                            .overlay(alignment: .top) {
                                if !locationManager.isLocationAuthorized {
                                    Button(action: {
                                        showLocationPermissionAlert = true
                                    }) {
                                        Text("GPS Access Required")
                                            .font(.caption)
                                            .padding(8)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 50)
                                }
                            }
                        
                        if let errorMessage = locationManager.locationErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        VStack(spacing: 20) {
                            Text("Ready to ride?")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Track your motorcycle ride with GPS")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if locationManager.isLocationAuthorized {
                                    locationManager.startTracking()
                                    rideManager.startRide()
                                } else {
                                    showLocationPermissionAlert = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "record.circle")
                                    Text("Start Tracking")
                                }
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .navigationTitle("MotoTracker")
                    .alert("Location Permission Required", isPresented: $showLocationPermissionAlert) {
                        Button("Settings", role: .none) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button("Request Permission", role: .none) {
                            locationManager.requestLocationPermissions()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("MotoTracker needs GPS access to track your rides. Please grant location permissions in Settings.")
                    }
                }
            }
            .tabItem {
                Label("Record", systemImage: "record.circle")
            }
            .tag(0)
            
            // History Tab
            NavigationView {
                RideListView()
            }
            .tabItem {
                Label("History", systemImage: "list.bullet")
            }
            .tag(1)
            
            // Stats Tab
            NavigationView {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            // Check for location permissions when app starts
            locationManager.checkLocationAuthorization()
        }
    }
} 