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

    var image: Set<String> = ["No"]
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

    var weather: String?
    var temperature: String?

    init() {}

    static let groupOptions = ["Single", "Couple", "Family", "Friends"]
    static let groupCountOptions = ["2", "3", "4", "5", "6+"]

    var isSubmitting = false
    var submitSuccess = false

    static let merchTypeOptions = ["T-Shirt", "Hoodie", "Baseball Hat", "Winter Hat", "Jacket", "Sweatshirt", "Bag"]
    static let imageOptions = ["No", "Golden Gate Bridge", "USA Flag", "Cable Cart"]
    static let typographyOptions = ["San Francisco", "California", "SF", "CA", "Bay Area", "Since 1850", "USA"]

    var isReady: Bool {
        gender != nil && ageGroup != nil && race != nil && merchType != nil
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
            image: image.sorted().joined(separator: "; "),
            typography: Array(typography).sorted(),
            weather: weather,
            temperature: temperature,
            merchTypes: merchType.map { [$0] } ?? [],
            garmentColors: Array(garmentColors).sorted(),
            printColors: Array(printColors).sorted(),
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
        image = ["No"]
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
        weather = nil
        temperature = nil
        comments = []
        isSubmitting = false
        submitSuccess = false
    }
}
