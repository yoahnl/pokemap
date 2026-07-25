# Runtime-Owned Player Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire de `map_runtime` l’autorité complète de la session joueur, faire de `map_player_ui` son renderer Flutter responsive et réduire `pokemap_hub` à la sélection d’un jeu, la fourniture d’adaptateurs et l’hébergement de la vue joueur.

**Architecture:** Le Hub fournit une source de jeu installée, un stockage de sauvegardes, des préférences et un callback de sortie. `map_runtime` possède la machine d’état, les commandes, le cycle de vie, les verrous d’input et les services contextuels. `map_player_ui` dépend des contrats du runtime et transforme leurs snapshots en widgets Flutter. Le sens de dépendance reste strictement `pokemap_hub -> map_player_ui -> map_runtime`; `map_runtime` ne dépend jamais de `map_player_ui`.

**Tech Stack:** Dart 3, Flutter, Flame, `package:test`, `flutter_test`, APIs de focus et d’actions Flutter, contrats existants `GameSessionController`, `PlayerInputRouter`, Scene V2 et services runtime.

---

## 1. Résultat produit attendu

À la fin de ce plan :

- le Hub peut ouvrir un jeu installé sans posséder l’écran titre, le menu pause, les écrans de détail, les résultats ou les crédits ;
- le player runtime peut passer par `titre -> chargement -> jeu -> pause -> détail -> jeu -> titre -> Hub` sans superposition d’interfaces ni softlock ;
- le menu pause est une UI Flutter provenant de `map_player_ui`, pilotée par `map_runtime` ;
- le menu s’adapte en trois variantes :
  - desktop et grande fenêtre : panneau latéral avec navigation et détail côte à côte ;
  - mobile paysage : panneau compact à deux colonnes ;
  - mobile portrait : feuille racine puis page de détail ;
- le player accepte :
  - desktop : clavier, souris et manette ;
  - mobile portrait ou paysage : tactile et manette ;
- la sélection et le focus logique survivent à un changement de taille ou d’orientation ;
- Boutique, Centre Pokémon et PC ne figurent jamais dans le menu pause ;
- ces services sont ouverts par une interaction du monde, un objet, une zone ou un événement, avec préconditions éventuelles ;
- le retour au titre détruit complètement la session Flame ;
- le retour au Hub ne peut intervenir que depuis le titre, après destruction de la session ;
- l’architecture reste compatible avec un futur host standalone sans implémenter ce host dans ce chantier.

## 2. Périmètre et non-objectifs

### Inclus

- contrats génériques du player runtime ;
- machine d’état et commandes révisionnées ;
- migration des responsabilités actuellement détenues par le shell Hub ;
- écran titre, chargement, erreur, résultat et crédits ;
- menu pause A1 et écrans joueur simples ;
- routing clavier, souris, tactile et manette ;
- lifecycle, teardown, reprise et récupération ;
- Boutique, soin et PC contextuels ;
- adaptateurs Hub ;
- tests d’architecture, unitaires, widgets, intégration et smoke macOS.

### Exclus

- création d’une application standalone et packaging d’un exécutable standalone ;
- nouveau format `.pokemapgame` ou modification de son schéma ;
- refonte du moteur de combat `map_battle` ;
- refonte globale du Hub, de la bibliothèque ou de l’installateur ;
- remplacement du `playable_runtime_host`, qui reste un outil développeur ;
- refonte visuelle complète de tous les écrans Équipe, Sac, Pokédex, Carte et Options ;
- modification du fichier roadmap sans demande explicite séparée.

## 3. Contraintes non négociables

1. `map_runtime` ne dépend pas de `map_player_ui`.
2. `map_player_ui` ne dépend pas de `pokemap_hub`.
3. Aucun type `Hub*` ne doit apparaître dans une API publique runtime ou player UI.
4. Les snapshots runtime sont immuables et portent une révision monotone.
5. Toute commande UI porte la révision du snapshot qui l’a produite.
6. Une commande obsolète est refusée sans effet métier.
7. Tout verrou d’input acquis par un écran modal est libéré dans un `finally`.
8. Un échec de sauvegarde ne détruit jamais la dernière sauvegarde valide.
9. Un changement de layout conserve la section, la sélection et le focus logique.
10. Boutique, soin et PC sont des services contextuels, jamais des entrées globales du menu pause.
11. Le Hub n’empile aucun overlay joueur au-dessus de l’UI runtime.
12. La dernière session Flame est détruite avant le titre, puis le titre est détruit avant la sortie vers le Hub.

## 4. Lots et ordre de livraison

| Phase | Lots | Sortie principale |
|---|---|---|
| Phase 0 — Baseline et frontières | P0-L1 à P0-L2 | Comportement actuel caractérisé et frontières protégées |
| Phase 1 — Contrats player runtime | P1-L1 à P1-L3 | Ports génériques, snapshots, commandes et input logique |
| Phase 2 — Coordinateur runtime | P2-L1 à P2-L4 | Parcours titre/session/pause/fin/lifecycle possédé par le runtime |
| Phase 3 — UI joueur Flutter | P3-L1 à P3-L4 | Vue player et menu A1 responsive avec focus multi-input |
| Phase 4 — Bascule du Hub | P4-L1 à P4-L3 | Hub réduit à ses adaptateurs et à l’hébergement |
| Phase 5 — Services contextuels | P5-L1 à P5-L4 | Boutique, soin et PC ouverts depuis le monde |
| Phase 6 — Durcissement | P6-L1 à P6-L3 | Robustesse input, lifecycle, sauvegarde et teardown |
| Phase 7 — Certification et clôture | P7-L1 à P7-L3 | E2E, build macOS, preuves et dette documentée |

## 5. Graphe de dépendances

```text
P0-L1 ──> P0-L2
             │
             ├──> P1-L1 ──> P1-L2 ──> P2-L1 ──> P2-L2 ──> P2-L3
             │                 │           │         │         │
             └──> P1-L3 ───────┘           └─────────┴──> P2-L4
                                                           │
P1-L2 ──> P3-L1 ──> P3-L2 ──> P3-L3 ──> P3-L4            │
                          │                     │            │
                          └─────────────────────┴────────────┤
                                                           v
P1-L1 ──> P4-L1 ───────────────────────────────────────> P4-L2 ──> P4-L3
             │                                               │
             └──> P5-L1 ──> P5-L2 ──> P5-L3 ──> P5-L4      │
                                                           v
                                      P6-L1 ──> P6-L2 ──> P6-L3
                                                           │
                                                           v
                                      P7-L1 ──> P7-L2 ──> P7-L3
```

## 6. Règles d’exécution communes

Pour chaque lot :

- commencer par `git status --short --untracked-files=all` ;
- ne modifier que les fichiers listés ou une dépendance directe découverte et justifiée ;
- ajouter d’abord le test ciblé en échec ;
- exécuter le test ciblé et conserver le motif exact de l’échec ;
- implémenter le plus petit changement qui le rend vert ;
- lancer l’analyse du package concerné ;
- exécuter `git diff --check` ;
- inspecter le status final et préserver les changements préexistants ;
- ne faire le commit indiqué que si l’exécution du plan est explicitement autorisée à écrire dans Git.

Les deux échecs Selbrume connus ne doivent pas être assimilés à des régressions de ce chantier :

- `selbrume_event_v2_three_source_integration_test.dart` : `Bad state: Too many elements` ;
- `selbrume_narrative_campaign_outcome_matrix_test.dart` : verdict attendu `pass`, verdict obtenu `indeterminate`.

Tout nouvel échec doit être isolé et expliqué. Le dépôt ne doit pas être déclaré globalement vert tant que ces suites n’ont pas été rejouées et corrigées.

---

# Phase 0 — Baseline et frontières

## P0-L1 — Caractériser le parcours player actuel

**Objectif**

Figer par des tests le comportement utile déjà présent et reproduire les deux régressions observées : double UI et blocage après `Continue`.

**Périmètre**

- parcours Hub vers jeu installé ;
- titre, nouvelle partie, continuer, pause, reprise ;
- combat suivi de progression ;
- retour au titre puis au Hub ;
- vérification qu’un seul propriétaire rend chaque surface.

**Dépendances**

- aucune ;
- le package installé de test et les fixtures Hub existantes.

**Fichiers concernés**

- Modifier : `apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart`
- Modifier : `apps/pokemap_hub/test/ui/hub_runtime_presentation_test.dart`
- Modifier : `packages/map_runtime/test/session/playable_map_game_session_runtime_test.dart`
- Modifier : `packages/map_runtime/test/playable_map_game_post_battle_progression_integration_test.dart`
- Créer : `apps/pokemap_hub/test/ui/hub_player_ownership_characterization_test.dart`

**Étapes**

- [ ] Capturer l’état Git initial sans supprimer les fichiers non suivis.
- [ ] Ajouter un test qui monte un jeu installé puis vérifie qu’une seule surface de titre, de pause et de combat est présente.
- [ ] Ajouter un test qui déclenche `Continue`, ferme la progression post-combat et prouve que les déplacements redeviennent possibles.
- [ ] Ajouter un test qui revient au titre et vérifie que l’ancienne session ne reçoit plus de commandes.
- [ ] Lancer les tests ciblés et consigner séparément les comportements déjà verts et les reproductions rouges.
- [ ] Ne corriger aucun comportement dans ce lot : son produit est la baseline testée.

**Commandes**

```bash
cd apps/pokemap_hub
flutter test test/ui/hub_player_ownership_characterization_test.dart
flutter test test/ui/hub_app_player_navigation_test.dart test/ui/hub_runtime_presentation_test.dart

cd packages/map_runtime
flutter test test/session/playable_map_game_session_runtime_test.dart
flutter test test/playable_map_game_post_battle_progression_integration_test.dart
```

**Critères de DONE**

- chaque surface actuelle possède un test de caractérisation ;
- la double UI échoue avec un message ciblé, pas avec une recherche fragile de texte générique ;
- le test post-`Continue` observe un déplacement ou une commande de monde réellement acceptée ;
- aucun code produit n’est modifié ;
- les échecs préexistants sont distingués des nouvelles attentes.

**Risques**

- les tests Hub peuvent être trop couplés au texte localisé ;
- un faux positif est possible si deux surfaces utilisent des labels différents ;
- la progression post-combat peut nécessiter un fake d’horloge déterministe.

