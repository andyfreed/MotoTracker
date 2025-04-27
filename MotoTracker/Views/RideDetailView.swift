import SwiftUI
import MapKit
import UIKit

// Add this helper function for pre-iOS 16 support
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct RideDetailView: View {
    let ride: Ride
    @State private var mapRegion: MKCoordinateRegion
    @State private var showExtraTelemetry = false
    @State private var isShowingShareSheet = false
    @State private var sharedImage: UIImage?
    @EnvironmentObject private var userSettings: UserSettings
    
    init(ride: Ride) {
        self.ride = ride
        
        // Initialize map region with the ride's region, or a default if there's none
        if let region = ride.region {
            _mapRegion = State(initialValue: region)
        } else {
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3323, longitude: -122.0312),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Map
                ExtendedMapView(
                    region: $mapRegion,
                    polylines: [ride.routePolyline]
                )
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Share button
                Button(action: {
                    generateShareableImage()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Ride")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Details section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(formattedDate(ride.startTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let endTime = ride.endTime {
                            Text(formattedTime(endTime))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Distance", value: ride.formattedDistance(with: userSettings), icon: "speedometer")
                        StatCard(title: "Duration", value: ride.formattedDuration, icon: "clock")
                        StatCard(title: "Avg. Speed", value: ride.formattedAverageSpeed(with: userSettings), icon: "gauge")
                        StatCard(title: "Max Speed", value: ride.formattedMaxSpeed(with: userSettings), icon: "hare")
                    }
                    
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
                    .padding(.top, 8)
                    
                    // Additional telemetry section
                    if showExtraTelemetry {
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()
                            
                            Text("Elevation Data")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(
                                    title: "Elevation Gain", 
                                    value: ride.formattedElevationGain(with: userSettings), 
                                    icon: "arrow.up.right"
                                )
                                
                                StatCard(
                                    title: "Elevation Loss", 
                                    value: ride.formattedElevationLoss(with: userSettings), 
                                    icon: "arrow.down.right"
                                )
                                
                                StatCard(
                                    title: "Max Altitude", 
                                    value: userSettings.formatAltitude(ride.maxAltitude), 
                                    icon: "mountain.2.fill"
                                )
                                
                                StatCard(
                                    title: "Min Altitude", 
                                    value: userSettings.formatAltitude(ride.minAltitude), 
                                    icon: "mountain.2"
                                )
                            }
                            
                            // If ride has location points with course/heading data
                            if !ride.locationPoints.isEmpty && ride.locationPoints.first(where: { $0.course >= 0 }) != nil {
                                Divider()
                                
                                Text("Direction Data")
                                    .font(.headline)
                                
                                let startDirection = directionFromCourse(ride.locationPoints.first?.course ?? 0)
                                let endDirection = directionFromCourse(ride.locationPoints.last?.course ?? 0)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text("Start Direction")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Image(systemName: "location.north.line")
                                                .foregroundColor(.green)
                                            Text(startDirection)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("End Direction")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Text(endDirection)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                            Image(systemName: "location.north.line")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .transition(.opacity)
                    }
                    
                    Divider()
                    
                    // Start and end locations
                    if !ride.locationPoints.isEmpty {
                        LocationSection(
                            startPoint: ride.locationPoints.first!,
                            endPoint: ride.locationPoints.last!
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle(ride.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = sharedImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func directionFromCourse(_ course: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int(round(course.truncatingRemainder(dividingBy: 360) / 45))
        return directions[index]
    }
    
    private func generateShareableImage() {
        let shareableView = ShareableRideView(ride: ride, userSettings: userSettings)
            .frame(width: 1080, height: 1920)
            .background(Color(.systemBackground))
        
        // Use ImageRenderer if available (iOS 16+), otherwise use snapshot function
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareableView)
            if let image = renderer.uiImage {
                self.sharedImage = image
                self.isShowingShareSheet = true
            }
        } else {
            // Pre-iOS 16 approach
            self.sharedImage = shareableView.snapshot()
            self.isShowingShareSheet = true
        }
    }
}

// Update ShareSheet to specifically target Instagram when available
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Exclude activities that wouldn't make sense for an image of a ride
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .print
        ]
        
        // Completion handler
        controller.completionWithItemsHandler = { activity, completed, items, error in
            if completed, let activity = activity {
                // Track successful shares
                print("Shared via: \(activity)")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

struct ShareableRideView: View {
    let ride: Ride
    let userSettings: UserSettings
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with logo and title
            VStack(spacing: 4) {
                Text("🏍 MotoTracker")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.blue)
                
                Text(ride.name)
                    .font(.title2.bold())
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(formatDate(ride.startTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 40)
            
            // Map with route (placeholder - in a real app, we'd render the actual map)
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.5), .green.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(16)
                .shadow(radius: 3)
                
                VStack {
                    Image(systemName: "map.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Ride Route")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            
            // Ride stats in a fancy card
            VStack(spacing: 24) {
                // Title
                Text("Ride Stats")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Primary stats in a grid
                HStack(spacing: 20) {
                    StatBox(
                        title: "Distance",
                        value: ride.formattedDistance(with: userSettings),
                        icon: "ruler"
                    )
                    
                    StatBox(
                        title: "Duration",
                        value: ride.formattedDuration,
                        icon: "clock"
                    )
                }
                
                HStack(spacing: 20) {
                    StatBox(
                        title: "Avg Speed",
                        value: ride.formattedAverageSpeed(with: userSettings),
                        icon: "speedometer"
                    )
                    
                    StatBox(
                        title: "Max Speed",
                        value: ride.formattedMaxSpeed(with: userSettings),
                        icon: "hare"
                    )
                }
                
                // Elevation stats if available
                if ride.totalAscent > 0 || ride.totalDescent > 0 {
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Elevation Gain",
                            value: ride.formattedElevationGain(with: userSettings),
                            icon: "arrow.up.right"
                        )
                        
                        StatBox(
                            title: "Elevation Loss",
                            value: ride.formattedElevationLoss(with: userSettings),
                            icon: "arrow.down.right"
                        )
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 5)
            .padding()
            
            // App info and social tags
            VStack(spacing: 8) {
                Text("Shared via MotoTracker")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("#MotoTracker #MotorcycleRide #RideTracking")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                    Image(systemName: "gauge")
                    Image(systemName: "mountain.2")
                    Image(systemName: "map")
                }
                .font(.title2)
                .foregroundColor(.blue.opacity(0.7))
                .padding(.top, 4)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// Helper view for consistent stat presentation in shared image
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LocationSection: View {
    let startPoint: LocationPoint
    let endPoint: LocationPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Information")
                .font(.headline)
            
            HStack(alignment: .top) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Start")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(startPoint.coordinate.latitude), \(startPoint.coordinate.longitude)")
                        .font(.caption)
                }
            }
            
            HStack(alignment: .top) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading) {
                    Text("End")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(endPoint.coordinate.latitude), \(endPoint.coordinate.longitude)")
                        .font(.caption)
                }
            }
        }
    }
} 