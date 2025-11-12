import SwiftUI

struct HeroVideoSection: View {
    var body: some View {
        ZStack {
            // Background video placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: UIScreen.main.bounds.width, height: 300)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            // Gradient overlay
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.95),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
            .frame(width: UIScreen.main.bounds.width, height: 300)
            
            // Top navigation overlay
            VStack {
                HStack {
                    Button(action: {
                        // Profile action
                    }) {
                        Image("profile")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(hex: "B951E7"))
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Filters")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    Button(action: {
                        // Settings action
                    }) {
                        Image("settings")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Content overlay
                VStack(spacing: 12) {
                    Text("AI Video Generator")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        // Action pentru video generation
                    }) {
                        Text("Create Video")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(width: UIScreen.main.bounds.width, height: 300)
        }
    }
}