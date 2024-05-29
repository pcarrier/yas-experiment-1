import ServiceManagement
import SwiftUI

class yasService: ObservableObject {
    @Published var onLogin: Bool = (SMAppService.mainApp.status == SMAppService.Status.enabled) {
        didSet {
            if onLogin {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
}

@main
struct yasApp: App {
    init() {
        if (!UserDefaults.standard.bool(forKey: "alreadyStarted")) {
            UserDefaults.standard.setValue(true, forKey: "alreadyStarted")
            try? SMAppService.mainApp.register()
        }
    }

    @StateObject private var service = yasService()
    var body: some Scene {
        MenuBarExtra("YAS", systemImage: "hand.thumbsup") {
            AppMenu(onLogin: $service.onLogin)
        }
    }
}

struct AppMenu: View {
    @Binding var onLogin: Bool

    var body: some View {
        Link("Manage", destination: URL(string: "https://yas.tools")!)
        Divider()
        Toggle(isOn: $onLogin, label: { Text("Launch at login") })
        Button(action: { NSApplication.shared.terminate(nil) }, label: { Text("Quit") })
    }
}
