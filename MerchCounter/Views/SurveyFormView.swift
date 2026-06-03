import SwiftUI

struct SurveyFormView: View {
    @Environment(FormState.self) private var s
    @State private var showToast = false
    @State private var scrollToTop = false
    @State private var merchTypeInput = ""
    @State private var showMerchTypeAlert = false
    @State private var imageInput = ""
    @State private var showImageAlert = false
    @State private var typographyInput = ""
    @State private var showTypographyAlert = false
    @State private var commentInput = ""
    @State private var showCommentAlert = false
    @State private var totalCount = 0
    @State private var todayCount = 0
    @State private var pendingCount = 0

    var body: some View {
        @Bindable var model = s

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    genderSection
                    ageSection
                    raceSection
                    groupSection
                    modeSection
                    if s.mode == "Wearing" {
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
                        imageSection($model)
                        typographySection($model)
                    } else {
                        bagSizeSection($model)
                    }
                    commentSection
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .padding(.bottom, 50)
                .id("top")
            }
            .task {
                await SubmissionQueue.shared.syncCumulativeFromSheet()
                let (condition, temp) = await WeatherService.shared.currentWeather()
                s.weather = condition
                s.temperature = temp
                await updateStatsText()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pendingCountChanged)) { note in
                pendingCount = note.object as? Int ?? 0
                Task { await updateStatsText() }
            }
            .onAppear {
                Task { pendingCount = await SubmissionQueue.shared.count }
                Task { await updateStatsText() }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Text("\(totalCount)")
                        Text("/")
                        Text("\(todayCount)")
                            .foregroundColor(Color.appAccent)
                    }
                    .appFont(.semibold)
                }
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
            SegmentedControl(options: ["Male", "Female"], selection: Binding(
                get: { s.gender },
                set: { s.gender = $0 }
            ), icons: ["Male": "figure.stand", "Female": "figure.stand.dress"])
            .frame(height: 36)
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
            segmentedButtonRow(options: ["White", "Latino", "Asian", "Indian", "Black", "Arab"], selection: Binding(
                get: { s.race },
                set: { s.race = $0 }
            ))
        }
    }

    private func segmentedButtonRow(options: [String], selection: Binding<String?>) -> some View {
        SegmentedControl(options: options, selection: selection)
            .frame(height: 36)
    }

    private func segmentedButtonRow(options: [String], stringSelection: Binding<String>) -> some View {
        SegmentedControl(options: options, selection: Binding(
            get: { stringSelection.wrappedValue },
            set: { if let v = $0 { stringSelection.wrappedValue = v } }
        ))
        .frame(height: 36)
    }

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Group")
            segmentedButtonRow(options: FormState.groupOptions, stringSelection: Binding(
                get: { s.group },
                set: {
                    s.group = $0
                    if $0 == "Single" {
                        s.groupCount = nil
                        s.matchingDesigns = nil
                    }
                }
            ))
            if s.isGroup {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Count")
                    segmentedButtonRow(options: FormState.groupCountOptions, stringSelection: Binding(
                        get: { s.groupCount ?? "2" },
                        set: { s.groupCount = $0 }
                    ))
                }
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Matching Designs")
                    segmentedButtonRow(options: ["Yes", "No"], stringSelection: Binding(
                        get: { s.matchingDesigns ?? "Yes" },
                        set: { s.matchingDesigns = $0 }
                    ))
                }
            }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Mode")
            SegmentedControl(options: FormState.modeOptions, selection: Binding(
                get: { Optional(s.mode) },
                set: { if let v = $0 { s.mode = v } }
            ), icons: ["Wearing": "tshirt", "Carrying Bag": "bag"])
            .frame(height: 36)
        }
    }

    private func bagSizeSection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Bag Size")
            FlowLayout(spacing: 8) {
                ForEach(FormState.bagSizeOptions, id: \.self) { option in
                    let isSelected = model.wrappedValue.bagSizes.contains(option)
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        if isSelected {
                            model.wrappedValue.bagSizes.remove(option)
                        } else {
                            model.wrappedValue.bagSizes.insert(option)
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
            }
        }
    }

    private func merchTypeSection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Merch")
            let allOptions = FormState.merchTypeOptions + model.wrappedValue.customMerchTypes
            RadioGroup(options: allOptions, selection: model.merchType, trailingButton: {
                AnyView(Button {
                    showMerchTypeAlert = true
                } label: {
                    Text("Other...")
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

    private func imageSection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Image")
            let allOptions = FormState.imageOptions + model.wrappedValue.customImageTypes
            FlowLayout(spacing: 8) {
                ForEach(allOptions, id: \.self) { option in
                    let isSelected = model.wrappedValue.image.contains(option)
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        if isSelected {
                            model.wrappedValue.image.remove(option)
                        } else {
                            model.wrappedValue.image.insert(option)
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
                Button {
                    showImageAlert = true
                } label: {
                    Text("Other...")
                        .appFont()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }
            }
            .alert("Add Image Type", isPresented: $showImageAlert) {
                TextField("Image type", text: $imageInput)
                Button("Cancel", role: .cancel) {
                    imageInput = ""
                }
                Button("Add") {
                    model.wrappedValue.customImageInput = imageInput
                    model.wrappedValue.addCustomImage()
                    imageInput = ""
                }
            }
        }
    }

    private func typographySection(_ model: Bindable<FormState>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Typography")
            let allOptions = FormState.typographyOptions + model.wrappedValue.customTypography
            MultiSelectGrid(options: allOptions, selected: model.typography, trailingButton: {
                AnyView(Button {
                    showTypographyAlert = true
                } label: {
                    Text("Other...")
                        .appFont()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                })
            })
            .alert("Add Typography", isPresented: $showTypographyAlert) {
                TextField("Typography", text: $typographyInput)
                Button("Cancel", role: .cancel) {
                    typographyInput = ""
                }
                Button("Add") {
                    model.wrappedValue.customTypographyInput = typographyInput
                    model.wrappedValue.addCustomTypography()
                    typographyInput = ""
                }
            }
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Note")
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
                Text("Add Note...")
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

        // Preserve all form values when group is not single
        let formSnapshot = s.isGroup ? FormSnapshot(from: s) : nil

        await SubmissionQueue.shared.add(record)
        await updateStatsText()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        showToast = true
        s.reset()
        if let snap = formSnapshot {
            snap.restore(into: s)
        }
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

    private func updateStatsText() async {
        totalCount = await SubmissionQueue.shared.cumulativeTotal
        todayCount = await SubmissionQueue.shared.cumulativeToday
    }
}

// MARK: - Custom Segmented Control

struct SegmentedControl: View {
    let options: [String]
    @Binding var selection: String?
    var icons: [String: String] = [:]

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
                        HStack(spacing: 4) {
                            if let icon = icons[option] {
                                Image(systemName: icon)
                                    .appFont(.medium)
                            }
                            Text(option)
                                .appFont(.medium)
                        }
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

// MARK: - Form Snapshot

private struct FormSnapshot {
    let gender: String?
    let ageGroup: String?
    let race: String?
    let merchType: String?
    let customMerchTypes: [String]
    let garmentColors: Set<String>
    let printColors: Set<String>
    let image: Set<String>
    let customImageTypes: [String]
    let typography: Set<String>
    let customTypography: [String]
    let group: String
    let groupCount: String?
    let matchingDesigns: String?
    let mode: String
    let bagSizes: Set<String>
    let comments: [String]

    init(from s: FormState) {
        gender = s.gender
        ageGroup = s.ageGroup
        race = s.race
        merchType = s.merchType
        customMerchTypes = s.customMerchTypes
        garmentColors = s.garmentColors
        printColors = s.printColors
        image = s.image
        customImageTypes = s.customImageTypes
        typography = s.typography
        customTypography = s.customTypography
        group = s.group
        groupCount = s.groupCount
        matchingDesigns = s.matchingDesigns
        mode = s.mode
        bagSizes = s.bagSizes
        comments = s.comments
    }

    func restore(into s: FormState) {
        s.gender = gender
        s.ageGroup = ageGroup
        s.race = race
        s.merchType = merchType
        s.customMerchTypes = customMerchTypes
        s.garmentColors = garmentColors
        s.printColors = printColors
        s.image = image
        s.customImageTypes = customImageTypes
        s.typography = typography
        s.customTypography = customTypography
        s.group = group
        s.groupCount = groupCount
        s.matchingDesigns = matchingDesigns
        s.mode = mode
        s.bagSizes = bagSizes
        s.comments = comments
    }
}
