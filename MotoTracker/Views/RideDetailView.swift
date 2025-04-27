import SwiftUI
import MapKit

struct RideDetailView: View {
    let ride: Ride
    @State private var mapRegion: MKCoordinateRegion
    
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
                MapView(region: $mapRegion, polylines: [ride.routePolyline])
                    .frame(height: 300)
                    .cornerRadius(12)
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
                        StatCard(title: "Distance", value: ride.formattedDistance, icon: "speedometer")
                        StatCard(title: "Duration", value: ride.formattedDuration, icon: "clock")
                        StatCard(title: "Avg. Speed", value: ride.formattedAverageSpeed, icon: "speedometer.medium")
                        StatCard(title: "Max Speed", value: ride.formattedMaxSpeed, icon: "hare")
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