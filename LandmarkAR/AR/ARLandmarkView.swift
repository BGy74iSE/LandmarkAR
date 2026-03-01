import ARKit
import CoreLocation
import RealityKit
import SwiftUI
import UIKit

// MARK: - ARLandmarkView
// SwiftUI wrapper around our UIKit ARViewController.
// (ARKit requires UIKit, so we bridge using UIViewControllerRepresentable)

struct ARLandmarkView: UIViewControllerRepresentable {
    let landmarks: [Landmark]
    let userLocation: CLLocation?
    let heading: CLHeading?
    @Binding var selectedLandmark: Landmark?

    func makeUIViewController(context: Context) -> ARLandmarkViewController {
        ARLandmarkViewController()
    }

    func updateUIViewController(_ vc: ARLandmarkViewController, context: Context) {
        // Called whenever landmarks, location, or heading changes
        vc.update(landmarks: landmarks, userLocation: userLocation, heading: heading) { landmark in
            selectedLandmark = landmark
        }
    }
}

// MARK: - ARLandmarkViewController
// The main AR view controller. Handles ARSession + floating label placement.

class ARLandmarkViewController: UIViewController, ARSessionDelegate {

    // ARView is RealityKit's main rendering view (built on top of ARKit)
    private var arView: ARView!

    // We keep track of label views so we can update/remove them
    private var labelViews: [String: LandmarkLabelView] = [:]  // keyed by landmark ID

    // Current state passed in from SwiftUI
    private var landmarks: [Landmark] = []
    private var userLocation: CLLocation?
    private var heading: CLHeading?
    private var onSelect: ((Landmark) -> Void)?

    // How often to update label positions (every N frames)
    private var frameCount = 0
    private let updateInterval = 30  // update every 30 frames (~0.5 seconds at 60fps)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

