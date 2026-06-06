import Foundation

actor SimpleSessionQueue {
    static let shared = SimpleSessionQueue()

    private var records: [SimpleSessionRecord] = []
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("simple_session_queue.json")
        if let data = try? Data(contentsOf: fileURL) {
            records = (try? JSONDecoder().decode([SimpleSessionRecord].self, from: data)) ?? []
        }
    }

    var count: Int { records.count }

    func add(_ record: SimpleSessionRecord) {
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

        var remaining: [SimpleSessionRecord] = []
        for record in records {
            do {
                try await service.appendSimpleSessionRecord(record)
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
