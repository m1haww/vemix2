import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = FilterDataManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // AI Video Generator Header
                    VStack(spacing: 20) {
                        
                   
                        
                        
                    }
                    .padding(.top, 40)
                    
                    // Relive your memories section
                    ReliveMemoriesSection()
                
                    // Dynamic categories from JSON
                    ForEach(dataManager.categories) { category in
                        CategorySection(category: category)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Filters")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .background(Color.black.ignoresSafeArea())
    }
}

struct ReliveMemoriesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Relive your memories")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 180)
                    .overlay(
                        Image("memories")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    )
                
                Text("Animated Photo")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Color.black.opacity(0.7)
                            .cornerRadius(25)
                    )
                    .padding(8)
            }
        }
    }
}

struct CategorySection: View {
    let category: FilterCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(category.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(category.items) { item in
                        FilterCard(item: item, categoryId: category.id)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

struct FilterCard: View {
    let item: FilterItem
    let categoryId: String
    @State private var showVideoGenerator = false
    
    var body: some View {
        Button(action: {
            showVideoGenerator = true
        }) {
            ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    item.isGradient == true ?
                    AnyShapeStyle(LinearGradient(
                        colors: item.gradientColorsValues,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )) :
                    AnyShapeStyle(item.backgroundColorValue)
                )
                .frame(
                    width: categoryId == "trends" ? 200 : 150, 
                    height: categoryId == "trends" ? 220 : 180
                )
                .overlay(
                    Group {
                        if let imageName = item.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: categoryId == "trends" ? 200 : 150,
                                    height: categoryId == "trends" ? 220 : 180
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        
                        // Only show NEW badge if it exists
                        if item.hasNewBadge == true {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 20, height: 20)
                                        Text("NEW")
                                            .font(.system(size: 6))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 8)
                                    .padding(.trailing, 8)
                                }
                                Spacer()
                            }
                        }
                    }
                )
            
            Text(item.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color.black.opacity(0.7)
                        .cornerRadius(25)
                )
                .padding(8)
            }
        }
        .sheet(isPresented: $showVideoGenerator) {
            VideoGenerationView(selectedFilter: item)
        }
    }
}

struct CardOverlay: View {
    let item: FilterItem
    
    var body: some View {
        ZStack {
            if item.hasCustomContent == true {
                VStack {
                    Text("Google")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text("Veo\n3")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            
            if item.hasNewBadge == true {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            Text("NEW")
                                .font(.system(size: 6))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        FiltersView()
    }
}
