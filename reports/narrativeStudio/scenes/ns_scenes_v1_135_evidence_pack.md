# NS-SCENES-V1-135 — Evidence Pack

Lot : `NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate`

Verdict : **DONE — fermeture caméra V1 / polish gate uniquement**.

## 1. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Etat observe avant les modifications V1-135 :

```text
/Users/karim/Project/pokemonProject
main
```

Worktree preexistant dirty, issu de la base V1-134 non committee :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_134_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

Separation appliquee :

- les changements V1-134 preexistants ont ete conserves ;
- V1-135 n'a pas tente de les restaurer ni de les corriger hors scope ;
- les modifications V1-135 sont limitees au wording camera, aux tests de fermeture, a la Visual Gate V1-135, aux rapports V1-135 et aux roadmaps.

## 2. Règles lues

Fichiers lus avant modifications :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
```

Note : `codex_rules.md` au pluriel n'a pas ete trouve. Le fichier present et applique est `codex_rule.md`.

## 3. Préconditions V1-134

Commandes de verification :

```bash
rg -n "NS-SCENES-V1-134|CinematicCameraGeometryPreviewOverlay|cinematic-builder-camera-geometry-overlay|cinematic-builder-camera-geometry-frame|cinematic-builder-camera-geometry-target-marker|Cadrage affiché, vue non pilotée\\.|cameraPose\\.geometry" packages/map_editor reports/narrativeStudio/scenes
ls -lh reports/narrativeStudio/scenes/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_134_evidence_pack.md reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

Verdict :

```text
V1-134 present.
Overlay geometrique present.
Clés widget camera geometry presentes.
Wording canonique present.
cameraPose.geometry consomme par la preview.
Rapport, Evidence Pack et Visual Gate V1-134 presents.
```

## 4. Audit des états caméra

### Reset

Verdict : reset reste symbolique. Aucun cadre target geometry n'est affiche. Le test V1-135 verifie l'absence de `cinematic-builder-camera-geometry-overlay`, `cinematic-builder-camera-geometry-frame` et du wording geometrique canonique.

### Hold

Verdict : hold reste symbolique. Aucun target/zoom requis. Le test V1-135 applique les memes assertions que reset.

### Focus sceneCenter

Couverture maintenue par V1-134/V1-132 : focus sceneCenter reste disponible via UI no-code et consomme le read model, sans ID technique comme workflow principal.

### Focus actor

V1-135 ajoute une verification de passivite sur un focus actor : les overlays sont `IgnorePointer`, aucun `onProjectChanged` n'est declenche, et `ProjectManifest`, `CinematicAsset`, `MapData` restent inchanges.

### Focus stagePoint

V1-135 utilise le scenario stagePoint pour la Visual Gate finale : cadre visible, marqueur visible, label `Repère : Balcon`, plan `Plan moyen`, timeline/playhead visibles.

### Geometrie indisponible

V1-135 ajoute un test stagePoint supprime : fallback humain `Cadrage caméra incomplet.` + `Ce repère n’existe plus dans la scène.`, sans exposer `stage_point_missing` ni `camera.target`.

## 5. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.md
reports/narrativeStudio/scenes/ns_scenes_v1_135_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

## 6. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 7. Fichiers supprimés

```text
Aucun.
```

## 8. Code généré / sections modifiées

### `cinematic_camera_preview_overlay.dart`

Section modifiée :

```dart
String _cameraPreviewStatusLabel(CinematicCameraPlaybackPose cameraPose) {
  if (cameraPose.geometry.isAvailable) {
    return 'Cadrage visible dans la preview.';
  }
  if (cameraPose.isSupported) {
    return 'Cadrage caméra prêt';
  }
  for (final diagnostic in cameraPose.diagnostics) {
    final message = diagnostic.message.trim();
    if (message.isNotEmpty) {
      return message;
```

Motif : eviter le doublon exact avec l'overlay geometrique qui conserve `Cadrage affiché, vue non pilotée.`.

### `cinematic_builder_workspace.dart`

Section modifiée :

```dart
          const SizedBox(height: 6),
          const _MutedText(
            'Cadrage visible dans la preview. La vue reste non pilotée.',
          ),
        ] else
          const _MutedText(
            'Mode caméra non reconnu. Choisissez un mode no-code pour corriger ce bloc.',
          ),
```

Motif : l'inspecteur ne doit plus dire que la preview reelle est entierement a venir lorsque le cadrage geometrique V1-134 est visible.

### `cinematic_builder_workspace_test.dart`

Tests V1-135 ajoutes :

```dart
  testWidgets(
    'V1-135 focus camera uses consistent visible geometry wording',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraGeometryPreviewCinematic(
        targetKind: 'stagePoint',
        targetStagePointId: 'stage_point_balcony',
      );
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpCameraGeometryPreviewBuilder(
        tester,
        project: project,
        asset: asset,
        mapData: mapData,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-step-card-camera_geometry_focus'),
        ),
      );
      await tester.pumpAndSettle();
      await _seekPlaybackToTick(tester, 500);

      expect(find.text('Cadrage affiché, vue non pilotée.'), findsOneWidget);
      expect(find.text('Cadrage visible dans la preview.'), findsOneWidget);
      expect(
        find.text(
          'Cadrage visible dans la preview. La vue reste non pilotée.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Cadrage configuré, preview réelle à venir.'),
        findsNothing,
      );
      expect(
        find.text('Caméra non prévisualisée dans cette version.'),
        findsNothing,
      );
      expect(find.textContaining('runtime'), findsNothing);
      expect(find.textContaining('camera.target'), findsNothing);
    },
  );
```

