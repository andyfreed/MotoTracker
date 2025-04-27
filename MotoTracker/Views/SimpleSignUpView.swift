import SwiftUI

struct SimpleSignUpView: View {
    @ObservedObject private var supabaseIntegration = SupabaseIntegration.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Title
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
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
                    .padding(.top, 20)
                    
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
                    
                    // Confirm Password field
                    VStack(alignment: .leading) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        SecureField("", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Sign Up button
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white))
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Account created successfully! Please check your email.")
            }
        }
    }
    
    private func signUp() {
        // Validate inputs
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            showingErrorAlert = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        supabaseIntegration.signUp(email: email, password: password) { success, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            } else {
                showingSuccessAlert = true
            }
        }
    }
}

struct SimpleSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleSignUpView()
    }
} 