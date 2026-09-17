import SwiftUI

/// Navigation de la fenêtre principale pilotée depuis l'extérieur (panneau barre menus)
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    static let mainWindowID = "main"

    /// Module demandé — consommé par MainView puis remis à nil
    @Published var requestedModule: Module?

    private init() {}
}
