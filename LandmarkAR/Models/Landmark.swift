import CoreLocation
import Foundation

// MARK: - Landmark Model
// Represents a single point of interest (natural landmark, historic site, etc.)

struct Landmark: Identifiable {
    let id: String           // Unique Wikipedia page ID
    let title: String        // Display name
    let summary: String      // Short description from Wikipedia
    let coordinate: CLLocationCoordinate2D  // Lat/long of the landmark
    let wikipediaURL: URL?   // Link to full Wikipedia article

    // Calculated at runtime — filled in after we know the user's location
    var distance: CLLocationDistance = 0   // Meters from user
    var bearing: Double = 0                // Degrees (0=North, 90=East, etc.)
}

// MARK: - Wikipedia API Response Models
// These structs map directly to the JSON returned by the Wikipedia GeoSearch API

struct WikipediaGeoSearchResponse: Codable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Codable {
    let geosearch: [WikipediaGeoResult]
}

struct WikipediaGeoResult: Codable {
    let pageid: Int
    let title: String
    let lat: Double
    let lon: Double
    let dist: Double    // Distance in meters (provided by Wikipedia)
}

// MARK: - Wikipedia Summary Response
// Used when we fetch a short description for each landmark

struct WikipediaSummaryResponse: Codable {
    let extract: String   // Plain-text summary paragraph
    let content_urls: WikipediaContentURLs?
}

struct WikipediaContentURLs: Codable {
    let desktop: WikipediaDesktopURL?
}

struct WikipediaDesktopURL: Codable {
    let page: String?
}
