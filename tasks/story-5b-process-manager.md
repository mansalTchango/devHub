# Story 5B : Process Manager

**Priorité** : 🟡 Moyenne
**Dépendances** : Story 1 (navigation), Story 2 (ShellService), Story 5A (projets + launch commands)
**Statut** : 🔲 À faire

## Objectif

Lancer les projets depuis DevHub avec logs centralisés. Remplace les multiples fenêtres Terminal par une vue unique groupée par projet.

## Architecture

```
DevHub/
├── Models/
│   └── RunningProcess.swift         // Modèle process en cours
├── Services/
│   └── ProcessManager.swift         // Gestion Process() long-running
├── ViewModels/
│   └── ProcessManagerViewModel.swift
└── Views/
    └── Processes/
        ├── ProcessManagerView.swift  // Vue principale
        ├── ProcessLogView.swift      // Vue logs temps réel
        └── ProcessCard.swift         // Carte process compact
```

## Modèles

### RunningProcess
- `id: UUID`
- `projectName: String`
- `projectPath: String`
- `command: LaunchCommand`
- `process: Process` (Foundation)
- `status: ProcessStatus` (.running, .stopped, .errored, .finished)
- `logs: [LogLine]` — stdout + stderr avec timestamp
- `startedAt: Date`
- `pid: Int32`

### LogLine
- `id: UUID`
- `text: String`
- `timestamp: Date`
- `source: LogSource` (.stdout, .stderr)

## Service : ProcessManager

Actor singleton qui gère les Process() :

- `start(command:, projectPath:)` → lance Process(), pipe stdout/stderr
- `stop(id:)` → terminate + waitUntilExit
- `restart(id:)` → stop + start même commande
- `stopAll()` → termine tous les process
- Streaming via `FileHandle.readabilityHandler` sur stdout/stderr pipes
- Cleanup automatique : `terminationHandler` sur Process pour màj status
- Limite mémoire logs : garder dernières 1000 lignes par process

## Vue principale : ProcessManagerView

### Layout
- Header fixe : titre "Processes" + compteur running + bouton "Stop All"
- Liste scrollable des process groupés par dossier parent (comme ProjectsView)
- Chaque ProcessCard : nom projet + commande + status badge + durée + boutons Stop/Restart
- Clic sur carte → expand logs inline (ou panneau latéral)

### Lancement
- Depuis ProjectsView : bouton launch → démarre process dans ProcessManager au lieu d'ouvrir Terminal
- Ou depuis ProcessManagerView : sélecteur projet + commande

### Logs
- Affichage monospace, scroll auto en bas
- Couleurs : stdout blanc, stderr rouge/orange
- Bouton copier logs
- Bouton clear logs
- Filtre texte dans les logs

### Status badges
- 🟢 Running (vert, animé pulse)
- 🔴 Stopped (rouge)
- 🟡 Errored (orange)
- ⚪ Finished (gris)

## Tasks

- [ ] Modèle `RunningProcess` + `LogLine` + `ProcessStatus`
- [ ] Service `ProcessManager` — start/stop/restart, streaming stdout/stderr
- [ ] `ProcessManagerViewModel` — état processes, actions, groupement
- [ ] `ProcessCard` — carte compacte avec status + durée + boutons
- [ ] `ProcessLogView` — logs temps réel monospace avec scroll auto
- [ ] `ProcessManagerView` — vue principale avec groupement par dossier
- [ ] Brancher dans `MainView` (nouveau module ou sous-section de Projects)
- [ ] Modifier `ProjectsView` : bouton launch → ProcessManager au lieu de Terminal
- [ ] Limite mémoire logs (max 1000 lignes par process)
- [ ] Bouton "Stop All" avec confirmation
- [ ] Cleanup process à la fermeture de l'app

## Critères de validation

- [ ] Process lance et logs s'affichent en temps réel
- [ ] Stop/Restart fonctionnent correctement
- [ ] Stderr affiché en rouge/orange
- [ ] Groupement par dossier cohérent avec ProjectsView
- [ ] Pas de fuite mémoire (logs limités, process cleanup)
- [ ] "Stop All" termine tous les process
- [ ] Build passe

## Notes techniques

- Utiliser `Process()` de Foundation (pas ShellService) pour garder handle sur le process
- `Pipe()` pour stdout et stderr séparés
- `FileHandle.readabilityHandler` pour streaming async
- `@MainActor` pour les updates UI
- `terminationHandler` pour détecter fin/crash
- Attention : `Process.terminate()` envoie SIGTERM, prévoir fallback SIGKILL si timeout