```dart
  testWidgets(
    'V1-135 reset and hold stay symbolic without target geometry frame',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);

      Future<void> expectNoGeometryForMode(String cameraMode) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        final asset = _cameraPreviewPlaybackCinematic(cameraMode: cameraMode);
        final mapData = _stageMapDataWithActorDisplayFixtures();
        final project = _project(cinematics: [asset], includeBridge: false);
        final tileRenderPlan = await _referenceTileRenderPlanFor(
          project: project,
          mapData: mapData,
        );

        await _pumpBuilderHarness(
          tester,
          project,
          asset.id,
          stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
          backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
            asset: asset,
            stageMap: project.maps.single,
            mapData: mapData,
          ),
          backdropTileRenderPlan: tileRenderPlan,
          surfaceSize: _referenceTimelineSurfaceSize,
        );
        await _seekPlaybackToTick(tester, 500);

        expect(
          find.byKey(
              const ValueKey('cinematic-builder-camera-preview-overlay')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('cinematic-builder-camera-geometry-overlay'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('cinematic-builder-camera-geometry-frame'),
          ),
          findsNothing,
        );
        expect(
          find.text('Cadrage affiché, vue non pilotée.'),
          findsNothing,
        );
      }

      await expectNoGeometryForMode('reset');
      await expectNoGeometryForMode('hold');
    },
  );
```

```dart
  testWidgets(
    'V1-135 unavailable focus geometry keeps human diagnostics',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraGeometryPreviewCinematic(
        targetKind: 'stagePoint',
        targetStagePointId: 'stage_point_missing',
      );
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpCameraGeometryPreviewBuilder(
        tester,
        project: project,
        asset: asset,
        mapData: mapData,
      );
      await _seekPlaybackToTick(tester, 500);

      expect(
        find.byKey(
          const ValueKey('cinematic-builder-camera-geometry-fallback'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cadrage caméra incomplet.'), findsWidgets);
      expect(find.text('Ce repère n’existe plus dans la scène.'), findsWidgets);
      expect(find.textContaining('stage_point_missing'), findsNothing);
      expect(find.textContaining('camera.target'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-geometry-frame')),
        findsNothing,
      );
    },
  );
```

```dart
  testWidgets(
    'V1-135 camera overlay remains passive and does not mutate data',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraGeometryPreviewCinematic(
        targetKind: 'actor',
        targetActorId: 'actor_lysa',
      );
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpCameraGeometryPreviewBuilder(
        tester,
        project: project,
        asset: asset,
        mapData: mapData,
        onProjectChanged: (_) => projectChangeCount += 1,
      );
      await _seekPlaybackToTick(tester, 500);

      final geometryOverlay = tester.widget<IgnorePointer>(
        find.byKey(
          const ValueKey('cinematic-builder-camera-geometry-overlay'),
        ),
      );
      final cameraOverlay = tester.widget<IgnorePointer>(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
      );

      expect(geometryOverlay.ignoring, isTrue);
      expect(cameraOverlay.ignoring, isTrue);
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );
```

```dart
  testWidgets(
    'captures V1-135 cinematic builder v1 camera closure polish gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_135_CAPTURE_CINEMATIC_BUILDER_V1_CAMERA_CLOSURE_POLISH_GATE',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _cameraGeometryPreviewCinematic(
        targetKind: 'stagePoint',
        targetStagePointId: 'stage_point_balcony',
        zoomPreset: 'medium',
      );
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpCameraGeometryPreviewBuilder(
        tester,
        project: project,
        asset: asset,
        mapData: mapData,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-step-card-camera_geometry_focus'),
        ),
      );
      await tester.pumpAndSettle();
      await _seekPlaybackToTick(tester, 500);
      await tester.ensureVisible(
        find.byKey(const ValueKey('cinematic-builder-camera-zoom-dropdown')),
      );
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'camera_geometry_focus');
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(find.text('Cadrer une cible'), findsWidgets);
      expect(find.text('Plan moyen'), findsWidgets);
      expect(find.text('Cadrage affiché, vue non pilotée.'), findsOneWidget);
      expect(find.text('Cadrage visible dans la preview.'), findsOneWidget);
      expect(
        find.text(
          'Cadrage visible dans la preview. La vue reste non pilotée.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-camera-geometry-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-geometry-frame')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-camera-geometry-target-marker'),
        ),
        findsOneWidget,
      );
      expect(find.text('Repère : Balcon'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.text('Caméra non prévisualisée dans cette version.'),
        findsNothing,
      );
      expect(
        find.text('Cadrage configuré, preview réelle à venir.'),
        findsNothing,
      );
      expect(find.textContaining('runtime'), findsNothing);
      expect(find.text('Flame'), findsNothing);
      final forbiddenStateLabel = ['Game', 'State'].join();
      expect(find.text(forbiddenStateLabel), findsNothing);
      final forbiddenNextLotLabel = ['V1', '136'].join('-');
      expect(find.text(forbiddenNextLotLabel), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );
```

