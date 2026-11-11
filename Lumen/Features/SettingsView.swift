import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @Environment(\.modelContext) private var context
    @State private var reminder = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(Copy.settingsSheep(lang)) {
                    TextField(Copy.onbNamePlaceholder(lang), text: $profile.sheepName)
                        .autocorrectionDisabled()
                }

                Section(Copy.settingsReading(lang)) {
                    Picker(Copy.settingsLanguage(lang), selection: Binding(
                        get: { profile.language },
                        set: { language in
                            profile.language = language
                            // Keep the translation in the chosen language unless the reader picks otherwise.
                            if ContentStore.shared.translation(profile.translationID)?.language != language.rawValue,
                               let first = ContentStore.shared.translations(for: language).first {
                                profile.translationID = first.id
                            }
                            NotificationService.refresh(for: profile)
                        })) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    Picker(Copy.settingsTranslation(lang), selection: $profile.translationID) {
                        ForEach(ContentStore.shared.bundle.translations) { translation in
                            Text(translation.name).tag(translation.id)
                        }
                    }
                    Picker(Copy.settingsDaily(lang), selection: $profile.dailyMinutes) {
                        ForEach([3, 5, 10], id: \.self) { minutes in
                            Text(Copy.minutesADay.f(lang, minutes)).tag(minutes)
                        }
                    }
                }

                Section {
                    Toggle(Copy.onbReminderToggle(lang), isOn: Binding(
                        get: { profile.remindersOn },
                        set: { on in
                            profile.remindersOn = on
                            if on { NotificationService.enable(for: profile) } else { NotificationService.refresh(for: profile) }
                        }))
                        .tint(Brand.Palette.gold)
                    if profile.remindersOn {
                        DatePicker(Copy.reminderTime(lang), selection: $reminder, displayedComponents: .hourAndMinute)
                            .onChange(of: reminder) { _, value in
                                let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
                                profile.reminderHour = parts.hour ?? 8
                                profile.reminderMinute = parts.minute ?? 0
                                NotificationService.refresh(for: profile)
                            }
                    }
                } header: {
                    Text(Copy.settingsReminder(lang))
                } footer: {
                    Text(Copy.settingsReminderNote(lang))
                }

                Section(Copy.settingsPremium(lang)) {
                    Button {
                        router.showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { router.showFocus = true }
                    } label: {
                        Label(Copy.focusTitle(lang), systemImage: "lock.shield.fill")
                    }
                    Button {
                        router.showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { router.showPaywall = true }
                    } label: {
                        Label(profile.isPremium ? Copy.settingsPremiumActive(lang) : Copy.settingsSeePlans(lang), systemImage: "sparkles")
                    }
                }

                Section {
                    Text(Copy.aboutStudyAids(lang))
                    Text(Copy.aboutTranslations(lang))
                    Text(Copy.aboutCare(lang))
                } header: {
                    Text(Copy.settingsAbout.f(lang, Brand.name))
                }
                .font(Brand.Fonts.callout)
                .foregroundStyle(Brand.Palette.petrolSoft)

                Section {
                    Button(Copy.devNextDay(lang)) {
                        profile.debugDayOffset += 1
                        profile.refreshStreak()
                        FocusService.shared.sync(with: profile)
                    }
                    Button(Copy.devSkipDay(lang)) {
                        profile.debugDayOffset += 2
                        profile.refreshStreak()
                        FocusService.shared.sync(with: profile)
                    }
                    Button(Copy.devTogglePremium(lang)) {
                        profile.isPremium.toggle()
                        FocusService.shared.sync(with: profile)
                    }
                    Button(Copy.devReset(lang), role: .destructive) { reset() }
                } header: {
                    Text(Copy.devTitle(lang))
                } footer: {
                    Text(Copy.devNote.f(lang, profile.debugDayOffset))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.Palette.ivory.ignoresSafeArea())
            .navigationTitle(Copy.settingsTitle(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.done(lang)) { router.showSettings = false }
                }
            }
            .onAppear {
                var parts = DateComponents()
                parts.hour = profile.reminderHour
                parts.minute = profile.reminderMinute
                reminder = Calendar.current.date(from: parts) ?? Date()
            }
        }
    }

    private func reset() {
        router.showSettings = false
        FocusService.shared.apply(locked: false)
        for record in (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? [] { context.delete(record) }
        for verse in (try? context.fetch(FetchDescriptor<SavedVerse>())) ?? [] { context.delete(verse) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            profile.resetEverything()
            NotificationService.refresh(for: profile)
            router.tab = 0
        }
    }
}
