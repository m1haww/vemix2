import SwiftUI
import Combine

class GalleryViewModel: ObservableObject {
    @Published var selectedFilter = "All"
    @Published var selectedVideo: GeneratedVideo?
    @Published var showingVideoDetail = false

    private let appState = AppStateManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {

        appState.$generatedVideos
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var filteredVideos: [GeneratedVideo] {
        var filtered = appState.generatedVideos

        switch selectedFilter {
        case "Recent":
            filtered = appState.generatedVideos.filter { $0.date > Date().addingTimeInterval(-86400) }
        case "Completed":
            filtered = appState.generatedVideos.filter { $0.status == .completed }
        case "Pending":
            filtered = appState.generatedVideos.filter { $0.status == .pending }
        case "Failed":
            filtered = appState.generatedVideos.filter { $0.status == .failed }
        default:
            break
        }

        return filtered
    }

    func selectVideo(_ video: GeneratedVideo) {
        selectedVideo = video
        showingVideoDetail = true
    }
}