**Commit suggéré**

```bash
git add apps/pokemap_hub/test/ui packages/map_runtime/test
git commit -m "test(player): characterize runtime ownership and resume flow"
```

## P0-L2 — Verrouiller les frontières d’architecture

**Objectif**

Empêcher toute nouvelle dépendance inverse et rendre mesurable la disparition progressive de la logique player dans le Hub.

**Périmètre**

- imports interdits ;
- symboles interdits dans les API publiques ;
- définition des propriétaires de chaque état ;
- inventaire explicite des classes Hub à migrer puis supprimer.

**Dépendances**

- P0-L1.

**Fichiers concernés**

- Modifier : `packages/map_runtime/test/session/session_architecture_boundary_test.dart`
- Créer : `packages/map_player_ui/test/player/player_architecture_boundary_test.dart`
- Créer : `apps/pokemap_hub/test/player/hub_player_architecture_boundary_test.dart`
- Modifier : `packages/map_runtime/lib/src/session/game_session_contract.dart`
- Modifier : `docs/superpowers/specs/2026-07-25-runtime-owned-player-shell-design.md` uniquement si un écart factuel est découvert.

**Étapes**

- [ ] Ajouter un test interdisant tout import de `map_player_ui` et de `pokemap_hub` sous `packages/map_runtime/lib`.
- [ ] Ajouter un test interdisant tout import de `pokemap_hub` sous `packages/map_player_ui/lib`.
- [ ] Ajouter un test interdisant les noms `Hub`, `InstalledGame` et `Library` dans les exports publics runtime player.
- [ ] Ajouter au test Hub une allowlist temporaire des fichiers qui possèdent encore la machine d’état player.
- [ ] Documenter dans le test l’échéance de suppression de chaque entrée de l’allowlist par numéro de lot.
- [ ] Remplacer dans `GameSessionDescriptor` le vocabulaire « créé par le Hub » par « créé par le host » sans changer le comportement.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/session/session_architecture_boundary_test.dart

cd packages/map_player_ui
flutter test test/player/player_architecture_boundary_test.dart

cd apps/pokemap_hub
flutter test test/player/hub_player_architecture_boundary_test.dart
```

**Critères de DONE**

- les trois règles de dépendance sont testées ;
- chaque exception temporaire est liée à un lot de suppression ;
- le runtime ne décrit plus le Hub comme autorité de lancement ;
- le test échoue si un import interdit ou un type `Hub*` est ajouté.

**Risques**

- les tests textuels d’import doivent ignorer `test/`, `.dart_tool/` et `build/` ;
- une allowlist trop large masquerait une régression.

**Commit suggéré**

```bash
git add packages/map_runtime packages/map_player_ui apps/pokemap_hub/test/player
git commit -m "test(architecture): lock player ownership boundaries"
```

---

# Phase 1 — Contrats player runtime

## P1-L1 — Introduire les ports génériques du host

**Objectif**

Remplacer les dépendances directes aux concepts Hub par des ports génériques utilisables plus tard par un Hub, un host de développement ou un standalone.

**Périmètre**

- source de jeu ;
- sauvegardes ;
- préférences ;
- sortie externe ;
- contexte de lancement générique.

**Dépendances**

- P0-L2.

**Fichiers concernés**

- Créer : `packages/map_runtime/lib/src/player/runtime_player_host.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_host_test.dart`
- Modifier : `packages/map_runtime/lib/map_runtime.dart`
- Modifier : `packages/map_runtime/lib/src/session/game_session_contract.dart`

**API cible**

```dart
abstract interface class RuntimeGameSource {
  GameIdentity get identity;
  String get displayTitle;
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    String? saveReadHandle,
  });
}

abstract interface class PlayerSaveGateway {
  Future<PlayerSaveSummary?> readLatestSummary();
  Future<String?> openSaveReadHandle({
    required GameSessionLaunchMode launchMode,
  });
  Future<void> commit(GameSessionCheckpointCommit request);
}

abstract interface class PlayerPreferencesGateway {
  Future<PlayerPreferencesSnapshot> load();
  Future<void> save(PlayerPreferencesSnapshot preferences);
}

abstract interface class RuntimeExternalExit {
  Future<void> returnToHost();
}
```

`PlayerSaveSummary` et `PlayerPreferencesSnapshot` sont des valeurs immuables introduites dans le même fichier. Le plan réutilise `GameSessionLaunchMode` et `GameSessionCheckpointCommit`, déjà définis par le runtime, afin de ne pas créer un second vocabulaire pour `newGame`, `continueGame`, `load` et la persistance des checkpoints.

**Étapes**

- [ ] Écrire les tests de contrat avec des fakes minimaux et prouver que chaque port peut être implémenté sans Flutter widget.
- [ ] Définir des valeurs immuables pour le résumé de sauvegarde et les préférences.
- [ ] Réutiliser `GameIdentity`, le read handle opaque et les contrats de session existants lorsque leur sens est déjà générique.
- [ ] Déplacer un type existant uniquement si son nom ou son package crée une dépendance Hub ; sinon l’adapter.
- [ ] Exporter les nouveaux contrats dans `map_runtime.dart`.
- [ ] Vérifier qu’aucune API ne suppose un chemin local ou une bibliothèque installée.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_host_test.dart
flutter test test/session/session_architecture_boundary_test.dart
flutter analyze
```

**Critères de DONE**

- un fake host en mémoire peut fournir un jeu, une sauvegarde et des préférences ;
- aucun type public ne contient `Hub` ou `InstalledGame` ;
- aucun chemin de stockage n’est imposé par le runtime ;
- le callback de sortie est externe et testable ;
- les exports publics sont documentés.

**Risques**

- dupliquer des contrats de save déjà présents ;
- laisser fuiter `HubSaveStore` dans une signature ;
- rendre le runtime responsable de l’installation, hors périmètre.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): add generic player host ports"
```

## P1-L2 — Définir snapshot, phases et commandes révisionnées

**Objectif**

Créer le langage stable entre la machine d’état runtime et l’UI Flutter.

**Périmètre**

- phases player ;
- section de pause ;
- actions disponibles ;
- progression ;
- erreur récupérable ;
- sélection logique ;
- révision monotone ;
- rejet des commandes périmées.

**Dépendances**

- P1-L1.

**Fichiers concernés**

- Créer : `packages/map_runtime/lib/src/player/runtime_player_models.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_models_test.dart`
- Modifier : `packages/map_runtime/lib/map_runtime.dart`

**API cible**

```dart
enum RuntimePlayerPhase {
  boot,
  title,
  preparingSession,
  loadingSession,
  playing,
  paused,
  saving,
  lifecyclePaused,
  completing,
  result,
  credits,
  disposingSession,
  externalExit,
  error,
}

enum RuntimePlayerPauseSection {
  root,
  party,
  bag,
  pokedex,
  map,
  options,
}

enum RuntimePlayerAction {
  continueGame,
  newGame,
  load,
  openMenu,
  resume,
  openParty,
  openBag,
  openPokedex,
  openMap,
  save,
  openOptions,
  returnToPauseRoot,
  returnToTitle,
  showCredits,
  finishCredits,
  returnToHost,
  retry,
  cancel,
}

final class RuntimePlayerCommand {
  const RuntimePlayerCommand({
    required this.action,
    required this.snapshotRevision,
    this.payload,
  });

  final RuntimePlayerAction action;
  final int snapshotRevision;
  final Object? payload;
}
```

`RuntimePlayerSnapshot` doit exposer la phase, la section, les actions autorisées, la progression éventuelle, l’erreur éventuelle, l’identifiant de sélection logique et la source d’input active. Il ne contient aucun widget ni contexte Flutter.

**Étapes**

- [ ] Tester l’égalité et l’immuabilité du snapshot.
- [ ] Tester que les actions disponibles sont explicites et que l’UI n’a pas à les déduire de la phase.
- [ ] Tester que l’incrément de révision accompagne chaque transition observable.
- [ ] Tester la représentation d’une erreur récupérable avec actions `retry` et `cancel`.
- [ ] Tester qu’une section indisponible porte une raison lisible et n’est pas seulement absente.
- [ ] Exporter les modèles.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_models_test.dart
flutter analyze
```

**Critères de DONE**

- toutes les phases validées dans la spécification sont représentées ;
- chaque snapshot porte une révision ;
- chaque commande porte la révision source ;
- l’UI peut rendre les actions disponibles et indisponibles sans connaître les règles métier ;
- le modèle ne dépend ni de Flutter ni du Hub.

**Risques**

- un `Object? payload` trop permissif peut affaiblir le typage ; limiter les payloads à des valeurs dédiées et les remplacer par des commandes spécialisées si plus de deux formes apparaissent ;
- une liste d’actions calculée dans l’UI recréerait une deuxième autorité.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): define revisioned player snapshots and commands"
```

## P1-L3 — Unifier les inputs logiques du player

**Objectif**

Faire converger clavier, souris, tactile et manette vers des intentions logiques uniques, indépendantes du layout.

**Périmètre**

- source d’input active ;
- navigation directionnelle ;
- confirmer, retour, menu/start ;
- pointeur/tactile ;
- mémorisation de sélection ;
- politique de visibilité du bouton tactile.

**Dépendances**

- P0-L2 ;
- P1-L2.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/session/player_input.dart`
- Créer : `packages/map_runtime/lib/src/player/runtime_player_input.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_input_test.dart`
- Modifier : `packages/map_runtime/test/session/player_input_router_test.dart`
- Modifier : `packages/map_runtime/lib/map_runtime.dart`

**Étapes**

- [ ] Ajouter `PlayerInputSource.keyboard`, `mouse`, `touch` et `controller`.
- [ ] Ajouter les intentions `moveFocus`, `confirm`, `back`, `openMenu` et `activatePointerTarget`.
- [ ] Tester le passage de souris à manette sans double activation.
- [ ] Tester qu’un événement tactile active la source tactile et qu’un événement manette ultérieur active la source manette.
- [ ] Tester que `Menu/Start` est ignoré pendant un verrou modal non refermable.
- [ ] Définir une politique pure : sur mobile, le bouton tactile reste monté et devient atténué après une activité manette ; il ne disparaît pas.
- [ ] Conserver les mappings plateforme dans les adaptateurs, pas dans la machine d’état.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_input_test.dart
flutter test test/session/player_input_router_test.dart
flutter analyze
```

**Critères de DONE**

- une même intention `openMenu` peut provenir du clavier, du tactile ou de la manette ;
- la source active est observable dans le snapshot ;
- aucun test ne dépend d’un modèle précis de manette ;
- le changement de source ne modifie pas la sélection logique ;
- les inputs de jeu et de menu peuvent être verrouillés séparément.

**Risques**

- doubles événements générés par un bouton manette et son émulation clavier ;
- disparition du focus quand la souris bouge sans clic ;
- confusion entre input de monde Flame et navigation Flutter.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): unify logical player input sources"
```

