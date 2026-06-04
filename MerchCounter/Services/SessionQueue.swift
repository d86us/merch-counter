import Foundation

actor SessionQueue {
    static let shared = SessionQueue()

    private var records: [SessionRecord] = []
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("session_queue.json")
        if let data = try? Data(contentsOf: fileURL) {
            records = (try? JSONDecoder().decode([SessionRecord].self, from: data)) ?? []
        }
    }

    var count: Int { records.count }

    func add(_ record: SessionRecord) {
        records.append(record)
        save()
        flushInBackground()
    }

    func flushInBackground() {
        Task { await flush() }
    }

    private func flush() async {
        guard !records.isEmpty else { return }
        let service = try? await MainActor.run { try GoogleSheetsService() }
        guard let service else { return }

        var remaining: [SessionRecord] = []
        for record in records {
            do {
                try await service.appendSessionRecord(record)
            } catch {
                remaining.append(record)
            }
        }
        records = remaining
        save()
    }

    private func save() {
        let data = try? JSONEncoder().encode(records)
        try? data?.write(to: fileURL, options: .atomic)
    }
}
