# DevHub — Lessons Learned

<!-- Format : [date] | erreur | règle -->

[2026-07-01] | xcodegen `entitlements.properties` inline échoue avec "Decoding failed at path" | Toujours créer fichier `.entitlements` séparé et référencer via `path:`
[2026-07-01] | Renommer cas enum Module casse les previews qui référencent anciens cas | Grep `.ancienCas` dans tout DevHub/ après renommage enum
[2026-07-01] | `ActionButton` déjà défini dans QuickActions → conflit nom avec nouveau composant Git | Préfixer composants privés par nom module (ex: `GitActionButton`) pour éviter collisions
[2026-07-01] | Nouveaux fichiers Swift pas compilés après ajout | Toujours `xcodegen generate` après ajout de fichiers quand projet utilise XcodeGen
[2026-07-01] | `@MainActor` static method appelée dans TaskGroup (Sendable closure) → erreur actor isolation | Marquer `nonisolated static` les fonctions pures (parsing, formatting) dans classes @MainActor
[2026-07-01] | SwiftTerm ajouté manuellement dans Xcode mais pas dans project.yml → xcodegen écrase la config SPM à chaque generate → linker error | Toujours déclarer les dépendances SPM dans `project.yml` (section `packages` + `dependencies`), jamais uniquement via Xcode GUI
[2026-07-01] | Redesign massif (18 fichiers) : écrire le thème en premier (couleurs/modifiers), puis layout, puis re-skin modules | Structurer redesign en phases : 1) fondations thème 2) navigation 3) re-skin — chaque phase doit compiler avant la suivante
[2026-07-02] | SwiftTerm `feed(byteArray:)` attend `ArraySlice<UInt8>` pas `Array<UInt8>` | Wrapper avec `ArraySlice(bytes)`. Aussi `selectAll`/`copy` veulent `Any` pas `nil` → passer `self`
[2026-09-17] | `zsh -l -c` depuis app GUI → "command not found: yarn/pod" car PATH (nvm, rbenv, brew) défini dans ~/.zshrc, lu seulement en shell interactif ; LANG absent aussi | Ne jamais utiliser `ProcessInfo.processInfo.environment` brut pour lancer des commandes : passer par `ShellEnvironment.resolved` (PATH résolu via `zsh -l -i`, caché, LANG UTF-8)
[2026-09-17] | `MenuBarExtra` créé mais invisible : barre menus pleine + encoche MacBook → nouvel item placé à gauche, caché derrière l'encoche (AX le voit, pas l'œil) | Enregistrer défaut `NSStatusItem Preferred Position Item-0` (pts depuis bord droit) via `UserDefaults.register` avant création de la scène ; vérifier position réelle par AX/capture, pas seulement existence
