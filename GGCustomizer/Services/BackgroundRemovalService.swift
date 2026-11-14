import Foundation
import UIKit

#if canImport(CoreImage) && canImport(Vision)
import CoreImage
import Vision
#endif

enum BackgroundRemovalError: LocalizedError {
    case unavailable
    case invalidImage
    case noForegroundDetected
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .unavailable: return "On-device background removal requires iOS 17 or later."
        case .invalidImage: return "This image could not be prepared for background removal."
        case .noForegroundDetected: return "No clear foreground subject was found. Try a photo with more separation."
        case .renderingFailed: return "The foreground mask could not be rendered."
        }
    }
}

enum BackgroundRemovalService {
    static var isAvailable: Bool {
        #if canImport(CoreImage) && canImport(Vision)
        if #available(iOS 17.0, *) { return true }
        #endif
        return false
    }

    /// Uses Apple's Vision foreground mask locally. The source image is never uploaded.
    static func removeBackground(from image: UIImage) throws -> UIImage {
        #if canImport(CoreImage) && canImport(Vision)
        guard let cgImage = image.cgImage else { throw BackgroundRemovalError.invalidImage }
        if #available(iOS 17.0, *) {
            return try removeBackground(from: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        #endif
        throw BackgroundRemovalError.unavailable
    }

    #if canImport(CoreImage) && canImport(Vision)
    @available(iOS 17.0, *)
    private static func removeBackground(from cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) throws -> UIImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
            throw BackgroundRemovalError.noForegroundDetected
        }
        let maskBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        let source = CIImage(cgImage: cgImage)
        let transparent = CIImage(color: .clear).cropped(to: source.extent)
        let output = source.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: transparent,
            kCIInputMaskImageKey: CIImage(cvPixelBuffer: maskBuffer)
        ])
        let context = CIContext(options: nil)
        guard let rendered = context.createCGImage(output, from: source.extent) else {
            throw BackgroundRemovalError.renderingFailed
        }
        return UIImage(cgImage: rendered, scale: scale, orientation: orientation)
    }
    #endif
}
