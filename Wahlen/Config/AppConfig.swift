import Foundation

enum AppConfig {
    static let supabaseURL = "https://hdhueuihmxbskiusenpe.supabase.co"
    static let supabaseAnonKey = "sb_publishable_H6YjVStNvwY-VnZuZCYDxw_mOWEvAAW"

    static let webBaseURL = "https://fsbs-wahlen.vercel.app"
    static let ballotPath = "/abstimmung.html"

    static func ballotURL(for token: String) -> URL {
        var components = URLComponents(string: webBaseURL + ballotPath)!
        components.queryItems = [URLQueryItem(name: "s", value: token)]
        return components.url!
    }

    static var supabaseURLValue: URL { URL(string: supabaseURL)! }
}
