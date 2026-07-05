# Story 8 : Module Dev Environment

**Priorité** : 🟢 Basse
**Dépendances** : Story 1 (navigation), Story 2 (ShellService)
**Statut** : À faire

## Objectif
Voir les versions de tous les outils dev installés et les mettre à jour.

## Architecture

```
DevHub/
├── Models/
│   └── DevTool.swift
├── ViewModels/
│   └── DevEnvViewModel.swift
└── Views/
    └── DevEnv/
        ├── DevEnvView.swift
        └── ToolRow.swift
```

## Tasks

### 1. Modèle DevTool

```swift
struct DevTool: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let versionCommand: String      // ex: "node --version"
    let updateCommand: String?      // ex: "brew upgrade node"
    var installedVersion: String?
    var isInstalled: Bool
    var isUpdating: Bool = false
}
```

### 2. Outils à détecter

| Outil | Commande version | Commande update |
|-------|-----------------|-----------------|
| Node.js | `node --version` | `brew upgrade node` |
| npm | `npm --version` | `npm install -g npm` |
| Yarn | `yarn --version` | `brew upgrade yarn` |
| pnpm | `pnpm --version` | `brew upgrade pnpm` |
| Python | `python3 --version` | `brew upgrade python` |
| Ruby | `ruby --version` | `brew upgrade ruby` |
| Git | `git --version` | `brew upgrade git` |
| Xcode | `xcodebuild -version` | — (App Store) |
| Homebrew | `brew --version` | `brew update` |
| CocoaPods | `pod --version` | `gem install cocoapods` |
| Docker | `docker --version` | — (Docker Desktop) |
| Go | `go version` | `brew upgrade go` |
| Rust | `rustc --version` | `rustup update` |

### 3. DevEnvViewModel

```swift
@MainActor
class DevEnvViewModel: ObservableObject {
    @Published var tools: [DevTool] = [...]
    @Published var isScanning = false

    func scanAll() async           // Détecter versions
    func update(_ tool: DevTool) async
    func updateAll() async         // brew update && brew upgrade
}
```

### 4. DevEnvView

```
┌──────────────────────────────────────────────┐
│  🛠 Dev Environment          [Update All]    │
│──────────────────────────────────────────────│
│  Outil          Version       Action         │
│  ────────────────────────────────────────────│
│  ⬢ Node.js      v20.11.0     [Update]       │
│  📦 npm          10.2.4       [Update]       │
│  🧶 Yarn         1.22.21      [Update]       │
│  🐍 Python       3.12.1       [Update]       │
│  💎 Ruby         3.3.0        [Update]       │
│  🔀 Git          2.43.0       [Update]       │
│  🔨 Xcode        15.2         App Store      │
│  🍺 Homebrew     4.2.4        [Update]       │
│  ❌ Docker       Non installé  —             │
└──────────────────────────────────────────────┘
```

### 5. ToolRow
- Icône + Nom
- Version (vert si installé, gris "Non installé" sinon)
- Bouton Update (spinner pendant update)
- Pas de bouton si pas de commande update

## Critères de validation
- [ ] Détecte versions de tous les outils installés
- [ ] "Non installé" pour les outils absents
- [ ] Update individuel fonctionne
- [ ] Update All fonctionne
