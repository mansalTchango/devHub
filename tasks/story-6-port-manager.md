# Story 6 : Module Port Manager

**Priorité** : 🟡 Moyenne
**Dépendances** : Story 1 (navigation), Story 2 (ShellService)
**Statut** : À faire

## Objectif
Voir tous les ports réseau occupés et kill les process en un clic.

## Architecture

```
DevHub/
├── Models/
│   └── PortInfo.swift
├── ViewModels/
│   └── PortsViewModel.swift
└── Views/
    └── Ports/
        ├── PortsView.swift
        └── PortRow.swift
```

## Tasks

### 1. Modèle PortInfo

```swift
struct PortInfo: Identifiable {
    let id: UUID
    let port: Int
    let pid: Int
    let processName: String
    let user: String
    let protocol: String  // TCP/UDP
    let state: String     // LISTEN, ESTABLISHED, etc.
}
```

### 2. PortsViewModel

```swift
@MainActor
class PortsViewModel: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var searchText = ""
    @Published var isRefreshing = false
    @Published var autoRefresh = false

    var filteredPorts: [PortInfo] { ... }

    func refresh() async           // lsof -i -P -n | parse
    func kill(_ port: PortInfo) async
    func startAutoRefresh()        // Timer 5s
    func stopAutoRefresh()
}
```

- Parse output de `lsof -i -P -n -sTCP:LISTEN` pour ports en écoute
- Kill via `kill -9 {pid}`
- Filtre par numéro de port ou nom de process

### 3. PortsView

Layout tableau :
```
┌──────────────────────────────────────────────────────┐
│  🔌 Port Manager         [🔄 Refresh] [Auto: OFF]   │
│  ┌──────────────────────────────────────────────┐    │
│  │ 🔍 Filtrer par port ou process...            │    │
│  └──────────────────────────────────────────────┘    │
│──────────────────────────────────────────────────────│
│  Port    Process         PID      State    Action    │
│  ──────────────────────────────────────────────────  │
│  3000    node            12345    LISTEN   [Kill]    │
│  5432    postgres        6789     LISTEN   [Kill]    │
│  8080    java            11111    LISTEN   [Kill]    │
│  3001    next-server     22222    LISTEN   [Kill]    │
└──────────────────────────────────────────────────────┘
```

### 4. PortRow
- Port en bold monospace
- Nom process
- PID
- Badge état (LISTEN = bleu, ESTABLISHED = vert)
- Bouton Kill rouge avec confirmation

### 5. Features
- Refresh manuel + auto-refresh toggle (5s)
- Confirmation dialog avant kill
- Animation quand un port disparaît après kill
- Tri par port number (défaut)

## Critères de validation
- [ ] Liste les ports en écoute correctement
- [ ] Filtre par port ou process fonctionne
- [ ] Kill process fonctionne (avec confirmation)
- [ ] Auto-refresh fonctionne
- [ ] Port disparu après kill → animation
