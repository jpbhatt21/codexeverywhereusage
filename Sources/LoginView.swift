import SwiftUI

struct LoginView: View {
    @EnvironmentObject var accountManager: AccountManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Codex Everywhere")
                .font(.title2.bold())

            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isLoading)

            Divider()

            if !accountManager.accounts.isEmpty {
                VStack(spacing: 8) {
                    Text("Or switch account")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(accountManager.accounts) { account in
                        Button(action: { accountManager.switchTo(account) }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                Text(account.email)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let token = try await APIClient.shared.login(email: email, password: password)
                accountManager.addAccount(email: email, token: token)
                email = ""
                password = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
