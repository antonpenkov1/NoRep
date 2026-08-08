import SwiftUI
import Charts

@MainActor
final class WorkoutViewStore: ObservableObject {
    @Published var tick = WorkoutSceneModels.Tick.ViewModel(
        state: .idle,
        blockTitle: "",
        label: "",
        timeText: "",
        phaseColor: Theme.accent,
        progress: nil,
        totalLine: "",
        nextUpLine: nil,
        noteText: nil,
        showsRoundButton: false,
        roundsText: "",
        showsDoneSegment: false,
        showsSkip: false
    )
    @Published var summary: WorkoutSceneModels.Summary.ViewModel?

    var interactor: WorkoutBusinessLogic!
    var router: WorkoutRoutingLogic!

    func displayTick(_ viewModel: WorkoutSceneModels.Tick.ViewModel) {
        tick = viewModel
    }

    func displaySummary(_ viewModel: WorkoutSceneModels.Summary.ViewModel) {
        summary = viewModel
    }
}

enum WorkoutSceneFactory {
    @MainActor
    static func make(plan: WorkoutPlan, router appRouter: AppRouter) -> WorkoutViewStore {
        let store = WorkoutViewStore()
        let presenter = WorkoutPresenter()
        presenter.display = store
        store.interactor = WorkoutInteractor(plan: plan, presenter: presenter)
        store.router = WorkoutRouter(appRouter: appRouter)
        return store
    }
}

struct WorkoutView: View {
    @StateObject private var store: WorkoutViewStore
    @State private var showAbandonDialog = false
    @State private var showFullNote = false

    init(plan: WorkoutPlan, router: AppRouter) {
        _store = StateObject(wrappedValue: WorkoutSceneFactory.make(plan: plan, router: router))
    }

