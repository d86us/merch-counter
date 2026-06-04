import SwiftUI

struct SessionObservationView: View {
    @State private var isActive = false
    @State private var intervalStart: Date?
    @State private var weather: String?
    @State private var temperature: String?
    @State private var elapsedTimer: Timer?
    @State private var sliceTimer: Timer?
    @State private var cumulativeTotal = 0
    @State private var cycleCount = 0
    @State private var isSaving = false
    @AppStorage("lastSessionNumber") private var lastSessionNumber = 0
    @State private var currentSessionNumber = 0
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var now: Date = Date()

    // Persistence - delete this block and saveState/loadState/clearState calls to remove
    private struct PersistedState: Codable {
        var intervalStart: Date?
        var currentSessionNumber = 0, cumulativeTotal = 0, cycleCount = 0
        var weather: String?, temperature: String?
        var pc_ccSolo = 0, pc_ccGroup = 0, pc_ccFamily = 0
        var pc_wSolo = 0, pc_wGroup = 0, pc_wFamily = 0
        var enSolo = 0, enGroup = 0, enFamily = 0
        var lwbSolo = 0, lwbGroup = 0, lwbFamily = 0
        var bagSmall = 0, bagMedium = 0, bagBig = 0
        var en2Solo = 0, en2Group = 0, en2Family = 0
        var lwb2Solo = 0, lwb2Group = 0, lwb2Family = 0
        var bag2Small = 0, bag2Medium = 0, bag2Big = 0
    }
    @AppStorage("sessionData") private var sessionData: Data = Data()

    @State private var pc_ccSolo = 0
    @State private var pc_ccGroup = 0
    @State private var pc_ccFamily = 0
    @State private var pc_wSolo = 0
    @State private var pc_wGroup = 0
    @State private var pc_wFamily = 0
    @State private var enSolo = 0
    @State private var enGroup = 0
    @State private var enFamily = 0
    @State private var lwbSolo = 0
    @State private var lwbGroup = 0
    @State private var lwbFamily = 0
    @State private var bagSmall = 0
    @State private var bagMedium = 0
    @State private var bagBig = 0

    // Store2
    @State private var en2Solo = 0
    @State private var en2Group = 0
    @State private var en2Family = 0
    @State private var lwb2Solo = 0
    @State private var lwb2Group = 0
    @State private var lwb2Family = 0
    @State private var bag2Small = 0
    @State private var bag2Medium = 0
    @State private var bag2Big = 0

    private let sliceInterval: TimeInterval = 300

