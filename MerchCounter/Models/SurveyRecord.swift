import Foundation

struct SurveyRecord: Codable {
    let timestamp: Date
    let gender: String
    let ageGroup: String
    let race: String
    let group: String
    let groupCount: String
    let matchingDesigns: String
    let mode: String
    let bagSizes: [String]
    let image: String
    let typography: [String]
    let weather: String?
    let temperature: String?
    let merchTypes: [String]
    let garmentColors: [String]
    let printColors: [String]
    let printPosition: [String]
    let comments: [String]

    enum CodingKeys: String, CodingKey {
        case timestamp, gender, ageGroup, race, group, groupCount, matchingDesigns
        case mode, bagSizes
        case image, typography
        case weather, temperature, merchTypes, garmentColors, printColors, printPosition, comments
    }

    init(timestamp: Date, gender: String, ageGroup: String, race: String, group: String, groupCount: String, matchingDesigns: String, mode: String, bagSizes: [String], image: String, typography: [String], weather: String?, temperature: String?, merchTypes: [String], garmentColors: [String], printColors: [String], printPosition: [String], comments: [String]) {
        self.timestamp = timestamp
        self.gender = gender
        self.ageGroup = ageGroup
        self.race = race
        self.group = group
        self.groupCount = groupCount
        self.matchingDesigns = matchingDesigns
        self.mode = mode
        self.bagSizes = bagSizes
        self.image = image
        self.typography = typography
        self.weather = weather
        self.temperature = temperature
        self.merchTypes = merchTypes
        self.garmentColors = garmentColors
        self.printColors = printColors
        self.printPosition = printPosition
        self.comments = comments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        gender = try c.decode(String.self, forKey: .gender)
        ageGroup = try c.decode(String.self, forKey: .ageGroup)
        race = try c.decode(String.self, forKey: .race)
        group = try c.decodeIfPresent(String.self, forKey: .group) ?? ""
        groupCount = try c.decodeIfPresent(String.self, forKey: .groupCount) ?? ""
        matchingDesigns = try c.decodeIfPresent(String.self, forKey: .matchingDesigns) ?? ""
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "Wearing"
        bagSizes = try c.decodeIfPresent([String].self, forKey: .bagSizes) ?? []
        image = try c.decodeIfPresent(String.self, forKey: .image) ?? ""
        typography = try c.decodeIfPresent([String].self, forKey: .typography) ?? []
        weather = try c.decodeIfPresent(String.self, forKey: .weather)
        temperature = try c.decodeIfPresent(String.self, forKey: .temperature)
        merchTypes = try c.decode([String].self, forKey: .merchTypes)
        garmentColors = try c.decode([String].self, forKey: .garmentColors)
        printColors = try c.decode([String].self, forKey: .printColors)
        printPosition = try c.decodeIfPresent([String].self, forKey: .printPosition) ?? []
        comments = try c.decode([String].self, forKey: .comments)
    }

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
        func dash(_ s: String) -> String { s.isEmpty ? "-" : s }
        return [
            dateString,
            timeString,
            dash(weather ?? ""),
            dash(temperature ?? ""),
            dash(gender),
            dash(ageGroup),
            dash(race),
            dash(group),
            dash(groupCount),
            dash(matchingDesigns),
            dash(mode),
            dash(bagSizes.joined(separator: "; ")),
            dash(image),
            dash(typography.joined(separator: "; ")),
            dash(merchTypes.joined(separator: "; ")),
            dash(garmentColors.joined(separator: "; ")),
            dash(printColors.joined(separator: "; ")),
            dash(printPosition.joined(separator: "; ")),
            dash(comments.joined(separator: "; ")),
        ]
    }

    static var sheetHeaders: [String] {
        ["Date", "Time", "Weather", "Temperature", "Gender", "Age", "Demographic", "Group", "Count", "Matching", "Mode", "Bag Sizes", "Image", "Typography", "Merch Types", "Garment Colors", "Print Colors", "Print Position", "Comment"]
    }
}
