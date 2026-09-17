import SwiftUI
import MediaPlayer

struct SystemVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.tintColor = UIColor(CarTheme.accent)
        view.showsVolumeSlider = true
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