    private var intervalTotal: Int {
        pc_ccSolo + pc_ccGroup + pc_ccFamily +
        pc_wSolo + pc_wGroup + pc_wFamily +
        enSolo + enGroup + enFamily +
        lwbSolo + lwbGroup + lwbFamily +
        bagSmall + bagMedium + bagBig +
        en2Solo + en2Group + en2Family +
        lwb2Solo + lwb2Group + lwb2Family +
        bag2Small + bag2Medium + bag2Big
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar

            sectionDivider

            passingBySection

            sectionDivider

            storeSection
        }
        .padding(.horizontal, 12)
        .padding(.top, 45)
        .padding(.bottom, 50)
        .task {
            impactGenerator.prepare()
            loadState()
            let (condition, temp) = await WeatherService.shared.currentWeather()
            weather = condition
            temperature = temp
        }

    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Text("Session \(currentSessionNumber)")
                .appFont(.semibold)
                .monospaced()
                .foregroundColor(Color.appAccent)
            Text(formattedCycleElapsed)
                .appFont(.semibold)
                .monospaced()
            if isSaving {
                Text("Saving...")
                    .appFont(.semibold)
                    .monospaced()
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("END")
                .appFont(.semibold)
                .monospaced()
                .foregroundColor(Color.appAccent)
                .underline()
                .onTapGesture { manualEnd() }
        }
        .opacity(isActive ? 1 : 0.5)
        .padding(.bottom, 6)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(height: 2)
            .padding(.vertical, 10)
    }

    // MARK: - Passing By (two columns)

    private var passingBySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Passing By")
            HStack(alignment: .top, spacing: 10) {
                directionColumn("To Cable Car", arrow: "arrow.left",
                    solo: $pc_ccSolo, group: $pc_ccGroup, family: $pc_ccFamily)
                directionColumn("To Wharf", arrow: "arrow.right",
                    solo: $pc_wSolo, group: $pc_wGroup, family: $pc_wFamily)
            }
        }
    }

    private func directionColumn(_ title: String, arrow: String, solo: Binding<Int>, group: Binding<Int>, family: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                directionHeader(title)
                Image(systemName: arrow)
                    .font(.caption)
            .foregroundColor(.primary)
            }
            stepperRow("Solo", value: solo)
            stepperRow("Group", value: group)
            stepperRow("Family", value: family)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Store1 / Store2 (two columns)

    private var storeSection: some View {
        HStack(alignment: .top, spacing: 10) {
            storeColumn("Store 1",
                enSolo: $enSolo, enGroup: $enGroup, enFamily: $enFamily,
                lwbSolo: $lwbSolo, lwbGroup: $lwbGroup, lwbFamily: $lwbFamily,
                bagSmall: $bagSmall, bagMedium: $bagMedium, bagBig: $bagBig)

            storeColumn("Store 2",
                enSolo: $en2Solo, enGroup: $en2Group, enFamily: $en2Family,
                lwbSolo: $lwb2Solo, lwbGroup: $lwb2Group, lwbFamily: $lwb2Family,
                bagSmall: $bag2Small, bagMedium: $bag2Medium, bagBig: $bag2Big)
        }
    }

    private func storeColumn(_ title: String,
        enSolo: Binding<Int>, enGroup: Binding<Int>, enFamily: Binding<Int>,
        lwbSolo: Binding<Int>, lwbGroup: Binding<Int>, lwbFamily: Binding<Int>,
        bagSmall: Binding<Int>, bagMedium: Binding<Int>, bagBig: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionLabel(title)
                .padding(.bottom, 10)
            iconHeader("arrow.up", text: "Entered")
            stepperRow("Solo", value: enSolo)
            stepperRow("Group", value: enGroup)
            stepperRow("Family", value: enFamily)
                .padding(.bottom, 10)
            iconHeader("arrow.down", text: "LEAVING with BAG")
            stepperRow("Solo", value: lwbSolo)
            stepperRow("Group", value: lwbGroup)
            stepperRow("Family", value: lwbFamily)
                .padding(.bottom, 10)
            iconHeader("bag", text: "Bag")
            stepperRow("Small", value: bagSmall)
            stepperRow("Medium", value: bagMedium)
            stepperRow("Big", value: bagBig)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reusable Components

    private func directionHeader(_ text: String) -> some View {
        Text(text)
            .appFont(.semibold)
            .monospaced()
            .foregroundColor(.primary)
            .textCase(.uppercase)
    }

    private func iconHeader(_ icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primary)
            Text(text)
                .appFont(.semibold)
                .monospaced()
                .foregroundColor(.primary)
                .textCase(.uppercase)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .appFont(.semibold)
            .monospaced()
            .foregroundColor(Color.appAccent)
            .textCase(.uppercase)
    }

    private func stepperRow(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .appFont(.semibold)
                .monospaced()
                .foregroundColor(Color.appAccent)
                .opacity(value.wrappedValue == 0 ? 0.5 : 1.0)
                .lineLimit(1)
            Spacer()
            FlashValueView(value: value.wrappedValue)
            HStack(spacing: 10) {
                StepperButton(systemName: "minus.circle.fill", isActive: value.wrappedValue > 0) {
                    if value.wrappedValue > 0 {
                        value.wrappedValue -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                StepperButton(systemName: "plus.circle.fill", isActive: true) {
                    increment(value)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Persistence

    private func saveState() {
        let s = PersistedState(
            intervalStart: intervalStart, currentSessionNumber: currentSessionNumber,
            cumulativeTotal: cumulativeTotal, cycleCount: cycleCount,
            weather: weather, temperature: temperature,
            pc_ccSolo: pc_ccSolo, pc_ccGroup: pc_ccGroup, pc_ccFamily: pc_ccFamily,
            pc_wSolo: pc_wSolo, pc_wGroup: pc_wGroup, pc_wFamily: pc_wFamily,
            enSolo: enSolo, enGroup: enGroup, enFamily: enFamily,
            lwbSolo: lwbSolo, lwbGroup: lwbGroup, lwbFamily: lwbFamily,
            bagSmall: bagSmall, bagMedium: bagMedium, bagBig: bagBig,
            en2Solo: en2Solo, en2Group: en2Group, en2Family: en2Family,
            lwb2Solo: lwb2Solo, lwb2Group: lwb2Group, lwb2Family: lwb2Family,
            bag2Small: bag2Small, bag2Medium: bag2Medium, bag2Big: bag2Big
        )
        sessionData = (try? JSONEncoder().encode(s)) ?? Data()
    }

    private func loadState() {
        guard let s = try? JSONDecoder().decode(PersistedState.self, from: sessionData),
              let start = s.intervalStart,
              Date().timeIntervalSince(start) < 600 else { return }
        isActive = true
        intervalStart = start
        currentSessionNumber = s.currentSessionNumber
        cumulativeTotal = s.cumulativeTotal
        cycleCount = s.cycleCount
        weather = s.weather; temperature = s.temperature
        pc_ccSolo = s.pc_ccSolo; pc_ccGroup = s.pc_ccGroup; pc_ccFamily = s.pc_ccFamily
        pc_wSolo = s.pc_wSolo; pc_wGroup = s.pc_wGroup; pc_wFamily = s.pc_wFamily
        enSolo = s.enSolo; enGroup = s.enGroup; enFamily = s.enFamily
        lwbSolo = s.lwbSolo; lwbGroup = s.lwbGroup; lwbFamily = s.lwbFamily
        bagSmall = s.bagSmall; bagMedium = s.bagMedium; bagBig = s.bagBig
        en2Solo = s.en2Solo; en2Group = s.en2Group; en2Family = s.en2Family
        lwb2Solo = s.lwb2Solo; lwb2Group = s.lwb2Group; lwb2Family = s.lwb2Family
        bag2Small = s.bag2Small; bag2Medium = s.bag2Medium; bag2Big = s.bag2Big
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in now = Date() }
        sliceTimer = Timer.scheduledTimer(withTimeInterval: sliceInterval, repeats: true) { _ in sliceNow() }
    }

    private func clearState() { sessionData = Data() }

    // MARK: - Actions

    private func increment(_ value: Binding<Int>) {
        if !isActive { startSession() }
        value.wrappedValue += 1
        saveState()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func startSession() {
        lastSessionNumber += 1
        currentSessionNumber = lastSessionNumber
        intervalStart = Date()
        isActive = true
        cumulativeTotal = 0
        cycleCount = 0
        impactGenerator.impactOccurred()
        impactGenerator.prepare()

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            now = Date()
        }

        sliceTimer = Timer.scheduledTimer(withTimeInterval: sliceInterval, repeats: true) { _ in
            sliceNow()
        }
        saveState()
    }

    private func sliceNow() {
        guard let intervalStart else { return }
        let now = Date()

        if intervalTotal == 0 {
            autoEnd()
            return
        }

        let record = makeRecord(from: intervalStart, to: now)
        isSaving = true
        Task { @MainActor in
            await SessionQueue.shared.add(record)
            try? await Task.sleep(nanoseconds: 800_000_000)
            isSaving = false
        }
        cumulativeTotal += intervalTotal
        cycleCount += 1
        self.intervalStart = now
        resetCounters()
        saveState()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func manualEnd() {
        guard isActive, let start = intervalStart else { return }
        let now = Date()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        sliceTimer?.invalidate()
        sliceTimer = nil
        if intervalTotal > 0 {
            let record = makeRecord(from: start, to: now)
            isSaving = true
            Task { @MainActor in
                await SessionQueue.shared.add(record)
                try? await Task.sleep(nanoseconds: 800_000_000)
                isSaving = false
                autoEnd()
            }
        } else {
            autoEnd()
        }
    }

    private func makeRecord(from fromDate: Date, to toDate: Date) -> SessionRecord {
        SessionRecord(
            sessionNumber: currentSessionNumber,
            date: fromDate,
            startTime: fromDate,
            endTime: toDate,
            weather: weather,
            temperature: temperature,
            passByToCableCar_Solo: pc_ccSolo,
            passByToCableCar_Group: pc_ccGroup,
            passByToCableCar_Family: pc_ccFamily,
            passByToWharf_Solo: pc_wSolo,
            passByToWharf_Group: pc_wGroup,
            passByToWharf_Family: pc_wFamily,
            entered_Solo: enSolo,
            entered_Group: enGroup,
            entered_Family: enFamily,
            leavingWithBags_Solo: lwbSolo,
            leavingWithBags_Group: lwbGroup,
            leavingWithBags_Family: lwbFamily,
            bagSmall: bagSmall,
            bagMedium: bagMedium,
            bagBig: bagBig,
            entered2_Solo: en2Solo,
            entered2_Group: en2Group,
            entered2_Family: en2Family,
            leavingWithBags2_Solo: lwb2Solo,
            leavingWithBags2_Group: lwb2Group,
            leavingWithBags2_Family: lwb2Family,
            bag2Small: bag2Small,
            bag2Medium: bag2Medium,
            bag2Big: bag2Big
        )
    }

    private func reset() {
        isActive = false
        intervalStart = nil
        cumulativeTotal = 0
        cycleCount = 0
        resetCounters()
    }

    private func autoEnd() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        sliceTimer?.invalidate()
        sliceTimer = nil
        reset()
        clearState()
    }

    private var formattedCycleElapsed: String {
        guard let start = intervalStart else { return "00:00" }
        let t = now.timeIntervalSince(start)
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func resetCounters() {
        pc_ccSolo = 0; pc_ccGroup = 0; pc_ccFamily = 0
        pc_wSolo = 0; pc_wGroup = 0; pc_wFamily = 0
        enSolo = 0; enGroup = 0; enFamily = 0
        lwbSolo = 0; lwbGroup = 0; lwbFamily = 0
        bagSmall = 0; bagMedium = 0; bagBig = 0
        en2Solo = 0; en2Group = 0; en2Family = 0
        lwb2Solo = 0; lwb2Group = 0; lwb2Family = 0
        bag2Small = 0; bag2Medium = 0; bag2Big = 0
    }
}

private struct StepperButton: View {
    let systemName: String
    let isActive: Bool
    let action: () -> Void
    @State private var flash = false

    var body: some View {
        Button {
            action()
            flash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                flash = false
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 36))
                .foregroundColor(flash ? Color.appAccent : Color(.systemGray4))
                .animation(.easeOut(duration: 0.1), value: flash)
        }
        .disabled(!isActive)
    }
}

private struct FlashValueView: View {
    let value: Int
    @State private var flash = false

    var body: some View {
        Text("\(value)")
            .appFont(.semibold)
            .monospaced()
            .frame(minWidth: 24)
            .foregroundColor(flash ? Color.appAccent : .primary)
            .scaleEffect(flash ? 1.3 : 1.0)
            .opacity(value == 0 ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.1), value: flash)
            .onChange(of: value) { _, _ in
                flash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    flash = false
                }
            }
    }
}
