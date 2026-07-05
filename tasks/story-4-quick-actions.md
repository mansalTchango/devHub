# Story 4 : Module Quick Actions

**Priorité** : 🟠 Haute
**Dépendances** : Story 1 (navigation), Story 2 (ShellService)
**Statut** : À faire

## Objectif
Grille de boutons pour actions système rapides fréquemment utilisées par un dev.

## Architecture

```
DevHub/
├── Models/
│   └── QuickAction.swift
├── ViewModels/
│   └── QuickActionsViewModel.swift
└── Views/
    └── QuickActions/
        ├── QuickActionsView.swift      // Vue principale grille
        └── ActionButton.swift          // Bouton individuel
```

## Tasks

### 1. Modèle QuickAction

```swift
struct QuickAction: Identifiable {
    let id: UUID
    let name: String
    let icon: String           // SF Symbol
    let command: String
    let needsSudo: Bool
    let needsInput: Bool       // Ex: kill port → input numéro
    let inputPlaceholder: String?
    let category: ActionCategory
    var lastRun: Date?
}

enum ActionCategory: String, CaseIterable {
    case system = "Système"
    case dev = "Développement"
    case cleanup = "Nettoyage"
}
```

### 2. Actions prédéfinies

| Action | Commande | Sudo | Input |
|--------|----------|------|-------|
| Kill Port | `lsof -ti:{port} \| xargs kill -9` | Non | Oui (port) |
| Flush DNS | `dscacheutil -flushcache && killall -HUP mDNSResponder` | Oui | Non |
| Restart Dock | `killall Dock` | Non | Non |
| Purge RAM | `purge` | Oui | Non |
| Vider Corbeille | `rm -rf ~/.Trash/*` | Non | Non |
| Rebuild Spotlight | `mdutil -E /` | Oui | Non |
| Kill Xcode | `killall Xcode` | Non | Non |
| Restart Finder | `killall Finder` | Non | Non |
| Clear Downloads 30j+ | `find ~/Downloads -mtime +30 -delete` | Non | Non |
| Restart Audio | `killall coreaudiod` | Oui | Non |

### 3. QuickActionsViewModel

```swift
@MainActor
class QuickActionsViewModel: ObservableObject {
    @Published var actions: [QuickAction] = [...]
    @Published var runningAction: UUID? = nil
    @Published var lastResult: (UUID, Bool)? = nil  // (id, success)

    func run(_ action: QuickAction, input: String?) async
}
```

- Gestion sudo : utiliser `osascript -e 'do shell script "..." with administrator privileges'`
- Feedback : animation succès (checkmark vert) ou erreur (x rouge) pendant 2s

### 4. QuickActionsView

Layout grille :
```
┌──────────────────────────────────────────────┐
│  ⚡ Quick Actions                            │
│──────────────────────────────────────────────│
│  Système                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ 🔄 Flush │ │ 🖥 Dock  │ │ 🧠 Purge │    │
│  │   DNS    │ │ Restart  │ │   RAM    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│  Développement                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ 🔌 Kill  │ │ 🔨 Kill  │ │ 🔍 Rebuild│   │
│  │  Port    │ │  Xcode   │ │ Spotlight │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│  Nettoyage                                   │
│  ┌──────────┐ ┌──────────┐                  │
│  │ 🗑 Vider │ │ 📥 Clear │                  │
│  │ Corbeille│ │Downloads │                  │
│  └──────────┘ └──────────┘                  │
└──────────────────────────────────────────────┘
```

### 5. ActionButton

- Bouton carré ~120×100px
- Icône SF Symbol grande au centre
- Label en dessous
- Hover : léger scale up + ombre
- Clic : animation press
- Pendant exécution : spinner
- Après : checkmark vert (2s) ou X rouge (2s)
- Si `needsInput` : popover avec TextField avant exécution

### 6. Gestion Sudo

Pour les commandes nécessitant sudo :
```swift
// Utiliser osascript pour prompt système natif
let script = "do shell script \"\(command)\" with administrator privileges"
let result = try await ShellService.shared.run(
    executable: "/usr/bin/osascript",
    arguments: ["-e", script]
)
```

## Critères de validation
- [ ] Grille affiche toutes les actions groupées par catégorie
- [ ] Actions sans sudo s'exécutent directement
- [ ] Actions sudo demandent mot de passe via dialog système
- [ ] Kill Port affiche input pour numéro de port
- [ ] Animation succès/erreur visible
- [ ] Hover et press feedback sur les boutons
