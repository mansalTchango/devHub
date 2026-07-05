# Story 9 : Module System Monitor

**Priorité** : 🟢 Basse
**Dépendances** : Story 1 (navigation)
**Statut** : À faire

## Objectif
Widgets compacts montrant CPU, RAM, disque et batterie en temps réel.

## Architecture

```
DevHub/
├── ViewModels/
│   └── SystemViewModel.swift
└── Views/
    └── System/
        ├── SystemView.swift
        ├── GaugeWidget.swift       // Jauge circulaire réutilisable
        └── MetricCard.swift
```

## Tasks

### 1. SystemViewModel

```swift
@MainActor
class SystemViewModel: ObservableObject {
    @Published var cpuUsage: Double = 0        // 0-100
    @Published var ramUsed: UInt64 = 0
    @Published var ramTotal: UInt64 = 0
    @Published var diskUsed: UInt64 = 0
    @Published var diskTotal: UInt64 = 0
    @Published var batteryLevel: Int = 0       // 0-100
    @Published var isCharging: Bool = false

    var ramPercentage: Double { ... }
    var diskPercentage: Double { ... }

    private var timer: Timer?

    func startMonitoring()     // Timer 2s
    func stopMonitoring()
    func refresh() async
}
```

Commandes pour métriques :
- **CPU** : `top -l 1 -n 0 | grep "CPU usage"` → parse idle%
- **RAM** : `vm_stat` → parse pages free/active/inactive/wired
- **Disque** : `df -h /` → parse used/total
- **Batterie** : `pmset -g batt` → parse percentage + charging

### 2. SystemView

Layout 2×2 widgets :
```
┌──────────────────────────────────────────────┐
│  📊 System Monitor                           │
│──────────────────────────────────────────────│
│  ┌───────────────┐  ┌───────────────┐        │
│  │   ╭───╮       │  │   ╭───╮       │        │
│  │   │45%│  CPU  │  │   │72%│  RAM  │        │
│  │   ╰───╯       │  │   ╰───╯       │        │
│  │  Idle: 55%    │  │ 12/16 Go used │        │
│  └───────────────┘  └───────────────┘        │
│  ┌───────────────┐  ┌───────────────┐        │
│  │   ╭───╮       │  │   🔋          │        │
│  │   │78%│ Disk  │  │   87%         │        │
│  │   ╰───╯       │  │   Battery     │        │
│  │ 380/500 Go    │  │ ⚡ Charging    │        │
│  └───────────────┘  └───────────────┘        │
└──────────────────────────────────────────────┘
```

### 3. GaugeWidget
- Anneau circulaire animé (SwiftUI `Canvas` ou `Shape`)
- Pourcentage au centre en gros
- Couleur dynamique : vert (<60%), orange (60-80%), rouge (>80%)
- Animation `.spring()` sur changement de valeur
- Label en dessous

### 4. MetricCard
- Fond `.ultraThinMaterial`
- `RoundedRectangle(cornerRadius: 16)`
- GaugeWidget + détails texte
- Taille uniforme dans la grille

### 5. Alertes visuelles
- CPU > 80% → bordure rouge pulsante
- RAM > 90% → bordure rouge pulsante
- Disque > 90% → bordure rouge pulsante
- Batterie < 20% et pas en charge → bordure orange

## Critères de validation
- [ ] 4 widgets affichent métriques en temps réel
- [ ] Refresh toutes les 2s, animations fluides
- [ ] Couleurs changent selon seuils
- [ ] Alertes visuelles fonctionnent
- [ ] Valeurs cohérentes avec Activity Monitor
