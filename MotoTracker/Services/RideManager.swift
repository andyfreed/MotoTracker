import Foundation
import Combine

class RideManager: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var activeRide: Ride?
    @Published var isRecording = false
    
    private let saveKey = "savedRides"
    
    init() {
        loadRides()
    }
    
    // MARK: - Ride Recording
    
    func startRide(name: String = "My Ride") {
        activeRide = Ride(name: name, startTime: Date())
        isRecording = true
    }
    
    func updateActiveRide(with locationPoints: [LocationPoint]) {
        guard isRecording, var ride = activeRide else { return }
        
        ride.locationPoints = locationPoints
        activeRide = ride
    }
    
    func stopRide() {
        guard isRecording, var ride = activeRide else { return }
        
        ride.endTime = Date()
        rides.append(ride)
        saveRides()
        
        activeRide = nil
        isRecording = false
    }
    
    func discardRide() {
        activeRide = nil
        isRecording = false
    }
    
    // MARK: - Ride Management
    
    func deleteRide(at indexSet: IndexSet) {
        rides.remove(atOffsets: indexSet)
        saveRides()
    }
    
    func deleteRide(id: UUID) {
        if let index = rides.firstIndex(where: { $0.id == id }) {
            rides.remove(at: index)
            saveRides()
        }
    }
    
    func updateRide(_ ride: Ride) {
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index] = ride
            saveRides()
        }
    }
    
    // MARK: - Persistence
    
    private func saveRides() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rides)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving rides: \(error.localizedDescription)")
        }
    }
    
    private func loadRides() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            rides = try decoder.decode([Ride].self, from: data)
        } catch {
            print("Error loading rides: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    
    var totalDistance: Double {
        rides.reduce(0) { $0 + $1.distance }
    }
    
    var formattedTotalDistance: String {
        let distanceInKilometers = totalDistance / 1000
        return String(format: "%.2f km", distanceInKilometers)
    }
    
    var totalDuration: TimeInterval {
        rides.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: totalDuration) ?? "Unknown"
    }
    
    var averageSpeed: Double {
        guard !rides.isEmpty else { return 0 }
        
        let totalSpeed = rides.reduce(0) { $0 + $1.averageSpeed }
        return totalSpeed / Double(rides.count)
    }
    
    var formattedAverageSpeed: String {
        let speedInKmh = averageSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", speedInKmh)
    }
    
    var longestRide: Ride? {
        rides.max(by: { $0.distance < $1.distance })
    }
    
    var fastestRide: Ride? {
        rides.max(by: { $0.averageSpeed < $1.averageSpeed })
    }
} 