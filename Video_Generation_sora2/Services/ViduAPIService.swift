import Foundation
import UIKit

final class ViduAPIService {
    static let shared = ViduAPIService()

    private let apiKey: String
    private let baseURL = "https://api.vidu.com"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private init() {

        self.apiKey = APIKeys.viduAPIKey

        if apiKey.isEmpty {
            print("⚠️ ViduAPIService: API key is missing - please configure VIDU_API_KEY")
        }
    }

    func generateVideoFromText(
        prompt: String,
        model: ViduModel = .vidu15,
        style: ViduStyle = .general,
        duration: Int? = nil,
        seed: Int? = nil,
        aspectRatio: ViduAspectRatio = .ratio16x9,
        resolution: ViduResolution? = nil,
        movementAmplitude: ViduMovementAmplitude = .auto,
        bgm: Bool = false,
        offPeak: Bool = false,
        payload: String? = nil,
        callbackUrl: String? = nil
    ) async throws -> ViduTaskResponse {

        let videoDuration = duration ?? model.defaultDuration

        let videoResolution = resolution ?? model.defaultResolution(for: videoDuration)

        guard model.supportedDurations.contains(videoDuration) else {
            throw ViduError.invalidDuration(model: model.rawValue, duration: videoDuration)
        }

        guard model.supportedResolutions(for: videoDuration).contains(videoResolution) else {
            throw ViduError.invalidResolution(model: model.rawValue, duration: videoDuration, resolution: videoResolution.rawValue)
        }

        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "style": style.rawValue,
            "prompt": String(prompt.prefix(1500)),
            "duration": videoDuration,
            "aspect_ratio": aspectRatio.rawValue,
            "resolution": videoResolution.rawValue,
            "movement_amplitude": movementAmplitude.rawValue,
            "bgm": bgm,
            "off_peak": offPeak
        ]

        if let seed = seed {
            requestBody["seed"] = seed
        }

        if let payload = payload {
            requestBody["payload"] = String(payload.prefix(1048576))
        }

        if let callbackUrl = callbackUrl {
            requestBody["callback_url"] = callbackUrl
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/ent/v2/text2video",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ViduError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw ViduError.rateLimitExceeded
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw ViduError.serverError(error)
            }
            throw ViduError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ViduTaskResponse.self, from: data)
    }

    func generateVideoFromImage(
        image: UIImage,
        prompt: String? = nil,
        model: ViduModel = .vidu15,
        style: ViduStyle = .general,
        duration: Int? = nil,
        seed: Int? = nil,
        aspectRatio: ViduAspectRatio = .ratio16x9,
        resolution: ViduResolution? = nil,
        movementAmplitude: ViduMovementAmplitude = .auto,
        bgm: Bool = false,
        offPeak: Bool = false,
        firstFrameCondition: ViduFrameCondition = .weak,
        lastFrameCondition: ViduFrameCondition? = nil
    ) async throws -> ViduTaskResponse {

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw ViduError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        let videoDuration = duration ?? model.defaultDuration

        let videoResolution = resolution ?? model.defaultResolution(for: videoDuration)

        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "style": style.rawValue,
            "first_frame_image": base64Image,
            "first_frame_condition": firstFrameCondition.rawValue,
            "duration": videoDuration,
            "aspect_ratio": aspectRatio.rawValue,
            "resolution": videoResolution.rawValue,
            "movement_amplitude": movementAmplitude.rawValue,
            "bgm": bgm,
            "off_peak": offPeak
        ]

        if let prompt = prompt {
            requestBody["prompt"] = String(prompt.prefix(1500))
        }

        if let seed = seed {
            requestBody["seed"] = seed
        }

        if let lastFrameCondition = lastFrameCondition {
            requestBody["last_frame_condition"] = lastFrameCondition.rawValue
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/ent/v2/image2video",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ViduError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw ViduError.serverError(error)
            }
            throw ViduError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ViduTaskResponse.self, from: data)
    }

    func getTaskStatus(taskId: String) async throws -> ViduTaskStatus {
        let request = createRequest(
            endpoint: "/ent/v2/tasks/\(taskId)/creations",
            method: "GET"
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ViduError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw ViduError.taskNotFound
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw ViduError.serverError(error)
            }
            throw ViduError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ViduTaskStatus.self, from: data)
    }

    func pollTaskUntilComplete(
        taskId: String,
        pollInterval: TimeInterval = 3.0,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> ViduTaskStatus {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getTaskStatus(taskId: taskId)

            let progress: Double? = {
                switch status.state {
                case "created", "queueing":
                    return 0.1
                case "processing":
                    return 0.5
                case "success":
                    return 1.0
                case "failed":
                    return nil
                default:
                    return 0.1
                }
            }()

            progressHandler?(progress)

            switch status.state {
            case "success":
                guard let creations = status.creations, !creations.isEmpty else {
                    throw ViduError.invalidResponse
                }
                return status
            case "failed":
                let errorMessage = status.errCode ?? "Task failed without specific reason"
                throw ViduError.taskFailed(errorMessage)
            case "created", "queueing", "processing":

                break
            default:
                break
            }

            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw ViduError.timeout
    }

    func cancelTask(taskId: String) async throws -> Bool {
        let request = createRequest(
            endpoint: "/ent/v2/task/\(taskId)/cancel",
            method: "POST"
        )

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ViduError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }

    private func createRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
        }

        return request
    }
}

