import SwiftUI
import AVKit

struct ExploreView: View {
    @State private var exploreConfig: ExploreConfig?
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var player: AVPlayer?
    @State private var showPromptSheet: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Video - Full Screen
                GeometryReader { geometry in
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(
                                width: max(geometry.size.width, geometry.size.height * (16/9)),
                                height: max(geometry.size.height, geometry.size.width * (9/16))
                            )
                            .clipped()
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.6),
                                        Color.black.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    } else {
                        Color.black
                    }
                }
                .ignoresSafeArea(.all)
                
                // Side Action Buttons (Like & Try) - Moved Higher
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 80) // Reduce top spacer to move buttons up
                    
                    VStack(spacing: 24) {
                        // Like Button
                        VStack(spacing: 4) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isLiked.toggle()
                                    likeCount += isLiked ? 1 : -1
                                }
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(isLiked ? .red : .white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                    )
                                    .scaleEffect(isLiked ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLiked)
                            }
                            
                            Text("Like")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        // Try Button
                        VStack(spacing: 4) {
                            Button(action: {
                                showPromptSheet = true
                            }) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                    )
                            }
                            
                            Text("Try")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    
                    .padding(.bottom, 130)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Main Content
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Video Description
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exploreConfig?.title ?? "ASMR")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(exploreConfig?.trendWords ?? "Explore the last trends and start creating now!")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    // Action Button
                    Button(action: {
                        // Navigate to filters or main creation flow
                    }) {
                        Text("Try it Now")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(hex: "B951E7")
                            )
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadExploreConfig()
        }
        .sheet(isPresented: $showPromptSheet) {
            VideoPromptBottomSheet(
                initialPrompt: exploreConfig?.description ?? "",
                onGenerate: { prompt, model in
                    showPromptSheet = false
                }
            )
        }
    }
    
    private func loadExploreConfig() {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }
        
        do {
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let exploreData = jsonData?["explore"] as? [String: Any] {
                exploreConfig = ExploreConfig(
                    backgroundVideo: exploreData["background_video"] as? String ?? "",
                    title: exploreData["title"] as? String ?? "ASMR",
                    description: exploreData["description"] as? String ?? "Discover amazing AI capabilities",
                    trendWords: exploreData["trend_words"] as? String ?? "Explore the last trends and start creating now!",
                    likes: exploreData["likes"] as? Int ?? 1247,
                    category: exploreData["category"] as? String ?? "Trending"
                )
                likeCount = exploreConfig?.likes ?? 1247
                setupVideoPlayer()
            }
        } catch {
            print("Error loading explore config: \(error)")
        }
    }
    
    private func setupVideoPlayer() {
        guard let config = exploreConfig, !config.backgroundVideo.isEmpty else { return }
        
        // Try to get video from Assets Dataset first
        if let dataAsset = NSDataAsset(name: config.backgroundVideo) {
            // Create a temporary file from the data
            let tempURL = createTemporaryVideoFile(from: dataAsset.data)
            setupPlayer(with: tempURL)
            return
        }
        
        // Fallback: Try to get video from main bundle
        if let videoURL = Bundle.main.url(forResource: config.backgroundVideo, withExtension: "mp4") {
            setupPlayer(with: videoURL)
        }
    }
    
    private func createTemporaryVideoFile(from data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("explore_video.mp4")
        
        try? data.write(to: tempURL)
        return tempURL
    }
    
    private func setupPlayer(with url: URL) {
        player = AVPlayer(url: url)
        
        // Configure player for full screen background video
        if player?.currentItem != nil {
            // Set video gravity to fill screen
            player?.currentItem?.videoComposition = nil
        }
        
        // Loop video infinitely
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: CMTime.zero)
            player?.play()
        }
        
        // Enable audio for video playback
        player?.isMuted = true
    }
}

struct ExploreConfig {
    let backgroundVideo: String
    let title: String
    let description: String
    let trendWords: String
    let likes: Int
    let category: String
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
