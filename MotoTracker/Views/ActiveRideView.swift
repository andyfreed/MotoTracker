import SwiftUI
import MapKit

struct ActiveRideView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var rideManager: RideManager
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showingConfirmationDialog = false
    @State private var showingRenameDialog = false
    @State private var rideName = "My Ride"
    @State private var showExtraTelemetry = false
    
    // Timer for updating the view regularly
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Map showing current location and path
            ExtendedMapView(region: $locationManager.currentRegion)
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
                // Current location and direction
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    Text(locationManager.currentAddress)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let location = locationManager.lastLocation, location.course >= 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "location.north.line")
                            Text(getDirectionFromCourse(location.course))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
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
                
                // Toggle for additional telemetry
                Button(action: {
                    withAnimation {
                        showExtraTelemetry.toggle()
                    }
                }) {
                    HStack {
                        Text(showExtraTelemetry ? "Hide Advanced Telemetry" : "Show Advanced Telemetry")
                        Image(systemName: showExtraTelemetry ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                // Additional telemetry section
                if showExtraTelemetry {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ActiveStatCard(
                            title: "Altitude",
                            value: formattedAltitude(),
                            icon: "mountain.2"
                        )
                        
                        ActiveStatCard(
                            title: "Elevation Gain",
                            value: formattedElevationGain(),
                            icon: "arrow.up.right"
                        )
                        
                        ActiveStatCard(
                            title: "Heading",
                            value: formattedHeading(),
                            icon: "location.north.line"
                        )
                        
                        ActiveStatCard(
                            title: "GPS Accuracy",
                            value: formattedAccuracy(),
                            icon: "scope"
                        )
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
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
            if rideManager.activeRide != nil {
                rideName = rideManager.activeRide?.name ?? "My Ride"
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
        guard rideManager.activeRide != nil else { return "0.00 \(userSettings.unitSystem.distanceUnit)" }
        
        let locations = locationManager.currentLocationPoints
        guard locations.count > 1 else { return "0.00 \(userSettings.unitSystem.distanceUnit)" }
        
        var totalDistance = 0.0
        for i in 0..<locations.count-1 {
            let start = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
            let end = CLLocation(latitude: locations[i+1].latitude, longitude: locations[i+1].longitude)
            totalDistance += end.distance(from: start)
        }
        
        let distanceInKilometers = totalDistance / 1000
        return userSettings.formatDistance(distanceInKilometers)
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
        guard let location = locationManager.lastLocation else { return "0 \(userSettings.unitSystem.speedUnit)" }
        
        let speedInKmh = max(0, location.speed) * 3.6 // Convert m/s to km/h
        return userSettings.formatSpeed(speedInKmh)
    }
    
    private func formattedMaxSpeed() -> String {
        let speeds = locationManager.currentLocationPoints.map { $0.speed }
        let maxSpeed = speeds.max() ?? 0
        let speedInKmh = maxSpeed * 3.6 // Convert m/s to km/h
        return userSettings.formatSpeed(speedInKmh)
    }
    
    private func formattedAltitude() -> String {
        guard let location = locationManager.lastLocation else { return "0 \(userSettings.unitSystem.altitudeUnit)" }
        return userSettings.formatAltitude(location.altitude)
    }
    
    private func formattedElevationGain() -> String {
        guard locationManager.currentLocationPoints.count > 1 else { 
            return "0 \(userSettings.unitSystem.altitudeUnit)" 
        }
        
        var ascent = 0.0
        for i in 1..<locationManager.currentLocationPoints.count {
            let diff = locationManager.currentLocationPoints[i].altitude - locationManager.currentLocationPoints[i-1].altitude
            if diff > 0 {
                ascent += diff
            }
        }
        return userSettings.formatAltitude(ascent)
    }
    
    private func formattedHeading() -> String {
        guard let location = locationManager.lastLocation, location.course >= 0 else { 
            return "N/A" 
        }
        
        return getDirectionFromCourse(location.course)
    }
    
    private func formattedAccuracy() -> String {
        guard let location = locationManager.lastLocation else { 
            return "N/A" 
        }
        
        return "\(Int(location.horizontalAccuracy))m"
    }
    
    private func getDirectionFromCourse(_ course: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int(round(course.truncatingRemainder(dividingBy: 360) / 45))
        return directions[index]
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