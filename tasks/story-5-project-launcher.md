# Story 5A : Module Project Launcher

**Priorité** : 🟡 Moyenne
**Dépendances** : Story 1 (navigation), Story 2 (ShellService)
**Statut** : ✅ Fait

## Objectif
Scanner et lister tous les projets dev, ouvrir rapidement dans VS Code / Terminal / Finder.
Lancer des commandes configurables par projet (dev/staging/prod) dans Terminal.

## Scan paths (fixés)
- `~/Documents/perso`
- `~/Documents/pro`

## Architecture

```
DevHub/
├── Models/
│   └── Project.swift              // Project, ProjectType, LaunchCommand, LaunchEnvironment
├── ViewModels/
│   └── ProjectsViewModel.swift    // Scan, actions, persistence launch commands
└── Views/
    └── Projects/
        ├── ProjectsView.swift     // Vue principale + LaunchCommandsSheet
        └── ProjectCard.swift      // Carte projet
```

## Fichiers créés
- [x] `Models/Project.swift` — struct Project, enum ProjectType, struct LaunchCommand, enum LaunchEnvironment
- [x] `ViewModels/ProjectsViewModel.swift` — scan async, détection type, git info, actions, persistence
- [x] `Views/Projects/ProjectsView.swift` — vue principale avec recherche, filtres, groupement par dossier
- [x] `Views/Projects/ProjectCard.swift` — carte projet avec boutons ouvrir + lancer
- [x] `Views/MainView.swift` — branché `.projects: ProjectsView()`

## Fonctionnalités implémentées

### Scan
- Scan récursif profondeur max 3
- Ignore : node_modules, .git, build, DerivedData, venv, etc.
- Détection type via fichiers marqueurs (package.json, Package.swift, etc.)
- Git info : branche + dirty/clean via ShellService

### Actions par projet
- **Ouvrir** : VS Code, Terminal, Finder, Xcode (si Swift)
- **Lancer** : commandes configurables (Dev/Staging/Prod/Custom)
  - Exécution via AppleScript → Terminal
  - Persistance dans UserDefaults

### Vue
- Recherche par nom/path
- Filtre par type (Node.js, Swift, Python, Rust, Go)
- Groupement par dossier (perso / pro)
- Tri par dernière modification
- Carte avec hover effect, badge git, date relative

## Critères de validation
- [x] Scan trouve les projets dans ~/Documents/perso et ~/Documents/pro
- [x] Type projet détecté correctement
- [x] Git branch et dirty/clean affichés
- [x] Ouverture VS Code / Terminal / Finder / Xcode fonctionne
- [x] Recherche et filtre par type fonctionnent
- [x] Launch commands configurables et persistées
- [x] Build passe

---

# Story 5B : Process Manager (À faire)

## Objectif
Lancer les projets depuis DevHub avec logs centralisés, groupés par dossier. Remplace les multiples fenêtres Terminal.

## Fonctionnalités prévues
- Lancer Process() long-running depuis DevHub
- Capture stdout/stderr en streaming
- Affichage logs temps réel par projet
- Groupement par dossier parent
- Boutons Stop/Restart par projet
- Bouton "Stop All"
- Durée d'exécution affichée
