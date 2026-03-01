import SwiftUI

// MARK: - LandmarkDetailSheet
// Shown when the user taps a floating label in AR.
// Displays the Wikipedia summary + a link to the full article.

struct LandmarkDetailSheet: View {
    let landmark: Landmark
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Distance badge
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(formattedDistance)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    Divider()

                    // Wikipedia summary text
                    Text(landmark.summary)
                        .font(.body)
                        .lineSpacing(4)

                    Divider()

                    // Link to full Wikipedia article
                    if let url = landmark.wikipediaURL {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Read full article on Wikipedia")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(landmark.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var formattedDistance: String {
        let meters = landmark.distance
        if meters < 1000 {
            return "\(Int(meters)) meters away"
        } else {
            return String(format: "%.1f km away", meters / 1000)
        }
    }
}
