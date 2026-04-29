import SwiftUI
import UIKit

/// One-shot helper to render `AppIconDesign` to a 1024×1024 PNG and write it to
/// the app's Documents directory. Use the dev tool in Settings to trigger,
/// then drop the PNG into `Assets.xcassets/AppIcon.appiconset/`.
@MainActor
enum AppIconExporter {
    static func exportIcon() -> String? {
        let renderer = ImageRenderer(content: AppIconDesign())
        renderer.scale = 1.0  // canvas is already 1024×1024
        guard let cgImage = renderer.cgImage else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.pngData() else { return nil }
        guard let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("NeonMahjong-AppIcon-1024.png")
        else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            return nil
        }
    }
}
