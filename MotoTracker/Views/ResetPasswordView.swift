import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
            Text("Back")
                .foregroundColor(.white)
        })
        .alert("Error", isPresented: $showingErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .alert("Success", isPresented: $showingSuccessAlert, actions: {
            Button("OK", role: .cancel) { 
                presentationMode.wrappedValue.dismiss()
            }
        }, message: {
            Text("Password reset instructions have been sent to your email.")
        })
    }
    
    private func headerView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.rotation")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Enter your email to receive instructions")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
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
        }
    }
    
    private func actionButtons() -> some View {
        VStack(spacing: 15) {
            // Reset Password Button
            Button(action: resetPassword) {
                Text("Send Reset Instructions")
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
            Text("Remember your password?")
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Sign In")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func resetPassword() {
        // Validate form
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.resetPassword(email: email)
                
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
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

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView()
            .environmentObject(SupabaseManager.shared)
    }
} 