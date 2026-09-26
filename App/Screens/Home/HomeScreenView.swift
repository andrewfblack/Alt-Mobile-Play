import SwiftUI

struct HomeScreenView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        GeometryReader { geo in
            let contentWidth = min(geo.size.width, 1100)
            let contentHeight = min(geo.size.height, 680)
            let slotWidth = (contentWidth - 16) / 2
            HStack(spacing: 16) {
                widgetSlot(0)
                    .frame(width: slotWidth, height: contentHeight)
                widgetSlot(1)
                    .frame(width: slotWidth, height: contentHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .onAppear { settings.apply() }
    }

    private func widgetSlot(_ index: Int) -> some View {
        let kind = settings.homeWidgets.count > index ? settings.homeWidgets[index] : .nowPlaying
        return HomeWidgetView(kind: kind)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .tileBackground()
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .contextMenu {
                ForEach(HomeWidgetKind.allCases) { option in
                    Button {
                        settings.setWidget(option, at: index)
                    } label: {
                        Label(option.title, systemImage: option == kind ? "checkmark" : option.icon)
                    }
                }
            }
            .accessibilityHint("Touch and hold to change this widget")
    }
}
