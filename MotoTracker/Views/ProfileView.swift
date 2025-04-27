import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var rideManager: RideManager
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showingLogoutAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                if let user = supabaseManager.currentUser {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Profile Image
                            profileImageSection(user: user)
                            
                            // User Info
                            userInfoSection(user: user)
                            
                            // Stats Card
                            statsCard()
                            
                            // Settings & Logout
                            settingsSection()
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Text("Not signed in")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        NavigationLink(destination: SignInView()) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .background(Color.black.opacity(0.4))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("Profile")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Error", isPresented: $showingErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
        }
    }
    
    private func profileImageSection(user: User) -> some View {
        VStack {
            if let profileImageURL = user.profileImageURL, let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            }
            
            Text(user.username)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 20)
    }
    
    private func userInfoSection(user: User) -> some View {
        VStack(spacing: 15) {
            Text("Account Information")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            infoRow(title: "Username", value: user.username)
            infoRow(title: "Email", value: user.email)
            infoRow(title: "Account ID", value: user.id)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func statsCard() -> some View {
        VStack(spacing: 15) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                statItem(count: "\(rideManager.rides.count)", title: "Rides")
                statItem(count: rideManager.formattedTotalDistance(with: userSettings), title: "Distance")
                statItem(count: rideManager.formattedTotalDuration, title: "Duration")
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }
    
    private func statItem(count: String, title: String) -> some View {
        VStack {
            Text(count)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func settingsSection() -> some View {
        VStack(spacing: 15) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                // Edit profile action
            }) {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text("Edit Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: {
                // Change password action
            }) {
                HStack {
                    Image(systemName: "lock.circle")
                    Text("Change Password")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: {
                showingLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Logout")
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.3))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }
    
    private func logout() {
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.signOut()
                isLoading = false
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    isLoading = false
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SupabaseManager.shared)
            .environmentObject(RideManager())
            .environmentObject(UserSettings())
    }
} 