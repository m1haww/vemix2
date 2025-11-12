import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
            // Main content area that extends behind navigation
            Group {
                switch selectedTab {
                case 0:
                    FiltersView()
                case 1:
                    ExploreView()
                case 2:
                    VideosView()
                default:
                    FiltersView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            
            // Custom bottom navigation overlaid
            HStack(spacing: 0) {
                // Filtres tab
                CustomTabItem(
                    imageName: "Filtres",
                    title: "Filtres",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                // Explore tab
                CustomTabItem(
                    imageName: "Explore",
                    title: "Explore",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                // Videos tab
                CustomTabItem(
                    imageName: "Videos",
                    title: "Videos",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .frame(height: 90 + geometry.safeAreaInsets.bottom)
            
            .padding(.bottom, geometry.safeAreaInsets.bottom)
            .background(
                ZStack {
                    // Base blur effect
                    BlurView(style: .systemUltraThinMaterialDark)
                    
                    // Color overlay with reduced opacity
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "434343").opacity(0.4),
                            Color(hex: "000000").opacity(0.6)
                        ]),
                        startPoint: .bottomLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
            .ignoresSafeArea(.all, edges: .all)
            }
        }
        .background(Color.black)
        .ignoresSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}

struct CustomTabItem: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? Color(hex: "B951E7") : .white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color(hex: "B951E7") : .white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
