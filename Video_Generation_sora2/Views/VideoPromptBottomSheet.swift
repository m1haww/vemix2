import SwiftUI
import AVKit

struct VideoPromptBottomSheet: View {
    let initialPrompt: String
    let onGenerate: (String, VideoProvider) -> Void
    
    @State private var prompt: String = ""
    @State private var selectedProviderId: String = "veo"
    @StateObject private var aiConfig = AIModelsConfigService.shared
    @StateObject private var dataManager = FilterDataManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                textEditorSection
                suggestedPromptsSection
                Spacer()
                createButtonSection
            }
            .background(Color.black)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            prompt = initialPrompt
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("✕") {
                dismiss()
            }
            .font(.title2)
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Describe your video")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    TextEditor(text: $prompt)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .frame(minHeight: 120, maxHeight: 300)
                    
                    HStack {
                        Spacer()
                        Text("Google Veo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "B951E7").opacity(0.2))
                            .cornerRadius(16)
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                
                if prompt.isEmpty {
                    Text("Describe your video...")
                        .foregroundColor(.white.opacity(0.3))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Spacer()
                Text("\(prompt.count) / 1000")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var suggestedPromptsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Prompt")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            HStack(spacing: 8) {
                ForEach(dataManager.suggestedPrompts, id: \.id) { suggestion in
                    Button(action: {
                        prompt = suggestion.prompt
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            SuggestedVideoPreview(videoName: suggestion.videoName)
                                .frame(width: 170, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.pink)
                                )
                            
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Try")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "B951E7"))
                            .cornerRadius(20)
                            .padding(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var createButtonSection: some View {
        Button(action: {
            onGenerate(prompt, .veo)
        }) {
            Text("Create for 200 coins")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "B951E7"))
                .cornerRadius(30)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .disabled(prompt.isEmpty)
        .opacity(prompt.isEmpty ? 0.5 : 1.0)
    }
}

struct SuggestedVideoPreview: View {
    let videoName: String
    @State private var player: AVPlayer?
    
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .disabled(true)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                Color.gray.opacity(0.3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
        }
        .onAppear {
            setupVideoPlayer()
        }
    }
    
    private func setupVideoPlayer() {
        if let dataAsset = NSDataAsset(name: videoName) {
            let tempURL = createTemporaryVideoFile(from: dataAsset.data, fileName: videoName)
            setupPlayer(with: tempURL)
            return
        }
        
        if let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            setupPlayer(with: videoURL)
        }
    }
    
    private func createTemporaryVideoFile(from data: Data, fileName: String) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("\(fileName).mp4")
        try? data.write(to: tempURL)
        return tempURL
    }
    
    private func setupPlayer(with url: URL) {
        player = AVPlayer(url: url)
        player?.isMuted = true
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: CMTime.zero)
            player?.play()
        }
    }
}
