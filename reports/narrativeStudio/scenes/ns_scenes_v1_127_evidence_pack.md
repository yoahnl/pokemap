# NS-SCENES-V1-127 — Evidence Pack

## Verdict

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

## Gate 0

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

État dirty initial : aucun fichier dirty ; `selbrume/project.json` n’était pas dirty.

## Règles lues

- `AGENTS.md` : fourni dans le contexte.
- `agent_rules.md` : lu.
- `codex_rule.md` : lu.
- `codex_rules.md` : absent.
- `skills/README.md` : lu.
- `skills/using-superpowers/SKILL.md` : lu.
- `skills/test-driven-development/SKILL.md` : lu.
- `skills/verification-before-completion/SKILL.md` : lu.
- `skills/writing-plans/SKILL.md` : lu.

Conflit traité : `codex_rule.md` demande beaucoup de commentaires, mais le prompt V1-127 demande d’éviter les commentaires décoratifs. La règle spécifique du lot a été suivie : pas de nouveau commentaire Dart décoratif ; l’explication est dans les rapports.

## Fichiers lus

Rapports/roadmaps :

- `reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Core/tests/editor read-only :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/cinematic_emote_catalog.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_emote_catalog_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`

## Fichiers modifiés

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_127_cinematic_emote_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_127_evidence_pack.md`

Ces deux fichiers sont des artefacts de rapport ; leur contenu complet est présent dans les fichiers eux-mêmes.

## Code généré — modèle public

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

## Code généré — frame et évaluation

```dart
final List<CinematicActorEmotePlaybackState> activeEmotes;
```

```dart
List<CinematicActorEmotePlaybackState> activeEmotes = const [],
```

```dart
case CinematicTimelineStepKind.actorEmote:
  final plan = _buildActorEmotePlan(
    step: step,
    actorTracks: actorTracks,
    actorTrackIds: actorTrackIds,
    diagnostics: itemDiagnostics,
  );
  emotePlans[step.id] = plan;
  if (!plan.isSupported) {
    supported = false;
    hasUnsupportedSteps = true;
  }
  break;
```

```dart
case CinematicTimelineStepKind.actorEmote:
  if (item.containsTime(clampedTimeMs)) {
    activeEmotes.add(
      _emotePlaybackStateFor(
        item: item,
        plan: plan._actorEmotePlans[item.stepId],
        clampedTimeMs: clampedTimeMs,
      ),
    );
  }
  break;
```

```dart
CinematicActorEmotePlaybackState _emotePlaybackStateFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required _ActorEmotePlaybackPlan? plan,
  required int clampedTimeMs,
}) {
  final elapsedMs =
      (clampedTimeMs - item.startMs).clamp(0, item.visualDurationMs).toInt();
  return CinematicActorEmotePlaybackState(
    activeStepId: item.stepId,
    stepIndex: item.stepIndex,
    actorId: plan?.actorId ?? item.actorId,
    actorLabel: plan?.actorLabel ?? item.actorLabel,
    emoteId: plan?.emoteId,
    emoteLabel: plan?.emoteLabel,
    durationMs: item.visualDurationMs,
    elapsedMs: elapsedMs,
    progress: _timelineItemProgress(item, clampedTimeMs),
    isSupported: plan?.isSupported == true && item.supported,
    diagnostics: item.diagnostics,
  );
}
```

## Tests RED exacts

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Résultat :

```text
Exit code: 1
Member not found: 'cinematicPreviewPlaybackEmoteUnknown'
Member not found: 'cinematicPreviewPlaybackEmoteMissing'
Member not found: 'cinematicPreviewPlaybackEmoteActorUnknown'
Member not found: 'cinematicPreviewPlaybackEmoteActorMissing'
The getter 'activeEmotes' isn't defined for the type 'CinematicPreviewPlaybackFrame'
```

## Tests GREEN exacts

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie :

```text
00:00 +20: All tests passed!
```

## Tests map_core ciblés

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +20: All tests passed!

dart test --reporter=compact test/cinematic_emote_catalog_test.dart
00:01 +3: All tests passed!

dart test --reporter=compact test/cinematic_authoring_operations_test.dart
00:01 +71: All tests passed!

dart test --reporter=compact test/cinematic_diagnostics_test.dart
00:00 +55: All tests passed!

dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +4: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!
```

