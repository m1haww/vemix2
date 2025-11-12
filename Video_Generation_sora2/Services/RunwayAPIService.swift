import Foundation
import UIKit

final class RunwayAPIService {
    static let shared = RunwayAPIService()

    private let apiKey: String
    private let baseURL = "https://api.dev.runwayml.com"
    private let apiVersion = "2024-11-06"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private init() {

        self.apiKey = APIKeys.runwayAPIKey

        if apiKey.isEmpty {
            print("⚠️ RunwayAPIService: API key is missing")
        }
    }

    func generateVideoFromImage(
        image: UIImage,
        prompt: String? = nil,
        model: RunwayModel = .gen3aTurbo,
        aspectRatio: RunwayAspectRatio = .landscape16x9,
        duration: Int = 10,
        seed: UInt32? = nil,
        contentModeration: RunwayContentModeration = .init()
    ) async throws -> RunwayTaskResponse {

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw RunwayError.invalidImage
        }

        let base64Image = "data:image/jpeg;base64,\(imageData.base64EncodedString())"

        var requestBody: [String: Any] = [
            "promptImage": base64Image,
            "model": model.rawValue,
            "ratio": aspectRatio.rawValue,
            "duration": duration
        ]

        if let prompt = prompt {
            requestBody["promptText"] = prompt
        }

        if let seed = seed {
            requestBody["seed"] = seed
        }

        requestBody["contentModeration"] = [
            "publicFigureThreshold": contentModeration.publicFigureThreshold.rawValue
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/v1/image_to_video",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RunwayError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw RunwayError.rateLimitExceeded
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw RunwayError.serverError(error)
            }
            throw RunwayError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RunwayTaskResponse.self, from: data)
    }

    func generateVideoFromText(
        prompt: String,
        model: RunwayModel = .gen3aTurbo,
        aspectRatio: RunwayAspectRatio = .landscape16x9,
        duration: Int = 10,
        seed: UInt32? = nil,
        contentModeration: RunwayContentModeration = .init()
    ) async throws -> RunwayTaskResponse {
        var requestBody: [String: Any] = [
            "promptText": prompt,
            "model": model.rawValue,
            "ratio": aspectRatio.rawValue,
            "duration": duration
        ]

        if let seed = seed {
            requestBody["seed"] = seed
        }

        requestBody["contentModeration"] = [
            "publicFigureThreshold": contentModeration.publicFigureThreshold.rawValue
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/v1/text_to_video",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RunwayError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw RunwayError.rateLimitExceeded
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw RunwayError.serverError(error)
            }
            throw RunwayError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RunwayTaskResponse.self, from: data)
    }

    func getTaskStatus(taskId: String) async throws -> RunwayTaskStatus {
        let request = createRequest(
            endpoint: "/v1/tasks/\(taskId)",
            method: "GET"
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RunwayError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw RunwayError.taskNotFound
        }

        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? String {
                throw RunwayError.serverError(error)
            }
            throw RunwayError.serverError("Request failed with status code: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            let standardFormatter = ISO8601DateFormatter()
            if let date = standardFormatter.date(from: dateString) {
                return date
            }
            
            print("⚠️ RunwayAPI: Failed to parse date string: \(dateString)")
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Date string does not match expected format"))
        }
        return try decoder.decode(RunwayTaskStatus.self, from: data)
    }

    func pollTaskUntilComplete(
        taskId: String,
        pollInterval: TimeInterval = 5.0,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> RunwayTaskStatus {
        let startTime = Date()
        var lastPollTime = Date.distantPast

        while Date().timeIntervalSince(startTime) < timeout {

            let timeSinceLastPoll = Date().timeIntervalSince(lastPollTime)
            if timeSinceLastPoll < pollInterval {
                let waitTime = pollInterval - timeSinceLastPoll
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }

            lastPollTime = Date()

            do {
                let status = try await getTaskStatus(taskId: taskId)

                progressHandler?(status.progressRatio)

                switch status.status {
                case .succeeded:
                    return status
                case .failed:
                    throw RunwayError.taskFailed(status.failureReason ?? "Task failed without specific reason")
                case .cancelled:
                    throw RunwayError.taskCancelled
                case .pending, .running, .throttled:
                    continue
                }
            } catch RunwayError.taskNotFound {
                throw RunwayError.taskNotFound
            } catch {
                print("[RunwayAPIService] Error polling task \(taskId): \(error)")
                try await Task.sleep(nanoseconds: UInt64(10 * 1_000_000_000))
            }
        }

        throw RunwayError.timeout
    }

    private func createRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "X-Runway-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
        }

        return request
    }
}

