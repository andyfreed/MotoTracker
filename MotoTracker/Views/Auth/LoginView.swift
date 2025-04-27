import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignup = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]), 
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("MotoTracker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Track your rides. Share your adventures.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    
                    // Login form
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                        
                        Button(action: login) {
                            HStack {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                
                                if supabaseManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(supabaseManager.isLoading || !isValidInput)
                        .opacity(isValidInput ? 1.0 : 0.6)
                        
                        Button(action: { showingSignup = true }) {
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.white)
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Error message
                    if let error = supabaseManager.authError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal, 30)
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingSignup) {
                SignupView()
                    .environmentObject(supabaseManager)
            }
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private func login() {
        Task {
            do {
                try await supabaseManager.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SupabaseManager.shared)
    }
} 