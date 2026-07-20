import Foundation

struct LibraryItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var category: String
    var excerpt: String
    var isBookmarked: Bool = false
    var readTime: Int  // minutes
    var icon: String

    static let samples: [LibraryItem] = [
        LibraryItem(title: "The Art of Stillness",    category: "Mindfulness", excerpt: "In a world of constant motion, stillness is a radical act.", isBookmarked: true,  readTime: 5, icon: "moon.stars.fill"),
        LibraryItem(title: "Gratitude as Practice",   category: "Gratitude",   excerpt: "Gratitude turns what we have into enough.",                  isBookmarked: false, readTime: 3, icon: "heart.fill"),
        LibraryItem(title: "Navigating Change",       category: "Growth",      excerpt: "Every transition holds the seed of transformation.",         isBookmarked: true,  readTime: 7, icon: "arrow.triangle.2.circlepath"),
        LibraryItem(title: "Roots and Wings",         category: "Connection",  excerpt: "The deepest connections grow from knowing yourself.",        isBookmarked: false, readTime: 4, icon: "person.2.fill"),
        LibraryItem(title: "The Inner Compass",       category: "Purpose",     excerpt: "Your values are your compass. Let them guide you home.",     isBookmarked: false, readTime: 6, icon: "safari.fill"),
        LibraryItem(title: "Weathering the Storm",    category: "Resilience",  excerpt: "Resilience is not the absence of pain, but its alchemy.",    isBookmarked: true,  readTime: 8, icon: "cloud.rain.fill"),
    ]
}
