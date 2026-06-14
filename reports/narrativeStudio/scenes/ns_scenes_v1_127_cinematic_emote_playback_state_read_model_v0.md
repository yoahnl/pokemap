# NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0

Statut : `NS-SCENES-V1-127 : DONE`.

## 1. Résumé exécutif

V1-127 expose les emotes actives du bloc `actorEmote` dans le read model pur de playback `CinematicPreviewPlaybackFrame`.

Le nouveau champ `activeEmotes` est produit par `frameAt(timeMs)` et contient un état immutable `CinematicActorEmotePlaybackState` avec :

- `activeStepId` ;
- `stepIndex` ;
- `actorId` / `actorLabel` ;
- `emoteId` / `emoteLabel` ;
- `durationMs` / `elapsedMs` ;
- `progress` clampé ;
- `isSupported` / `supported` ;
- `diagnostics`.

Aucune UI, aucun renderer, aucun overlay, aucun asset loading, aucun runtime, aucun Flame et aucun GameState n’a été ajouté.

## 2. Gate 0

Commande :

```bash
cd /Users/karim/Project/pokemonProject && pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
```

État initial : working tree propre, aucune sortie `git status`, `git diff --stat` ou `git diff --name-only`.

## 3. Fichiers lus

Règles lues :

- `AGENTS.md` fourni dans le contexte ;
- `agent_rules.md` ;
- `codex_rule.md` ;
- `skills/README.md` ;
- `skills/using-superpowers/SKILL.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- `skills/writing-plans/SKILL.md`.

Fichier absent :

- `codex_rules.md` : absent (`wc: codex_rules.md: open: No such file or directory`).

Rapports et roadmaps lus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md` ;
- `reports/narrativeStudio/scenes/road_map_scenes.md` ;
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

Fichiers core/editor lus en lecture seule ou inspectés :

- `packages/map_core/lib/src/models/cinematic_asset.dart` ;
- `packages/map_core/lib/src/models/cinematic_emote_catalog.dart` ;
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` ;
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart` ;
- `packages/map_core/lib/map_core.dart` ;
- tests core demandés ;
- fichiers editor demandés en lecture seule, sans modification.

## 4. Rappel V1-126

V1-126 avait posé :

- le catalogue emote V0 pur ;
- les helpers `actorEmote` ;
- le stockage `actorId` sur `CinematicTimelineStep.actorId` ;
- le stockage `emoteId` dans metadata `actor.emoteId` ;
- les opérations add/update ;
- les diagnostics actor/emote/durée ;
- une frontière explicite : le playback state actif était reporté à V1-127.

## 5. Audit playback plan existant

Verdict : le plan actuel permet d’ajouter `activeEmotes` sans toucher au runtime.

Constats :

- `CinematicPreviewPlaybackFrame` exposait déjà `actorPoses`, `fadeState`, `cameraPose`, `activeStepIds` et `visibleDiagnostics`.
- `frameAt(timeMs)` passe par `evaluateCinematicPreviewPlaybackFrame`, clamp le temps et parcourt les `timelineItems`.
- `CinematicPreviewPlaybackTimelineItem.containsTime` suit la convention `startMs <= timeMs && timeMs < endMs`, donc end exclusive.
- `actorPoses` reste calculé à partir des tracks et plans `actorMove`.
- `fadeState` et `cameraPose` sont des états read-model indépendants.
- `actorEmote` existait comme kind, mais n’était pas encore transformé en état actif.
- `buildCinematicTimelineTimeLayoutReadModel` est linéaire : chaque step reçoit `currentMs -> endMs`, sans modèle parallèle actuel.

## 6. Décision d’architecture

Choix retenu : ajouter le modèle emote dans `cinematic_preview_playback_plan.dart`, à côté des états actor/fade/camera existants.

Raisons :

- le read model de playback est déjà la source de vérité de `frameAt(timeMs)` ;
- aucun fichier dédié n’était nécessaire pour ce V0 ;
- le champ `activeEmotes` peut rester vide par défaut pour préserver les callers existants ;
- le futur renderer combinera `frame.actorPoses` et `frame.activeEmotes`, sans recalculer la timeline côté UI.

## 7. Modèle playback emote

Code généré principal :

