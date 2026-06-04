import SwiftUI

struct ContentView: View {
    @State private var formState = FormState()
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                SurveyFormView()
                    .environment(formState)
            }
            .tabItem {
                Text("Survey 1")
            }
            .tag(0)

            SessionObservationView()
                .tabItem {
                Text("Survey 2")
            }
            .tag(1)
        }
        .tint(Color.appAccent)
        .onAppear {
            let font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
            UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .normal)
        }
    }
}
