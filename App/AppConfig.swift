import Foundation

enum AppConfig {
    /// Fallback dùng khi Info.plist thiếu key (chỉ để app không crash;
    /// UI sẽ hiển thị lỗi rõ ràng qua `isAPIConfigured`).
    private static let fallbackBaseURL = URL(string: "https://maps.toctruongbiker.com/wp-json/mhm/v1")!

    static var apiBaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "MHM_API_BASE_URL") as? String
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Bỏ token "$()" mà xcconfig chèn để né việc // bị coi là comment.
        let cleaned = value.replacingOccurrences(of: "$()", with: "")
        return URL(string: cleaned).filterValidURL ?? fallbackBaseURL
    }

    static var goongAPIKey: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "GOONG_API_KEY") as? String
        return raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// True nếu Info.plist thực sự có URL hợp lệ (khác fallback).
    static var isAPIConfigured: Bool {
        let raw = Bundle.main.object(forInfoDictionaryKey: "MHM_API_BASE_URL") as? String
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleaned = value.replacingOccurrences(of: "$()", with: "")
        guard let url = URL(string: cleaned), let scheme = url.scheme,
              ["http", "https"].contains(scheme), let host = url.host, !host.isEmpty,
              host != "example.com" else { return false }
        return true
    }
}

private extension Optional where Wrapped == URL {
    var filterValidURL: URL? {
        guard let url = self,
              let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              let host = url.host,
              !host.isEmpty,
              host != "example.com"
        else { return nil }
        return url
    }
}
