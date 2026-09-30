import Foundation

final class DataProvider {
    static let shared = DataProvider()
    private init() {}

    func loadCategories() -> [Category] {
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json") else {
            print("categories.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var cats = try decoder.decode([Category].self, from: data)
            #if DEBUG
            print("[DataProvider] Loaded categories.json from: \(url.lastPathComponent), count=\(cats.count)")
            #endif
            // Backfill backgroundVideoName if JSON is old but file exists in Data/
            cats = cats.map { cat in
                if cat.backgroundVideoName != nil { return cat }
                let candidates = ["\(cat.backgroundImageName)_video", cat.backgroundImageName]
                if let found = locateVideoName(inDataFolderFrom: candidates) {
                    return Category(id: cat.id,
                                    title: cat.title,
                                    backgroundImageName: cat.backgroundImageName,
                                    backgroundVideoName: found,
                                    videos: cat.videos)
                }
                return cat
            }
            return cats
        } catch {
            print("Failed to decode categories.json: \(error)")
            return []
        }
    }

    private func locateVideoName(inDataFolderFrom names: [String]) -> String? {
        for name in names {
            let base = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            if let _ = Bundle.main.url(forResource: ext.isEmpty ? base : name, withExtension: ext.isEmpty ? nil : ext, subdirectory: "Data") { return base }
            if let _ = Bundle.main.url(forResource: base, withExtension: "mp4", subdirectory: "Data") { return base }
        }
        return nil
    }
}
