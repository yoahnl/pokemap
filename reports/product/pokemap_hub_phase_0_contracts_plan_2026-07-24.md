# PokeMap Hub Phase 0 Contracts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer les six lots `HUB-000` à `HUB-005` en un Decision Pack approuvé qui verrouille l’architecture, le format, la sécurité, la compatibilité, les sauvegardes, les parcours joueur et l’isolation de session avant tout code produit.

**Architecture:** `apps/pokemap_hub` sera la racine de composition d’un produit distinct du host développeur. Les contrats persistés et partagés resteront purs, `map_runtime` ne dépendra jamais de `map_player_ui`, et les décisions de format, sécurité, compatibilité et session seront validées ensemble avant la Phase 1.

**Tech Stack:** Markdown normatif, JSON Schema, fixtures JSON, Dart pur pour les futurs contrats et tests, Flutter pour les futurs Hub/player UI, ZIP déterministe, SHA-256, SemVer, Flame conservé dans `map_runtime`.

---

## 1. Statut et règle de gel

Statut au 2026-07-24 :

- Phase 0 : `TODO — proposition détaillée, non approuvée` ;
- `HUB-000` à `HUB-005` : `TODO` ;
- Phase 1 et suivantes : `BLOCKED par la gate de décision Phase 0` ;
- code Dart/Flutter, scaffolds `map_distribution`, `map_player_ui` et `pokemap_hub` : **non autorisés dans cette passe** ;
- aucune implémentation visuelle isolée du Hub ne doit commencer ;
- le présent fichier est un plan, pas une acceptation des décisions qu’il organise.

La sortie de Phase 0 exige une validation humaine explicite des cinq gates A à E et de la gate de cohérence finale. L’absence de réponse ou une simple absence d’objection ne vaut pas approbation.

## 2. Sources de vérité lues

Les sources suivantes ont été lues intégralement avant rédaction :

- `AGENTS.md` ;
- `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `reports/product/pokemap_hub_player_application_audit_2026-07-24.md` ;
- `skills/README.md` ;
- `skills/writing-plans/SKILL.md` ;
- `skills/brainstorming/SKILL.md` ;
- `skills/dispatching-parallel-agents/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md`.

Le rapport d’audit Hub reste la source de vérité produit et technique. Le présent plan précise son exécution sans le remplacer.

## 3. Verdict exécutif

Verdict : **GO pour une Phase 0 exclusivement documentaire ; NO-GO pour le code des phases 1 à 8.**

Les six IDs de l’audit restent canoniques afin de préserver la roadmap à 47 lots. Ils sont complétés par des paquets de décisions internes et des gates utilisateur, sans ajouter un septième lot.

Ordre causal retenu :

```text
HUB-000 draft
    │
    ├──> HUB-002 contraintes de sécurité ──┐
    │                                      ├──> HUB-001 final
    └──> HUB-001 squelette de format ──────┘
                                               │
                                               v
                                            HUB-003
                                               │
                                               v
                                            HUB-005
                                               │
                         ratification HUB-000 ─┘
                                               │
                                               v
                                            HUB-004
                                               │
                                               v
                                  gate de cohérence Phase 0
                                               │
                                               v
                                  seulement ensuite HUB-010
