# Story 1 : Squelette App + Navigation

**Priorité** : 🔴 Critique (bloque tout le reste)
**Dépendances** : Aucune
**Statut** : À faire

## Objectif
Créer l'app SwiftUI macOS "DevHub" avec navigation sidebar et structure de base.

## Architecture

```
DevHub/
├── DevHubApp.swift          // Point d'entrée, WindowGroup, settings fenêtre
├── Models/
│   └── Module.swift         // Enum des modules (cleaner, quickActions, projects, etc.)
├── Views/
│   ├── MainView.swift       // NavigationSplitView : sidebar + detail
│   ├── SidebarView.swift    // Liste des modules avec icônes
│   └── Placeholders/
│       └── PlaceholderView.swift  // Vue générique "Coming soon" par module
└── Resources/
    └── Assets.xcassets       // Couleurs custom, app icon
```

## Tasks

### 1. Créer projet Xcode
- SwiftUI macOS app, target macOS 14+
- Nom : "DevHub"
- Bundle ID : com.devhub.app
- Pas de storyboard, pur SwiftUI
- Désactiver App Sandbox (nécessaire pour shell commands)

### 2. Modèle Module
```swift
enum Module: String, CaseIterable, Identifiable {
    case cleaner = "Mac Cleaner"
    case quickActions = "Quick Actions"
    case projects = "Projects"
    case ports = "Port Manager"
    case git = "Git Dashboard"
    case devEnv = "Dev Environment"
    case system = "System Monitor"

    var id: String { rawValue }
    var icon: String { ... }        // SF Symbol name
    var description: String { ... }
    var color: Color { ... }        // Accent couleur par module
}
```

### 3. MainView — NavigationSplitView
- Sidebar gauche : liste des modules
- Zone détail droite : vue du module sélectionné
- `@State var selectedModule: Module? = .cleaner`
- Switch sur selectedModule pour afficher la bonne vue (PlaceholderView pour l'instant)

### 4. SidebarView
- Chaque item : icône SF Symbol + label
- Style : `.listRowBackground` custom, highlight sur sélection
- Section header "Modules" en haut
- Espacement propre entre items

### 5. Design & Style
- **Palette** :
  - Fond : couleur système sombre (`.background`)
  - Accents : gradient bleu (#007AFF) → violet (#5856D6)
  - Cartes : `.ultraThinMaterial` avec `RoundedRectangle(cornerRadius: 12)`
  - Texte : blanc principal, gris secondaire
- **Fenêtre** :
  - Taille par défaut : 1000×700
  - Taille minimum : 800×500
  - Titre barre : "DevHub"
- **Typographie** :
  - Titres : `.system(.title2, design: .rounded, weight: .bold)`
  - Body : `.system(.body, design: .rounded)`

### 6. PlaceholderView
- Prend un `Module` en paramètre
- Affiche : icône grande + nom module + "Coming soon" + description
- Centré verticalement et horizontalement
- Style cohérent avec le design global

## Critères de validation
- [ ] App compile et lance sans erreur
- [ ] Sidebar affiche 7 modules avec icônes
- [ ] Clic sur module → zone détail change
- [ ] Design sombre, propre, cohérent
- [ ] Fenêtre taille correcte et resizable
