import SwiftUI

struct SimpleSessionObservationView: View {
    @State private var isActive = false
    @State private var intervalStart: Date?
    @State private var weather: String?
    @State private var temperature: String?
    @State private var elapsedTimer: Timer?
    @State private var sliceTimer: Timer?
    @State private var cumulativeTotal = 0
    @State private var cycleCount = 0
    @State private var isSaving = false
    @AppStorage("simpleLastSessionNumber") private var lastSessionNumber = 0
    @State private var currentSessionNumber = 0
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var now: Date = Date()

    private struct PersistedState: Codable {
        var intervalStart: Date?
        var currentSessionNumber = 0, cumulativeTotal = 0, cycleCount = 0
        var weather: String?, temperature: String?
        var pc_cc = 0, pc_w = 0
        var en = 0, en2 = 0
        var bagSmall = 0, bagMedium = 0, bagBig = 0
        var bag2Small = 0, bag2Medium = 0, bag2Big = 0
    }
    @AppStorage("simpleSessionData") private var sessionData: Data = Data()

    @State private var pc_cc = 0
    @State private var pc_w = 0
    @State private var en = 0
    @State private var en2 = 0
    @State private var bagSmall = 0
    @State private var bagMedium = 0
    @State private var bagBig = 0
    @State private var bag2Small = 0
    @State private var bag2Medium = 0
    @State private var bag2Big = 0

    private let sliceInterval: TimeInterval = 300

    private var intervalTotal: Int {
        pc_cc + pc_w + en + en2 + bagSmall + bagMedium + bagBig + bag2Small + bag2Medium + bag2Big
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar

            sectionDivider

            passingBySection

            sectionDivider

            entersSection

            sectionDivider

            bagsSection

            Spacer()
        }
        .padding(.horizontal, 12)
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

    private var passingBySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                verticalStepper(label: "PASSING LEFT", value: $pc_cc)
                    .frame(maxWidth: .infinity)
                verticalStepper(label: "PASSING RIGHT", value: $pc_w)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var entersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                verticalStepper(label: "S1 ENTERED", value: $en)
                    .frame(maxWidth: .infinity)
                verticalStepper(label: "S2 ENTERED", value: $en2)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var bagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                verticalStepper(label: "S1 BAG SMALL", value: $bagSmall)
                    .frame(maxWidth: .infinity)
                verticalStepper(label: "S2 BAG SMALL", value: $bag2Small)
                    .frame(maxWidth: .infinity)
            }
            HStack(alignment: .top, spacing: 10) {
                verticalStepper(label: "S1 BAG MEDIUM", value: $bagMedium)
                    .frame(maxWidth: .infinity)
                verticalStepper(label: "S2 BAG MEDIUM", value: $bag2Medium)
                    .frame(maxWidth: .infinity)
            }
            HStack(alignment: .top, spacing: 10) {
                verticalStepper(label: "S1 BAG BIG", value: $bagBig)
                    .frame(maxWidth: .infinity)
                verticalStepper(label: "S2 BAG BIG", value: $bag2Big)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func verticalStepper(label: String, value: Binding<Int>) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .appFont(.semibold)
                .monospaced()
                .foregroundColor(Color.appAccent)
                .opacity(value.wrappedValue == 0 ? 0.5 : 1.0)
                .lineLimit(1)
            HStack(spacing: 6) {
                StepperButton(systemName: "minus.circle.fill", isActive: value.wrappedValue > 0) {
                    if value.wrappedValue > 0 {
                        value.wrappedValue -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                FlashValueView(value: value.wrappedValue)
                StepperButton(systemName: "plus.circle.fill", isActive: true, color: Color.appAccent) {
                    increment(value)
                }
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Persistence

    private func saveState() {
        let s = PersistedState(
            intervalStart: intervalStart, currentSessionNumber: currentSessionNumber,
            cumulativeTotal: cumulativeTotal, cycleCount: cycleCount,
            weather: weather, temperature: temperature,
            pc_cc: pc_cc, pc_w: pc_w,
            en: en, en2: en2,
            bagSmall: bagSmall, bagMedium: bagMedium, bagBig: bagBig,
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
        pc_cc = s.pc_cc; pc_w = s.pc_w
        en = s.en; en2 = s.en2
        bagSmall = s.bagSmall; bagMedium = s.bagMedium; bagBig = s.bagBig
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
            await SimpleSessionQueue.shared.add(record)
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
                await SimpleSessionQueue.shared.add(record)
                try? await Task.sleep(nanoseconds: 800_000_000)
                isSaving = false
                autoEnd()
            }
        } else {
            autoEnd()
        }
    }

    private func makeRecord(from fromDate: Date, to toDate: Date) -> SimpleSessionRecord {
        SimpleSessionRecord(
            sessionNumber: currentSessionNumber,
            date: fromDate,
            startTime: fromDate,
            endTime: toDate,
            weather: weather,
            temperature: temperature,
            passingLeft: pc_cc,
            passingRight: pc_w,
            s1Entered: en,
            s2Entered: en2,
            s1BagSmall: bagSmall,
            s1BagMedium: bagMedium,
            s1BagBig: bagBig,
            s2BagSmall: bag2Small,
            s2BagMedium: bag2Medium,
            s2BagBig: bag2Big
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
        pc_cc = 0; pc_w = 0
        en = 0; en2 = 0
        bagSmall = 0; bagMedium = 0; bagBig = 0
        bag2Small = 0; bag2Medium = 0; bag2Big = 0
    }
}

private struct StepperButton: View {
    let systemName: String
    let isActive: Bool
    let action: () -> Void
    var color: Color = Color(.systemGray4)
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
                .foregroundColor(flash ? Color.appAccent : color)
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
