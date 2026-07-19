import SwiftUI

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

    init(plan: WorkoutPlan, router: AppRouter) {
        _store = StateObject(wrappedValue: WorkoutSceneFactory.make(plan: plan, router: router))
    }

    var body: some View {
        ZStack {
            background

            if let summary = store.summary {
                SummaryView(summary: summary) {
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

// MARK: - Summary

private struct SummaryView: View {
    let summary: WorkoutSceneModels.Summary.ViewModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.work)
            Text("WORKOUT DONE")
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(Theme.textPrimary)
                .tracking(2)
            Card {
                VStack(spacing: 14) {
                    summaryRow(title: "Workout", value: summary.title)
                    Divider().overlay(Theme.cardBorder)
                    summaryRow(title: "Time", value: summary.totalText)
                    if let rounds = summary.roundsText {
                        Divider().overlay(Theme.cardBorder)
                        summaryRow(title: "Score", value: rounds)
                    }
                    Divider().overlay(Theme.cardBorder)
                    Text(summary.detail)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
            BigButton(title: "DONE", systemImage: "checkmark") {
                onDone()
            }
        }
        .padding(20)
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
