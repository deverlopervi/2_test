import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notConfigured
    case unauthorized
    case server(String)
    case notJSON(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "API URL không hợp lệ."
        case .invalidResponse: return "Phản hồi API không hợp lệ."
        case .notConfigured:
            return "Ứng dụng chưa được cấu hình API server (MHM_API_BASE_URL). Vui lòng build lại với cấu hình đúng."
        case .unauthorized: return "Tài khoản hoặc mật khẩu không hợp lệ."
        case .server(let message): return message
        case .notJSON(let host):
            return "Server \(host) không trả về JSON. Kiểm tra lại URL API trong Config.xcconfig."
        }
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: value) { return date }
            let iso2 = ISO8601DateFormatter()
            if let date = iso2.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        encoder.dateEncodingStrategy = .iso8601
    }

    func login(username: String, password: String) async throws -> MHMLoginResponse {
        let body = ["username": username, "password": password]
        return try await send(path: "mobile/login", method: "POST", token: nil, body: body)
    }

    func sync(token: String, since: Date? = nil) async throws -> MHMSyncPayload {
        var query: [URLQueryItem] = []
        if let since {
            let iso = ISO8601DateFormatter().string(from: since)
            query.append(URLQueryItem(name: "since", value: iso))
        }
        return try await send(path: "mobile/sync", method: "GET", token: token, query: query, body: Optional<String>.none)
    }

    func createCheckin(token: String, request: MHMCreateCheckinRequest) async throws -> MHMCheckin {
        try await send(path: "checkins", method: "POST", token: token, body: request)
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        token: String?,
        query: [URLQueryItem] = [],
        body: Body?
    ) async throws -> Response {
        // Chặn sớm nếu app chưa được cấu hình đúng API server.
        guard AppConfig.isAPIConfigured else { throw APIError.notConfigured }

        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 || http.statusCode == 403 { throw APIError.unauthorized }

        // Nếu server trả HTML (ví dụ trang lỗi WordPress, hoặc URL sai trỏ về example.com),
        // báo lỗi rõ ràng thay vì để JSONDecoder văng ra rồi in cả trang HTML lên UI.
        let contentType = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
        let looksLikeHTML = contentType.contains("text/html")
            || (data.prefix(15).map { Character(UnicodeScalar($0)) }
                    .reduce(into: "") { $0.append($1) }
                    .lowercased()
                    .contains("<!doctype") == true)

        guard (200..<300).contains(http.statusCode) else {
            if looksLikeHTML {
                throw APIError.notJSON(url.host ?? "server")
            }
            let raw = String(data: data, encoding: .utf8) ?? ""
            // Cố decode message JSON dạng { "message": "..." }
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = obj["message"] as? String ?? obj["error"] as? String {
                throw APIError.server(msg)
            }
            let trimmed = raw.count > 200 ? String(raw.prefix(200)) + "…" : raw
            throw APIError.server(trimmed.isEmpty ? "Server error \(http.statusCode)" : trimmed)
        }

        if looksLikeHTML { throw APIError.notJSON(url.host ?? "server") }

        return try decoder.decode(Response.self, from: data)
    }
}
