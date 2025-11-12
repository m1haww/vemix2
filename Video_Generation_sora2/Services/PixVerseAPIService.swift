import Foundation
import UIKit

final class PixVerseAPIService {
    static let shared = PixVerseAPIService()

    private let apiKey: String
    private let baseURL = "https://app-api.pixverse.ai"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private init() {

        self.apiKey = APIKeys.pixverseAPIKey

        if apiKey.isEmpty {
            print("⚠️ PixVerseAPIService: API key is missing - please configure PIXVERSE_API_KEY")
        }
    }

    func generateVideoFromText(
        prompt: String,
        negativePrompt: String? = nil,
        model: PixVerseModel = .v45,
        aspectRatio: PixVerseAspectRatio = .ratio16x9,
        duration: Int = 5,
        quality: PixVerseQuality = .hd540p,
        motionMode: PixVerseMotionMode = .normal,
        cameraMovement: PixVerseCameraMovement? = nil,
        style: PixVerseStyle? = nil,
        seed: Int? = nil,
        watermark: Bool = false,
        templateId: Int64? = nil,
        soundEffectSwitch: Bool = false,
        soundEffectContent: String? = nil
    ) async throws -> PixVerseTaskResponse {
        var requestBody: [String: Any] = [
            "prompt": prompt,
            "model": model.rawValue,
            "aspect_ratio": aspectRatio.rawValue,
            "duration": duration,
            "quality": quality.rawValue,
            "motion_mode": motionMode.rawValue,
            "water_mark": watermark
        ]
        
        // Add optional parameters if provided
        if let negativePrompt = negativePrompt {
            requestBody["negative_prompt"] = negativePrompt
        }
        
        if let seed = seed {
            requestBody["seed"] = seed
        }
        
        if let cameraMovement = cameraMovement {
            requestBody["camera_movement"] = cameraMovement.rawValue
        }
        
        // Only add style for v3.5 model
        if model == .v35, let style = style {
            requestBody["style"] = style.rawValue
        }
        
        if let templateId = templateId {
            requestBody["template_id"] = templateId
        }
        
        if soundEffectSwitch {
            requestBody["sound_effect_switch"] = soundEffectSwitch
            if let soundEffectContent = soundEffectContent {
                requestBody["sound_effect_content"] = soundEffectContent
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print(String(data: jsonData, encoding: .utf8) ?? "Failed to serialize JSON")

        let request = createRequest(
            endpoint: "/openapi/v2/video/text/generate",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        print("[PixVerseAPI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[PixVerseAPI] Error: Response is not HTTPURLResponse")
            throw PixVerseError.invalidResponse
        }

        print("[PixVerseAPI] Status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 429 {
            throw PixVerseError.rateLimitExceeded
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(PixVerseErrorResponse.self, from: data) {
                throw PixVerseError.apiError(code: errorResponse.errCode, message: errorResponse.errMsg)
            }
            throw PixVerseError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        // Don't use convertFromSnakeCase - we're handling keys manually
        
        do {
            let taskResponse = try decoder.decode(PixVerseTaskResponse.self, from: data)
            
            if taskResponse.errCode != 0 {
                print("[PixVerseAPI] API returned error code: \(taskResponse.errCode), message: \(taskResponse.errMsg)")
                throw PixVerseError.apiError(code: taskResponse.errCode, message: taskResponse.errMsg)
            }

            guard let videoId = taskResponse.resp?.videoId else {
                print("[PixVerseAPI] Error: No videoId in response. Full response: \(taskResponse)")
                throw PixVerseError.invalidResponse
            }

            print("[PixVerseAPI] Success! Video ID: \(videoId)")
            return taskResponse
        } catch {
            print("[PixVerseAPI] Failed to decode response: \(error)")
            print("[PixVerseAPI] Raw response was: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw error
        }
    }

    func generateVideoFromImage(
        image: UIImage,
        prompt: String? = nil,
        negativePrompt: String? = nil,
        model: PixVerseModel = .v45,
        aspectRatio: PixVerseAspectRatio = .ratio16x9,
        duration: Int = 5,
        quality: PixVerseQuality = .hd720p,
        motionMode: PixVerseMotionMode = .normal,
        cameraMovement: PixVerseCameraMovement? = nil,
        style: PixVerseStyle? = nil,
        seed: Int? = nil,
        watermark: Bool = false,
        soundEffectSwitch: Bool = false,
        soundEffectContent: String? = nil
    ) async throws -> PixVerseTaskResponse {

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw PixVerseError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        var requestBody: [String: Any] = [
            "image": base64Image,
            "model": model.rawValue,
            "aspect_ratio": aspectRatio.rawValue,
            "duration": duration,
            "quality": quality.rawValue,
            "motion_mode": motionMode.rawValue,
            "water_mark": watermark
        ]

        if let prompt = prompt {
            requestBody["prompt"] = prompt
        }

        if let negativePrompt = negativePrompt {
            requestBody["negative_prompt"] = negativePrompt
        }

        if let cameraMovement = cameraMovement {
            requestBody["camera_movement"] = cameraMovement.rawValue
        }

        // Only add style for v3.5 model
        if model == .v35, let style = style {
            requestBody["style"] = style.rawValue
        }

        if let seed = seed {
            requestBody["seed"] = seed
        }
        
        if soundEffectSwitch {
            requestBody["sound_effect_switch"] = soundEffectSwitch
            if let soundEffectContent = soundEffectContent {
                requestBody["sound_effect_content"] = soundEffectContent
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/openapi/v2/video/image/generate",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        print("[PixVerseAPI Image] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[PixVerseAPI Image] Error: Response is not HTTPURLResponse")
            throw PixVerseError.invalidResponse
        }

        print("[PixVerseAPI Image] Status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(PixVerseErrorResponse.self, from: data) {
                throw PixVerseError.apiError(code: errorResponse.errCode, message: errorResponse.errMsg)
            }
            throw PixVerseError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        
        do {
            let taskResponse = try decoder.decode(PixVerseTaskResponse.self, from: data)
            print("[PixVerseAPI Image] Success! Video ID: \(taskResponse.resp?.videoId ?? -1)")
            return taskResponse
        } catch {
            print("[PixVerseAPI Image] Failed to decode response: \(error)")
            print("[PixVerseAPI Image] Raw response was: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw error
        }
    }

    func getVideoStatus(videoId: Int64) async throws -> PixVerseVideoStatus {

        let request = createRequest(
            endpoint: "/openapi/v2/video/result/\(videoId)",
            method: "GET"
        )

        print("[PixVerseAPI Status] Checking status for video ID: \(videoId)")

        let (data, response) = try await session.data(for: request)

        print("[PixVerseAPI Status] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[PixVerseAPI Status] Error: Response is not HTTPURLResponse")
            throw PixVerseError.invalidResponse
        }

        print("[PixVerseAPI Status] Status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(PixVerseErrorResponse.self, from: data) {
                print("[PixVerseAPI Status] API error: code=\(errorResponse.errCode), message=\(errorResponse.errMsg)")
                throw PixVerseError.apiError(code: errorResponse.errCode, message: errorResponse.errMsg)
            }
            throw PixVerseError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter())
        
        do {
            let status = try decoder.decode(PixVerseVideoStatus.self, from: data)
            print("[PixVerseAPI Status] Video status: \(status.resp?.status ?? -1), URL: \(status.resp?.url ?? "none")")
            return status
        } catch {
            print("[PixVerseAPI Status] Failed to decode response: \(error)")
            print("[PixVerseAPI Status] Raw response was: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw error
        }
    }

    func pollVideoUntilComplete(
        videoId: Int64,
        pollInterval: TimeInterval = 3.0,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> PixVerseVideoStatus {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getVideoStatus(videoId: videoId)

            if status.errCode != 0 {
                throw PixVerseError.apiError(code: status.errCode, message: status.errMsg)
            }

            if let resp = status.resp {

                let progress: Double? = {
                    switch resp.videoStatus {
                    case .generating:
                        return 0.5
                    case .success:
                        return 1.0
                    case .failed, .moderationFailed:
                        return nil
                    default:
                        return 0.1
                    }
                }()

                progressHandler?(progress)

                switch resp.videoStatus {
                case .success:

                    guard resp.url != nil else {
                        throw PixVerseError.invalidResponse
                    }
                    return status
                case .failed:
                    throw PixVerseError.taskFailed("Video generation failed")
                case .moderationFailed:
                    throw PixVerseError.taskFailed("Content moderation failed - please adjust your prompt")
                case .generating:

                    break
                case .unknown:

                    print("[PixVerseAPIService] Unknown status code: \(resp.status)")
                    break
                }
            }

            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw PixVerseError.timeout
    }

    private func createRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let traceId = UUID().uuidString
        request.setValue(apiKey, forHTTPHeaderField: "API-KEY")
        request.setValue(traceId, forHTTPHeaderField: "Ai-trace-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
        }

        // Log request details
        print("[PixVerseAPI Request] URL: \(url)")
        print("[PixVerseAPI Request] Method: \(method)")
        print("[PixVerseAPI Request] API-KEY: \(apiKey.prefix(10))...")
        print("[PixVerseAPI Request] Trace-ID: \(traceId)")
        if let body = body {
            print("[PixVerseAPI Request] Body: \(String(data: body, encoding: .utf8) ?? "Unable to decode")")
        }

        return request
    }
}

enum PixVerseModel: String {
    case v45 = "v4.5"
    case v4 = "v4"
    case v35 = "v3.5"

    var displayName: String {
        switch self {
        case .v45: return "PixVerse 4.5"
        case .v4: return "PixVerse 4.0"
        case .v35: return "PixVerse 3.5"
        }
    }

    var description: String {
        switch self {
        case .v45: return "Latest model • Best quality"
        case .v4: return "Stable • High quality"
        case .v35: return "Fast • Good quality"
        }
    }
}

enum PixVerseAspectRatio: String, CaseIterable {
    case ratio16x9 = "16:9"
    case ratio4x3 = "4:3"
    case ratio1x1 = "1:1"
    case ratio3x4 = "3:4"
    case ratio9x16 = "9:16"

    var displayName: String {
        switch self {
        case .ratio16x9: return "Landscape (16:9)"
        case .ratio4x3: return "Standard (4:3)"
        case .ratio1x1: return "Square (1:1)"
        case .ratio3x4: return "Portrait (3:4)"
        case .ratio9x16: return "Portrait (9:16)"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .ratio16x9: return 16.0/9.0
        case .ratio4x3: return 4.0/3.0
        case .ratio1x1: return 1.0
        case .ratio3x4: return 3.0/4.0
        case .ratio9x16: return 9.0/16.0
        }
    }
}

enum PixVerseQuality: String, CaseIterable {
    case turbo360p = "360p"
    case hd540p = "540p"
    case hd720p = "720p"
    case fhd1080p = "1080p"

    var displayName: String {
        switch self {
        case .turbo360p: return "Turbo (360p)"
        case .hd540p: return "HD (540p)"
        case .hd720p: return "HD (720p)"
        case .fhd1080p: return "Full HD (1080p)"
        }
    }
}

enum PixVerseMotionMode: String, CaseIterable {
    case auto = "auto"
    case normal = "normal"
    case slow = "slow"
    case fast = "fast"

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .normal: return "Normal"
        case .slow: return "Slow Motion"
        case .fast: return "Fast Motion"
        }
    }
}

enum PixVerseCameraMovement: String, CaseIterable {
    case zoomIn = "zoom_in"
    case zoomOut = "zoom_out"
    case panLeft = "pan_left"
    case panRight = "pan_right"
    case tiltUp = "tilt_up"
    case tiltDown = "tilt_down"
    case rotateClockwise = "rotate_clockwise"
    case rotateCounterclockwise = "rotate_counterclockwise"

    var displayName: String {
        switch self {
        case .zoomIn: return "Zoom In"
        case .zoomOut: return "Zoom Out"
        case .panLeft: return "Pan Left"
        case .panRight: return "Pan Right"
        case .tiltUp: return "Tilt Up"
        case .tiltDown: return "Tilt Down"
        case .rotateClockwise: return "Rotate Clockwise"
        case .rotateCounterclockwise: return "Rotate Counter-Clockwise"
        }
    }
}

enum PixVerseStyle: String, CaseIterable {
    case anime = "anime"
    case animation3d = "3d_animation"
    case clay = "clay"
    case comic = "comic"
    case cyberpunk = "cyberpunk"
    
    var displayName: String {
        switch self {
        case .anime: return "Anime"
        case .animation3d: return "3D Animation"
        case .clay: return "Clay"
        case .comic: return "Comic"
        case .cyberpunk: return "Cyberpunk"
        }
    }
}

struct PixVerseTaskResponse: Codable {
    let errCode: Int
    let errMsg: String
    let resp: TaskData?

    struct TaskData: Codable {
        let videoId: Int64?

        private enum CodingKeys: String, CodingKey {
            case videoId = "video_id"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try to decode as Int64 first, then as Double if that fails
            if let intValue = try? container.decode(Int64.self, forKey: .videoId) {
                self.videoId = intValue
                print("[PixVerseAPI] Decoded video_id as Int64: \(intValue)")
            } else if let doubleValue = try? container.decode(Double.self, forKey: .videoId) {
                self.videoId = Int64(doubleValue)
                print("[PixVerseAPI] Decoded video_id as Double->Int64: \(Int64(doubleValue))")
            } else if let stringValue = try? container.decode(String.self, forKey: .videoId),
                      let intValue = Int64(stringValue) {
                self.videoId = intValue
                print("[PixVerseAPI] Decoded video_id as String->Int64: \(intValue)")
            } else {
                print("[PixVerseAPI] Failed to decode video_id - setting to nil")
                self.videoId = nil
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case errCode = "ErrCode"
        case errMsg = "ErrMsg"
        case resp = "Resp"
    }
}

struct PixVerseVideoStatus: Codable {
    let errCode: Int
    let errMsg: String
    let resp: VideoData?

    struct VideoData: Codable {
        let id: Int64
        let status: Int
        let url: String?
        let prompt: String?
        let negativePrompt: String?
        let seed: Int?
        let outputWidth: Int?
        let outputHeight: Int?
        let size: Int?
        let createTime: String?
        let modifyTime: String?
        let style: String?
        let resolutionRatio: Int?

        var videoStatus: VideoStatus {
            switch status {
            case 1: return .success
            case 5: return .generating
            case 7: return .moderationFailed
            case 8: return .failed
            default: return .unknown
            }
        }

        enum VideoStatus {
            case success
            case generating
            case moderationFailed
            case failed
            case unknown
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case status
            case url
            case prompt
            case negativePrompt = "negative_prompt"
            case seed
            case outputWidth
            case outputHeight
            case size
            case createTime = "create_time"
            case modifyTime = "modify_time"
            case style
            case resolutionRatio = "resolution_ratio"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case errCode = "ErrCode"
        case errMsg = "ErrMsg"
        case resp = "Resp"
    }
}

struct PixVerseErrorResponse: Codable {
    let errCode: Int
    let errMsg: String

    private enum CodingKeys: String, CodingKey {
        case errCode = "ErrCode"
        case errMsg = "ErrMsg"
    }
}

enum PixVerseError: LocalizedError {
    case invalidImage
    case invalidResponse
    case rateLimitExceeded
    case serverError(String)
    case apiError(code: Int, message: String)
    case taskFailed(String)
    case timeout
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid response from PixVerse API"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        case .apiError(let code, let message):
            return "PixVerse error (\(code)): \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason)"
        case .timeout:
            return "Request timed out"
        case .missingAPIKey:
            return "PixVerse API key is missing"
        }
    }
}
