import Foundation

struct Category: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let backgroundImageName: String
    let backgroundVideoName: String?
    let videos: [VideoItem]

    init(id: String,
         title: String,
         backgroundImageName: String,
         backgroundVideoName: String? = nil,
         videos: [VideoItem]) {
        self.id = id
        self.title = title
        self.backgroundImageName = backgroundImageName
        self.backgroundVideoName = backgroundVideoName
        self.videos = videos
    }
}
