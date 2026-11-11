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
    var lastError: String?
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
            lastError = nil
        } catch {
            isAuthorized = false
            lastError = error.localizedDescription
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
