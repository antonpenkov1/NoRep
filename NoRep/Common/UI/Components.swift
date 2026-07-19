import SwiftUI

// MARK: - Duration picker (minutes : seconds wheels)

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    var maxMinutes: Int = 90
    var secondStep: Int = 5

    private var minutes: Binding<Int> {
        Binding(
            get: { Int(duration) / 60 },
            set: { duration = TimeInterval($0 * 60 + Int(duration) % 60) }
        )
    }

    private var seconds: Binding<Int> {
        Binding(
            get: { Int(duration) % 60 },
            set: { duration = TimeInterval((Int(duration) / 60) * 60 + $0) }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: minutes) {
                ForEach(0...maxMinutes, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()

            Picker("Seconds", selection: seconds) {
                ForEach(Array(stride(from: 0, through: 55, by: secondStep)), id: \.self) { s in
                    Text("\(s) sec").tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 120)
    }
}

// MARK: - Stepper row

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text("\(value)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 44)
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    /// 0...1, nil hides the progress stroke (open-ended segments).
    var progress: Double?
    var color: Color
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            if let progress {
                Circle()
                    .trim(from: 0, to: max(0.001, min(1, progress)))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
    }
}

// MARK: - Big action button

struct BigButton: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = Theme.accent
    var textColor: Color = .black
    var borderColor: Color? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor ?? .clear, lineWidth: 1.5)
            )
            .foregroundStyle(textColor)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card container

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.cardBorder)
            )
    }
}
