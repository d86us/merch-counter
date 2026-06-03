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

    var designFeatures: Set<String> = []
    var customDesignFeatures: [String] = []
    var showCustomDesignFeature = false
    var customDesignFeatureInput = ""

    var comments: [String] = []

    let timestamp = Date()

    var weather: String?
    var temperature: String?

    var isSubmitting = false
    var submitSuccess = false

    static let merchTypeOptions = ["T-Shirt", "Hoodie", "Baseball Hat", "Winter Hat", "Jacket", "Sweatshirt", "Bag"]
    static let designFeatureOptions = [
        "Animal", "Bay Area", "Bay Bridge", "CA", "Cable Cart", "California", "California Flag",
        "Golden Gate Bridge", "Illustration", "Non-SF Merch", "San Francisco", "SF", "SF Baseball", "SF Football",
        "Sightseeing", "Since 1850", "Sport Font", "Salesforce Tower", "Trans American Building",
        "Type Only", "Bear"
    ]

    var isReady: Bool {
        gender != nil && ageGroup != nil && merchType != nil
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

    func addCustomDesignFeature() {
        let trimmed = customDesignFeatureInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customDesignFeatures.append(trimmed)
        designFeatures.insert(trimmed)
        customDesignFeatureInput = ""
        showCustomDesignFeature = false
    }

    func toRecord() -> SurveyRecord {
        SurveyRecord(
            timestamp: Date(),
            gender: gender ?? "",
            ageGroup: ageGroup ?? "",
            race: race ?? "",
            weather: weather,
            temperature: temperature,
            merchTypes: merchType.map { [$0] } ?? [],
            garmentColors: Array(garmentColors).sorted(),
            printColors: Array(printColors).sorted(),
            designFeatures: Array(designFeatures).sorted(),
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
        designFeatures = []
        customDesignFeatures = []
        customDesignFeatureInput = ""
        showCustomDesignFeature = false
        weather = nil
        temperature = nil
        comments = []
        isSubmitting = false
        submitSuccess = false
    }
}
