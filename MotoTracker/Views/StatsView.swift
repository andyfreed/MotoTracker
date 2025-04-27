import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var rideManager: RideManager
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary card
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Riding Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(rideManager.rides.count) Rides")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Stats grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Stats")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatsCard(
                            title: "Total Distance",
                            value: rideManager.formattedTotalDistance(with: userSettings),
                            icon: "map"
                        )
                        
                        StatsCard(
                            title: "Total Time",
                            value: rideManager.formattedTotalDuration,
                            icon: "clock"
                        )
                        
                        StatsCard(
                            title: "Avg. Speed",
                            value: rideManager.formattedAverageSpeed(with: userSettings),
                            icon: "speedometer"
                        )
                        
                        if let fastestRide = rideManager.fastestRide {
                            StatsCard(
                                title: "Top Speed",
                                value: fastestRide.formattedMaxSpeed(with: userSettings),
                                icon: "hare"
                            )
                        } else {
                            StatsCard(
                                title: "Top Speed",
                                value: "0 \(userSettings.unitSystem.speedUnit)",
                                icon: "hare"
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Top rides
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Rides")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if rideManager.rides.isEmpty {
                        HStack {
                            Spacer()
                            Text("No rides recorded yet")
                                .foregroundColor(.secondary)
                                .padding()
                            Spacer()
                        }
                    } else {
                        // Longest ride
                        if let longestRide = rideManager.longestRide {
                            TopRideCard(
                                title: "Longest Ride",
                                rideName: longestRide.name,
                                value: longestRide.formattedDistance(with: userSettings),
                                date: longestRide.startTime
                            )
                        }
                        
                        // Fastest ride
                        if let fastestRide = rideManager.fastestRide {
                            TopRideCard(
                                title: "Fastest Ride",
                                rideName: fastestRide.name,
                                value: fastestRide.formattedAverageSpeed(with: userSettings),
                                date: fastestRide.startTime
                            )
                        }
                    }
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct TopRideCard: View {
    let title: String
    let rideName: String
    let value: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rideName)
                        .font(.headline)
                    
                    Text(formattedDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 