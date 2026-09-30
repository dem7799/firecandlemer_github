import Foundation

final class CategoryViewModel: ObservableObject {
    let category: Category
    @Published var videos: [VideoItem]

    init(category: Category) {
        self.category = category
        self.videos = category.videos
    }
}

