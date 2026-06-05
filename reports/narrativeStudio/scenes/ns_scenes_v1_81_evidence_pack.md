# NS-SCENES-V1-81 — Evidence Pack

## Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
```

## Fichiers lus

```text
AGENTS.md
agent_rules.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_80_cinematic_character_library_picker_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_80_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_79_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## Recherches obligatoires

```text
rg -n "actorAppearanceBindings|CinematicActorAppearanceBinding|actorAppearanceBinding|characterAssetMissing|cinematicOnlyCharacterMissing|characterLibraryUnavailable" packages/map_core packages/map_editor
Résultat : occurrences existantes V1-79/V1-80 localisées dans core diagnostics, authoring operations, Builder, readiness et tests.

rg -n "Apparence|Personnage|Character Library|Aucun personnage|personnage absent|personnage choisi|Retirer" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/test
Résultat : libellés V1-80 trouvés dans Builder/tests, utilisés comme base des nouveaux messages V1-81.

rg -n "CinematicStagePreviewReadiness|Preparation preview|Apparences acteurs|readiness" packages/map_editor/lib/src/ui/canvas/cinematics
Résultat : readiness centralisée dans cinematic_stage_preview_readiness.dart et consommée par Builder/Library.

rg -n "PokeMapButton|PokeMapBadge|PokeMapCard|PokeMapStatusTile|PokeMapPanel" packages/map_editor/lib/src/ui
Résultat : primitives design-system disponibles ; V1-81 réutilise PokeMapButton et les widgets locaux existants basés sur tokens.
```

## TDD — sortie RED

Test ajouté avant implémentation :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows incompatible character appearance drift when actor is no longer cinematic only'
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Cet acteur n’est plus en “Cinématique
uniquement”.": []>
00:03 +0 -1: Some tests failed.
```

## Sorties GREEN

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +14: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +9: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
00:00 +47: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
00:00 +34: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows incompatible character appearance drift when actor is no longer cinematic only'
00:02 +1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:18 +138: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:04 +14: All tests passed!

cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_81_CAPTURE_CINEMATIC_ACTOR_APPEARANCE_DRIFT=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:17 +138: All tests passed!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 6 items...
No issues found! (ran in 2.1s)
```

## Analyse globale editor

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
344 issues found. (ran in 3.2s)
```

Premières erreurs hors lot :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
```

Preuve :

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
-rw-r--r--  1 karim  staff  243866 Jun  5 18:01 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
e958dfd44a0ed345df1ee356d0d1c08c0d7d0a505684dcc17652038cd048da11  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
```

## Checks anti-scope

```text
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<vide>

rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|playCinematic|runtimePreview|previewRuntime|startPlayback|stopPlayback|PlaybackController|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>

rg -n "class CinematicActorBinding[\s\S]*characterId|CinematicActorBinding\([^\)]*characterId|characterId.*CinematicActorBinding|requiredActors.*characterId" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_core/lib/src/models packages/map_core/test || true
<vide>

rg -n "TextField\([^\)]*(characterId|rawId|id)|json|JSON|raw id|free[ -]*(id|identifier)|characterId.*TextField" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart || true
<vide>

rg -n "createCharacter|updateCharacter|deleteCharacter|upsertCharacterAnimation|setPlayerCharacter|CharacterLibraryPanel" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>

