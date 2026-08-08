import SwiftUI
import Charts

@MainActor
final class HistoryViewStore: ObservableObject {
    @Published var viewModel = HistoryModels.Load.ViewModel(
        rows: [],
        stats: .init(streakText: "0", thisWeekText: "0", thisMonthText: "0", totalText: "0", totalTimeText: "0m"),
        heatWeeks: []
    )
    @Published var detail: HistoryModels.Detail.ViewModel?

    var interactor: HistoryBusinessLogic!

    func displayLoad(_ viewModel: HistoryModels.Load.ViewModel) {
        self.viewModel = viewModel
    }

    func displayDetail(_ viewModel: HistoryModels.Detail.ViewModel) {
        detail = viewModel
    }
}

enum HistorySceneFactory {
    @MainActor
    static func make() -> HistoryViewStore {
        let store = HistoryViewStore()
        let presenter = HistoryPresenter()
        presenter.display = store
        store.interactor = HistoryInteractor(presenter: presenter)
        return store
    }
}

struct HistoryView: View {
    @StateObject private var store: HistoryViewStore

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: HistorySceneFactory.make())
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if store.viewModel.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !store.viewModel.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let csv = store.viewModel.csvURL {
                            ShareLink(item: csv) {
                                Label("Export CSV", systemImage: "tablecells")
                            }
                        }
                        if let json = store.viewModel.jsonURL {
                            ShareLink(item: json) {
                                Label("Export JSON", systemImage: "curlybraces")
                            }
                        }
                        Button(role: .destructive) {
                            store.interactor.clearAll()
                        } label: {
                            Label("Clear journal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $store.detail) { detail in
            HistoryDetailView(detail: detail)
        }
        .onAppear { store.interactor.load() }
    }

    private var content: some View {
        List {
            Section {
                statsHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            }
            Section {
                ForEach(store.viewModel.rows) { row in
                    Button {
                        store.interactor.showDetail(id: row.id)
                    } label: {
                        rowView(row)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.card)
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.viewModel.rows[$0].id }
                    store.interactor.delete(ids: ids)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                statTile(value: store.viewModel.stats.streakText, label: String(localized: "day streak"), icon: "flame.fill", color: Theme.accent)
                statTile(value: store.viewModel.stats.thisWeekText, label: String(localized: "this week"), icon: "calendar", color: Theme.work)
                statTile(value: store.viewModel.stats.thisMonthText, label: String(localized: "this month"), icon: "calendar", color: Theme.rest)
            }
            HStack(spacing: 10) {
                statTile(value: store.viewModel.stats.totalText, label: String(localized: "workouts"), icon: "checkmark.seal.fill", color: Theme.textSecondary)
                statTile(value: store.viewModel.stats.totalTimeText, label: String(localized: "under the clock"), icon: "clock.fill", color: Theme.prepare)
            }
            heatmap
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.black))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.cardBorder)
        )
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST 12 WEEKS")
                .font(.sectionLabel)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 4) {
                ForEach(Array(store.viewModel.heatWeeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 4) {
                        ForEach(week) { day in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(heatColor(day))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(day.isToday ? Theme.accent : .clear, lineWidth: 1.5)
                                )
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.cardBorder)
        )
    }

    private func heatColor(_ day: JournalStats.HeatDay) -> Color {
        if day.isFuture { return .clear }
        switch day.count {
        case 0: return Theme.background
        case 1: return Theme.work.opacity(0.45)
        case 2: return Theme.work.opacity(0.75)
        default: return Theme.work
        }
    }

    private func rowView(_ row: HistoryModels.Load.ViewModel.Row) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(row.title)
                    .font(.system(.body, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                if let rx = row.rxText {
                    Text(rx)
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundStyle(rx == "RX" ? Color.black : Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rx == "RX" ? Theme.work : Theme.background, in: Capsule())
                }
                if let emoji = row.feelingEmoji {
                    Text(emoji).font(.caption)
                }
                Spacer()
                Text(row.timeText)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Text(row.note ?? row.detail)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
            HStack {
                Text(row.dateText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let score = row.scoreText {
                    Text(score)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.work)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary)
            Text("No workouts yet")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Finish a WOD and it lands here")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Detail sheet

private struct HistoryDetailView: View {
    let detail: HistoryModels.Detail.ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        scoreCard
                        if !detail.attempts.isEmpty {
                            progressionCard
                        }
                        if !detail.roundDurations.isEmpty {
                            splitsCard
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(detail.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var scoreCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(detail.dateText)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if let rx = detail.rxText {
                        Text(rx)
                            .font(.system(.caption2, design: .rounded).weight(.black))
                            .foregroundStyle(rx == "RX" ? Color.black : Theme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(rx == "RX" ? Theme.work : Theme.background, in: Capsule())
                    }
                    if let emoji = detail.feelingEmoji {
                        Text(emoji)
                    }
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TIME").font(.sectionLabel).foregroundStyle(Theme.textSecondary)
                        Text(detail.timeText)
                            .font(.system(.title2, design: .rounded).weight(.black))
                            .foregroundStyle(Theme.accent)
                    }
                    if let score = detail.scoreText {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SCORE").font(.sectionLabel).foregroundStyle(Theme.textSecondary)
                            Text(score)
                                .font(.system(.title2, design: .rounded).weight(.black))
                                .foregroundStyle(Theme.work)
                        }
                    }
                    Spacer()
                }
                if let note = detail.note {
                    Divider().overlay(Theme.cardBorder)
                    Text(note)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Divider().overlay(Theme.cardBorder)
                Text(detail.detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var progressionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("PROGRESSION · \(detail.attempts.count) attempts")
                    .font(.sectionLabel)
                    .foregroundStyle(Theme.textSecondary)
                Chart {
                    ForEach(detail.attempts) { attempt in
                        LineMark(
                            x: .value("Date", attempt.date),
                            y: .value("Score", attempt.value)
                        )
                        .foregroundStyle(Theme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        PointMark(
                            x: .value("Date", attempt.date),
                            y: .value("Score", attempt.value)
                        )
                        .foregroundStyle(attempt.isBest ? Theme.prepare : (attempt.isCurrent ? Theme.textPrimary : Theme.accent))
                        .symbolSize(attempt.isBest ? 120 : 60)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Theme.cardBorder)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(detail.progressionCaption?.hasPrefix("Time") == true ? TimeFormat.clock(v) : "\(Int(v))")
                            }
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 150)
                if let caption = detail.progressionCaption {
                    Text(caption + " · ★ best")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
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
                    ForEach(Array(detail.roundDurations.enumerated()), id: \.offset) { index, seconds in
                        BarMark(
                            x: .value("Round", index + 1),
                            y: .value("Seconds", seconds)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(4)
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
                .frame(height: 130)
            }
        }
    }
}