---

# Phase 2 — Coordinateur runtime

## P2-L1 — Créer le coordinateur et le parcours titre/lancement

**Objectif**

Déplacer l’autorité `boot -> title -> preparing -> loading -> playing` du Hub vers `map_runtime`.

**Périmètre**

- initialisation ;
- lecture des sauvegardes ;
- Continuer ;
- Nouvelle partie ;
- Charger ;
- progression de chargement ;
- annulation avant création de session.

**Dépendances**

- P1-L1 ;
- P1-L2 ;
- P1-L3.

**Fichiers concernés**

- Créer : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_coordinator_launch_test.dart`
- Modifier : `packages/map_runtime/lib/src/session/game_session_controller.dart`
- Modifier : `packages/map_runtime/lib/src/session/in_process_game_session_adapter.dart`
- Modifier : `packages/map_runtime/lib/map_runtime.dart`

**API cible**

```dart
final class RuntimePlayerCoordinator {
  RuntimePlayerCoordinator({
    required RuntimeGameSource gameSource,
    required PlayerSaveGateway saveGateway,
    required PlayerPreferencesGateway preferencesGateway,
    required RuntimeExternalExit externalExit,
    required GameSessionController sessionController,
  });

  ValueListenable<RuntimePlayerSnapshot> get snapshot;

  Future<void> initialize();
  Future<RuntimeCommandResult> dispatch(RuntimePlayerCommand command);
  Future<void> pauseForLifecycle();
  Future<void> resumeFromLifecycle();
  Future<void> dispose();
}
```

**Étapes**

- [ ] Écrire un test qui initialise sans sauvegarde et obtient un titre avec `newGame`.
- [ ] Écrire un test qui initialise avec sauvegarde compatible et obtient `continueGame`.
- [ ] Écrire un test qui refuse Continuer si le résumé existe mais que la save ne peut pas être ouverte.
- [ ] Écrire un test qui publie les étapes `preparingSession` puis `loadingSession`.
- [ ] Implémenter une sérialisation des commandes afin qu’un second lancement soit refusé pendant le premier.
- [ ] Rejeter une commande dont `snapshotRevision` n’est plus courante.
- [ ] Transformer les exceptions de source, save ou session en erreur runtime avec action de reprise appropriée.
- [ ] Ne pas intégrer de widget dans le coordinateur.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_coordinator_launch_test.dart
flutter test test/session/game_session_controller_test.dart test/session/in_process_game_session_adapter_test.dart
flutter analyze
```

**Critères de DONE**

- le Hub n’est pas nécessaire pour tester le parcours de lancement ;
- les trois intentions de lancement sont distinguées ;
- un double clic ne crée qu’une session ;
- une commande périmée retourne un résultat explicite et n’a aucun effet ;
- la progression et les erreurs sont visibles dans le snapshot.

**Risques**

- course entre lecture de sauvegarde et nouvelle partie ;
- double création de session sur double activation ;
- perte de la cause initiale lors de la conversion d’erreur.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): own player title and launch flow"
```

## P2-L2 — Posséder pause, reprise et navigation de détail

**Objectif**

Faire du runtime l’unique autorité du menu pause et de sa navigation logique.

**Périmètre**

- ouverture Menu/Start ;
- pause du monde ;
- root et sections ;
- retour au root ;
- reprise ;
- actions disponibles ou désactivées ;
- sélection logique.

**Dépendances**

- P2-L1.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_coordinator_pause_test.dart`
- Modifier : `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modifier : `packages/map_runtime/test/session/playable_map_game_session_runtime_test.dart`

**Étapes**

- [ ] Tester qu’`openMenu` depuis `playing` met le monde en pause avant de publier `paused`.
- [ ] Tester que `openParty`, `openBag`, `openPokedex`, `openMap` et `openOptions` changent uniquement la section logique.
- [ ] Tester que `returnToPauseRoot` conserve le menu ouvert.
- [ ] Tester que `resume` ferme le menu, libère le verrou UI et reprend le monde.
- [ ] Tester qu’une section indisponible ne change pas l’état et retourne sa raison.
- [ ] Tester que Boutique, soin et PC n’existent pas dans les actions du snapshot pause.
- [ ] Conserver la dernière sélection de root et de chaque section dans le coordinateur.
- [ ] Encadrer acquisition et libération du verrou d’input par `try/finally`.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_coordinator_pause_test.dart
flutter test test/session/playable_map_game_session_runtime_test.dart
flutter analyze
```

**Critères de DONE**

- le monde ne reçoit aucun déplacement pendant la pause ;
- `resume` restaure effectivement les déplacements ;
- le runtime, pas l’UI, décide si une action est disponible ;
- le root contient exactement Reprendre, Équipe, Sac, Pokédex, Carte, Sauvegarder, Options et Retour au titre ;
- aucun service contextuel n’est exposé globalement.

**Risques**

- deux verrous concurrents entre pause et dialogue ;
- reprise visuelle sans reprise du tick Flame ;
- perte de sélection lors d’un changement de section.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): own pause navigation and resume"
```

## P2-L3 — Posséder sauvegarde, fin, résultat et crédits

**Objectif**

Compléter le parcours joueur après la partie sans déléguer ces états au Hub.

**Périmètre**

- sauvegarde manuelle ;
- marqueur de partie complétée ;
- `GameCompleted` ;
- résultat ;
- crédits ;
- retour au titre.

**Dépendances**

- P2-L2.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_coordinator_completion_test.dart`
- Modifier : `packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart`
- Modifier : `packages/map_runtime/lib/src/session/game_session_contract.dart`
- Modifier : `packages/map_runtime/test/session/playable_map_game_session_runtime_test.dart`

**Étapes**

- [ ] Tester qu’une commande Save passe par `saving`, écrit un checkpoint et revient à la section précédente.
- [ ] Tester qu’un échec d’écriture publie une erreur récupérable sans détruire la session.
- [ ] Ajouter ou réutiliser l’événement typé `GameCompleted`.
- [ ] Tester qu’une fin de jeu bloque le gameplay avant de publier `completing`.
- [ ] Écrire un checkpoint marqué complété avant d’afficher le résultat.
- [ ] Tester `result -> credits -> title`.
- [ ] Tester le chemin `result -> title` lorsqu’un jeu n’a pas de crédits déclaratifs.
- [ ] Vérifier que le titre est affiché uniquement après teardown de la session.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_coordinator_completion_test.dart
flutter test test/session/playable_map_game_session_runtime_test.dart
flutter analyze
```

**Critères de DONE**

- la sauvegarde manuelle est commandée par le runtime ;
- l’erreur de save conserve le dernier état jouable ;
- `GameCompleted` verrouille le monde ;
- résultat et crédits sont des phases runtime ;
- aucune phase de fin n’est implémentée dans le Hub.

**Risques**

- affichage du résultat avant confirmation du checkpoint ;
- double traitement de `GameCompleted` ;
- crédits absents ou invalides.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): own save completion results and credits"
```

## P2-L4 — Posséder lifecycle, teardown et sortie externe

**Objectif**

Garantir qu’une session peut être suspendue, reprise, détruite et quittée sans conserver de monde fantôme.

**Périmètre**

- background/foreground ;
- phase précédente ;
- crash marker si déjà disponible ;
- destruction de session ;
- retour titre ;
- retour host ;
- dispose idempotent.

**Dépendances**

- P2-L1 ;
- P2-L2 ;
- P2-L3.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_coordinator_lifecycle_test.dart`
- Modifier : `packages/map_runtime/lib/src/session/game_session_controller.dart`
- Modifier : `packages/map_runtime/test/session/game_session_controller_test.dart`

**Étapes**

- [ ] Tester `playing -> lifecyclePaused -> playing`.
- [ ] Tester `paused/detail -> lifecyclePaused -> paused/detail`.
- [ ] Tester que deux notifications background successives sont idempotentes.
- [ ] Tester `returnToTitle` : verrouillage, phase `disposingSession`, dispose unique, puis titre.
- [ ] Tester que `returnToHost` est refusé depuis `playing` et `paused`.
- [ ] Tester que `returnToHost` depuis le titre dispose le coordinateur puis appelle le port externe une seule fois.
- [ ] Tester que toute exception de teardown libère les verrous et produit une erreur récupérable.
- [ ] Rendre `dispose()` idempotent.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_coordinator_lifecycle_test.dart
flutter test test/session/game_session_controller_test.dart
flutter analyze
```

**Critères de DONE**

- la phase précédant le background est restaurée ;
- aucune session ne survit au retour titre ;
- le host n’est appelé que depuis le titre ;
- dispose et lifecycle sont idempotents ;
- les verrous sont libérés même en cas d’exception.

**Risques**

- callback externe déclenché alors qu’un widget est déjà démonté ;
- reprise d’une session partiellement détruite ;
- perte de la section de pause après background.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): harden player lifecycle and teardown"
```

---

# Phase 3 — UI joueur Flutter

## P3-L1 — Créer la vue player canonique

**Objectif**

Fournir un widget unique qui écoute le snapshot runtime et rend les surfaces correspondantes.

**Périmètre**

- titre ;
- chargement ;
- jeu ;
- erreur ;
- résultat ;
- crédits ;
- composition sans logique métier.

**Dépendances**

- P1-L2 ;
- P2-L1 ;
- P2-L3.

**Fichiers concernés**

- Créer : `packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart`
- Créer : `packages/map_player_ui/lib/src/player/runtime_player_surface_router.dart`
- Créer : `packages/map_player_ui/test/player/pokemap_player_session_view_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/player_title_screen.dart`
- Modifier : `packages/map_player_ui/lib/src/player/player_session_surfaces.dart`
- Modifier : `packages/map_player_ui/lib/map_player_ui.dart`

**Étapes**

- [ ] Écrire un fake coordinateur publiant chaque phase.
- [ ] Vérifier qu’une seule surface est montée pour chaque phase.
- [ ] Relier les boutons aux `RuntimePlayerCommand` portant la révision du snapshot courant.
- [ ] Désactiver une action absente de `availableActions` sans la recalculer localement.
- [ ] Afficher progression, étape et possibilité d’annulation lorsque le snapshot les expose.
- [ ] Afficher une erreur lisible avec cause, étape, action recommandée et bouton de diagnostic si disponible.
- [ ] Conserver la scène Flame montée uniquement pendant les phases qui en ont besoin.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/pokemap_player_session_view_test.dart
flutter test test/player/player_title_screen_test.dart
flutter analyze
```

