// Not part of the app target yet. Add a "Device Activity Monitor Extension" target, then use this file.
// In the app, start a repeating daily DeviceActivitySchedule (00:00 to 23:59) named "lumen.daily".
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Puts the shield back at the start of each day, even if the app is not opened.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let shared = UserDefaults(suiteName: "group.app.lumen.Lumen")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let data = shared?.data(forKey: "focus.selection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    }
}
