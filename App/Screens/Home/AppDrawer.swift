import SwiftUI

struct AppDrawerView: View {
    @Environment(AppRouter.self) private var router
    @State private var settings = AppSettings.shared
    @State private var page = 0

    private let columns = 3
    private let rows = 2
    private let spacing: CGFloat = 14

    private var perPage: Int { columns * rows }

    private var pages: [[HomeApp]] {
        let apps = settings.homeApps
        guard !apps.isEmpty else { return [[]] }
        return stride(from: 0, to: apps.count, by: perPage).map {
            Array(apps[$0 ..< min($0 + perPage, apps.count)])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let outer: CGFloat = 24
            let topPad: CGFloat = 16
            let titleHeight: CGFloat = 38
            let dotsHeight: CGFloat = pages.count > 1 ? 22 : 0
            let controlsGap: CGFloat = pages.count > 1 ? 18 : 0
            let availH = geo.size.height - topPad - titleHeight - dotsHeight - controlsGap
            let tileByWidth = (geo.size.width - outer * 2 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let tileByHeight = (availH - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let tile = max(64, min(tileByWidth, tileByHeight))
            let gridHeight = tile * CGFloat(rows) + spacing * CGFloat(rows - 1)

            VStack(spacing: 0) {
                topTitle("Apps")
                    .padding(.horizontal, outer)
                    .padding(.top, topPad)
                    .frame(height: topPad + titleHeight)

                ZStack {
                    TabView(selection: $page) {
                        ForEach(pages.indices, id: \.self) { index in
                            grid(pages[index], tile: tile).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if pages.count > 1 {
                        HStack {
                            pageArrow("chevron.left", enabled: page > 0) { page -= 1 }
                            Spacer()
                            pageArrow("chevron.right", enabled: page < pages.count - 1) { page += 1 }
                        }
                    }
                }
                .frame(height: gridHeight)

                if pages.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == page ? CarTheme.primaryText : CarTheme.tertiaryText)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.top, controlsGap)
                    .frame(height: dotsHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onChange(of: pages.count) { _, count in
            if page >= count { page = max(0, count - 1) }
        }
    }

    private func grid(_ apps: [HomeApp], tile: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(tile), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(apps) { app in
                Button { open(app) } label: {
                    tileView(app)
                        .frame(width: tile, height: tile)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tileView(_ app: HomeApp) -> some View {
        VStack(spacing: 10) {
            Image(systemName: app.icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(app.color)
            Text(app.title)
                .font(CarTheme.rounded(15, .medium))
                .foregroundStyle(CarTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CarTheme.field.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
    }

    private func pageArrow(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(enabled ? CarTheme.primaryText : CarTheme.tertiaryText.opacity(0.4))
                .frame(width: 34, height: 34)
                .background(Circle().fill(CarTheme.field.opacity(0.85)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func open(_ app: HomeApp) {
        if let raw = app.screen, let screen = AppScreen(rawValue: raw) {
            router.navigate(to: screen)
        } else {
            app.open()
        }
    }
}