## Suite complète map_core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact > /tmp/ns_scenes_v1_127_map_core_full_test.log && tr '\r' '\n' < /tmp/ns_scenes_v1_127_map_core_full_test.log | sed '/^$/d' | tail -n 1
```

Sortie :

```text
00:04 +2513: All tests passed!
```

## Analyse statique

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

## Régressions map_editor ciblées

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Sortie :

```text
00:05 +7: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

Sortie :

```text
00:04 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie :

```text
00:06 +26: All tests passed!
```

## Build

Build non lancé.

Justification : aucun fichier editor/runtime n’a été modifié ; le lot est `map_core` pur. Les validations lancées sont `dart analyze`, tests `map_core` ciblés, suite complète `map_core`, et régressions Flutter editor ciblées demandées.

## Anti-scope

Commande globale :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\.Image|rootBundle|decodeImage|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-128" || true
```

Sortie : non vide uniquement pour les mentions documentaires `V1-128` dans les roadmaps.

Commande code/scopes produit :

```bash
git diff --unified=0 -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\.Image|rootBundle|decodeImage|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-128" || true
```

Sortie :

```text
<vide>
```

Commandes :

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

Confirmations :

- aucun `packages/map_editor` modifié ;
- aucun `packages/map_runtime` modifié ;
- aucun `packages/map_gameplay` modifié ;
- aucun `packages/map_battle` modifié ;
- aucun `examples/playable_runtime_host` modifié ;
- aucun asset modifié ;
- aucun asset racine déplacé ou copié ;
- aucun `pubspec.yaml` modifié ;
- aucun `selbrume` modifié ;
- aucun screenshot V1-127/V1-128 créé ;
- V1-128 recommandé, non démarré.

## Git final

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematic_preview_playback_plan.dart           | 228 +++++++++++++++++++-
 .../test/cinematic_preview_playback_plan_test.dart | 239 +++++++++++++++++++--
 .../scenes/road_map_scene_builder_authoring.md     |  54 +++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  58 +++--
 4 files changed, 510 insertions(+), 69 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les deux rapports V1-127 apparaissent dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_127_cinematic_emote_playback_state_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_127_evidence_pack.md
```

## Roadmaps

`reports/narrativeStudio/scenes/road_map_scenes.md` :

- V1-127 DONE ;
- V1-128 recommandé.

`reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` :

- V1-127 DONE ;
- V1-128 recommandé.

## Passes / sub-agents équivalents

- Passe A — Audit initial : PASS. Le plan existant peut recevoir `activeEmotes` sans runtime.
- Passe B — Design read model : PASS. État emote pur, sans position dupliquée.
- Passe C — Tests RED : PASS. Les tests échouent sur `activeEmotes` et diagnostics manquants.
- Passe D — Implémentation : PASS. `frameAt` expose les emotes actives.
- Passe E — Tests GREEN : PASS. Tests ciblés et suite `map_core` passent.
- Passe F — Analyse / anti-scope : PASS. `dart analyze` propre, code anti-scope vide.
- Passe G — Rapport / Evidence Pack / Roadmaps : PASS. Rapports créés et roadmaps alignées.
- Passe H — Auto-critique finale : PASS avec limites documentées.

## Risques et limites

- Le time layout actuel est linéaire ; les overlaps réels sont un sujet futur.
- Le futur renderer devra arbitrer le rendu si deux emotes existent sur le même acteur.
- Les assets restent candidats, non chargés.
- V1-128 doit rester authoring UI ; le rendu visuel appartient plutôt à V1-129.
