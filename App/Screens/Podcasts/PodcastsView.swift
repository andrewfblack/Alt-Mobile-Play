import SwiftUI

private struct PodcastShow: Identifiable {
    let id = UUID()
    let title: String
    let host: String
    let colorIndex: Int
    let icon: String
    let episodes: [PodcastEpisode]

    var color: Color { CarTheme.palette[colorIndex % CarTheme.palette.count] }
}

private struct PodcastEpisode: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let progress: Double // 0.0 to 1.0
}

private let sampleShows: [PodcastShow] = [
    PodcastShow(
        title: "Morning Drive",
        host: "Sarah & James",
        colorIndex: 4,
        icon: "sun.max.fill",
        episodes: [
            PodcastEpisode(title: "Traffic Update", duration: "12 min", progress: 0.6),
            PodcastEpisode(title: "Local News Roundup", duration: "18 min", progress: 0.0),
            PodcastEpisode(title: "Weather Forecast", duration: "5 min", progress: 0.0),
        ]
    ),
    PodcastShow(
        title: "Tech Today",
        host: "Mike Chen",
        colorIndex: 0,
        icon: "laptopcomputer",
        episodes: [
            PodcastEpisode(title: "AI in Cars", duration: "32 min", progress: 0.45),
            PodcastEpisode(title: "EV Market Update", duration: "24 min", progress: 0.0),
            PodcastEpisode(title: "App of the Week", duration: "8 min", progress: 0.0),
        ]
    ),
    PodcastShow(
        title: "True Crime Stories",
        host: "Jessica Miller",
        colorIndex: 1,
        icon: "eyebrow",
        episodes: [
            PodcastEpisode(title: "The Missing Case", duration: "45 min", progress: 0.2),
            PodcastEpisode(title: "Evidence Found", duration: "38 min", progress: 0.0),
            PodcastEpisode(title: "The Reveal", duration: "52 min", progress: 0.0),
        ]
    ),
    PodcastShow(
        title: "Comedy Hour",
        host: "Various",
        colorIndex: 3,
        icon: "theatermasks.fill",
        episodes: [
            PodcastEpisode(title: "Best of 2024", duration: "55 min", progress: 0.0),
            PodcastEpisode(title: "Road Trip Special", duration: "40 min", progress: 0.0),
        ]
    ),
]

struct PodcastsView: View {
    @Environment(AppRouter.self) private var router
    @State private var selectedShow: PodcastShow?

    var body: some View {
        GeometryReader { geo in
            let listWidth = max(220, min(320, geo.size.width * 0.34))
            VStack(spacing: 0) {
                topTitle("Podcasts")
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                HStack(alignment: .top, spacing: 20) {
                    // Shows list
                    ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sampleShows) { show in
                            Button { selectedShow = show } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: show.icon)
                                        .font(.system(size: 24))
                                        .foregroundStyle(show.color)
                                        .frame(width: 44, height: 44)
                                        .background(show.color.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(show.title)
                                            .font(CarTheme.rounded(18, .semibold))
                                            .foregroundStyle(CarTheme.primaryText)
                                            .lineLimit(1)
                                        Text(show.host)
                                            .font(CarTheme.rounded(14))
                                            .foregroundStyle(CarTheme.secondaryText)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(selectedShow?.id == show.id ? CarTheme.accent.opacity(0.12) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(width: listWidth)

                // Episodes
                if let show = selectedShow {
                    episodeList(show)
                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(CarTheme.tertiaryText)
                        Text("Select a show")
                            .font(CarTheme.rounded(20))
                            .foregroundStyle(CarTheme.tertiaryText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .onAppear { if selectedShow == nil { selectedShow = sampleShows.first } }
    }
}

    private func episodeList(_ show: PodcastShow) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(show.episodes) { ep in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ep.title)
                                .font(CarTheme.rounded(20, .semibold))
                                .foregroundStyle(CarTheme.primaryText)
                                .lineLimit(2)
                            Text(ep.duration)
                                .font(CarTheme.rounded(16))
                                .foregroundStyle(CarTheme.secondaryText)
                            if ep.progress > 0 {
                                ProgressView(value: ep.progress)
                                    .tint(show.color)
                            }
                        }
                        Spacer()
                        Button { } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(show.color.opacity(ep.progress > 0 ? 1.0 : 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 14)
                    if ep.id != show.episodes.last?.id {
                        Divider().background(CarTheme.tertiaryText.opacity(0.3))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
