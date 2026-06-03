import SwiftUI

let serviceAccountFileName = "GoogleServiceAccount"

extension Color {
    static let appAccent = Color(red: 1, green: 0.8, blue: 0)
}

extension View {
    func appFont(_ weight: Font.Weight = .regular) -> some View {
        self.font(.subheadline.weight(weight))
    }
}

extension Text {
    func appFont(_ weight: Font.Weight = .regular) -> Text {
        self.font(.subheadline.weight(weight))
    }
}
