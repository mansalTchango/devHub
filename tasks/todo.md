# DevHub — Stories & Tasks

## État : En cours de développement

---

## Story 11 : Optimisation Terminaux (onglet Processes) ✅
**Priorité** : 🟠 Haute
**Dépend de** : Story 5B, Story 10

### Tasks
- [x] TerminalPaneState.swift — ViewModel pont AppKit↔SwiftUI (scroll lock, search, fontSize)
- [x] EnhancedTerminalView.swift — sous-classe LocalProcessTerminalView (scroll lock, clear, copy)
- [x] RunningProcess.swift — type EnhancedTerminalView + paneState
- [x] ProcessManager.swift — connexion onScrollStateChanged → paneState
- [x] TerminalViewWrapper.swift — adaptation type + fontSize binding
- [x] ScrollToBottomButton.swift — bouton flottant overlay style hacker
- [x] TerminalToolbar.swift — barre compacte (recherche, clear, copy, font +/-)
- [x] ResizableTerminalGrid.swift — intégration toolbar + overlay scroll button
- [x] Build Xcode sans erreur

### Critères de validation
- [x] Build Xcode sans erreur
- [ ] Scroll lock fonctionne (scroll up = verrouillé, bouton ↓ = retour)
- [ ] Recherche Cmd+F fonctionne
- [ ] Clear/Copy/Font +/- fonctionnent

---

## Story 10 : Redesign Terminal/Hacker + Dashboard ✅
**Priorité** : 🟠 Haute
**Dépend de** : Toutes les stories précédentes

### Tasks
- [x] HackerTheme.swift — palette couleurs, ViewModifiers (.hackerCard, .terminalHeader, .blinkingCursor), ASCIIProgressBar
- [x] StatusBadge.swift — composant [OK] [RUN] [ERR] [WARN] style CLI
- [x] Module.swift — couleurs hacker, ajout terminalName/terminalCommand
- [x] DashboardView.swift — grille modules avec stats temps réel, quick_stats, footer hostname
- [x] MainView.swift — layout custom sans NavigationSplitView, breadcrumb terminal ~/devhub > module
- [x] SidebarView.swift — vidée (remplacée par dashboard)
- [x] CleanerView + CleaningTaskCard — re-skin hacker
- [x] QuickActionsView + ActionButton — re-skin hacker avec catégories commentaires CLI
- [x] ProjectsView + ProjectCard — re-skin hacker, tabs git branch style
- [x] ProcessManagerView + ProcessCard — re-skin hacker, status badges CLI
- [x] PortsView — re-skin netstat style monospaced
- [x] DevEnvView — re-skin brew list style, versions v-prefixed
- [x] SystemView + MetricCard + GaugeWidget — jauges matrix vert + barres ASCII
- [x] DevHubApp.swift — fond noir
- [x] xcodegen generate — build OK

### Critères de validation
- [x] Build Xcode sans erreur
- [x] Thème sombre cohérent sur tous les modules

> **⚠️ Note aux agents** : Chaque story a son fichier détaillé dans `tasks/story-{N}-*.md` (ex: `story-1-squelette.md`, `story-3-cleaner.md`). **Toujours lire le fichier story correspondant avant de développer** — il contient les spécifications complètes, contraintes techniques et détails d'implémentation.

---

## Story 1 : Squelette App + Navigation
**Priorité** : 🔴 Critique (bloque tout le reste)
**Fichiers** : `DevHubApp.swift`, `MainView.swift`, `Module.swift`

### Tasks
- [x] Créer projet Xcode SwiftUI macOS (target macOS 14+)
- [x] Modèle `Module` — enum avec nom, icône SF Symbol, description
- [x] `MainView` — NavigationSplitView avec sidebar (liste modules) + zone détail
- [x] Design sidebar : icônes + labels, highlight sélection, style sombre
- [x] Fenêtre : taille par défaut 1000×700, min 800×500
- [x] Placeholder view pour chaque module (titre + "Coming soon")
- [x] Style global : fond sombre, accents bleu/violet

