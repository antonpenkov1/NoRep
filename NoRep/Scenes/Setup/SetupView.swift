import SwiftUI

@MainActor
final class SetupViewStore: ObservableObject {
    @Published var viewModel = SetupModels.Refresh.ViewModel(
        title: "",
        summary: "",
        emom: EmomConfig(),
        amrap: AmrapConfig(),
        forTime: ForTimeConfig(),
        tabata: TabataConfig(),
        countdown: 10,
        soundEnabled: true,
        name: "",
        note: ""
    )

    var interactor: SetupBusinessLogic!

    func displayRefresh(_ viewModel: SetupModels.Refresh.ViewModel) {
        self.viewModel = viewModel
    }
}

enum SetupSceneFactory {
    @MainActor
    static func make(type: WorkoutType, router appRouter: AppRouter) -> SetupViewStore {
        let store = SetupViewStore()
        let presenter = SetupPresenter()
        presenter.display = store
        let router = SetupRouter(appRouter: appRouter)
        store.interactor = SetupInteractor(type: type, presenter: presenter) { plan in
            router.routeToWorkout(plan: plan)
        }
        return store
    }
}

struct SetupView: View {
    @StateObject private var store: SetupViewStore
    private let type: WorkoutType

    init(type: WorkoutType, router: AppRouter) {
        self.type = type
        _store = StateObject(wrappedValue: SetupSceneFactory.make(type: type, router: router))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    typeSection
                    workoutSection
                    commonSection
                    summaryCard
                    BigButton(title: "START", systemImage: "play.fill") {
                        store.interactor.start()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .navigationTitle(store.viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { store.interactor.load() }
    }

    // MARK: - Type-specific controls

    @ViewBuilder
    private var typeSection: some View {
        switch type {
        case .emom: emomSection
        case .amrap: amrapSection
        case .forTime: forTimeSection
        case .tabata: tabataSection
        case .mix: EmptyView()
        }
    }

    private var emomSection: some View {
        Card {
            VStack(spacing: 8) {
                StepperRow(
                    title: String(localized: "Rounds"),
                    value: Binding(
                        get: { store.viewModel.emom.rounds },
                        set: { store.interactor.update(.emom(EmomConfig(rounds: $0, interval: store.viewModel.emom.interval))) }
                    ),
                    range: 1...99
                )
                Divider().overlay(Theme.cardBorder)
                labeled(String(localized: "Every")) {
                    DurationPicker(duration: Binding(
                        get: { store.viewModel.emom.interval },
                        set: { store.interactor.update(.emom(EmomConfig(rounds: store.viewModel.emom.rounds, interval: $0))) }
                    ), maxMinutes: 10)
                }
            }
        }
    }

    private var amrapSection: some View {
        Card {
            labeled(String(localized: "Duration")) {
                DurationPicker(duration: Binding(
                    get: { store.viewModel.amrap.duration },
                    set: { store.interactor.update(.amrap(AmrapConfig(duration: $0))) }
                ))
            }
        }
    }

    private var forTimeSection: some View {
        Card {
            VStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { store.viewModel.forTime.isCapEnabled },
                    set: { store.interactor.update(.forTime(ForTimeConfig(isCapEnabled: $0, timeCap: store.viewModel.forTime.timeCap))) }
                )) {
                    Text("Time cap")
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.accent)
                if store.viewModel.forTime.isCapEnabled {
                    Divider().overlay(Theme.cardBorder)
                    DurationPicker(duration: Binding(
                        get: { store.viewModel.forTime.timeCap },
                        set: { store.interactor.update(.forTime(ForTimeConfig(isCapEnabled: true, timeCap: $0))) }
                    ))
                }
            }
        }
    }

    private var tabataSection: some View {
        Card {
            VStack(spacing: 8) {
                StepperRow(
                    title: String(localized: "Rounds"),
                    value: Binding(
                        get: { store.viewModel.tabata.rounds },
                        set: { var c = store.viewModel.tabata; c.rounds = $0; store.interactor.update(.tabata(c)) }
                    ),
                    range: 1...30
                )
                Divider().overlay(Theme.cardBorder)
                secondsRow(title: String(localized: "Work"), value: store.viewModel.tabata.work, range: 5...120) {
                    var c = store.viewModel.tabata; c.work = $0; store.interactor.update(.tabata(c))
                }
                Divider().overlay(Theme.cardBorder)
                secondsRow(title: String(localized: "Rest"), value: store.viewModel.tabata.rest, range: 0...120) {
                    var c = store.viewModel.tabata; c.rest = $0; store.interactor.update(.tabata(c))
                }
            }
        }
    }

    // MARK: - Workout name & movements

    private var workoutSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME · optional, tracks your PRs")
                        .font(.sectionLabel)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Fran, Murph, «Monday hell»…", text: Binding(
                        get: { store.viewModel.name },
                        set: { store.interactor.update(.name($0)) }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                }
                Divider().overlay(Theme.cardBorder)
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORKOUT · shown on the timer screen")
                        .font(.sectionLabel)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("21-15-9 thrusters / pull-ups…", text: Binding(
                        get: { store.viewModel.note },
                        set: { store.interactor.update(.note($0)) }
                    ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(2...6)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    // MARK: - Common controls

    private var commonSection: some View {
        Card {
            VStack(spacing: 12) {
                HStack {
                    Text("Countdown")
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Picker("Countdown", selection: Binding(
                        get: { Int(store.viewModel.countdown) },
                        set: { store.interactor.update(.countdown(TimeInterval($0))) }
                    )) {
                        Text("Off").tag(0)
                        Text("5s").tag(5)
                        Text("10s").tag(10)
                        Text("15s").tag(15)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }
                Divider().overlay(Theme.cardBorder)
                Toggle(isOn: Binding(
                    get: { store.viewModel.soundEnabled },
                    set: { store.interactor.update(.sound($0)) }
                )) {
                    Text("Sound cues")
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.accent)
            }
        }
    }

    private var summaryCard: some View {
        Card {
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.accent)
                Text(store.viewModel.summary)
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.sectionLabel)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secondsRow(title: String, value: TimeInterval, range: ClosedRange<Int>, onChange: @escaping (TimeInterval) -> Void) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text("\(Int(value))s")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 52)
            Stepper("", value: Binding(
                get: { Int(value) },
                set: { onChange(TimeInterval($0)) }
            ), in: range, step: 5)
            .labelsHidden()
        }
    }
}