    // MARK: - Setup

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        // World tracking: uses camera + IMU to track device position/orientation
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading  // CRITICAL: aligns AR world with compass north
        arView.session.run(config)
        arView.session.delegate = self
    }

    // MARK: - Update from SwiftUI

    func update(landmarks: [Landmark],
                userLocation: CLLocation?,
                heading: CLHeading?,
                onSelect: @escaping (Landmark) -> Void) {
        self.landmarks = landmarks
        self.userLocation = userLocation
        self.heading = heading
        self.onSelect = onSelect
        refreshLabels()
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCount += 1
        guard frameCount % updateInterval == 0 else { return }
        refreshLabels()
    }

    // MARK: - Label Placement
    // This is the core of the app: converting GPS coordinates to AR screen positions.

    private func refreshLabels() {
        guard let userLocation = userLocation,
              let arFrame = arView.session.currentFrame else { return }

        let cameraTransform = arFrame.camera.transform
        let projectionMatrix = arFrame.camera.projectionMatrix(
            for: .landscapeRight,
            viewportSize: arView.bounds.size,
            zNear: 0.1,
            zFar: 1000
        )

        for landmark in landmarks {
            // Convert the landmark's GPS position to an AR world-space position
            guard let worldPosition = worldPosition(for: landmark, relativeTo: userLocation) else { continue }

            // Project 3D world position to 2D screen coordinates
            guard let screenPoint = project(worldPosition,
                                            camera: cameraTransform,
                                            projection: projectionMatrix,
                                            viewSize: arView.bounds.size) else {
                // Landmark is behind the camera — hide its label
                labelViews[landmark.id]?.isHidden = true
                continue
            }

            // Show or create the label at the screen position
            showLabel(for: landmark, at: screenPoint)
        }
    }

    /// Converts a GPS coordinate to a 3D position in ARKit world space.
    /// ARKit uses meters; we use the bearing and distance to place a point
    /// in the correct compass direction at a fixed "display distance" from camera.
    private func worldPosition(for landmark: Landmark, relativeTo userLocation: CLLocation) -> SIMD3<Float>? {
        let bearing = landmark.bearing
        let bearingRad = Float(bearing.toRadians())

        // We place the label at a fixed distance regardless of actual distance
        // (so distant mountains still have visible labels)
        let displayDistance: Float = 80  // meters in AR world space

        // Convert polar (bearing + distance) to Cartesian (x, z)
        // In ARKit with gravityAndHeading: X = East, Z = South, Y = Up
        let x = displayDistance * sin(bearingRad)
        let z = -displayDistance * cos(bearingRad)  // negative = forward (north)
        let y: Float = 0  // same height as camera (eye level)

        return SIMD3<Float>(x, y, z)
    }

    /// Projects a 3D world-space point to 2D screen coordinates.
    /// Returns nil if the point is behind the camera.
    private func project(_ worldPoint: SIMD3<Float>,
                         camera: float4x4,
                         projection: float4x4,
                         viewSize: CGSize) -> CGPoint? {

        // Transform world point into camera (view) space
        let worldPoint4 = SIMD4<Float>(worldPoint.x, worldPoint.y, worldPoint.z, 1)
        let viewSpace = camera.inverse * worldPoint4

        // If z > 0 the point is behind the camera (ARKit uses right-handed coords)
        guard viewSpace.z < 0 else { return nil }

        // Apply projection matrix to get clip space
        let clipSpace = projection * viewSpace
        guard clipSpace.w != 0 else { return nil }

        // Perspective divide → NDC (-1 to 1)
        let ndc = SIMD2<Float>(clipSpace.x / clipSpace.w, clipSpace.y / clipSpace.w)

        // Convert NDC to screen pixels
        let screenX = CGFloat((ndc.x + 1) / 2) * viewSize.width
        let screenY = CGFloat((1 - ndc.y) / 2) * viewSize.height  // flip Y axis

        return CGPoint(x: screenX, y: screenY)
    }

    // MARK: - Label UI

    private func showLabel(for landmark: Landmark, at point: CGPoint) {
        // Clamp to screen edges so labels don't fly off screen
        let padding: CGFloat = 80
        let clampedX = max(padding, min(arView.bounds.width - padding, point.x))
        let clampedY = max(padding, min(arView.bounds.height - padding, point.y))
        let clampedPoint = CGPoint(x: clampedX, y: clampedY)

        if let existingLabel = labelViews[landmark.id] {
            // Update position of existing label
            existingLabel.isHidden = false
            existingLabel.center = clampedPoint
        } else {
            // Create a new label view
            let label = LandmarkLabelView(landmark: landmark)
            label.center = clampedPoint
            label.onTap = { [weak self] in
                self?.onSelect?(landmark)
            }
            arView.addSubview(label)
            labelViews[landmark.id] = label
        }
    }
}

// MARK: - LandmarkLabelView
// The floating label that appears in AR for each nearby landmark.

class LandmarkLabelView: UIView {

    var onTap: (() -> Void)?
    private let landmark: Landmark

    init(landmark: Landmark) {
        self.landmark = landmark
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // Semi-transparent dark pill background
        backgroundColor = UIColor.black.withAlphaComponent(0.65)
        layer.cornerRadius = 12
        layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        layer.borderWidth = 1

        // Stack: name label on top, distance below
        let nameLabel = UILabel()
        nameLabel.text = landmark.title
        nameLabel.textColor = .white
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center

        let distanceLabel = UILabel()
        let distanceText = formatDistance(landmark.distance)
        distanceLabel.text = "📍 \(distanceText)"
        distanceLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        distanceLabel.font = UIFont.systemFont(ofSize: 11)
        distanceLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [nameLabel, distanceLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])

        // Size the view to fit its content
        let targetWidth: CGFloat = 150
        nameLabel.preferredMaxLayoutWidth = targetWidth - 20
        let size = stack.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        )
        frame = CGRect(origin: .zero, size: CGSize(width: targetWidth, height: size.height + 16))

        // Tap to see detail
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func tapped() {
        onTap?()
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        }
    }
}