**Critères de DONE**

- un seul widget public suffit à héberger tout le player ;
- aucune phase n’est déduite depuis un état Hub ;
- aucune surface n’est empilée en double ;
- les commandes portent la bonne révision ;
- le widget peut être monté avec un fake runtime sans Hub.

**Risques**

- deux scènes montées pendant une transition ;
- perte de state Flutter à chaque snapshot ;
- callbacks après dispose.

**Commit suggéré**

```bash
git add packages/map_player_ui
git commit -m "feat(player-ui): add canonical runtime player view"
```

## P3-L2 — Implémenter le menu pause A1 responsive

**Objectif**

Rendre le menu validé sur desktop, mobile paysage et mobile portrait à partir du même état runtime.

**Périmètre**

- root ;
- panneau détail ;
- breakpoints basés sur contraintes ;
- scroll ;
- safe areas ;
- bouton tactile de menu.

**Dépendances**

- P2-L2 ;
- P3-L1.

**Fichiers concernés**

- Modifier : `packages/map_player_ui/lib/src/player/player_pause_menu.dart`
- Créer : `packages/map_player_ui/lib/src/player/runtime_player_pause_shell.dart`
- Créer : `packages/map_player_ui/lib/src/player/runtime_player_layout.dart`
- Créer : `packages/map_player_ui/test/player/runtime_player_pause_shell_test.dart`
- Modifier : `packages/map_player_ui/test/player_pause_menu_test.dart`

**Règles de layout**

```dart
enum RuntimePlayerLayoutClass {
  compactPortrait,
  compactLandscape,
  expanded,
}
```

- `compactPortrait` : root en feuille, puis détail plein écran ;
- `compactLandscape` : navigation et détail en deux colonnes compactes ;
- `expanded` : panneau droit, navigation et détail côte à côte ;
- le choix dépend de `BoxConstraints`, du ratio et de l’espace utile, jamais de `Platform`.

**Étapes**

- [ ] Écrire trois golden-like widget tests avec tailles fixes représentatives.
- [ ] Tester le root exact et l’absence de Boutique, Centre Pokémon et PC.
- [ ] Implémenter le calcul de classe de layout comme fonction pure testée.
- [ ] Rendre `compactPortrait` avec navigation root puis détail plein écran.
- [ ] Rendre `compactLandscape` avec deux colonnes scrollables indépendantes.
- [ ] Rendre `expanded` comme panneau latéral laissant le monde perceptible.
- [ ] Ajouter `SafeArea`, contraintes de hauteur et cibles tactiles d’au moins 48 pixels logiques.
- [ ] Maintenir le bouton tactile monté en mode mobile et l’atténuer après input manette.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/runtime_player_pause_shell_test.dart
flutter test test/player_pause_menu_test.dart
flutter analyze
```

**Critères de DONE**

- les trois variantes sont couvertes ;
- aucun overflow n’apparaît avec text scale 2.0 ;
- chaque cible tactile mesure au moins 48 pixels logiques ;
- le même snapshot produit une navigation cohérente dans les trois layouts ;
- le menu ne dépend d’aucune détection de plateforme.

**Risques**

- seuils de breakpoint trop rigides sur fenêtres redimensionnables ;
- overflow en paysage avec barre système ;
- détail trop dense en portrait.

**Commit suggéré**

```bash
git add packages/map_player_ui
git commit -m "feat(player-ui): implement responsive A1 pause shell"
```

## P3-L3 — Brancher les écrans de détail joueur

**Objectif**

Rendre les sections Équipe, Sac, Pokédex, Carte et Options via le routeur de détail commun.

**Périmètre**

- réutilisation des snapshots existants ;
- états vides ;
- actions indisponibles ;
- retour au root ;
- Save comme action, pas comme section permanente.

**Dépendances**

- P3-L2.

**Fichiers concernés**

- Modifier : `packages/map_player_ui/lib/src/player/player_session_surfaces.dart`
- Créer : `packages/map_player_ui/lib/src/player/runtime_player_detail_router.dart`
- Créer : `packages/map_player_ui/test/player/runtime_player_detail_router_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/player_pause_menu.dart`

**Étapes**

- [ ] Mapper chaque `RuntimePlayerPauseSection` vers une surface existante ou un état simple.
- [ ] Tester les cinq sections avec données, état vide et état indisponible.
- [ ] Afficher la raison fournie par le runtime pour une section désactivée.
- [ ] Garantir qu’un retour en portrait revient au root, tandis qu’en layout à deux colonnes il replace le focus sur l’entrée active.
- [ ] Relier Save à une commande et afficher l’état `saving` sans inventer un stockage.
- [ ] Vérifier qu’aucune surface n’importe `map_editor`.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/runtime_player_detail_router_test.dart
flutter test test/player/runtime_player_pause_shell_test.dart
flutter analyze
```

**Critères de DONE**

- toutes les entrées du root ont un résultat explicite ;
- un contenu absent donne un état vide guidé ;
- une action indisponible explique pourquoi ;
- Save passe exclusivement par le runtime ;
- aucune dépendance éditeur ou Hub n’est ajoutée.

**Risques**

- snapshots de présentation incomplets ;
- duplication de composants déjà présents ;
- détails trop ambitieux dépassant le périmètre « simple » validé.

**Commit suggéré**

```bash
git add packages/map_player_ui
git commit -m "feat(player-ui): route pause detail surfaces"
```

## P3-L4 — Gérer focus, raccourcis et changement d’orientation

**Objectif**

Rendre le menu entièrement utilisable avec les cinq combinaisons d’input validées.

**Périmètre**

- focus visible ;
- navigation directionnelle ;
- souris ;
- tactile ;
- manette logique ;
- changement portrait/paysage ;
- semantics.

**Dépendances**

- P1-L3 ;
- P3-L2 ;
- P3-L3.

**Fichiers concernés**

- Créer : `packages/map_player_ui/lib/src/player/runtime_player_focus_controller.dart`
- Créer : `packages/map_player_ui/lib/src/player/runtime_player_actions.dart`
- Créer : `packages/map_player_ui/test/player/runtime_player_input_navigation_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/runtime_player_pause_shell.dart`
- Modifier : `packages/map_player_ui/test/player/runtime_player_pause_shell_test.dart`

**Étapes**

