import Foundation
import CoreLocation

@MainActor
final class SyncEngine: ObservableObject {
    // Core (đã có sẵn từ /mobile/sync)
    @Published private(set) var hazards: [MHMHazard] = []
    @Published private(set) var checkins: [MHMCheckin] = []
    @Published private(set) var journey: [MHMJourneyPoint] = []

    // Bổ sung để có parity với website
    @Published private(set) var pings: [MHMPing] = []
    @Published private(set) var reports: [MHMReport] = []
    @Published private(set) var rescueTeams: [MHMRescueTeam] = []
    @Published private(set) var chatThreads: [MHMChatThread] = []
    @Published private(set) var categories: [MHMCategory] = []
    @Published private(set) var profile: MHMUser?

    @Published var errorMessage: String?
    @Published var isSyncing = false

    /// Trạng thái từng phần dữ liệu phụ — để UI biết endpoint nào lỗi
    /// mà không kéo cả sync fail theo.
    @Published private(set) var moduleErrors: [String: String] = [:]

    private var authStore: AuthStore?
    private let api = APIClient()
    private var lastSyncDate: Date?

    func configure(authStore: AuthStore) async {
        self.authStore = authStore
        if authStore.isLoggedIn {
            await sync()
        }
    }

    /// Sync toàn bộ dữ liệu app cần sau login — chạy song song
    /// tất cả endpoint phụ để login xong có dữ liệu ngay.
    func sync(currentLocation: CLLocationCoordinate2D? = nil) async {
        guard let token = authStore?.token, !token.isEmpty else { return }
        isSyncing = true
        errorMessage = nil
        moduleErrors.removeAll()
        defer { isSyncing = false }

        // 1) Core sync
        do {
            let payload = try await api.sync(token: token, since: lastSyncDate)
            merge(payload)
            lastSyncDate = payload.serverTime ?? Date()
            if let u = payload.user { profile = u }
        } catch {
            errorMessage = error.localizedDescription
        }

        // 2) Các module song song
        let coord: MHMCoordinate? = currentLocation.map {
            MHMCoordinate(lat: $0.latitude, lng: $0.longitude)
        }

        async let meTask         = safe("me")         { try await self.api.me(token: token) }
        async let pingsTask      = safe("pings")      { try await self.api.pings(token: token) }
        async let reportsTask    = safe("reports")    { try await self.api.reports(token: token) }
        async let rescueTask     = safe("rescue")     { try await self.api.nearbyRescueTeams(token: token, coordinate: coord) }
        async let chatTask       = safe("chat")       { try await self.api.chatThreads(token: token) }
        async let categoriesTask = safe("categories") { try await self.api.categories(token: token) }

        let (me, pingList, reportList, rescueList, chatList, catList) =
            await (meTask, pingsTask, reportsTask, rescueTask, chatTask, categoriesTask)

        if let me { profile = me }
        if let pingList { pings = pingList }
        if let reportList { reports = reportList }
        if let rescueList { rescueTeams = rescueList }
        if let chatList { chatThreads = chatList }
        if let catList { categories = catList }
    }

    func createCheckin(title: String, note: String?, coordinate: CLLocationCoordinate2D) async {
        guard let token = authStore?.token, !token.isEmpty else { return }
        do {
            let created = try await api.createCheckin(
                token: token,
                request: MHMCreateCheckinRequest(
                    title: title,
                    note: note,
                    lat: coordinate.latitude,
                    lng: coordinate.longitude
                )
            )
            upsertCheckin(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Chạy 1 network call, nuốt lỗi và ghi vào `moduleErrors`
    /// để 1 endpoint hỏng không kéo cả sync fail theo.
    private func safe<T>(_ key: String, _ work: @escaping () async throws -> T) async -> T? {
        do { return try await work() }
        catch {
            moduleErrors[key] = error.localizedDescription
            return nil
        }
    }

    private func merge(_ payload: MHMSyncPayload) {
        payload.hazards.forEach { upsertHazard($0) }
        payload.checkins.forEach { upsertCheckin($0) }
        journey = payload.journey
    }

    private func upsertHazard(_ hazard: MHMHazard) {
        hazards.removeAll { $0.id == hazard.id }
        hazards.append(hazard)
    }

    private func upsertCheckin(_ checkin: MHMCheckin) {
        checkins.removeAll { $0.id == checkin.id }
        checkins.append(checkin)
    }
}
