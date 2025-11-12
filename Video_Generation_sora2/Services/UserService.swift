import Foundation

final class UserService {
    static let shared = UserService()

    private let userDefaults = UserDefaults.standard
    private let appUserIdKey = "app_user_id"
    private let userRegisteredKey = "user_registered"

    private let baseURL = "https://veo3-backend-164860087792.us-central1.run.app"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    var appUserId: String {
        if let existingId = userDefaults.string(forKey: appUserIdKey) {
            return existingId
        }

        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: appUserIdKey)
        userDefaults.synchronize()
        return newId
    }

    func registerUser(initialCredits: Int) async throws -> UserRegistrationResponse {
        let endpoint = "/register-user"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = UserRegistrationRequest(
            app_user_id: appUserId,
            credits: initialCredits
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200, 201:
            let decoder = JSONDecoder()
            let registrationResponse = try decoder.decode(UserRegistrationResponse.self, from: data)

            return registrationResponse

        case 409:
            print("[UserService] User already exists, fetching credits...")
            return try await fetchCredits()

        default:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw UserServiceError.serverError(errorMessage)
            }
            throw UserServiceError.serverError("Registration failed with status: \(httpResponse.statusCode)")
        }
    }

    func fetchCredits() async throws -> UserRegistrationResponse {
        let endpoint = "/get-credits/\(appUserId)"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let creditsResponse = try decoder.decode(UserCreditsResponse.self, from: data)

            return UserRegistrationResponse(
                user_id: creditsResponse.user_id,
                credits: creditsResponse.credits,
                message: "Credits fetched successfully"
            )
        case 404:
            throw UserServiceError.userNotFound

        default:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw UserServiceError.serverError(errorMessage)
            }
            throw UserServiceError.serverError("Failed to fetch credits with status: \(httpResponse.statusCode)")
        }
    }

    func useCredits(_ credits: Int) async throws -> UseCreditsResponse {
        let endpoint = "/use-credits"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = UseCreditsRequest(
            app_user_id: appUserId,
            credits: credits
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(UseCreditsResponse.self, from: data)

        case 400:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw UserServiceError.insufficientCredits(errorMessage)
            }
            throw UserServiceError.badRequest("Invalid request")

        case 404:
            throw UserServiceError.userNotFound

        default:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw UserServiceError.serverError(errorMessage)
            }
            throw UserServiceError.serverError("Failed to use credits with status: \(httpResponse.statusCode)")
        }
    }

    func addCredits(_ credits: Int) async throws -> AddCreditsResponse {
        let endpoint = "/add-credits"
        let url = URL(string: "\(baseURL)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = AddCreditsRequest(
            app_user_id: appUserId,
            credits: credits
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(AddCreditsResponse.self, from: data)

        case 404:
            throw UserServiceError.userNotFound

        default:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw UserServiceError.serverError(errorMessage)
            }
            throw UserServiceError.serverError("Failed to add credits with status: \(httpResponse.statusCode)")
        }
    }
}

struct UserRegistrationRequest: Codable {
    let app_user_id: String
    let credits: Int
}

struct UserRegistrationResponse: Codable {
    let user_id: String
    let credits: Int
    let message: String
}

struct UserCreditsResponse: Codable {
    let user_id: String
    let credits: Int
    let created_at: String
}

struct UseCreditsRequest: Codable {
    let app_user_id: String
    let credits: Int
}

struct UseCreditsResponse: Codable {
    let message: String
    let user_id: String
    let credits_used: Int
    let remaining_credits: Int
}

struct AddCreditsRequest: Codable {
    let app_user_id: String
    let credits: Int
}

struct AddCreditsResponse: Codable {
    let credits_added: Int
    let message: String
    let total_credits: Int
    let user_id: String
}

enum UserServiceError: LocalizedError {
    case invalidResponse
    case userNotFound
    case serverError(String)
    case insufficientCredits(String)
    case badRequest(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .userNotFound:
            return "User not found"
        case .serverError(let message):
            return "Server error: \(message)"
        case .insufficientCredits(let message):
            return message
        case .badRequest(let message):
            return message
        }
    }
}
