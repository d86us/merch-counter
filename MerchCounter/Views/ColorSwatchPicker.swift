import SwiftUI

struct ColorSwatchPicker: View {
    let title: String
    @Binding var selected: Set<String>
    @Binding var showCustom: Bool
    @Binding var customInput: String
    let onAdd: () -> Void
    var columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 7)
    @State private var colorInput = ""
    @State private var showColorAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ColorOption.all) { option in
                    swatch(option)
                }
                addCustomButton
            }

            if !selected.isEmpty {
                customTags
            }
        }
    }

    var customColors: Set<String> {
        let predefined = Set(ColorOption.all.map(\.name))
        return selected.subtracting(predefined)
    }

    @ViewBuilder
    var customTags: some View {
        let tags = Array(customColors).sorted()
        if !tags.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { name in
                    HStack(spacing: 4) {
                        Text(name)
                            .appFont()
                        Button {
                            selected.remove(name)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .appFont()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
        }
    }

    var addCustomButton: some View {
        Button {
            showColorAlert = true
        } label: {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "plus")
                        .appFont(.medium)
                        .foregroundColor(.white)
                )
        }
        .alert("Add \(title)", isPresented: $showColorAlert) {
            TextField("Color name", text: $colorInput)
            Button("Cancel", role: .cancel) {
                colorInput = ""
            }
            Button("Add") {
                customInput = colorInput
                onAdd()
                colorInput = ""
            }
        }
    }

    func swatch(_ option: ColorOption) -> some View {
        let isSelected = selected.contains(option.name)
        return Button {
            if isSelected {
                selected.remove(option.name)
            } else {
                selected.insert(option.name)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.appAccent : Color(.systemGray4), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .appFont(.bold)
                        .foregroundColor(option.color.isLight ? .black : .white)
                }
            }
        }
    }
}

extension Color {
    var isLight: Bool {
        guard let components = cgColor?.components else { return false }
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 0.6
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
            height = y + maxHeight
        }

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}
