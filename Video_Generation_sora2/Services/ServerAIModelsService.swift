import Foundation

// MARK: - Server Configuration Models
struct ServerAIModelsConfig: Codable {
    let serverConfig: ServerConfiguration
    let enabledProviders: [EnabledProvider]
    let featureFlags: FeatureFlags
    let pricing: [String: PricingInfo]
    
    enum CodingKeys: String, CodingKey {
        case serverConfig = "server_config"
        case enabledProviders = "enabled_providers"
        case featureFlags = "feature_flags"
        case pricing
    }
}

struct ServerConfiguration: Codable {
    let lastUpdated: String
    let version: String
    let remoteUrl: String
    let cacheDurationHours: Int
    
    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case version
        case remoteUrl = "remote_url"
        case cacheDurationHours = "cache_duration_hours"
    }
}

struct EnabledProvider: Codable, Identifiable {
    let id: String
    let enabled: Bool
    let priority: Int
    let models: [EnabledModel]
    
    enum CodingKeys: String, CodingKey {
        case id = "provider_id"
        case enabled
        case priority
        case models
    }
}

struct EnabledModel: Codable, Identifiable {
    let id: String
    let enabled: Bool
    let isDefault: Bool
    let displayName: String
    let apiValue: String
    
    enum CodingKeys: String, CodingKey {
        case id = "model_id"
        case enabled
        case isDefault = "is_default"
        case displayName = "display_name"
        case apiValue = "api_value"
    }
}

struct FeatureFlags: Codable {
    let enableAudioGeneration: Bool
    let enableImageToVideo: Bool
    let enableBatchGeneration: Bool
    let maxConcurrentGenerations: Int
    let defaultTimeoutSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case enableAudioGeneration = "enable_audio_generation"
        case enableImageToVideo = "enable_image_to_video"
        case enableBatchGeneration = "enable_batch_generation"
        case maxConcurrentGenerations = "max_concurrent_generations"
        case defaultTimeoutSeconds = "default_timeout_seconds"
    }
}

struct PricingInfo: Codable {
    let creditsPerGeneration: Int
    let premiumMultiplier: Double
    
    enum CodingKeys: String, CodingKey {
        case creditsPerGeneration = "credits_per_generation"
        case premiumMultiplier = "premium_multiplier"
    }
}

// MARK: - Server AI Models Service
@MainActor
final class ServerAIModelsService: ObservableObject {
    static let shared = ServerAIModelsService()
    
    @Published var serverConfig: ServerAIModelsConfig?
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var error: String?
    
    private let cacheKey = "server_ai_models_cache"
    private let cacheTimestampKey = "server_ai_models_timestamp"
    
    private init() {
        Task {
            await loadServerConfiguration()
        }
    }
    
    // MARK: - Public Methods
    func loadServerConfiguration() async {
        isLoading = true
        error = nil
        
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
        } else {
            error = "Failed to load AI models configuration"
        }
        
