import SwiftUI
import AVKit

struct VideosView: View {
    @StateObject private var viewModel = GalleryViewModel()

    let filters = ["All", "Recent", "Completed", "Pending", "Failed"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Enhanced Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Creations")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("\(viewModel.filteredVideos.count) videos")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Add action for creating new video
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Create")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                            }
                        }
                        
                        // Enhanced Filter Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filters, id: \.self) { filter in
                                    ModernFilterChip(
                                        title: filter,
                                        isSelected: viewModel.selectedFilter == filter,
                                        count: getFilterCount(filter),
                                        action: { 
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.selectedFilter = filter
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)
                    .background(
                        LinearGradient(
                            colors: [Color.black, Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            if viewModel.filteredVideos.isEmpty {
                                EmptyGalleryView()
                            } else {
                                ForEach(viewModel.filteredVideos) { video in
                                    GeneratedVideoCard(video: video)
                                        .padding(.horizontal, 20)
                                        .onTapGesture {
                                            viewModel.selectVideo(video)
                                        }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingVideoDetail) {
            if let video = viewModel.selectedVideo {
                GeneratedVideoDetailView(video: video)
            }
        }
    }
    
    private func getFilterCount(_ filter: String) -> Int {
        let allVideos = AppStateManager.shared.generatedVideos
        switch filter {
        case "All":
            return allVideos.count
        case "Recent":
            return allVideos.filter { $0.date > Date().addingTimeInterval(-86400) }.count
        case "Completed":
            return allVideos.filter { $0.status == .completed }.count
        case "Pending":
            return allVideos.filter { $0.status == .pending }.count
        case "Failed":
            return allVideos.filter { $0.status == .failed }.count
        default:
            return 0
        }
    }
}

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : .gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
    }
}

struct GeneratedVideoCard: View {
    let video: GeneratedVideo
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            videoThumbnailSection
            videoInfoSection
        }
        .cardStyle
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onTapGesture { handleTap() }
    }
    
    private var videoThumbnailSection: some View {
        ZStack {
            if video.status == .completed {
                completedVideoView
            } else {
                pendingVideoView
            }
        }
    }
    
    private var completedVideoView: some View {
        StoredVideoThumbnailView(video: video)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(videoOverlay)
    }
    
    private var videoOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            playButton
            categoryBadge
        }
    }
    
    private var playButton: some View {
        Button(action: {}) {
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 2)
                )
        }
    }
    
    private var categoryBadge: some View {
        VStack {
            HStack {
                Text(video.category)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(statusColor(video.status).opacity(0.8))
                    )
                Spacer()
            }
            Spacer()
        }
        .padding(12)
    }
    
    private var pendingVideoView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .frame(height: 200)
            .overlay(pendingContent)
    }
    
    private var pendingContent: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(statusColor(video.status).opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: video.status.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(statusColor(video.status))
                )
            
            VStack(spacing: 4) {
                Text(video.status.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if video.status == .pending {
                    Text("Processing your video...")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var videoInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerInfo
            
            if let prompt = video.prompt {
                Text(prompt)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            if video.status == .completed {
                actionButtons
            }
        }
        .padding(16)
    }
    
    private var headerInfo: some View {
        HStack {
            Text(timeAgo(from: video.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            statusIndicator
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(video.status))
                .frame(width: 6, height: 6)
            Text(video.status.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(statusColor(video.status))
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            actionButton(icon: "square.and.arrow.up", text: "Share")
            actionButton(icon: "arrow.down.to.line", text: "Save")
            Spacer()
        }
    }
    
    private func actionButton(icon: String, text: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(text)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func handleTap() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isHovered.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHovered = false
            }
        }
    }
}

extension View {
    var cardStyle: some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

func timeAgo(from date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    let hours = Int(interval / 3600)

    if hours < 1 {
        return "Just now"
    } else if hours < 24 {
        return "\(hours)h ago"
    } else {
        return "\(hours / 24)d ago"
    }
}

func statusColor(_ status: GeneratedVideoStatus) -> Color {
    switch status {
    case .pending:
        return .orange
    case .completed:
        return .green
    case .failed:
        return .red
    }
}

struct EmptyGalleryView: View {
    @State private var showVideoGenerator = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3),
                                    Color.blue.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                VStack(spacing: 16) {
                    Text("No Videos Yet")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Start creating amazing AI videos with cutting-edge models")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    showVideoGenerator = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))

                        Text("Create First Video")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: Color.purple.opacity(0.5), radius: 20, x: 0, y: 10)
                }

                VStack(spacing: 16) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "Multiple AI Models", color: .green)
                    FeatureRow(icon: "bolt.circle.fill", text: "Fast Generation", color: .yellow)
                    FeatureRow(icon: "infinity.circle.fill", text: "Various Styles", color: .blue)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .sheet(isPresented: $showVideoGenerator) {
            VideoGeneratorView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

// Placeholder views that need to be implemented
struct StoredVideoThumbnailView: View {
    let video: GeneratedVideo
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray)
            .overlay(
                Image(systemName: "video.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            )
    }
}

struct GeneratedVideoDetailView: View {
    let video: GeneratedVideo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Video Details")
                    .font(.title)
                    .padding()
                
                Text(video.prompt ?? "No prompt")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Video Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VideoGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Video Generator")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon - AI Video Generation Interface")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Create Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VideosView_Previews: PreviewProvider {
    static var previews: some View {
        VideosView()
    }
}