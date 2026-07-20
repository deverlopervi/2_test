import SwiftUI

@main
struct MuleHazardMapApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var syncEngine = SyncEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .environmentObject(syncEngine)
                .task {
                    // Cho AuthStore biết SyncEngine để login xong tự
                    // kéo full data (me, pings, reports, chat, rescue, categories).
                    authStore.syncEngine = syncEngine
                    await syncEngine.configure(authStore: authStore)
                }
        }
    }
}
