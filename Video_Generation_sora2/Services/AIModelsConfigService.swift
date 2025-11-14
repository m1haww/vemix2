import Foundation

// MARK: - Data Models
struct AIModelsConfig: Codable {
    let aiModels: AIModelsData
    let serverConfig: ServerConfig
    
    enum CodingKeys: String, CodingKey {
        case aiModels = "ai_models"
        case serverConfig = "server_config"
    }
}

struct AIModelsData: Codable {
    let providers: [AIProvider]
}

struct AIProvider: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String
    let icon: String
    let description: String
    let supportsImageInput: Bool
    let supportsAudio: Bool
    let models: [AIModel]
    let aspectRatios: [AspectRatio]
    let durations: [Int]
}

struct AIModel: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String
    let apiValue: String
    let isDefault: Bool?
}

struct AspectRatio: Codable, Identifiable {
    let id: String
    let displayName: String
    let value: String
}

struct ServerConfig: Codable {
    let remoteUrl: String
    let cacheDurationHours: Int
    let fallbackToLocal: Bool
    
    enum CodingKeys: String, CodingKey {
        case remoteUrl = "remote_url"
        case cacheDurationHours = "cache_duration_hours"
        case fallbackToLocal = "fallback_to_local"
    }
}

// MARK: - Service
@MainActor
final class AIModelsConfigService: ObservableObject {
    static let shared = AIModelsConfigService()
    
    @Published var providers: [AIProvider] = []
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    
    private let cacheKey = "ai_models_config_cache"
    private let cacheTimestampKey = "ai_models_config_timestamp"
    
    private init() {
        Task {
            await loadConfiguration()
        }
    }
    
    func loadConfiguration() async {
        isLoading = true
        
        // Try to load from server first
        if let config = await loadFromServer() {
            await updateConfiguration(config)
            isLoading = false
            return
        }
        
        // Fallback to cached version
        if let cachedConfig = loadFromCache(), !isCacheExpired() {
            await updateConfiguration(cachedConfig)
            isLoading = false
            return
        }
        
        // Final fallback to local JSON
        if let localConfig = loadFromLocal() {
            await updateConfiguration(localConfig)
            saveToCache(localConfig)
        }
        
        isLoading = false
    }
    
    func refreshFromServer() async {
        isLoading = true
        
        if let config = await loadFromServer() {
            await updateConfiguration(config)
            saveToCache(config)
        }
        
        isLoading = false
    }
    
    // MARK: - Server Loading
    private func loadFromServer() async -> AIModelsConfig? {
        guard let url = URL(string: getServerURL()) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let config = try JSONDecoder().decode(AIModelsConfig.self, from: data)
            return config
        } catch {
            print("Error loading from server: \(error)")
            return nil
        }
    }
    
    private func getServerURL() -> String {
        // You can change this URL to your server
        return "https://your-server.com/api/ai-models-config"
    }
    
    // MARK: - Local Loading
    private func loadFromLocal() -> AIModelsConfig? {
        guard let url = Bundle.main.url(forResource: "ai_models_config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(AIModelsConfig.self, from: data)
        } catch {
            print("Error loading local config: \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    private func saveToCache(_ config: AIModelsConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            print("Error saving to cache: \(error)")
        }
    }
    
    private func loadFromCache() -> AIModelsConfig? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(AIModelsConfig.self, from: data)
        } catch {
            print("Error loading from cache: \(error)")
            return nil
        }
    }
    
    private func isCacheExpired() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let expirationTime = 24 * 60 * 60.0 // 24 hours
        
        return Date().timeIntervalSince(cacheDate) > expirationTime
    }
    
    // MARK: - Configuration Update
    private func updateConfiguration(_ config: AIModelsConfig) async {
        providers = config.aiModels.providers
        lastUpdated = Date()
    }
    
    // MARK: - Helper Methods
    func getProvider(by id: String) -> AIProvider? {
        return providers.first { $0.id == id }
    }
    
    func getDefaultModel(for providerId: String) -> AIModel? {
        guard let provider = getProvider(by: providerId) else { return nil }
        return provider.models.first { $0.isDefault == true } ?? provider.models.first
    }
    
    func getModels(for providerId: String) -> [AIModel] {
        return getProvider(by: providerId)?.models ?? []
    }
    
    func getAspectRatios(for providerId: String) -> [AspectRatio] {
        return getProvider(by: providerId)?.aspectRatios ?? []
    }
    
    func getDurations(for providerId: String) -> [Int] {
        return getProvider(by: providerId)?.durations ?? []
    }
}