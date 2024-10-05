import SwiftUI

enum LoginError: Error {
    case expiredSession
    case transferMarketBanned
    case captchaRequired
    case unexpectedError(String)
}

struct LoginView: View {
    @State private var xUtSid: String = "3db07621-9b45-4841-9026-9e9f09dbc27d"
    @State private var isLoggedIn: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("FIFA Sniper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    TextField("Enter X-UT-SID", text: $xUtSid)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none) // Disable auto-capitalization
                        .disableAutocorrection(true) // Disable auto-correction
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(xUtSid.isEmpty || isLoading)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Login")
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $isLoggedIn) {
            DashboardView(xUtSid: xUtSid)
        }
    }
    
    private func handleLoginError(_ error: Error) -> String {
        switch error {
        case LoginError.expiredSession:
            return "Your session has expired. Please log in again."
        case LoginError.transferMarketBanned:
            return "You are currently banned from the transfer market."
        case LoginError.captchaRequired:
            return "Please complete the captcha to proceed."
        case LoginError.unexpectedError(let message):
            return message // You can choose to log this message if needed
        default:
            return "An unexpected error occurred. Please try again later."
        }
    }
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.login(xUtSid: xUtSid) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let success):
                    if success {
                        isLoggedIn = true
                    } else {
                        
                        errorMessage = "Invalid session token"
                    }
                case .failure(let error):
                    errorMessage = handleLoginError(error)
                }
            }
        }
    }
}

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}
