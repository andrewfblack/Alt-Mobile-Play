import SwiftUI

struct VolumePopup: View {
    @Binding var isPresented: Bool
    let barWidth: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(CarTheme.accent)
                    Text("Volume")
                        .font(CarTheme.rounded(22, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CarTheme.primaryText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(CarTheme.field.opacity(0.85)))
                    }
                    .buttonStyle(.plain)
                }

                SystemVolumeView()
                    .frame(height: 44)

                Text("Device output volume")
                    .font(CarTheme.rounded(15))
                    .foregroundStyle(CarTheme.secondaryText)
            }
            .padding(24)
            .frame(width: 460)
            .background(CarTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
.overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(CarTheme.primaryText.opacity(0.12), lineWidth: 1)
                )
            .padding(.leading, barWidth)
        }
        .transition(.opacity)
    }
}
