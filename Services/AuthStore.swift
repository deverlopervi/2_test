import Foundation

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var user: MHMUser?
    @Published var errorMessage: String?
    @Published var isBusy = false

    private let tokenKey = "mhm.mobile.auth.token"
    private let api = APIClient()

    /// SyncEngine được gắn từ App root để login xong có thể trigger
    /// full sync tất cả module (pings/reports/chat/rescue/categories/me).
    weak var syncEngine: SyncEngine?

    var isLoggedIn: Bool { token?.isEmpty == false }

    init() {
        token = KeychainStore.shared.get(tokenKey)
    }

    func login(username: String, password: String) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let response = try await api.login(username: username, password: password)
            token = response.token
            user = response.user
            KeychainStore.shared.set(response.token, for: tokenKey)

            // Sau khi login OK, kéo toàn bộ dữ liệu như website.
            await syncEngine?.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        token = nil
        user = nil
        KeychainStore.shared.delete(tokenKey)
    }
}
