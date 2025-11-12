import Foundation

struct VideoPreset: Identifiable, Equatable {
    let id = UUID()
    let videoAssetName: String
    let title: String
    let prompt: String
    let style: String
    let category: PresetCategory
    let isPortrait: Bool

    init(videoAssetName: String, title: String, prompt: String, style: String, category: PresetCategory, isPortrait: Bool = false) {
        self.videoAssetName = videoAssetName
        self.title = title
        self.prompt = prompt
        self.style = style
        self.category = category
        self.isPortrait = isPortrait
    }

    static func == (lhs: VideoPreset, rhs: VideoPreset) -> Bool {
        return lhs.id == rhs.id
    }
}

enum PresetCategory: String, CaseIterable {
    case bigfoot = "Bigfoot"
    case interviews = "Interviews"
    case reports = "Reports"
    case sirena = "Sirena"
    case portraits = "Portraits"
    case fantasy = "Fantasy"
    case custom = "Custom"
}

extension VideoPreset {
    static let presets: [VideoPreset] = [
        VideoPreset(
            videoAssetName: "bigfoot1",
            title: "Bigfoot Vlog Day",
            prompt: "A mysterious forest vlog where the camera unexpectedly captures a close-up encounter with Bigfoot. Handheld, personal vlogger style, misty forest atmosphere, slight camera shake, Bigfoot reacts to being filmed, dramatic lighting",
            style: "Vlog",
            category: .bigfoot
        ),
        VideoPreset(
            videoAssetName: "bigfoot2",
            title: "Jungle Encounter",
            prompt: "Drone footage captures shocking Bigfoot encounter in jungle, creature swats drone mid-air, intense close-up reaction",
            style: "Documentary",
            category: .bigfoot
        ),
        VideoPreset(
            videoAssetName: "bigfoot3",
            title: "Yoga With Sasquatch",
            prompt: "A peaceful yoga session is humorously interrupted when Bigfoot joins the class, blending serene stretches with chaotic charm in a bright studio setting",
            style: "Lifestyle",
            category: .bigfoot
        ),
        VideoPreset(
            videoAssetName: "interview1",
            title: "Street Talk",
            prompt: "Street interviews on busy city boulevard, asking locals about trending topics",
            style: "News",
            category: .interviews
        ),
        VideoPreset(
            videoAssetName: "interview2",
            title: "Beach Chat",
            prompt: "Beachside interviews with tourists and locals on sunny beach",
            style: "Documentary",
            category: .interviews
        ),
        VideoPreset(
            videoAssetName: "interview3",
            title: "City Opinions",
            prompt: "Funny mock interview with dog answering questions on sidewalk",
            style: "Lifestyle",
            category: .interviews
        ),
        VideoPreset(
            videoAssetName: "report1",
            title: "Breaking News Update",
            prompt: "On-the-ground reporter delivers urgent breaking news amid chaotic construction protest in urban neighborhood, shot in dynamic handheld news footage style",
            style: "News",
            category: .reports
        ),
        VideoPreset(
            videoAssetName: "report2",
            title: "Field Report Live",
            prompt: "TV reporter standing near street disaster site with serious tone",
            style: "Journalism",
            category: .reports
        ),
        VideoPreset(
            videoAssetName: "report3",
            title: "Granny's Sports Car Joyride",
            prompt: "Wholesome and hilarious street interview with an elderly woman driving a bright green Lamborghini through the city, cheerful crowd reactions, spontaneous joyride energy, cinematic vlog style",
            style: "Broadcast",
            category: .reports
        ),
        VideoPreset(
            videoAssetName: "sirena1",
            title: "Ocean Dream",
            prompt: "Ethereal slow-motion scene of a graceful woman swimming underwater in crystal-clear blue ocean. Her flowing blonde hair drifts gently, shimmering with sunlight. She glides like a mermaid with elegance and poise, surrounded by soft bubbles and sparkles. Magical, dreamy, cinematic underwater beauty aesthetic.",
            style: "Fantasy",
            category: .sirena,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "sirena2",
            title: "Aqua Dance",
            prompt: "Graceful lakeside mermaid transformation as she emerges from a secret underwater realm to relax on land",
            style: "Artistic",
            category: .sirena,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "sirena3",
            title: "Crystal Waters",
            prompt: "Tranquil underwater scene of a mermaid gliding gracefully through sunlit turquoise water, her flowing hair suspended and shimmering scales sparkling as sunlight filters from above",
            style: "Performance",
            category: .sirena,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "sirena4",
            title: "Mermaid Lagoon",
            prompt: "Mystical underwater ballet in a glowing mermaid lagoon, shimmering with light and motion",
            style: "Fantasy",
            category: .sirena,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl1",
            title: "Golden Hour",
            prompt: "Confident lifestyle video of a blonde woman in a black outfit posing gracefully indoors during daylight, filmed in portrait mode with soft natural lighting",
            style: "Portrait",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl2",
            title: "City Lights",
            prompt: "Stylish indoor fashion pose with confident energy and natural daylight",
            style: "Cinematic",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl3",
            title: "Nature Walk",
            prompt: "Confident indoor dance performance with natural lighting and casual outfit",
            style: "Lifestyle",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl4",
            title: "Coffee Time",
            prompt: "Energetic late-night dance rehearsal under neon purple lights in underground studio",
            style: "Lifestyle",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl5",
            title: "Beach Vibes",
            prompt: "Stylish girl filming casual dance at home, warm lighting, confident energy",
            style: "Travel",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "girl6",
            title: "Night Out",
            prompt: "Stylish girl dancing confidently indoors with low lighting, evening vibe",
            style: "Fashion",
            category: .portraits,
            isPortrait: true
        ),
        VideoPreset(
            videoAssetName: "fantasy1",
            title: "Dragon Realm",
            prompt: "Majestic fantasy scene with a glowing priestess summoning light atop a rocky cliff, dramatic skies and magical atmosphere",
            style: "Fantasy",
            category: .fantasy
        ),
        VideoPreset(
            videoAssetName: "fantasy2",
            title: "Fairy Garden",
            prompt: "Mythical woman basking in heavenly light as storm clouds part above ancient cliffs",
            style: "Fantasy",
            category: .fantasy
        ),
        VideoPreset(
            videoAssetName: "fantasy3",
            title: "Magic Castle",
            prompt: "Fantasy queen bathed in ethereal light atop ancient mountain ridge, hands raised as glowing beams pierce stormy skies – cinematic divine ascension mood",
            style: "Fantasy",
            category: .fantasy
        ),
        VideoPreset(
            videoAssetName: "fantasy4",
            title: "Enchanted Forest",
            prompt: "Close-up of magical girl with sparkles and dreamy forest atmosphere around her",
            style: "Fantasy",
            category: .fantasy
        )
    ]

    static func preset(for videoName: String) -> VideoPreset? {
        return presets.first { $0.videoAssetName == videoName }
    }
}
