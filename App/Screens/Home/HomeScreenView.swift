import SwiftUI

struct HomeScreenView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        GeometryReader { geo in
            let slotWidth = (geo.size.width - 24) / 2
            HStack(spacing: 24) {
                widgetSlot(0)
                    .frame(width: slotWidth, height: geo.size.height)
                widgetSlot(1)
                    .frame(width: slotWidth, height: geo.size.height)
            }
        }
        .padding(24)
        .onAppear { settings.apply() }
    }

    private func widgetSlot(_ index: Int) -> some View {
        let kind = settings.homeWidgets.count > index ? settings.homeWidgets[index] : .nowPlaying
        return ZStack(alignment: .topTrailing) {
            HomeWidgetView(kind: kind)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            Menu {
                ForEach(HomeWidgetKind.allCases) { option in
                    Button {
                        settings.setWidget(option, at: index)
                    } label: {
                        Label(option.title, systemImage: option == kind ? "checkmark" : option.icon)
                    }
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CarTheme.tertiaryText)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CarTheme.background.opacity(0.55)))
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .tileBackground()
        .contentShape(Rectangle())
    }
}