import Foundation

struct SurveyRecord: Codable {
    let timestamp: Date
    let gender: String
    let ageGroup: String
    let race: String
    let weather: String?
    let temperature: String?
    let merchTypes: [String]
    let garmentColors: [String]
    let printColors: [String]
    let designFeatures: [String]
    let comments: [String]

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: timestamp)
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }

    var sheetRowValues: [String] {
        [
            dateString,
            timeString,
            weather ?? "",
            temperature ?? "",
            gender,
            ageGroup,
            race,
            merchTypes.joined(separator: "; "),
            garmentColors.joined(separator: "; "),
            printColors.joined(separator: "; "),
            designFeatures.joined(separator: "; "),
            comments.joined(separator: "; "),
        ]
    }

    static var sheetHeaders: [String] {
        ["Date", "Time", "Weather", "Temperature", "Gender", "Age", "Race", "Merch Types", "Garment Colors", "Print Colors", "Design Features", "Comment"]
    }
}
