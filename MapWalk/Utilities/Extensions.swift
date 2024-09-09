//
//  Extensions.swift
//  MapWalkSwift
//
//  Created by MyMac on 12/09/23.
//

import UIKit
import CoreLocation
import CoreGraphics
import MapKit
import simd
import AVFoundation

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        var topViewController: UIViewController? = nil
        if #available(iOS 13, *) {
            for scene in self.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        if window.isKeyWindow {
                            topViewController = window.rootViewController
                        }
                    }
                }
            }
        } else {
            topViewController = keyWindow?.rootViewController
        }
        while true {
            if let presented = topViewController?.presentedViewController {
                topViewController = presented
            } else if let navController = topViewController as? UINavigationController {
                topViewController = navController.topViewController
            } else if let tabBarController = topViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                // Handle any other third party container in `else if` if required
                break
            }
        }
        return topViewController
    }
}

extension UIView {
    //func roundCorners(_ corners: UIRectCorner, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
        
        let borderLayer = CAShapeLayer()
        borderLayer.path = path.cgPath
        //borderLayer.lineWidth = borderWidth
        //borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)
    }
}

extension MKAnnotationView {

    func loadCustomLines(customLines: [String]) {
        let stackView = self.stackView()
        for line in customLines {
            let label = UILabel()
            label.text = line
            label.numberOfLines = 0
            stackView.addArrangedSubview(label)
        }
        self.detailCalloutAccessoryView = stackView
    }

    private func stackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }
}

extension UIViewController {
    func showAlert(title: String, message: String, okActionTitle: String, completion:@escaping (_ result:Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { action in
            completion(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { action in
            completion(false)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func showAlert(title: String? = "Oops!", message: String? = "Something went wrong, please try again later!") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    public func checkCameraPermission(completion: @escaping ((Bool) -> Void)) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .authorized:
            completion(true)
        case .restricted, .denied:
            completion(false)
        @unknown default:
            completion(false)
            break
        }
    }
    
    public func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }

        var parameters = [String: String]()
        for queryItem in queryItems {
            if let value = queryItem.value {
                parameters[queryItem.name] = value
            }
        }

        return parameters
    }
}

@IBDesignable
extension UIView {
    @IBInspectable var CornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var BorderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
            self.layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var BorderColor: UIColor {
        get {
            return self.BorderColor
        } set {
            self.layer.borderColor = newValue.cgColor
            
        }
    }
    
    @IBInspectable var Round: Bool {
        get {
            return false
        } set {
            if newValue {
                self.layer.cornerRadius = self.frame.size.height/2
                self.layer.masksToBounds = true
            }
            
        }
    }
}

extension String {
    func toCoordinate() -> CLLocationCoordinate2D {
        // Remove curly braces and split the string by comma
        let cleanedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
        let components = cleanedString.split(separator: ",")
        
        // Check if we have exactly two components
        guard components.count == 2,
              let latitude = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
            return kCLLocationCoordinate2DInvalid
        }
        
        // Return CLLocationCoordinate2D instance
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func toCGAffineTransform() -> CGAffineTransform? {
        // Regular expression to match the components of CGAffineTransform
        let regexPattern = #"CGAffineTransform\(a: ([\d.-]+), b: ([\d.-]+), c: ([\d.-]+), d: ([\d.-]+), tx: ([\d.-]+), ty: ([\d.-]+)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return nil
        }
        
        guard let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) else {
            return nil
        }
        
        let nsString = self as NSString
        guard let a = Double(nsString.substring(with: match.range(at: 1))),
              let b = Double(nsString.substring(with: match.range(at: 2))),
              let c = Double(nsString.substring(with: match.range(at: 3))),
              let d = Double(nsString.substring(with: match.range(at: 4))),
              let tx = Double(nsString.substring(with: match.range(at: 5))),
              let ty = Double(nsString.substring(with: match.range(at: 6))) else {
            return nil
        }
        
        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }
}

extension UIImage {
    /// Flips the image either vertically, horizontally, or both.
    /// - Parameters:
    ///   - flipVertically: A Boolean value indicating whether to flip the image vertically.
    ///   - flipHorizontally: A Boolean value indicating whether to flip the image horizontally.
    /// - Returns: A new `UIImage` instance with the specified flip transformations applied.
    func flip(flipVertically: Bool, flipHorizontally: Bool) -> UIImage {
        var transform = CGAffineTransform.identity
        
        if flipVertically {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        
        if flipHorizontally {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        return applyTransform(transform)
    }
    
    private func applyTransform(_ transform: CGAffineTransform) -> UIImage {
        let size = self.size
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        // Translate context to center, apply transformation, then translate back
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.concatenate(transform)
        context.translateBy(x: -size.width / 2, y: -size.height / 2)
        
        // Draw the image
        self.draw(in: CGRect(origin: .zero, size: size))
        
        let transformedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return transformedImage ?? self
    }
}

// MARK: - simd_float4x4
extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1.0)
    }
}
