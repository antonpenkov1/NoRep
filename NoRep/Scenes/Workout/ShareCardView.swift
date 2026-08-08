import SwiftUI

/// The dark result card rendered to an image for the share sheet / stories.
struct ShareCardView: View {
    let summary: WorkoutSceneModels.Summary.ViewModel
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            logo
                .padding(.bottom, 22)

            if summary.isPR {
                Text("NEW PR")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .tracking(2)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.prepare, in: Capsule())
                    .padding(.bottom, 10)
            }

            Text(summary.name)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Text(dateText)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 20)

            HStack(alignment: .firstTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TIME")
                        .font(.sectionLabel)
                        .foregroundStyle(Theme.textSecondary)
                    Text(summary.totalText)
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                }
                if let rounds = summary.roundsText {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SCORE")
                            .font(.sectionLabel)
                            .foregroundStyle(Theme.textSecondary)
                        Text(rounds)
                            .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.work)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .padding(.bottom, 18)

            if !summary.note.isEmpty {
                Text(summary.note)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .lineLimit(5)
                    .padding(.bottom, 18)
            }

            if summary.roundDurations.count > 1 {
                splitsBars
                    .padding(.bottom, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 420, height: 540, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.10, blue: 0.13), Color(red: 0.045, green: 0.045, blue: 0.065)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var logo: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0.1, to: 0.85)
                    .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-95))
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 30, height: 4.5)
                    .clipShape(Capsule())
                    .rotationEffect(.degrees(45))
            }
            Text("NoRep")
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text("WOD TIMER")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var splitsBars: some View {
        let maxDuration = summary.roundDurations.max() ?? 1
        return VStack(alignment: .leading, spacing: 6) {
            Text("ROUND SPLITS")
                .font(.sectionLabel)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(summary.roundDurations.enumerated()), id: \.offset) { _, duration in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.accent.opacity(0.85))
                        .frame(height: max(8, 56 * duration / maxDuration))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56, alignment: .bottom)
        }
    }
}
