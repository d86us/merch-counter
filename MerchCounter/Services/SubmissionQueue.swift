import Foundation

extension Notification.Name {
    static let pendingCountChanged = Notification.Name("pendingCountChanged")
}

actor SubmissionQueue {
    static let shared = SubmissionQueue()

    private var records: [SurveyRecord] = []
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("submission_queue.json")
        if let data = try? Data(contentsOf: fileURL) {
            records = (try? JSONDecoder().decode([SurveyRecord].self, from: data)) ?? []
        }
    }

    var count: Int { records.count }

    func add(_ record: SurveyRecord) {
        records.append(record)
        save()
        notify()
        flushInBackground()
    }

    func flushInBackground() {
        Task { await flush() }
    }

    private func flush() async {
        guard !records.isEmpty else { return }
        let service = try? await MainActor.run { try GoogleSheetsService() }
        guard let service else { return }

        var remaining: [SurveyRecord] = []
        for record in records {
            do {
                try await service.appendRecord(record)
            } catch {
                remaining.append(record)
            }
        }
        records = remaining
        save()
        notify()
    }

    private func save() {
        let data = try? JSONEncoder().encode(records)
        try? data?.write(to: fileURL, options: .atomic)
    }

    private func notify() {
        let count = records.count
        Task { @MainActor in
            NotificationCenter.default.post(name: .pendingCountChanged, object: count)
        }
    }
}
