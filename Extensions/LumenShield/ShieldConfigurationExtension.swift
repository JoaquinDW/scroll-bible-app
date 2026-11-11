// Not part of the app target yet. Add a "Shield Configuration Extension" target in Xcode
// (File > New > Target), then replace its generated file with this one. See README.
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the screen shown over a shielded app: today's verse and a "Read to unlock" button.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    // Shared with the app through an App Group so the shield can show today's verse.
    private let shared = UserDefaults(suiteName: "group.app.lumen.Lumen")

    private let ivory = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1)
    private let petrol = UIColor(red: 0.14, green: 0.27, blue: 0.31, alpha: 1)
    private let brown = UIColor(red: 0.29, green: 0.23, blue: 0.17, alpha: 1)
    private let gold = UIColor(red: 0.90, green: 0.73, blue: 0.36, alpha: 1)

    private func make() -> ShieldConfiguration {
        let reference = shared?.string(forKey: "shield.reference") ?? "Psalm 23:1"
        let verse = shared?.string(forKey: "shield.verse") ?? "The Lord is my shepherd; I shall not want."
        let button = shared?.string(forKey: "shield.button") ?? "Read to unlock"
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterialLight,
            backgroundColor: ivory,
            icon: UIImage(named: "sheep_reading"),
            title: ShieldConfiguration.Label(text: reference, color: petrol),
            subtitle: ShieldConfiguration.Label(text: verse, color: brown),
            primaryButtonLabel: ShieldConfiguration.Label(text: button, color: petrol),
            primaryButtonBackgroundColor: gold,
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration { make() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { make() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { make() }
}