```

`HUB-004` peut être esquissé en parallèle, mais il ne peut pas être approuvé avant `HUB-003` et `HUB-005`.

## 4. Trois stratégies de décomposition examinées

| Stratégie | Avantages | Faiblesses | Verdict |
|---|---|---|---|
| Six lots exécutés strictement `000 → 005` | Traçabilité directe avec l’audit | Ordre causal incorrect : la sécurité doit contraindre le format et l’isolation doit contraindre les parcours | Rejetée |
| Trois macro-lots fusionnés | Moins de documents | Sécurité, saves et isolation deviennent trop larges ; validation tardive et ambiguë | Rejetée |
| Dix à douze micro-lots | Décisions très atomiques | Dérive des 47 lots, duplication et fausse indépendance | Rejetée comme backlog canonique |
| Six lots canoniques avec gates internes | Préserve les IDs, rend les décisions vérifiables et révisables | Exige une revue de cohérence finale | **Retenue** |

## 5. Audit initial du dépôt

### 5.1 État Git initial

```text
HEAD: a3bc35104b558e2d8c27e1c81ac7c2a3fe1a43cc
Changements suivis: 0
Fichiers non suivis préexistants: 73
```

Inventaire groupé exact des 73 fichiers non suivis à préserver :

| Zone | Nombre | Contenu |
|---|---:|---|
| `.superpowers/brainstorm/14071-1784849311/**` | 4 | Trois documents HTML et `state/server-info` |
| `examples/playable_runtime_host/test/selbrume_dynamic_shop_e2e_test.dart` | 1 | Test utilisateur préexistant |
| `reports/gameplay/evidence/fg_079_dynamic_shop_e2e/*` | 7 | Captures FG-079 |
| `reports/gameplay/evidence/selbrume_mvp_walkthrough_2026-07-23/*` | 53 | Captures du walkthrough |
| `reports/gameplay/selbrume_mvp_walkthrough_protocol.md` | 1 | Protocole gameplay |
| `reports/narrativeStudio/performance/*` | 2 | Analyse et plan performance |
| `reports/product/evidence/hub_runtime_audit_2026-07-24/*` | 4 | Captures de l’audit Hub |
| `reports/product/pokemap_hub_player_application_audit_2026-07-24.md` | 1 | Audit Hub source de vérité |

Aucun de ces fichiers ne doit être modifié, déplacé ou supprimé par la Phase 0.

### 5.2 Contrats existants utiles

| Fondation | Fichier actuel | Conclusion |
|---|---|---|
| Projet auteur/runtime | `packages/map_core/lib/src/models/project_manifest.dart` | `ProjectManifest` n’a ni `gameId`, ni `gameVersion`, ni éditeur de distribution ; `ProjectSettings.mistralApiKey` est sérialisé. |
| Version projet | `packages/map_core/lib/src/models/enums.dart` | `ProjectVersion` ne couvre que `v1/v2`. |
| Migrations | `packages/map_core/lib/src/operations/project_json_migrations.dart` | Base existante, mais axes de compatibilité Hub absents. |
| Validation projet | `packages/map_core/lib/src/validation/validators.dart` | `ProjectValidator` est réutilisable pour le préflight. |
| Canonicalisation | `packages/map_core/lib/src/operations/narrative_event_canonical_json.dart` | JCS/RFC 8785 et SHA-256 existent et doivent être évalués avant de créer une seconde canonicalisation. |
| État sauvegardé | `packages/map_core/lib/src/models/save_data.dart` | État métier sans enveloppe multijeu. |
| Persistance métier | `packages/map_core/lib/src/operations/game_state_persistence.dart` | Conversion `GameState`/`SaveData` réutilisable. |
| Port de save | `packages/map_runtime/lib/domain/repositories/game_save_repository.dart` | Injectable, mais global et sans scope jeu/profil/slot. |
| Save fichier | `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart` | Chemin global `pokemonProject/game_save.json`, écriture directe sans backup/checksum. |
| Transaction runtime | `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Bonne couture d’injection et rollback d’activation, à ne pas confondre avec une écriture disque atomique. |
| Préflight runtime | `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart` | Bonne base, mais plusieurs chemins sont seulement joints/normalisés. |
| Digest | `examples/playable_runtime_host/lib/src/project_tree_digest.dart` | Primitive déterministe utile, pas encore inventaire normatif de package. |
| Import host | `examples/playable_runtime_host/lib/src/runtime_projects_directory.dart` | Supprime la cible avant copie ; comportement interdit pour le Hub. |
| Save de lancement host | `examples/playable_runtime_host/lib/src/runtime_launch_save.dart` | Contrat de harness à exclure de tout export joueur. |
| Menu host | `examples/playable_runtime_host/lib/src/in_game_menu.dart` | UI provisoire ; services PC/Boutique/Centre actuellement trop globaux. |
| Combat | `packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart` | Snapshot prometteur ; le moteur `map_battle` ne doit pas être réécrit. |

Les répertoires suivants n’existent pas encore :

- `packages/map_distribution` ;
- `packages/map_player_ui` ;
- `apps/pokemap_hub`.

Aucun `GameLibrary`, `GamePackageManifest`, `SaveEnvelope`, `GameSessionController`, `GameCompleted`, écran titre ou machine d’états Hub n’a été trouvé.

### 5.3 Correction de deux ambiguïtés de l’audit

1. La liste de champs `SaveEnvelope` du rapport omet `profileId`, alors que l’arborescence cible et la demande directe l’exigent. `profileId` est donc obligatoire.
2. `HUB-041 PackageAssetResolver` arrive trop tard pour sécuriser le smoke de `HUB-031`. La politique de confinement doit être spécifiée dans `HUB-001/002`, implémentée dans la primitive de validation au plus tard en `HUB-014/HUB-031`, puis adaptée au runtime en `HUB-041`.

### 5.4 Lots mécaniques liés

La roadmap mécanique n’est pas modifiée par ce plan.

| Lot FG | Statut actuel | Relation avec le Hub |
|---|---|---|
| `FG-011` New Game Runtime Flow | `TODO` | Le parcours titre/New Game de `HUB-004` devra lui fournir un shell produit. |
| `FG-014` Save/Load Transaction Hardening | `DONE` | Prouve le rollback runtime existant, pas l’isolation multijeu ni la durabilité disque atomique. |
| `FG-015` Runtime Pause Menu Shell | `TODO` | Le menu joueur futur doit respecter les contrats `HUB-004`. |
| `FG-160` Pause Menu Complete | `TODO` | Recouvre le menu joueur, sans prouver le Hub. |
| `FG-162` Runtime Options | `TODO` | Les préférences globales/jeu restent à séparer. |
| `FG-163` Runtime Save Menu | `TODO` | Dépendra de `HUB-003`. |
| `FG-165` Runtime Input Lock Conventions | `TODO` | Dépendra du routeur et des états `HUB-004/005`. |
| `FG-180` Readiness Report | `DONE` | Preuve fangame, pas preuve Hub générique. |
| `FG-182` Golden Slice E2E | `DONE` | Preuve Selbrume/harness, pas preuve multijeu. |
| `FG-185` MVP Release Gate | `PARTIAL / NO-GO` | Le dépôt ne doit pas être déclaré globalement prêt. |

Le contrat `GameCompleted`/« Terminer le jeu » ne possède pas de lot FG dédié explicite dans la roadmap actuelle. Il reste un gap : contrat produit dans `HUB-004`, implémentation runtime/no-code à affecter aux phases 4 et 7 lors d’une future mise à jour explicitement demandée de la roadmap.

## 6. Arborescence documentaire cible de Phase 0

Cette arborescence est créée uniquement pendant l’exécution approuvée des lots, pas pendant la présente planification :

```text
reports/product/pokemap_hub/phase_0/
├── README.md
├── decision-register.md
├── glossary.md
├── phase-0-exit-gate.md
├── adr/
│   ├── 0001-hub-player-host-boundaries.md
│   └── 0002-session-isolation-by-platform.md
├── contracts/
│   ├── ownership-and-dependencies.md
│   ├── pokemapgame-v1.md
│   ├── game-manifest-v1.schema.json
│   ├── canonicalization-vectors.json
│   ├── game-session-port.md
│   ├── session-failure-and-exit-matrix.md
│   └── examples/
├── security/
│   ├── pokemapgame-v1-threat-model.md
│   ├── package-trust-and-quota-policy.md
│   └── hostile-package-corpus.md
├── compatibility/
│   ├── version-and-capability-policy.md
│   └── compatibility-matrix.json
├── saves/
│   ├── save-envelope-v1.schema.json
│   ├── save-lifecycle-and-migration-policy.md
│   └── examples/
│       ├── minimal-valid-save-envelope.json
│       └── invalid/
└── product/
    ├── information-architecture.md
    ├── player-state-machine.md
    ├── action-availability-matrix.md
    ├── acceptance-journeys.md
    └── game-completion-contract.md
```

Chaque ADR doit utiliser les statuts `Proposed`, `Accepted`, `Superseded` ou `Rejected`, nommer le décideur et dater l’approbation.

## 7. Registre des décisions à obtenir

| ID | Décision structurante | Lot propriétaire | Gate |
|---|---|---|---|
| `P0-D01` | Hub séparé, host conservé comme harness | `HUB-000` | A |
| `P0-D02` | Responsabilité et sens exact des dépendances de chaque package | `HUB-000` | A |
| `P0-D03` | Propriétaire de `GameIdentity`, `SaveEnvelope`, ports de save/session et snapshots | `HUB-000` | A |
| `P0-D04` | Syntaxe, normalisation et immutabilité de `gameId` | `HUB-001` | B |
| `P0-D05` | ZIP déterministe et canonicalisation exacte | `HUB-001` | B |
| `P0-D06` | Inventaire, tree hash, signature et projection runtime | `HUB-001/002` | B |
| `P0-D07` | Quotas numériques et politique data-only hostile | `HUB-002` | B |
| `P0-D08` | Sideload non signé et future signature catalogue | `HUB-002` | B |
| `P0-D09` | Matrice package/jeu/projet/runtime/Hub/capabilities/save | `HUB-003` | C |
| `P0-D10` | Profils, slots, Continue/New Game, completed save, désinstallation et isolation des données mutables | `HUB-003` | C |
| `P0-D11` | Politique de migration de l’ancienne save globale | `HUB-003` | C |
| `P0-D12` | Même processus ou player enfant par plateforme | `HUB-005` | D |
| `P0-D13` | Processus enfant séparé ou mode `--player-session` du Hub | `HUB-005` | D |
| `P0-D14` | États Hub/titre/pause/fin et comportements d’erreur | `HUB-004` | E |
| `P0-D15` | Contrat `GameCompleted`, crédits et retour | `HUB-004` | E |

Recommandation d’ownership à faire valider dans `P0-D03` :

- `GameIdentity`, `SaveEnvelope` et DTO persistés runtime-neutres : `map_core` ;
- manifeste, SemVer, package, validation hostile et reçus : `map_distribution` ;
- port de session, orchestration runtime et snapshots de présentation : `map_runtime` ;
- stockage racine, bibliothèque et adaptation plateforme : `apps/pokemap_hub` ;
- widgets et focus joueur : `map_player_ui` ;
- aucune dépendance `map_runtime → map_player_ui` ou `map_runtime → map_distribution` ;
- `map_player_ui` peut consommer seulement les contrats publics de présentation de `map_runtime`.

Cette recommandation reste `Proposed` jusqu’à la Gate A.

---

## 8. HUB-000 — ADR Hub/player/host et frontières de packages

### Objectif

Figer les responsabilités, dépendances autorisées/interdites, propriétaires des contrats partagés et la distinction entre architecture logique et topologie de processus.

### Périmètre inclus

- `apps/pokemap_hub` comme racine de composition ;
- `packages/map_distribution` pur Dart ;
- `packages/map_player_ui` Flutter, indépendant de `map_editor` ;
- `map_runtime` comme moteur de session ;
- `map_battle` conservé comme moteur pur ;
- `map_editor` consommateur futur du contrat d’export ;
- `playable_runtime_host` maintenu comme harness développeur ;
- ownership de `GameIdentity`, `SaveEnvelope`, `GameLibrary`, install receipts, ports de session/save et snapshots ;
- matrice des imports autorisés et interdits ;
- glossaire normatif.

### Hors périmètre

- création des packages/app ;
- choix final du processus enfant, réservé à `HUB-005` ;
- implémentation de l’installateur, des saves ou des écrans ;
- déplacement de code hors du host ;
- modification de `map_battle`.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/README.md`
- `reports/product/pokemap_hub/phase_0/decision-register.md`
- `reports/product/pokemap_hub/phase_0/glossary.md`
- `reports/product/pokemap_hub/phase_0/adr/0001-hub-player-host-boundaries.md`
- `reports/product/pokemap_hub/phase_0/contracts/ownership-and-dependencies.md`

### Fichiers actuels à citer, sans les modifier

- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_editor/lib/map_editor.dart`
- `packages/map_battle/lib/map_battle.dart`
- `examples/playable_runtime_host/lib/main.dart`
- les `pubspec.yaml` de chaque package existant.

### Tâches

- [ ] Écrire le glossaire : jeu, package, projet, version installée, profil, slot, save, session, runtime, Hub et host.
- [ ] Dresser la matrice package × responsabilité avec un propriétaire unique par contrat.
- [ ] Dessiner le graphe des dépendances autorisées et interdites.
- [ ] Décider l’ownership `P0-D03`.
- [ ] Documenter que `examples/` ne peut être une dépendance de production.
- [ ] Documenter que la topologie de processus reste ouverte jusqu’à `HUB-005`.
- [ ] Faire approuver Gate A.
- [ ] Après `HUB-005`, ratifier ou amender l’ADR sans laisser deux architectures concurrentes.

### Tests et revues de Phase 0

- matrice complète : chaque responsabilité a exactement un owner ;
- détection manuelle de cycle sur le graphe ;
- scénario de composition ne nécessitant aucun import depuis `examples/playable_runtime_host` ;
- revue des contrats Flutter/`dart:ui` qui ne seraient pas sérialisables en IPC ;
- revue architecture indépendante et approbation utilisateur.

### Obligations de preuve downstream

À créer lors des lots de scaffolding/implémentation, pas pendant Phase 0 :

- `packages/map_distribution/test/architecture/pure_dart_boundary_test.dart`
- `packages/map_runtime/test/architecture/player_ui_dependency_guard_test.dart`
- `packages/map_player_ui/test/architecture/editor_dependency_guard_test.dart`
- `apps/pokemap_hub/test/architecture/dependency_direction_test.dart`

### Critères de DONE

- ADR `0001` au statut `Accepted` ;
- Gate A approuvée explicitement ;
- Hub racine de composition et host harness écrits comme invariants ;
- `map_runtime ─X→ map_player_ui` ;
- `map_distribution` sans Flutter/Flame ;
- aucune dépendance de production vers `examples/` ;
- propriétaires des contrats P0 décidés ;
- aucun nom, fixture ou chemin Selbrume dans les contrats normatifs ;
- ratification post-`HUB-005` effectuée.

### Risques

- créer prématurément un package de DTO supplémentaire ;
- placer `SaveEnvelope` dans un package inaccessible au Hub ;
- faire dépendre le runtime du format ZIP ;
- confondre frontière logique et choix de processus ;
- laisser des responsabilités produit dans le host.

### Dépendances

Aucune pour le draft. Ratification finale après `HUB-005`. Bloque tous les autres lots.

---

## 9. HUB-002 — Threat model et politique de confiance

### Objectif

Transformer les risques de l’audit en une politique hostile testable qui contraint le format avant son gel.

### Périmètre inclus

- acteurs, frontières de confiance et surfaces d’attaque ;
- package malveillant, corrompu ou créé par un éditeur compromis ;
- chemins absolus, `..`, UNC, drive Windows, NUL et séparateurs ambigus ;
- symlinks, hardlinks, fichiers spéciaux, entrées chiffrées ;
- doublons ZIP et collisions casse/NFC/NFD ;
- fichiers manquants, supplémentaires, non inventoriés ou hash faux ;
- profondeur, nombre, taille, ratio de compression et décodage d’images ;
- allowlist data-only et refus d’exécutables ;
- références sortant de la racine ;
- secrets probables, notamment `mistralApiKey` ;
- packages non signés, signatures invalides et futur catalogue ;
- redaction des diagnostics et risques résiduels ;
- quotas numériques V1.

### Hors périmètre

- DRM, anti-cheat, mods exécutables et sandbox de plugins ;
- réseau/catalogue public réel ;
- implémentation du scanner ou de l’extracteur ;
- garantie contre toutes les vulnérabilités des décodeurs natifs.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/security/pokemapgame-v1-threat-model.md`
- `reports/product/pokemap_hub/phase_0/security/package-trust-and-quota-policy.md`
- `reports/product/pokemap_hub/phase_0/security/hostile-package-corpus.md`

### Fichiers actuels à citer, sans les modifier

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- les résolveurs runtime d’assets inventoriés par l’audit ;
- `examples/playable_runtime_host/lib/src/project_tree_digest.dart`
- `examples/playable_runtime_host/lib/src/runtime_projects_directory.dart`.

### Tâches

- [ ] Définir acteurs, assets, trust boundaries et scénarios d’abus.
- [ ] Relier chaque menace à prévention, détection, message joueur, récupération et lot d’implémentation.
- [ ] Fixer des quotas chiffrés et justifiés, sans `TBD`.
- [ ] Définir l’ordre inspection → validation → extraction, avec validation avant écriture hors staging.
- [ ] Définir une allowlist data-only et une denylist de défense en profondeur.
- [ ] Définir le comportement exact de secret detection : rejet dur et diagnostic redacted.
- [ ] Valider : sideload local non signé avec avertissement ; catalogue public signé.
- [ ] Écrire l’index du corpus hostile neutre.
- [ ] Injecter les contraintes normatives dans `HUB-001`.
- [ ] Faire approuver la partie sécurité de Gate B.

### Tests et revues de Phase 0

- chaque menace P0 possède au moins un contrôle et un cas hostile ;
- revue macOS/Linux/Windows des chemins et collisions ;
- revue adversariale indépendante ;
- cas exacts de limite acceptés, limite+1 refusés ;
- SHA-256 n’est jamais présenté comme une preuve d’identité éditeur ;
- signature et validation hostile restent deux contrôles distincts.

### Obligations de preuve downstream

Sous `packages/map_distribution/test/security/` :

- `package_archive_path_policy_test.dart`
- `package_archive_structure_policy_test.dart`
- `package_quota_policy_test.dart`
- `package_payload_policy_test.dart`
- `package_secret_scan_test.dart`
- `package_reference_confinement_test.dart`
- `test/support/hostile_zip_fixture_builder.dart`

Commande future :

```bash
cd packages/map_distribution
dart test test/security
dart analyze
```

### Critères de DONE

- threat model et trust policy approuvés ;
- quotas numériques présents ;
- traversal, liens, doublons, collisions, bombs, exécutables, secrets et références externes couverts ;
- état unsigned/valid/invalid et UX associés définis ;
- `mistralApiKey` est un rejet dur ;
- non-objectifs et risques résiduels acceptés ;
- aucune menace P0 sans propriétaire downstream ;
- contraintes reprises dans la spécification `HUB-001`.

### Risques

- faux sentiment de sandbox ;
- quotas arbitraires sans justification ;
- faux positifs du secret scanning ;
- divergence de normalisation entre plateformes ;
- autoriser une extraction avant inspection complète.

### Dépendances

`HUB-000` draft. Travaille en boucle avec `HUB-001`.

---

## 10. HUB-001 — Spécification `.pokemapgame` V1

### Objectif

Produire un format installable normatif, déterministe, strictement data-only et indépendant du workspace auteur.

### Périmètre inclus

- extension `.pokemapgame` et type de fichier ;
- arborescence racine ;
- ZIP déterministe : ordre, timestamps, permissions, extra fields, commentaires, encodage et compression ;
- syntaxe, normalisation et immutabilité de `gameId` ;
- `packageFormat`, `gameVersion`, publisher, compatibilité, capacités, projet, save, locales et branding ;
- métadonnées localisées et description ;
- inventaire fermé, tailles et SHA-256 par fichier ;
- canonicalisation et préimage exacte du tree hash ;
- exclusion du manifeste de son propre inventaire ;
- couverture exacte de la signature ;
- projection runtime nettoyée ;
- exclusions des saves, caches, logs, debug, locks, secrets et fichiers éditeur ;
- conflit même `gameId + gameVersion` avec tree hash différent ;
- politique de confinement que l’inspector puis le runtime devront partager.

### Hors périmètre

- builder/extracteur Dart ;
- installateur et promotion atomique ;
- signature et catalogue réels ;
- export UI de l’éditeur ;
- widgets ou scripts fournis par un jeu.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/contracts/pokemapgame-v1.md`
- `reports/product/pokemap_hub/phase_0/contracts/game-manifest-v1.schema.json`
- `reports/product/pokemap_hub/phase_0/contracts/canonicalization-vectors.json`
- `reports/product/pokemap_hub/phase_0/contracts/examples/minimal-valid/game-manifest.json`
- `reports/product/pokemap_hub/phase_0/contracts/examples/complete-valid/game-manifest.json`
- fixtures négatives neutres sous `reports/product/pokemap_hub/phase_0/contracts/examples/invalid/`.

### Fichiers actuels à citer, sans les modifier

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/operations/narrative_event_canonical_json.dart`
- `packages/map_core/test/fixtures/narrative_event_jcs/`
- `examples/playable_runtime_host/lib/src/project_tree_digest.dart`
- `examples/playable_runtime_host/tool/package_selbrume_macos.dart`.

### Tâches

- [ ] Écrire un squelette de format pour permettre au threat model de référencer ses surfaces.
- [ ] Fixer `gameId` sans dérivation depuis titre/dossier.
- [ ] Spécifier tous les champs, types, contraintes et politiques de champs inconnus.
- [ ] Spécifier le ZIP byte-for-byte, pas seulement le contenu logique.
- [ ] Spécifier la canonicalisation JSON et des chemins.
- [ ] Spécifier l’inventaire canonique, le tree hash et la signature sans auto-référence.
- [ ] Spécifier la projection runtime et les exclusions obligatoires.
- [ ] Spécifier le conflit même version/hash différent.
- [ ] Ajouter exemple minimal, exemple complet et exemples invalides génériques.
- [ ] Faire la revue croisée format/sécurité/compatibilité.
- [ ] Faire approuver Gate B commune avec `HUB-002`.

### Tests et revues de Phase 0

- les JSON et JSON Schema sont syntaxiquement valides ;
- exemple minimal et complet satisfont le schéma ;
- fixtures invalides violent chacune une règle nommée ;
- vecteurs connus de canonicalisation avec entrées et résultats attendus ;
- même entrée logique produit mêmes octets et mêmes hashes ;
- changement de titre/dossier ne change jamais `gameId` ;
- deux jeux neutres peuvent partager un titre mais pas une identité ;
- le manifeste n’est pas inclus dans `content.files`.

### Obligations de preuve downstream

Sous `packages/map_distribution/test/` :

- `game_package_manifest_codec_test.dart`
- `package_manifest_schema_test.dart`
- `package_canonicalization_test.dart`
- `package_builder_determinism_test.dart`
- fixtures sous `test/fixtures/manifests/v1/`.

Commande future :

```bash
cd packages/map_distribution
dart test test/game_package_manifest_codec_test.dart \
  test/package_manifest_schema_test.dart \
  test/package_canonicalization_test.dart \
  test/package_builder_determinism_test.dart
dart analyze
```

### Critères de DONE

- spécification normative avec `MUST`, `SHOULD`, `MAY` ;
- schéma et exemples cohérents ;
- extension, structure, identity, versions, branding, locales et capacités définis ;
- ZIP et canonicalisation sans comportement implicite ;
- inventaire, hashes, tree hash et signature précisément définis ;
- contenu exécutable impossible par contrat ;
- workspace auteur et fichiers host/debug exclus ;
- primitive de confinement assignée à `HUB-014/HUB-031`, adaptateur runtime à `HUB-041` ;
- Gate B approuvée.

### Risques

- hash auto-référentiel ;
- ZIP déclaré déterministe sans métadonnées fixées ;
- `gameId` mutable ou utilisable directement comme chemin ;
- copie brute du workspace ;
- format trop couplé au `ProjectManifest` courant ;
- divergence entre canonicalisation de build et inspection.

### Dépendances

`HUB-000` draft et contraintes de `HUB-002`. Revue de compatibilité avec `HUB-003` avant acceptation finale.

---

## 11. HUB-003 — Compatibilité, identité et comportement des saves

### Objectif

Séparer chaque dimension de version et définir sans ambiguïté l’isolation, la sélection, l’écriture, la migration, l’update, le downgrade, le rollback et la conservation des sauvegardes.

### Périmètre inclus

- axes distincts : package, jeu, projet, Hub, runtime API, capabilities et save ;
- matrice install/run/update/downgrade/migrate/refuse ;
- `GameIdentity` stable ;
- sémantique de `compatibilityId` ;
- `SaveEnvelope` avec `schemaVersion`, `gameId`, `profileId`, `slotId`, `saveId`, dates, versions, compatibilité, checksum et état métier ;
- namespace `gameId/profileId/slotId` ;
- préférences globales du Hub séparées des préférences de jeu/profil ;
- caches mutables scoppés au minimum par `gameId/gameVersion`, sans écriture dans une version installée immuable ;
- canonicalisation/checksum de l’enveloppe ;
- temp → flush → relecture → validation → backup → rename → restauration ;
- migrations sur copie avec receipt ;
- comportement New Game, Continue et Load ;
- saves complétées ;
- désinstallation conservant les saves par défaut ;
- suppression de données séparée et explicite ;
- politique pour l’ancien `pokemonProject/game_save.json` ;
- conflit d’une version installée au même numéro mais au tree hash différent.

### Hors périmètre

- repository multijeu Dart ;
- écriture disque réelle ;
- UI de gestion des profils/slots ;
- migration d’une save utilisateur ;
- modification du `GameState` métier.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/compatibility/version-and-capability-policy.md`
- `reports/product/pokemap_hub/phase_0/compatibility/compatibility-matrix.json`
- `reports/product/pokemap_hub/phase_0/saves/save-envelope-v1.schema.json`
- `reports/product/pokemap_hub/phase_0/saves/save-lifecycle-and-migration-policy.md`
- `reports/product/pokemap_hub/phase_0/saves/examples/minimal-valid-save-envelope.json`
- fixtures négatives sous `reports/product/pokemap_hub/phase_0/saves/examples/invalid/`.

### Fichiers actuels à citer, sans les modifier

- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_runtime/lib/domain/repositories/game_save_repository.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart`.

### Tâches

- [ ] Définir le sens et l’algorithme de comparaison de chaque axe de version.
- [ ] Définir `unknown required capability = rejet`.
- [ ] Remplir chaque cellule de la matrice avec décision, message joueur et récupération.
- [ ] Spécifier `GameIdentity`.
- [ ] Spécifier `SaveEnvelope` avec le minimum obligatoire exact : `schemaVersion`, `gameId`, `profileId`, `slotId`, `saveId`, date de création, date de mise à jour, version du jeu à la création, version du jeu à la dernière ouverture, format projet, format save, `compatibilityId`, checksum et état métier.
- [ ] Définir les invariants de chemin sans utiliser directement une valeur non validée.
- [ ] Séparer préférences Hub, préférences jeu/profil et caches ; scopper les caches par `gameId/gameVersion`.
- [ ] Définir atomicité, backup, quarantaine et receipts.
- [ ] Définir Continue/New Game/Load avec plusieurs profils et slots.
- [ ] Définir update, downgrade, migration et rollback séparément.
- [ ] Définir l’état « completed » et sa chargeabilité.
- [ ] Décider qu’aucune save globale historique n’est attribuée automatiquement à un jeu.
- [ ] Faire approuver Gate C.

### Recommandation legacy

L’ancien `game_save.json` reste une donnée du host. Un import futur, s’il est retenu, doit être explicite depuis le détail d’un jeu choisi, copier avant toute transformation et enregistrer sa provenance. Il ne doit jamais être déplacé ni auto-associé.

### Tests et revues de Phase 0

- matrice table-driven ancien/égal/futur pour tous les axes ;
- deux jeux avec mêmes `profileId/slotId` sans collision ;
- package/runtime/save futur refusé clairement ;
- capability inconnue obligatoire refusée ;
- update compatible et incompatible ;
- downgrade autorisé et interdit ;
- primary corrompu avec backup valide ;
- migration échouée sans perte ;
- Continue choisit uniquement une save compatible du bon jeu/profil ;
- New Game ne remplace jamais silencieusement un slot ;
- uninstall conserve les saves par défaut.

### Obligations de preuve downstream

Sous `packages/map_distribution/test/compatibility/` :

- `package_compatibility_policy_test.dart`
- `runtime_capability_policy_test.dart`
- `save_compatibility_policy_test.dart`
- `packages/map_distribution/test/fixtures/compatibility/compatibility_matrix_v1.json`.

Puis, pour les contrats projet/save existants :

```bash
cd packages/map_distribution
dart test test/compatibility
dart analyze

cd ../map_core
dart test test/project_json_migrations_test.dart test/save_data_test.dart
dart analyze
```

### Critères de DONE

- matrice exhaustive et approuvée ;
- aucun fallback silencieux ;
- `profileId` obligatoire ;
- `packageFormat`, `gameVersion`, `projectFormat`, Hub/runtime/capabilities et `saveFormat` distincts ;
- préférences et caches mutables isolés sans modifier les versions installées ;
- dernière save valide toujours conservée ;
- migration sur copie avec receipt ;
- rollback jeu séparé du rollback save ;
- politique legacy, uninstall et save complétée décidée ;
- même version/tree hash différent traité explicitement ;
- Gate C approuvée.

### Risques

- confondre SemVer du jeu avec versions de formats ;
- downgrade de jeu rendant une save illisible ;
- checksum sans canonicalisation exacte ;
- attribution erronée de la save globale ;
- scope de repository exposant un autre `gameId`.

### Dépendances

`HUB-001` et `HUB-002`. Bloque `HUB-005` et l’approbation finale de `HUB-004`.

---

## 12. HUB-005 — ADR isolation de session

### Objectif

Choisir une topologie par plateforme tout en gardant un contrat de session indépendant du transport et une autorité de save strictement scoppée.

### Périmètre inclus

- comparaison même processus, player enfant desktop et enfant partout ;
- crash Dart, crash natif, OOM, décodeur, hang et kill ;
- V0, mobile et desktop public ;
- startup, rendu, audio, focus, lifecycle, reprise et teardown ;
- crash marker et récupération ;
- autorité du Hub sur library/save roots ;
- commandes, événements, heartbeat, timeouts et raisons de sortie ;
- choix `apps/pokemap_player` ou mode `--player-session` du binaire Hub ;
- protocole IPC versionné si player enfant ;
- fallback si le prototype desktop ne satisfait pas les critères.

### Hors périmètre

- implémentation du processus enfant ;
- IPC, kill tests, notarisation ou packaging réels ;
- support d’un player enfant mobile ;
- seconde logique métier spécifique desktop.

### Recommandation de départ à valider

- V0/mobile : même processus, session jetable, contenu strictement validé, crash marker ;
- desktop public : player enfant à prototyper avant publication ;
- API `GameSessionController` topology-neutral ;
- le player ne reçoit ni racine libre ni capacité à choisir un autre `gameId` ;
- le Hub reste propriétaire de la bibliothèque et de l’autorité de save.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/adr/0002-session-isolation-by-platform.md`
- `reports/product/pokemap_hub/phase_0/contracts/game-session-port.md`
- `reports/product/pokemap_hub/phase_0/contracts/session-failure-and-exit-matrix.md`

### Fichiers actuels à citer, sans les modifier

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart`
- `examples/playable_runtime_host/lib/main.dart`
- inputs et lifecycle existants inventoriés dans `map_runtime` et le host.

### Tâches

- [ ] Comparer les trois topologies avec coût, UX, rendu, distribution, reprise et crash boundary.
- [ ] Choisir une politique par plateforme/release tier.
- [ ] Définir un port de session commun aux transports.
- [ ] Définir launch/ready/heartbeat/completed/return/fatal/exit.
- [ ] Définir timeouts, perte de transport, double session et process orphelin.
- [ ] Définir l’autorité save et les informations minimales transmises.
- [ ] Définir le teardown audio/input/overlays/cache/moteur.
- [ ] Choisir binaire séparé ou mode du Hub pour le prototype.
- [ ] Définir des critères mesurables de réussite/échec du prototype desktop.
- [ ] Faire approuver Gate D.
- [ ] Ratifier `HUB-000`.

### Tests et revues de Phase 0

- matrice panne → propriétaire → UX → récupération ;
- session normale, exception Dart, exit non-zéro, hang, kill, OOM simulé et Hub fermé ;
- retour titre/Hub après succès, erreur ou crash ;
- double lancement refusé ;
- lancement du jeu B après teardown de A ;
- revue sécurité de l’autorité save ;
- checklist de teardown exhaustive.

### Obligations de preuve downstream

Tests unitaires sous `apps/pokemap_hub/test/session/` :

- `game_session_supervisor_test.dart`
- `session_crash_marker_repository_test.dart`
- `session_teardown_contract_test.dart`.

Test d’intégration séparé :

- `apps/pokemap_hub/integration_test/session_isolation_macos_test.dart`.

Commandes futures :

```bash
cd apps/pokemap_hub
flutter test test/session
flutter analyze
flutter test integration_test/session_isolation_macos_test.dart -d macos
```

### Critères de DONE

- ADR au statut `Accepted` par plateforme ;
- limites OOM/crash natif documentées honnêtement ;
- port identique en-process/IPC ;
- choix binaire séparé ou mode Hub explicite ;
- propriété saves/logs/audio/plein écran/lifecycle décidée ;
- fallback documenté si le prototype enfant échoue ;
- comportement perte IPC et crash marker défini ;
- Gate D approuvée ;
- ADR `HUB-000` ratifié ou amendé.

### Risques

- transformer l’IPC en seconde architecture ;
- croire qu’un `try/catch` isole un OOM ou crash natif ;
- divergence mobile/desktop ;
- fuite d’autorité vers d’autres saves ;
- coût de notarisation et packaging sous-estimé ;
- sur-ingénierie de la V0.

### Dépendances

`HUB-000`, `HUB-002`, `HUB-003`. Précède l’approbation finale de `HUB-004`.

---

## 13. HUB-004 — Architecture de l’information et états Hub/titre/menu/fin

### Objectif

Valider tous les comportements, états, actions, erreurs et récupérations du parcours joueur avant la création d’écrans ou widgets.

Le terme ambigu « IA » de l’audit est développé ici comme **architecture de l’information**, jamais comme intelligence artificielle.

### Périmètre inclus

- boot, recovery, empty state et bibliothèque ;
- accueil avec « Reprendre la dernière partie », jeux installés, import, progression, erreurs de compatibilité, mises à jour, espace disque et diagnostics ;
- détail avec icon, cover, titre, auteur, description, version, dernière sauvegarde, temps de jeu, Continuer, Nouvelle partie, Réparer, Mettre à jour, Gérer les sauvegardes et Désinstaller ;
- import, installation, progression, annulation et erreurs ;
- détail jeu, update, repair, uninstall et saves ;
- titre brandé déclaratif ;
- New Game, Continue, Load, Options, Crédits et Retour Hub ;
- session et menu pause contenant exactement Reprendre, Équipe, Sac, Pokédex, Carte, Sauvegarder, Options et Retour au titre ;
- lifecycle arrière-plan/reprise ;
- `GameCompleted`, verrouillage gameplay, save complétée, résultat et crédits ;
- retour Hub après teardown ;
- clavier, manette, tactile, focus, portrait et paysage ;
- timeouts et récupération ;
- capacités conditionnelles du jeu.

### Règle services monde

Boutique, PC et Centre Pokémon ne figurent pas comme services globaux du menu. Ils sont accessibles par interaction dans le monde ou par une capacité explicite, éventuellement conditionnée par les Facts.

### Hors périmètre

- maquettes haute fidélité ;
- tokens/design system joueur ;
- widgets Flutter ;
- moteur de combat ou dialogue ;
- implémentation no-code de `Terminer le jeu`.

### Fichiers à créer

- `reports/product/pokemap_hub/phase_0/product/information-architecture.md`
- `reports/product/pokemap_hub/phase_0/product/player-state-machine.md`
- `reports/product/pokemap_hub/phase_0/product/action-availability-matrix.md`
- `reports/product/pokemap_hub/phase_0/product/acceptance-journeys.md`
- `reports/product/pokemap_hub/phase_0/product/game-completion-contract.md`

### Fichiers actuels à citer, sans les modifier

- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/in_game_menu_test.dart`
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- captures `reports/product/evidence/hub_runtime_audit_2026-07-24/`.

### Tâches

- [ ] Définir les objets d’information et actions par surface.
- [ ] Définir chaque état avec entrée, sortie, retour, erreur, annulation et récupération.
- [ ] Aligner Continue/New Game/Load avec `HUB-003`.
- [ ] Aligner retour Hub et crash recovery avec `HUB-005`.
- [ ] Définir les règles de focus et d’input sans implémentation.
- [ ] Définir disponibilité des actions selon package, save, compatibilité, capability et lifecycle.
- [ ] Définir `GameCompleted`, résultat, crédits et destinations de retour.
- [ ] Écrire deux walkthroughs neutres multijeux.
- [ ] Vérifier qu’aucun état n’expose debug, seeds, map ID ou chemin workspace.
- [ ] Faire approuver Gate E.

### Tests et revues de Phase 0

- chaque état a une transition de sortie ou un état terminal explicite ;
- transitions interdites documentées ;
- aucune impasse après package corrompu, save incompatible ou disque plein ;
- New Game avec slots existants ;
- Continue avec plusieurs profils et dernière save incompatible ;
- retour Hub après succès, échec et crash ;
- services monde absents sans capability/contexte ;
- walkthrough générique avec deux jeux neutres ;
- revue clavier/manette/tactile, portrait/paysage et accessibilité.

### Obligations de preuve downstream

Sous `apps/pokemap_hub/test/contracts/` :

- `hub_navigation_contract_test.dart`
- `game_detail_action_contract_test.dart`
- `session_return_contract_test.dart`.

Sous `packages/map_player_ui/test/contracts/` :

- `title_flow_contract_test.dart`
- `pause_menu_contract_test.dart`
- `game_completion_contract_test.dart`
- `player_input_accessibility_contract_test.dart`.

Commandes futures :

```bash
cd packages/map_player_ui
flutter test test/contracts
flutter analyze

cd ../../apps/pokemap_hub
flutter test test/contracts
flutter analyze

cd ../../examples/playable_runtime_host
flutter test test/in_game_menu_test.dart test/runtime_launch_save_test.dart
```

### Critères de DONE

- information architecture, state machine et parcours approuvés ;
- happy paths, annulations, erreurs et récupération couverts ;
- comportements destructifs avec confirmation explicite ;
- Continue/New Game alignés sur `HUB-003` ;
- retour Hub aligné sur `HUB-005` ;
- `GameCompleted` lié aux futurs lots runtime/no-code sans les implémenter ;
- aucune UI de debug ou hypothèse Selbrume ;
- services monde uniquement contextuels/capability-driven ;
- Gate E approuvée.

### Risques

- coder l’accueil avant les contrats ;
- confondre architecture de l’information et polish ;
- rendre PC/Boutique/Centre universels ;
- overwrite de save implicite ;
- fin de jeu uniquement visuelle, sans événement métier ;
- parcours impossible à piloter au clavier/manette.

### Dépendances

`HUB-000`, `HUB-003`, `HUB-005`. Peut être esquissé plus tôt, mais doit fermer en dernier.

---

## 14. Gate de cohérence finale Phase 0

Cette gate n’est pas un septième lot.

### Tâches

- [ ] Tous les ADR sont `Accepted`.
- [ ] Toutes les validations A à E sont consignées avec date et décideur.
- [ ] Aucun `TBD`, `TODO`, `FIXME` ou décision structurante différée ne subsiste.
- [ ] `gameId`, versions, capabilities, `SaveEnvelope`, états et raisons de sortie ont le même sens partout.
- [ ] Schéma, threat model et matrice de compatibilité ont été cross-reviewés.
- [ ] Deux jeux neutres sont utilisés dans les scénarios.
- [ ] `playable_runtime_host` apparaît uniquement comme harness/non-objectif.
- [ ] Aucune dépendance de production vers `examples/`.
- [ ] Aucun code/scaffold/UI Hub n’a été commencé avant la gate.
- [ ] Le propriétaire de la primitive de confinement avant `HUB-031` est explicite.
- [ ] Le contrat `GameCompleted` possède des lots downstream identifiés.
- [ ] La roadmap à 47 lots est préservée ou toute modification future est explicitement autorisée.

### Commandes de validation documentaire

À exécuter une fois les artefacts Phase 0 créés :

```bash
find reports/product/pokemap_hub/phase_0 -type f -print | sort
rg -n 'TBD|TODO|FIXME' reports/product/pokemap_hub/phase_0
git ls-files --others --exclude-standard reports/product/pokemap_hub/phase_0
git diff --check
git status --short --untracked-files=all
```

Résultat attendu pour le scan `TBD|TODO|FIXME` : aucune sortie et code retour `1` de `rg`, signifiant qu’aucun motif n’a été trouvé.

Contrôle indépendant des fichiers nouveaux, que `git diff --check` ne couvre pas :

```bash
python3 - <<'PY'
from pathlib import Path

root = Path("reports/product/pokemap_hub/phase_0")
errors = []
for path in root.rglob("*"):
    if not path.is_file():
        continue
    text = path.read_text(encoding="utf-8")
    for number, line in enumerate(text.splitlines(), start=1):
        if line != line.rstrip():
            errors.append(f"{path}:{number}: trailing whitespace")
    if path.suffix == ".md" and text.count("```") % 2:
        errors.append(f"{path}: unbalanced code fences")
if errors:
    raise SystemExit("\n".join(errors))
print("new-file whitespace/Markdown checks: OK")
PY
```

Validation réelle des exemples contre leurs JSON Schemas :

```bash
python3 - <<'PY'
import json
from pathlib import Path
import jsonschema

root = Path("reports/product/pokemap_hub/phase_0")

def require_rejected(validator, paths, label):
    paths = list(paths)
    if not paths:
        raise SystemExit(f"{label}: no invalid fixtures found")
    for path in paths:
        try:
            payload = json.loads(path.read_text())
        except json.JSONDecodeError:
            continue
        if not list(validator.iter_errors(payload)):
            raise SystemExit(f"{label}: fixture unexpectedly accepted: {path}")

manifest_schema = json.loads(
    (root / "contracts/game-manifest-v1.schema.json").read_text()
)
jsonschema.Draft202012Validator.check_schema(manifest_schema)
manifest_validator = jsonschema.Draft202012Validator(manifest_schema)
for path in (root / "contracts/examples").glob("*-valid/game-manifest.json"):
    manifest_validator.validate(json.loads(path.read_text()))
require_rejected(
    manifest_validator,
    (root / "contracts/examples/invalid").rglob("*.json"),
    "manifest schema",
)

save_schema = json.loads(
    (root / "saves/save-envelope-v1.schema.json").read_text()
)
jsonschema.Draft202012Validator.check_schema(save_schema)
save_validator = jsonschema.Draft202012Validator(save_schema)
save_validator.validate(json.loads(
    (root / "saves/examples/minimal-valid-save-envelope.json").read_text()
))
require_rejected(
    save_validator,
    (root / "saves/examples/invalid").rglob("*.json"),
    "save schema",
)

json.loads((root / "compatibility/compatibility-matrix.json").read_text())
print("JSON Schema examples: OK")
PY
```

Le module Python `jsonschema` est une dépendance de validation à déclarer et pinner avant exécution de la gate. S’il est indisponible, la gate reste `NO-GO` ; une simple validation syntaxique avec `json.tool` ne suffit pas.

### Critères de sortie

- Decision Pack cohérent, approuvé et sans ambiguïté ;
- chaque risque P0 possède contrôle, preuve et propriétaire downstream ;
- chaque lot `HUB-000..005` peut être proposé `DONE` avec preuve fraîche ;
- `HUB-010` devient le prochain lot autorisé ;
- aucun lot mécanique FG n’est automatiquement promu par cette gate.

## 15. Matrice de dépendances downstream

| Décision Phase 0 | Premier lot consommateur | Contrôle |
|---|---|---|
| Ownership/packages | `HUB-010` | Scaffolds et barrels suivent `HUB-000`. |
| Format/canonicalisation | `HUB-011/012/013` | Codecs, inventaire et builder suivent `HUB-001`. |
| Hostile policy/confinement | `HUB-014`, puis `HUB-031` | L’inspection et le smoke installateur ne peuvent attendre `HUB-041`. |
| Identité/save envelope | `HUB-020` | Contrats versionnés suivent `HUB-003`. |
| Repository scoppé | `HUB-021/022` | Namespace et atomicité suivent `HUB-003`. |
| Installer/library | `HUB-030..034` | Promotion, rollback et retention suivent `HUB-001..003`. |
| Session topology-neutral | `HUB-040` | Contrôleur compatible in-process/IPC. |
| Runtime asset adapter | `HUB-041` | Adaptateur runtime d’une politique déjà implémentée. |
| Title/New Game/Continue | `HUB-043` | États et guards suivent `HUB-003/004`. |
| Completion/return | `HUB-044` et Phase 7 no-code | Contrat `GameCompleted` et teardown suivent `HUB-004/005`. |
| UI Hub/player | `HUB-050..054` | Aucun écran avant contrats stables. |

## 16. Protocole d’exécution recommandé

Après approbation du présent plan :

1. exécuter `HUB-000` draft ;
2. exécuter `HUB-001` squelette et `HUB-002` en boucle de revue ;
3. fermer la Gate B ;
4. exécuter et fermer `HUB-003` ;
5. exécuter `HUB-005`, puis ratifier `HUB-000` ;
6. finaliser `HUB-004` ;
7. exécuter la gate de cohérence ;
8. demander une autorisation distincte avant tout code `HUB-010`.

Pour chaque lot :

- audit initial ciblé ;
- rédaction documentaire ;
- revue architecture/sécurité/tests selon le lot ;
- validation humaine explicite ;
- vérifications documentaires fraîches ;
- rapport avec état Git initial/final ;
- aucune opération Git d’écriture sans instruction directe.

## 17. Preuves de la présente passe de planification

### Passes indépendantes

| Passe | Verdict |
|---|---|
| Sub-agent Audit / Architecture | **GO documentaire ; NO-GO code.** A identifié l’omission `profileId`, le retard du confinement et la ratification `HUB-000/005`. |
| Sub-agent Implémentation / exécutabilité | **GO conditionnel.** Six lots canoniques avec paquets de décision internes ; ordre numérique strict rejeté. |
| Sub-agent Tests | **NO-GO pour DONE.** Aucun artefact normatif ni test Hub n’existe ; les preuves actuelles sont monoprojet/harness. |
| Sub-agent Build / Validation | **N/A pour build dans une passe documentaire.** Les commandes package-scoped futures sont définies lot par lot. |
| Sub-agent Critique initiale | **NO-GO Phase 1+.** Cinq gates utilisateur et une gate de cohérence requises. |
| Sub-agent Critique finale du fichier | **GO final.** Deux passes `CHANGES_REQUIRED` ont produit neuf corrections ; la troisième revue n’a trouvé aucun nouveau blocage. |

### Commandes d’inspection principales exécutées

```bash
git rev-parse HEAD
git status --short --untracked-files=all
find . -name AGENTS.md -not -path './.git/*' -print
cat AGENTS.md
cat codex_rule.md
cat pokemap_roadmap_mecaniques_fangame.md
cat reports/product/pokemap_hub_player_application_audit_2026-07-24.md
cat skills/README.md
rg --files docs reports packages examples
rg -n '<contrats Hub/save/package/session ciblés>' packages examples
```

Résultats :

- un seul `AGENTS.md`, à la racine ;
- HEAD complet `a3bc35104b558e2d8c27e1c81ac7c2a3fe1a43cc` ;
- aucun changement suivi initial ;
- 73 fichiers non suivis préexistants, préservés ;
- aucun contrat Hub multijeu normatif existant.

### Tests, analyse et build de cette passe

- tests Dart/Flutter : non lancés, car aucun comportement ni code n’a été modifié ;
- analyse Dart/Flutter : non applicable au Markdown ;
- build : non applicable à un plan documentaire ;
- meilleure validation alternative : structure, contenu obligatoire, diff whitespace, absence de modification de code et état Git final.

Les résultats verts cités dans l’audit restent une preuve historique, pas une preuve fraîche de cette passe. Le dépôt ne doit pas être déclaré globalement vert, notamment à cause des trois échecs Selbrume connus sur le même HEAD.

### Validation fraîche du plan

```text
Contrôle Python des espaces et fences Markdown
→ OK

Inventaire des headings HUB-000..005 et sections requises
→ 6 lots présents ; objectif/périmètre/fichiers/tests/DONE/risques/dépendances présents 6 fois

Scan des anciens chemins ignorés et placeholders
→ aucune occurrence ; code retour rg = 1

git check-ignore -v reports/product/pokemap_hub_phase_0_contracts_plan_2026-07-24.md
→ aucune sortie ; code retour = 1, fichier non ignoré

git status --short --untracked-files=all
→ 0 changement suivi ; 74 fichiers non suivis visibles, soit les 73 préexistants + ce plan
```

## 18. Fichiers créés ou modifiés par cette passe

Fichier créé :

- `reports/product/pokemap_hub_phase_0_contracts_plan_2026-07-24.md`
  - contenu complet : le présent document ;
  - rôle : plan documentaire exécutable et gate de non-implémentation ;
  - impact : aucun comportement runtime, éditeur, host ou save modifié.

Fichiers modifiés ou supprimés : aucun.

### État Git final de la passe

```text
HEAD: a3bc35104b558e2d8c27e1c81ac7c2a3fe1a43cc
Changements suivis: 0
Fichiers non suivis visibles: 74
  - baseline utilisateur préexistante: 73
  - fichier créé par cette passe: 1
Fichiers créés mais ignorés: 0
```

Le premier emplacement envisagé sous `docs/superpowers/plans/` était couvert par la règle `.gitignore: /docs/*`. Il a été abandonné et le fichier a été déplacé sous `reports/product/`; aucun doublon ignoré ne subsiste.

## 19. Limites, risques et auto-critique

### Limites conservées

- aucun quota numérique n’est choisi par ce plan : le choix appartient à `HUB-002` et doit être justifié/approuvé ;
- aucun format ZIP définitif n’est accepté par ce plan ;
- aucun owner recommandé n’est considéré accepté avant Gate A ;
- aucun test Hub réel ne peut être lancé avant la création approuvée des modules ;
- aucune preuve générique multijeu n’existe encore ;
- les captures d’audit décrivent le host, pas le futur design final.

### Risques restants

- `HUB-001/002/003` peuvent produire des documents contradictoires sans revue commune ;
- un child player desktop peut exiger une cible de build non prévue ;
- un format byte-deterministic peut dépendre des capacités de la bibliothèque ZIP retenue ;
- des quotas trop stricts peuvent bloquer des jeux valides, trop larges peuvent exposer le Hub ;
- les saves legacy ne peuvent pas être associées automatiquement sans risque ;
- les contrats de présentation Flutter actuels ne sont pas tous sérialisables pour IPC ;
- `GameCompleted` reste un gap de roadmap mécanique explicite.

### Auto-critique

Le plan est volontairement plus détaillé que les six lignes de roadmap afin d’empêcher une implémentation prématurée. Son principal risque est de transformer la Phase 0 en documentation sans fin. Les gates limitent ce risque : chaque lot doit trancher des décisions nommées, produire des matrices testables et interdire les `TBD`. La Phase 0 ne doit pas devenir un prétexte pour implémenter des prototypes non approuvés.

## 20. Handoff

Action attendue : revue et validation de la décomposition, de l’ordre causal et du registre `P0-D01..P0-D15`.

Tant que cette validation n’est pas donnée :

- ne pas exécuter `HUB-000` ;
- ne créer aucun document normatif sous `reports/product/pokemap_hub/phase_0/` ;
- ne créer aucun package/app ;
- ne modifier ni roadmap ni code ;
- conserver `HUB-000..005` à `TODO`.
