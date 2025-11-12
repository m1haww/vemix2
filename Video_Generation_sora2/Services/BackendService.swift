import Foundation
import UIKit

final class BackendService {
    static let shared = BackendService()

    private var baseURL = ""

    private lazy var session: URLSession = {
        return safeSession()
    }()

    private func safeSession() -> URLSession {
        let config: URLSessionConfiguration
        if #available(iOS 18.4, *) {
            config = URLSessionConfiguration.ephemeral
        } else {
            config = URLSessionConfiguration.default
        }

        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.httpShouldSetCookies = false
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 1

        return URLSession(configuration: config)
    }

    private init() {}

    func fetchBaseURL() async throws -> String {

        let url = URL(string: "https://ai-assistant-backend-164860087792.europe-west1.run.app/api/config/base-url")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.serverError("Invalid response type")
        }

        if httpResponse.statusCode != 200 {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = json?["error"] as? String ?? "Failed to fetch base URL"
            throw BackendError.serverError(errorMessage)
        }

        let json: [String: Any]
        do {
            guard let parsedJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw BackendError.invalidResponse
            }
            json = parsedJson
        } catch {
            throw BackendError.serverError("Cannot parse base URL response: \(error.localizedDescription)")
        }

        guard let baseUrlFromServer = json["base_url"] as? String else {
            throw BackendError.invalidResponse
        }

        baseURL = baseUrlFromServer
        return baseUrlFromServer
    }

    func generateVideo(
        image: UIImage? = nil,
        prompt: String?,
        model: GoogleCloudConfig.VeoModel = .veo3Fast,
        aspectRatio: VeoAspectRatio,
        duration: Int,
        generateAudio: Bool
    ) async throws -> String {
        var requestBody: [String: Any] = [
            "aspectRatio": aspectRatio.rawValue,
            "durationSeconds": duration,
            "generateAudio": generateAudio,
            "enhancePrompt": true,
            "model": model.rawValue
        ]

        if let prompt = prompt {
            requestBody["prompt"] = prompt
        }

        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64String = imageData.base64EncodedString()
            requestBody["image"] = base64String
            requestBody["imageMimeType"] = "image/jpeg"
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("[BackendService] Error serializing request body: \(error)")
            throw BackendError.serverError("Cannot serialize request: \(error.localizedDescription)")
        }

        let request = createRequest(
            endpoint: "/generate-video",
            method: "POST",
            body: jsonData
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .cannotParseResponse {
                throw BackendError.serverError("Server returned malformed response. Please check server logs.")
            }
            throw error
        } catch {
            print("[BackendService] Network error: \(error)")
            throw error
        }

        let json: [String: Any]
        do {
            guard let parsedJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[BackendService] Error: Response is not a JSON object")
                throw BackendError.invalidResponse
            }
            json = parsedJson
        } catch {
            print("[BackendService] JSON parsing error: \(error)")
            print("[BackendService] Raw response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw BackendError.serverError("Cannot parse response: \(error.localizedDescription)")
        }

        guard let operationName = json["name"] as? String else {
            print("[BackendService] Error: No operation name in response")
            print("[BackendService] Response data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw BackendError.invalidResponse
        }

        print("[BackendService] Video generation started with operation: \(operationName)")
        return operationName
    }

    func getVideoStatus(operationId: String) async throws -> VeoOperationStatus {
        let requestBody = ["operationName": operationId]

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("[BackendService] Error serializing status request body: \(error)")
            throw BackendError.serverError("Cannot serialize status request: \(error.localizedDescription)")
        }

        let request = createRequest(
            endpoint: "/check-operation",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.serverError("Invalid response type")
        }

        if httpResponse.statusCode != 200 {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = json?["error"] as? String ?? "Failed to check operation status"
            throw BackendError.serverError(errorMessage)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(VeoOperationStatus.self, from: data)
        } catch {
            print("[BackendService] JSON decoding error: \(error)")
            print("[BackendService] Raw response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            throw BackendError.invalidResponse
        }
    }

    func generateRunwayVideo(
        image: UIImage? = nil,
        prompt: String,
        model: RunwayModel,
        aspectRatio: RunwayAspectRatio,
        duration: Int
    ) async throws -> String {
        var requestBody: [String: Any] = [
            "provider": "runway",
            "model": model.rawValue,
            "aspectRatio": aspectRatio.rawValue,
            "duration": duration,
            "prompt": prompt
        ]

        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64String = imageData.base64EncodedString()
            requestBody["image"] = base64String
            requestBody["imageMimeType"] = "image/jpeg"
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/generate-runway-video",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.serverError("Invalid response type")
        }

        if httpResponse.statusCode != 200 {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = json?["error"] as? String ?? "Failed to generate Runway video"
            throw BackendError.serverError(errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let taskId = json["taskId"] as? String else {
            throw BackendError.invalidResponse
        }

        print("[BackendService] Runway video generation started with task: \(taskId)")
        return taskId
    }

    func getRunwayTaskStatus(taskId: String) async throws -> RunwayTaskStatus {
        let requestBody = ["taskId": taskId]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        let request = createRequest(
            endpoint: "/check-runway-task",
            method: "POST",
            body: jsonData
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.serverError("Invalid response type")
        }

        if httpResponse.statusCode != 200 {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = json?["error"] as? String ?? "Failed to check Runway task status"
            throw BackendError.serverError(errorMessage)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RunwayTaskStatus.self, from: data)
    }

    private func createRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")

        if let body = body {
            request.httpBody = body
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }

        return request
    }
}

struct AuthToken: Codable {
    let token: String
    let expiresIn: Int
}

enum BackendError: LocalizedError {
    case notImplemented
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Backend integration not implemented yet"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