enum ViduModel: String, CaseIterable {
    case viduq1 = "viduq1"
    case vidu15 = "vidu1.5"

    var displayName: String {
        switch self {
        case .viduq1: return "Vidu Q1"
        case .vidu15: return "Vidu 1.5"
        }
    }

    var description: String {
        switch self {
        case .viduq1: return "Fast generation • 5s videos"
        case .vidu15: return "Latest model • 4s/8s videos • Best quality"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .viduq1: return 5
        case .vidu15: return 4
        }
    }

    var supportedDurations: [Int] {
        switch self {
        case .viduq1: return [5]
        case .vidu15: return [4, 8]
        }
    }

    func defaultResolution(for duration: Int) -> ViduResolution {
        switch self {
        case .viduq1:
            return .res1080p
        case .vidu15:
            switch duration {
            case 4: return .res360p
            case 8: return .res720p
            default: return .res720p
            }
        }
    }

    func supportedResolutions(for duration: Int) -> [ViduResolution] {
        switch self {
        case .viduq1:
            return [.res1080p]
        case .vidu15:
            switch duration {
            case 4: return [.res360p, .res720p, .res1080p]
            case 8: return [.res720p]
            default: return [.res720p]
            }
        }
    }
}

enum ViduStyle: String, CaseIterable {
    case general = "general"
    case anime = "anime"

    var displayName: String {
        switch self {
        case .general: return "General"
        case .anime: return "Anime"
        }
    }

    var description: String {
        switch self {
        case .general: return "General style with prompt control"
        case .anime: return "Optimized for anime aesthetics"
        }
    }
}

enum ViduAspectRatio: String, CaseIterable {
    case ratio16x9 = "16:9"
    case ratio9x16 = "9:16"
    case ratio1x1 = "1:1"

    var displayName: String {
        switch self {
        case .ratio16x9: return "Landscape (16:9)"
        case .ratio9x16: return "Portrait (9:16)"
        case .ratio1x1: return "Square (1:1)"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .ratio16x9: return 16.0/9.0
        case .ratio9x16: return 9.0/16.0
        case .ratio1x1: return 1.0
        }
    }
}

enum ViduResolution: String, CaseIterable {
    case res360p = "360p"
    case res720p = "720p"
    case res1080p = "1080p"

    var displayName: String {
        switch self {
        case .res360p: return "360p"
        case .res720p: return "HD (720p)"
        case .res1080p: return "Full HD (1080p)"
        }
    }
}

enum ViduMovementAmplitude: String, CaseIterable {
    case auto = "auto"
    case small = "small"
    case medium = "medium"
    case large = "large"

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

enum ViduFrameCondition: String {
    case weak = "weak"
    case medium = "medium"
    case strong = "strong"
}

struct ViduTaskResponse: Codable {
    let taskId: String
}

struct ViduVideoInfo: Codable {
    let duration: Double?
    let fps: Int?
    let resolution: ViduVideoResolution?
}

struct ViduVideoResolution: Codable {
    let width: Int?
    let height: Int?
}

struct ViduCreation: Codable {
    let id: String
    let url: String
    let coverUrl: String?
    let watermarkedUrl: String?
    let moderationUrl: [String]?
    let video: ViduVideoInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case coverUrl = "cover_url"
        case watermarkedUrl = "watermarked_url"
        case moderationUrl = "moderation_url"
        case video
    }
}

struct ViduTaskStatus: Codable {
    let state: String
    let errCode: String?
    let creations: [ViduCreation]?
    let id: String?
    let credits: Int?
    let bgm: Bool?
    let payload: String?
    let cusPriority: Int?
    let offPeak: Bool?
    
    enum CodingKeys: String, CodingKey {
        case state
        case errCode = "err_code"
        case creations
        case id
        case credits
        case bgm
        case payload
        case cusPriority = "cus_priority"
        case offPeak = "off_peak"
    }
}

enum ViduTaskState: String, Codable {
    case created = "created"
    case queueing = "queueing"
    case processing = "processing"
    case success = "success"
    case failed = "failed"
}

enum ViduError: LocalizedError {
    case invalidImage
    case invalidResponse
    case invalidDuration(model: String, duration: Int)
    case invalidResolution(model: String, duration: Int, resolution: String)
    case rateLimitExceeded
    case serverError(String)
    case taskFailed(String)
    case taskNotFound
    case timeout
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid response from Vidu API"
        case .invalidDuration(let model, let duration):
            return "Invalid duration \(duration)s for model \(model)"
        case .invalidResolution(let model, let duration, let resolution):
            return "Invalid resolution \(resolution) for model \(model) with duration \(duration)s"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason)"
        case .taskNotFound:
            return "Task not found or was deleted"
        case .timeout:
            return "Request timed out"
        case .missingAPIKey:
            return "Vidu API key is missing"
        }
    }
}