```dart
@immutable
final class CinematicActorEmotePlaybackState {
  CinematicActorEmotePlaybackState({
    required this.activeStepId,
    required this.stepIndex,
    required this.actorId,
    this.actorLabel,
    required this.emoteId,
    this.emoteLabel,
    required this.durationMs,
    required this.elapsedMs,
    required this.progress,
    required this.isSupported,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  final String activeStepId;
  final int stepIndex;
  final String? actorId;
  final String? actorLabel;
  final String? emoteId;
  final String? emoteLabel;
  final int durationMs;
  final int elapsedMs;
  final double progress;
  final bool isSupported;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  bool get supported => isSupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorEmotePlaybackState &&
          other.activeStepId == activeStepId &&
          other.stepIndex == stepIndex &&
          other.actorId == actorId &&
          other.actorLabel == actorLabel &&
          other.emoteId == emoteId &&
          other.emoteLabel == emoteLabel &&
          other.durationMs == durationMs &&
          other.elapsedMs == elapsedMs &&
          other.progress == progress &&
          other.isSupported == isSupported &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        activeStepId,
        stepIndex,
        actorId,
        actorLabel,
        emoteId,
        emoteLabel,
        durationMs,
        elapsedMs,
        progress,
        isSupported,
        Object.hashAll(diagnostics),
      );
}
```

## 8. Exposition dans CinematicPreviewPlaybackFrame

`CinematicPreviewPlaybackFrame` expose maintenant :

```dart
List<CinematicActorEmotePlaybackState> activeEmotes = const [],
```

Le champ est copié en liste immutable et intégré à l’égalité/hash. La valeur par défaut vide évite de forcer les tests/callers editor existants à changer.

## 9. Sémantique temporelle

Convention existante conservée :

- début inclus ;
- fin exclusive ;
- progress = `(time - startMs) / visualDurationMs`, clampé `0.0..1.0` ;
- temps négatif et temps après durée totale passent par le clamp global de `frameAt`.

Preuve testée :

- `frameAt(0)` expose l’emote avec `progress == 0` ;
- `frameAt(400)` expose environ `0.5` pour 800 ms ;
- `frameAt(799)` expose environ `0.998` ;
- `frameAt(800)` n’expose plus l’emote.

## 10. Support / unsupported

Un `actorEmote` devient unsupported si :

- acteur absent ;
- acteur inconnu ;
- emote absente ;
- emote inconnue ;
- durée non valide, via le diagnostic de durée/fallback existant.

L’état actif reste présent même unsupported, pour permettre à la future UI de contextualiser le problème.

## 11. Plusieurs emotes simultanées

Décision V0 : `activeEmotes` est une liste et `frameAt` ajoute chaque `actorEmote` actif dans l’ordre déterministe des `timelineItems`.

Limite honnête : le time layout actuel est linéaire, donc les données actuelles ne produisent pas encore de vrais overlaps. Si un futur modèle temporel autorise des fenêtres superposées, `activeEmotes` pourra retourner plusieurs états sans changer la forme de la frame.

## 12. Relation actorPoses

`activeEmotes` ne duplique pas la position acteur.

Le futur renderer devra combiner :

- `frame.actorPoses` pour la position/direction ;
- `frame.activeEmotes` pour l’emote active et ses diagnostics.

Le test V1-127 vérifie que `actorPoseById('actor_lysa')` reste disponible pendant un `actorEmote`.

## 13. Relation fadeState / cameraPose

Le test mixte V1-127 vérifie :

- emote active puis fade actif ;
- emote active puis camera active ;
- `fadeState` et `cameraPose` restent disponibles dans leurs fenêtres respectives ;
- `activeEmotes` redevient vide hors fenêtre emote.

## 14. Diagnostics

Nouveaux codes read-model :

```dart
cinematicPreviewPlaybackEmoteActorMissing,
cinematicPreviewPlaybackEmoteActorUnknown,
cinematicPreviewPlaybackEmoteMissing,
cinematicPreviewPlaybackEmoteUnknown,
```

Messages no-code :

- `Impossible de prévisualiser cette émotion : acteur manquant.`
- `Impossible de prévisualiser cette émotion : acteur introuvable.`
- `Impossible de prévisualiser cette émotion : choix manquant.`
- `Impossible de prévisualiser cette émotion : choix indisponible.`

Aucun message visible ne mentionne `metadata`, `JSON`, `frameIndex`, `sourceRect` ou `actor.emoteId`.

## 15. Non-objectifs confirmés

Non démarrés :

- V1-128 ;
- UI emote ;
- palette/inspecteur emote ;
- renderer/overlay emote ;
- chargement image ;
- asset registry runtime ;
- runtime/Flame/GameState ;
- `map_editor` ;
- assets racine ;
- pubspec ;
- screenshot / Visual Gate.

## 16. Hygiène de diff

Fichiers modifiés :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart` : ajout du read model emote pur et de son évaluation dans `frameAt`.
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart` : tests V1-127 RED/GREEN, diagnostics et non-régressions fade/camera/actorPose.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-127 DONE, V1-128 recommandé.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-127 DONE, V1-128 recommandé.

