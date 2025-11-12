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
                    Text("My Creations")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .padding(.bottom, 13)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(filters, id: \.self) { filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: viewModel.selectedFilter == filter,
                                    action: { viewModel.selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 3)
                    }
                    .frame(height: 40)

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if video.status == .completed {
                    StoredVideoThumbnailView(video: video)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))

                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 2)
                            }
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: video.status.iconName)
                                    .font(.system(size: 40))
                                    .foregroundColor(statusColor(video.status))

                                Text(video.status.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        )
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(video.category)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    Text(timeAgo(from: video.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let prompt = video.prompt {
                    Text(prompt)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor(video.status))
                            .frame(width: 8, height: 8)
                        Text(video.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    Spacer()
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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