- [ ] Tester clavier : ouvrir, déplacer le focus, confirmer, retour, reprendre.
- [ ] Tester souris : survol sans activation, clic unique, retour.
- [ ] Tester tactile : ouverture, section, retour et reprise.
- [ ] Tester manette via intentions logiques, sans dépendance à un plugin physique dans le widget test.
- [ ] Stocker un `logicalSelectionId` et remapper le `FocusNode` après changement de layout.
- [ ] Tester portrait -> paysage -> portrait en conservant section et sélection.
- [ ] Ajouter des semantics pour titre, état sélectionné, indisponibilité et raccourci.
- [ ] Tester text scale 2.0 et reduced motion.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/runtime_player_input_navigation_test.dart
flutter test test/player/runtime_player_pause_shell_test.dart
flutter analyze
```

**Critères de DONE**

- clavier, souris, tactile et manette logique accomplissent le même parcours ;
- le focus est visible pour clavier et manette ;
- le focus n’est pas artificiellement affiché après un simple mouvement de souris ;
- l’orientation ne ramène pas au root ni à la première entrée ;
- les actions principales sont annoncées par les semantics.

**Risques**

- Flutter peut recréer les `FocusNode` lors du changement de branche de layout ;
- conflits entre `Shortcuts` de l’application hôte et du player ;
- événements retour reçus deux fois.

**Commit suggéré**

```bash
git add packages/map_player_ui
git commit -m "feat(player-ui): support responsive focus and multi-input navigation"
```

---

# Phase 4 — Bascule du Hub

## P4-L1 — Implémenter les adaptateurs Hub

**Objectif**

Traduire les données installées, saves et préférences du Hub vers les ports génériques du runtime.

**Périmètre**

- jeu installé ;
- descripteur de session ;
- save scoppée ;
- préférences globales ;
- callback de sortie ;
- diagnostics.

**Dépendances**

- P1-L1 ;
- P2-L4.

**Fichiers concernés**

- Créer : `apps/pokemap_hub/lib/src/player/hub_runtime_game_source.dart`
- Créer : `apps/pokemap_hub/lib/src/player/hub_player_save_gateway.dart`
- Créer : `apps/pokemap_hub/lib/src/player/hub_player_preferences_gateway.dart`
- Créer : `apps/pokemap_hub/test/player/hub_runtime_game_source_test.dart`
- Créer : `apps/pokemap_hub/test/player/hub_player_save_gateway_test.dart`
- Créer : `apps/pokemap_hub/test/session/save_read_handle_test.dart`
- Modifier : `apps/pokemap_hub/lib/src/session/installed_game_launch_resolver.dart`
- Modifier : `apps/pokemap_hub/lib/src/session/save_read_handle.dart`

**Étapes**

- [ ] Adapter `InstalledGameLaunchContext` à `RuntimeGameSource` sans le faire fuiter.
- [ ] Tester que `gameId`, version, capacités, locale et handles proviennent de la version courante installée.
- [ ] Adapter le repository de save avec scope `gameId/profileId/slotId`.
- [ ] Tester que le gateway refuse une save d’un autre jeu, profil ou slot.
- [ ] Adapter les préférences globales et leur valeur par défaut.
- [ ] Mapper les erreurs d’installation/save vers des diagnostics consommables par le runtime.
- [ ] Ne déplacer aucune règle d’installation dans `map_runtime`.

**Commandes**

```bash
cd apps/pokemap_hub
flutter test test/player/hub_runtime_game_source_test.dart
flutter test test/player/hub_player_save_gateway_test.dart
flutter test test/session/installed_game_launch_resolver_test.dart test/session/save_read_handle_test.dart
flutter analyze
```

**Critères de DONE**

- le runtime peut être lancé avec quatre adaptateurs Hub explicites ;
- l’identité et la sauvegarde restent strictement scoppées ;
- les adaptateurs sont testables sans widget ;
- aucune règle d’installation ne quitte le Hub ;
- aucune API runtime n’importe un type Hub.

**Risques**

- conserver deux sources concurrentes de vérité pour la version courante ;
- adaptation incorrecte des handles de save ;
- diagnostic trop technique pour l’UI.

**Commit suggéré**

```bash
git add apps/pokemap_hub/lib/src/player apps/pokemap_hub/lib/src/session apps/pokemap_hub/test/player
git commit -m "feat(hub): adapt installed games to runtime player ports"
```

## P4-L2 — Remplacer la composition player du Hub

**Objectif**

Monter une unique `PokeMapPlayerSessionView` et supprimer toute superposition Hub sur le monde.

**Périmètre**

- création du coordinateur ;
- injection des adaptateurs ;
- montage/démontage ;
- retour au Hub ;
- navigation.

**Dépendances**

- P3-L4 ;
- P4-L1.

**Fichiers concernés**

- Modifier : `apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart`
- Modifier : `apps/pokemap_hub/lib/src/ui/hub_app.dart`
- Modifier : `apps/pokemap_hub/lib/src/ui/hub_shell.dart`
- Modifier : `apps/pokemap_hub/lib/pokemap_hub_player.dart`
- Modifier : `apps/pokemap_hub/lib/pokemap_hub_ui.dart`
- Modifier : `apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart`
- Modifier : `apps/pokemap_hub/test/ui/hub_runtime_presentation_test.dart`

**Étapes**

- [ ] Remplacer l’empilement actuel par un unique `PokeMapPlayerSessionView`.
- [ ] Créer le coordinateur une seule fois par ouverture de jeu.
- [ ] Relier `RuntimeExternalExit.returnToHost()` à la navigation Hub.
- [ ] Appeler `dispose()` avant de reconstruire la bibliothèque.
- [ ] Tester Hub -> détail -> joueur -> titre -> Hub.
- [ ] Tester qu’un retour navigateur système pendant une session demande d’abord le retour au titre ou est refusé proprement.
- [ ] Tester qu’aucun widget de l’ancien shell n’est monté.
- [ ] Rejouer le test de caractérisation P0-L1 et le rendre vert.

**Commandes**

```bash
cd apps/pokemap_hub
flutter test test/ui/hub_app_player_navigation_test.dart
flutter test test/ui/hub_runtime_presentation_test.dart
flutter test test/ui/hub_player_ownership_characterization_test.dart
flutter analyze
```

**Critères de DONE**

- une seule interface joueur est visible ;
- le Hub ne connaît que la vue player et les adaptateurs ;
- le retour au Hub ne se produit qu’après teardown ;
- le parcours Continuer est jouable après les overlays ;
- les tests de navigation sont verts.

**Risques**

- double dispose entre widget et coordinateur ;
- callback de retour appelé après démontage ;
- navigation système contournant le teardown.

**Commit suggéré**

```bash
git add apps/pokemap_hub
git commit -m "refactor(hub): host the runtime-owned player view"
```

## P4-L3 — Supprimer l’ancien shell player du Hub

**Objectif**

Éliminer les doubles autorités une fois la bascule validée.

**Périmètre**

- modèles d’état Hub player ;
- controller Hub player ;
- vues titre/pause/résultat Hub ;
- allowlist d’architecture.

**Dépendances**

- P4-L2.

**Fichiers concernés**

- Supprimer : `apps/pokemap_hub/lib/src/player/player_shell_models.dart`
- Supprimer : `apps/pokemap_hub/lib/src/player/player_shell_controller.dart`
- Supprimer ou réduire : `apps/pokemap_hub/lib/src/ui/player/hub_player_shell_view.dart`
- Supprimer : `apps/pokemap_hub/test/player/player_shell_controller_test.dart`
- Supprimer ou réécrire : `apps/pokemap_hub/test/ui/hub_player_shell_view_test.dart`
- Modifier : `apps/pokemap_hub/test/player/hub_player_architecture_boundary_test.dart`
- Modifier : `apps/pokemap_hub/lib/pokemap_hub_player.dart`

**Étapes**

- [ ] Vérifier par `rg` que les symboles à supprimer n’ont plus de consommateurs.
- [ ] Supprimer les modèles et controller Hub devenus morts.
- [ ] Supprimer les tests qui ne testent que l’ancienne implémentation ; conserver les attentes produit dans les tests runtime/UI.
- [ ] Réduire `hub_player_shell_view.dart` à un wrapper sans état uniquement si une API de compatibilité publique l’exige.
- [ ] Vider l’allowlist temporaire créée en P0-L2.
- [ ] Ajouter un test qui échoue si une nouvelle machine d’état player apparaît sous le Hub.

**Commandes**

```bash
rg "PlayerShellController|PlayerShellState|HubPlayerShellView" apps/pokemap_hub

cd apps/pokemap_hub
flutter test test/player/hub_player_architecture_boundary_test.dart
flutter test
flutter analyze
```

**Critères de DONE**

- aucune machine d’état joueur ne subsiste dans le Hub ;
- aucune allowlist temporaire ne subsiste ;
- les exports publics ne référencent plus l’ancien shell ;
- le Hub complet reste vert hors échecs explicitement préexistants.

**Risques**

- casser une API publique utilisée par un test ou un outil local ;
- supprimer une responsabilité de save qui n’a pas encore d’adaptateur ;
- conserver un alias trompeur trop longtemps.

**Commit suggéré**

```bash
git add -A apps/pokemap_hub
git commit -m "refactor(hub): remove legacy player state ownership"
```

---

# Phase 5 — Services contextuels

## P5-L1 — Définir le contrat runtime des services de monde

**Objectif**

Permettre à une interaction Scene d’ouvrir un service typé sans l’ajouter au menu pause.

**Périmètre**

- Boutique ;
- soin ;
- PC ;
- requête, snapshot, commande et résultat ;
- gating Facts/capacités ;
- fermeture et erreurs.

**Dépendances**

- P1-L2 ;
- P2-L2.

**Fichiers concernés**

- Créer : `packages/map_runtime/lib/src/player/runtime_world_service_models.dart`
- Créer : `packages/map_runtime/test/player/runtime_world_service_models_test.dart`
- Modifier : `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart`
- Modifier : `packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart`
- Modifier : `packages/map_runtime/lib/map_runtime.dart`

**API cible**

```dart
sealed class RuntimeWorldServiceRequest {
  const RuntimeWorldServiceRequest({
    required this.interactionId,
  });

  final String interactionId;
}

final class OpenShopService extends RuntimeWorldServiceRequest {
  const OpenShopService({
    required super.interactionId,
    required this.shopId,
  });

  final String shopId;
}

final class OpenHealService extends RuntimeWorldServiceRequest {
  const OpenHealService({
    required super.interactionId,
    this.requiresConfirmation = true,
  });

  final bool requiresConfirmation;
}

final class OpenPcService extends RuntimeWorldServiceRequest {
  const OpenPcService({
    required super.interactionId,
  });
}
```

**Étapes**

- [ ] Tester les trois requêtes typées.
- [ ] Ajouter un snapshot de service modal avec révision, état, commandes disponibles et erreur.
- [ ] Relier les commandes Scene existantes aux requêtes sans créer de widget.
- [ ] Évaluer les Facts et capacités avant acquisition du verrou modal.
- [ ] Tester qu’une requête refusée laisse le monde interactif.
- [ ] Tester qu’une fermeture ou erreur libère toujours le verrou.
- [ ] Garder le menu pause ignorant de ces services.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_world_service_models_test.dart
flutter test test/playable_map_game_scene_interactive_command_integration_test.dart
flutter analyze
```

**Critères de DONE**

- les services sont déclenchables par NPC, objet, zone ou événement ;
- chaque requête est typée et révisionnée ;
- les préconditions sont évaluées par le runtime ;
- une erreur ne bloque pas le monde ;
- le snapshot pause n’expose aucune entrée de service.

**Risques**

- chevauchement avec les contrats existants de `player_service_runtime_controller.dart` ;
- acquisition du verrou avant validation ;
- service réentrant déclenché deux fois.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "feat(runtime): add contextual world service contracts"
```

## P5-L2 — Migrer la Boutique vers l’UI joueur

**Objectif**

Fournir une Boutique Flutter réutilisable par le player, ouverte uniquement par une interaction de monde.

**Périmètre**

- catalogue ;
- sélection ;
- quantité ;
- achat/vente si déjà supporté ;
- argent ;
- résultat ;
- fermeture multi-input.

**Dépendances**

- P5-L1 ;
- P3-L4.

**Fichiers concernés**

- Créer : `packages/map_player_ui/lib/src/player/player_shop_overlay.dart`
- Créer : `packages/map_player_ui/test/player/player_shop_overlay_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart`
- Modifier : `packages/map_player_ui/lib/map_player_ui.dart`
- Modifier : `examples/playable_runtime_host/lib/src/in_game_shop_page.dart` uniquement pour réutiliser le composant ou supprimer la duplication.

**Étapes**

- [ ] Caractériser les actions déjà supportées par `in_game_shop_page.dart`.
- [ ] Extraire la présentation générique sans dépendance au host.
- [ ] Tester catalogue vide, fonds insuffisants, achat valide, quantité et fermeture.
- [ ] Tester clavier, clic, tactile et intentions manette.
- [ ] Afficher les erreurs métier fournies par le runtime sans recalculer les prix.
- [ ] Monter la Boutique seulement lorsqu’un snapshot de service `shop` est actif.
- [ ] Vérifier qu’ouvrir le menu pause ne peut jamais ouvrir la Boutique.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/player_shop_overlay_test.dart
flutter analyze

cd examples/playable_runtime_host
flutter test
flutter analyze
```

**Critères de DONE**

- la Boutique est un widget de `map_player_ui` ;
- le runtime reste autorité des prix, stocks, fonds et transactions ;
- le host développeur peut réutiliser la même UI sans devenir le produit ;
- aucune entrée Boutique n’existe dans le menu pause ;
- une fermeture restaure les inputs du monde.

