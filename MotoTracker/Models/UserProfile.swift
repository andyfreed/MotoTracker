import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    var username: String
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var totalRides: Int
    var totalDistance: Double
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case totalRides = "total_rides"
        case totalDistance = "total_distance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // User stat metrics
    var formattedTotalDistance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let distanceStr = formatter.string(from: NSNumber(value: totalDistance)) ?? "0"
        return "\(distanceStr) km"
    }
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
} 