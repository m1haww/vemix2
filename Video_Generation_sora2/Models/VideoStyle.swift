import Foundation

struct VideoStyle: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let category: StyleCategory
}

enum StyleCategory: String, CaseIterable {
    case transformation = "Transformation"
    case effects = "Effects"
    case anime = "Anime"
    case superhero = "Superhero"
    case artistic = "Artistic"
}

enum VideoGenerationModel: String, CaseIterable {
    case veo2 = "Veo 2"
    case soraX = "Sora X"
    case runway = "Runway Gen-3"
    case pika = "Pika Labs 2.0"
    case stable = "Stable Video 3D"
    case lumiere = "Lumiere Pro"

    var description: String {
        switch self {
        case .veo2: return "Google's latest video model"
        case .soraX: return "OpenAI's advanced video AI"
        case .runway: return "Runway's creative toolkit"
        case .pika: return "Ultra-realistic generation"
        case .stable: return "3D-aware video synthesis"
        case .lumiere: return "Temporal consistency master"
        }
    }

    var color: String {
        switch self {
        case .veo2: return "blue"
        case .soraX: return "green"
        case .runway: return "purple"
        case .pika: return "orange"
        case .stable: return "red"
        case .lumiere: return "cyan"
        }
    }
}
