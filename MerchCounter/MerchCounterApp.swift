import SwiftUI

@main
struct MerchCounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await SubmissionQueue.shared.flushInBackground()
                }
                .task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    let service = try? GoogleSheetsService()
                    await service?.migrateIfNeeded()
                }
            }
    }
}
