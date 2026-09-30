import Foundation

final class HomeViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading: Bool = true

    func load() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let data = DataProvider.shared.loadCategories()
            DispatchQueue.main.async {
                self.categories = data
                self.isLoading = false
            }
        }
    }
}

