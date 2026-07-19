import Foundation
import CoreLocation

@MainActor
final class SyncEngine: ObservableObject {
    @Published private(set) var hazards: [MHMHazard] = []
    @Published private(set) var checkins: [MHMCheckin] = []
    @Published private(set) var journey: [MHMJourneyPoint] = []
    @Published var errorMessage: String?
    @Published var isSyncing = false

    private var authStore: AuthStore?
    private let api = APIClient()
    private var lastSyncDate: Date?

    func configure(authStore: AuthStore) async {
        self.authStore = authStore
        if authStore.isLoggedIn {
            await sync()
        }
    }

    func sync() async {
        guard let token = authStore?.token, !token.isEmpty else { return }
        isSyncing = true
        errorMessage = nil
        defer { isSyncing = false }
        do {
            let payload = try await api.sync(token: token, since: lastSyncDate)
            merge(payload)
            lastSyncDate = payload.serverTime ?? Date()
        } catch {
            errorMessage = error.localizedDescription
        }
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
