import SwiftUI
import MapKit

struct ActiveRideView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @State private var showingConfirmationDialog = false
    @State private var showingRenameDialog = false
    @State private var rideName = "My Ride"
    
    // Timer for updating the view regularly
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Map showing current location and path
            MapView(
                region: $locationManager.currentRegion,
                showsUserLocation: true,
                trackingMode: .follow
            )
            .ignoresSafeArea(edges: .top)
            .frame(height: 300)
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    showingRenameDialog = true
                }) {
                    Text(rideName)
                        .font(.headline)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .padding(8)
                }
            }
            
            // Stats for current ride
            VStack(spacing: 16) {
                // Current location
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    Text(locationManager.currentAddress)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ActiveStatCard(
                        title: "Distance",
                        value: formattedDistance(),
                        icon: "map"
                    )
                    
                    ActiveStatCard(
                        title: "Duration",
                        value: formattedDuration(),
                        icon: "clock"
                    )
                    
                    ActiveStatCard(
                        title: "Current Speed",
                        value: formattedCurrentSpeed(),
                        icon: "speedometer"
                    )
                    
                    ActiveStatCard(
                        title: "Max Speed",
                        value: formattedMaxSpeed(),
                        icon: "hare"
                    )
                }
                .padding(.horizontal)
                
                // Stop button
                Button(action: {
                    showingConfirmationDialog = true
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Ride")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .offset(y: -20)
        }
        .onAppear {
            // Update ride name if available
            if let ride = rideManager.activeRide {
                rideName = ride.name
            }
        }
        .onReceive(timer) { _ in
            // Update ride with latest location points
            rideManager.updateActiveRide(with: locationManager.currentLocationPoints)
        }
        .confirmationDialog(
            "Are you sure you want to stop recording?",
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Save Ride", role: .none) {
                locationManager.stopTracking()
                rideManager.stopRide()
            }
            
            Button("Discard Ride", role: .destructive) {
                locationManager.stopTracking()
                rideManager.discardRide()
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Ride", isPresented: $showingRenameDialog) {
            TextField("Ride Name", text: $rideName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard !rideName.isEmpty else { return }
                if var ride = rideManager.activeRide {
                    ride.name = rideName
                    rideManager.activeRide = ride
                }
            }
        }
        .navigationTitle("Recording Ride")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Formatting Functions
    
    private func formattedDistance() -> String {
        guard let ride = rideManager.activeRide else { return "0.00 km" }
        
        let locations = locationManager.currentLocationPoints
        guard locations.count > 1 else { return "0.00 km" }
        
        var totalDistance = 0.0
        for i in 0..<locations.count-1 {
            let start = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
            let end = CLLocation(latitude: locations[i+1].latitude, longitude: locations[i+1].longitude)
            totalDistance += end.distance(from: start)
        }
        
        let distanceInKilometers = totalDistance / 1000
        return String(format: "%.2f km", distanceInKilometers)
    }
    
    private func formattedDuration() -> String {
        guard let ride = rideManager.activeRide else { return "00:00" }
        
        let duration = Date().timeIntervalSince(ride.startTime)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: duration) ?? "00:00:00"
    }
    
    private func formattedCurrentSpeed() -> String {
        guard let location = locationManager.lastLocation else { return "0 km/h" }
        
        let speedInKmh = max(0, location.speed) * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", speedInKmh)
    }
    
    private func formattedMaxSpeed() -> String {
        let speeds = locationManager.currentLocationPoints.map { $0.speed }
        let maxSpeed = speeds.max() ?? 0
        let speedInKmh = maxSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", speedInKmh)
    }
}

struct ActiveStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Helper to apply cornerRadius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorners(radius: radius, corners: corners))
    }
}

struct RoundedCorners: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 