import SwiftUI
import SwiftData

@main
struct InspirationInboxApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .modelContainer(env.store.container)
                .task { await env.onLaunch() }
        }
    }
}
