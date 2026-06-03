import Foundation

actor WeatherService {
    static let shared = WeatherService()

    private let session: URLSession

    private struct OpenMeteoResponse: Decodable {
        struct CurrentWeather: Decodable {
            let temperature: Double
            let weatherCode: Int
            enum CodingKeys: String, CodingKey {
                case temperature
                case weatherCode = "weathercode"
            }
        }
        let currentWeather: CurrentWeather
        enum CodingKeys: String, CodingKey {
            case currentWeather = "current_weather"
        }
    }

    private let latitude = 37.808
    private let longitude = -122.417
    private var cachedWeather: (condition: String, temperature: String)?
    private var cachedFetchTime: Date?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    private var shouldRefresh: Bool {
        guard let last = cachedFetchTime else { return true }
        return Date().timeIntervalSince(last) >= 1800
    }

    func currentWeather() async -> (condition: String, temperature: String) {
        if !shouldRefresh, let cached = cachedWeather {
            return cached
        }
        return await fetchWeather()
    }

    private func fetchWeather() async -> (condition: String, temperature: String) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true&temperature_unit=fahrenheit&timezone=America%2FLos_Angeles"
        guard let url = URL(string: urlString) else { return ("Unknown", "") }

        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let condition = Self.label(for: decoded.currentWeather.weatherCode)
            let temp = Int(decoded.currentWeather.temperature.rounded())
            let result = (condition, "\(temp)")
            cachedWeather = result
            cachedFetchTime = Date()
            return result
        } catch {
            if let cached = cachedWeather { return cached }
            return ("Unknown", "")
        }
    }

    static func label(for code: Int) -> String {
        switch code {
        case 0: "Sunny"
        case 1: "Mostly Clear"
        case 2: "Partly Cloudy"
        case 3: "Overcast"
        case 45, 48: "Foggy"
        case 51, 53, 55, 56, 57: "Drizzle"
        case 61, 63, 65, 66, 67: "Rainy"
        case 71, 73, 75, 77: "Snow"
        case 80, 81, 82: "Rainy"
        case 85, 86: "Snow"
        case 95, 96, 99: "Thunderstorm"
        default: "Cloudy"
        }
    }
}