enum RunwayModel: String {
    case gen3aTurbo = "gen3a_turbo"
    case gen4Turbo = "gen4_turbo"

    var displayName: String {
        switch self {
        case .gen3aTurbo: return "Gen-3 Alpha Turbo"
        case .gen4Turbo: return "Gen-4 Turbo"
        }
    }
}

enum RunwayAspectRatio: String, CaseIterable {
    case landscape16x9 = "1280:720"
    case portrait9x16 = "720:1280"
    case landscape4x3 = "1104:832"
    case portrait3x4 = "832:1104"
    case square1x1 = "960:960"
    case cinematic21x9 = "1584:672"
    case landscape5x3 = "1280:768"
    case portrait3x5 = "768:1280"

    var displayName: String {
        switch self {
        case .landscape16x9: return "Landscape (16:9)"
        case .portrait9x16: return "Portrait (9:16)"
        case .square1x1: return "Square (1:1)"
        case .landscape4x3: return "Standard (4:3)"
        case .portrait3x4: return "Portrait (3:4)"
        case .cinematic21x9: return "Cinematic (21:9)"
        case .landscape5x3: return "Wide (5:3)"
        case .portrait3x5: return "Tall (3:5)"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .landscape16x9: return 16.0/9.0
        case .portrait9x16: return 9.0/16.0
        case .square1x1: return 1.0
        case .landscape4x3: return 4.0/3.0
        case .portrait3x4: return 3.0/4.0
        case .cinematic21x9: return 21.0/9.0
        case .landscape5x3: return 5.0/3.0
        case .portrait3x5: return 3.0/5.0
        }
    }

    static func supportedRatios(for model: RunwayModel) -> [RunwayAspectRatio] {
        // All models support all 8 aspect ratios
        return RunwayAspectRatio.allCases
    }
}

struct RunwayContentModeration {
    let publicFigureThreshold: PublicFigureThreshold

    init(publicFigureThreshold: PublicFigureThreshold = .auto) {
        self.publicFigureThreshold = publicFigureThreshold
    }

    enum PublicFigureThreshold: String {
        case auto = "auto"
        case low = "low"
    }
}

struct RunwayTaskResponse: Codable {
    let id: String
}

struct RunwayTaskStatus: Codable {
    let id: String
    let status: TaskStatus
    let createdAt: Date
    let failure: String?
    let failureCode: String?
    let output: [String]?
    let progress: Double?

    enum TaskStatus: String, Codable {
        case pending = "PENDING"
        case running = "RUNNING"
        case succeeded = "SUCCEEDED"
        case failed = "FAILED"
        case cancelled = "CANCELLED"
        case throttled = "THROTTLED"
    }
    
    var outputUrls: [String]? { return output }
    var progressRatio: Double? { return progress }
    var failureReason: String? { return failure }
    
    // Custom decoding to handle progress field robustly
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(TaskStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        failure = try container.decodeIfPresent(String.self, forKey: .failure)
        failureCode = try container.decodeIfPresent(String.self, forKey: .failureCode)
        output = try container.decodeIfPresent([String].self, forKey: .output)
        
        // Handle progress field with custom decoding to avoid precision issues
        if container.contains(.progress) {
            if let progressValue = try? container.decodeIfPresent(Double.self, forKey: .progress) {
                progress = progressValue
            } else if let progressString = try? container.decodeIfPresent(String.self, forKey: .progress),
                      let progressDouble = Double(progressString) {
                progress = progressDouble
            } else {
                progress = nil
            }
        } else {
            progress = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, status, createdAt, failure, failureCode, output, progress
    }
}

enum RunwayError: LocalizedError {
    case invalidImage
    case invalidResponse
    case rateLimitExceeded
    case serverError(String)
    case taskFailed(String)
    case taskCancelled
    case taskNotFound
    case timeout
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid response from Runway API"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason)"
        case .taskCancelled:
            return "Task was cancelled"
        case .taskNotFound:
            return "Task not found or was deleted"
        case .timeout:
            return "Request timed out"
        case .missingAPIKey:
            return "Runway API key is missing"
        }
    }
}
