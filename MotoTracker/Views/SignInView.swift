import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    @State private var showingSignUp = false
    @State private var showingResetPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    headerView()
                    
                    Spacer()
                        .frame(height: 20)
                    
                    formView()
                    
                    actionButtons()
                    
                    Spacer()
                    
                    footerView()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 40)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .background(Color.black.opacity(0.4))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingErrorAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
            .fullScreenCover(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
            }
        }
    }
    
    private func headerView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.motorsport")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Sign in to track your rides")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func formView() -> some View {
        VStack(spacing: 15) {
            // Email field
            VStack(alignment: .leading, spacing: 5) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 5) {
                Text("Password")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                SecureField("", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
            
            // Forgot password
            HStack {
                Spacer()
                Button(action: {
                    showingResetPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.top, 5)
        }
    }
    
    private func actionButtons() -> some View {
        VStack(spacing: 15) {
            // Sign In Button
            Button(action: signIn) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
    }
    
    private func footerView() -> some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: {
                showingSignUp = true
            }) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func signIn() {
        // Validate form
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.signIn(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                }
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

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(SupabaseManager.shared)
    }
} 