import SwiftUI
import SwiftData

@main
struct LumenApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .tint(Brand.Palette.petrol)
        }
        .modelContainer(for: [UserProfile.self, SessionRecord.self, SavedVerse.self])
    }
}

/// Decides between onboarding, the soft paywall and the main app.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @State private var router = Router()

    var body: some View {
        Group {
            if let profile = profiles.first {
                if !profile.hasOnboarded {
                    OnboardingFlow(profile: profile)
                } else if !profile.hasSeenPaywall {
                    PaywallView(profile: profile) { profile.hasSeenPaywall = true }
                } else {
                    MainTabs(profile: profile)
                }
            } else {
                Brand.Palette.ivory.ignoresSafeArea()
            }
        }
        .environment(router)
        .environment(\.lang, profiles.first?.language ?? .en)
        .animation(.easeInOut(duration: 0.5), value: profiles.first?.hasOnboarded)
        .animation(.easeInOut(duration: 0.5), value: profiles.first?.hasSeenPaywall)
        .onAppear {
            if profiles.isEmpty { context.insert(UserProfile()) }
            refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .onOpenURL { url in
            // lumen://session opens today's reading (used by the Focus Mode shield and notifications).
            guard url.scheme == Brand.urlScheme, let profile = profiles.first, profile.hasOnboarded else { return }
            if url.host == "session" {
                profile.hasSeenPaywall = true
                router.reviewDay = nil
                router.showSession = true
            }
        }
    }

    private func refresh() {
        guard let profile = profiles.first else { return }
        profile.refreshStreak()
        FocusService.shared.sync(with: profile)
    }
}

struct MainTabs: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            HomeView(profile: profile)
                .tabItem { Label(Copy.tabHome(lang), systemImage: "sun.max.fill") }
                .tag(0)
            JourneysView(profile: profile)
                .tabItem { Label(Copy.tabJourneys(lang), systemImage: "map.fill") }
                .tag(1)
            FlockView(profile: profile)
                .tabItem { Label(Copy.tabFlock(lang), systemImage: "person.3.fill") }
                .tag(2)
            ProgressScreen(profile: profile)
                .tabItem { Label(Copy.tabProgress(lang), systemImage: "leaf.fill") }
                .tag(3)
        }
        .fullScreenCover(isPresented: $router.showSession) {
            SessionFlow(profile: profile)
                .environment(router)
                .environment(\.lang, profile.language)
        }
        .fullScreenCover(isPresented: $router.showLostSheep) {
            LostSheepView(profile: profile)
                .environment(router)
                .environment(\.lang, profile.language)
        }
        .sheet(isPresented: $router.showSettings) {
            SettingsView(profile: profile)
                .environment(router)
                .environment(\.lang, profile.language)
        }
        .sheet(isPresented: $router.showFocus) {
            FocusSetupView(profile: profile)
                .environment(router)
                .environment(\.lang, profile.language)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView(profile: profile) { router.showPaywall = false }
                .environment(\.lang, profile.language)
        }
    }
}
