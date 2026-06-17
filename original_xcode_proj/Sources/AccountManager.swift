import Foundation
import SwiftUI

struct Account: Identifiable, Codable, Hashable {
    let id: String
    let email: String
    let token: String

    init(email: String, token: String) {
        self.id = email
        self.email = email
        self.token = token
    }
}

@MainActor
class AccountManager: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var activeAccount: Account?
    @Published var isLoggedIn = false

    private let accountsKey = "codex_accounts"
    private let activeKey = "codex_active_account"

    init() {
        loadAccounts()
    }

    var currentToken: String? {
        activeAccount?.token
    }

    func addAccount(email: String, token: String) {
        let account = Account(email: email, token: token)

        if !accounts.contains(where: { $0.email == email }) {
            accounts.append(account)
        }

        activeAccount = account
        isLoggedIn = true

        saveAccounts()
        saveActiveAccount()
    }

    func switchTo(_ account: Account) {
        activeAccount = account
        isLoggedIn = true
        saveActiveAccount()
    }

    func removeAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }

        if activeAccount?.id == account.id {
            activeAccount = accounts.first
        }

        if accounts.isEmpty {
            isLoggedIn = false
            activeAccount = nil
        }

        saveAccounts()
        saveActiveAccount()
    }

    func logout() {
        activeAccount = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: activeKey)
    }

    // MARK: - Persistence

    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }

    private func saveActiveAccount() {
        if let account = activeAccount,
           let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: activeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
    }

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = decoded
        }

        if let data = UserDefaults.standard.data(forKey: activeKey),
           let decoded = try? JSONDecoder().decode(Account.self, from: data) {
            activeAccount = decoded
            isLoggedIn = true
        }
    }
}
