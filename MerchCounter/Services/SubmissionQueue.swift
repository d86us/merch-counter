import Foundation

extension Notification.Name {
    static let pendingCountChanged = Notification.Name("pendingCountChanged")
}

actor SubmissionQueue {
    static let shared = SubmissionQueue()

    private var records: [SurveyRecord] = []
    private let fileURL: URL
    private let defaults = UserDefaults.standard

    private let totalKey = "cumulative_total"
    private let todayKey = "cumulative_today"
    private let todayDateKey = "cumulative_today_date"

    private static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("submission_queue.json")
        if let data = try? Data(contentsOf: fileURL) {
            records = (try? JSONDecoder().decode([SurveyRecord].self, from: data)) ?? []
        }
    }

    var count: Int { records.count }

    var todayCount: Int {
        records.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    var cumulativeTotal: Int { defaults.integer(forKey: totalKey) }

    var cumulativeToday: Int {
        let saved = defaults.string(forKey: todayDateKey) ?? ""
        guard saved == Self.dateFormatter.string(from: Date()) else { return 0 }
        return defaults.integer(forKey: todayKey)
    }

    func add(_ record: SurveyRecord) {
        records.append(record)
        save()
        defaults.set(defaults.integer(forKey: totalKey) + 1, forKey: totalKey)
        let today = Self.dateFormatter.string(from: Date())
        let saved = defaults.string(forKey: todayDateKey) ?? ""
        if saved == today {
            defaults.set(defaults.integer(forKey: todayKey) + 1, forKey: todayKey)
        } else {
            defaults.set(today, forKey: todayDateKey)
            defaults.set(1, forKey: todayKey)
        }
        notify()
        flushInBackground()
    }

    func syncCumulativeFromSheet() async {
        let service = try? await MainActor.run { try GoogleSheetsService() }
        guard let counts = try? await service?.fetchRowCounts() else { return }
        let today = Self.dateFormatter.string(from: Date())
        let pending = records.count
        let todayPending = records.filter { Calendar.current.isDateInToday($0.timestamp) }.count
        defaults.set(counts.total + pending, forKey: totalKey)
        defaults.set(today, forKey: todayDateKey)
        defaults.set(counts.today + todayPending, forKey: todayKey)
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
