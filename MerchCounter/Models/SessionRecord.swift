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
            "PassByToCableCar: Solo", "PassByToCableCar: Group", "PassByToCableCar: Family",
            "PassByToWharf: Solo", "PassByToWharf: Group", "PassByToWharf: Family",
            "Entered: Solo", "Entered: Group", "Entered: Family",
            "Leaving with Bag: Solo", "Leaving with Bag: Group", "Leaving with Bag: Family",
            "Bag Small", "Bag Medium", "Bag Big",
            "Entered2: Solo", "Entered2: Group", "Entered2: Family",
            "Leaving with Bag2: Solo", "Leaving with Bag2: Group", "Leaving with Bag2: Family",
            "Bag2 Small", "Bag2 Medium", "Bag2 Big",
        ]
    }
}
