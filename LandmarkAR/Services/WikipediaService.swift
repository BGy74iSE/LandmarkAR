import CoreLocation
import Foundation

// MARK: - WikipediaService
// Fetches nearby landmarks from the Wikipedia GeoSearch API,
// then loads a short summary for each one.

class WikipediaService {

    // Search radius in meters — landmarks within this distance will appear
    private let searchRadiusMeters = 10_000  // 10 km

    // Maximum number of landmarks to show at once (keeps the AR view clean)
    private let maxResults = 20

    // MARK: - Fetch Nearby Landmarks

    /// Main entry point. Call this with the user's current location.
    /// Returns an array of Landmark objects with summaries filled in.
    func fetchNearbyLandmarks(near location: CLLocation) async throws -> [Landmark] {

        // Step 1: Search for Wikipedia articles near this GPS coordinate
        let geoResults = try await geoSearch(near: location)

        // Step 2: For each result, fetch a short summary (run all fetches in parallel)
        let landmarks = try await withThrowingTaskGroup(of: Landmark?.self) { group in
            for result in geoResults {
                group.addTask {
                    try await self.buildLandmark(from: result, userLocation: location)
                }
            }

            var results: [Landmark] = []
            for try await landmark in group {
                if let landmark = landmark {
                    results.append(landmark)
                }
            }
            return results
        }

        // Sort by distance so the closest landmarks are first
        return landmarks.sorted { $0.distance < $1.distance }
    }

    // MARK: - Private Helpers

    /// Wikipedia GeoSearch: returns articles near a lat/lon
    private func geoSearch(near location: CLLocation) async throws -> [WikipediaGeoResult] {
        // Build the API URL
        // Docs: https://www.mediawiki.org/wiki/API:Geosearch
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "geosearch"),
            URLQueryItem(name: "gscoord", value: "\(location.coordinate.latitude)|\(location.coordinate.longitude)"),
            URLQueryItem(name: "gsradius", value: "\(searchRadiusMeters)"),
            URLQueryItem(name: "gslimit", value: "\(maxResults)"),
            URLQueryItem(name: "format", value: "json"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(WikipediaGeoSearchResponse.self, from: data)
        return response.query.geosearch
    }

    /// Fetches a plain-text summary for one Wikipedia article, then builds a Landmark
    private func buildLandmark(from result: WikipediaGeoResult, userLocation: CLLocation) async throws -> Landmark? {
        // Wikipedia REST summary endpoint — fast and returns clean text
        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(result.title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"

        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let summary = try JSONDecoder().decode(WikipediaSummaryResponse.self, from: data)

        // Build the landmark's CLLocation so we can calculate distance + bearing
        let landmarkLocation = CLLocation(
            latitude: result.lat,
            longitude: result.lon
        )
        let landmarkCoord = CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon)

        // Calculate distance from user to this landmark
        let distance = userLocation.distance(from: landmarkLocation)

        // Calculate compass bearing (azimuth) from user to landmark
        let bearing = userLocation.coordinate.bearing(to: landmarkCoord)

        // Build Wikipedia page URL
        let pageURL = summary.content_urls?.desktop?.page.flatMap { URL(string: $0) }

        return Landmark(
            id: "\(result.pageid)",
            title: result.title,
            summary: summary.extract,
            coordinate: landmarkCoord,
            wikipediaURL: pageURL,
            distance: distance,
            bearing: bearing
        )
    }
}

// MARK: - CLLocationCoordinate2D Bearing Extension
// Math to calculate the compass direction from one GPS point to another

extension CLLocationCoordinate2D {
    /// Returns the bearing in degrees (0 = North, 90 = East, 180 = South, 270 = West)
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let fromLat = latitude.toRadians()
        let fromLon = longitude.toRadians()
        let toLat = destination.latitude.toRadians()
        let toLon = destination.longitude.toRadians()

        let dLon = toLon - fromLon
        let y = sin(dLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLon)

        let bearing = atan2(y, x).toDegrees()
        // Normalize to 0–360
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {
    func toRadians() -> Double { self * .pi / 180 }
    func toDegrees() -> Double { self * 180 / .pi }
}
