import SwiftUI

struct ContentView: View {
    @State private var formState = FormState()

    var body: some View {
        NavigationStack {
            SurveyFormView()
                .environment(formState)
        }
    }
}
