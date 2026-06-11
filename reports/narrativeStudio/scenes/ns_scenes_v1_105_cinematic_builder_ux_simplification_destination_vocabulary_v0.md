# NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0

## Résumé exécutif

Lot V1-105 terminé. A la demande de Karim, le Cinematic Builder et la Cinematics Library ont été nettoyés côté vocabulaire visible pour parler en termes no-code : `Repère`, `Destination`, `Position libre`, `Personnage ou objet de la map`, `Déclencheur de map`, `Marqueur temps`, `Aucun problème`.

Le lot anciennement prévu comme `Cinematic Manual Path Authoring Prep Contract` est volontairement repoussé à V1-106. Aucun modèle core, runtime, gameplay, playback ou Manual Path n'a été démarré.

## Confirmation du scope

Inclus :

- simplification des libellés visibles dans le Builder ;
- simplification des libellés visibles dans la Library ;
- tests de vocabulaire positif et négatif ;
- régénération d'une Visual Gate V1-105 ;
- mise à jour des roadmaps pour décaler Manual Path ;
- petite hygiène locale de warnings fatals détectés par l'analyse ciblée.

Exclus :

- pas de changement `map_core` ;
- pas de changement runtime/Flame/gameplay/battle ;
- pas de sérialisation JSON nouvelle ;
- pas de pathfinding, playback ou interpolation ;
- pas de Manual Path authoring.

## Audit initial

Etat git initial :

```text
pwd -> /Users/karim/Project/pokemonProject
branch -> main
git status --short --untracked-files=all -> <vide>
git diff --stat -> <vide>
git diff --name-only -> <vide>
```

Fichiers concernés identifiés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Contrats préservés :

- `stagePoint`, `targetId`, `actorId`, `movementTarget` restent des identifiants internes ;
- le lot modifie le vocabulaire utilisateur, pas les contrats de données ;
- les helpers de preview restent editor-only ;
- les anciens contrôles runtime/playback restent hors scope.

Rapports précédents relus par contexte de roadmap :

- V1-102 à V1-104-bis ferment Stage Points, initial placement et actorMove target ;
- V1-105 devait devenir un lot UX avant Manual Path selon le prompt fourni.

Risques principaux :

- renommer par erreur des IDs internes au lieu des libellés visibles ;
- laisser survivre des anciens termes visibles (`Point de scène`, `Point abstrait`, `Cibles de déplacement`) ;
- casser les tests timeline qui attendaient `Repère :` pour le probe temporel ;
- marquer Manual Path comme commencé alors que le lot est uniquement UX.

## Verdict des passes / sub-agents

- Sub-agent Audit / Architecture : scope valide, changement UX seulement, Manual Path doit glisser à V1-106.
- Sub-agent Implémentation : vocabulaire visible aligné, identifiants internes conservés.
- Sub-agent Tests : tests Builder/Library/overlay verts après mise à jour des attentes.
- Sub-agent Build / Validation : analyse ciblée en sortie 0 avec infos non fatales ; build complet non lancé car changement widget/editor testé par suites ciblées.
- Sub-agent Critique finale : pas de diff runtime/gameplay/battle/examples/Xcode ; anciens libellés visibles absents du scan ; limite restante = infos analyzer historiques `prefer_const` / `withOpacity`.

## Fichiers modifiés

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Zones modifiées :

- labels timeline : `Repère :` devient `Marqueur :` ;
- palette/stage points : `Points de scène` devient `Repères de scène`, `Ajouter un point` devient `Ajouter un repère` dans l'expérience visible ;
- destinations : `Point abstrait`, `Entité de map`, `Event de map` deviennent `Position libre`, `Personnage ou objet de la map`, `Déclencheur de map` ;
- diagnostics : `Aucun diagnostic` devient `Aucun problème` / `Aucun problème prioritaire` ;
- test helpers invisibles et helpers morts nettoyés pour supprimer les warnings fatals de l'analyse ciblée.

Diffs/zones précises :

```text
6190: 'Personnage ou objet de la map'
6679: 'Aucun repère de scène disponible. Créez d’abord un repère...'
8498: label: 'Position libre'
8539: label: 'Personnage ou objet de la map'
8556: label: 'Déclencheur de map'
9066: 'Aucun problème prioritaire'
10484: final baseLabel = 'Marqueur : ${_shortTimeLabel(timeMs)}';
11208: 'Repères de scène'
11225: 'Aucun repère de scène.\\nClique sur « Ajouter un repère »...'
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`

Zones modifiées :

- `Diagnostics` -> `Problèmes` ;
- `Aucun diagnostic` -> `Aucun problème` ;
- résumé timeline : `Read-only V0` -> `Déroulé`, `Steps` -> `Actions`, `step(s)` -> `action(s)`, `Actors utilisés` -> `Acteurs utilisés`.

Extrait diff :

```diff
- title: 'Diagnostics',
+ title: 'Problèmes',
- ? 'Aucun diagnostic'
+ ? 'Aucun problème'
- subtitle: 'Read-only V0',
+ subtitle: 'Déroulé',
- _KeyValue(label: 'Steps', value: '${timeline.stepCount} step(s)'),
+ _KeyValue(label: 'Actions', value: '${timeline.stepCount} action(s)'),
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`

Zones modifiées :

- suppression d'un import `dart:math` inutilisé ;
- suppression d'un import design system inutilisé ;
- suppression d'un `print('DEBUG DRAG: onPanCancel')` de debug.

