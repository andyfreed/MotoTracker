import SwiftUI

struct RideListView: View {
    @EnvironmentObject private var rideManager: RideManager
    @State private var isShowingRenameDialog = false
    @State private var selectedRideId: UUID?
    @State private var newRideName = ""
    
    var body: some View {
        Group {
            if rideManager.rides.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Rides Yet")
                        .font(.title)
                    
                    Text("Your recorded rides will appear here")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(rideManager.rides.sorted(by: { $0.startTime > $1.startTime })) { ride in
                        NavigationLink(destination: RideDetailView(ride: ride)) {
                            RideRow(ride: ride)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                rideManager.deleteRide(id: ride.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                selectedRideId = ride.id
                                newRideName = ride.name
                                isShowingRenameDialog = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Ride History")
        .alert("Rename Ride", isPresented: $isShowingRenameDialog) {
            TextField("Ride Name", text: $newRideName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let id = selectedRideId,
                   let index = rideManager.rides.firstIndex(where: { $0.id == id }),
                   !newRideName.isEmpty {
                    var updatedRide = rideManager.rides[index]
                    updatedRide.name = newRideName
                    rideManager.updateRide(updatedRide)
                }
            }
        }
    }
}

struct RideRow: View {
    let ride: Ride
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ride.name)
                .font(.headline)
            
            HStack {
                Label(ride.formattedDistance, systemImage: "speedometer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(ride.formattedDuration, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(formattedDate(ride.startTime))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 