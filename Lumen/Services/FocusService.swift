import Foundation
import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

/// Focus Mode: shields the apps the user picked until today's session is done.
///
/// The app target handles authorization, app selection and applying or clearing the shield.
/// The custom shield screen ("Read to unlock") and the midnight re-lock need two app
/// extensions; their source is in /Extensions and the README explains how to add them.
@MainActor
@Observable
final class FocusService {
    static let shared = FocusService()

    var isAuthorized = false
    /// Why the last authorization attempt failed, in words the user can act on.
    var lastFailure: FocusFailure?
    var selectedCount = 0

    #if canImport(FamilyControls)
    var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    #endif

    private let selectionKey = "focus.selection"

    private init() {
        #if canImport(FamilyControls)
        if let data = UserDefaults.standard.data(forKey: selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        updateCount()
        #endif
    }

    var isSupported: Bool {
        #if canImport(FamilyControls)
        return true
        #else
        return false
        #endif
    }

    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            lastFailure = isAuthorized ? nil : .denied
        } catch {
            isAuthorized = false
            lastFailure = FocusFailure(error)
        }
        #endif
    }

    func saveSelection() {
        #if canImport(FamilyControls)
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
        updateCount()
        #endif
    }

    /// Locks or unlocks to match the user's day. Safe to call often.
    func sync(with profile: UserProfile) {
        let shouldLock = profile.focusEnabled && profile.isPremium && profile.status != .doneToday
        apply(locked: shouldLock)
    }

    func apply(locked: Bool) {
        #if canImport(FamilyControls)
        guard isAuthorized, locked else {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        #endif
    }

    #if canImport(FamilyControls)
    private func updateCount() {
        selectedCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }
    #endif
}

/// Authorization failures, mapped to messages the user can act on (never the raw system text).
enum FocusFailure: Equatable {
    /// The user said no, or closed the Screen Time prompt.
    case denied
    /// Screen Time is restricted or managed on this device (parental controls, MDM).
    case restricted
    /// This build is not signed with the Family Controls entitlement. Shows up as
    /// "Couldn't communicate with a helper application" on a device.
    case notConfigured
    /// Anything else, including the Simulator, where Screen Time is not available.
    case unavailable

    init(_ error: Error) {
        #if targetEnvironment(simulator)
        self = .unavailable
        #else
        #if canImport(FamilyControls)
        if let familyError = error as? FamilyControlsError {
            switch familyError {
            case .authorizationCanceled: self = .denied
            case .restricted, .invalidAccountType, .authorizationConflict: self = .restricted
            case .unavailable: self = .unavailable
            default: self = .notConfigured
            }
            return
        }
        #endif
        let ns = error as NSError
        // NSCocoaErrorDomain 4097/4099: the Screen Time helper refused this app, which in
        // practice means the Family Controls entitlement is missing from the signed build.
        if ns.domain == NSCocoaErrorDomain && (ns.code == 4097 || ns.code == 4099) {
            self = .notConfigured
        } else {
            self = .unavailable
        }
        #endif
    }

    var message: LText {
        switch self {
        case .denied: return Copy.focusFailDenied
        case .restricted: return Copy.focusFailRestricted
        case .notConfigured: return Copy.focusFailNotConfigured
        case .unavailable: return Copy.focusFailUnavailable
        }
    }
}

/// Presents Apple's app picker when Screen Time APIs are available.
struct FocusPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @State private var service = FocusService.shared

    func body(content: Content) -> some View {
        #if canImport(FamilyControls)
        content
            .familyActivityPicker(isPresented: $isPresented, selection: $service.selection)
            .onChange(of: isPresented) { _, showing in
                if !showing { service.saveSelection() }
            }
        #else
        content
        #endif
    }
}
