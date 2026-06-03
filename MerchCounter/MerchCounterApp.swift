import SwiftUI

@main
struct MerchCounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await SubmissionQueue.shared.syncCumulativeFromSheet()
                    await SubmissionQueue.shared.flushInBackground()
                }
        }
    }
}