        isLoading = false
    }
    
    func refreshFromServer() async {
        isLoading = true
        error = nil
        
        if let config = await loadFromServer() {
            await updateConfiguration(config)
            saveToCache(config)
        } else {
            error = "Failed to refresh configuration from server"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    func isProviderEnabled(_ providerId: String) -> Bool {
        guard let config = serverConfig else { return true }
        return config.enabledProviders.first { $0.id == providerId }?.enabled ?? true
    }
    
    func isModelEnabled(_ modelId: String, for providerId: String) -> Bool {
        guard let config = serverConfig else { return true }
        guard let provider = config.enabledProviders.first(where: { $0.id == providerId }) else { return true }
        return provider.models.first { $0.id == modelId }?.enabled ?? true
    }
    
    func getEnabledModels(for providerId: String) -> [EnabledModel] {
        guard let config = serverConfig else { return [] }
        guard let provider = config.enabledProviders.first(where: { $0.id == providerId }) else { return [] }
        return provider.models.filter { $0.enabled }
    }
    
    func getDefaultModel(for providerId: String) -> EnabledModel? {
        let enabledModels = getEnabledModels(for: providerId)
        return enabledModels.first { $0.isDefault } ?? enabledModels.first
    }
    
    func getPricing(for providerId: String) -> PricingInfo? {
        return serverConfig?.pricing[providerId]
    }
    
    func getCreditsRequired(for providerId: String, isPremium: Bool = false) -> Int {
        guard let pricing = getPricing(for: providerId) else { return 100 }
        let baseCredits = pricing.creditsPerGeneration
        return isPremium ? Int(Double(baseCredits) * pricing.premiumMultiplier) : baseCredits
    }
    
    func getEnabledProviders() -> [EnabledProvider] {
        guard let config = serverConfig else { return [] }
        return config.enabledProviders
            .filter { $0.enabled }
            .sorted { $0.priority < $1.priority }
    }
    
    func getFeatureFlags() -> FeatureFlags? {
        return serverConfig?.featureFlags
    }
    
    // MARK: - Private Methods
    private func loadFromServer() async -> ServerAIModelsConfig? {
        guard let config = serverConfig ?? loadFromLocal(),
              let url = URL(string: config.serverConfig.remoteUrl) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let serverConfig = try JSONDecoder().decode(ServerAIModelsConfig.self, from: data)
            print("✅ Successfully loaded AI models config from server")
            return serverConfig
        } catch {
            print("❌ Error loading from server: \(error)")
            return nil
        }
    }
    
    private func loadFromLocal() -> ServerAIModelsConfig? {
        guard let url = Bundle.main.url(forResource: "server_ai_models", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Local server AI models config file not found")
            return nil
        }
        
        do {
            let config = try JSONDecoder().decode(ServerAIModelsConfig.self, from: data)
            print("✅ Successfully loaded AI models config from local file")
            return config
        } catch {
            print("❌ Error loading local server config: \(error)")
            return nil
        }
    }
    
    private func saveToCache(_ config: ServerAIModelsConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        } catch {
            print("❌ Error saving server config to cache: \(error)")
        }
    }
    
    private func loadFromCache() -> ServerAIModelsConfig? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(ServerAIModelsConfig.self, from: data)
        } catch {
            print("❌ Error loading server config from cache: \(error)")
            return nil
        }
    }
    
    private func isCacheExpired() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        
        // Get cache duration from config or default to 24 hours
        let cacheDuration = TimeInterval((serverConfig?.serverConfig.cacheDurationHours ?? 24) * 3600)
        
        return Date().timeIntervalSince(cacheDate) > cacheDuration
    }
    
    private func updateConfiguration(_ config: ServerAIModelsConfig) async {
        serverConfig = config
        lastUpdated = Date()
        print("✅ Updated AI models configuration")
    }
}

// MARK: - Integration with existing AIModelsConfigService
extension AIModelsConfigService {
    
    func getFilteredProviders() -> [AIProvider] {
        let serverService = ServerAIModelsService.shared
        
        return providers.compactMap { provider in
            // Check if provider is enabled on server
            guard serverService.isProviderEnabled(provider.id) else { return nil }
            
            // Filter models based on server configuration
            let enabledModels = provider.models.filter { model in
                serverService.isModelEnabled(model.id, for: provider.id)
            }
            
            // Return provider with filtered models
            guard !enabledModels.isEmpty else { return nil }
            
            return AIProvider(
                id: provider.id,
                name: provider.name,
                displayName: provider.displayName,
                icon: provider.icon,
                description: provider.description,
                supportsImageInput: provider.supportsImageInput,
                supportsAudio: provider.supportsAudio,
                models: enabledModels,
                aspectRatios: provider.aspectRatios,
                durations: provider.durations
            )
        }.sorted { provider1, provider2 in
            // Sort by server priority
            let enabledProviders = serverService.getEnabledProviders()
            let priority1 = enabledProviders.first { $0.id == provider1.id }?.priority ?? 999
            let priority2 = enabledProviders.first { $0.id == provider2.id }?.priority ?? 999
            return priority1 < priority2
        }
    }
    
    func getCreditsRequired(for providerId: String, isPremium: Bool = false) -> Int {
        return ServerAIModelsService.shared.getCreditsRequired(for: providerId, isPremium: isPremium)
    }
    
    func isFeatureEnabled(_ feature: String) -> Bool {
        guard let featureFlags = ServerAIModelsService.shared.getFeatureFlags() else { return true }
        
        switch feature {
        case "audio_generation":
            return featureFlags.enableAudioGeneration
        case "image_to_video":
            return featureFlags.enableImageToVideo
        case "batch_generation":
            return featureFlags.enableBatchGeneration
        default:
            return true
        }
    }
}