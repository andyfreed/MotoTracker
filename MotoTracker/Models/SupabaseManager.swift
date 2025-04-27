import Foundation
import Supabase

// Make the class public so it's accessible across the module
public class SupabaseManager: ObservableObject {
    public static let shared = SupabaseManager()
    
    // MARK: - Properties
    private let supabaseURL = URL(string: "https://nrtqhohamqkdlhfnlxjt.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ydHFob2hhbXFrZGxoZm5seGp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MjUxNTUsImV4cCI6MjA2MTMwMTE1NX0.yx_q1fjPVrZ3UNRblUSTa1DdNcyAym1e7lLaZM4PpIk"
    
    private(set) lazy var client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
    
    @Published public var currentUser: User?
    @Published public var authError: String?
    @Published public var isLoading = false
    
    // MARK: - Initialization
    
    private init() {
        // Check for existing session
        Task {
            do {
                let session = try await client.auth.session
                await MainActor.run {
                    self.currentUser = User(id: session.user.id.uuidString,
                                           email: session.user.email ?? "",
                                           username: session.user.userMetadata["username"] as? String ?? "")
                }
            } catch {
                print("No existing session: \(error)")
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    public func signIn(email: String, password: String) async throws {
        await setLoading(true)
        authError = nil
        
        do {
            let response = try await client.auth.signIn(email: email, password: password)
            await MainActor.run {
                self.currentUser = User(id: response.user.id.uuidString,
                                       email: response.user.email ?? "",
                                       username: response.user.userMetadata["username"] as? String ?? "")
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    public func signUp(email: String, password: String, username: String? = nil) async throws {
        await setLoading(true)
        authError = nil
        
        var userData: [String: String] = [:]
        if let username = username {
            userData["username"] = username
        }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: userData
            )
            
            if let user = response.user {
                await MainActor.run {
                    self.currentUser = User(id: user.id.uuidString,
                                           email: user.email ?? "",
                                           username: username ?? "")
                    self.isLoading = false
                }
            } else {
                throw AuthError.signUpFailed
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    public func signOut() async throws {
        await setLoading(true)
        
        do {
            try await client.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    public func resetPassword(email: String) async throws {
        await setLoading(true)
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Ride Management
    
    public func saveRide(_ ride: Ride) async throws -> String {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        // Convert ride to dictionary format for Supabase
        let rideData: [String: Any] = [
            "user_id": userId,
            "name": ride.name,
            "start_time": ISO8601DateFormatter().string(from: ride.startTime),
            "end_time": ride.endTime != nil ? ISO8601DateFormatter().string(from: ride.endTime!) : NSNull(),
            "distance": ride.distance,
            "max_speed": ride.maxSpeed * 3.6, // Convert to km/h
            "avg_speed": ride.averageSpeed * 3.6, // Convert to km/h
            "elevation_gain": ride.totalAscent,
            "elevation_loss": ride.totalDescent
        ]
        
        do {
            let response = try await client
                .from("rides")
                .insert(values: rideData)
                .execute()
            
            if let data = response.data,
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstItem = jsonObject.first,
               let rideId = firstItem["id"] as? String {
                return rideId
            } else {
                throw APIError.invalidResponse
            }
        } catch {
            print("Error saving ride: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func fetchUserRides() async throws -> [Ride] {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let response = try await client
                .from("rides")
                .select()
                .eq("user_id", value: userId)
                .order("start_time", ascending: false)
                .execute()
            
            guard let data = response.data else {
                return []
            }
            
            struct SupabaseRide: Codable {
                let id: String
                let user_id: String
                let name: String
                let start_time: String
                let end_time: String?
                let distance: Double?
                let max_speed: Double?
                let avg_speed: Double?
                let elevation_gain: Double?
                let elevation_loss: Double?
            }
            
            let decoder = JSONDecoder()
            let supabaseRides = try decoder.decode([SupabaseRide].self, from: data)
            
            let dateFormatter = ISO8601DateFormatter()
            
            return supabaseRides.map { supabaseRide in
                var ride = Ride(name: supabaseRide.name, 
                               startTime: dateFormatter.date(from: supabaseRide.start_time) ?? Date())
                
                ride.id = UUID(uuidString: supabaseRide.id) ?? UUID()
                if let endTimeStr = supabaseRide.end_time, 
                   let endTime = dateFormatter.date(from: endTimeStr) {
                    ride.endTime = endTime
                }
                
                // Other properties would need to be set based on your Ride model
                return ride
            }
        } catch {
            print("Error fetching rides: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
}

// MARK: - Error Types

public enum AuthError: Error, LocalizedError {
    case signUpFailed
    case loginFailed
    case sessionExpired
    case userNotFound
    case notAuthenticated
    
    public var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .loginFailed:
            return "Login failed. Please check your credentials."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userNotFound:
            return "User not found."
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        }
    }
}

public enum APIError: Error, LocalizedError {
    case invalidResponse
    case dataFetchFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from the server."
        case .dataFetchFailed:
            return "Failed to fetch data."
        }
    }
}

// MARK: - User Model

public struct User: Identifiable, Codable {
    public let id: String
    public let email: String
    public let username: String
    public var profileImageURL: String?
    
    public init(id: String, email: String, username: String, profileImageURL: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.profileImageURL = profileImageURL
    }
} 