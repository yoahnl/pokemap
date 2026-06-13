# NS-SCENES-V1-122 — Evidence Pack

## Gate 0

Lot exécuté : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.

Nature : documentaire uniquement.

Verdict Gate 0 : PASS.

Interprétation : le prompt est cohérent avec l'état du repo. La seule tension vient de `codex_rule.md`, qui demande normalement tests et build ; le prompt V1-122 interdit explicitement les modifications packages/tests/code, donc la validation retenue est documentaire, read-only et anti-scope.

## État dirty initial

```bash
pwd
```

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

```text
main
```

```bash
git status --short --untracked-files=all
```

```text
Sortie : <vide>
```

```bash
git diff --stat
```

```text
Sortie : <vide>
```

```bash
git diff --name-only
```

```text
Sortie : <vide>
```

```bash
git log --oneline -n 10
```

```text
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
```

## Règles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Fichier absent :

```bash
sed -n '1,220p' codex_rules.md
```

```text
sed: codex_rules.md: No such file or directory
```

## Fichiers lus

Rapports récents : V1-110, V1-111, V1-112, V1-113, V1-116, V1-117, V1-118, V1-119, V1-120, V1-121 et Evidence Pack V1-121.

Rapports camera/timeline/backdrop : V1-45, V1-51, V1-71, V1-82, V1-83, V1-84, V1-95 et V1-95-bis.

Roadmaps : `reports/narrativeStudio/scenes/road_map_scenes.md`, `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

Code read-only : les fichiers `map_core` et `map_editor` listés dans le prompt, plus les tests ciblés.

## Commandes d'audit exécutées

```bash
wc -l reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_82_cinematic_map_backdrop_preview_prep_contract.md reports/narrativeStudio/scenes/ns_scenes_v1_83_cinematic_map_backdrop_preview_read_model_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.md
```

```text
     606 reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
     405 reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
     388 reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
     557 reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
     401 reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
     673 reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md
     414 reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md
     704 reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md
     695 reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md
     299 reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md
     400 reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md
    2488 reports/narrativeStudio/scenes/road_map_scenes.md
    1999 reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
     739 reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
     366 reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
     810 reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md
     848 reports/narrativeStudio/scenes/ns_scenes_v1_82_cinematic_map_backdrop_preview_prep_contract.md
     393 reports/narrativeStudio/scenes/ns_scenes_v1_83_cinematic_map_backdrop_preview_read_model_v0.md
     231 reports/narrativeStudio/scenes/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.md
     436 reports/narrativeStudio/scenes/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md
     211 reports/narrativeStudio/scenes/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.md
   14063 total
```

## Recherches rg utiles

```bash
rg -n "CinematicCameraPlaybackPose|supportsCamera|cinematicPreviewPlaybackCameraUnsupported|cameraPose =|CameraPlayback|camera remains an unsupported placeholder" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

```text
packages/map_core/test/cinematic_preview_playback_plan_test.dart:314:        'fade returns fade state and camera remains an unsupported placeholder',
packages/map_core/test/cinematic_preview_playback_plan_test.dart:349:      expect(plan.capabilities.supportsCamera, isFalse);
packages/map_core/test/cinematic_preview_playback_plan_test.dart:355:              .cinematicPreviewPlaybackCameraUnsupported,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:28:  cinematicPreviewPlaybackCameraUnsupported,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:107:    required this.supportsCamera,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:116:  final bool supportsCamera;
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:379:final class CinematicCameraPlaybackPose {
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:380:  const CinematicCameraPlaybackPose({
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:421:  final CinematicCameraPlaybackPose? cameraPose;
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:622:                .cinematicPreviewPlaybackCameraUnsupported,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:684:      supportsCamera: false,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:707:  CinematicCameraPlaybackPose? cameraPose;
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:757:          cameraPose = CinematicCameraPlaybackPose(
```