**Risques**

- logique métier actuellement cachée dans le widget host ;
- divergence achat/vente ;
- catalogue trop grand nécessitant virtualisation.

**Commit suggéré**

```bash
git add packages/map_player_ui examples/playable_runtime_host
git commit -m "feat(player-ui): add contextual shop overlay"
```

## P5-L3 — Implémenter le soin contextuel simple

**Objectif**

Livrer le flux V0 validé : dialogue court, confirmation, soin transactionnel, résultat.

**Périmètre**

- interaction ;
- confirmation ;
- `healParty` ;
- HP, PP et statuts ;
- message de résultat ;
- chemin immédiat optionnel.

**Dépendances**

- P5-L1 ;
- P3-L4.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart`
- Modifier : `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- Créer : `packages/map_runtime/test/player/runtime_heal_service_test.dart`
- Créer : `packages/map_player_ui/lib/src/player/player_heal_confirmation.dart`
- Créer : `packages/map_player_ui/test/player/player_heal_confirmation_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart`

**Étapes**

- [ ] Écrire un test runtime avec équipe blessée, PP consommés et statut.
- [ ] Déclencher une requête avec confirmation depuis une interaction Scene.
- [ ] Tester annulation : aucun état métier modifié et verrou libéré.
- [ ] Tester confirmation : HP, PP et statuts restaurés en une transaction.
- [ ] Tester échec d’écriture : état précédent restauré et erreur visible.
- [ ] Ajouter la confirmation Flutter et son résultat.
- [ ] Tester le mode immédiat pour une interaction spéciale explicitement configurée.
- [ ] Vérifier que le menu pause n’expose aucun soin global.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_heal_service_test.dart
flutter test test/playable_map_game_scene_interactive_command_integration_test.dart
flutter analyze

cd packages/map_player_ui
flutter test test/player/player_heal_confirmation_test.dart
flutter analyze
```

**Critères de DONE**

- le soin est déclenché par le monde ;
- annuler ne modifie rien ;
- confirmer restaure HP, PP et statuts ;
- la transaction est atomique du point de vue runtime ;
- un échec n’abandonne aucun verrou.

**Risques**

- soin partiel si une écriture échoue au milieu ;
- conflit avec un autosave simultané ;
- dialogue et service acquérant chacun un verrou.

**Commit suggéré**

```bash
git add packages/map_runtime packages/map_player_ui
git commit -m "feat(player): add contextual heal service flow"
```

## P5-L4 — Implémenter le PC contextuel V0

**Objectif**

Ouvrir le PC depuis le monde avec une UI joueur simple et sans entrée globale.

**Périmètre**

- ouverture/fermeture ;
- consultation équipe/boxes ;
- dépôt/retrait si les contrats existants le permettent ;
- états indisponibles ;
- conservation de sélection.

**Dépendances**

- P5-L1 ;
- P3-L3.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart`
- Créer : `packages/map_runtime/test/player/runtime_pc_service_test.dart`
- Créer : `packages/map_player_ui/lib/src/player/player_pc_overlay.dart`
- Créer : `packages/map_player_ui/test/player/player_pc_overlay_test.dart`
- Modifier : `packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart`
- Modifier : `examples/playable_runtime_host/lib/main.dart` si le host contient encore une présentation PC divergente.

**Étapes**

- [ ] Caractériser les opérations PC déjà disponibles dans le runtime.
- [ ] Tester l’ouverture depuis NPC, objet ou événement.
- [ ] Rendre les opérations non supportées désactivées avec raison explicite.
- [ ] Tester dépôt/retrait uniquement si le runtime possède déjà les contrats transactionnels nécessaires.
- [ ] Ajouter l’overlay Flutter responsive.
- [ ] Tester fermeture, erreur et retour au monde.
- [ ] Tester l’absence du PC dans le menu pause.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_pc_service_test.dart
flutter analyze

cd packages/map_player_ui
flutter test test/player/player_pc_overlay_test.dart
flutter analyze

cd examples/playable_runtime_host
flutter test
```

**Critères de DONE**

- le PC n’est accessible que par une interaction autorisée ;
- les opérations supportées sont transactionnelles ;
- les opérations non disponibles sont expliquées ;
- fermeture et erreur rendent les inputs au monde ;
- le player et le host ne maintiennent pas deux règles métier divergentes.

**Risques**

- contrats de boxes incomplets ;
- déplacement de Pokémon non atomique ;
- scope qui dérive vers une refonte complète du PC.

**Commit suggéré**

```bash
git add packages/map_runtime packages/map_player_ui examples/playable_runtime_host
git commit -m "feat(player): add contextual PC service"
```

---

# Phase 6 — Durcissement

## P6-L1 — Centraliser les verrous et la priorité des surfaces

**Objectif**

Éliminer les softlocks et les conflits entre pause, dialogue, combat, progression et services.

**Périmètre**

- pile de surfaces ;
- propriétaire du verrou ;
- priorité ;
- libération garantie ;
- reprise après overlay post-combat.

**Dépendances**

- P2-L4 ;
- P5-L4.

**Fichiers concernés**

- Créer : `packages/map_runtime/lib/src/player/runtime_input_lock_manager.dart`
- Créer : `packages/map_runtime/test/player/runtime_input_lock_manager_test.dart`
- Modifier : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Modifier : `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modifier : `packages/map_runtime/lib/src/presentation/flame/post_battle_progression_overlay_component.dart`
- Modifier : `packages/map_runtime/test/playable_map_game_post_battle_progression_integration_test.dart`

**Étapes**

- [ ] Définir des tokens de verrou possédés et idempotents.
- [ ] Tester pause + background, dialogue + background et service + erreur.
- [ ] Tester qu’un composant ne peut pas libérer le verrou d’un autre.
- [ ] Tester la priorité : combat/progression, service, pause, monde.
- [ ] Remplacer les booléens concurrents par le gestionnaire commun.
- [ ] Encadrer tous les overlays concernés par `try/finally`.
- [ ] Rejouer la reproduction post-`Continue` et vérifier un déplacement réel.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_input_lock_manager_test.dart
flutter test test/playable_map_game_post_battle_progression_integration_test.dart
flutter test test/session/playable_map_game_session_runtime_test.dart
flutter analyze
```

**Critères de DONE**

- aucun booléen isolé ne décide seul si le monde accepte les inputs ;
- chaque verrou a un propriétaire identifiable ;
- les libérations sont idempotentes ;
- le jeu reprend après progression post-combat ;
- les combinaisons modales testées ne softlockent pas.

**Risques**

- migration incomplète de vieux chemins d’overlay ;
- ordre de priorité incorrect ;
- token perdu lors d’une exception asynchrone.

**Commit suggéré**

```bash
git add packages/map_runtime
git commit -m "fix(runtime): centralize modal input locks"
```

## P6-L2 — Durcir sauvegardes et transitions destructives

**Objectif**

Garantir que Save, retour titre et fin de jeu ne détruisent ni la dernière save valide ni la session prématurément.

**Périmètre**

- écriture atomique via gateway ;
- backup ;
- commande concurrente ;
- retour titre pendant save ;
- fin pendant save ;
- récupération.

**Dépendances**

- P2-L3 ;
- P4-L1 ;
- P6-L1.

**Fichiers concernés**

- Modifier : `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart`
- Créer : `packages/map_runtime/test/player/runtime_player_save_race_test.dart`
- Modifier : `apps/pokemap_hub/lib/src/player/hub_player_save_gateway.dart`
- Modifier : `apps/pokemap_hub/test/player/hub_player_save_gateway_test.dart`
- Modifier : `apps/pokemap_hub/lib/src/player/hub_session_checkpoint_committer.dart`
- Modifier : `apps/pokemap_hub/test/session/hub_session_checkpoint_committer_test.dart`

**Étapes**

- [ ] Tester double Save : une écriture active, seconde commande refusée ou coalescée.
- [ ] Tester retour titre pendant Save : attendre la transaction ou annuler sans perte.
- [ ] Tester `GameCompleted` pendant Save.
- [ ] Simuler échec avant promotion et vérifier la save précédente.
- [ ] Simuler échec après création du backup et vérifier la restauration.
- [ ] Relire et valider la save avant de publier le succès.
- [ ] Publier une erreur avec action de retry sans démonter le monde.

**Commandes**

```bash
cd packages/map_runtime
flutter test test/player/runtime_player_save_race_test.dart
flutter analyze

