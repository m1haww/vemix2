import Foundation

struct VideoCategory: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let videos: [VideoItem]
    let isPortrait: Bool

    init(title: String, subtitle: String, videos: [VideoItem], isPortrait: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.videos = videos
        self.isPortrait = isPortrait
    }

    static func == (lhs: VideoCategory, rhs: VideoCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

struct VideoItem: Equatable {
    let fileName: String
    let displayTitle: String
}

extension VideoCategory {
    static let categories: [VideoCategory] = [
        VideoCategory(
            title: "Bigfoot",
            subtitle: "Mysterious creature sightings",
            videos: [
                VideoItem(fileName: "bigfoot1", displayTitle: "Bigfoot Vlog Day"),
                VideoItem(fileName: "bigfoot2", displayTitle: "Jungle Encounter"),
                VideoItem(fileName: "bigfoot3", displayTitle: "Yoga With Sasquatch")
            ]
        ),
        VideoCategory(
            title: "Sirena",
            subtitle: "Underwater beauty",
            videos: [
                VideoItem(fileName: "sirena1", displayTitle: "Ocean Dream"),
                VideoItem(fileName: "sirena2", displayTitle: "Aqua Dance"),
                VideoItem(fileName: "sirena3", displayTitle: "Crystal Waters"),
                VideoItem(fileName: "sirena4", displayTitle: "Mermaid Lagoon")
            ],
            isPortrait: true
        ),
        VideoCategory(
            title: "Interviews",
            subtitle: "Conversations with people",
            videos: [
                VideoItem(fileName: "interview1", displayTitle: "Street Talk"),
                VideoItem(fileName: "interview2", displayTitle: "Beach Chat"),
                VideoItem(fileName: "interview3", displayTitle: "City Opinions")
            ]
        ),
        VideoCategory(
            title: "Portraits",
            subtitle: "Lifestyle photography",
            videos: [
                VideoItem(fileName: "girl1", displayTitle: "Golden Hour"),
                VideoItem(fileName: "girl2", displayTitle: "City Lights"),
                VideoItem(fileName: "girl3", displayTitle: "Nature Walk"),
                VideoItem(fileName: "girl4", displayTitle: "Coffee Time"),
                VideoItem(fileName: "girl5", displayTitle: "Beach Vibes"),
                VideoItem(fileName: "girl6", displayTitle: "Night Out")
            ],
            isPortrait: true
        ),
        VideoCategory(
            title: "Reports",
            subtitle: "Live news coverage",
            videos: [
                VideoItem(fileName: "report1", displayTitle: "Breaking News Update"),
                VideoItem(fileName: "report2", displayTitle: "Field Report Live"),
                VideoItem(fileName: "report3", displayTitle: "Granny's Sports Car Joyride")
            ]
        ),
        VideoCategory(
            title: "Fantasy",
            subtitle: "Magical worlds",
            videos: [
                VideoItem(fileName: "fantasy1", displayTitle: "Dragon Realm"),
                VideoItem(fileName: "fantasy2", displayTitle: "Fairy Garden"),
                VideoItem(fileName: "fantasy3", displayTitle: "Magic Castle"),
                VideoItem(fileName: "fantasy4", displayTitle: "Enchanted Forest")
            ],
            isPortrait: true
        )
    ]

    static func category(for title: String) -> VideoCategory? {
        return categories.first { $0.title.lowercased() == title.lowercased() }
    }
}