Fichiers créés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_127_cinematic_emote_playback_state_read_model_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_127_evidence_pack.md`.

Aucun reformat global n’a été fait. Seul `dart format` ciblé a été lancé sur les fichiers Dart modifiés.

## 17. Tests RED

Commande RED initiale :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Résultat RED : exit code 1. Échecs attendus :

```text
Member not found: 'cinematicPreviewPlaybackEmoteUnknown'
Member not found: 'cinematicPreviewPlaybackEmoteMissing'
Member not found: 'cinematicPreviewPlaybackEmoteActorUnknown'
Member not found: 'cinematicPreviewPlaybackEmoteActorMissing'
The getter 'activeEmotes' isn't defined for the type 'CinematicPreviewPlaybackFrame'
```

## 18. Tests GREEN

Commande ciblée finale :

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
00:00 +20: All tests passed!
```

## 19. Tests exécutés

Depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
dart test --reporter=compact test/cinematic_emote_catalog_test.dart
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
dart test --reporter=compact test/cinematic_diagnostics_test.dart
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
dart test --reporter=compact
```

Résultats :

```text
cinematic_preview_playback_plan_test.dart : 00:00 +20: All tests passed!
cinematic_emote_catalog_test.dart : 00:01 +3: All tests passed!
cinematic_authoring_operations_test.dart : 00:01 +71: All tests passed!
cinematic_diagnostics_test.dart : 00:00 +55: All tests passed!
cinematic_timeline_time_layout_read_model_test.dart : 00:00 +4: All tests passed!
cinematic_actor_display_preview_model_test.dart : 00:00 +27: All tests passed!
suite complète map_core : 00:04 +2513: All tests passed!
```

Depuis `packages/map_editor` :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Résultats :

```text
V1-124 : 00:05 +7: All tests passed!
V1-121 : 00:04 +5: All tests passed!
library/stage overlay : 00:06 +26: All tests passed!
```

## 20. Analyse statique

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 21. Build

Build non lancé.

Justification : le lot modifie uniquement `map_core` pur et des rapports. Le prompt indiquait que le build n’était pas obligatoire si aucun fichier editor n’était modifié. La validation alternative lancée couvre `dart analyze`, la suite complète `map_core` et les régressions Flutter editor ciblées.

## 22. Checks anti-scope

Commande globale :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\.Image|rootBundle|decodeImage|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-128" || true
```

Résultat : sortie non vide uniquement à cause des mentions documentaires `V1-128` dans les roadmaps, exigées par le prompt.

Commande code/scopes produit :

```bash
git diff --unified=0 -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\.Image|rootBundle|decodeImage|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-128" || true
```

Sortie :

```text
<vide>
```

Autres checks :

```bash
git diff --name-only -- packages/map_editor
git diff --name-only -- assets emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_127*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_128*' -print
```

Sortie :

```text
<vide>
```

## 23. Roadmaps mises à jour

- `road_map_scenes.md` : V1-127 DONE, prochain lot recommandé V1-128.
- `road_map_scene_builder_authoring.md` : V1-127 DONE, prochain lot recommandé V1-128.

Prochain lot recommandé :

```text
NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
```

## 24. Git final

Les checks finaux complets sont reproduits dans l’Evidence Pack. État attendu : uniquement les deux fichiers `map_core`, les deux roadmaps et les deux rapports V1-127.

## 25. Risques restants

- La simultanéité réelle reste limitée par le time layout linéaire.
- Le futur renderer devra décider comment arbitrer plusieurs emotes sur le même acteur si un modèle temporel parallèle apparaît.
- Les assets restent candidats et non intégrés à un chemin officiel.
- Les labels no-code du catalogue pourront être polis visuellement plus tard.

## 26. Auto-critique

- Le read model est assez riche pour V1-128 : l’UI pourra lire acteur, emote, progress et diagnostics sans recalculer.
- L’absence de position dans l’état emote est volontairement saine : `actorPoses` reste la source de vérité.
- Les diagnostics sont contextualisés au step et à l’acteur, mais pas encore au futur composant visuel.
- Le tri déterministe repose sur l’ordre des `timelineItems`; il est suffisant tant que le layout reste linéaire.
- V1-128 doit être UI authoring, pas renderer preview : le bloc doit d’abord devenir éditable proprement.
- Un bis n’est pas recommandé pour V1-127 ; les limites restantes appartiennent au modèle temporel futur ou à V1-128/V1-129.

## 27. Verdict final

```text
NS-SCENES-V1-127 : DONE.
Emote Playback State Read Model : implémenté.
frameAt(timeMs) : expose activeEmotes.
activeStepId / actorId / emoteId / progress / supported / diagnostics : présents.
actorPoses : intact.
fadeState : intact.
cameraPose : intact.
UI / renderer : non démarrés.
Runtime / Flame / GameState : non touchés.
map_editor : non modifié.
Assets racine : non déplacés, non copiés.
pubspec : non modifié.
Screenshot / Visual Gate : absents.
V1-128 : recommandé, non démarré.
```

## 28. Prochain lot recommandé

```text
NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
```