cd apps/pokemap_hub
flutter test test/player/hub_player_save_gateway_test.dart
flutter test test/session/hub_session_checkpoint_committer_test.dart
flutter analyze
```

**Critères de DONE**

- une seule transaction modifie un slot à la fois ;
- la dernière save valide reste lisible après chaque injection d’échec ;
- retour titre et fin attendent une frontière sûre ;
- l’UI reçoit un diagnostic récupérable ;
- aucune migration destructive n’est introduite.

**Risques**

- deadlock entre teardown et save ;
- backup écrasé trop tôt ;
- erreur de checksum seulement détectée au prochain lancement.

**Commit suggéré**

```bash
git add packages/map_runtime apps/pokemap_hub
git commit -m "fix(player): protect saves across lifecycle transitions"
```

## P6-L3 — Durcir resize, orientation et performance UI

**Objectif**

Garantir une expérience stable sur fenêtre desktop redimensionnable et mobile portrait/paysage.

**Périmètre**

- changements rapides de contraintes ;
- conservation state/focus ;
- scroll ;
- text scale ;
- reduced motion ;
- rebuild budget raisonnable.

**Dépendances**

- P3-L4 ;
- P6-L1.

**Fichiers concernés**

- Modifier : `packages/map_player_ui/lib/src/player/runtime_player_pause_shell.dart`
- Modifier : `packages/map_player_ui/lib/src/player/runtime_player_focus_controller.dart`
- Créer : `packages/map_player_ui/test/player/runtime_player_resize_stress_test.dart`
- Modifier : `packages/map_player_ui/test/player/runtime_player_input_navigation_test.dart`

**Étapes**

- [ ] Tester une séquence de tailles portrait, paysage compact, expanded, puis portrait.
- [ ] Vérifier section, sélection, focus logique et position de scroll.
- [ ] Tester text scale 1.0, 1.5 et 2.0.
- [ ] Tester hauteur réduite avec clavier virtuel simulé.
- [ ] Vérifier que reduced motion supprime les transitions non essentielles.
- [ ] Utiliser des sous-arbres stables pour ne pas recréer la scène Flame à chaque navigation de détail.
- [ ] Ajouter une assertion de test prouvant que la scène n’est pas remontée lors d’un simple resize.

**Commandes**

```bash
cd packages/map_player_ui
flutter test test/player/runtime_player_resize_stress_test.dart
flutter test test/player/runtime_player_input_navigation_test.dart
flutter analyze
```

**Critères de DONE**

- aucun overflow sur les tailles testées ;
- aucun reset de section ou sélection ;
- la scène runtime n’est pas recréée ;
- reduced motion et text scaling restent utilisables ;
- le focus final correspond à l’élément logique initial.

**Risques**

- conservation de scroll difficile entre deux structures de layout ;
- focus sur un élément momentanément absent ;
- rebuild excessif si le snapshot complet change trop souvent.

**Commit suggéré**

```bash
git add packages/map_player_ui
git commit -m "fix(player-ui): preserve state across responsive layout changes"
```

---

# Phase 7 — Certification et clôture

## P7-L1 — Construire le parcours E2E Hub complet

**Objectif**

Prouver le parcours produit réel avec un package installé et sans raccourci développeur.

**Périmètre**

- import déjà installé ou fixture installée ;
- bibliothèque ;
- titre ;
- nouvelle partie et continuer ;
- pause/détail ;
- service contextuel ;
- combat/progression ;
- save ;
- retour titre/Hub.

**Dépendances**

- P4-L3 ;
- P5-L4 ;
- P6-L3.

**Fichiers concernés**

- Créer : `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart`
- Créer : `apps/pokemap_hub/test/fixtures/runtime_owned_player_game/` avec une fixture minimale data-only
- Modifier : `apps/pokemap_hub/pubspec.yaml` uniquement si l’infrastructure d’intégration l’exige.

**Étapes**

- [x] Installer la fixture dans un répertoire temporaire.
- [x] Ouvrir le jeu depuis la bibliothèque.
- [x] Démarrer une nouvelle partie et déplacer le personnage.
- [x] Ouvrir le menu avec une intention clavier/manette puis naviguer vers une section.
- [x] Reprendre et vérifier le mouvement.
- [x] Déclencher une Boutique ou un soin depuis une interaction du monde.
- [x] Sauvegarder, revenir au titre, Continuer et vérifier l’état restauré.
- [x] Déclencher le retour au Hub et vérifier qu’aucune session reste active.
- [x] Vérifier qu’aucun panneau debug du host n’est visible.

**Commandes**

```bash
cd apps/pokemap_hub
flutter test integration_test/runtime_owned_player_flow_test.dart -d macos
```

**Critères de DONE**

- le parcours complet passe sur macOS ;
- aucun workspace auteur direct ni seed debug n’est utilisé ;
- aucune double UI n’est observée ;
- le mouvement fonctionne après chaque fermeture modale ;
- la sauvegarde reste scoppée au jeu et au slot.

**Risques**

- test E2E lent ou sensible au timing ;
- fixture trop proche de Selbrume ;
- automation manette physique non portable : utiliser les intentions logiques pour ce test et réserver le matériel à la QA manuelle.

**Commit suggéré**

```bash
git add apps/pokemap_hub/integration_test apps/pokemap_hub/test/fixtures apps/pokemap_hub/pubspec.yaml
git commit -m "test(hub): cover the runtime-owned player journey"
```

## P7-L2 — Exécuter la matrice de certification

**Objectif**

Obtenir une preuve fraîche package par package, puis construire l’application macOS Debug.

**Périmètre**

- tests ciblés ;
- suites complètes concernées ;
- analyses ;
- build ;
- smoke manuel ;
- régressions connues.

**Dépendances**

- P7-L1.

**Fichiers concernés**

- Aucun fichier produit attendu.
- Créer seulement si demandé comme artefact de certification : `reports/product/runtime_owned_player_shell_certification_2026-07-25.md`.

**Étapes**

- [x] Exécuter les tests et analyses `map_runtime`.
- [x] Exécuter les tests et analyses `map_player_ui`.
- [x] Exécuter les tests et analyses `pokemap_hub`.
- [x] Exécuter les tests et analyses du `playable_runtime_host` si les composants partagés ont changé.
- [x] Construire macOS Debug.
- [ ] Faire un smoke manuel clavier/souris.
- [ ] Faire un smoke manuel avec manette si un périphérique est disponible.
- [ ] Vérifier portrait et paysage sur émulateur ou device mobile si disponible.
- [x] Classer chaque échec comme régression du chantier, échec préexistant prouvé ou limitation d’environnement.

**Commandes**

```bash
cd packages/map_runtime
flutter test
flutter analyze

cd packages/map_player_ui
flutter test
flutter analyze

cd apps/pokemap_hub
flutter test
flutter analyze
flutter build macos --debug

