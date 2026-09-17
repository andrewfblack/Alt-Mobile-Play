import SwiftUI
import UIKit

/// A native, accessible slider with a smaller thumb and a full-height touch area.
struct PlaybackSlider: UIViewRepresentable {
    @Binding var value: Double
    let duration: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        let thumb = UIGraphicsImageRenderer(size: CGSize(width: 18, height: 18)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: 16, height: 16)).fill()
        }
        slider.setThumbImage(thumb, for: .normal)
        slider.setThumbImage(thumb, for: .highlighted)
        slider.accessibilityLabel = "Playback position"
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }

    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.parent = self
        slider.maximumValue = Float(duration)
        if !slider.isTracking { slider.value = Float(value) }
        slider.minimumTrackTintColor = UIColor(CarTheme.accent)
        slider.maximumTrackTintColor = UIColor(CarTheme.secondaryText.opacity(0.25))
        slider.isEnabled = context.environment.isEnabled
    }

    final class Coordinator: NSObject {
        var parent: PlaybackSlider
        init(_ parent: PlaybackSlider) { self.parent = parent }

        @objc func changed(_ sender: UISlider) {
            parent.value = Double(sender.value)
        }
    }
}
