import Foundation

enum AppConfig {
    // Base CDN URL; final URL = cdnBase + videoKey + ".mp4"
    // Replace with your external cloud storage root URL ending with a trailing slash "/"
    static let cdnBase: String = "https://YOUR_STORAGE_URL_OR_CDN_BASE_PATH/"
}
