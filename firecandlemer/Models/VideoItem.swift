import Foundation

struct VideoItem: Identifiable, Decodable, Hashable {
    let id: String
    let previewImageName: String
    let videoKey: String
    let isFree: Bool

    var videoURL: URL {
        // Build full URL from base + key + .mp4
        let path = AppConfig.cdnBase + videoKey + ".mp4"
        return URL(string: path) ?? URL(string: AppConfig.cdnBase)!
    }

    enum CodingKeys: String, CodingKey {
        case id
        case previewImageName
        case videoURL
        case free
    }

    init(id: String, previewImageName: String, videoKey: String) {
        self.id = id
        self.previewImageName = previewImageName
        self.videoKey = videoKey
        self.isFree = false
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let previewImageName = try container.decode(String.self, forKey: .previewImageName)
        // Accept raw key like "fire1" or "fireplace/fire1" in videoURL
        let raw = try container.decode(String.self, forKey: .videoURL)
        let key = (raw as NSString).deletingPathExtension // strip .mp4 if included
        // id may be absent in JSON; derive from key
        let id = (try? container.decode(String.self, forKey: .id)) ?? key
        self.id = id
        self.previewImageName = previewImageName
        self.videoKey = key
        self.isFree = (try? container.decodeIfPresent(Bool.self, forKey: .free)) ?? false
    }
}
