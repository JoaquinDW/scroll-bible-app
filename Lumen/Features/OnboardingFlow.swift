import SwiftUI

/// Welcome, then a short illustrated setup that ends with a personal plan.
struct OnboardingFlow: View {
    @Bindable var profile: UserProfile
    @Environment(\.lang) private var lang
    @State private var step = 0
    @State private var reminder = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wantsReminder = true
    @FocusState private var nameFocused: Bool

    private let lastStep = 8

    var body: some View {
        ZStack {
            if step == 0 {
                WelcomeView { advance() }
                    .transition(.opacity)
            } else {
                Brand.Palette.ivory.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(spacing: 22) {
                            stepContent
                        }
                        .padding(.horizontal, Brand.Metrics.padding)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    footer
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                step = max(0, step - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.Palette.petrol)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(Text(Copy.back(lang)))
            ProgressBar(value: Double(step) / Double(lastStep))
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(step == lastStep ? Copy.onbStart(lang) : Copy.continueLabel(lang)) { advance() }
                .buttonStyle(.primary)
                .disabled(step == 6 && profile.sheepName.trimmingCharacters(in: .whitespaces).isEmpty)
            if step == 7 {
                Button(Copy.skipForNow(lang)) { advance() }
                    .font(Brand.Fonts.callout)
                    .foregroundStyle(Brand.Palette.petrolSoft)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, Brand.Metrics.padding)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1:
            stepHeader(.idle, Copy.onbLanguageTitle(lang), Copy.onbLanguageBody(lang))
            ForEach(AppLanguage.allCases) { language in
                OptionRow(title: language.displayName, subtitle: nil, symbol: "globe", selected: profile.language == language) {
                    profile.language = language
                    if let first = ContentStore.shared.translations(for: language).first {
                        profile.translationID = first.id
                    }
                }
            }
        case 2:
            stepHeader(.reading, Copy.onbTranslationTitle(lang), Copy.onbTranslationBody(lang))
            ForEach(ContentStore.shared.translations(for: profile.language)) { translation in
                OptionRow(title: translation.name, subtitle: Copy.publicDomain(lang), symbol: "book.closed.fill",
                          selected: profile.translationID == translation.id) {
                    profile.translationID = translation.id
                }
            }
            Text(Copy.onbTranslationNote(lang))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 3:
            stepHeader(.happy, Copy.onbGoalTitle(lang), Copy.onbGoalBody(lang))
            ForEach(Goal.allCases) { goal in
                OptionRow(title: Copy.goalTitle(goal)(lang), subtitle: Copy.goalBody(goal)(lang), symbol: Copy.goalSymbol(goal),
                          selected: profile.goal == goal) {
                    profile.goal = goal
                }
            }
        case 4:
            stepHeader(.idle, Copy.onbTimeTitle(lang), Copy.onbTimeBody(lang))
            ForEach([3, 5, 10], id: \.self) { minutes in
                OptionRow(title: Copy.minutesADay.f(lang, minutes), subtitle: minutes == 5 ? Copy.recommended(lang) : nil,
                          symbol: "hourglass", selected: profile.dailyMinutes == minutes) {
                    profile.dailyMinutes = minutes
                }
            }
        case 5:
            stepHeader(.sleepy, Copy.onbReminderTitle(lang), Copy.onbReminderBody(lang))
            VStack(spacing: 14) {
                Toggle(Copy.onbReminderToggle(lang), isOn: $wantsReminder)
                    .font(Brand.Fonts.body)
                    .tint(Brand.Palette.gold)
                if wantsReminder {
                    DatePicker(Copy.reminderTime(lang), selection: $reminder, displayedComponents: .hourAndMinute)
                        .font(Brand.Fonts.body)
                }
            }
            .foregroundStyle(Brand.Palette.petrol)
            .softCard()
            Text(Copy.onbReminderExample.f(lang, profile.displaySheepName))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 6:
            stepHeader(.happy, Copy.onbNameTitle(lang), Copy.onbNameBody(lang))
            TextField(Copy.onbNamePlaceholder(lang), text: $profile.sheepName)
                .font(Brand.Fonts.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.Palette.petrol)
                .submitLabel(.done)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .softCard()
                .onAppear { nameFocused = true }
        case 7:
            stepHeader(.returned, Copy.onbFriendTitle(lang), Copy.onbFriendBody(lang))
            ShareLink(item: Copy.inviteMessage.f(lang, Brand.name)) {
                Label(Copy.inviteFriend(lang), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.quiet)
        default:
            planSummary
        }
    }

    private func stepHeader(_ state: SheepState, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 10) {
            SheepView(state: state, size: 120, name: profile.sheepName.isEmpty ? nil : profile.sheepName)
                .padding(.top, 6)
            Text(title)
                .font(Brand.Fonts.title)
                .foregroundStyle(Brand.Palette.petrol)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrolSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 4)
    }

    private var planSummary: some View {
        let journey = ContentStore.shared.journey(profile.currentJourneyID)
        return VStack(spacing: 18) {
            stepHeader(.celebrating, Copy.onbPlanTitle.f(lang, profile.displaySheepName), Copy.onbPlanBody(lang))
            VStack(alignment: .leading, spacing: 14) {
                PlanRow(symbol: "map.fill", text: journey?.title.t(lang) ?? "")
                PlanRow(symbol: "hourglass", text: Copy.minutesADay.f(lang, profile.dailyMinutes))
                PlanRow(symbol: "book.closed.fill", text: ContentStore.shared.translation(profile.translationID)?.name ?? profile.translationID)
                PlanRow(symbol: Copy.goalSymbol(profile.goal), text: Copy.goalTitle(profile.goal)(lang))
                if wantsReminder {
                    PlanRow(symbol: "bell.fill", text: reminder.formatted(date: .omitted, time: .shortened))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard()
        }
    }

    private func advance() {
        if step == 5 {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminder)
            profile.reminderHour = parts.hour ?? 8
            profile.reminderMinute = parts.minute ?? 0
            profile.remindersOn = wantsReminder
            if wantsReminder {
                NotificationService.enable(for: profile)
            }
        }
        if step == 6 {
            profile.sheepName = profile.sheepName.trimmingCharacters(in: .whitespaces)
            nameFocused = false
        }
        if step >= lastStep {
            profile.hasOnboarded = true
        } else {
            step += 1
        }
    }
}

struct WelcomeView: View {
    var onStart: () -> Void
    @Environment(\.lang) private var lang
    @State private var appeared = false

    var body: some View {
        ZStack {
            SceneView(config: SceneConfig(name: "scene_meadow_day_01", lightLevel: 4, bloom: 16), glow: appeared ? 0.35 : 0)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Text(Brand.name)
                    .font(Brand.Fonts.headline)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundStyle(Brand.Palette.petrol)
                    .padding(.top, 28)
                Spacer()
                SheepView(state: .happy, size: 190)
                    .padding(.bottom, 26)
                VStack(spacing: 12) {
                    Text(Copy.welcomePromise(lang))
                        .font(Brand.Fonts.display)
                        .foregroundStyle(Brand.Palette.petrol)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                    Text(Copy.welcomeBody(lang))
                        .font(Brand.Fonts.body)
                        .foregroundStyle(Brand.Palette.petrol)
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous).fill(Brand.Palette.ivory.opacity(0.9)))
                .padding(.horizontal, Brand.Metrics.padding)
                Button(Copy.welcomeStart(lang), action: onStart)
                    .buttonStyle(.primary)
                    .padding(.horizontal, Brand.Metrics.padding)
                    .padding(.top, 18)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4)) { appeared = true }
        }
    }
}

struct OptionRow: View {
    var title: String
    var subtitle: String?
    var symbol: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Brand.Palette.teal)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Brand.Fonts.headline)
                        .foregroundStyle(Brand.Palette.petrol)
                    if let subtitle {
                        Text(subtitle)
                            .font(Brand.Fonts.callout)
                            .foregroundStyle(Brand.Palette.petrolSoft)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Brand.Palette.gold : Brand.Palette.petrol.opacity(0.25))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Brand.Metrics.cardCorner, style: .continuous).fill(Brand.Palette.paper))
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Metrics.cardCorner, style: .continuous)
                    .stroke(selected ? Brand.Palette.gold : Brand.Palette.petrol.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct PlanRow: View {
    var symbol: String
    var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Brand.Palette.gold)
                .frame(width: 26)
            Text(text)
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrol)
        }
    }
}
