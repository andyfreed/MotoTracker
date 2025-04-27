import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var rideManager: RideManager
    // Re-enable SupabaseManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                RideListView()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("Ride History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchRides) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // Re-enable Supabase fetch
                if supabaseManager.currentUser != nil {
                    fetchRides()
                }
            }
            .alert("Error Loading Rides", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    private func fetchRides() {
        guard supabaseManager.currentUser != nil else { return }
        
        isLoading = true
        
        Task {
            do {
                // Fetch rides from Supabase
                let rides = try await supabaseManager.fetchUserRides()
                
                // Update the ride manager with fetched rides
                await MainActor.run {
                    // Merge with local rides or replace them
                    // This implementation replaces local rides with Supabase ones
                    // You might want different behavior depending on your sync strategy
                    rideManager.rides = rides
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environmentObject(RideManager())
            .environmentObject(SupabaseManager.shared)
    }
} 