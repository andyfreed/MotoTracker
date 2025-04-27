import SwiftUI

struct SimpleSignInView: View {
    @ObservedObject private var supabaseIntegration = SupabaseIntegration.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "figure.motorsport")
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
                    
                    // Email field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        TextField("", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    
                    // Password field
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        SecureField("", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Sign In button
                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Sign Up link
                    Button(action: {
                        showingSignUp = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingSignUp) {
                SimpleSignUpView()
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        supabaseIntegration.signIn(email: email, password: password) { success, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
}

struct SimpleSignInView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleSignInView()
    }
} 