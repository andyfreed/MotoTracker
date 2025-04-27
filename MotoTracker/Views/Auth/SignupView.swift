import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]), 
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Title
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        // Signup form
                        VStack(spacing: 20) {
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            TextField("Username", text: $username)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                            
                            // Validation messages
                            VStack(alignment: .leading, spacing: 5) {
                                if !username.isEmpty && username.count < 3 {
                                    ValidationMessage(message: "Username must be at least 3 characters", isValid: false)
                                }
                                
                                if !password.isEmpty && password.count < 6 {
                                    ValidationMessage(message: "Password must be at least 6 characters", isValid: false)
                                }
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    ValidationMessage(message: "Passwords do not match", isValid: false)
                                }
                            }
                            
                            Button(action: signUp) {
                                HStack {
                                    Text("Sign Up")
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
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        
                        // Error message
                        if let error = supabaseManager.authError {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .padding(.horizontal, 30)
                        }
                        
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.white)
                                Text("Sign In")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .navigationBarItems(leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.title2)
            })
            .navigationBarTitle("", displayMode: .inline)
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && email.contains("@") && 
        !username.isEmpty && username.count >= 3 &&
        !password.isEmpty && password.count >= 6 &&
        password == confirmPassword
    }
    
    private func signUp() {
        Task {
            do {
                try await supabaseManager.signUp(email: email, password: password, username: username)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct ValidationMessage: View {
    let message: String
    let isValid: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle" : "exclamationmark.circle")
                .foregroundColor(isValid ? .green : .red)
            Text(message)
                .font(.caption)
                .foregroundColor(isValid ? .green : .red)
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(SupabaseManager.shared)
    }
} 