    var body: some View {
        ZStack {
            background

            if let summary = store.summary {
                SummaryView(summary: summary, interactor: store.interactor) {
                    store.router.routeToRoot()
                }
            } else {
                timerContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if store.summary == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAbandonDialog = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .confirmationDialog("End this workout?", isPresented: $showAbandonDialog, titleVisibility: .visible) {
            Button("Finish & save") {
                store.interactor.finishEarly()
            }
            Button("Discard", role: .destructive) {
                store.interactor.abandon()
                store.router.routeToRoot()
            }
            Button("Keep going", role: .cancel) {}
        }
        .sheet(isPresented: $showFullNote) {
            NoteSheet(title: store.tick.blockTitle, text: store.tick.noteText ?? "")
        }
        .onAppear { store.interactor.start() }
    }

    private var background: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            RadialGradient(
                colors: [store.tick.phaseColor.opacity(store.tick.state == .paused ? 0.05 : 0.16), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: store.tick.phaseColor)
        }
    }

    private var timerContent: some View {
        VStack(spacing: 0) {
            header
            noteHint
            Spacer()
            dial
            Spacer()
            roundSection
            controls
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(store.tick.blockTitle)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.5)
            Text(store.tick.label)
                .font(.system(.title2, design: .rounded).weight(.black))
                .foregroundStyle(store.tick.phaseColor)
                .tracking(1)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var noteHint: some View {
        if let note = store.tick.noteText {
            Button {
                showFullNote = true
            } label: {
                Text(note)
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.card.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private var dial: some View {
        ZStack {
            ProgressRing(progress: store.tick.progress, color: store.tick.phaseColor, lineWidth: 12)
            VStack(spacing: 8) {
                Text(store.tick.timeText)
                    .font(.timerDigits(88))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 36)
                    .contentTransition(.numericText(countsDown: true))
                Text(store.tick.totalLine)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                if store.tick.state == .paused {
                    Text("PAUSED")
                        .font(.system(.caption, design: .rounded).weight(.black))
                        .foregroundStyle(Theme.prepare)
                        .tracking(2)
                }
            }
        }
        .frame(maxWidth: 340, maxHeight: 340)
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
        .onTapGesture {
            if store.tick.showsRoundButton {
                store.interactor.addRound()
            }
        }
    }

    @ViewBuilder
    private var roundSection: some View {
        if store.tick.showsRoundButton {
            VStack(spacing: 4) {
                Text(store.tick.roundsText)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap the dial for +1 round")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, 20)
        } else if let nextUp = store.tick.nextUpLine {
            Text(nextUp)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 20)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            controlButton(
                systemImage: "flag.checkered",
                label: "Finish",
                color: Theme.accent
            ) {
                store.interactor.finishEarly()
            }

            controlButton(
                systemImage: store.tick.state == .paused ? "play.fill" : "pause.fill",
                label: store.tick.state == .paused ? "Resume" : "Pause",
                color: Theme.textPrimary,
                prominent: true
            ) {
                store.interactor.togglePause()
            }

            if store.tick.showsDoneSegment || store.tick.showsSkip {
                controlButton(
                    systemImage: "forward.end.fill",
                    label: store.tick.showsDoneSegment ? "Done" : "Skip",
                    color: Theme.textSecondary
                ) {
                    store.interactor.advanceSegment()
                }
            } else {
                controlButton(systemImage: "forward.end.fill", label: "Skip", color: Theme.textSecondary.opacity(0.3)) {}
                    .disabled(true)
            }
        }
    }

    private func controlButton(
        systemImage: String,
        label: String,
        color: Color,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
            }
            .foregroundStyle(prominent ? Color.black : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                prominent ? Theme.textPrimary : Theme.card,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.cardBorder)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full note sheet

private struct NoteSheet: View {
    let title: String
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    Text(text)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}

// MARK: - Summary

private struct SummaryView: View {
    let summary: WorkoutSceneModels.Summary.ViewModel
    let interactor: WorkoutBusinessLogic
    let onDone: () -> Void

    @State private var name: String
    @State private var note: String
    @State private var isRx: Bool?
    @State private var feeling: Int?

    private static let feelings = ["🤕", "😮‍💨", "😐", "💪", "🔥"]

    init(summary: WorkoutSceneModels.Summary.ViewModel, interactor: WorkoutBusinessLogic, onDone: @escaping () -> Void) {
        self.summary = summary
        self.interactor = interactor
        self.onDone = onDone
        _name = State(initialValue: summary.name)
        _note = State(initialValue: summary.note)
        _isRx = State(initialValue: summary.isRx)
        _feeling = State(initialValue: summary.feeling)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let prLine = summary.prLine {
                    prBanner(prLine)
                }
                scoreCard
                if !summary.roundDurations.isEmpty {
                    splitsCard
                }
                detailsCard
                BigButton(title: "DONE", systemImage: "checkmark") {
                    saveEdits()
                    onDone()
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: summary.isPR ? "bell.fill" : "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(summary.isPR ? Theme.prepare : Theme.work)
            Text(summary.isPR ? "NEW PR — RING THE BELL" : "WORKOUT DONE")
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(Theme.textPrimary)
                .tracking(2)
        }
        .padding(.top, 8)
    }

    private func prBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: summary.isPR ? "trophy.fill" : "chart.line.uptrend.xyaxis")
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
        }
        .foregroundStyle(summary.isPR ? Color.black : Theme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            summary.isPR ? Theme.prepare : Theme.card,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var scoreCard: some View {
        Card {
            VStack(spacing: 14) {
                HStack {
                    Text("Time")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(summary.totalText)
                        .font(.system(.title2, design: .rounded).weight(.black))
                        .foregroundStyle(Theme.accent)
                }
                if let rounds = summary.roundsText {
                    Divider().overlay(Theme.cardBorder)
                    HStack {
                        Text("Score")
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(rounds)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.work)
                    }
                }
                Divider().overlay(Theme.cardBorder)
                Text(summary.detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var splitsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("ROUND SPLITS")
                    .font(.sectionLabel)
                    .foregroundStyle(Theme.textSecondary)
                Chart {
                    ForEach(Array(summary.roundDurations.enumerated()), id: \.offset) { index, seconds in
                        BarMark(
                            x: .value("Round", index + 1),
                            y: .value("Seconds", seconds)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(4)
                    }
                    if summary.roundDurations.count > 1 {
                        RuleMark(y: .value("Average", summary.roundDurations.reduce(0, +) / Double(summary.roundDurations.count)))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(summary.roundDurations.count, 10))) { _ in
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Theme.cardBorder)
                        AxisValueLabel {
                            if let seconds = value.as(Double.self) {
                                Text(TimeFormat.clock(seconds))
                            }
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 140)
            }
        }
    }

    private var detailsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME · used for PR tracking")
                        .font(.sectionLabel)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Fran, Murph, «Monday hell»…", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Divider().overlay(Theme.cardBorder)
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORKOUT")
                        .font(.sectionLabel)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("21-15-9 thrusters / pull-ups…", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...5)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Divider().overlay(Theme.cardBorder)
                HStack(spacing: 10) {
                    rxButton("RX", value: true)
                    rxButton("SCALED", value: false)
                    Spacer()
                    ForEach(Array(Self.feelings.enumerated()), id: \.offset) { index, emoji in
                        Button {
                            feeling = feeling == index + 1 ? nil : index + 1
                            saveEdits()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .opacity(feeling == index + 1 ? 1 : (feeling == nil ? 0.7 : 0.3))
                                .scaleEffect(feeling == index + 1 ? 1.25 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onChange(of: name) { saveEdits() }
        .onChange(of: note) { saveEdits() }
    }

    private func rxButton(_ title: String, value: Bool) -> some View {
        Button {
            isRx = isRx == value ? nil : value
            saveEdits()
        } label: {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundStyle(isRx == value ? Color.black : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isRx == value ? Theme.work : Theme.background,
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(Theme.cardBorder))
        }
        .buttonStyle(.plain)
    }

    private func saveEdits() {
        interactor.updateSummary(WorkoutSceneModels.SummaryEdit(
            name: name,
            note: note,
            isRx: isRx,
            feeling: feeling
        ))
    }
}