Raison : l'analyse ciblée du lot échouait sur warnings fatals liés à ce fichier inclus dans la validation.

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`

Zones modifiées :

- suppression de helpers privés morts `_statusLabel` et `_statusBadgeVariant` ;
- suppression du paramètre `key` jamais fourni sur `_EmptyStagePointsHelperOverlay`.

Raison : l'analyse ciblée du lot incluait ce fichier et échouait sur warnings fatals.

### `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Tests ajoutés/modifiés :

- nouveau test `uses simplified no-code destination vocabulary in builder` ;
- Visual Gate V1-105 ;
- attentes timeline `Repère :` remplacées par `Marqueur :` ;
- garde-fous négatifs sur anciens termes visibles : `Ajouter un point`, `Point abstrait`, `Point de scène`, `Cibles de déplacement`, `Vue simple`, IDs techniques visibles.

Extrait de test :

```dart
expect(find.text('Ajouter un repère'), findsWidgets);
expect(find.text('Destination'), findsWidgets);
expect(find.text('Repère de scène'), findsWidgets);
expect(find.text('Position libre'), findsWidgets);
expect(find.textContaining('Personnage ou objet de la map'), findsWidgets);
expect(find.textContaining('Déclencheur de map'), findsWidgets);
expect(find.text('Timeline cinématique'), findsOneWidget);
expect(find.textContaining('Cibles de déplacement'), findsNothing);
```

### `packages/map_editor/test/cinematics_library_workspace_test.dart`

Zones modifiées :

- attentes `2 step(s)` / `3 step(s)` remplacées par `2 action(s)` / `3 action(s)` ;
- les vieux états `sandbox uniquement` et `contexte incomplet` ne sont plus attendus comme libellés visibles.

### `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`

Zones modifiées :

- suppression d'une variable locale inutilisée `updateCalled`.

### Roadmaps

Fichiers :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Décision :

- V1-105 devient `Cinematic Builder UX Simplification / Destination Vocabulary V0` et passe DONE ;
- l'ancien Manual Path Prep devient V1-106 ;
- Manual Path Core devient V1-107 ;
- Manual Path Drawing UI devient V1-108 ;
- Preview Playback Prep devient V1-109.

## Fichiers créés

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md`

Le PNG est un fichier binaire ; son contenu complet n'est pas recopié dans le rapport, mais son type, sa dimension et son SHA-256 sont fournis dans l'Evidence Pack.

## Commandes et résultats

### Tests

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
Résultat exact final : 00:35 +204: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
Résultat exact final : 00:08 +26: All tests passed!
```

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_105_CAPTURE_CINEMATIC_BUILDER_UX_SIMPLIFICATION=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-105 cinematic builder ux simplification destination vocabulary visual gate when requested'
Résultat exact final : 00:03 +1: All tests passed!
```

### Analyse

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
Résultat : sortie 0. 48 infos non fatales restantes, principalement prefer_const_constructors, deprecated_member_use withOpacity et unnecessary_import.
Ligne finale exacte : 48 issues found. (ran in 1.6s)
```

### Visual Gate

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
-rw-r--r--  1 karim  staff   159K Jun 11 21:48 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
5835676297cb96e8084f8f8c16bec56cb8c47ea25dbf2c010fedde77bc184336  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```

### Anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
Sortie : <vide>
```

```text
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
Sortie : <vide>
```

```text
rg -n "Ajouter un point|Point abstrait|Point de scène|Cibles de déplacement|Aucun diagnostic|Effacer le repère|Aide repère|Repère :" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
Sortie : <vide>
```

### Build

Build complet non lancé. Justification : le lot est limité à `map_editor` widgets/tests et à des libellés UX ; la validation alternative retenue est la suite widget complète ciblée du Builder (`+204`), la suite Library + overlay (`+26`), l'analyse ciblée en sortie 0 et la Visual Gate. Aucun package runtime/core/battle/gameplay n'a été touché.

## Etat git final

```text
git diff --check
Sortie : <vide>
```

```text
git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    | 470 ++++++++++---------
 .../cinematic_map_backdrop_preview_panel.dart      | 122 ++---
 .../cinematic_stage_point_preview_overlay.dart     |  20 +-
 .../cinematics/cinematics_library_workspace.dart   |  50 +-
 .../test/cinematic_builder_workspace_test.dart     | 508 ++++++++++++++++-----
 ...cinematic_stage_point_preview_overlay_test.dart |  31 +-
 .../test/cinematics_library_workspace_test.dart    |  12 +-
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  26 +-
 9 files changed, 798 insertions(+), 458 deletions(-)
```

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_105_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png
```

## Limites conservées

- Les IDs internes `targetId`, `actorId`, `stagePointId` restent dans le code et les modèles.
- Les libellés visibles sont simplifiés, mais le moteur ne consomme aucun nouveau comportement.
- Aucun chemin manuel n'est authorable dans ce lot.
- Les infos analyzer non fatales historiques ne sont pas toutes nettoyées.

## Auto-critique finale

Points positifs :

- le vocabulaire visible est cohérent ;
- les tests couvrent les anciens termes à ne plus afficher ;
- le scan anti-scope confirme l'absence de modifications runtime/gameplay/battle/examples/Xcode ;
- les roadmaps ne laissent plus V1-105 pointer vers Manual Path.

Risques restants :

- quelques chaînes techniques peuvent encore exister dans des IDs internes ou fixtures, volontairement non renommés ;
- le PNG Visual Gate prouve la composition, pas une validation pixel-perfect automatisée exhaustive ;
- le build macOS/desktop complet n'a pas été relancé.

## Prochaines étapes proposées

1. Lancer `NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract`.
2. Garder la règle vocabulaire : tout nouveau concept spatial visible doit avoir un terme auteur no-code avant d'exposer son identifiant interne.