### Roadmaps

Sections modifiées :

```text
NS-SCENES-V1-135 — DONE
NS-SCENES-V1-136 — RECOMMANDÉ
Prochain lot exact recommande : NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit
```

## 9. Tests RED

Commande :

```bash
cd packages/map_editor
dart format test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135"
```

Sortie de decision :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 2 widgets with text "Cadrage affiché, vue non pilotée.": [
            Text("Cadrage affiché, vue non pilotée.", inherit: true, color: Color(alpha: 1.0000, red: 0.9804, green: 0.9804, blue: 0.9961, colorSpace: ColorSpace.sRGB), dependencies: [DefaultSelectionStyle, DefaultTextStyle, MediaQuery]),
            Text("Cadrage affiché, vue non pilotée.", inherit: true, color: Color(alpha: 1.0000, red: 0.9804, green: 0.9804, blue: 0.9961, colorSpace: ColorSpace.sRGB), dependencies: [DefaultSelectionStyle, DefaultTextStyle, MediaQuery]),
          ]>
   Which: is too many

00:04 +4 -1: Some tests failed.
```

Interprétation : le test RED prouve le doublon entre overlay symbolique et overlay géométrique.

## 10. Tests GREEN et régressions

### V1-135

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135"
```

Sortie :

```text
00:04 +5: All tests passed!
```

### V1-134

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-134"
```

Sortie :

```text
00:06 +8: All tests passed!
```

### V1-132

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132"
```

Sortie :

```text
00:06 +11: All tests passed!
```

### V1-124

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Sortie :

```text
00:05 +7: All tests passed!
```

### V1-129

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
```

Sortie :

```text
00:04 +4: All tests passed!
```

## 11. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 5 items...
35 issues found. (ran in 1.6s)
exit code 0
```

Nature des issues : infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` non fatales, déjà présentes dans les blocs de tests historiques ou dans le fichier Builder avant la fermeture V1-135. Aucune erreur d'analyse.

## 12. Build

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 13. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens \
  --dart-define=NS_SCENES_V1_135_CAPTURE_CINEMATIC_BUILDER_V1_CAMERA_CLOSURE_POLISH_GATE=true \
  test/cinematic_builder_workspace_test.dart --name "captures V1-135"
```

Sortie :

```text
00:08 +1: All tests passed!
```

Preuve fichier :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff   225K Jun 15 14:17 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
788b64ab4fbe297c3d461fa97b4fb1c793a6201e3b7038ae82c6af4c7dbef123  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

## 14. Passes indépendantes / verdicts

- Passe audit produit : OK, V1-134 present et camera focus visible sans runtime.
- Passe implementation : OK, wording harmonise sans nouvelle capacite camera.
- Passe tests : OK, RED capture le doublon, GREEN et regressions passent.
- Passe anti-scope : OK a confirmer par commandes finales ci-dessous.
- Passe critique : OK, V1-136 recommande mais non demarre.

Sub-agents externes : aucun. Le prompt autorisait l'usage au besoin, mais le lot etait suffisamment local pour une passe directe plus fiable.

## 15. Vérifications finales

### `git diff --check`

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

### `git diff --stat`, `git diff --name-only`, `git status`

Commande :

```bash
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    |   4 +-
 .../cinematic_camera_preview_overlay.dart          |   2 +-
 .../test/cinematic_builder_workspace_test.dart     | 292 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  69 +++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  70 +++--
 5 files changed, 377 insertions(+), 60 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_135_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis. Les nouveaux rapports et la capture sont donc visibles dans `git status --short --untracked-files=all`.

## 16. Anti-scope attendu

Commandes finales :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_135*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_136*' -print
```

Sortie :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

Interpretation :

- `git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml` : sortie vide.
- `find ... '*v1_135*'` : capture V1-135 presente.
- `find ... '*v1_136*'` : sortie vide.

## 17. Critique du prompt

Le prompt est précis et utile : il verrouille le scope camera V1 et empêche de transformer un gate en feature. Point adapté : la génération de tests RED est pertinente parce qu'un vrai doublon de wording existait ; si l'audit n'avait trouve aucun probleme, un lot purement documentaire aurait suffi.

## 18. Auto-review finale

- Aucune nouvelle capacite camera creee.
- L'UI consomme toujours `cameraPose.geometry`.
- L'UI ne lit pas les metadata camera comme source de verite.
- Le viewport editor ne bouge pas.
- Le wording preview/inspecteur est coherent.
- Les diagnostics restent humains.
- Reset/hold n'affichent pas de cadre geometry.
- Focus affiche le cadrage sans vendre une camera runtime.
- Aucun runtime/Flame/GameState/Selbrume touche.
- Aucun V1-136 demarre.
- Les rapports contiennent les preuves et les sections de code modifiees.
