import Foundation
import UIKit

final class Veo3FastAPIService {
    static let shared = Veo3FastAPIService()
    
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
        negativePrompt: String? = nil,
        length: Int = 8,
        aspectRatio: String = "16:9",
        resolution: String = "720p",
        seed: Int? = nil,
        generateAudio: Bool = true,
        webhookUrl: String? = nil
    ) async throws -> Veo3FastGenerationResponse {
        let url = URL(string: "\(baseURL)/generation/google/veo3-fast")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeys.veo3FastAPIKey, forHTTPHeaderField: "x-api-key")
        
        let body = Veo3FastTextToVideoRequest(
            input: Veo3FastTextToVideoInput(
                prompt: prompt,
                negativePrompt: negativePrompt,
                length: length,
                aspectRatio: aspectRatio,
                resolution: resolution,
                seed: seed,
                generateAudio: generateAudio
            ),
            webhookUrl: webhookUrl
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Veo3FastError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Veo3FastError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(Veo3FastGenerationResponse.self, from: data)
    }
    
    func generateVideoFromImage(
        imageUrl: String,
        prompt: String,
        negativePrompt: String? = nil,
        length: Int = 8,
        aspectRatio: String = "16:9",
        resolution: String = "1080p",
        seed: Int? = nil,
        generateAudio: Bool = true,
        webhookUrl: String? = nil
    ) async throws -> Veo3FastGenerationResponse {
        let url = URL(string: "\(baseURL)/generation/google/veo3-fast")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeys.veo3FastAPIKey, forHTTPHeaderField: "x-api-key")
        
        let body = Veo3FastImageToVideoRequest(
            input: Veo3FastImageToVideoInput(
                image: imageUrl,
                prompt: prompt,
                negativePrompt: negativePrompt,
                length: length,
                aspectRatio: aspectRatio,
                resolution: resolution,
                seed: seed,
                generateAudio: generateAudio
            ),
            webhookUrl: webhookUrl
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Veo3FastError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Veo3FastError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(Veo3FastGenerationResponse.self, from: data)
    }
    
    func getTaskStatus(taskId: String) async throws -> Veo3FastTaskStatus {
        let url = URL(string: "\(baseURL)/generation/\(taskId)/status")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIKeys.veo3FastAPIKey, forHTTPHeaderField: "x-api-key")
        
        let (data, response) = try await session.data(for: request)
        
        print("--------")
        print(String(data: data, encoding: .utf8) ?? "Unknown error")
        print("--------")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Veo3FastError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Veo3FastError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(Veo3FastTaskStatus.self, from: data)
    }
    
    func uploadImage(_ image: UIImage, fileName: String? = nil) async throws -> UploadImageResponse {
        let url = URL(string: "https://ai-assistant-backend-164860087792.europe-west1.run.app/api/file/upload-file")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIKeys.veo3FastAPIKey, forHTTPHeaderField: "x-api-key")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw Veo3FastError.invalidResponse
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
            throw Veo3FastError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Veo3FastError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(UploadImageResponse.self, from: data)
    }
    
    func pollTaskUntilComplete(
        taskId: String,
        pollInterval: TimeInterval = 3.0,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> Veo3FastTaskStatus {
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
                throw Veo3FastError.taskFailed(reason: firstGeneration.failMsg)
                
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
        
        throw Veo3FastError.timeout
    }
}

struct Veo3FastTextToVideoRequest: Codable {
    let input: Veo3FastTextToVideoInput
    let webhookUrl: String?
}

struct Veo3FastTextToVideoInput: Codable {
    let prompt: String
    let negativePrompt: String?
    let length: Int
    let aspectRatio: String
    let resolution: String
    let seed: Int?
    let generateAudio: Bool
}

struct Veo3FastImageToVideoRequest: Codable {
    let input: Veo3FastImageToVideoInput
    let webhookUrl: String?
}

struct Veo3FastImageToVideoInput: Codable {
    let image: String
    let prompt: String
    let negativePrompt: String?
    let length: Int
    let aspectRatio: String
    let resolution: String
    let seed: Int?
    let generateAudio: Bool
}

struct Veo3FastGenerationResponse: Codable {
    let code: String
    let message: String
    let data: Veo3FastGenerationData
}

struct Veo3FastGenerationData: Codable {
    let taskId: String
    let status: Veo3FastTaskStatusEnum
}

struct UploadImageResponse: Codable {
    let message: String
    let fileName: String
}

struct Veo3FastTaskStatus: Codable {
    let code: String
    let message: String
    let data: Veo3FastTaskStatusData
}

struct Veo3FastTaskStatusData: Codable {
    let taskId: String
    let generations: [Veo3FastGeneration]
}

struct Veo3FastGeneration: Codable {
    let id: String
    let status: Veo3FastTaskStatusEnum
    let failMsg: String?
    let url: String?
    let mediaType: Veo3FastMediaType
    let createdDate: String?
    let updatedDate: String?
}

enum Veo3FastMediaType: String, Codable {
    case image = "image"
    case video = "video"
    case text = "text"
    case audio = "audio"
}

enum Veo3FastTaskStatusEnum: String, Codable {
    case waiting = "waiting"
    case processing = "processing"
    case succeed = "succeed"
    case failed = "failed"
}

enum Veo3FastError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case taskFailed(reason: String?)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Veo3 Fast API"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason ?? "Unknown reason")"
        case .timeout:
            return "Request timed out"
        }
    }
}
