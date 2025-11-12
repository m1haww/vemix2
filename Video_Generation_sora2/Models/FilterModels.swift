import Foundation
import SwiftUI

struct FilterCategory: Codable, Identifiable {
    let id: String
    let title: String
    let items: [FilterItem]
}

struct FilterItem: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let backgroundColor: String
    let isGradient: Bool?
    let gradientColors: [String]?
    let hasCustomContent: Bool?
    let customText: String?
    let hasNewBadge: Bool?
    let imageName: String?
    
    var backgroundColorValue: Color {
        return Color(hex: backgroundColor)
    }
    
    var gradientColorsValues: [Color] {
        return gradientColors?.map { Color(hex: $0) } ?? []
    }
}

class FilterDataManager: ObservableObject {
    @Published var categories: [FilterCategory] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Could not load data.json")
            return
        }
        
        do {
            let response = try JSONDecoder().decode(FilterResponse.self, from: data)
            self.categories = response.categories
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
}

struct FilterResponse: Codable {
    let categories: [FilterCategory]
}