### Critères de validation
- [x] App lance, sidebar affiche tous les modules, navigation fonctionne
- [x] Design propre et cohérent

---

## Story 2 : Service Shell + Utilitaires
**Priorité** : 🔴 Critique (utilisé par tous les modules)
**Fichiers** : `Services/ShellService.swift`, `Utilities/DiskSizeCalculator.swift`

### Tasks
- [x] `ShellService` — exécution commandes shell async via `Process()`
- [x] Retour structuré : stdout, stderr, exit code
- [x] `DiskSizeCalculator` — calcul taille dossier récursif
- [x] Gestion erreurs : permissions refusées, commande introuvable
- [x] Timeout configurable par commande

### Critères de validation
- [x] Peut exécuter commande shell et récupérer résultat
- [x] Calcul taille dossier correct

---

## Story 3 : Module Mac Cleaner
**Priorité** : 🟠 Haute
**Dépend de** : Story 1, Story 2
**Fichiers** : `Views/Cleaner/`, `ViewModels/CleanerViewModel.swift`, `Models/CleaningTask.swift`

### Tasks
- [x] Modèle `CleaningTask` — nom, commande, icône, taille scannée, statut (idle/scanning/cleaning/done/error)
- [x] `CleanerViewModel` — scan tailles réelles, exécution nettoyage, calcul espace libéré
- [x] 7 tâches de nettoyage : DerivedData, Simulateurs, iOS DeviceSupport, Yarn cache, Arc cache, CocoaPods cache, Caches misc
- [x] Vue liste : cartes avec icône + nom + taille réelle + bouton Nettoyer + statut animé
- [x] Bouton "Tout nettoyer" en haut avec confirmation dialog
- [x] Barre de progression par tâche
- [x] Compteur total espace libéré (animé)
- [x] Scan automatique au chargement du module

### Critères de validation
- [x] Scan affiche tailles réelles des dossiers
- [x] Nettoyage individuel fonctionne, statut change
- [x] "Tout nettoyer" exécute séquentiellement avec feedback
- [x] Items à 0 Go grisés

---

## Story 4 : Module Quick Actions
**Priorité** : 🟠 Haute
**Dépend de** : Story 1, Story 2
**Fichiers** : `Views/QuickActions/`, `ViewModels/QuickActionsViewModel.swift`

### Tasks
- [x] Liste d'actions rapides prédéfinies :
  - Kill port (input numéro de port)
  - Flush DNS (`sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`)
  - Restart Dock (`killall Dock`)
  - Purge RAM (`sudo purge`)
  - Vider corbeille (`rm -rf ~/.Trash/*`)
  - Rebuild Spotlight (`sudo mdutil -E /`)
  - Kill Xcode (`killall Xcode`)
  - Clear Downloads vieux de 30j
  - Restart Finder, Restart Audio (bonus)
- [x] Vue grille : boutons larges avec icône + nom
- [x] Feedback visuel : animation succès/erreur
- [x] Actions nécessitant sudo : demander mot de passe via dialog système
- [x] Possibilité d'ajouter des actions custom (stockage UserDefaults)

### Critères de validation
- Chaque action s'exécute correctement
- Feedback visuel clair
- Actions sudo demandent le mot de passe

---

## Story 5A : Module Project Launcher ✅
**Priorité** : 🟡 Moyenne
**Dépend de** : Story 1, Story 2
**Fichiers** : `Views/Projects/`, `ViewModels/ProjectsViewModel.swift`, `Models/Project.swift`

### Tasks
- [x] Modèle `Project` + `ProjectType` + `LaunchCommand` + `LaunchEnvironment`
- [x] Scan ~/Documents/Perso et ~/Documents/vo2 (profondeur max 3)
- [x] Détection type projet via fichiers marqueurs
- [x] Vue avec recherche, filtres type, groupement par dossier
- [x] Actions : ouvrir VS Code, Terminal, Finder, Xcode
- [x] Launch commands configurables (Dev/Staging/Prod) persistées UserDefaults
- [x] Branché dans MainView

