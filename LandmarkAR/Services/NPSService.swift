import CoreLocation
import Foundation

// MARK: - NPSService (LAR-12)
// Fetches nearby National Park Service sites from the NPS API.
// Requires a free API key from https://www.nps.gov/subjects/developer/get-started.htm

class NPSService {

    private let baseURL = "https://developer.nps.gov/api/v1"
    private let fetchLimit = 100  // NPS has ~500 total sites; fetch in batches

    // LAR-17: NPS is disabled as a user-facing source. Set this key to re-enable.
    private let apiKey: String = ""

    // MARK: - Fetch Nearby Landmarks

    /// Main entry point. Returns an empty array immediately if no API key is configured.
    func fetchNearbyLandmarks(near location: CLLocation, settings: AppSettings) async throws -> [Landmark] {
        guard !apiKey.isEmpty else { return [] }

        let radiusMeters = settings.maxDistanceKm * 1000
        let parks = try await fetchAllParks(apiKey: apiKey)

        return parks.compactMap { park in
            guard let lat = Double(park.latitude), let lon = Double(park.longitude),
                  lat != 0, lon != 0 else { return nil }

            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let parkLocation = CLLocation(latitude: lat, longitude: lon)
            let distance = location.distance(from: parkLocation)

            guard distance <= radiusMeters else { return nil }

            let bearing = location.coordinate.bearing(to: coordinate)
            let category = LandmarkCategory.classify(title: park.fullName, summary: park.description)
            let url = URL(string: park.url)

            return Landmark(
                id: "nps-\(park.id)",
                title: park.fullName,
                summary: park.description,
                coordinate: coordinate,
                wikipediaURL: url,
                category: category,
                distance: distance,
                bearing: bearing
            )
        }.sorted { $0.distance < $1.distance }
    }

    // MARK: - Private Helpers

    private func fetchAllParks(apiKey: String) async throws -> [NPSPark] {
        var allParks: [NPSPark] = []
        var start = 0

        repeat {
            var components = URLComponents(string: "\(baseURL)/parks")!
            components.queryItems = [
                URLQueryItem(name: "limit",   value: "\(fetchLimit)"),
                URLQueryItem(name: "start",   value: "\(start)"),
                URLQueryItem(name: "api_key", value: apiKey),
            ]

            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let response = try JSONDecoder().decode(NPSParksResponse.self, from: data)

            allParks.append(contentsOf: response.data)

            let total = Int(response.total) ?? 0
            start += fetchLimit
            if start >= total { break }
        } while true

        return allParks
    }
}

// MARK: - NPS API Response Models

private struct NPSParksResponse: Codable {
    let total: String
    let data: [NPSPark]
}

private struct NPSPark: Codable {
    let id: String
    let fullName: String
    let description: String
    let latitude: String
    let longitude: String
    let url: String
}
