import ServiceManagement

/// Registers the app as a login item. macOS keeps the real state (users can also
/// change it in System Settings → General → Login Items), so always read it back.
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled = SMAppService.mainApp.status == .enabled
    @Published private(set) var error: String?

    func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = "Couldn't change this: \(error.localizedDescription)"
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
