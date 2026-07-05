# Story 2 : Service Shell + Utilitaires

**Priorité** : 🔴 Critique (utilisé par tous les modules)
**Dépendances** : Story 1 (projet Xcode doit exister)
**Statut** : À faire

## Objectif
Service réutilisable pour exécuter des commandes shell et calculer des tailles de dossiers.

## Architecture

```
DevHub/
├── Services/
│   └── ShellService.swift        // Exécution commandes shell async
└── Utilities/
    └── DiskSizeCalculator.swift  // Calcul taille dossiers
```

## Tasks

### 1. ShellService

```swift
struct ShellResult {
    let output: String
    let error: String
    let exitCode: Int32
    var success: Bool { exitCode == 0 }
}

actor ShellService {
    static let shared = ShellService()

    func run(_ command: String, timeout: TimeInterval = 30) async throws -> ShellResult
    func run(executable: String, arguments: [String], timeout: TimeInterval = 30) async throws -> ShellResult
}
```

- Utilise `Process()` + `Pipe()` pour stdout/stderr
- Exécution sur thread background (pas bloquer MainActor)
- Timeout configurable (défaut 30s), throw si dépassé
- Gestion erreurs : commande introuvable, permission denied, timeout

### 2. DiskSizeCalculator

```swift
struct DiskSizeCalculator {
    /// Calcule taille d'un dossier en bytes
    static func sizeOfDirectory(at path: String) async -> UInt64

    /// Formate bytes en string lisible (ex: "39.2 Go")
    static func formatBytes(_ bytes: UInt64) -> String

    /// Vérifie si un dossier existe
    static func directoryExists(at path: String) -> Bool
}
```

- Utilise `FileManager` pour scan récursif
- Format : Go (> 1 Go), Mo (> 1 Mo), Ko sinon
- Gère le cas dossier inexistant → retourne 0

### 3. Gestion erreurs

```swift
enum ShellError: LocalizedError {
    case commandNotFound(String)
    case permissionDenied(String)
    case timeout(TimeInterval)
    case executionFailed(exitCode: Int32, stderr: String)
}
```

## Critères de validation
- [ ] `ShellService.run("echo hello")` retourne "hello" dans output
- [ ] `ShellService.run("ls /nonexistent")` retourne exitCode != 0 avec stderr
- [ ] `DiskSizeCalculator.sizeOfDirectory` retourne taille correcte
- [ ] `DiskSizeCalculator.formatBytes` formate correctement (Go/Mo/Ko)
- [ ] Timeout fonctionne (commande `sleep 60` avec timeout 2s → throw)
