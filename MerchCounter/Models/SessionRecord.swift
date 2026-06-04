import Foundation

struct SessionRecord: Codable {
    let sessionNumber: Int
    let date: Date
    let startTime: Date
    let endTime: Date
    let weather: String?
    let temperature: String?

    let passByToCableCar_Solo: Int
    let passByToCableCar_Group: Int
    let passByToCableCar_Family: Int

    let passByToWharf_Solo: Int
    let passByToWharf_Group: Int
    let passByToWharf_Family: Int

    // Store1
    let entered_Solo: Int
    let entered_Group: Int
    let entered_Family: Int

    let leavingWithBags_Solo: Int
    let leavingWithBags_Group: Int
    let leavingWithBags_Family: Int

    let bagSmall: Int
    let bagMedium: Int
    let bagBig: Int

    // Store2
    let entered2_Solo: Int
    let entered2_Group: Int
    let entered2_Family: Int

    let leavingWithBags2_Solo: Int
    let leavingWithBags2_Group: Int
    let leavingWithBags2_Family: Int

    let bag2Small: Int
    let bag2Medium: Int
    let bag2Big: Int

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
            "\(passByToCableCar_Solo)", "\(passByToCableCar_Group)", "\(passByToCableCar_Family)",
            "\(passByToWharf_Solo)", "\(passByToWharf_Group)", "\(passByToWharf_Family)",
            "\(entered_Solo)", "\(entered_Group)", "\(entered_Family)",
            "\(leavingWithBags_Solo)", "\(leavingWithBags_Group)", "\(leavingWithBags_Family)",
            "\(bagSmall)", "\(bagMedium)", "\(bagBig)",
            "\(entered2_Solo)", "\(entered2_Group)", "\(entered2_Family)",
            "\(leavingWithBags2_Solo)", "\(leavingWithBags2_Group)", "\(leavingWithBags2_Family)",
            "\(bag2Small)", "\(bag2Medium)", "\(bag2Big)",
        ]
    }

    static var sheetHeaders: [String] {
        [
            "Session", "Date", "Start", "End", "Weather", "Temp",
            "PassByToCableCarSolo", "PassByToCableCarGroup", "PassByToCableCarFamily",
            "PassByToWharfSolo", "PassByToWharfGroup", "PassByToWharfFamily",
            "EnteredSolo", "EnteredGroup", "EnteredFamily",
            "LeavingWithBagSolo", "LeavingWithBagGroup", "LeavingWithBagFamily",
            "BagSmall", "BagMedium", "BagBig",
            "Entered2Solo", "Entered2Group", "Entered2Family",
            "LeavingWithBag2Solo", "LeavingWithBag2Group", "LeavingWithBag2Family",
            "Bag2Small", "Bag2Medium", "Bag2Big",
        ]
    }
}
