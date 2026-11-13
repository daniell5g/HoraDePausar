import SwiftUI
import HoraDePausarCore

struct SettingsView: View {
    @Environment(DevotionStore.self) private var store
    @Environment(AppCoordinator.self) private var coordinator
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1] // segunda → domingo
    /// Weekday name in the app language; `day` is a `Calendar` weekday (1 = Sunday).
    private static func weekdayName(_ day: Int) -> String {
        let pt = ["domingo", "segunda", "terça", "quarta", "quinta", "sexta", "sábado"]
        let en = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return L(pt[day - 1], en[day - 1])
    }

    var body: some View {
        Form {
            Section {
                Picker(L("Idioma", "Language"), selection: Binding(get: { store.language }, set: { store.setLanguage($0) })) {
                    ForEach(AppLanguage.allCases, id: \.self) { Text($0.nativeName).tag($0) }
                }
            } footer: {
                Text(L("Muda o app e as passagens.", "Changes the app and the passages."))
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(L("Lembrete diário", "Daily reminder"), isOn: binding(\.schedule.isEnabled))
                DatePicker(L("Horário", "Time"), selection: timeBinding, displayedComponents: .hourAndMinute)
                    .disabled(!store.state.schedule.isEnabled)
                LabeledContent(L("Dias", "Days")) {
                    HStack(spacing: 6) {
                        ForEach(Self.weekdayOrder, id: \.self) { day in
                            DayChip(letter: WeekDay.letter(weekday: day, in: store.language),
                                    name: Self.weekdayName(day),
                                    isOn: store.state.schedule.weekdays.contains(day)) {
                                store.updatePreferences { state in
                                    if state.schedule.weekdays.contains(day) { state.schedule.weekdays.remove(day) } else { state.schedule.weekdays.insert(day) }
                                }
                            }
                        }
                    }
                }
                .disabled(!store.state.schedule.isEnabled)
            } header: {
                Text(L("Quando pausar", "When to pause"))
            } footer: {
                Text(footerText).foregroundStyle(.secondary)
            }

            Section(L("Como avisar", "How to remind")) {
                Picker(L("Estilo", "Style"), selection: binding(\.reminderStyle)) {
                    ForEach(ReminderStyle.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Toggle(L("Som suave", "Soft sound"), isOn: binding(\.playSound))
                Button(L("Mostrar o lembrete agora", "Show the reminder now")) { coordinator.presentReminder(force: true) }
            }

            Section {
                Toggle(L("Lembrar de novo à noite", "Remind me again at night"), isOn: binding(\.evening.isEnabled))
                DatePicker(L("Horário da noite", "Evening time"), selection: eveningBinding, displayedComponents: .hourAndMinute)
                    .disabled(!store.state.evening.isEnabled)
            } header: {
                Text(L("Lembrete da noite", "Evening reminder"))
            } footer: {
                Text(L("Só aparece se a passagem do dia ainda não foi lida.", "Only shows if today's passage hasn't been read yet.")).foregroundStyle(.secondary)
            }
            .disabled(!store.state.schedule.isEnabled)

            Section(L("Sistema", "System")) {
                Toggle(L("Abrir ao iniciar o Mac", "Open when the Mac starts"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enable in setLaunchAtLogin(enable) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                let edition = PassageLibrary.edition(for: store.language)
                Text(edition.attribution)
                    .font(.caption)
                Text(edition.changesNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    Link(edition.licenseTitle, destination: edition.licenseURL)
                    Link(edition.sourceTitle, destination: edition.sourceURL)
                }
                .font(.caption)
                .foregroundStyle(Brand.accent)
            } header: {
                Text(L("Texto bíblico", "Bible text"))
            }
        }
        .formStyle(.grouped)
        .subtleScrollIndicator()
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .navigationTitle(L("Ajustes", "Settings"))
    }

    private var footerText: String {
        guard store.state.schedule.isEnabled else {
            return L("O app não vai te lembrar. A passagem do dia continua no ícone da barra de menus.",
                     "The app won't remind you. Today's passage is still in the menu bar icon.")
        }
        guard !store.state.schedule.weekdays.isEmpty else { return L("Escolha pelo menos um dia.", "Pick at least one day.") }
        if let next = store.nextReminder { return L("Próxima pausa \(ReminderText.relative(next)).", "Next pause \(ReminderText.relative(next)).") }
        return ""
    }

    private var timeBinding: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: store.state.schedule.hour, minute: store.state.schedule.minute, second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.updatePreferences { $0.schedule.hour = c.hour ?? 7; $0.schedule.minute = c.minute ?? 0 }
        }
    }

    private var eveningBinding: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: store.state.evening.hour, minute: store.state.evening.minute, second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.updatePreferences { $0.evening.hour = c.hour ?? 21; $0.evening.minute = c.minute ?? 0 }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<AppState, T>) -> Binding<T> {
        Binding { store.state[keyPath: keyPath] } set: { value in store.updatePreferences { $0[keyPath: keyPath] = value } }
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            try LoginItem.set(enable)
            loginError = nil
        } catch {
            loginError = L("O macOS recusou: ", "macOS refused: ") + error.localizedDescription
            launchAtLogin = LoginItem.isEnabled
        }
    }
}

struct DayChip: View {
    var letter: String
    var name: String
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.system(size: 11.5, weight: .semibold))
                .frame(width: 26, height: 26)
                .foregroundStyle(isOn ? Brand.onAccent : Color.secondary)
                .background(Circle().fill(isOn ? Brand.accent : Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .help(name)
    }
}
