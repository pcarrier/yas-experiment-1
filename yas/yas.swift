import Network
import ServiceManagement
import SwiftUI

class YasServer {
    private let service: yasService
    private let secret: String
    private let listener: NWListener

    init(service: yasService, secret: String) {
        self.service = service
        self.secret = secret
        let params = NWParameters(tls: nil)
        params.acceptLocalOnly = true
        let opts = NWProtocolWebSocket.Options()
        opts.autoReplyPing = true
        params.defaultProtocolStack.applicationProtocols.insert(opts, at: 0)
        listener = try! NWListener(using: params)
        listener.stateUpdateHandler = self.stateUpdateHandler(to:)
        listener.newConnectionHandler = self.newConnectionHandler(of:)
    }

    func start() throws {
        listener.start(queue: .main)
    }
    
    private func stateUpdateHandler(to newState: NWListener.State) {
        switch newState {
        case .setup:
            fallthrough
        case .ready:
            // FIXME: report state, eg in menu icon
            if let port = listener.port {
                print("Listening on port \(port)")
                service.manageURL = URL(string: "https://yas.tools/manage#\(port):\(secret)")
            }
            break
        case .cancelled:
            // FIXME: crash "cleanly"
            exit(EXIT_FAILURE)
        case .waiting(_):
            fallthrough
        case .failed(_):
            // FIXME: crash "cleanly"
            exit(EXIT_FAILURE)
        default:
            break
        }
    }
    
    private func newConnectionHandler(of: NWConnection) {
        exit(EXIT_SUCCESS)
    }
}

class yasService: ObservableObject {
    let secretBytesCount = 32

    @Published var manageURL: URL?
    @Published var onLogin: Bool = (SMAppService.mainApp.status == SMAppService.Status.enabled) {
        didSet {
            if onLogin {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
    @Published var installed: Bool = false
    
    init() {
        if (!UserDefaults.standard.bool(forKey: "alreadyStarted")) {
            UserDefaults.standard.setValue(true, forKey: "alreadyStarted")
            try? SMAppService.mainApp.register()
        }
        
        install()

        var secretBytes = Data(count: secretBytesCount)
        let status = secretBytes.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            SecRandomCopyBytes(kSecRandomDefault, secretBytesCount, ptr.baseAddress!)
        }
        if status != errSecSuccess {
            // FIXME: crash "cleanly"
            exit(EXIT_FAILURE)
        } else {
            let secret = secretBytes.base64EncodedString()
            try! YasServer(service: self, secret: secret).start()
        }
    }
    
    func install() {
        let daemon = SMAppService.daemon(plistName: "tools.yas.yasd.plist")
        do { try daemon.register() }
        catch let error as NSError {
            print(error)
            installed = error.code == kSMErrorAlreadyRegistered
        }
    }
}

@main
struct YasApp: App {
    @StateObject private var service = yasService()
    var body: some Scene {
        MenuBarExtra("YAS", systemImage: "hand.thumbsup") {
            AppMenu(onLogin: $service.onLogin, manageURL: $service.manageURL)
        }
    }
}

struct AppMenu: View {
    @Binding var onLogin: Bool
    @Binding var manageURL: URL?
    var body: some View {
        if let url = manageURL {
            Link("Manage", destination: url)
            Divider()
        }
        Toggle(isOn: $onLogin, label: { Text("Launch at login") })
        Button(action: { NSApplication.shared.terminate(nil) }, label: { Text("Quit") })
    }
}
