import Foundation

struct SimpleSessionRecord: Codable {
    let sessionNumber: Int
    let date: Date
    let startTime: Date
    let endTime: Date
    let weather: String?
    let temperature: String?

    let passingLeft: Int
    let passingRight: Int

    let s1Entered: Int
    let s2Entered: Int

    let s1BagSmall: Int
    let s1BagMedium: Int
    let s1BagBig: Int

    let s2BagSmall: Int
    let s2BagMedium: Int
    let s2BagBig: Int

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var startTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: startTime)
    }

    var endTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: endTime)
    }

    var sheetRowValues: [String] {
        [
            "\(sessionNumber)",
            dateString,
            startTimeString,
            endTimeString,
            weather ?? "-",
            temperature ?? "-",
            "\(passingLeft)", "\(passingRight)",
            "\(s1Entered)", "\(s2Entered)",
            "\(s1BagSmall)", "\(s1BagMedium)", "\(s1BagBig)",
            "\(s2BagSmall)", "\(s2BagMedium)", "\(s2BagBig)",
        ]
    }

    static var sheetHeaders: [String] {
        [
            "Session", "Date", "Start", "End", "Weather", "Temp",
            "Passing Left", "Passing Right",
            "S1 Entered", "S2 Entered",
            "S1 Bag Small", "S1 Bag Medium", "S1 Bag Big",
            "S2 Bag Small", "S2 Bag Medium", "S2 Bag Big",
        ]
    }
}
