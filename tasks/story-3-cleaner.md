# Story 3 : Module Mac Cleaner

**Priorité** : 🟠 Haute
**Dépendances** : Story 1 (navigation), Story 2 (ShellService + DiskSizeCalculator)
**Statut** : À faire

## Objectif
Module de nettoyage : scanner les caches dev, afficher tailles réelles, nettoyer en un clic.

## Architecture

```
DevHub/
├── Models/
│   └── CleaningTask.swift
├── ViewModels/
│   └── CleanerViewModel.swift
└── Views/
    └── Cleaner/
        ├── CleanerView.swift         // Vue principale du module
        └── CleaningTaskCard.swift    // Carte individuelle
```

## Tasks

### 1. Modèle CleaningTask

```swift
struct CleaningTask: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String              // SF Symbol
    let command: String           // Commande shell à exécuter
    let targetPaths: [String]     // Dossiers à scanner pour taille
    var status: TaskStatus = .idle
    var scannedSize: UInt64 = 0
    var freedSize: UInt64 = 0
}

enum TaskStatus {
    case idle, scanning, ready, cleaning, done, error(String)
}
```

### 2. Les 7 tâches de nettoyage

| # | Nom | Commande | Dossiers à scanner |
|---|-----|----------|-------------------|
| 1 | Xcode DerivedData | `rm -rf ~/Library/Developer/Xcode/DerivedData/*` | `~/Library/Developer/Xcode/DerivedData` |
| 2 | Simulateurs unavailable | `xcrun simctl delete unavailable` | — (pas de scan, taille après) |
| 3 | iOS DeviceSupport | `rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*` | `~/Library/Developer/Xcode/iOS DeviceSupport` |
| 4 | Cache Yarn | `yarn cache clean` | `~/Library/Caches/Yarn` |
| 5 | Cache Arc | `rm -rf ~/Library/Caches/Arc/*` | `~/Library/Caches/Arc` |
| 6 | Cache CocoaPods | `pod cache clean --all` | `~/Library/Caches/CocoaPods` |
| 7 | Caches misc | `rm -rf ~/Library/Caches/Cypress ~/Library/Caches/ms-playwright ~/Library/Caches/typescript` | Les 3 dossiers listés |

### 3. CleanerViewModel

```swift
@MainActor
class CleanerViewModel: ObservableObject {
    @Published var tasks: [CleaningTask] = [...]
    @Published var isScanning = false
    @Published var totalFreed: UInt64 = 0

    func scanAll() async          // Scanner tailles de tous les dossiers
    func clean(_ task: CleaningTask) async   // Nettoyer une tâche
    func cleanAll() async         // Nettoyer toutes les tâches (séquentiel)
}
```

- `scanAll()` : lance au chargement, met à jour `scannedSize` de chaque tâche
- `clean()` : exécute commande via ShellService, calcule espace libéré (taille avant - après)
- `cleanAll()` : confirmation dialog d'abord, puis exécute séquentiellement

### 4. CleanerView (vue principale)

Layout :
```
┌─────────────────────────────────────────────┐
│  🧹 Mac Cleaner          [Tout nettoyer]    │
│  Total récupérable : 106.2 Go               │
│─────────────────────────────────────────────│
│  ┌─────────────────────────────────────┐    │
│  │ 📁 Xcode DerivedData    39.2 Go    │    │
│  │ Fichiers de build Xcode  [Nettoyer] │    │
│  │ ████████████████░░░░░     ✅ Done   │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ 📱 Simulateurs          15.1 Go    │    │
│  │ Simulateurs obsolètes   [Nettoyer] │    │
│  └─────────────────────────────────────┘    │
│  ... (5 autres cartes)                      │
└─────────────────────────────────────────────┘
```

### 5. CleaningTaskCard

- Icône + Nom + Description
- Taille scannée (formatée en Go/Mo)
- Bouton "Nettoyer" (désactivé si 0 Go ou en cours)
- Barre de progression animée pendant nettoyage
- Badge statut : gris (idle), bleu (scanning), orange (cleaning), vert (done), rouge (error)
- Espace libéré affiché après nettoyage

### 6. Animations & Polish

- Compteur animé pour total espace libéré
- `.spring()` transition sur changement de statut
- Cartes en `.ultraThinMaterial` + `RoundedRectangle(cornerRadius: 12)`
- Items à 0 Go : opacité réduite, bouton désactivé

## Critères de validation
- [ ] Scan au chargement affiche tailles réelles
- [ ] Bouton individuel nettoie et montre espace libéré
- [ ] "Tout nettoyer" demande confirmation puis exécute tout
- [ ] Items à 0 Go grisés
- [ ] Animations fluides
- [ ] Erreurs affichées proprement (pas de crash)
