import UIKit

enum OrientationMode: String {
    case portrait
    case landscape
    case auto
}

final class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    @Published var mode: OrientationMode = .auto

    private init() {}

    func setOrientation(_ mode: OrientationMode) {
        self.mode = mode
        switch mode {
        case .auto:
            // Let system handle rotations
            break
        case .portrait:
            force(.portrait)
        case .landscape:
            force(.landscapeRight)
        }
    }

    private func force(_ orientation: UIInterfaceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
}