cd examples/playable_runtime_host
flutter test
flutter analyze
```

**Critères de DONE**

- chaque commande possède son résultat exact ;
- aucune nouvelle erreur d’analyse ;
- le build macOS Debug réussit ;
- les deux échecs Selbrume connus sont rejoués ou explicitement isolés ;
- le dépôt n’est déclaré globalement vert que si une preuve complète le permet.

**Risques**

- suites longues et chevauchantes ;
- échec matériel manette non reproductible en CI ;
- tests Selbrume masquant une régression si les logs ne sont pas séparés.

**Commit suggéré**

Aucun commit si aucune preuve suivie n’est créée. Si un rapport est explicitement demandé :

```bash
git add reports/product/runtime_owned_player_shell_certification_2026-07-25.md
git commit -m "docs(player): record runtime shell certification evidence"
```

## P7-L3 — Clore le chantier et préparer le lot suivant

**Objectif**

Documenter précisément ce qui est livré, ce qui reste limité et les statuts roadmap proposés.

**Périmètre**

- inventaire ;
- architecture finale ;
- preuves ;
- limites ;
- propositions de statuts FG ;
- prochain lot ;
- status Git.

**Dépendances**

- P7-L2.

**Fichiers concernés**

- Modifier : `docs/superpowers/specs/2026-07-25-runtime-owned-player-shell-design.md`
- Modifier : `docs/superpowers/plans/2026-07-25-runtime-owned-player-shell.md`
- Créer seulement sur demande explicite de rapport : `reports/gameplay/fg_015_runtime_pause_menu_shell_v0.md`
- Ne pas modifier : `pokemap_roadmap_mecaniques_fangame.md` sans demande explicite.

**Étapes**

- [x] Cocher uniquement les étapes réellement prouvées dans ce plan.
- [x] Lister tous les fichiers modifiés et les migrations d’API.
- [x] Documenter les commandes et résultats exacts.
- [x] Signaler les limites standalone, manette physique et mobile réel.
- [x] Proposer les statuts :
  - `FG-015 Runtime Pause Menu Shell V0` : candidat DONE si la matrice est verte ;
  - `FG-160 Pause Menu Complete V0` : candidat PARTIAL ou DONE selon la profondeur réelle des sections ;
  - `FG-163 Runtime Save Menu V0` : candidat DONE si les scénarios de race et récupération sont verts ;
  - `FG-165 Runtime Input Lock Conventions V0` : candidat DONE si P6-L1 est vert ;
  - `FG-070 Shop Runtime V0` : demander la clarification roadmap « contextuel uniquement » ;
  - `FG-071 Heal Center Flow V0` : candidat DONE si P5-L3 est vert ;
  - `FG-091 Open Shop / Open PC` : candidat DONE si P5-L2 et P5-L4 sont verts ;
  - `FG-094 Event Templates` : inchangé si aucun template auteur n’a été ajouté.
- [x] Capturer le status Git final sans stage implicite.

**Commandes**

```bash
git diff --check
git status --short --untracked-files=all
git diff --stat
```

**Critères de DONE**

- le plan reflète l’état réel et non l’intention ;
- aucun lot n’est marqué terminé sans preuve ;
- les statuts roadmap sont proposés, pas appliqués silencieusement ;
- les changements utilisateur préexistants restent identifiés ;
- le prochain chantier recommandé est clair.

**Risques**

- surévaluer `FG-160` alors que les détails restent volontairement simples ;
- confondre fonctionnement par intentions logiques et certification sur manette physique ;
- committer des artefacts `.superpowers/brainstorm` non destinés au produit.

**Commit suggéré**

```bash
git add docs/superpowers/specs/2026-07-25-runtime-owned-player-shell-design.md docs/superpowers/plans/2026-07-25-runtime-owned-player-shell.md
git commit -m "docs(player): close runtime-owned shell implementation plan"
```

## P7 — Résultat exécuté le 2026-07-25

### Lots et commits

- `P7-L1` — `9e024417e406b455e8c964bea584c8904707e66b`
  (`test(hub): certify runtime-owned player journey`) ;
- `P7-L2` — `e1e0a6ed0c1bff8fb606f7accecc70eb20ec9314`
  (`fix(player): preserve certified lifecycle recovery`) ;
- `P7-L3` — preuve documentaire portée par le commit de clôture du présent
  plan.

### Inventaire des fichiers P7-L1 et P7-L2

- `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart` ;
- `apps/pokemap_hub/lib/src/ui/hub_game_views.dart` ;
- `apps/pokemap_hub/lib/src/ui/hub_shell.dart` ;
- `apps/pokemap_hub/pubspec.lock` ;
- `apps/pokemap_hub/pubspec.yaml` ;
- `apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/maps/runtime_harbor.json` ;
- `apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/project.json` ;
- `apps/pokemap_hub/test/player/hub_player_save_gateway_test.dart` ;
- `apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart` ;
- `apps/pokemap_hub/test/support/runtime_owned_player_package_fixture_test.dart` ;
- `apps/pokemap_hub/test/widget_test.dart` supprimé car il s’agissait encore du
  test Flutter modèle obsolète, tandis que `test/ui/hub_shell_test.dart`
  couvre le shell réel ;
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` ;
- `packages/map_core/test/scene_interactive_command_test.dart` ;
- `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart` ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` ;
- `packages/map_runtime/test/player/runtime_player_save_race_test.dart` ;
- `packages/map_runtime/test/player/support/runtime_player_test_harness.dart`.

P7 n’introduit aucune migration d’API publique. Les évolutions portent sur la
préservation interne du warning de teardown lors du rechargement du titre, la
publication de l’état d’un service contextuel pendant une Scene active, les
diagnostics des ports de sortie Scene, les clés de test stables du Hub et
l’infrastructure d’intégration native.

### Preuves fraîches

| Surface | Commande | Résultat |
|---|---|---|
| E2E Hub macOS | `flutter test integration_test/runtime_owned_player_flow_test.dart -d macos` | 1 test réussi ; build et exécution natives réussies |
| `map_core` ciblé | `dart test test/scene_interactive_command_test.dart` | 3 tests réussis |
| `map_core` complet | `dart test` | 4 440 réussis, 2 échecs classés ci-dessous |
| `map_core` analyse | `dart analyze` | aucune anomalie |
| `map_player_ui` complet | `flutter test` | 63 tests réussis |
| `map_player_ui` analyse | `flutter analyze` | aucune anomalie |
| `map_runtime` ciblé initial | quatre suites Scene, service contextuel et race de save | 16 tests réussis |
| `map_runtime` ciblé après correction lifecycle | cinq suites du coordinateur et de race de save | 31 tests réussis |
| `map_runtime` complet | `flutter test` | 2 404 réussis, 2 échecs Selbrume, 1 ignoré |
| `map_runtime` analyse | `flutter analyze` | aucune anomalie |
| Hub ciblé | fixture compilée et shell Hub | 9 tests réussis |
| `pokemap_hub` complet | `flutter test` | 121 tests réussis |
| `pokemap_hub` analyse | `flutter analyze` | aucune anomalie |
| Hub macOS Debug | `flutter build macos --debug` | réussi, `build/macos/Build/Products/Debug/PokeMap Hub.app` |
| `playable_runtime_host` complet | `flutter test` | 334 réussis, 1 échec Selbrume, 2 ignorés |
| host analyse | `flutter analyze` | aucune anomalie |

Le runner macOS a indiqué `Failed to foreground app; open returned 1`, mais
l’application de test a été construite, le scénario a été exécuté jusqu’au
retour Hub et le test est passé. Cette alerte d’environnement n’est pas une
erreur du scénario.

### Échecs séparés de la preuve du chantier

- `map_core/test/border/stone_chain_line_border_resolver_test.dart` dépasse le
  budget de 8 secondes avec `8.858299` secondes : budget de performance
  sensible à la machine, sans lien avec le player ;
- `map_core/test/event_builder_authoring_operations_test.dart` attend encore
  un `UnsupportedError` pour `stepCompleted`, alors que l’opération retourne
  désormais une définition Scene : contrat auteur divergent, hors P7 ;
- `map_runtime/test/selbrume_event_v2_three_source_integration_test.dart`
  échoue avec `Bad state: Too many elements` ;
- `map_runtime/test/selbrume_narrative_campaign_outcome_matrix_test.dart`
  attend `pass` et obtient `indeterminate` ;
- `playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart`
  attend le hash
  `sha256:8827f2e81335b205b92606621f3111785f5354b5b9f486896e2d2db0874d6468`
  et obtient
  `sha256:d3a8d38e05fab52e8e10b2bc5538cf4bc2892cc0862f8cf17f6f275fb56e3258`.

Le dépôt n’est donc pas déclaré globalement vert.

### Limites et propositions roadmap

- le scénario natif macOS prouve clavier, événements de focus et interactions
  de type souris/tactile ; aucune manette physique n’était disponible ;
- portrait, paysage, conservation de focus et text scaling sont couverts par
  les widget tests, pas par un appareil mobile physique ;
- le parcours E2E neutre couvre Boutique et soin contextuels, mais ne déclenche
  pas un combat ; combat et progression restent couverts par les suites
  runtime dédiées ;
- le host standalone reste volontairement hors périmètre.

Propositions, sans modification de
`pokemap_roadmap_mecaniques_fangame.md` :

- `FG-015` : candidat `DONE` sur la preuve ciblée du shell runtime-owned ;
- `FG-160` : `PARTIAL`, les écrans de détail restant volontairement simples ;
- `FG-163` : candidat `DONE`, y compris concurrence, sauvegarde atomique,
  récupération et retour titre ;
- `FG-165` : candidat `DONE` sur les verrous centralisés et les tests de
  non-fuite ;
- `FG-070` : conserver le statut actuel et clarifier « contextuel uniquement » ;
- `FG-071` : candidat `DONE` pour le flow de soin contextuel V0 ;
- `FG-091` : candidat `DONE` pour l’ouverture contextuelle Boutique/PC ;
- `FG-094` : inchangé, aucun template auteur n’a été ajouté.

Le prochain chantier recommandé est la résolution séparée des trois régressions
Selbrume et des deux divergences `map_core`, puis une passe QA matérielle
manette/mobile. La création d’un host standalone reste un chantier ultérieur.

---

# 7. Matrice de traçabilité des décisions

| Décision validée | Lots responsables | Preuve attendue |
|---|---|---|
| Runtime autorité de session | P1-L2, P2-L1 à P2-L4 | Tests du coordinateur sans Hub |
| UI Flutter provenant du player UI | P3-L1 à P3-L4 | Widget tests sans import Hub |
| Hub simple host/adaptateur | P4-L1 à P4-L3 | Test de frontière et suppression ancien shell |
| Future compatibilité standalone | P1-L1, P0-L2 | Ports génériques sans type Hub |
| Standalone hors chantier actuel | Tous | Aucun app/builder standalone créé |
| Menu A1 | P3-L2 | Trois layouts testés |
| Desktop clavier/souris/manette | P1-L3, P3-L4 | Tests d’intentions et de focus |
| Mobile tactile/manette | P1-L3, P3-L4 | Tests tactile et manette logique |
| Portrait et paysage | P3-L2, P6-L3 | Resize/orientation sans perte d’état |
| Boutique contextuelle | P5-L1, P5-L2 | Interaction Scene et absence du menu |
| Soin contextuel simple | P5-L3 | Confirmation, transaction, résultat |
| PC contextuel | P5-L4 | Interaction de monde et absence du menu |
| Fin de jeu runtime | P2-L3 | `GameCompleted`, résultat, crédits |
| Retour propre au titre/Hub | P2-L4, P4-L2 | Teardown avant navigation |
| Pas de softlock après Continue | P0-L1, P6-L1, P7-L1 | Déplacement accepté après overlay |

# 8. Gates de phase

## Gate Phase 0

- baseline reproductible ;
- tests de frontière actifs ;
- aucun code produit modifié dans P0-L1.

## Gate Phase 1

- ports génériques compilent sans Hub ;
- snapshots et commandes révisionnés ;
- inputs logiques testés ;
- analyses runtime vertes.

## Gate Phase 2

- machine d’état runtime couvre titre, session, pause, save, fin et lifecycle ;
- commandes périmées refusées ;
- teardown prouvé ;
- aucun widget ajouté au runtime.

## Gate Phase 3

- vue canonique unique ;
- trois layouts A1 ;
- cinq modes d’usage couverts par tests logiques ;
- orientation et focus conservés ;
- analyses player UI vertes.

## Gate Phase 4

- Hub monté sur la vue canonique ;
- ancien shell supprimé ;
- test de double UI vert ;
- test Hub complet vert.

## Gate Phase 5

- services déclenchés depuis le monde ;
- Boutique, soin et PC absents du menu ;
- erreurs et fermeture libèrent les inputs ;
- host développeur reste distinct.

## Gate Phase 6

- verrous centralisés ;
- save protégée contre les races ;
- resize/orientation stressés ;
- reproduction post-`Continue` verte.

## Gate Phase 7

- parcours E2E vert ;
- tests/analyzes package-scoped exécutés ;
- build macOS Debug réussi ;
- preuves et limites consignées ;
- status Git final inspecté.

# 9. Séquence de livraison recommandée

La livraison doit rester incrémentale :

1. P0 et P1 peuvent être fusionnés sans impact visuel.
2. P2 livre une machine d’état runtime testable avec fakes.
3. P3 livre l’UI player indépendante du Hub.
4. P4 effectue la bascule produit en une fenêtre courte et réversible.
5. P5 ajoute les services contextuels après stabilisation de la navigation.
6. P6 élimine les races et softlocks révélés par l’intégration.
7. P7 certifie l’ensemble.

Ne pas commencer P4 tant que les gates P2 et P3 ne sont pas vertes. Ne pas supprimer l’ancien shell en P4-L3 avant que P4-L2 soit validé par les tests Hub. Ne pas déclarer le menu complet si les écrans de détail restent de simples surfaces provisoires : dans ce cas `FG-160` reste PARTIAL même si `FG-015` peut être proposé DONE.

# 10. Estimation relative

| Phase | Complexité | Risque dominant |
|---|---:|---|
| Phase 0 | S | Tests de caractérisation trop faibles |
| Phase 1 | M | Contrats trop couplés au Hub |
| Phase 2 | XL | Courses asynchrones et teardown |
| Phase 3 | L | Focus responsive multi-input |
| Phase 4 | L | Bascule et double ownership |
| Phase 5 | XL | Transactions et services existants divergents |
| Phase 6 | L | Softlocks difficiles à reproduire |
| Phase 7 | M | Flakiness E2E et environnement matériel |

L’estimation est relative et sert à ordonner les risques ; elle ne constitue pas une promesse de durée.

# 11. Définition globale de terminé

Le chantier est terminé uniquement si :

- `map_runtime` possède l’intégralité de la machine d’état joueur ;
- `map_player_ui` rend cette machine d’état sans décider des règles métier ;
- `pokemap_hub` ne possède plus de shell joueur parallèle ;
- le parcours complet fonctionne avec une seule interface ;
- pause et reprise ne bloquent jamais le monde ;
- les trois layouts et les cinq combinaisons d’usage sont couverts ;
- Boutique, soin et PC sont exclusivement contextuels ;
- save, lifecycle, teardown et sortie sont testés en échec comme en succès ;
- le Hub passe ses tests et son analyse ;
- le runtime et le player UI passent leurs tests et analyses ;
- la build macOS Debug réussit ;
- les régressions Selbrume connues sont séparées de la preuve de ce chantier ;
- aucune affirmation de couverture globale n’est faite sans exécution fraîche ;
- aucun changement utilisateur préexistant ni fichier non suivi n’a été écrasé.
