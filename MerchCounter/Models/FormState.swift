import Foundation
import Observation

@Observable
class FormState {
    var gender: String?
    var ageGroup: String?
    var race: String?

    var merchType: String?
    var customMerchTypes: [String] = []
    var showCustomMerch = false
    var customMerchInput = ""

    var garmentColors: Set<String> = []
    var showCustomGarmentColor = false
    var customGarmentColorInput = ""

    var printColors: Set<String> = []
    var showCustomPrintColor = false
    var customPrintColorInput = ""

    var image: Set<String> = []
    var customImageTypes: [String] = []
    var showCustomImage = false
    var customImageInput = ""

    var typography: Set<String> = []
    var customTypography: [String] = []
    var showCustomTypography = false
    var customTypographyInput = ""

    var comments: [String] = []

    var group: String = "Single"
    var groupCount: String?
    var matchingDesigns: String?

    var isGroup: Bool { group != "Single" }

    var mode: String = "Wearing"
    var bagSizes: Set<String> = []

    var weather: String?
    var temperature: String?

    init() {}

    static let groupOptions = ["Single", "Couple", "Family", "Friends"]
    static let groupCountOptions = ["2", "3", "4", "5", "6+"]
    static let modeOptions = ["Wearing", "Carrying Bag"]
    static let bagSizeOptions = ["Small", "Medium", "Big"]

    var isSubmitting = false
    var submitSuccess = false

    static let merchTypeOptions = ["Hoodie", "T-Shirt", "Sweatshirt", "Jacket", "Baseball Hat", "Winter Hat", "Bag"]
    static let imageOptions = ["Golden Gate Bridge", "USA Flag", "CA Flag", "Cable Cart", "Bear"]
    static let typographyOptions = ["San Francisco", "California", "SF", "CA", "Bay Area", "Since 1850", "USA"]

    var isReady: Bool {
        gender != nil && ageGroup != nil && race != nil && (merchType != nil || mode == "Carrying Bag")
    }

    func addCustomMerch() {
        let trimmed = customMerchInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customMerchTypes.append(trimmed)
        merchType = trimmed
        customMerchInput = ""
        showCustomMerch = false
    }

    func addCustomGarmentColor() {
        let trimmed = customGarmentColorInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        garmentColors.insert(trimmed)
        customGarmentColorInput = ""
        showCustomGarmentColor = false
    }

    func addCustomPrintColor() {
        let trimmed = customPrintColorInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        printColors.insert(trimmed)
        customPrintColorInput = ""
        showCustomPrintColor = false
    }

    func addCustomImage() {
        let trimmed = customImageInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customImageTypes.append(trimmed)
        image = [trimmed]
        customImageInput = ""
        showCustomImage = false
    }

    func addCustomTypography() {
        let trimmed = customTypographyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customTypography.append(trimmed)
        typography.insert(trimmed)
        customTypographyInput = ""
        showCustomTypography = false
    }

    func toRecord() -> SurveyRecord {
        SurveyRecord(
            timestamp: Date(),
            gender: gender ?? "",
            ageGroup: ageGroup ?? "",
            race: race ?? "",
            group: group,
            groupCount: isGroup ? groupCount ?? "" : "",
            matchingDesigns: isGroup ? (matchingDesigns ?? "") : "",
            mode: mode,
            bagSizes: mode == "Carrying Bag" ? Array(bagSizes).sorted() : [],
            image: mode == "Carrying Bag" ? "" : image.sorted().joined(separator: "; "),
            typography: mode == "Carrying Bag" ? [] : Array(typography).sorted(),
            weather: weather,
            temperature: temperature,
            merchTypes: merchType.map { [$0] } ?? [],
            garmentColors: mode == "Carrying Bag" ? [] : Array(garmentColors).sorted(),
            printColors: mode == "Carrying Bag" ? [] : Array(printColors).sorted(),
            comments: comments
        )
    }

    func reset() {
        gender = nil
        ageGroup = nil
        race = nil
        merchType = nil
        customMerchTypes = []
        customMerchInput = ""
        showCustomMerch = false
        garmentColors = []
        customGarmentColorInput = ""
        showCustomGarmentColor = false
        printColors = []
        customPrintColorInput = ""
        showCustomPrintColor = false
        image = []
        customImageTypes = []
        customImageInput = ""
        showCustomImage = false
        typography = []
        customTypography = []
        customTypographyInput = ""
        showCustomTypography = false
        group = "Single"
        groupCount = nil
        matchingDesigns = nil
        mode = "Wearing"
        bagSizes = []
        weather = nil
        temperature = nil
        comments = []
        isSubmitting = false
        submitSuccess = false
    }
}