rg -n "stageContext.*mapId|CinematicStageContext\([^\)]*mapId|mapId.*stageContext" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
packages/map_editor/test/cinematic_builder_workspace_test.dart:82:    final project = _project(cinematics: [_stageContextCinematic(mapId: null)]);
packages/map_editor/test/cinematic_builder_workspace_test.dart:116:    expect(updated.stageContext?.toJson(), isNot(contains('mapId')));
packages/map_editor/test/cinematic_builder_workspace_test.dart:293:    expect(updated.stageContext?.toJson(), isNot(contains('mapId')));
packages/map_editor/test/cinematic_builder_workspace_test.dart:1291:      cinematics: [_stageContextCinematic(mapId: null)],
packages/map_editor/test/cinematic_builder_workspace_test.dart:1661:    expect(find.text('stageContext.mapId'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:8597:  return _stageContextCinematic(mapId: 'missing_map');

git diff -U0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(stageContext.*mapId|CinematicStageContext\([^\)]*mapId|mapId.*stageContext)" || true
<vide>

rg -n "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart || true
<vide>

rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>

rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
<vide>
```

## Code généré / hunks complets

Commande :

```bash
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index 4fc96ba8..45fec904 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -4000,0 +4001,4 @@ class _StageActorBindingsSection extends StatelessWidget {
+    final orphanAppearanceBindings = _orphanActorAppearanceBindings(
+      asset,
+      stageContext,
+    );
@@ -4026,0 +4031,46 @@ class _StageActorBindingsSection extends StatelessWidget {
+        if (orphanAppearanceBindings.isNotEmpty) ...[
+          const SizedBox(height: 4),
+          for (final binding in orphanAppearanceBindings) ...[
+            _StageOrphanAppearanceBindingNotice(
+              binding: binding,
+              onClear: () => onRemoveActorAppearanceBinding(binding.actorId),
+            ),
+            const SizedBox(height: 8),
+          ],
+        ],
+      ],
+    );
+  }
+}
+
+class _StageOrphanAppearanceBindingNotice extends StatelessWidget {
+  const _StageOrphanAppearanceBindingNotice({
+    required this.binding,
+    required this.onClear,
+  });
+
+  final CinematicActorAppearanceBinding binding;
+  final Future<void> Function() onClear;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      key: ValueKey(
+        'cinematic-builder-character-appearance-${binding.actorId}-orphan',
+      ),
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const _KeyValue(
+          label: 'Apparence',
+          value: 'Référence orpheline',
+        ),
+        const SizedBox(height: 4),
+        const _MutedText('Une apparence référence un acteur supprimé.'),
+        _MutedText('Acteur référencé : ${binding.actorId}'),
+        _MutedText('Personnage référencé : ${binding.characterId}'),
+        const SizedBox(height: 6),
+        _StageAppearanceClearButton(
+          actorId: binding.actorId,
+          label: 'Nettoyer la référence',
+          onClear: onClear,
+        ),
@@ -4259,2 +4309,12 @@ class _StageActorAppearanceSection extends StatelessWidget {
-          _MutedText(_appearanceDisabledMessage(selectedKind)),
-          if (appearanceBinding != null) ...[
+          if (appearanceBinding == null)
+            _MutedText(_appearanceDisabledMessage(selectedKind))
+          else ...[
+            const _MutedText(
+              'Cet acteur n’est plus en “Cinématique uniquement”.',
+            ),
+            const _MutedText(
+              'L’apparence Character Library ne s’applique plus.',
+            ),
+            _MutedText(
+              'Personnage référencé : ${appearanceBinding!.characterId}',
+            ),
@@ -4261,0 +4322,2 @@ class _StageActorAppearanceSection extends StatelessWidget {
+            const _MutedText('Action : Retirer l’apparence'),
+            const SizedBox(height: 4),
@@ -4264 +4326 @@ class _StageActorAppearanceSection extends StatelessWidget {
-              label: 'Retirer la référence',
+              label: 'Retirer l’apparence',
@@ -4271 +4333,3 @@ class _StageActorAppearanceSection extends StatelessWidget {
-            'Aucun personnage disponible dans la Character Library. '
+            'La Character Library est vide.',
+          ),
+          const _MutedText(
@@ -4273,0 +4338,8 @@ class _StageActorAppearanceSection extends StatelessWidget {
+          if (appearanceBinding != null) ...[
+            const SizedBox(height: 6),
+            _StageAppearanceClearButton(
+              actorId: actor.actorId,
+              label: 'Retirer la référence',
+              onClear: onClear,
+            ),
+          ],
@@ -4309,0 +4382,3 @@ class _StageActorAppearanceSection extends StatelessWidget {
+            for (final warning
+                in _characterAppearanceWarnings(selectedCharacter))
+              _MutedText(warning),
@@ -7002,0 +7078,18 @@ CinematicActorAppearanceBinding? _actorAppearanceBindingFor(
+List<CinematicActorAppearanceBinding> _orphanActorAppearanceBindings(
+  CinematicAsset asset,
+  CinematicStageContext context,
+) {
+  return context.actorAppearanceBindings.where((binding) {
+    return !_hasRequiredActor(asset, binding.actorId);
+  }).toList(growable: false);
+}
+
+bool _hasRequiredActor(CinematicAsset asset, String actorId) {
+  for (final actor in asset.requiredActors) {
+    if (actor.actorId == actorId) {
+      return true;
+    }
+  }
+  return false;
+}
+
@@ -7061,0 +7155,28 @@ String? _characterTagsLine(ProjectCharacterEntry character) {
+List<String> _characterAppearanceWarnings(ProjectCharacterEntry character) {
+  final warnings = <String>[];
+  if (character.tilesetId.trim().isEmpty) {
+    warnings.add('Ce personnage n’a pas encore de tileset utilisable.');
+  }
+  if (character.frameWidth <= 0 || character.frameHeight <= 0) {
+    warnings.add(
+      'Ce personnage n’a pas encore de dimensions exploitables pour la future preview.',
+    );
+  }
+  if (!_hasIdleAnimation(character)) {
+    warnings.add(
+      'Ce personnage n’a pas encore d’animation idle pour la future preview.',
+    );
+  }
+  return warnings;
+}
+
+bool _hasIdleAnimation(ProjectCharacterEntry character) {
+  for (final animation in character.animations) {
+    if (animation.state == CharacterAnimationState.idle &&
+        animation.frames.isNotEmpty) {
+      return true;
+    }
+  }
+  return false;
+}
+
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
index 738862a4..56d715dc 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
@@ -80,0 +81,5 @@ CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
+  final actorAppearances = _actorAppearancesItem(
+    asset,
+    effectiveContext,
+    characters,
+  );
@@ -85 +90 @@ CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
-    _actorAppearancesItem(asset, effectiveContext, characters),
+    actorAppearances,
@@ -116 +121,4 @@ CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
-      libraryStatusLabel: 'à corriger avant preview',
+      libraryStatusLabel: actorAppearances.kind ==
+              CinematicStagePreviewReadinessItemKind.blocking
+          ? 'apparence à corriger'
+          : 'à corriger avant preview',
@@ -127 +135,4 @@ CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
-      libraryStatusLabel: 'contexte incomplet',
+      libraryStatusLabel: actorAppearances.kind ==
+              CinematicStagePreviewReadinessItemKind.incomplete
+          ? 'apparence à compléter'
+          : 'contexte incomplet',
@@ -149,0 +161,18 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
+  for (final appearance in context.actorAppearanceBindings) {
+    final actor = _requiredActorFor(asset, appearance.actorId);
+    if (actor == null) {
+      return _item(
+        'Apparences acteurs',
+        CinematicStagePreviewReadinessItemKind.blocking,
+        'Une apparence référence un acteur supprimé.',
+      );
+    }
+    final binding = _actorBindingFor(context, appearance.actorId);
+    if (binding?.kind != CinematicActorBindingKind.cinematicOnly) {
+      return _item(
+        'Apparences acteurs',
+        CinematicStagePreviewReadinessItemKind.blocking,
+        '${_actorDisplayLabel(actor)} n’est plus en Cinématique uniquement.',
+      );
+    }
+  }
@@ -172 +201 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-      'Character Library vide pour les acteurs cinématique uniquement',
+      'La Character Library est vide.',
@@ -181 +210 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-        '${_actorDisplayLabel(actor)} n’a pas encore de personnage',
+        '${_actorDisplayLabel(actor)} n’a pas encore de personnage.',
@@ -189 +218 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-        '${_actorDisplayLabel(actor)} pointe vers un personnage absent',
+        '${_actorDisplayLabel(actor)} pointe vers un personnage absent.',
@@ -196 +225 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-        '${character.name} n’a pas encore de sprite Character Library',
+        '${character.name} utilise un personnage sans sprite preview.',
@@ -199,3 +228 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-    if (character.frameWidth <= 0 ||
-        character.frameHeight <= 0 ||
-        character.animations.isEmpty) {
+    if (character.frameWidth <= 0 || character.frameHeight <= 0) {
@@ -205 +232,8 @@ CinematicStagePreviewReadinessItem _actorAppearancesItem(
-        '${character.name} a des données de preview à compléter',
+        '${character.name} a des dimensions de preview à compléter.',
+      );
+    }
+    if (!_hasIdleAnimation(character)) {
+      return _item(
+        'Apparences acteurs',
+        CinematicStagePreviewReadinessItemKind.incomplete,
+        '${character.name} n’a pas encore d’animation idle pour la future preview.',
@@ -504 +538 @@ String _itemStatusLabel(CinematicStagePreviewReadinessItemKind kind) {
-    CinematicStagePreviewReadinessItemKind.blocking => 'Bloquant',
+    CinematicStagePreviewReadinessItemKind.blocking => 'À corriger',
@@ -532,0 +567,9 @@ CinematicActorBinding? _actorBindingFor(
+CinematicActorRef? _requiredActorFor(CinematicAsset asset, String actorId) {
+  for (final actor in asset.requiredActors) {
+    if (actor.actorId == actorId) {
+      return actor;
+    }
+  }
+  return null;
+}
+
@@ -544,0 +588,10 @@ CinematicActorAppearanceBinding? _actorAppearanceBindingFor(
+bool _hasIdleAnimation(ProjectCharacterEntry character) {
+  for (final animation in character.animations) {
+    if (animation.state == CharacterAnimationState.idle &&
+        animation.frames.isNotEmpty) {
+      return true;
+    }
+  }
+  return false;
+}
+
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index 51b96300..cbe981f9 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -1151,0 +1152,7 @@ const _stageDiagnosticCodes = <String>{
+  'actorAppearanceBindingUnknownActor',
+  'actorAppearanceBindingUnknownCharacter',
+  'actorAppearanceBindingRequiresCinematicOnly',
+  'cinematicOnlyCharacterMissing',
+  'characterLibraryUnavailable',
+  'characterAssetMissingSprite',
+  'characterAssetMissingPreviewData',
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index 2303697b..9fb2227a 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -589,0 +590 @@ void main() {
+    expect(find.text('La Character Library est vide.'), findsOneWidget);
@@ -592 +592,0 @@ void main() {
-        'Aucun personnage disponible dans la Character Library. '
@@ -681,0 +682,204 @@ void main() {
+  testWidgets(
+      'shows incompatible character appearance drift when actor is no longer cinematic only',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(
+      characters: const [
+        ProjectCharacterEntry(
+          id: 'character_rival',
+          name: 'Rival',
+          tilesetId: 'characters/rival',
+          frameWidth: 32,
+          frameHeight: 32,
+        ),
+      ],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_incompatible_character_appearance',
+          title: 'Incompatible character appearance',
+          mapId: 'map_lab',
+          requiredActors: [
+            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
+          ],
+          stageContext: CinematicStageContext(
+            actorBindings: [
+              CinematicActorBinding(
+                actorId: 'actor_rival',
+                kind: CinematicActorBindingKind.player,
+              ),
+            ],
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_rival',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(
+            steps: [
+              CinematicTimelineStep(
+                id: 'step_wait',
+                kind: CinematicTimelineStepKind.wait,
+                label: 'Opening wait',
+                durationMs: 500,
+              ),
+            ],
+          ),
+        ),
+      ],
+      includeBridge: false,
+    );
+    var latestProject = project;
+    final beforeActorBindings = _asset(
+      project,
+      'cinematic_incompatible_character_appearance',
+    ).stageContext?.actorBindings.map((binding) => binding.toJson()).toList();
+    final beforeTimeline = _asset(
+      project,
+      'cinematic_incompatible_character_appearance',
+    ).timeline.toJson();
+    final beforeDuration = _entry(
+      project,
+      'cinematic_incompatible_character_appearance',
+    ).timeline.estimatedDurationMs;
+
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_incompatible_character_appearance',
+      onProjectChanged: (project) => latestProject = project,
+    );
+
+    expect(
+      find.text('Cet acteur n’est plus en “Cinématique uniquement”.'),
+      findsOneWidget,
+    );
+    expect(
+      find.text('L’apparence Character Library ne s’applique plus.'),
+      findsOneWidget,
+    );
+    expect(find.text('Retirer l’apparence'), findsOneWidget);
+    expect(
+      find.byKey(
+        const ValueKey(
+            'cinematic-builder-character-appearance-actor_rival-toggle'),
+      ),
+      findsNothing,
+    );
+
+    for (final key in <String>[
+      'cinematic-builder-transport-reset-button',
+      'cinematic-builder-transport-play-button',
+      'cinematic-builder-transport-stop-button',
+    ]) {
+      final button = tester.widget<PokeMapButton>(
+        find.byKey(ValueKey<String>(key)),
+      );
+      expect(button.onPressed, isNull);
+    }
+
+    final clearButton = find.byKey(
+      const ValueKey(
+        'cinematic-builder-character-appearance-actor_rival-clear',
+      ),
+    );
+    await tester.ensureVisible(clearButton);
+    await tester.tap(clearButton);
+    await tester.pumpAndSettle();
+
+    final updatedAsset = _asset(
+      latestProject,
+      'cinematic_incompatible_character_appearance',
+    );
+    expect(updatedAsset.stageContext?.actorAppearanceBindings, isEmpty);
+    expect(
+      updatedAsset.stageContext?.actorBindings
+          .map((binding) => binding.toJson())
+          .toList(),
+      beforeActorBindings,
+    );
+    expect(updatedAsset.timeline.toJson(), beforeTimeline);
+    expect(
+      _entry(latestProject, 'cinematic_incompatible_character_appearance')
+          .timeline
+          .estimatedDurationMs,
+      beforeDuration,
+    );
+  });
+
+  testWidgets('shows orphan actor appearance binding and cleans it explicitly',
+      (tester) async {
+    _setLargeSurface(tester);
+    final project = _project(
+      characters: const [
+        ProjectCharacterEntry(
+          id: 'character_rival',
+          name: 'Rival',
+          tilesetId: 'characters/rival',
+        ),
+      ],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_orphan_character_appearance',
+          title: 'Orphan character appearance',
+          mapId: 'map_lab',
+          stageContext: CinematicStageContext(
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_deleted',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(
+            steps: [
+              CinematicTimelineStep(
+                id: 'step_wait',
+                kind: CinematicTimelineStepKind.wait,
+                label: 'Opening wait',
+                durationMs: 500,
+              ),
+            ],
+          ),
+        ),
+      ],
+      includeBridge: false,
+    );
+    var latestProject = project;
+    final beforeTimeline =
+        _asset(project, 'cinematic_orphan_character_appearance')
+            .timeline
+            .toJson();
+
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_orphan_character_appearance',
+      onProjectChanged: (project) => latestProject = project,
+    );
+
+    expect(
+      find.text('Une apparence référence un acteur supprimé.'),
+      findsWidgets,
+    );
+    expect(find.text('Acteur référencé : actor_deleted'), findsOneWidget);
+    expect(find.text('Personnage référencé : character_rival'), findsOneWidget);
+    expect(find.text('Nettoyer la référence'), findsOneWidget);
+
+    final clearButton = find.byKey(
+      const ValueKey(
+        'cinematic-builder-character-appearance-actor_deleted-clear',
+      ),
+    );
+    await tester.ensureVisible(clearButton);
+    await tester.tap(clearButton);
+    await tester.pumpAndSettle();
+
+    final updatedAsset = _asset(
+      latestProject,
+      'cinematic_orphan_character_appearance',
+    );
+    expect(updatedAsset.stageContext?.actorAppearanceBindings, isEmpty);
+    expect(updatedAsset.timeline.toJson(), beforeTimeline);
+  });
+
@@ -818 +1022 @@ void main() {
-      'Rival actor n’a pas encore de personnage',
+      'Rival actor n’a pas encore de personnage.',
@@ -853,0 +1058,168 @@ void main() {
+    expect(
+      appearanceItem(brokenProject, 'cinematic_unknown_character').message,
+      'Rival actor pointe vers un personnage absent.',
+    );
+
+    final incompatibleProject = _project(
+      characters: const [readyCharacter],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_incompatible_character',
+          title: 'Incompatible character',
+          mapId: 'map_lab',
+          requiredActors: [
+            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
+          ],
+          stageContext: CinematicStageContext(
+            actorBindings: [
+              CinematicActorBinding(
+                actorId: 'actor_rival',
+                kind: CinematicActorBindingKind.player,
+              ),
+            ],
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_rival',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(),
+        ),
+      ],
+      includeBridge: false,
+    );
+    expect(
+      appearanceItem(incompatibleProject, 'cinematic_incompatible_character')
+          .kind,
+      CinematicStagePreviewReadinessItemKind.blocking,
+    );
+    expect(
+      appearanceItem(incompatibleProject, 'cinematic_incompatible_character')
+          .message,
+      'Rival actor n’est plus en Cinématique uniquement.',
+    );
+
+    final orphanProject = _project(
+      characters: const [readyCharacter],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_orphan_character',
+          title: 'Orphan character',
+          mapId: 'map_lab',
+          stageContext: CinematicStageContext(
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_deleted',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(),
+        ),
+      ],
+      includeBridge: false,
+    );
+    expect(
+      appearanceItem(orphanProject, 'cinematic_orphan_character').kind,
+      CinematicStagePreviewReadinessItemKind.blocking,
+    );
+    expect(
+      appearanceItem(orphanProject, 'cinematic_orphan_character').message,
+      'Une apparence référence un acteur supprimé.',
+    );
+
+    const missingSpriteCharacter = ProjectCharacterEntry(
+      id: 'character_rival',
+      name: 'Rival',
+      tilesetId: '',
+      frameWidth: 32,
+      frameHeight: 32,
+      animations: [
+        CharacterAnimation(
+          state: CharacterAnimationState.idle,
+          direction: EntityFacing.south,
+          frames: [
+            CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
+          ],
+        ),
+      ],
+    );
+    final missingSpriteProject = _project(
+      characters: const [missingSpriteCharacter],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_missing_sprite_character',
+          title: 'Missing sprite character',
+          mapId: 'map_lab',
+          requiredActors: [
+            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
+          ],
+          stageContext: CinematicStageContext(
+            actorBindings: [
+              CinematicActorBinding(
+                actorId: 'actor_rival',
+                kind: CinematicActorBindingKind.cinematicOnly,
+              ),
+            ],
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_rival',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(),
+        ),
+      ],
+      includeBridge: false,
+    );
+    expect(
+      appearanceItem(missingSpriteProject, 'cinematic_missing_sprite_character')
+          .message,
+      'Rival utilise un personnage sans sprite preview.',
+    );
+
+    const missingPreviewDataCharacter = ProjectCharacterEntry(
+      id: 'character_rival',
+      name: 'Rival',
+      tilesetId: 'characters/rival',
+      frameWidth: 32,
+      frameHeight: 32,
+    );
+    final missingPreviewDataProject = _project(
+      characters: const [missingPreviewDataCharacter],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_missing_preview_character',
+          title: 'Missing preview character',
+          mapId: 'map_lab',
+          requiredActors: [
+            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
+          ],
+          stageContext: CinematicStageContext(
+            actorBindings: [
+              CinematicActorBinding(
+                actorId: 'actor_rival',
+                kind: CinematicActorBindingKind.cinematicOnly,
+              ),
+            ],
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_rival',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(),
+        ),
+      ],
+      includeBridge: false,
+    );
+    expect(
+      appearanceItem(
+        missingPreviewDataProject,
+        'cinematic_missing_preview_character',
+      ).message,
+      'Rival n’a pas encore d’animation idle pour la future preview.',
+    );
@@ -6939,0 +7312,120 @@ void main() {
+
+  testWidgets(
+      'captures V1-81 cinematic actor appearance drift diagnostics polish when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_81_CAPTURE_CINEMATIC_ACTOR_APPEARANCE_DRIFT',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    await _loadScreenshotFonts();
+    final project = _project(
+      characters: const [
+        ProjectCharacterEntry(
+          id: 'character_rival',
+          name: 'Rival',
+          tilesetId: 'characters/rival',
+          frameWidth: 32,
+          frameHeight: 32,
+        ),
+      ],
+      cinematics: [
+        CinematicAsset(
+          id: 'cinematic_character_drift_capture',
+          title: 'Character drift capture',
+          mapId: 'map_lab',
+          requiredActors: [
+            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
+          ],
+          stageContext: CinematicStageContext(
+            actorBindings: [
+              CinematicActorBinding(
+                actorId: 'actor_rival',
+                kind: CinematicActorBindingKind.player,
+              ),
+            ],
+            actorAppearanceBindings: [
+              CinematicActorAppearanceBinding(
+                actorId: 'actor_rival',
+                characterId: 'character_rival',
+              ),
+            ],
+          ),
+          timeline: CinematicTimeline(
+            steps: [
+              CinematicTimelineStep(
+                id: 'step_wait',
+                kind: CinematicTimelineStepKind.wait,
+                label: 'Entrée rival',
+                durationMs: 500,
+              ),
+            ],
+          ),
+        ),
+      ],
+      includeBridge: false,
+    );
+
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_character_drift_capture',
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-stage-actors-section')),
+    );
+    await tester.pumpAndSettle();
+    await tester.drag(
+      find.byKey(const ValueKey('cinematic-builder-inspector-placeholder')),
+      const Offset(0, 390),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Aperçu sandbox'), findsOneWidget);
+    expect(find.text('Acteurs'), findsWidgets);
+    expect(find.text('Apparence'), findsWidgets);
+    expect(
+      find.text('Cet acteur n’est plus en “Cinématique uniquement”.'),
+      findsOneWidget,
+    );
+    expect(
+      find.text('L’apparence Character Library ne s’applique plus.'),
+      findsOneWidget,
+    );
+    expect(find.text('Retirer l’apparence'), findsOneWidget);
+    expect(find.text('Préparation preview'), findsOneWidget);
+    expect(
+      find.textContaining('Apparences acteurs — À corriger'),
+      findsWidgets,
+    );
+    expect(find.text('Timeline par pistes'), findsOneWidget);
+    expect(find.text('Lecture en cours'), findsNothing);
+    for (final key in <String>[
+      'cinematic-builder-transport-reset-button',
+      'cinematic-builder-transport-play-button',
+      'cinematic-builder-transport-stop-button',
+    ]) {
+      final button = tester.widget<PokeMapButton>(
+        find.byKey(ValueKey<String>(key)),
+      );
+      expect(button.onPressed, isNull);
+    }
+    expect(tester.takeException(), isNull);
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_81_cinematic_actor_appearance_readiness_'
+      'drift_diagnostics_polish_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+
+    expect(screenshotFile.existsSync(), isTrue);
+  });
diff --git a/packages/map_editor/test/cinematics_library_workspace_test.dart b/packages/map_editor/test/cinematics_library_workspace_test.dart
index 5a5d9b53..d18c4524 100644
--- a/packages/map_editor/test/cinematics_library_workspace_test.dart
+++ b/packages/map_editor/test/cinematics_library_workspace_test.dart
@@ -185,0 +186,62 @@ void main() {
+  testWidgets('shows preview summary for actor appearance drift',
+      (tester) async {
+    _setLargeSurface(tester);
+    await tester.pumpWidget(
+      _Harness(
+        project: _project(
+          characters: const [
+            ProjectCharacterEntry(
+              id: 'character_rival',
+              name: 'Rival',
+              tilesetId: 'characters/rival',
+              frameWidth: 32,
+              frameHeight: 32,
+            ),
+          ],
+          cinematics: [
+            CinematicAsset(
+              id: 'cinematic_appearance_drift_summary',
+              title: 'Appearance drift summary cinematic',
+              mapId: 'map_lab',
+              requiredActors: [
+                CinematicActorRef(
+                  actorId: 'actor_rival',
+                  label: 'Rival actor',
+                ),
+              ],
+              stageContext: CinematicStageContext(
+                actorBindings: [
+                  CinematicActorBinding(
+                    actorId: 'actor_rival',
+                    kind: CinematicActorBindingKind.player,
+                  ),
+                ],
+                actorAppearanceBindings: [
+                  CinematicActorAppearanceBinding(
+                    actorId: 'actor_rival',
+                    characterId: 'character_rival',
+                  ),
+                ],
+              ),
+              timeline: CinematicTimeline(
+                steps: [
+                  CinematicTimelineStep(
+                    id: 'step_wait',
+                    kind: CinematicTimelineStepKind.wait,
+                    label: 'Beat',
+                    durationMs: 500,
+                  ),
+                ],
+              ),
+            ),
+          ],
+          includeBridge: false,
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Preview'), findsOneWidget);
+    expect(find.text('apparence à corriger'), findsOneWidget);
+  });
+
@@ -884,0 +947 @@ ProjectManifest _project({
+  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
@@ -893,0 +957 @@ ProjectManifest _project({
+    characters: characters,
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 138936bd..ebcf503f 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -12 +12 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
-NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0
+NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract
@@ -117 +117 @@ NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Pol
-| NS-SCENES-V1-81 | Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | editor / ui-polish | Polir les diagnostics apparence/stage apres V1-80 : refs cassees, changement de kind apres selection, assets Character Library incomplets et messages readiness. | Pas de preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound, mutation Character Library ou nouveau modele core. | Builder/Library cinematics, readiness editor, tests widget, rapport, screenshot si UI. | TODO : drift apparence plus lisible, actions de nettoyage explicites, readiness precise sans faux OK. | Masquer une reference cassee ; supprimer automatiquement une ref ; faire croire a une preview reelle. | TODO : diagnostic polish apres picker, sans elargir le pouvoir runtime/editor. | V1-80. |
+| NS-SCENES-V1-81 | Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | editor / ui-polish | Polir les diagnostics apparence/stage apres V1-80 : refs cassees, changement de kind apres selection, assets Character Library incomplets et messages readiness. | Pas de preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound, mutation Character Library ou nouveau modele core. | Builder/Library cinematics, readiness editor, tests widget, rapport, screenshot si UI. | DONE : drift apparence lisible, actions de nettoyage explicites, readiness precise, summary Library et Visual Gate. | Masquer une reference cassee ; supprimer automatiquement une ref ; faire croire a une preview reelle. | DONE : diagnostic polish apres picker, sans elargir le pouvoir runtime/editor. | V1-80. |
@@ -119,0 +120,14 @@ NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Pol
+## Mise a jour V1-81
+
+Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.
+
+Demande : Karim a fourni le prompt du lot et a autorise l'utilisation de sub agents au besoin. Le scope retenu reste concentre sur le polish editor des apparences Character Library.
+
+Decision : les refs d'apparence ne sont jamais supprimees automatiquement. Le Builder expose des messages humains et des actions explicites pour nettoyer ref character cassee, actor kind incompatible et actor supprime/orphelin. La Library resume le drift via `Preview : apparence a corriger`.
+
+Scope realise : diagnostics apparence humanises, Character Library vide expliquee, character incomplet explique sans preview reelle, readiness `Apparences acteurs` alignee, Visual Gate V1-81, tests Builder/Library, analyse cible editor.
+
+Limites : pas de preview reelle, pas de runtime, pas de mutation Character Library, pas de pathfinding, pas de donnees Selbrume, pas de `characterId` dans `CinematicActorBinding` ou `requiredActors`.
+
+Prochain lot exact recommande : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.
+
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 0439c82b..0c83b0e2 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -138 +138 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-| NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | TODO | Prochain lot recommande : polir les diagnostics et la readiness autour des apparences Character Library apres V1-80, notamment refs cassees, changement de binding kind apres selection, assets incomplets et actions de nettoyage explicites, sans preview reelle ni runtime. |
+| NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | DONE | Diagnostics apparence Character Library humanises apres V1-80 : ref character cassee, actor kind incompatible, actor supprime/orphelin, Character Library vide, character incomplet, actions de correction explicites, readiness `Apparences acteurs`, summary Library et Visual Gate, sans preview reelle, runtime, playback, pathfinding, mutation Character Library ni donnee Selbrume. |
@@ -143 +143 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-`NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0`
+`NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`
@@ -145 +145 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-Raison : V1-80 expose maintenant le picker Character Library limite aux acteurs `cinematicOnly`. Le prochain verrou produit recommande est de polir les diagnostics de drift apparence/stage : refs cassees, changement de kind apres selection, assets incomplets et messages de readiness, sans ouvrir de preview reelle ni runtime.
+Raison : V1-81 ferme le polish des diagnostics d'apparence Character Library sans brancher de preview reelle. Le prochain verrou produit recommande est de cadrer la future preview map backdrop : source de rendu, camera/viewport, limites sandbox et refus explicite de runtime/playback premature.
@@ -147 +147 @@ Raison : V1-80 expose maintenant le picker Character Library limite aux acteurs
-Ordre apres V1-80 : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0`.
+Ordre apres V1-81 : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.
@@ -154,0 +155,16 @@ Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regle
+## Mise a jour V1-81
+
+Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.
+
+Demande : lot implemente a la demande de Karim, avec autorisation d'utiliser des sub agents au besoin. Le besoin etait de polir le drift apparence Character Library apres V1-80, sans ouvrir de preview reelle ni toucher au runtime.
+
+Decision : les diagnostics d'apparence restent dans le Builder/Library/readiness editor. Aucune mutation automatique silencieuse n'est faite : les refs incompatibles, cassees ou orphelines sont visibles et nettoyables par action explicite.
+
+Scope realise : messages humains pour ref character cassee, actor kind incompatible, acteur supprime/orphelin, Character Library vide, character sans tileset ou sans animation idle exploitable ; actions `Retirer la reference`, `Retirer l'apparence`, `Nettoyer la reference` ; readiness `Apparences acteurs` avec `OK`, `A completer` et `A corriger` ; summary Library `apparence a corriger` ; Visual Gate V1-81.
+
+Preuve : test RED puis GREEN `shows incompatible character appearance drift when actor is no longer cinematic only`, tests Builder/Library cibles verts, core non-regression cibles verts, analyse cible editor verte, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png` generee.
+
+Limites confirmees : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de mutation Character Library, pas de `characterId` dans `CinematicActorBinding` ou `requiredActors`, pas de TextField ID, pas de JSON brut, pas d'image IA ou `gpt-image-2`, pas de donnee Selbrume.
+
+Prochain lot exact recommande : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.
+
```

## Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_81_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
```

## Auto-review critique

```text
1. map_core modifié : non.
2. map_runtime modifié : non.
3. map_gameplay/map_battle/examples modifiés : non.
4. CharacterLibraryPanel modifié : non.
5. ProjectCharacterEntry créé/édité/supprimé : non.
6. Preview réelle ajoutée : non.
7. Playback ajouté : non.
8. currentTimeMs/playbackTimeMs/isPlaying ajoutés : non.
9. Pathfinding/collision/warp/spawn runtime ajoutés : non.
10. Données Selbrume ajoutées : non.
11. characterId dans CinematicActorBinding : non.
12. characterId dans requiredActors : non.
13. stageContext.mapId ajouté : non.
14. Refs cassées character visibles : oui.
15. Refs cassées character corrigeables explicitement : oui.
16. Actor kind incompatible expliqué : oui.
17. Actor kind incompatible corrigeable sans mutation automatique : oui.
18. Character Library vide expliqué : oui.
19. Character incomplet expliqué : oui.
20. Readiness apparences mise à jour : oui.
21. Picker Character Library V1-80 fonctionne encore : oui.
22. Pickers mapEntity/mapEvent V1-77 fonctionnent encore : oui.
23. timeline.steps préservé : oui.
24. durationMs préservé : oui.
25. duration editor et resize fonctionnent encore : oui.
26. Transports disabled : oui.
27. Visual Gate prouve le drift polish : oui.
28. Evidence Pack complet sans placeholders : oui.
29. Prochain lot : NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract.
```

## Sorties finales Git

```text
git diff --check
<vide>

git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    | 129 +++++-
 .../cinematic_stage_preview_readiness.dart         |  77 +++-
 .../cinematics/cinematics_library_workspace.dart   |   7 +
 .../test/cinematic_builder_workspace_test.dart     | 496 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  64 +++
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  24 +-
 7 files changed, 791 insertions(+), 24 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_81_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
```
