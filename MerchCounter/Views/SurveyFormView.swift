import SwiftUI

struct SurveyFormView: View {
    @Environment(FormState.self) private var s
    @State private var showToast = false
    @State private var scrollToTop = false
    @State private var merchTypeInput = ""
    @State private var showMerchTypeAlert = false
    @State private var designFeatureInput = ""
    @State private var showDesignFeatureAlert = false
    @State private var commentInput = ""
    @State private var showCommentAlert = false
    @State private var weatherText = "Loading…"
    @State private var pendingCount = 0

    var body: some View {
        @Bindable var model = s

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    genderSection
                    ageSection
                    raceSection
                    merchTypeSection($model)
                    garmentSection(title: "Garment",
                                  colors: $model.garmentColors,
                                  showCustom: $model.showCustomGarmentColor,
                                  customInput: $model.customGarmentColorInput,
                                  onAdd: { model.addCustomGarmentColor() })
                    garmentSection(title: "Print",
                                   colors: $model.printColors,
                                   showCustom: $model.showCustomPrintColor,
                                   customInput: $model.customPrintColorInput,
                                   onAdd: { model.addCustomPrintColor() })
                    designFeatureSection($model)
                    commentSection
                }
                .padding()
                .id("top")
            }
            .task {
                let (condition, temp) = await WeatherService.shared.currentWeather()
                s.weather = condition
                s.temperature = temp
                updateStatsText()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pendingCountChanged)) { note in
                pendingCount = note.object as? Int ?? 0
            }
            .onAppear {
                Task { pendingCount = await SubmissionQueue.shared.count }
                updateStatsText()
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text("Saved!")
                        .appFont(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appAccent)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 30)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showToast)
            .onChange(of: scrollToTop) { _, _ in
                withAnimation { proxy.scrollTo("top", anchor: .top) }
            }
            .navigationTitle(weatherText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { s.reset() }
                        .foregroundColor(Color.appAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        if pendingCount > 0 {
                            Text("\(pendingCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        submitButton
                    }
                }
            }
        }
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Gender")
            segmentedButtonRow(options: ["Male", "Female"], selection: Binding(
                get: { s.gender },
                set: { s.gender = $0 }
            ))
        }
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Age")
            segmentedButtonRow(options: ["Child", "Teen", "20", "30", "40", "50", "60+"], selection: Binding(
                get: { s.ageGroup },
                set: { s.ageGroup = $0 }
            ))
        }
    }

    private var raceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Demographic")
            segmentedButtonRow(options: ["White", "Arab", "Latino", "Indian", "Asian", "Black"], selection: Binding(
                get: { s.race },
                set: { s.race = $0 }
            ))
        }
    }

    private func segmentedButtonRow(options: [String], selection: Binding<String?>) -> some View {
        SegmentedControl(options: options, selection: selection)
            .frame(height: 36)
    }
    private func merchTypeSection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Merch")
            let allOptions = FormState.merchTypeOptions + model.wrappedValue.customMerchTypes
            RadioGroup(options: allOptions, selection: model.merchType, trailingButton: {
                AnyView(Button {
                    showMerchTypeAlert = true
                } label: {
                    Text("+")
                        .appFont(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                })
            })
            .alert("Add Merch Type", isPresented: $showMerchTypeAlert) {
                TextField("Merch type name", text: $merchTypeInput)
                Button("Cancel", role: .cancel) {
                    merchTypeInput = ""
                }
                Button("Add") {
                    model.wrappedValue.customMerchInput = merchTypeInput
                    model.wrappedValue.addCustomMerch()
                    merchTypeInput = ""
                }
            }
        }
    }

    private func garmentSection(title: String, colors: Binding<Set<String>>, showCustom: Binding<Bool>, customInput: Binding<String>, onAdd: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title)
            ColorSwatchPicker(
                title: title,
                selected: colors,
                showCustom: showCustom,
                customInput: customInput,
                onAdd: onAdd
            )
        }
    }

    private func designFeatureSection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Design")
            let allOptions = FormState.designFeatureOptions + model.wrappedValue.customDesignFeatures
            MultiSelectGrid(options: allOptions, selected: model.designFeatures, trailingButton: {
                AnyView(Button {
                    showDesignFeatureAlert = true
                } label: {
                    Text("+")
                        .appFont()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                })
            })
            .alert("Add Design Feature", isPresented: $showDesignFeatureAlert) {
                TextField("Design feature", text: $designFeatureInput)
                Button("Cancel", role: .cancel) {
                    designFeatureInput = ""
                }
                Button("Add") {
                    model.wrappedValue.customDesignFeatureInput = designFeatureInput
                    model.wrappedValue.addCustomDesignFeature()
                    designFeatureInput = ""
                }
            }
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Comment")
            if !s.comments.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(s.comments, id: \.self) { comment in
                        HStack(spacing: 4) {
                            Text(comment)
                                .appFont()
                            Button {
                                s.comments.removeAll { $0 == comment }
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
            Button {
                showCommentAlert = true
            } label: {
                Text("+")
                    .appFont()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
            }
            .alert("Add Comment", isPresented: $showCommentAlert) {
                TextField("Comment", text: $commentInput)
                Button("Cancel", role: .cancel) {
                    commentInput = ""
                }
                Button("Add") {
                    let trimmed = commentInput.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        s.comments.append(trimmed)
                    }
                    commentInput = ""
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            if s.isSubmitting {
                ProgressView()
            } else {
                Text("Submit")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appAccent)
            }
        }
        .disabled(!s.isReady || s.isSubmitting)
    }

    private func submit() async {
        s.isSubmitting = true

        let (condition, temp) = await WeatherService.shared.currentWeather()
        s.weather = condition
        s.temperature = temp
        let record = s.toRecord()

        await SubmissionQueue.shared.add(record)
        incrementStats()
        updateStatsText()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        showToast = true
        s.reset()
        scrollToTop.toggle()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        showToast = false
        s.isSubmitting = false
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .appFont(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }

    private func updateStatsText() {
        let defaults = UserDefaults.standard
        let total = defaults.integer(forKey: "totalSubmissions")
        let today = defaults.integer(forKey: "todaySubmissions")
        weatherText = "Total \(total) Today \(today)"
    }

    private func incrementStats() {
        let defaults = UserDefaults.standard
        let total = defaults.integer(forKey: "totalSubmissions") + 1
        defaults.set(total, forKey: "totalSubmissions")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let lastDate = defaults.string(forKey: "lastSubmitDate")

        if lastDate == today {
            let count = defaults.integer(forKey: "todaySubmissions") + 1
            defaults.set(count, forKey: "todaySubmissions")
        } else {
            defaults.set(1, forKey: "todaySubmissions")
            defaults.set(today, forKey: "lastSubmitDate")
        }
    }
}

// MARK: - Custom Segmented Control

struct SegmentedControl: View {
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))

                if selection != nil {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appAccent)
                        .frame(width: segmentWidth(geo))
                        .offset(x: highlightOffset(geo))
                        .animation(.interactiveSpring, value: selection)
                }

                HStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Text(option)
                            .appFont(.medium)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(selection == option ? .black : .primary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UISelectionFeedbackGenerator().selectionChanged()
                                selection = option
                            }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func segmentWidth(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width / CGFloat(max(options.count, 1))
    }

    private func highlightOffset(_ geo: GeometryProxy) -> CGFloat {
        guard let sel = selection, let index = options.firstIndex(of: sel) else { return 0 }
        return CGFloat(index) * segmentWidth(geo)
    }
}

struct RadioGroup: View {
    let options: [String]
    @Binding var selection: String?
    var columns: Int = 3
    var trailingButton: (() -> AnyView)?

    var gridItems: [GridItem] {
        Array(repeating: .init(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection = option
                } label: {
                    Text(option)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selection == option ? Color.appAccent : Color(.systemGray6))
                        .foregroundColor(selection == option ? .black : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            if let button = trailingButton {
                button()
            }
        }
    }
}

struct MultiSelectGrid: View {
    let options: [String]
    @Binding var selected: Set<String>
    var trailingButton: (() -> AnyView)?

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selected.contains(option)
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    if isSelected {
                        selected.remove(option)
                    } else {
                        selected.insert(option)
                    }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.appAccent : Color(.systemGray6))
                        .foregroundColor(isSelected ? .black : .primary)
                        .clipShape(Capsule())
                }
            }
            if let button = trailingButton {
                button()
            }
        }
    }
}
