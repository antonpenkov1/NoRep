import Foundation

/// Renders the journal as CSV / JSON files in the temp directory for sharing.
enum ExportService {

    static func writeCSV(_ results: [WorkoutResult]) -> URL? {
        var lines = ["date,title,type,total_seconds,rounds,rx,feeling,note,splits"]
        let iso = ISO8601DateFormatter()
        for r in results {
            let fields = [
                iso.string(from: r.date),
                csvEscape(r.title),
                r.typeID ?? "",
                String(r.totalSeconds),
                r.rounds.map(String.init) ?? "",
                r.isRx.map { $0 ? "rx" : "scaled" } ?? "",
                r.feeling.map(String.init) ?? "",
                csvEscape(r.note ?? ""),
                csvEscape((r.splits ?? []).map { String($0) }.joined(separator: "|"))
            ]
            lines.append(fields.joined(separator: ","))
        }
        return write(lines.joined(separator: "\n"), name: "norep-journal.csv")
    }

    static func writeJSON(_ results: [WorkoutResult]) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(results),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return write(text, name: "norep-journal.json")
    }

    private static func write(_ text: String, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(where: { ",\"\n".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
