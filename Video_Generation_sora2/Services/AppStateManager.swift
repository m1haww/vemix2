import SwiftUI
import Combine

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    @Published var selectedVideoPreset: VideoPreset?
    @Published var selectedCategory: VideoCategory?
    @Published var currentTab: Int = 0
    @Published var generatedVideos: [GeneratedVideo] = []
    @Published var showPaywall: Bool = false
    @Published var promptText: String = ""
    @Published var showingShop: Bool = false

    private let userDefaults = UserDefaults.standard
    private let generatedVideosKey = "GeneratedVideosHistory"

    private init() {
        loadGeneratedVideos()
    }

    func selectVideoPreset(_ preset: VideoPreset, category: VideoCategory? = nil) {
        selectedVideoPreset = preset
        selectedCategory = category
    }

    func selectCategory(_ category: VideoCategory) {
        selectedCategory = category
        currentTab = 1
    }

    func clearSelectedPreset() {
        selectedVideoPreset = nil
    }

    func clearSelectedCategory() {
        selectedCategory = nil
    }

    func navigateToTab(_ index: Int) {
        currentTab = index
    }

    func presentPaywall() {
        showPaywall = true
    }

    func setPromptText(_ prompt: String) {
        promptText = prompt
    }

    func clearPromptText() {
        promptText = ""
    }

    func openShop() {
        self.showingShop = true
    }

    func closeShop() {
        showingShop = false
    }

    func addGeneratedVideo(_ video: GeneratedVideo) {
        generatedVideos.insert(video, at: 0)
        saveGeneratedVideos()
    }

    func updateGeneratedVideo(_ video: GeneratedVideo) {
        if let index = generatedVideos.firstIndex(where: { $0.id == video.id }) {
            generatedVideos[index] = video
            saveGeneratedVideos()
        }
    }

    func removeGeneratedVideo(_ video: GeneratedVideo) {
        generatedVideos.removeAll { $0.id == video.id }
        saveGeneratedVideos()
    }

    func getGeneratedVideos(for category: String? = nil) -> [GeneratedVideo] {
        if let category = category {
            return generatedVideos.filter { $0.category == category }
        }
        return generatedVideos
    }

    private func saveGeneratedVideos() {
        if let encoded = try? JSONEncoder().encode(generatedVideos) {
            userDefaults.set(encoded, forKey: generatedVideosKey)
        }
    }

    private func loadGeneratedVideos() {
        if let data = userDefaults.data(forKey: generatedVideosKey),
           let decoded = try? JSONDecoder().decode([GeneratedVideo].self, from: data) {
            generatedVideos = decoded
        } else {
            // Add demo videos for testing
            addDemoVideos()
        }
    }
    
    private func addDemoVideos() {
        let demoVideos = [
            GeneratedVideo(
                id: UUID(),
                date: Date().addingTimeInterval(-3600),
                videoFilePath: "https://example.com/video1.mp4",
                category: "Nature",
                status: .completed,
                prompt: "A majestic eagle soaring through mountain peaks at golden hour"
            ),
            GeneratedVideo(
                id: UUID(),
                date: Date().addingTimeInterval(-7200),
                videoFilePath: "https://example.com/video2.mp4",
                category: "Sci-Fi",
                status: .completed,
                prompt: "Cyberpunk city with neon lights and flying cars in the rain"
            ),
            GeneratedVideo(
                id: UUID(),
                date: Date().addingTimeInterval(-300),
                videoFilePath: nil,
                category: "Nature",
                status: .pending,
                prompt: "A peaceful forest stream with sunlight filtering through trees"
            ),
            GeneratedVideo(
                id: UUID(),
                date: Date().addingTimeInterval(-1800),
                videoFilePath: nil,
                category: "Fantasy",
                status: .failed,
                prompt: "Medieval castle siege with dramatic lighting and effects"
            )
        ]
        
        generatedVideos = demoVideos
        saveGeneratedVideos()
    }
}
