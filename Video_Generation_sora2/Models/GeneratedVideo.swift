import Foundation

struct GeneratedVideo: Identifiable, Codable {
    let id: UUID
    let date: Date
    let videoFilePath: String?
    let category: String
    let status: GeneratedVideoStatus
    let prompt: String?
    let thumbnailData: Data?
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        videoFilePath: String?,
        category: String,
        status: GeneratedVideoStatus,
        prompt: String? = nil,
        thumbnailData: Data? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.date = date
        self.videoFilePath = videoFilePath
        self.category = category
        self.status = status
        self.prompt = prompt
        self.thumbnailData = thumbnailData
        self.errorMessage = errorMessage
    }
}

enum GeneratedVideoStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}
