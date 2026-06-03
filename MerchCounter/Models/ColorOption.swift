import SwiftUI

struct ColorOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color

    var brightness: CGFloat {
        guard let cg = color.cgColor, let components = cg.components else { return 0 }
        let count = cg.numberOfComponents
        let r = count >= 3 ? components[0] : components[0]
        let g = count >= 3 ? components[1] : components[0]
        let b = count >= 3 ? components[2] : components[0]
        return (r * 299 + g * 587 + b * 114) / 1000
    }

    static let all: [ColorOption] = [
        ColorOption(name: "White", color: .white),
        ColorOption(name: "Light Gray", color: Color(red: 0.83, green: 0.83, blue: 0.83)),
        ColorOption(name: "Gray", color: Color(red: 0.5, green: 0.5, blue: 0.5)),
        ColorOption(name: "Dark Gray", color: Color(red: 0.33, green: 0.33, blue: 0.33)),
        ColorOption(name: "Black", color: .black),
        ColorOption(name: "Yellow", color: .yellow),
        ColorOption(name: "Baby Pink", color: Color(red: 1.0, green: 0.71, blue: 0.76)),
        ColorOption(name: "Pink", color: .pink),
        ColorOption(name: "Orange", color: .orange),
        ColorOption(name: "Red", color: .red),
        ColorOption(name: "Green", color: .green),
        ColorOption(name: "Blue", color: .blue),
        ColorOption(name: "Brown", color: .brown),
        ColorOption(name: "Purple", color: .purple),
        ColorOption(name: "Olive", color: Color(red: 0.5, green: 0.5, blue: 0)),
        ColorOption(name: "Burgundy", color: Color(red: 0.5, green: 0, blue: 0.13)),
        ColorOption(name: "Dark Green", color: Color(red: 0.0, green: 0.39, blue: 0.0)),
        ColorOption(name: "Navy", color: Color(red: 0, green: 0, blue: 0.5)),
        ColorOption(name: "Dark Brown", color: Color(red: 0.4, green: 0.2, blue: 0.04)),
    ]
}