```bash
rg -n "CinematicTimelineCameraMode|cinematicTimelineCameraModeMetadataKey|cinematicTimelineDefaultCameraDurationMs|CinematicTimelineBasicBlockKind.camera|camera.mode|Hold|Reset" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
```

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:154:enum CinematicTimelineCameraMode {
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:183:const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:192:const cinematicTimelineDefaultCameraDurationMs = 500;
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:2322:    CinematicTimelineBasicBlockKind.camera => CinematicTimelineStep(
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:2333:          cinematicTimelineCameraModeMetadataKey: cameraMode.name,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:10434:        if (blockKind == CinematicTimelineBasicBlockKind.camera) ...[
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:10742:            for (final mode in CinematicTimelineCameraMode.values)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:10746:                  key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12124:    CinematicTimelineCameraMode.reset => 'Reset',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12125:    CinematicTimelineCameraMode.hold => 'Hold',
packages/map_editor/test/cinematic_builder_workspace_test.dart:10398:    expect(cameraStep.metadata, containsPair('camera.mode', 'hold'));
packages/map_editor/test/cinematic_builder_workspace_test.dart:10400:    expect(find.text('Hold'), findsWidgets);
```

```bash
rg -n "Carte entière|Vue scène|CinematicBackdropPreviewFramingState|panTiles|zoom|map-backdrop-zoom|map-backdrop-reset-view|CinematicMapBackdropViewportTransform" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
```

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart:29:final class CinematicMapBackdropViewportTransform {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:14:final class CinematicBackdropPreviewFramingState {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:17:    this.zoom = 1,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:18:    this.panTiles = Offset.zero,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:25:  static const zoomStep = 0.25;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:28:  final double zoom;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart:29:  final Offset panTiles;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1155:              label: 'Carte entière',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1171:              label: 'Vue scène',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1212:          key: const ValueKey('cinematic-builder-map-backdrop-zoom-out'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1229:          key: const ValueKey('cinematic-builder-map-backdrop-zoom-reset'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1244:          key: const ValueKey('cinematic-builder-map-backdrop-reset-view'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1252:          key: const ValueKey('cinematic-builder-map-backdrop-zoom-in'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart:1269:          key: const ValueKey('cinematic-builder-map-backdrop-zoom-label'),
```

## Extraits de code lus

`CinematicCameraPlaybackPose` actuel :

```dart
final class CinematicCameraPlaybackPose {
  const CinematicCameraPlaybackPose({
    required this.supported,
    this.activeStepId,
  });

  final bool supported;
  final String? activeStepId;
}
```

Traitement plan :

```dart
case CinematicTimelineStepKind.camera:
  itemDiagnostics.add(
    CinematicPreviewPlaybackDiagnostic(
      code: CinematicPreviewPlaybackDiagnosticCode
          .cinematicPreviewPlaybackCameraUnsupported,
      severity: CinematicPreviewPlaybackDiagnosticSeverity.info,
      message: 'La caméra de ce bloc sera cadrée dans un lot suivant.',
      stepId: step.id,
    ),
  );
  hasUnsupportedSteps = true;
```

Frame caméra actuelle :

```dart
case CinematicTimelineStepKind.camera:
  if (item.containsTime(clampedTimeMs)) {
    cameraPose = CinematicCameraPlaybackPose(
      supported: false,
      activeStepId: item.stepId,
    );
  }
```

Test existant :

```dart
expect(cameraFrame.cameraPose, isNotNull);
expect(cameraFrame.cameraPose!.supported, isFalse);
expect(plan.capabilities.supportsCamera, isFalse);
expect(plan.capabilities.hasUnsupportedSteps, isTrue);
```

## Options comparées

- Option A : refusée, mélange viewport d'édition et caméra.
- Option B : acceptable comme fallback, pas comme trajectoire complète.
- Option C : cible d'architecture retenue, caméra virtuelle editor-only séparée.
- Option D : refusée, runtime/Flame/GameState hors scope.
- Option E : fallback seulement, trop faible comme prochaine trajectoire.
- Option F : retenue, read model puis renderer.

## Décision retenue

Le modèle actuel ne suffit pas. V1-123 doit être :

```text
NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
```

V1-124 recommandé ensuite :

```text
NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
```

## Justification du prochain lot

Preuves :

- `cameraPose` ne porte que `supported` et `activeStepId`.
- `supportsCamera` vaut `false`.
- le diagnostic core dit que la caméra sera cadrée dans un lot suivant.
- le bloc Camera V0 ne porte que `reset` / `hold` + durée.
- les tests existants verrouillent la caméra comme placeholder unsupported.
- le viewport backdrop possède déjà un pan/zoom editor local à ne pas détourner.

## Fichiers modifiés

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Zones modifiées :

- `road_map_scenes.md` : ajout de la ligne DONE V1-122, bascule du header `Prochain lot exact recommande` vers V1-123, ajout de `Mise a jour V1-122`, et alignement des mentions de prochain lot global actuel vers V1-123.
- `road_map_scene_builder_authoring.md` : bascule du header vers V1-123, ajout de la ligne roadmap V1-122, ajout de `Mise a jour V1-122`, et alignement des mentions de prochain lot global actuel vers V1-123.

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_122_cinematic_camera_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_122_evidence_pack.md`

Note récursive : aucun code produit n'a été créé. Le contenu complet des fichiers créés est leur contenu documentaire dans ces deux fichiers ; aucune annexe de code généré n'existe pour ce lot.

## Sub-agents / passes nommées

- Sub-agent Audit / Architecture : PASS. Le repo prouve que la caméra est placeholder unsupported.
- Sub-agent Implémentation : PASS documentaire. Seuls rapports et roadmaps autorisés sont modifiés/créés.
- Sub-agent Tests : PASS avec exception documentée. Aucun test lancé ni créé, conformément au lot doc-only.
- Sub-agent Build / Validation : PASS via `git diff --check` et anti-scope.
- Sub-agent Critique finale : PASS avec risques restants listés dans le rapport principal.

## git diff --check

```bash
git diff --check
```

```text
Sortie : <vide>
```

## git diff --stat

```bash
git diff --stat
```

```text
 .../scenes/road_map_scene_builder_authoring.md     | 43 ++++++++++++-------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 48 ++++++++++++++--------
 2 files changed, 60 insertions(+), 31 deletions(-)
```

Note : les deux rapports V1-122 sont non suivis, donc ils apparaissent dans `git status --short --untracked-files=all`, pas dans `git diff --stat`.

## git diff --name-only

```bash
git diff --name-only
```

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## git status final

```bash
git status --short --untracked-files=all
```

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_122_cinematic_camera_preview_playback_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_122_evidence_pack.md
```

## Checks anti-scope

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_122*' -print
```

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_123*' -print
```

```text
Sortie : <vide>
```

## Confirmations

- Aucun package Dart/Flutter modifié.
- Aucun screenshot créé.
- Aucun runtime ajouté.
- Aucun Flame importé.
- Aucun GameState touché.
- V1-123 non démarré.

## Limites honnêtes

- Ce lot ne prouve pas une caméra visuelle ; il prouve seulement le contrat et la nécessité d'un read model.
- La sémantique finale de `reset` / `hold` devra être fixée par V1-123.
- La Visual Gate future appartient à V1-124 si le split est conservé.

## Verdict

`NS-SCENES-V1-122 : DONE documentaire.`

Prochain lot recommandé : `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0`.
