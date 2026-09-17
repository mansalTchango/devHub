import SwiftUI

@main
struct DevHubApp: App {
    init() {
        // Barre menus pleine + encoche : un nouvel item se place tout à gauche, caché derrière l'encoche.
        // Position par défaut (pts depuis le bord droit) ; ⌘+glisser de l'utilisateur écrase cette valeur.
        UserDefaults.standard.register(defaults: ["NSStatusItem Preferred Position Item-0": 220.0])

        // Warm up the user PATH lookup off the main thread (spawns an interactive shell)
        Task.detached(priority: .userInitiated) { _ = ShellEnvironment.resolved }
    }

    var body: some Scene {
        // Fenêtre unique : la fermer garde les process vivants (accessibles via barre menus),
        // seul Quit les arrête (ProcessManager écoute willTerminate)
        Window("DevHub", id: AppRouter.mainWindowID) {
            MainView()
        }
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
