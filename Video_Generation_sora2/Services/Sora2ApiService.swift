import Foundation
import UIKit

final class Sora2ApiService {
    static let shared = Sora2ApiService()

    private let baseURL = "https://pollo.ai/api/platform"
    private var session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 300.0
        self.session = URLSession(configuration: config)
    }

    func generateVideoFromText(
        prompt: String,
        model: Sora2Model = .sora2,
        length: Int = 8,
        aspectRatio: String = "16:9",
        webhookUrl: String? = nil
    ) async throws -> Sora2GenerationResponse {
        let endpoint = "/generation/sora/sora-2"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeys.sora2APIKey, forHTTPHeaderField: "x-api-key")

        let body = Sora2TextToVideoRequest(
            input: Sora2TextToVideoInput(
                prompt: prompt,
                length: length,
                aspectRatio: aspectRatio
            ),
            webhookUrl: webhookUrl
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Sora2Error.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Sora2Error.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try JSONDecoder().decode(Sora2GenerationResponse.self, from: data)
    }

    func generateVideoFromImage(
        imageUrl: String,
        prompt: String? = nil,
        model: Sora2Model = .sora2,
        length: Int = 8,
        aspectRatio: String = "16:9",
        webhookUrl: String? = nil
    ) async throws -> Sora2GenerationResponse {
        let endpoint = "/generation/sora/sora-2"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeys.sora2APIKey, forHTTPHeaderField: "x-api-key")

        let body = Sora2ImageToVideoRequest(
            input: Sora2ImageToVideoInput(
                image: imageUrl,
                prompt: prompt,
                length: length,
                aspectRatio: aspectRatio
            ),
            webhookUrl: webhookUrl
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(body)

        print("--------Sora2 Image-to-Video Request Body--------")
        if let requestBody = request.httpBody, let jsonString = String(data: requestBody, encoding: .utf8) {
            print(jsonString)
        }
        print("--------")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Sora2Error.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Sora2Error.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try JSONDecoder().decode(Sora2GenerationResponse.self, from: data)
    }

    func getTaskStatus(taskId: String) async throws -> Sora2TaskStatus {
        let url = URL(string: "\(baseURL)/generation/\(taskId)/status")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIKeys.sora2APIKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Sora2Error.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Sora2Error.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try JSONDecoder().decode(Sora2TaskStatus.self, from: data)
    }

    func uploadImage(_ image: UIImage, fileName: String? = nil) async throws -> UploadImageResponse {
        let url = URL(string: "https://ai-assistant-backend-164860087792.europe-west1.run.app/api/file/upload-file")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIKeys.sora2APIKey, forHTTPHeaderField: "x-api-key")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw Sora2Error.invalidResponse
        }

        let imageName = fileName ?? "image_\(Date().timeIntervalSince1970).jpg"

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(imageName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Sora2Error.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Sora2Error.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try JSONDecoder().decode(UploadImageResponse.self, from: data)
    }

    func pollTaskUntilComplete(
        taskId: String,
        pollInterval: TimeInterval = 3.0,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> Sora2TaskStatus {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let status = try await getTaskStatus(taskId: taskId)

            guard let firstGeneration = status.data.generations.first else {
                progressHandler?(0.05)
                try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                continue
            }

            switch firstGeneration.status {
            case .succeed:
                progressHandler?(1.0)
                return status

            case .failed:
                let failMessage = firstGeneration.failMsg?.isEmpty == false ? firstGeneration.failMsg : "Video generation failed. Please try again with a different prompt or settings."
                throw Sora2Error.taskFailed(reason: failMessage)

            case .processing:
                let progress = min(Date().timeIntervalSince(startTime) / 60.0, 0.95)
                progressHandler?(progress)

            case .waiting:
                progressHandler?(0.1)
            }

            if firstGeneration.status != .succeed && firstGeneration.status != .failed {
                try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }

        throw Sora2Error.timeout
    }
}

// MARK: - Request Models

struct Sora2TextToVideoRequest: Codable {
    let input: Sora2TextToVideoInput
    let webhookUrl: String?

    enum CodingKeys: String, CodingKey {
        case input
        case webhookUrl
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(input, forKey: .input)
        if let webhookUrl = webhookUrl {
            try container.encode(webhookUrl, forKey: .webhookUrl)
        }
    }
}

struct Sora2TextToVideoInput: Codable {
    let prompt: String
    let length: Int
    let aspectRatio: String
}

struct Sora2ImageToVideoRequest: Codable {
    let input: Sora2ImageToVideoInput
    let webhookUrl: String?

    enum CodingKeys: String, CodingKey {
        case input
        case webhookUrl
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(input, forKey: .input)
        if let webhookUrl = webhookUrl {
            try container.encode(webhookUrl, forKey: .webhookUrl)
        }
    }
}

struct Sora2ImageToVideoInput: Codable {
    let image: String
    let prompt: String?
    let length: Int
    let aspectRatio: String

    enum CodingKeys: String, CodingKey {
        case image
        case prompt
        case length
        case aspectRatio
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image, forKey: .image)
        if let prompt = prompt, !prompt.isEmpty {
            try container.encode(prompt, forKey: .prompt)
        }
        try container.encode(length, forKey: .length)
        try container.encode(aspectRatio, forKey: .aspectRatio)
    }
}

// MARK: - Response Models

struct Sora2GenerationResponse: Codable {
    let code: String
    let message: String
    let data: Sora2GenerationData
}

struct Sora2GenerationData: Codable {
    let taskId: String
    let status: Sora2TaskStatusEnum
}

struct Sora2TaskStatus: Codable {
    let code: String
    let message: String
    let data: Sora2TaskStatusData
}

struct Sora2TaskStatusData: Codable {
    let taskId: String
    let generations: [Sora2Generation]
}

struct Sora2Generation: Codable {
    let id: String
    let status: Sora2TaskStatusEnum
    let failMsg: String?
    let url: String?
    let mediaType: Sora2MediaType
    let createdDate: String?
    let updatedDate: String?
}

// MARK: - Enums

enum Sora2Model: String, CaseIterable {
    case sora2 = "Sora 2"

    var displayName: String {
        return self.rawValue
    }
}

enum Sora2MediaType: String, Codable {
    case image = "image"
    case video = "video"
    case text = "text"
    case audio = "audio"
}

enum Sora2TaskStatusEnum: String, Codable {
    case waiting = "waiting"
    case processing = "processing"
    case succeed = "succeed"
    case failed = "failed"
}

enum Sora2AspectRatio: String, CaseIterable {
    case landscape16x9 = "16:9"
    case portrait9x16 = "9:16"
    case square1x1 = "1:1"
    case standard4x3 = "4:3"
    case portrait3x4 = "3:4"

    var displayName: String {
        switch self {
        case .landscape16x9: return "Landscape (16:9)"
        case .portrait9x16: return "Portrait (9:16)"
        case .square1x1: return "Square (1:1)"
        case .standard4x3: return "Standard (4:3)"
        case .portrait3x4: return "Portrait (3:4)"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .landscape16x9: return 16.0/9.0
        case .portrait9x16: return 9.0/16.0
        case .square1x1: return 1.0/1.0
        case .standard4x3: return 4.0/3.0
        case .portrait3x4: return 3.0/4.0
        }
    }
}

enum Sora2Error: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case taskFailed(reason: String?)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Sora 2 API"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason ?? "Unknown reason")"
        case .timeout:
            return "Request timed out"
        }
    }
}
