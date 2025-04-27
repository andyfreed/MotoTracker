import Foundation
import CoreLocation
import MapKit

struct LocationPoint: Identifiable, Codable {
    var id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double // in meters per second
    let altitude: Double
    let course: Double // direction of travel in degrees (0-360)
    let heading: Double? // device orientation in degrees (0-360), may be nil
    let horizontalAccuracy: Double // accuracy of position in meters
    let verticalAccuracy: Double // accuracy of altitude in meters
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed > 0 ? location.speed : 0
        self.altitude = location.altitude
        self.course = location.course
        self.heading = location.course >= 0 ? location.course : nil
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
    }
    
    // Additional initializer for creating from saved data
    init(latitude: Double, longitude: Double, timestamp: Date, speed: Double, altitude: Double, 
         course: Double = 0, heading: Double? = nil, horizontalAccuracy: Double = 0, verticalAccuracy: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.speed = speed
        self.altitude = altitude
        self.course = course
        self.heading = heading
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
    }
    
    // Format direction (course) as cardinal direction
    var cardinalDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int(round(course.truncatingRemainder(dividingBy: 360) / 45))
        return directions[index]
    }
}

struct Ride: Identifiable, Codable {
    var id = UUID()
    var name: String
    var startTime: Date
    var endTime: Date?
    var locationPoints: [LocationPoint]
    
    // Computed properties
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
    
    var distance: Double {
        guard locationPoints.count > 1 else { return 0 }
        
        var totalDistance = 0.0
        for i in 0..<locationPoints.count-1 {
            let start = CLLocation(latitude: locationPoints[i].latitude, longitude: locationPoints[i].longitude)
            let end = CLLocation(latitude: locationPoints[i+1].latitude, longitude: locationPoints[i+1].longitude)
            totalDistance += end.distance(from: start)
        }
        
        return totalDistance
    }
    
    var formattedDistance: String {
        let distanceInKilometers = distance / 1000
        return String(format: "%.2f km", distanceInKilometers)
    }
    
    var averageSpeed: Double {
        guard !locationPoints.isEmpty else { return 0 }
        
        let totalSpeed = locationPoints.reduce(0) { $0 + $1.speed }
        return totalSpeed / Double(locationPoints.count)
    }
    
    var formattedAverageSpeed: String {
        let speedInKmh = averageSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", speedInKmh)
    }
    
    var maxSpeed: Double {
        locationPoints.map { $0.speed }.max() ?? 0
    }
    
    var formattedMaxSpeed: String {
        let speedInKmh = maxSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", speedInKmh)
    }
    
    // New telemetry calculations
    
    var minAltitude: Double {
        locationPoints.map { $0.altitude }.min() ?? 0
    }
    
    var maxAltitude: Double {
        locationPoints.map { $0.altitude }.max() ?? 0
    }
    
    var totalAscent: Double {
        guard locationPoints.count > 1 else { return 0 }
        
        var ascent = 0.0
        for i in 1..<locationPoints.count {
            let diff = locationPoints[i].altitude - locationPoints[i-1].altitude
            if diff > 0 {
                ascent += diff
            }
        }
        return ascent
    }
    
    var totalDescent: Double {
        guard locationPoints.count > 1 else { return 0 }
        
        var descent = 0.0
        for i in 1..<locationPoints.count {
            let diff = locationPoints[i-1].altitude - locationPoints[i].altitude
            if diff > 0 {
                descent += diff
            }
        }
        return descent
    }
    
    var region: MKCoordinateRegion? {
        guard !locationPoints.isEmpty else { return nil }
        
        // Find the center point
        let latitudes = locationPoints.map { $0.latitude }
        let longitudes = locationPoints.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate the span with some padding
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.01),
            longitudeDelta: max(lonDelta, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // Sample route polyline for map display
    var routePolyline: MKPolyline {
        let coordinates = locationPoints.map { $0.coordinate }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    // Formatted values with unit conversion
    func formattedDistance(with settings: UserSettings) -> String {
        let distanceInKilometers = distance / 1000
        return settings.formatDistance(distanceInKilometers)
    }
    
    func formattedAverageSpeed(with settings: UserSettings) -> String {
        let speedInKmh = averageSpeed * 3.6 // Convert m/s to km/h
        return settings.formatSpeed(speedInKmh)
    }
    
    func formattedMaxSpeed(with settings: UserSettings) -> String {
        let speedInKmh = maxSpeed * 3.6 // Convert m/s to km/h
        return settings.formatSpeed(speedInKmh)
    }
    
    func formattedElevationGain(with settings: UserSettings) -> String {
        return settings.formatAltitude(totalAscent)
    }
    
    func formattedElevationLoss(with settings: UserSettings) -> String {
        return settings.formatAltitude(totalDescent)
    }
    
    init(name: String = "My Ride", startTime: Date = Date(), locationPoints: [LocationPoint] = []) {
        self.name = name
        self.startTime = startTime
        self.locationPoints = locationPoints
    }
} 