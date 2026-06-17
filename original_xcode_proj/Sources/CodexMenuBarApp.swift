import SwiftUI

@main
struct CodexMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var accountManager = AccountManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(accountManager)
        } label: {
            Label {
                Text("Codex")
            } icon: {
                Image(systemName: "brain.head.profile")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