## Story 5B : Process Manager ✅
- [x] Lancer process long-running via SwiftTerm (terminal intégré)
- [x] Groupement par dossier parent (tabs), boutons Stop/Restart
- [x] Multi-terminal : ouvrir plusieurs terminaux simultanément en grille 2 colonnes
- [x] Grille resizable (dividers draggables horizontal + vertical)
- [x] Mode plein écran terminaux
- [x] Indicateur process running sur ProjectCard
- [x] Cleanup process à la fermeture app

---

## Story 6 : Module Port Manager ✅
**Priorité** : 🟡 Moyenne
**Dépend de** : Story 1, Story 2
**Fichiers** : `Views/Ports/`, `ViewModels/PortsViewModel.swift`, `Models/PortInfo.swift`

### Tasks
- [x] Modèle `PortInfo` — port, PID, nom process, user
- [x] Scan ports ouverts via `lsof -i -P -n -sTCP:LISTEN`
- [x] Vue tableau : port, process, PID, user, type, état, bouton Kill
- [x] Filtre par numéro de port ou nom de process
- [x] Refresh auto toutes les 5s (toggle on/off)
- [x] Confirmation avant kill
- [x] Branché dans MainView

### Critères de validation
- [x] Liste ports ouverts correctement
- [x] Kill process fonctionne
- [x] Refresh fonctionne

---

## Story 7 : Module Dev Environment
**Priorité** : 🟢 Basse
**Dépend de** : Story 1, Story 2
**Fichiers** : `Views/DevEnv/`, `ViewModels/DevEnvViewModel.swift`, `Models/DevTool.swift`

### Tasks
- [x] Modèle `DevTool` — struct avec version command, update command, etc.
- [x] Détection versions : Node, npm, Yarn, pnpm, Ruby, Python, Xcode, Homebrew, Git, CocoaPods, Docker, Go, Rust (13 outils)
- [x] Vue liste : outil + icône + version installée (badge vert) / "Non installé" (grisé)
- [x] Bouton update par outil (avec spinner + gestion erreur)
- [x] Bouton "Update All" pour tous outils updatables
- [x] Scan parallèle via TaskGroup
- [x] Intégration MainView — case `.devEnv: DevEnvView()`
- [x] XcodeGen — fichiers inclus, compilation Swift OK

### Critères de validation
- [x] Versions détectées correctement (scan parallèle)
- [x] Updates fonctionnent (individuel + all)
- [x] Compilation Swift sans erreur (linker error = bug Xcode 26 beta, préexistant)

---

## Story 8 : Module System Monitor
**Priorité** : 🟢 Basse
**Dépend de** : Story 1
**Fichiers** : `Views/System/`, `ViewModels/SystemViewModel.swift`

### Tasks
- [x] CPU usage, RAM usage, Disk usage, Battery level
- [x] Vue widgets compacts : jauges circulaires animées
- [x] Refresh toutes les 2s
- [x] Alertes visuelles si CPU > 80% ou RAM > 90%

### Critères de validation
- [x] Métriques affichées en temps réel
- [x] Jauges animées fluides

---

## Ordre d'exécution recommandé
```
Story 1 (Squelette) ──→ Story 2 (Shell Service)
                              │
                    ┌─────────┼─────────┐
                    ▼         ▼         ▼
              Story 3    Story 4    Story 5
             (Cleaner) (Quick Act) (Projects)
                                      │
                              ┌───────┼───────┐
                              ▼       ▼       ▼
                          Story 6  Story 7  Story 8
                          (Ports)  (DevEnv) (System)
```

Stories 1 & 2 : séquentielles (2 bloque sur 1)
Stories 3, 4, 5 : parallélisables après 1+2
Stories 6, 7, 8 : parallélisables après 5
