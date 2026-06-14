import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const _defaultBuilderSurfaceSize = Size(1280, 860);
const _referenceTimelineSurfaceSize = Size(1663, 926);

void main() {
  testWidgets('shows populated read-only cinematic builder shell', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project();
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_intro'),
      asset: _asset(project, 'cinematic_intro'),
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsOneWidget,
    );
    expect(find.text('Cinematic Builder V0'), findsOneWidget);
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);

    for (final label in <String>[
      'Caméra',
      'Déplacer un acteur',
      'Dialogue',
      'FX',
      'Son',
      'Fondu',
      'Attendre',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Déroulé'), findsOneWidget);
    expect(find.text('Timeline cinématique'), findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsWidgets);
    expect(find.text('8 piste(s)'), findsOneWidget);
    expect(find.text('Ordre linéaire conservé'), findsOneWidget);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.text('Professor reacts'), findsWidgets);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.text('Sélection de bloc à venir'), findsOneWidget);
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Canonical scene'), findsWidgets);

    for (final key in <String>[
      'cinematic-builder-validate-button',
      'cinematic-builder-preview-button',
      'cinematic-builder-save-button',
    ]) {
      final button = tester.widget<PokeMapButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull);
    }

    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('uses simplified no-code destination vocabulary in builder', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _extendedBackdropFixture();
    final beforeProject = fixture.project.toJson();
    final beforeMapData = fixture.mapData.toJson();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, fixture.asset.id),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajouter au déroulé'), findsOneWidget);
    expect(find.text('Ajouter un repère'), findsWidgets);
    expect(find.text('Destination'), findsWidgets);
    expect(find.text('Repère de scène'), findsWidgets);
    expect(find.text('Position libre'), findsWidgets);
    expect(find.textContaining('Personnage ou objet de la map'), findsWidgets);
    expect(find.textContaining('Déclencheur de map'), findsWidgets);
    expect(find.textContaining('Repère'), findsWidgets);
    expect(find.text('Timeline cinématique'), findsOneWidget);

    for (final forbidden in <String>[
      'Ajouter un point',
      'Point abstrait',
      'Point de scène',
      'Cibles de déplacement',
      'Id: target',
      'Vue simple',
    ]) {
      expect(find.text(forbidden), findsNothing);
    }
    expect(find.textContaining('sourceId'), findsNothing);
    expect(find.textContaining('targetId'), findsNothing);
    expect(find.textContaining('binding'), findsNothing);
    expect(find.textContaining('payload'), findsNothing);
    expect(fixture.project.toJson(), beforeProject);
    expect(fixture.mapData.toJson(), beforeMapData);
  });

  testWidgets('V1-128 palette adds actor emote block', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final asset = _actorEmoteAuthoringCinematic(withEmoteStep: false);
    final mapData = _stageMapDataWithActorDisplayFixtures();
    final project = _project(cinematics: [asset], includeBridge: false);
    final beforeMapData = mapData.toJson();
    var latestProject = project;
    var projectChangeCount = 0;

    await _pumpBuilderHarness(
      tester,
      project,
      asset.id,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
      onProjectChanged: (project) {
        latestProject = project;
        projectChangeCount += 1;
      },
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    expect(find.text('Émotion'), findsWidgets);
    final paletteButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actor-emote-button'),
    );
    await tester.ensureVisible(paletteButton);
    await tester.tap(paletteButton);
    await tester.pumpAndSettle();

    final updatedAsset = _asset(latestProject, asset.id);
    final emoteSteps = updatedAsset.timeline.steps
        .where((step) => step.kind == CinematicTimelineStepKind.actorEmote)
        .toList(growable: false);
    expect(emoteSteps, hasLength(1));
    final emoteStep = emoteSteps.single;
    expect(emoteStep.actorId, 'actor_professor');
    expect(
      cinematicTimelineActorEmoteEmoteIdOf(emoteStep),
      cinematicDefaultActorEmoteId,
    );
    expect(emoteStep.durationMs, cinematicTimelineDefaultActorEmoteDurationMs);
    expect(projectChangeCount, 1);
    expect(find.text('Professor affiche Surprise'), findsWidgets);
    _expectTimelineStepSelected(tester, emoteStep.id);
    expect(mapData.toJson(), beforeMapData);
  });

  testWidgets('V1-128 actor emote inspector lets user choose actor', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final asset = _actorEmoteAuthoringCinematic(emoteId: 'question');
    final project = _project(cinematics: [asset], includeBridge: false);
    var latestProject = project;

    await _pumpBuilderHarness(
      tester,
      project,
      asset.id,
      onProjectChanged: (project) => latestProject = project,
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_emote')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réaction'), findsWidgets);
    expect(find.text('Choix no-code'), findsWidgets);
    expect(find.text('Question'), findsWidgets);
    expect(find.textContaining('actor.emoteId'), findsNothing);
    expect(find.textContaining('frameIndex'), findsNothing);
    expect(find.textContaining('atlas'), findsNothing);

    final rivalButton = find.byKey(
      const ValueKey('cinematic-builder-actor-emote-actor-actor_rival'),
    );
    await tester.ensureVisible(rivalButton);
    await tester.tap(rivalButton);
    await tester.pumpAndSettle();

    final updatedStep = _asset(latestProject, asset.id)
        .timeline
        .steps
        .singleWhere((step) => step.id == 'step_emote');
    expect(updatedStep.actorId, 'actor_rival');
    expect(cinematicTimelineActorEmoteEmoteIdOf(updatedStep), 'question');
    expect(updatedStep.label, 'Rival affiche Question');
    expect(find.text('Rival affiche Question'), findsWidgets);
  });

  testWidgets(
    'V1-128 actor emote inspector lets user choose no-code emote and duration',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _actorEmoteAuthoringCinematic();
      final project = _project(cinematics: [asset], includeBridge: false);
      var latestProject = project;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (project) => latestProject = project,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_emote')),
      );
      await tester.pumpAndSettle();

      final heartButton = find.byKey(
        const ValueKey('cinematic-builder-actor-emote-emote-heart'),
      );
      await tester.ensureVisible(heartButton);
      await tester.tap(heartButton);
      await tester.pumpAndSettle();

      var updatedStep = _asset(latestProject, asset.id)
          .timeline
          .steps
          .singleWhere((step) => step.id == 'step_emote');
      expect(updatedStep.actorId, 'actor_professor');
      expect(cinematicTimelineActorEmoteEmoteIdOf(updatedStep), 'heart');
      expect(updatedStep.label, 'Professor affiche Coeur');
      expect(find.text('Coeur'), findsWidgets);

      final durationField = find.byKey(
        const ValueKey('cinematic-builder-actor-emote-duration-ms-field'),
      );
      await tester.ensureVisible(durationField);
      await tester.enterText(durationField, '1200');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      updatedStep = _asset(latestProject, asset.id).timeline.steps.singleWhere(
            (step) => step.id == 'step_emote',
          );
      expect(updatedStep.durationMs, 1200);
      expect(find.textContaining('sourceRect'), findsNothing);
      expect(find.textContaining('AssetImage'), findsNothing);
    },
  );

  testWidgets(
    'captures V1-128 cinematic emote block editor ui visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_128_CAPTURE_CINEMATIC_EMOTE_BLOCK_EDITOR_UI',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _actorEmoteAuthoringCinematic(emoteId: 'question');
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_emote')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Émotion'), findsWidgets);
      expect(find.text('Réaction'), findsWidgets);
      expect(find.text('Choix no-code'), findsWidgets);
      expect(find.text('Question'), findsWidgets);
      expect(find.text('Bornes : 100–30000 ms · pas 100 ms'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
        findsOneWidget,
      );
      expect(find.textContaining('actor.emoteId'), findsNothing);
      expect(find.textContaining('frameIndex'), findsNothing);
      expect(find.textContaining('runtime'), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('edits cinematic stage map and backdrop from builder', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic(mapId: null)]);
    var latestProject = project;
    final beforeAsset = _asset(project, 'cinematic_stage_context');
    final beforeSteps = beforeAsset.timeline.toJson();
    final beforeDuration = _entry(
      project,
      'cinematic_stage_context',
    ).timeline.estimatedDurationMs;

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(find.text('Contexte de scène'), findsOneWidget);
    expect(find.text('Map de scène'), findsOneWidget);
    final dropdownButton = find.byKey(
      const ValueKey('cinematic-builder-stage-map-dropdown'),
    );
    await tester.ensureVisible(dropdownButton);
    await tester.tap(dropdownButton);
    await tester.pumpAndSettle();

    final mapButton = find.byKey(
      const ValueKey('cinematic-builder-stage-map-map_lab'),
    );
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();
    final backdropDropdown = find.byKey(
      const ValueKey('cinematic-builder-backdrop-dropdown'),
    );
    await tester.ensureVisible(backdropDropdown);
    await tester.tap(backdropDropdown);
    await tester.pumpAndSettle();

    final backdropButton = find.byKey(
      const ValueKey('cinematic-builder-backdrop-projectMap'),
    );
    await tester.ensureVisible(backdropButton);
    await tester.tap(backdropButton);
    await tester.pumpAndSettle();

    final updated = _asset(latestProject, 'cinematic_stage_context');
    expect(updated.mapId, 'map_lab');
    expect(
      updated.stageContext?.backdropMode,
      CinematicStageBackdropMode.projectMap,
    );
    expect(updated.stageContext?.toJson(), isNot(contains('mapId')));
    expect(updated.timeline.toJson(), beforeSteps);
    expect(
      _entry(
        latestProject,
        'cinematic_stage_context',
      ).timeline.estimatedDurationMs,
      beforeDuration,
    );
    _expectTransportControlsPresent(tester);
  });

  testWidgets(
    'shows cinematic stage preview readiness checklist without starting preview',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_stageContextCinematic()]);
      await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

      final stateTile = find.text('État de la scène');
      await tester.ensureVisible(stateTile);
      await tester.tap(stateTile);
      await tester.pumpAndSettle();

      expect(find.text('Préparation preview'), findsOneWidget);
      expect(find.text('Incomplet'), findsWidgets);
      expect(
        find.textContaining('La preview réelle arrivera plus tard.'),
        findsWidgets,
      );
      for (final label in <String>[
        'Map de scène',
        'Décor',
        'Acteurs liés',
        'Départs de scène',
        'Destinations',
        'Sources de la map',
      ]) {
        expect(find.textContaining(label), findsWidgets);
      }
      expect(find.textContaining('À compléter'), findsWidgets);
      expect(
        find.textContaining(
          'Sources de la map — OK : aucune source de la map requise',
        ),
        findsWidgets,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      _expectTransportControlsPresent(tester);
    },
  );

  testWidgets(
    'renders static map backdrop preview when backdrop model is available',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_stageContextCinematic()]);
      final before = project.toJson();
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithVisualLayers();
      final beforeMapData = stageMapData.toJson();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
      expect(find.text('Fallback structurel'), findsOneWidget);
      expect(find.text('Lab map'), findsWidgets);
      expect(find.text('12 x 10 tuiles'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-viewport'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-meta-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-legend')),
        findsOneWidget,
      );
      final mapViewportSize = tester.getSize(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-viewport'),
        ),
      );
      final legendSize = tester.getSize(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-legend')),
      );
      expect(mapViewportSize.shortestSide, greaterThanOrEqualTo(220));
      expect(mapViewportSize.aspectRatio, closeTo(12 / 10, 0.08));
      expect(legendSize.height, lessThan(mapViewportSize.height * 0.35));
      expect(find.text('Fallback structurel'), findsOneWidget);
      expect(find.text('6 primitive(s) spatiale(s)'), findsOneWidget);
      expect(find.text('Ground · 4 · tile'), findsOneWidget);
      expect(find.text('Main path · 2 · path'), findsOneWidget);
      expect(find.text('Collision'), findsNothing);
      expect(find.text('Couche collision'), findsNothing);
      expect(find.text('Professor Oak'), findsNothing);
      expect(find.text('Décor seul'), findsWidgets);
      expect(find.text('Sans acteurs'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);

      _expectTransportControlsPresent(tester);

      expect(project.toJson(), before);
      expect(stageMapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'renders real tile map backdrop when tileset image is available',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final tilesetImage = await _makeTestTilesetImage();
      final project = _project(cinematics: [_stageContextCinematic()]);
      final before = project.toJson();
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithBitmapTileLayer();
      final beforeMapData = stageMapData.toJson();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );
      final bitmapProject = project.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'lab_tiles',
            name: 'Lab tiles',
            relativePath: 'assets/tilesets/lab.png',
          ),
        ],
        settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      );
      final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
        mapData: stageMapData,
        manifest: bitmapProject,
        tilesets: {
          'lab_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'lab_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        backdropTileRenderPlan: tileRenderPlan,
      );

      expect(find.text('Décor disponible'), findsOneWidget);
      expect(find.text('Décor seul'), findsWidgets);
      expect(find.text('Sans acteurs'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);
      expect(find.text('Tiles réelles affichées'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        findsOneWidget,
      );
      expect(tileRenderPlan.instructions, hasLength(2));
      expect(tileRenderPlan.instructions.first.tileId, 1);
      expect(tileRenderPlan.instructions.last.tileId, 2);
      expect(tileRenderPlan.instructions.first.sourceRect.left, 0);
      expect(tileRenderPlan.instructions.last.sourceRect.left, 8);
      expect(find.text('Aperçu spatial structurel'), findsNothing);
      expect(find.text('Preview réelle à venir.'), findsNothing);
      expect(find.text('Collision'), findsNothing);
      expect(find.text('Gate bell'), findsNothing);
      expect(find.text('Professor Oak'), findsNothing);

      _expectTransportControlsPresent(tester);
      expect(
        find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
        findsOneWidget,
      );
      expect(project.toJson(), before);
      expect(stageMapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'renders static actor placeholders over the cinematic map backdrop',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final tilesetImage = await _makeTestTilesetImage();
      final asset = _actorDisplayPreviewCinematic();
      final project = _project(
        cinematics: [asset],
        characters: const [
          ProjectCharacterEntry(
            id: 'character_lysa',
            name: 'Lysa',
            tilesetId: '',
          ),
        ],
      );
      final stageMapData = _stageMapDataWithActorDisplayFixtures();
      final beforeProject = project.toJson();
      final beforeMapData = stageMapData.toJson();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );
      final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
        mapData: stageMapData,
        manifest: project.copyWith(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'lab_tiles',
              name: 'Lab tiles',
              relativePath: 'assets/tilesets/lab.png',
            ),
          ],
          settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
        ),
        tilesets: {
          'lab_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'lab_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );
      final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
        cinematic: asset,
        project: project,
        stageMap: project.maps.single,
        mapData: stageMapData,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_actor_display_preview'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-actor-display-overlay')),
        findsOneWidget,
      );
      for (final actorId in <String>[
        'actor_player',
        'actor_guard',
        'actor_lysa',
      ]) {
        expect(
          find.byKey(
            ValueKey<String>('cinematic-builder-actor-display-actor-$actorId'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            ValueKey<String>(
              'cinematic-builder-actor-display-direction-$actorId',
            ),
          ),
          findsOneWidget,
        );
      }
      for (final actorId in <String>['actor_unbound', 'actor_missing']) {
        expect(
          find.byKey(
            ValueKey<String>('cinematic-builder-actor-display-actor-$actorId'),
          ),
          findsNothing,
        );
      }
      expect(find.text('Aucun acteur animé'), findsWidgets);
      expect(find.text('3 acteur(s) placés'), findsWidgets);
      expect(find.text('2 à compléter'), findsWidgets);
      expect(find.text('Placeholders'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-diagnostics'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Définis l’entrée de scène'), findsWidgets);
      expect(
        find.textContaining('son apparence reste à compléter'),
        findsWidgets,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Playback'), findsNothing);
      expect(find.text('Seek'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      _expectTransportControlsPresent(tester);
      expect(project.toJson(), beforeProject);
      expect(stageMapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'aligns actor placeholders with the backdrop viewport transform',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _actorDisplayPreviewCinematic();
      final project = _project(cinematics: [asset]);
      final stageMapData = _stageMapDataWithActorDisplayFixtures();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );
      final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
        cinematic: asset,
        project: project,
        stageMap: project.maps.single,
        mapData: stageMapData,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_actor_display_preview'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
      );

      final viewportRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-viewport'),
        ),
      );
      final guardRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_guard'),
        ),
      );
      final expectedGuardAnchor = Offset(
        viewportRect.left + (6.5 * viewportRect.width / 12),
        viewportRect.top + (6 * viewportRect.height / 10),
      );
      expect(guardRect.center.dx, closeTo(expectedGuardAnchor.dx, 1));
      expect(guardRect.bottom, closeTo(expectedGuardAnchor.dy, 1));
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey(
              'cinematic-builder-actor-display-direction-actor_lysa',
            ),
          ),
          matching: find.text('E'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'falls back to structural backdrop when tileset image is unavailable',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_stageContextCinematic()]);
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithBitmapTileLayer();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );
      final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
        mapData: stageMapData,
        manifest: project.copyWith(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'lab_tiles',
              name: 'Lab tiles',
              relativePath: 'assets/tilesets/lab.png',
            ),
          ],
          settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
        ),
        tilesets: const {},
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        backdropTileRenderPlan: tileRenderPlan,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fallback structurel'), findsOneWidget);
      expect(
        find.text('Image de tileset indisponible pour lab_tiles.'),
        findsOneWidget,
      );
      expect(find.text('Collision'), findsNothing);
      expect(find.text('Gate bell'), findsNothing);
      expect(find.text('Professor Oak'), findsNothing);
    },
  );

  testWidgets('builds bitmap instructions only from visible tile layers', (
    tester,
  ) async {
    final tilesetImage = await _makeTestTilesetImage();
    final manifest = _project().copyWith(
      tilesets: const [
        ProjectTilesetEntry(
          id: 'lab_tiles',
          name: 'Lab tiles',
          relativePath: 'assets/tilesets/lab.png',
        ),
        ProjectTilesetEntry(
          id: 'wide_tiles',
          name: 'Wide tiles',
          relativePath: 'assets/tilesets/wide.png',
        ),
      ],
      settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
    );
    const mapData = MapData(
      id: 'map_lab',
      name: 'Lab map',
      size: GridSize(width: 3, height: 1),
      layers: [
        MapLayer.tile(
          id: 'visible',
          name: 'Visible tiles',
          tilesetId: 'lab_tiles',
          tiles: [1, 0, 2],
        ),
        MapLayer.tile(
          id: 'hidden',
          name: 'Hidden tiles',
          tilesetId: 'lab_tiles',
          isVisible: false,
          tiles: [1, 1, 1],
        ),
        MapLayer.tile(
          id: 'semi',
          name: 'Semi transparent tiles',
          tilesetId: 'lab_tiles',
          opacity: 0.5,
          tiles: [0, 2, 0],
        ),
        MapLayer.tile(
          id: 'transparent',
          name: 'Transparent tiles',
          tilesetId: 'lab_tiles',
          opacity: 0,
          tiles: [1, 1, 1],
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: [true, true, true],
        ),
        MapLayer.tile(
          id: 'missing',
          name: 'Missing tileset',
          tilesetId: 'missing_tiles',
          tiles: [1, 1, 1],
        ),
        MapLayer.tile(
          id: 'out_of_bounds',
          name: 'Out of bounds tile',
          tilesetId: 'lab_tiles',
          tiles: [3, 0, 0],
        ),
        MapLayer.tile(
          id: 'wide_metrics',
          name: 'Wide metrics tile',
          tilesetId: 'wide_tiles',
          tiles: [1, 0, 0],
        ),
      ],
    );

    final plan = buildCinematicMapBackdropTileRenderPlan(
      mapData: mapData,
      manifest: manifest,
      tilesets: {
        'lab_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'lab_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
        'wide_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'wide_tiles',
          image: tilesetImage,
          tileWidth: 16,
          tileHeight: 8,
        ),
      },
    );

    expect(plan.instructions, hasLength(3));
    expect(plan.instructions.map((instruction) => instruction.layerId), [
      'visible',
      'visible',
      'semi',
    ]);
    expect(plan.instructions.map((instruction) => instruction.tileId), [
      1,
      2,
      2,
    ]);
    expect(plan.instructions.map((instruction) => instruction.opacity), [
      1.0,
      1.0,
      0.5,
    ]);
    expect(
      plan.diagnostics.map((diagnostic) => diagnostic.code),
      contains('missingTilesetEntry'),
    );
    expect(
      plan.diagnostics.map((diagnostic) => diagnostic.code),
      contains('sourceRectOutOfBounds'),
    );
    expect(
      plan.diagnostics.map((diagnostic) => diagnostic.code),
      contains('tileMetricMismatch'),
    );
    expect(
      plan.instructions.any(
        (instruction) => instruction.layerId == 'collision',
      ),
      isFalse,
    );
  });

  testWidgets(
    'builds extended backdrop bitmap instructions for neutral terrain path surface and placed elements',
    (tester) async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final manifest = _extendedBackdropProject();
      final mapData = _stageMapDataWithExtendedBackdrop();
      final beforeManifest = manifest.toJson();
      final beforeMapData = mapData.toJson();

      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: mapData,
        manifest: manifest,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      expect(plan.hasBitmapInstructions, isTrue);
      expect(plan.instructions.map((instruction) => instruction.renderPass), [
        CinematicMapBackdropRenderPass.terrain,
        CinematicMapBackdropRenderPass.path,
        CinematicMapBackdropRenderPass.tileBackground,
        CinematicMapBackdropRenderPass.surface,
        CinematicMapBackdropRenderPass.placedBackground,
        CinematicMapBackdropRenderPass.tileForeground,
        CinematicMapBackdropRenderPass.placedForeground,
      ]);
      expect(
        plan.instructions.map((instruction) => instruction.layerKind).toSet(),
        containsAll(<CinematicMapBackdropLayerKind>{
          CinematicMapBackdropLayerKind.terrain,
          CinematicMapBackdropLayerKind.path,
          CinematicMapBackdropLayerKind.tile,
          CinematicMapBackdropLayerKind.surface,
          CinematicMapBackdropLayerKind.object,
        }),
      );
      expect(
        plan.instructions
            .where((instruction) => instruction.sourceFamily == 'environment')
            .map((instruction) => instruction.sourceId)
            .toSet(),
        {'neutral_generated_tree'},
      );
      expect(
        plan.instructions.map((instruction) => instruction.sourceFamily),
        isNot(contains('event')),
      );
      expect(
        plan.instructions.map((instruction) => instruction.sourceFamily),
        isNot(contains('collision')),
      );
      expect(manifest.toJson(), beforeManifest);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'reproduces real cinematic backdrop depth divergence from Map Editor ordering',
    (tester) async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final manifest = _extendedBackdropProject();
      const mapData = MapData(
        id: 'test_map',
        name: 'Test Map',
        size: GridSize(width: 2, height: 2),
        layers: [
          MapLayer.tile(
            id: 'layer_roof',
            name: 'Roof layer',
            tilesetId: 'neutral_tiles',
            tiles: [1, 0, 0, 0],
          ),
          MapLayer.tile(
            id: 'layer_wall',
            name: 'Wall layer',
            tilesetId: 'neutral_tiles',
            tiles: [2, 0, 0, 0],
          ),
          MapLayer.path(
            id: 'layer_water',
            name: 'Water path',
            presetId: 'neutral_path',
            cells: [true, false, false, false],
          ),
          MapLayer.tile(
            id: 'layer_ponton',
            name: 'Ponton layer',
            tilesetId: 'neutral_tiles',
            tiles: [3, 0, 0, 0],
          ),
        ],
      );

      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: mapData,
        manifest: manifest,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      final pathWaterIdx = plan.instructions.indexWhere(
        (i) => i.layerId == 'layer_water',
      );
      final tilePontonIdx = plan.instructions.indexWhere(
        (i) => i.layerId == 'layer_ponton',
      );
      final tileWallIdx = plan.instructions.indexWhere(
        (i) => i.layerId == 'layer_wall',
      );
      final tileRoofIdx = plan.instructions.indexWhere(
        (i) => i.layerId == 'layer_roof',
      );

      expect(pathWaterIdx, isNot(-1));
      expect(tilePontonIdx, isNot(-1));
      expect(tileWallIdx, isNot(-1));
      expect(tileRoofIdx, isNot(-1));

      expect(
        pathWaterIdx,
        lessThan(tilePontonIdx),
        reason: 'Water path must paint under ponton tiles',
      );
      expect(
        tilePontonIdx,
        lessThan(tileWallIdx),
        reason:
            'Lower layer index (wall) must paint on top of higher layer index (ponton)',
      );
      expect(
        tileWallIdx,
        lessThan(tileRoofIdx),
        reason:
            'Roof layer (index 0) must paint on top of wall layer (index 1)',
      );
    },
  );

  testWidgets(
    'uses Path Studio center pattern when a path layer references its base preset',
    (tester) async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final manifest = _pathStudioWaterBackdropProject();

      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: _stageMapDataWithPathStudioWaterBackdrop(),
        manifest: manifest,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      final pathInstructions = plan.instructions
          .where((instruction) => instruction.sourceFamily == 'path')
          .toList();
      expect(pathInstructions, hasLength(4));
      expect(
        pathInstructions.map((instruction) => instruction.sourceId).toSet(),
        {'water_pattern'},
      );
      expect(
        pathInstructions.map((instruction) => instruction.sourceRect.left),
        [0.0, 8.0, 16.0, 24.0],
      );
    },
  );

  testWidgets('renders scene framing mode zoomed beyond full map fit', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _largeBackdropFixture();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, fixture.asset.id),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    expect(find.text('Carte entière'), findsOneWidget);
    expect(find.text('Vue scène'), findsOneWidget);
    expect(find.text('Zoom 1.00×'), findsOneWidget);

    final viewportFinder = find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
    );
    final frameFinder = find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-map-frame'),
    );
    final viewportRect = tester.getRect(viewportFinder);
    final fitFrameRect = tester.getRect(frameFinder);
    expect(fitFrameRect.width, lessThanOrEqualTo(viewportRect.width + 0.5));
    expect(fitFrameRect.height, lessThanOrEqualTo(viewportRect.height + 0.5));

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
    );
    await tester.pumpAndSettle();

    final sceneFrameRect = tester.getRect(frameFinder);
    expect(sceneFrameRect.width, greaterThan(viewportRect.width));
    expect(sceneFrameRect.height, greaterThan(viewportRect.height));
    expect(find.text('Déroulé'), findsOneWidget);
  });

  testWidgets(
    'zooms in and resets cinematic backdrop framing without mutating project or map',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largeBackdropFixture();
      final beforeProject = fixture.project.toJson();
      final beforeMapData = fixture.mapData.toJson();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      final frameFinder = find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-map-frame'),
      );
      final sceneFrameRect = tester.getRect(frameFinder);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zoom 1.25×'), findsOneWidget);
      final zoomedFrameRect = tester.getRect(frameFinder);
      expect(zoomedFrameRect.width, greaterThan(sceneFrameRect.width));

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-reset')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zoom 1.00×'), findsOneWidget);
      final resetFrameRect = tester.getRect(frameFinder);
      expect(resetFrameRect.width, closeTo(sceneFrameRect.width, 1));
      expect(fixture.project.toJson(), beforeProject);
      expect(fixture.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets('keeps actor placeholders aligned after scene framing zoom', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final tilesetImage = await _makeTestTilesetImage();
    final asset = _actorDisplayPreviewCinematic();
    final project = _project(cinematics: [asset]).copyWith(
      settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'lab_tiles',
          name: 'Lab tiles',
          relativePath: 'assets/tilesets/lab.png',
        ),
      ],
    );
    final stageMapData = _stageMapDataWithActorDisplayFixtures();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: stageMapData,
    );
    final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: stageMapData,
      manifest: project,
      tilesets: {
        'lab_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'lab_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      },
    );
    final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: project,
      stageMap: project.maps.single,
      mapData: stageMapData,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
    );

    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_actor_display_preview'),
      asset: asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: layerPlan,
      actorDisplayPreviewModel: actorDisplayPreviewModel,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
    );
    await tester.pumpAndSettle();

    final mapFrameRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-map-frame')),
    );
    final actorRect = tester.getRect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
      ),
    );
    final expectedAnchor = Offset(
      mapFrameRect.left + (8.5 * mapFrameRect.width / 12),
      mapFrameRect.top + (4 * mapFrameRect.height / 10),
    );
    expect(actorRect.center.dx, closeTo(expectedAnchor.dx, 1));
    expect(actorRect.bottom, closeTo(expectedAnchor.dy, 1));
  });

  test(
    'resolves cinematic backdrop focus from selected actor before fallbacks',
    () {
      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '2 actor(s)',
        actors: [
          _focusPreviewActor('actor_player', x: 1, y: 2),
          _focusPreviewActor('actor_lysa', x: 8, y: 3),
        ],
        diagnostics: const [],
      );
      final selectedStep = _actorDisplayPreviewCinematic()
          .timeline
          .steps
          .firstWhere((step) => step.id == 'step_face_lysa');

      final selectedFocus = resolveCinematicBackdropPreviewFocus(
        mapWidth: 12,
        mapHeight: 10,
        actorDisplayPreviewModel: model,
        selectedStep: selectedStep,
      );
      expect(selectedFocus.reason, 'selectedActor');
      expect(selectedFocus.actorId, 'actor_lysa');
      expect(selectedFocus.tileCenter, const Offset(8.5, 3.5));

      final actorBoundsFocus = resolveCinematicBackdropPreviewFocus(
        mapWidth: 12,
        mapHeight: 10,
        actorDisplayPreviewModel: model,
      );
      expect(actorBoundsFocus.reason, 'actorBounds');
      expect(actorBoundsFocus.tileCenter, const Offset(5, 3));

      final mapCenterFocus = resolveCinematicBackdropPreviewFocus(
        mapWidth: 12,
        mapHeight: 10,
      );
      expect(mapCenterFocus.reason, 'mapCenter');
      expect(mapCenterFocus.tileCenter, const Offset(6, 5));
    },
  );

  testWidgets(
    'renders a larger canvas-first scene preview with compact backdrop chrome',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largeBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();

      final viewportSize = tester.getSize(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
      );
      expect(viewportSize.height, greaterThanOrEqualTo(300));
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-details')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-details-toggle'),
        ),
        findsOneWidget,
      );
      expect(find.text('Carte entière'), findsOneWidget);
      expect(find.text('Vue scène'), findsOneWidget);
      expect(find.text('Déroulé'), findsOneWidget);
      _expectTransportControlsPresent(tester);
    },
  );

  testWidgets(
    'expands and collapses backdrop details without mutating the project',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largeBackdropFixture();
      final beforeProject = fixture.project.toJson();
      final beforeMapData = fixture.mapData.toJson();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();

      final detailsToggle = find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-details-toggle'),
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-details')),
        findsNothing,
      );

      await tester.tap(detailsToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-details')),
        findsOneWidget,
      );
      expect(find.textContaining('55 x 55'), findsWidgets);

      await tester.tap(detailsToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-details')),
        findsNothing,
      );
      expect(fixture.project.toJson(), beforeProject);
      expect(fixture.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets('pans the scene view locally by dragging the backdrop viewport', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _largeBackdropFixture();
    final beforeProject = fixture.project.toJson();
    final beforeMapData = fixture.mapData.toJson();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, fixture.asset.id),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
    );
    await tester.pumpAndSettle();

    final viewportFinder = find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
    );
    final frameFinder = find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-map-frame'),
    );
    final beforeFrame = tester.getRect(frameFinder);

    await tester.drag(viewportFinder, const Offset(-120, -80));
    await tester.pumpAndSettle();

    final afterFrame = tester.getRect(frameFinder);
    expect(afterFrame.left, isNot(closeTo(beforeFrame.left, 0.5)));
    expect(afterFrame.top, isNot(closeTo(beforeFrame.top, 0.5)));
    expect(find.textContaining('Pan'), findsOneWidget);
    expect(fixture.project.toJson(), beforeProject);
    expect(fixture.mapData.toJson(), beforeMapData);
  });

  test('clamps scene view pan in tile units', () {
    final result = resolveCinematicBackdropPreviewFraming(
      viewportSize: const Size(400, 300),
      mapPixelSize: const Size(440, 440),
      mapWidth: 55,
      mapHeight: 55,
      state: const CinematicBackdropPreviewFramingState(
        mode: CinematicBackdropPreviewFramingMode.scene,
        zoom: 2,
        panTiles: Offset(1000, -1000),
      ),
      focus: const CinematicBackdropPreviewFocus(
        tileCenter: Offset(27.5, 27.5),
        reason: 'test clamp',
      ),
    );

    expect(result.panTiles.dx, lessThan(1000));
    expect(result.panTiles.dy, greaterThan(-1000));
    expect(result.transform.frame.left, lessThanOrEqualTo(0));
    expect(result.transform.frame.top, lessThanOrEqualTo(0));
    expect(result.transform.frame.right, greaterThanOrEqualTo(400));
    expect(result.transform.frame.bottom, greaterThanOrEqualTo(300));
  });

  testWidgets(
    'resets scene view pan and zoom without mutating cinematic data',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largeBackdropFixture();
      final beforeProject = fixture.project.toJson();
      final beforeMapData = fixture.mapData.toJson();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      final frameFinder = find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-map-frame'),
      );
      final sceneFrame = tester.getRect(frameFinder);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zoom 1.25×'), findsOneWidget);
      expect(
        tester.getRect(frameFinder).left,
        isNot(closeTo(sceneFrame.left, 1)),
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-reset-view')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zoom 1.00×'), findsOneWidget);
      final resetFrame = tester.getRect(frameFinder);
      expect(resetFrame.left, closeTo(sceneFrame.left, 1));
      expect(resetFrame.top, closeTo(sceneFrame.top, 1));
      expect(fixture.project.toJson(), beforeProject);
      expect(fixture.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets('keeps actor placeholders aligned after scene framing pan', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final tilesetImage = await _makeTestTilesetImage();
    final asset = _actorDisplayPreviewCinematic();
    final project = _project(cinematics: [asset]).copyWith(
      settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'lab_tiles',
          name: 'Lab tiles',
          relativePath: 'assets/tilesets/lab.png',
        ),
      ],
    );
    final stageMapData = _stageMapDataWithActorDisplayFixtures();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: stageMapData,
    );
    final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: stageMapData,
      manifest: project,
      tilesets: {
        'lab_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'lab_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      },
    );
    final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: project,
      stageMap: project.maps.single,
      mapData: stageMapData,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
    );

    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_actor_display_preview'),
      asset: asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: layerPlan,
      actorDisplayPreviewModel: actorDisplayPreviewModel,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
      ),
      const Offset(-100, -60),
    );
    await tester.pumpAndSettle();

    final mapFrameRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-map-frame')),
    );
    final actorRect = tester.getRect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
      ),
    );
    final expectedAnchor = Offset(
      mapFrameRect.left + (8.5 * mapFrameRect.width / 12),
      mapFrameRect.top + (4 * mapFrameRect.height / 10),
    );
    expect(actorRect.center.dx, closeTo(expectedAnchor.dx, 1));
    expect(actorRect.bottom, closeTo(expectedAnchor.dy, 1));
  });

  testWidgets(
    'keeps grid hidden by default in scene view and toggles it locally',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largeBackdropFixture();
      final beforeProject = fixture.project.toJson();
      final beforeMapData = fixture.mapData.toJson();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grille masquée'), findsOneWidget);
      expect(find.text('Grille visible'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-grid-toggle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grille visible'), findsOneWidget);
      expect(fixture.project.toJson(), beforeProject);
      expect(fixture.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'renders extended cinematic map backdrop with terrain path surface and placed elements',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final project = _extendedBackdropProject(
        cinematics: [_stageContextCinematic()],
      );
      final asset = _asset(project, 'cinematic_stage_context');
      final mapData = _stageMapDataWithExtendedBackdrop();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 640,
          height: 360,
        ),
      );
      final layerRenderPlan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: mapData,
        manifest: project,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: layerRenderPlan,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(find.text('Tiles réelles affichées'), findsWidgets);
      expect(find.text('7 couche(s) bitmap'), findsWidgets);
      expect(find.text('Aperçu spatial structurel'), findsNothing);
      expect(find.text('Preview réelle à venir.'), findsNothing);
      expect(find.text('Collision'), findsNothing);
      expect(find.text('Neutral event'), findsNothing);
      _expectTransportControlsPresent(tester);
      expect(
        find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
        findsOneWidget,
      );
    },
  );

  testWidgets('preserves actor display placeholders over extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final tilesetImage = await _makeTestTilesetImage();
    final asset = _actorDisplayPreviewCinematic();
    final project = _project(
      cinematics: [asset],
      characters: const [
        ProjectCharacterEntry(
          id: 'character_lysa',
          name: 'Lysa',
          tilesetId: '',
        ),
      ],
    ).copyWith(
      settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'lab_tiles',
          name: 'Lab tiles',
          relativePath: 'assets/tilesets/lab.png',
        ),
      ],
    );
    final mapData = _stageMapDataWithActorDisplayFixtures();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: mapData,
    );
    final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: mapData,
      manifest: project,
      tilesets: {
        'lab_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'lab_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      },
    );
    final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: project,
      stageMap: project.maps.single,
      mapData: mapData,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
    );

    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_actor_display_preview'),
      asset: asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: layerPlan,
      actorDisplayPreviewModel: actorDisplayPreviewModel,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-actor-display-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
      ),
      findsOneWidget,
    );
    expect(find.text('Placeholders'), findsWidgets);
    expect(find.text('Aperçu statique'), findsWidgets);
  });

  testWidgets('keeps real tile backdrop visible with extended render plan', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final tilesetImage = await _makeTestTilesetImage();
    final project = _project(cinematics: [_stageContextCinematic()]).copyWith(
      settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'lab_tiles',
          name: 'Lab tiles',
          relativePath: 'assets/tilesets/lab.png',
        ),
      ],
    );
    final asset = _asset(project, 'cinematic_stage_context');
    final mapData = _stageMapDataWithBitmapTileLayer();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: mapData,
    );
    final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: mapData,
      manifest: project,
      tilesets: {
        'lab_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'lab_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      },
    );

    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_stage_context'),
      asset: asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: layerPlan,
    );

    expect(layerPlan.instructions, hasLength(2));
    expect(find.text('Tiles réelles affichées'), findsWidgets);
    expect(find.text('2 couche(s) bitmap'), findsWidgets);
    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
      findsOneWidget,
    );
  });

  test(
    'shows partial backdrop diagnostics for missing visual families',
    () async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final project = _project(cinematics: [_stageContextCinematic()]).copyWith(
        settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
        tilesets: const [
          ProjectTilesetEntry(
            id: 'neutral_tiles',
            name: 'Neutral tiles',
            relativePath: 'assets/tilesets/neutral.png',
          ),
        ],
      );
      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: _stageMapDataWithExtendedBackdrop(),
        manifest: project,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      expect(plan.hasBitmapInstructions, isTrue);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'missingTerrainPreset',
          'missingPathPreset',
          'missingSurfaceVisual',
          'missingPlacedElement',
        ]),
      );
    },
  );

  testWidgets('keeps transport controls disabled with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _extendedBackdropFixture();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, 'cinematic_stage_context'),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    _expectTransportControlsPresent(tester);
  });

  testWidgets('keeps timeline visible with extended backdrop', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _extendedBackdropFixture();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, 'cinematic_stage_context'),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
      findsOneWidget,
    );
    expect(find.text('Déroulé'), findsOneWidget);
  });

  testWidgets('keeps duration editor working with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final asset = _stageDurationCinematic(
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
      ),
    );
    final fixture = await _extendedBackdropFixture(asset: asset);
    var latestProject = fixture.project;

    await _pumpBuilderHarness(
      tester,
      fixture.project,
      'cinematic_stage_duration',
      onProjectChanged: (project) => latestProject = project,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '700');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_stage_duration',
      ).timeline.steps.singleWhere((step) => step.id == 'step_face').durationMs,
      700,
    );
  });

  testWidgets('keeps resize handle working with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final asset = _stageDurationCinematic(
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
      ),
    );
    final fixture = await _extendedBackdropFixture(asset: asset);
    var latestProject = fixture.project;

    await _pumpBuilderHarness(
      tester,
      fixture.project,
      'cinematic_stage_duration',
      onProjectChanged: (project) => latestProject = project,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(90, 0),
    );
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_stage_duration',
      ).timeline.steps.singleWhere((step) => step.id == 'step_face').durationMs,
      greaterThan(500),
    );
  });

  testWidgets('keeps mouse probe working with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final asset = _stageDurationCinematic(
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
      ),
    );
    final fixture = await _extendedBackdropFixture(asset: asset);

    await _pumpBuilderHarness(
      tester,
      fixture.project,
      'cinematic_stage_duration',
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final probeX = tick0Rect.left + (tick500Rect.left - tick0Rect.left) * 0.5;
    await _placeTimelineProbeAt(tester, Offset(probeX, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsOneWidget,
    );
  });

  testWidgets('keeps mapEntity actor picker working with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final fixture = await _extendedBackdropFixture();
    var latestProject = fixture.project;

    await _pumpBuilderHarness(
      tester,
      fixture.project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    final mapEntityButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity',
      ),
    );
    await tester.ensureVisible(mapEntityButton);
    await tester.tap(mapEntityButton);
    await tester.pumpAndSettle();
    final sourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity-source-entity_professor',
      ),
    );
    await tester.ensureVisible(sourceButton);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    expect(binding?.kind, CinematicActorBindingKind.mapEntity);
    expect(binding?.mapEntityId, 'entity_professor');
  });

  testWidgets(
    'keeps movement target mapEntity/mapEvent pickers working with extended backdrop',
    (tester) async {
      _setLargeSurface(tester);
      final fixture = await _extendedBackdropFixture();
      var latestProject = fixture.project;

      await _pumpBuilderHarness(
        tester,
        fixture.project,
        'cinematic_stage_context',
        onProjectChanged: (project) => latestProject = project,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
      );

      final mapEntityButton = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEntity',
        ),
      );
      await tester.ensureVisible(mapEntityButton);
      await tester.tap(mapEntityButton);
      await tester.pumpAndSettle();
      final entitySourceButton = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEntity-source-entity_professor',
        ),
      );
      await tester.ensureVisible(entitySourceButton);
      await tester.tap(entitySourceButton);
      await tester.pumpAndSettle();

      var binding = _asset(latestProject, 'cinematic_stage_context')
          .stageContext
          ?.movementTargetBindings
          .singleWhere((binding) => binding.targetId == 'target_center');
      expect(binding?.kind, CinematicMovementTargetBindingKind.mapEntity);
      expect(binding?.sourceId, 'entity_professor');

      final mapEventButton = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEvent',
        ),
      );
      await tester.ensureVisible(mapEventButton);
      await tester.tap(mapEventButton);
      await tester.pumpAndSettle();
      final eventSourceButton = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEvent-source-neutral_event',
        ),
      );
      await tester.ensureVisible(eventSourceButton);
      await tester.tap(eventSourceButton);
      await tester.pumpAndSettle();

      binding = _asset(latestProject, 'cinematic_stage_context')
          .stageContext
          ?.movementTargetBindings
          .singleWhere((binding) => binding.targetId == 'target_center');
      expect(binding?.kind, CinematicMovementTargetBindingKind.mapEvent);
      expect(binding?.sourceId, 'neutral_event');
    },
  );

  testWidgets('keeps Character Library picker working with extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final asset = CinematicAsset(
      id: 'cinematic_character_extended_picker',
      title: 'Character picker extended cinematic',
      mapId: 'map_lab',
      requiredActors: [
        CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
      ],
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor_rival',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
        ],
      ),
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'step_wait',
            kind: CinematicTimelineStepKind.wait,
            label: 'Opening wait',
            durationMs: 500,
          ),
        ],
      ),
    );
    final project = _extendedBackdropProject(cinematics: [asset]).copyWith(
      characters: const [
        ProjectCharacterEntry(
          id: 'character_rival',
          name: 'Rival',
          tilesetId: 'characters/rival',
          frameWidth: 32,
          frameHeight: 32,
          tags: ['rival', 'cinematic'],
        ),
      ],
    );
    final fixture = await _extendedBackdropFixture(
      asset: asset,
      project: project,
    );
    var latestProject = fixture.project;

    await _pumpBuilderHarness(
      tester,
      fixture.project,
      'cinematic_character_extended_picker',
      onProjectChanged: (project) => latestProject = project,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    final chooseButton = find.byKey(
      const ValueKey(
        'cinematic-builder-character-appearance-actor_rival-toggle',
      ),
    );
    await tester.ensureVisible(chooseButton);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();
    final rivalOption = find.byKey(
      const ValueKey(
        'cinematic-builder-character-appearance-actor_rival-character-character_rival',
      ),
    );
    await tester.ensureVisible(rivalOption);
    await tester.tap(rivalOption);
    await tester.pumpAndSettle();

    final context = _asset(
      latestProject,
      'cinematic_character_extended_picker',
    ).stageContext;
    expect(
      context?.actorAppearanceBindings.single.characterId,
      'character_rival',
    );
  });

  test(
    'does not render runtime entities events triggers collisions or warps',
    () async {
      final fixture = await _extendedBackdropFixture();

      expect(
        fixture.layerPlan.instructions.map(
          (instruction) => instruction.sourceFamily,
        ),
        isNot(contains('event')),
      );
      expect(
        fixture.layerPlan.instructions.map(
          (instruction) => instruction.sourceFamily,
        ),
        isNot(contains('collision')),
      );
      expect(
        fixture.layerPlan.instructions.map(
          (instruction) => instruction.sourceFamily,
        ),
        isNot(contains('trigger')),
      );
      expect(
        fixture.layerPlan.instructions.map(
          (instruction) => instruction.sourceFamily,
        ),
        isNot(contains('warp')),
      );
    },
  );

  testWidgets('does not mutate project when rendering extended backdrop', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _extendedBackdropFixture();
    final beforeProject = fixture.project.toJson();
    final beforeMapData = fixture.mapData.toJson();

    await _pumpBuilder(
      tester,
      _entry(fixture.project, 'cinematic_stage_context'),
      asset: fixture.asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      backdropPreviewModel: fixture.backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
    );

    expect(fixture.project.toJson(), beforeProject);
    expect(fixture.mapData.toJson(), beforeMapData);
  });

  testWidgets('shows human fallbacks for every non available backdrop status', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final baseAsset = _stageContextCinematic();
    final stageMapData = _stageMapDataWithVisualLayers();
    final mismatchedMapData = stageMapData.copyWith(id: 'map_other');
    final disabledAsset = _stageContextCinematic(
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.none,
      ),
    );
    final missingMapAsset = _stageContextCinematic(mapId: null);
    final unknownMapAsset = _stageContextCinematic(mapId: 'map_missing');

    final scenarios = <({
      CinematicAsset asset,
      ProjectMapEntry? stageMap,
      MapData? mapData,
      Set<String>? availableTilesetIds,
      String title,
      String message,
    })>[
      (
        asset: disabledAsset,
        stageMap: const ProjectMapEntry(
          id: 'map_lab',
          name: 'Lab map',
          relativePath: 'lab.json',
        ),
        mapData: stageMapData,
        availableTilesetIds: null,
        title: 'Décor désactivé',
        message: 'Décor de map désactivé pour cette cinématique.',
      ),
      (
        asset: missingMapAsset,
        stageMap: null,
        mapData: null,
        availableTilesetIds: null,
        title: 'Map de scène requise',
        message: 'Choisis une map de scène pour afficher le décor.',
      ),
      (
        asset: unknownMapAsset,
        stageMap: null,
        mapData: null,
        availableTilesetIds: null,
        title: 'Map introuvable',
        message: 'La map de scène n’existe plus dans le projet.',
      ),
      (
        asset: baseAsset,
        stageMap: const ProjectMapEntry(
          id: 'map_lab',
          name: 'Lab map',
          relativePath: 'lab.json',
        ),
        mapData: null,
        availableTilesetIds: null,
        title: 'Données map indisponibles',
        message:
            'Les données de cette map ne sont pas disponibles pour la preview.',
      ),
      (
        asset: baseAsset,
        stageMap: const ProjectMapEntry(
          id: 'map_lab',
          name: 'Lab map',
          relativePath: 'lab.json',
        ),
        mapData: mismatchedMapData,
        availableTilesetIds: null,
        title: 'Données map invalides',
        message: 'La map chargée ne correspond pas à la map de scène.',
      ),
      (
        asset: baseAsset,
        stageMap: const ProjectMapEntry(
          id: 'map_lab',
          name: 'Lab map',
          relativePath: 'lab.json',
        ),
        mapData: stageMapData,
        availableTilesetIds: {'other_tileset'},
        title: 'Tileset indisponible',
        message:
            'Le tileset de cette map n’est pas disponible pour la preview.',
      ),
    ];

    for (final scenario in scenarios) {
      final project = _project(cinematics: [scenario.asset]);
      final before = project.toJson();
      final beforeMapData = scenario.mapData?.toJson();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: scenario.asset,
        stageMap: scenario.stageMap,
        mapData: scenario.mapData,
        availableTilesetIds: scenario.availableTilesetIds,
      );

      await _pumpBuilder(
        tester,
        _entry(project, scenario.asset.id),
        asset: scenario.asset,
        backdropPreviewModel: backdropModel,
        provideStageMapSourceCatalog: false,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-fallback')),
        findsOneWidget,
      );
      expect(find.text(scenario.title), findsWidgets);
      expect(find.text(scenario.message), findsWidgets);
      expect(find.textContaining('{'), findsNothing);
      expect(find.textContaining('}'), findsNothing);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(project.toJson(), before);
      if (beforeMapData != null) {
        expect(scenario.mapData!.toJson(), beforeMapData);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets(
    'shows human fallback when static map backdrop data is unavailable',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_stageContextCinematic()]);
      final before = project.toJson();
      final asset = _asset(project, 'cinematic_stage_context');
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: null,
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        backdropPreviewModel: backdropModel,
        provideStageMapSourceCatalog: false,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-fallback')),
        findsOneWidget,
      );
      expect(find.text('Données map indisponibles'), findsOneWidget);
      expect(
        find.text(
          'Les données de cette map ne sont pas disponibles pour la preview.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      _expectTransportControlsPresent(tester);

      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'shows honest structural fallback when no spatial primitives exist',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_stageContextCinematic()]);
      final before = project.toJson();
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapData();
      final beforeMapData = stageMapData.toJson();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
      expect(find.text('Aucune couche visuelle lisible.'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        ),
        findsNothing,
      );
      expect(find.text('Aperçu sandbox'), findsNothing);
      expect(find.text('Professor Oak'), findsNothing);
      expect(find.text('Gate bell'), findsNothing);
      expect(project.toJson(), before);
      expect(stageMapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'shows sandbox-only readiness before stage context is configured',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_stageSandboxOnlyCinematic()]);
      await _pumpBuilderHarness(tester, project, 'cinematic_stage_sandbox');

      final stateTile = find.text('État de la scène');
      await tester.ensureVisible(stateTile);
      await tester.tap(stateTile);
      await tester.pumpAndSettle();

      expect(find.text('Préparation preview'), findsOneWidget);
      expect(find.text('Aperçu uniquement'), findsWidgets);
      expect(find.textContaining('Ajoute un contexte de scène'), findsWidgets);
      expect(
        find.textContaining('La preview réelle arrivera plus tard.'),
        findsWidgets,
      );
    },
  );

  testWidgets('shows blocked readiness with human stage diagnostic messages', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageUnknownMapCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    final stateTile = find.text('État de la scène');
    await tester.ensureVisible(stateTile);
    await tester.tap(stateTile);
    await tester.pumpAndSettle();

    expect(find.text('Préparation preview'), findsOneWidget);
    expect(find.text('À corriger'), findsWidgets);
    expect(
      find.textContaining('La map de scène n’existe plus dans le projet.'),
      findsWidgets,
    );
    expect(find.text('Diagnostics stage'), findsOneWidget);
    expect(find.text('stageMapUnknown'), findsWidgets);
    expect(find.textContaining('Impossible'), findsNothing);
    expect(find.textContaining('Non supporté définitivement'), findsNothing);
  });

  testWidgets('shows ready readiness for complete stage context', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageReadyCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_ready');

    final stateTile = find.text('État de la scène');
    await tester.ensureVisible(stateTile);
    await tester.tap(stateTile);
    await tester.pumpAndSettle();

    expect(find.text('Préparation preview'), findsOneWidget);
    expect(find.text('Prêt'), findsWidgets);
    expect(find.textContaining('Map de scène — OK : Lab map'), findsWidgets);
    expect(
      find.textContaining('Décor — OK : décor depuis la map'),
      findsWidgets,
    );
    expect(find.textContaining('Acteurs liés — OK'), findsWidgets);
    expect(find.textContaining('Départs de scène — OK'), findsWidgets);
    expect(find.textContaining('Destinations — OK'), findsWidgets);
    expect(
      find.textContaining(
        'Sources de la map — OK : aucune source de la map requise',
      ),
      findsWidgets,
    );
    expect(
      find.textContaining('La preview réelle arrivera plus tard.'),
      findsWidgets,
    );
    expect(find.text('Lecture en cours'), findsNothing);
  });

  testWidgets('clears cinematic stage map from builder', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final dropdownButton = find.byKey(
      const ValueKey('cinematic-builder-stage-map-dropdown'),
    );
    await tester.ensureVisible(dropdownButton);
    await tester.tap(dropdownButton);
    await tester.pumpAndSettle();

    final clearButton = find.byKey(
      const ValueKey('cinematic-builder-clear-stage-map'),
    );
    await tester.ensureVisible(clearButton);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    final updated = _asset(latestProject, 'cinematic_stage_context');
    expect(updated.mapId, isNull);
    expect(
      updated.stageContext?.backdropMode,
      CinematicStageBackdropMode.projectMap,
    );
    expect(find.text('Aucune map'), findsWidgets);
    final stateTile = find.text('État de la scène');
    await tester.ensureVisible(stateTile);
    await tester.tap(stateTile);
    await tester.pumpAndSettle();
    expect(
      find.text('Choisissez une map avant d’utiliser un décor de map.'),
      findsWidgets,
    );
  });

  testWidgets('switches backdrop mode without duplicating map id', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        _stageContextCinematic(
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.none,
          ),
        ),
      ],
    );
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final backdropDropdown = find.byKey(
      const ValueKey('cinematic-builder-backdrop-dropdown'),
    );
    await tester.ensureVisible(backdropDropdown);
    await tester.tap(backdropDropdown);
    await tester.pumpAndSettle();

    final projectMapButton = find.byKey(
      const ValueKey('cinematic-builder-backdrop-projectMap'),
    );
    await tester.ensureVisible(projectMapButton);
    await tester.tap(projectMapButton);
    await tester.pumpAndSettle();

    await tester.ensureVisible(backdropDropdown);
    await tester.tap(backdropDropdown);
    await tester.pumpAndSettle();

    final noneButton = find.byKey(
      const ValueKey('cinematic-builder-backdrop-none'),
    );
    await tester.ensureVisible(noneButton);
    await tester.tap(noneButton);
    await tester.pumpAndSettle();

    final updated = _asset(latestProject, 'cinematic_stage_context');
    expect(updated.mapId, 'map_lab');
    expect(updated.stageContext?.backdropMode, CinematicStageBackdropMode.none);
    expect(updated.stageContext?.toJson(), isNot(contains('mapId')));
  });

  testWidgets('shows actor binding section for required actors', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('Acteurs'), findsWidgets);
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Binding'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey(
          'cinematic-builder-actor-binding-actor_professor-player',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('binds actor to player', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final playerButton = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-player'),
    );
    await tester.ensureVisible(playerButton);
    await tester.tap(playerButton);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    expect(binding?.kind, CinematicActorBindingKind.player);
  });

  testWidgets('binds actor to selected map entity through stage source picker',
      (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final mapEntityButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity',
      ),
    );
    await tester.ensureVisible(mapEntityButton);
    await tester.tap(mapEntityButton);
    await tester.pumpAndSettle();

    final sourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity-source-entity_professor',
      ),
    );
    await tester.ensureVisible(sourceButton);
    expect(find.text('Professor Oak'), findsWidgets);
    expect(find.textContaining('PNJ'), findsWidgets);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    expect(binding?.kind, CinematicActorBindingKind.mapEntity);
    expect(binding?.mapEntityId, 'entity_professor');
  });

  testWidgets('prevents duplicate player binding', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextTwoActorsCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_two_actors',
      onProjectChanged: (project) => latestProject = project,
    );

    final professorPlayer = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-player'),
    );
    await tester.ensureVisible(professorPlayer);
    await tester.tap(professorPlayer);
    await tester.pumpAndSettle();

    final assistantPlayer = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_assistant-player'),
    );
    await tester.ensureVisible(assistantPlayer);
    final button = tester.widget<PokeMapButton>(assistantPlayer);
    expect(button.onPressed, isNull);
    expect(
      find.text('Un autre acteur est déjà lié au joueur.'),
      findsOneWidget,
    );
    expect(
      _asset(latestProject, 'cinematic_stage_two_actors')
          .stageContext
          ?.actorBindings
          .where((binding) => binding.kind == CinematicActorBindingKind.player)
          .length,
      1,
    );
  });

  testWidgets('binds actor to cinematic only', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-cinematicOnly',
      ),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    expect(binding?.kind, CinematicActorBindingKind.cinematicOnly);
  });

  testWidgets('selects character library entry for cinematic only actor', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      characters: const [
        ProjectCharacterEntry(
          id: 'character_rival',
          name: 'Rival',
          tilesetId: 'characters/rival',
          frameWidth: 32,
          frameHeight: 32,
          tags: ['rival', 'cinematic'],
        ),
      ],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_character_picker',
          title: 'Character picker cinematic',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Opening wait',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
    );
    var latestProject = project;
    final beforeSteps = _asset(
      project,
      'cinematic_character_picker',
    ).timeline.toJson();
    final beforeRequiredActors = _asset(
      project,
      'cinematic_character_picker',
    ).requiredActors;
    final beforeDuration = _entry(
      project,
      'cinematic_character_picker',
    ).timeline.estimatedDurationMs;

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_character_picker',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(find.text('Apparence'), findsWidgets);
    expect(find.text('Aucun personnage choisi.'), findsOneWidget);
    final chooseButton = find.byKey(
      const ValueKey(
        'cinematic-builder-character-appearance-actor_rival-toggle',
      ),
    );
    await tester.ensureVisible(chooseButton);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(find.text('Rival'), findsWidgets);
    expect(find.text('characters/rival · 32×32'), findsWidgets);
    expect(find.textContaining('rival · cinematic'), findsWidgets);
    final rivalOption = find.byKey(
      const ValueKey(
        'cinematic-builder-character-appearance-actor_rival-character-character_rival',
      ),
    );
    await tester.ensureVisible(rivalOption);
    await tester.tap(rivalOption);
    await tester.pumpAndSettle();

    final updated = _asset(latestProject, 'cinematic_character_picker');
    final context = updated.stageContext;
    expect(context?.actorAppearanceBindings.single.actorId, 'actor_rival');
    expect(
      context?.actorAppearanceBindings.single.characterId,
      'character_rival',
    );
    expect(
      context?.actorBindings.single.toJson(),
      isNot(contains('characterId')),
    );
    expect(updated.requiredActors, beforeRequiredActors);
    expect(updated.timeline.toJson(), beforeSteps);
    expect(
      _entry(
        latestProject,
        'cinematic_character_picker',
      ).timeline.estimatedDurationMs,
      beforeDuration,
    );
    _expectTransportControlsPresent(tester);
  });

  testWidgets(
    'keeps Character Library picker working with map backdrop visible',
    (tester) async {
      _setLargeSurface(tester);
      final asset = CinematicAsset(
        id: 'cinematic_character_backdrop_picker',
        title: 'Character picker backdrop cinematic',
        mapId: 'map_lab',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
        ],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_rival',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              label: 'Opening wait',
              durationMs: 500,
            ),
          ],
        ),
      );
      final project = _project(
        characters: const [
          ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: 'characters/rival',
            frameWidth: 32,
            frameHeight: 32,
            tags: ['rival', 'cinematic'],
          ),
        ],
        cinematics: [asset],
        includeBridge: false,
      );
      var latestProject = project;
      final stageMapData = _stageMapDataWithVisualLayers();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_character_backdrop_picker',
        onProjectChanged: (project) => latestProject = project,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
      final chooseButton = find.byKey(
        const ValueKey(
          'cinematic-builder-character-appearance-actor_rival-toggle',
        ),
      );
      await tester.ensureVisible(chooseButton);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      final rivalOption = find.byKey(
        const ValueKey(
          'cinematic-builder-character-appearance-actor_rival-character-character_rival',
        ),
      );
      await tester.ensureVisible(rivalOption);
      await tester.tap(rivalOption);
      await tester.pumpAndSettle();

      final context = _asset(
        latestProject,
        'cinematic_character_backdrop_picker',
      ).stageContext;
      expect(context?.actorAppearanceBindings.single.actorId, 'actor_rival');
      expect(
        context?.actorAppearanceBindings.single.characterId,
        'character_rival',
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows empty character library message for cinematic only actor',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_empty_character_library',
            title: 'Empty Character Library',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
            ),
            timeline: CinematicTimeline(),
          ),
        ],
        includeBridge: false,
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_empty_character_library',
      );

      expect(find.text('Apparence'), findsWidgets);
      expect(find.text('La Character Library est vide.'), findsOneWidget);
      expect(
        find.text(
          'Crée un personnage dans la Character Library pour l’utiliser ici.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'cinematic-builder-character-appearance-actor_rival-toggle',
          ),
        ),
        findsNothing,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('keeps appearance picker disabled for inherited actor bindings', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      characters: const [
        ProjectCharacterEntry(
          id: 'character_rival',
          name: 'Rival',
          tilesetId: 'characters/rival',
        ),
      ],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_inherited_appearances',
          title: 'Inherited appearances',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_player', label: 'Player actor'),
            CinematicActorRef(actorId: 'actor_npc', label: 'NPC actor'),
            CinematicActorRef(actorId: 'actor_free', label: 'Free actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_player',
                kind: CinematicActorBindingKind.player,
              ),
              CinematicActorBinding(
                actorId: 'actor_npc',
                kind: CinematicActorBindingKind.mapEntity,
                mapEntityId: 'entity_professor',
              ),
              CinematicActorBinding(
                actorId: 'actor_free',
                kind: CinematicActorBindingKind.unbound,
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_inherited_appearances',
    );

    expect(find.text('Apparence héritée du joueur.'), findsOneWidget);
    expect(find.text('Apparence héritée de l’entité de map.'), findsOneWidget);
    expect(
      find.text(
        'Lie d’abord l’acteur en Cinématique uniquement pour choisir un personnage.',
      ),
      findsOneWidget,
    );
    for (final actorId in <String>['actor_player', 'actor_npc', 'actor_free']) {
      expect(
        find.byKey(
          ValueKey<String>(
            'cinematic-builder-character-appearance-$actorId-toggle',
          ),
        ),
        findsNothing,
      );
    }
  });

  testWidgets(
    'shows incompatible character appearance drift when actor is no longer cinematic only',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        characters: const [
          ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: 'characters/rival',
            frameWidth: 32,
            frameHeight: 32,
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_incompatible_character_appearance',
            title: 'Incompatible character appearance',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.player,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_rival',
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  label: 'Opening wait',
                  durationMs: 500,
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      );
      var latestProject = project;
      final beforeActorBindings = _asset(
        project,
        'cinematic_incompatible_character_appearance',
      ).stageContext?.actorBindings.map((binding) => binding.toJson()).toList();
      final beforeTimeline = _asset(
        project,
        'cinematic_incompatible_character_appearance',
      ).timeline.toJson();
      final beforeDuration = _entry(
        project,
        'cinematic_incompatible_character_appearance',
      ).timeline.estimatedDurationMs;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_incompatible_character_appearance',
        onProjectChanged: (project) => latestProject = project,
      );

      expect(
        find.text('Cet acteur n’est plus en “Cinématique uniquement”.'),
        findsOneWidget,
      );
      expect(
        find.text('L’apparence Character Library ne s’applique plus.'),
        findsOneWidget,
      );
      expect(find.text('Retirer l’apparence'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'cinematic-builder-character-appearance-actor_rival-toggle',
          ),
        ),
        findsNothing,
      );

      _expectTransportControlsPresent(tester);

      final clearButton = find.byKey(
        const ValueKey(
          'cinematic-builder-character-appearance-actor_rival-clear',
        ),
      );
      await tester.ensureVisible(clearButton);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      final updatedAsset = _asset(
        latestProject,
        'cinematic_incompatible_character_appearance',
      );
      expect(updatedAsset.stageContext?.actorAppearanceBindings, isEmpty);
      expect(
        updatedAsset.stageContext?.actorBindings
            .map((binding) => binding.toJson())
            .toList(),
        beforeActorBindings,
      );
      expect(updatedAsset.timeline.toJson(), beforeTimeline);
      expect(
        _entry(
          latestProject,
          'cinematic_incompatible_character_appearance',
        ).timeline.estimatedDurationMs,
        beforeDuration,
      );
    },
  );

  testWidgets(
    'shows orphan actor appearance binding and cleans it explicitly',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        characters: const [
          ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: 'characters/rival',
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_orphan_character_appearance',
            title: 'Orphan character appearance',
            mapId: 'map_lab',
            stageContext: CinematicStageContext(
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_deleted',
                  characterId: 'character_rival',
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  label: 'Opening wait',
                  durationMs: 500,
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      );
      var latestProject = project;
      final beforeTimeline = _asset(
        project,
        'cinematic_orphan_character_appearance',
      ).timeline.toJson();

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_orphan_character_appearance',
        onProjectChanged: (project) => latestProject = project,
      );

      expect(
        find.text('Une apparence référence un acteur supprimé.'),
        findsWidgets,
      );
      expect(find.text('Acteur référencé : actor_deleted'), findsOneWidget);
      expect(
        find.text('Personnage référencé : character_rival'),
        findsOneWidget,
      );
      expect(find.text('Nettoyer la référence'), findsOneWidget);

      final clearButton = find.byKey(
        const ValueKey(
          'cinematic-builder-character-appearance-actor_deleted-clear',
        ),
      );
      await tester.ensureVisible(clearButton);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      final updatedAsset = _asset(
        latestProject,
        'cinematic_orphan_character_appearance',
      );
      expect(updatedAsset.stageContext?.actorAppearanceBindings, isEmpty);
      expect(updatedAsset.timeline.toJson(), beforeTimeline);
    },
  );

  testWidgets('clears broken character library reference explicitly', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      characters: const [
        ProjectCharacterEntry(
          id: 'character_rival',
          name: 'Rival',
          tilesetId: 'characters/rival',
        ),
      ],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_broken_character_reference',
          title: 'Broken character reference',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_deleted',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    var latestProject = project;

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_broken_character_reference',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(
      find.text(
        'Le personnage choisi n’existe plus dans la Character Library.',
      ),
      findsWidgets,
    );
    expect(find.text('Choisir un autre personnage'), findsOneWidget);
    final clearButton = find.byKey(
      const ValueKey(
        'cinematic-builder-character-appearance-actor_rival-clear',
      ),
    );
    await tester.ensureVisible(clearButton);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_broken_character_reference',
      ).stageContext?.actorAppearanceBindings,
      isEmpty,
    );
    expect(find.text('Aucun personnage choisi.'), findsOneWidget);
  });

  testWidgets('updates readiness for cinematic only character appearances', (
    tester,
  ) async {
    const readyCharacter = ProjectCharacterEntry(
      id: 'character_rival',
      name: 'Rival',
      tilesetId: 'characters/rival',
      frameWidth: 32,
      frameHeight: 32,
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.south,
          frames: [
            CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    );
    CinematicStagePreviewReadinessItem appearanceItem(
      ProjectManifest project,
      String cinematicId,
    ) {
      final asset = _asset(project, cinematicId);
      final readiness = buildCinematicStagePreviewReadiness(
        asset: asset,
        entry: _entry(project, cinematicId),
        maps: project.maps,
        characters: project.characters,
        stageMapSourceCatalog: _stageMapSourceCatalog(),
      );
      return readiness.items.singleWhere(
        (item) => item.label == 'Apparences acteurs',
      );
    }

    final missingProject = _project(
      characters: const [readyCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_missing_character',
          title: 'Missing character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(missingProject, 'cinematic_missing_character').kind,
      CinematicStagePreviewReadinessItemKind.incomplete,
    );
    expect(
      appearanceItem(missingProject, 'cinematic_missing_character').message,
      'Rival actor n’a pas encore de personnage.',
    );

    final brokenProject = _project(
      characters: const [readyCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_unknown_character',
          title: 'Unknown character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_deleted',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(brokenProject, 'cinematic_unknown_character').kind,
      CinematicStagePreviewReadinessItemKind.blocking,
    );
    expect(
      appearanceItem(brokenProject, 'cinematic_unknown_character').message,
      'Rival actor pointe vers un personnage absent.',
    );

    final incompatibleProject = _project(
      characters: const [readyCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_incompatible_character',
          title: 'Incompatible character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.player,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_rival',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(
        incompatibleProject,
        'cinematic_incompatible_character',
      ).kind,
      CinematicStagePreviewReadinessItemKind.blocking,
    );
    expect(
      appearanceItem(
        incompatibleProject,
        'cinematic_incompatible_character',
      ).message,
      'Rival actor n’est plus en Cinématique uniquement.',
    );

    final orphanProject = _project(
      characters: const [readyCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_orphan_character',
          title: 'Orphan character',
          mapId: 'map_lab',
          stageContext: CinematicStageContext(
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_deleted',
                characterId: 'character_rival',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(orphanProject, 'cinematic_orphan_character').kind,
      CinematicStagePreviewReadinessItemKind.blocking,
    );
    expect(
      appearanceItem(orphanProject, 'cinematic_orphan_character').message,
      'Une apparence référence un acteur supprimé.',
    );

    const missingSpriteCharacter = ProjectCharacterEntry(
      id: 'character_rival',
      name: 'Rival',
      tilesetId: '',
      frameWidth: 32,
      frameHeight: 32,
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.south,
          frames: [
            CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    );
    final missingSpriteProject = _project(
      characters: const [missingSpriteCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_missing_sprite_character',
          title: 'Missing sprite character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_rival',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(
        missingSpriteProject,
        'cinematic_missing_sprite_character',
      ).message,
      'Rival utilise un personnage sans sprite preview.',
    );

    const missingPreviewDataCharacter = ProjectCharacterEntry(
      id: 'character_rival',
      name: 'Rival',
      tilesetId: 'characters/rival',
      frameWidth: 32,
      frameHeight: 32,
    );
    final missingPreviewDataProject = _project(
      characters: const [missingPreviewDataCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_missing_preview_character',
          title: 'Missing preview character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_rival',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    expect(
      appearanceItem(
        missingPreviewDataProject,
        'cinematic_missing_preview_character',
      ).message,
      'Rival n’a pas encore d’animation idle pour la future preview.',
    );

    final readyProject = _project(
      characters: const [readyCharacter],
      cinematics: [
        CinematicAsset(
          id: 'cinematic_ready_character',
          title: 'Ready character',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_rival',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    final readyItem = appearanceItem(readyProject, 'cinematic_ready_character');
    expect(readyItem.kind, CinematicStagePreviewReadinessItemKind.ok);
    expect(readyItem.message, 'personnages de cinématique prêts');
  });

  testWidgets('binds actor to unbound', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-unbound'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    expect(binding?.kind, CinematicActorBindingKind.unbound);
  });

  testWidgets(
    'shows map entity binding option disabled when no stage map is selected',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        cinematics: [_stageContextCinematic(mapId: null)],
      );
      await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

      final button = find.byKey(
        const ValueKey(
          'cinematic-builder-actor-binding-actor_professor-mapEntity',
        ),
      );
      await tester.ensureVisible(button);
      expect(tester.widget<PokeMapButton>(button).onPressed, isNull);
      expect(find.text('Choisissez d’abord une map de scène.'), findsWidgets);
    },
  );

  testWidgets(
    'shows honest disabled message when map entities/events are unavailable',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_stageContextCinematic()]);
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_context',
        provideStageMapSourceCatalog: false,
      );

      final actorMapEntity = find.byKey(
        const ValueKey(
          'cinematic-builder-actor-binding-actor_professor-mapEntity',
        ),
      );
      await tester.ensureVisible(actorMapEntity);
      expect(tester.widget<PokeMapButton>(actorMapEntity).onPressed, isNull);
      expect(
        find.text(
          'Catalogue des personnages/déclencheurs de la map en cours de chargement.',
        ),
        findsWidgets,
      );

      final targetMapEvent = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEvent',
        ),
      );
      await tester.ensureVisible(targetMapEvent);
      expect(tester.widget<PokeMapButton>(targetMapEvent).onPressed, isNull);
      expect(
        find.text(
          'Catalogue des personnages/déclencheurs de la map en cours de chargement.',
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('shows initial placement section', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('Départs de scène'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'cinematic-builder-initial-placement-actor_professor-unset',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sets initial placement to unset', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey(
        'cinematic-builder-initial-placement-actor_professor-unset',
      ),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final placement = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.initialPlacements
        .singleWhere((placement) => placement.actorId == 'actor_professor');
    expect(placement?.kind, CinematicActorInitialPlacementKind.unset);
  });

  testWidgets('sets initial placement from movement target', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final placementButton = find.byKey(
      const ValueKey(
        'cinematic-builder-initial-placement-actor_professor-fromMovementTarget',
      ),
    );
    await tester.ensureVisible(placementButton);
    await tester.tap(placementButton);
    await tester.pumpAndSettle();
    final targetButton = find.byKey(
      const ValueKey(
        'cinematic-builder-initial-placement-actor_professor-target-target_center',
      ),
    );
    await tester.ensureVisible(targetButton);
    await tester.tap(targetButton);
    await tester.pumpAndSettle();

    final placement = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.initialPlacements
        .singleWhere((placement) => placement.actorId == 'actor_professor');
    expect(
      placement?.kind,
      CinematicActorInitialPlacementKind.fromMovementTarget,
    );
    expect(placement?.targetId, 'target_center');
  });

  testWidgets(
    'sets initial placement from map entity only when actor binding supports it',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        cinematics: [
          _stageContextCinematic(
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_professor',
                  kind: CinematicActorBindingKind.mapEntity,
                  mapEntityId: 'entity_professor',
                ),
              ],
            ),
          ),
        ],
      );
      var latestProject = project;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_context',
        onProjectChanged: (project) => latestProject = project,
      );

      final button = find.byKey(
        const ValueKey(
          'cinematic-builder-initial-placement-actor_professor-fromMapEntity',
        ),
      );
      await tester.ensureVisible(button);
      expect(tester.widget<PokeMapButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();

      final placement = _asset(latestProject, 'cinematic_stage_context')
          .stageContext
          ?.initialPlacements
          .singleWhere((placement) => placement.actorId == 'actor_professor');
      expect(placement?.kind, CinematicActorInitialPlacementKind.fromMapEntity);
    },
  );

  testWidgets('shows movement target binding section', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('Destinations'), findsWidgets);
    expect(find.text('Centre scène'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-abstractPoint',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sets movement target binding to abstract point', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-abstractPoint',
      ),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.movementTargetBindings
        .singleWhere((binding) => binding.targetId == 'target_center');
    expect(binding?.kind, CinematicMovementTargetBindingKind.abstractPoint);
    expect(binding?.sourceId, isNull);
  });

  testWidgets('binds movement target to selected map entity source', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final mapEntityButton = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-mapEntity',
      ),
    );
    await tester.ensureVisible(mapEntityButton);
    await tester.tap(mapEntityButton);
    await tester.pumpAndSettle();

    final sourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-mapEntity-source-entity_professor',
      ),
    );
    await tester.ensureVisible(sourceButton);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.movementTargetBindings
        .singleWhere((binding) => binding.targetId == 'target_center');
    expect(binding?.kind, CinematicMovementTargetBindingKind.mapEntity);
    expect(binding?.sourceId, 'entity_professor');
  });

  testWidgets('binds movement target to selected map event source', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final mapEventButton = find.byKey(
      const ValueKey('cinematic-builder-target-binding-target_center-mapEvent'),
    );
    await tester.ensureVisible(mapEventButton);
    await tester.tap(mapEventButton);
    await tester.pumpAndSettle();

    final sourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-mapEvent-source-event_gate_bell',
      ),
    );
    await tester.ensureVisible(sourceButton);
    expect(find.text('Gate bell'), findsWidgets);
    expect(find.textContaining('Objet event'), findsWidgets);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    final binding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.movementTargetBindings
        .singleWhere((binding) => binding.targetId == 'target_center');
    expect(binding?.kind, CinematicMovementTargetBindingKind.mapEvent);
    expect(binding?.sourceId, 'event_gate_bell');
  });

  testWidgets('keeps map-aware pickers working with map backdrop visible', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final asset = _stageContextCinematic();
    final project = _project(cinematics: [asset]);
    var latestProject = project;
    final stageMapData = _stageMapDataWithVisualLayers();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: stageMapData,
    );

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      backdropPreviewModel: backdropModel,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
      findsOneWidget,
    );
    final actorMapEntityButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity',
      ),
    );
    await tester.ensureVisible(actorMapEntityButton);
    await tester.tap(actorMapEntityButton);
    await tester.pumpAndSettle();

    final actorSourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity-source-entity_professor',
      ),
    );
    await tester.ensureVisible(actorSourceButton);
    await tester.tap(actorSourceButton);
    await tester.pumpAndSettle();

    final targetMapEventButton = find.byKey(
      const ValueKey('cinematic-builder-target-binding-target_center-mapEvent'),
    );
    await tester.ensureVisible(targetMapEventButton);
    await tester.tap(targetMapEventButton);
    await tester.pumpAndSettle();

    final eventSourceButton = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-mapEvent-source-event_gate_bell',
      ),
    );
    await tester.ensureVisible(eventSourceButton);
    await tester.tap(eventSourceButton);
    await tester.pumpAndSettle();

    final actorBinding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.actorBindings
        .singleWhere((binding) => binding.actorId == 'actor_professor');
    final targetBinding = _asset(latestProject, 'cinematic_stage_context')
        .stageContext
        ?.movementTargetBindings
        .singleWhere((binding) => binding.targetId == 'target_center');
    expect(actorBinding?.kind, CinematicActorBindingKind.mapEntity);
    expect(actorBinding?.mapEntityId, 'entity_professor');
    expect(targetBinding?.kind, CinematicMovementTargetBindingKind.mapEvent);
    expect(targetBinding?.sourceId, 'event_gate_bell');
    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
      findsOneWidget,
    );
  });

  testWidgets('shows stage diagnostics in builder', (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        _stageContextCinematic(
          mapId: null,
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
          ),
        ),
      ],
    );
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    final stateTile = find.text('État de la scène');
    await tester.ensureVisible(stateTile);
    await tester.tap(stateTile);
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics stage'), findsOneWidget);
    expect(
      find.text('Choisissez une map avant d’utiliser un décor de map.'),
      findsWidgets,
    );
    expect(find.text('stageBackdropRequiresMap'), findsOneWidget);
    expect(
      find.text('Le décor projectMap nécessite une map stage pour la preview.'),
      findsNothing,
    );
  });

  testWidgets('does not expose raw JSON', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('JSON'), findsNothing);
    expect(find.text('stageContext'), findsNothing);
    expect(find.textContaining('{'), findsNothing);
  });

  testWidgets('does not expose free ID text fields', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('mapEntityId'), findsNothing);
    expect(find.text('sourceId'), findsNothing);
    expect(find.text('eventId'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-stage-map-raw-id-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-stage-source-id-field')),
      findsNothing,
    );
  });

  testWidgets('does not add stageContext map id during readiness polish', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final dropdownButton = find.byKey(
      const ValueKey('cinematic-builder-stage-map-dropdown'),
    );
    await tester.ensureVisible(dropdownButton);
    await tester.tap(dropdownButton);
    await tester.pumpAndSettle();

    final mapButton = find.byKey(
      const ValueKey('cinematic-builder-stage-map-map_lab'),
    );
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();

    final stageJson = _asset(
      latestProject,
      'cinematic_stage_context',
    ).stageContext?.toJson();
    expect(stageJson, isNot(contains('mapId')));
    expect(find.text('stageContext.mapId'), findsNothing);
  });

  testWidgets('does not mutate timeline steps', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    final beforeSteps = _asset(
      project,
      'cinematic_stage_context',
    ).timeline.toJson();
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-player'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      _asset(latestProject, 'cinematic_stage_context').timeline.toJson(),
      beforeSteps,
    );
  });

  testWidgets('does not mutate durationMs', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    var latestProject = project;
    final beforeDurations = _asset(
      project,
      'cinematic_stage_context',
    ).timeline.steps.map((step) => step.durationMs).toList();
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_context',
      onProjectChanged: (project) => latestProject = project,
    );

    final button = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-abstractPoint',
      ),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_stage_context',
      ).timeline.steps.map((step) => step.durationMs).toList(),
      beforeDurations,
    );
  });

  testWidgets('does not enable transport controls', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    _expectTransportControlsPresent(tester);
  });

  testWidgets('does not start preview playback', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageContextCinematic()]);
    await _pumpBuilderHarness(tester, project, 'cinematic_stage_context');

    expect(find.text('Scène non jouée.'), findsWidgets);
    expect(find.text('Lecture read-only dans ce lot.'), findsWidgets);
    expect(find.text('Lecture en cours'), findsNothing);
  });

  testWidgets('duration editor still works after stage edits', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageDurationCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_duration',
      onProjectChanged: (project) => latestProject = project,
    );

    final stageButton = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-player'),
    );
    await tester.ensureVisible(stageButton);
    await tester.tap(stageButton);
    await tester.pumpAndSettle();
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '700');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_stage_duration',
      ).timeline.steps.singleWhere((step) => step.id == 'step_face').durationMs,
      700,
    );
  });

  testWidgets('resize handle still works after stage edits', (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_stageDurationCinematic()]);
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_stage_duration',
      onProjectChanged: (project) => latestProject = project,
    );

    final stageButton = find.byKey(
      const ValueKey('cinematic-builder-actor-binding-actor_professor-player'),
    );
    await tester.ensureVisible(stageButton);
    await tester.tap(stageButton);
    await tester.pumpAndSettle();
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    expect(
      _asset(
        latestProject,
        'cinematic_stage_duration',
      ).timeline.steps.singleWhere((step) => step.id == 'step_face').durationMs,
      greaterThan(500),
    );
  });

  testWidgets(
    'keeps duration resize and mouse probe working with map backdrop visible',
    (tester) async {
      _setLargeSurface(tester);
      final asset = _stageDurationCinematic(
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
      );
      final project = _project(cinematics: [asset]);
      var latestProject = project;
      final stageMapData = _stageMapDataWithVisualLayers();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_duration',
        onProjectChanged: (project) => latestProject = project,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
        findsOneWidget,
      );
      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();

      final durationField = find.byKey(
        const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
      );
      await tester.ensureVisible(durationField);
      await tester.enterText(durationField, '700');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        _asset(latestProject, 'cinematic_stage_duration')
            .timeline
            .steps
            .singleWhere((step) => step.id == 'step_face')
            .durationMs,
        700,
      );

      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
        ),
        const Offset(90, 0),
      );
      await tester.pumpAndSettle();

      expect(
        _asset(latestProject, 'cinematic_stage_duration')
            .timeline
            .steps
            .singleWhere((step) => step.id == 'step_face')
            .durationMs,
        greaterThan(700),
      );

      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final tick0Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final probeX = tick0Rect.left + (tick500Rect.left - tick0Rect.left) * 0.5;
      await _placeTimelineProbeAt(tester, Offset(probeX, axisRect.center.dy));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsOneWidget,
      );
      _expectTransportControlsPresent(tester);
    },
  );

  testWidgets('renders a derived time axis with proportional bars', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_time_layout'),
      asset: _asset(project, 'cinematic_time_layout'),
    );

    expect(find.text('Déroulé'), findsOneWidget);
    expect(find.text('Timeline cinématique'), findsOneWidget);
    expect(find.text('Layout temporel dérivé'), findsOneWidget);
    expect(find.text('0 ms'), findsOneWidget);
    expect(find.text('500 ms'), findsWidgets);
    expect(find.text('1 s'), findsOneWidget);
    expect(find.text('1.5 s'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-lane-actor:actor_professor'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-time-global')),
      findsOneWidget,
    );

    final cameraRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
    );
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    final waitRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_wait')),
    );
    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );

    expect(faceRect.left, greaterThan(cameraRect.left));
    expect(waitRect.left, greaterThan(faceRect.left));
    expect(moveRect.left, greaterThan(waitRect.left));
    expect(moveRect.width, greaterThan(cameraRect.width));
    expect(cameraRect.width, greaterThan(faceRect.width));

    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Marche'), findsWidgets);
    expect(find.text('Direct'), findsWidgets);

    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
    await tester.pumpAndSettle();

    final selectedCameraBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
    );
    expect(selectedCameraBar.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_camera'), findsWidgets);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.text('Fallback visuel'), findsWidgets);
    expect(find.text('drag'), findsNothing);
    expect(find.text('resize'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('renders timeline bars with corrected duration geometry', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.tapAt(faceCardRect.center);
    await tester.pumpAndSettle();

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final cameraBarRect = tester.getRect(
      find.byKey(
        const ValueKey('cinematic-builder-time-visual-bar-step_camera'),
      ),
    );
    final faceBarRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-visual-bar-step_face')),
    );
    final moveBarRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-visual-bar-step_move')),
    );
    final cursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );

    final pxPer500Ms = tick500Rect.left - tick0Rect.left;
    expect(pxPer500Ms, greaterThan(0));
    expect(cameraBarRect.left, closeTo(tick0Rect.left, 2));
    expect(cameraBarRect.width, closeTo(pxPer500Ms, 2));
    expect(faceBarRect.left, closeTo(tick500Rect.left, 2));
    expect(moveBarRect.left, closeTo(tick0Rect.left + pxPer500Ms * 2.2, 2));
    expect(moveBarRect.width, closeTo(pxPer500Ms * 2, 2));
    expect(moveBarRect.width, greaterThanOrEqualTo(cameraBarRect.width * 1.9));
    expect(cursorRect.center.dx, closeTo(tick500Rect.left, 2));

    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Marche'), findsWidgets);
    expect(find.text('Direct'), findsWidgets);
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets(
    'shows a non-interactive selection cursor on selected block start',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_time_layout'),
        asset: _asset(project, 'cinematic_time_layout'),
      );

      expect(find.textContaining('Sélection :'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();

      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor-handle')),
        findsOneWidget,
      );
      final faceCardRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      final faceCursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(faceCursorRect.center.dx, closeTo(faceCardRect.left, 1));

      final moveTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
      );
      await tester.tapAt(Offset(moveTapRect.left + 16, moveTapRect.top + 12));
      await tester.pumpAndSettle();

      expect(find.text('Sélection : 1.1 s'), findsOneWidget);
      expect(find.text('Sélection : 500 ms'), findsNothing);
      final moveCardRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
      );
      final moveCursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(moveCursorRect.center.dx, closeTo(moveCardRect.left, 1));
      expect(moveCursorRect.left, greaterThan(faceCursorRect.left));

      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
          tester, Offset(axisRect.left + 24, axisRect.center.dy));
      await tester.pumpAndSettle();

      final selectedMoveCard = tester.widget<PokeMapCard>(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
      );
      expect(selectedMoveCard.selected, isTrue);
      expect(find.text('Sélection : 1.1 s'), findsNothing);
      expect(find.textContaining('Marqueur :'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsOneWidget,
      );
      expect(find.text('Playback'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(find.text('Lecture'), findsWidgets);
      expect(find.text('Scrubber'), findsNothing);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'sets a local timeline time probe from mouse interaction without changing selection',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('step_face'), findsWidgets);

      final tick0Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final pxPer500Ms = tick500Rect.left - tick0Rect.left;
      final probeX = tick0Rect.left + pxPer500Ms * 1.5;

      await _placeTimelineProbeAt(tester, Offset(probeX, axisRect.center.dy));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Marqueur : 750 ms'), findsOneWidget);
      expect(find.text('Marqueur temps : 750 ms'), findsOneWidget);
      expect(
        find.text('Marqueur local : inspection uniquement.'),
        findsOneWidget,
      );
      expect(find.text('Sélection : 500 ms'), findsNothing);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('step_face'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      final probeCursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      );
      expect(probeCursorRect.center.dx, closeTo(probeX, 2));
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
    },
  );

  testWidgets(
    'snaps local timeline time probe to block boundaries without changing selection',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('step_face'), findsWidgets);

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );

      await _placeTimelineProbeAt(
          tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
      expect(find.text('Marqueur temps : 500 ms'), findsOneWidget);
      expect(
        find.text('Marqueur local : inspection uniquement.'),
        findsOneWidget,
      );
      expect(find.text('Sélection : 500 ms'), findsNothing);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('step_face'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      final probeCursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      );
      expect(probeCursorRect.center.dx, closeTo(tick500Rect.left, 2));
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
    },
  );

  testWidgets(
    'clears local timeline time probe without changing selected block',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
          tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
      expect(find.text('Sélection : 500 ms'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      );
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Marqueur : 500 ms · début bloc'), findsNothing);
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(find.textContaining('2. Professor turns'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
    },
  );

  testWidgets('clears local time probe with Escape while timeline has focus', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();
    _expectTimelineStepSelected(tester, 'step_face');

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Marqueur : 500 ms · début bloc'), findsNothing);
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      findsOneWidget,
    );
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('keeps local time probe when Escape targets a text field', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();
    _expectTimelineStepSelected(tester, 'step_face');

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    final sceneTab = find.byKey(
      const ValueKey('cinematic-builder-inspector-tab-scene'),
    );
    await tester.tap(sceneTab);
    await tester.pumpAndSettle();

    final labelField = find.byKey(
      const ValueKey('cinematic-builder-movement-target-label-target_center'),
    );
    await tester.ensureVisible(labelField);
    await tester.tap(labelField);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(find.text('Sélection : 500 ms'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      findsOneWidget,
    );
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('clears local time probe after accepted duration edit', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();
    _expectTimelineStepSelected(tester, 'step_face');

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );

    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '700');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      700,
    );
    expect(find.text('Marqueur : 500 ms · début bloc'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );
  });

  testWidgets('resizes selected cinematic block duration from right handle', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    final beforeProject = latestProject;
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_face'),
    );
    final moveFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_move'),
    );
    final faceRectBefore = tester.getRect(faceFinder);
    final moveRectBefore = tester.getRect(moveFinder);
    await tester.tapAt(faceRectBefore.center);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    final tick1000Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick1000Rect.left + 4, axisRect.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Marqueur :'), findsWidgets);
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );

    final handle = find.byKey(
      const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
    );
    expect(handle, findsOneWidget);
    await tester.drag(handle, const Offset(140, 0));
    await tester.pumpAndSettle();

    final beforeFace = beforeProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_face');
    final afterFace = latestProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_face');
    expect(afterFace.durationMs, greaterThan(beforeFace.durationMs!));
    expect(afterFace.durationMs! % 100, 0);
    expect(afterFace.toJson().containsKey('startMs'), isFalse);
    expect(afterFace.toJson().containsKey('endMs'), isFalse);
    for (final beforeStep
        in beforeProject.cinematics.single.timeline.steps.where(
      (step) => step.id != 'step_face',
    )) {
      final afterStep = latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == beforeStep.id);
      expect(afterStep.toJson(), beforeStep.toJson());
    }

    final faceRectAfter = tester.getRect(faceFinder);
    final moveRectAfter = tester.getRect(moveFinder);
    expect(faceRectAfter.width, greaterThan(faceRectBefore.width));
    expect(moveRectAfter.left, greaterThan(moveRectBefore.left));
    final beforeLayout = buildCinematicTimelineTimeLayoutReadModel(
      beforeProject.cinematics.single,
    );
    final afterLayout = buildCinematicTimelineTimeLayoutReadModel(
      latestProject.cinematics.single,
    );
    final beforeFaceBlock = beforeLayout.blocks.singleWhere(
      (block) => block.stepId == 'step_face',
    );
    final afterFaceBlock = afterLayout.blocks.singleWhere(
      (block) => block.stepId == 'step_face',
    );
    final beforeMoveBlock = beforeLayout.blocks.singleWhere(
      (block) => block.stepId == 'step_move',
    );
    final afterMoveBlock = afterLayout.blocks.singleWhere(
      (block) => block.stepId == 'step_move',
    );
    expect(afterFaceBlock.laneId, beforeFaceBlock.laneId);
    expect(afterMoveBlock.startMs, greaterThan(beforeMoveBlock.startMs));
    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.textContaining('Marqueur :'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );

    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    final textField = tester.widget<CupertinoTextField>(durationField);
    expect(textField.controller?.text, afterFace.durationMs.toString());
    _expectTransportControlsPresent(tester);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets(
    'shows right resize handle for selected editable authoring-owned block',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_durationResizeCinematic()]);
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_duration_resize',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(
          const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
        ),
        findsNothing,
      );
      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'cinematic-builder-duration-resize-left-handle-step_face',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('hides resize handle for non-owned block', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    final before = project.toJson();
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final soundFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_sound'),
    );
    await tester.ensureVisible(soundFinder);
    final soundRect = tester.getRect(soundFinder);
    await tester.tapAt(soundRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_sound'),
      ),
      findsNothing,
    );
    expect(project.toJson(), before);
  });

  testWidgets('hides resize handle for marker draft', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    final before = project.toJson();
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final markerFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_marker'),
    );
    await tester.ensureVisible(markerFinder);
    final markerRect = tester.getRect(markerFinder);
    await tester.tapAt(markerRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_marker'),
      ),
      findsNothing,
    );
    expect(project.toJson(), before);
  });

  testWidgets('dragging right handle decreases duration', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_face'),
    );
    final faceRectBefore = tester.getRect(faceFinder);
    await tester.tapAt(faceRectBefore.center);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(-160, 0),
    );
    await tester.pumpAndSettle();

    final afterFace = latestProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_face');
    final faceRectAfter = tester.getRect(faceFinder);
    expect(afterFace.durationMs, lessThan(500));
    expect(afterFace.durationMs! % 100, 0);
    expect(faceRectAfter.width, lessThan(faceRectBefore.width));
    _expectTimelineStepSelected(tester, 'step_face');
  });

  testWidgets('duration clamps to minimum', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    await tester.tapAt(moveRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_move'),
      ),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();

    final afterMove = latestProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_move');
    expect(afterMove.durationMs, cinematicTimelineActorMoveMinimumDurationMs);
    _expectTimelineStepSelected(tester, 'step_move');
  });

  testWidgets('duration clamps to maximum', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(40000, 0),
    );
    await tester.pumpAndSettle();

    final afterFace = latestProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_face');
    expect(afterFace.durationMs, cinematicTimelineMaximumDurationMs);
    _expectTimelineStepSelected(tester, 'step_face');
  });

  testWidgets('duration snaps to 100 ms increments', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(27, 0),
    );
    await tester.pumpAndSettle();

    final afterFace = latestProject.cinematics.single.timeline.steps
        .singleWhere((step) => step.id == 'step_face');
    expect(afterFace.durationMs! % 100, 0);
    expect(afterFace.durationMs, isNot(527));
  });

  testWidgets('left edge is not draggable', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_face'),
    );
    final faceRectBefore = tester.getRect(faceFinder);
    await tester.tapAt(faceRectBefore.center);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      Offset(faceRectBefore.left + 2, faceRectBefore.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(-180, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    final faceRectAfter = tester.getRect(faceFinder);
    expect(faceRectAfter.left, closeTo(faceRectBefore.left, 2));
    expect(faceRectAfter.width, closeTo(faceRectBefore.width, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('hover details remain functional after resize', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_face'),
    );
    final faceRect = tester.getRect(faceFinder);
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(moveRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-details')),
      findsOneWidget,
    );
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      greaterThan(500),
    );
  });

  testWidgets('keyboard navigation remains functional after resize', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_move');
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      greaterThan(500),
    );
  });

  testWidgets(
    'shows duration validation guidance and rejects invalid duration without mutation',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      var latestProject = _project(cinematics: [_durationResizeCinematic()]);
      final before = latestProject.toJson();
      await _pumpBuilderHarness(
        tester,
        latestProject,
        'cinematic_duration_resize',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (project) => latestProject = project,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();

      expect(find.text('Bornes : 100–30000 ms · pas 100 ms'), findsOneWidget);
      final durationField = find.byKey(
        const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
      );
      await tester.ensureVisible(durationField);
      await tester.enterText(durationField, '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Minimum pour ce bloc : 100 ms.'), findsOneWidget);
      expect(latestProject.toJson(), before);
      _expectTimelineStepSelected(tester, 'step_face');
    },
  );

  testWidgets('shows actorMove specific minimum duration guidance', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    await tester.tapAt(moveRect.center);
    await tester.pumpAndSettle();

    expect(find.text('Bornes : 200–30000 ms · pas 100 ms'), findsOneWidget);
  });

  testWidgets('shows maximum duration guidance', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();

    expect(find.textContaining('30000 ms'), findsWidgets);
  });

  testWidgets('shows non editable duration reason for marker draft', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final markerFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_marker'),
    );
    await tester.ensureVisible(markerFinder);
    await tester.tapAt(tester.getRect(markerFinder).center);
    await tester.pumpAndSettle();

    expect(
      find.text('Durée non éditable — brouillon sans effet moteur.'),
      findsOneWidget,
    );
  });

  testWidgets('shows non editable duration reason for non-owned step', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final soundFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_sound'),
    );
    await tester.ensureVisible(soundFinder);
    await tester.tapAt(tester.getRect(soundFinder).center);
    await tester.pumpAndSettle();

    expect(
      find.text('Durée non éditable — bloc en lecture seule.'),
      findsOneWidget,
    );
  });

  testWidgets('shows inline error for empty duration input', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    final before = latestProject.toJson();
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.tapAt(
      tester
          .getRect(
            find.byKey(
              const ValueKey('cinematic-builder-time-block-step_face'),
            ),
          )
          .center,
    );
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Saisis une durée en millisecondes.'), findsOneWidget);
    expect(latestProject.toJson(), before);
  });

  testWidgets('shows inline error for non integer duration input', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    final before = latestProject.toJson();
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.tapAt(
      tester
          .getRect(
            find.byKey(
              const ValueKey('cinematic-builder-time-block-step_face'),
            ),
          )
          .center,
    );
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text('Utilise un nombre entier de millisecondes.'),
      findsOneWidget,
    );
    expect(latestProject.toJson(), before);
  });

  testWidgets('shows inline error above maximum', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    final before = latestProject.toJson();
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.tapAt(
      tester
          .getRect(
            find.byKey(
              const ValueKey('cinematic-builder-time-block-step_face'),
            ),
          )
          .center,
    );
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '30001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Maximum : 30000 ms.'), findsOneWidget);
    expect(latestProject.toJson(), before);
  });

  testWidgets('shows resize minimum clamp feedback', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    await tester.tapAt(moveRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_move'),
      ),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minimum atteint : 200 ms'), findsOneWidget);
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_move')
          .durationMs,
      200,
    );
  });

  testWidgets('shows resize maximum clamp feedback', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    var latestProject = _project(cinematics: [_durationResizeCinematic()]);
    await _pumpBuilderHarness(
      tester,
      latestProject,
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(40000, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maximum atteint : 30000 ms'), findsOneWidget);
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      30000,
    );
  });

  testWidgets('shows local time probe help explaining selection and probe', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();
    _expectTimelineStepSelected(tester, 'step_face');

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(
      find.text('Marqueur local : inspection uniquement.'),
      findsOneWidget,
    );
    expect(find.text('Effacer le marqueur'), findsOneWidget);
    expect(find.text('Aide timeline'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );
    final probeCursorBefore = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );
    expect(find.text('Sélection : bloc inspecté.'), findsOneWidget);
    expect(find.text('Marqueur : position temporelle locale.'), findsOneWidget);
    expect(
      find.text('Alignement : marqueur calé sur une borne utile.'),
      findsOneWidget,
    );
    expect(find.text('Preview : lecture réelle à venir.'), findsOneWidget);
    expect(find.text('playback'), findsNothing);
    expect(find.text('seek'), findsNothing);
    expect(find.text('scrub'), findsNothing);
    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Professor turns'), findsWidgets);
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
      findsOneWidget,
    );
    expect(find.text('Bloc précédent / suivant'), findsOneWidget);
    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
      findsOneWidget,
    );
    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );
    final probeCursorAfter = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorAfter.left, closeTo(probeCursorBefore.left, 1));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);

    _expectTransportControlsPresent(tester);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aide timeline'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('clears local time probe with Escape after probe help is open', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();
    _expectTimelineStepSelected(tester, 'step_face');

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsOneWidget,
    );
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(find.text('Marqueur : 500 ms · début bloc'), findsNothing);
    expect(find.text('Aide timeline'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('clears local time probe without selection and can snap again', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.textContaining('Sélection :'), findsNothing);

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Marqueur :'), findsNothing);
    expect(find.textContaining('Sélection :'), findsNothing);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      findsNothing,
    );

    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsOneWidget,
    );
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('snaps local timeline time probe to timeline start and end', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );

    await _placeTimelineProbeAt(
        tester, Offset(tick0Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 0 ms · début timeline'), findsOneWidget);
    var probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(tick0Rect.left, 2));

    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
      const Offset(-380, 0),
    );
    await tester.pumpAndSettle();

    final visibleTick3000Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-3000')),
    );
    final visibleAxisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );

    await _placeTimelineProbeAt(
      tester,
      Offset(visibleTick3000Rect.center.dx, visibleAxisRect.center.dy),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 3 s · fin timeline'), findsOneWidget);
    probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(visibleTick3000Rect.left, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('snaps local timeline time probe to shared block boundary', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final pxPer500Ms = tick500Rect.left - tick0Rect.left;
    final faceEndX = tick0Rect.left + pxPer500Ms * 1.6;

    await _placeTimelineProbeAt(
        tester, Offset(faceEndX - 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 800 ms · début bloc'), findsOneWidget);
    expect(find.text('Marqueur temps : 800 ms'), findsOneWidget);
    expect(
      find.text('Marqueur local : inspection uniquement.'),
      findsOneWidget,
    );
    final probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(faceEndX, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('snap chooses nearest semantic target when boundaries overlap', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final pxPer500Ms = tick500Rect.left - tick0Rect.left;
    final sharedBoundaryX = tick0Rect.left + pxPer500Ms * 1.6;

    await _placeTimelineProbeAt(
        tester, Offset(sharedBoundaryX, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 800 ms · début bloc'), findsOneWidget);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('drags local timeline time probe and clamps to boundaries', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final pxPer500Ms = tick500Rect.left - tick0Rect.left;
    final probeStart = Offset(
      tick0Rect.left + pxPer500Ms,
      axisRect.center.dy,
    );
    final gesture = await tester.startGesture(
      probeStart,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveTo(probeStart);
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    await gesture.moveTo(Offset(axisRect.right + 240, axisRect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Marqueur : 3 s · fin timeline'), findsOneWidget);

    await gesture.moveTo(Offset(tick0Rect.left - 240, axisRect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Marqueur : 0 ms · début timeline'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    final probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(tick0Rect.left, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets(
    'clears local time probe when selecting blocks or using keyboard',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');

      final tick0Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final pxPer500Ms = tick500Rect.left - tick0Rect.left;
      final probePoint = Offset(
        tick0Rect.left + pxPer500Ms * 1.5,
        axisRect.center.dy,
      );
      await _placeTimelineProbeAt(tester, probePoint);
      await tester.pumpAndSettle();
      expect(find.text('Marqueur : 750 ms'), findsOneWidget);

      final moveRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
      );
      await tester.tapAt(moveRect.center);
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_move');
      expect(find.text('Marqueur : 750 ms'), findsNothing);
      expect(find.text('Sélection : 1.1 s'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );

      await _placeTimelineProbeAt(tester, probePoint);
      await tester.pumpAndSettle();
      expect(find.text('Marqueur : 750 ms'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_fade');
      expect(find.text('Marqueur : 750 ms'), findsNothing);
      expect(find.text('Sélection : 2.1 s'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_camera');
      await _placeTimelineProbeAt(tester, probePoint);
      await tester.pumpAndSettle();
      expect(find.text('Marqueur : 750 ms'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Marqueur : 750 ms'), findsNothing);
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets('time probe accounts for horizontal scroll offset', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_longTimelineCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_long_probe',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick1000Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final pxPer1000Ms = tick1000Rect.left - tick0Rect.left;
    final probeX = tick0Rect.left + pxPer1000Ms * 2.5;

    await _placeTimelineProbeAt(tester, Offset(probeX, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 2.5 s'), findsOneWidget);
    final probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(probeX, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('snap respects horizontal scroll offset', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_longTimelineCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_long_probe',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();

    final tick0Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
    );
    final tick1000Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    final pxPer1000Ms = tick1000Rect.left - tick0Rect.left;
    final targetX = tick0Rect.left + pxPer1000Ms * 3;

    await _placeTimelineProbeAt(
        tester, Offset(targetX + 6, axisRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Marqueur : 3 s · début bloc'), findsOneWidget);
    final probeCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
    );
    expect(probeCursorRect.center.dx, closeTo(targetX, 2));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('dragging a timeline block does not move or resize it', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final moveFinder = find.byKey(
      const ValueKey('cinematic-builder-time-block-step_move'),
    );
    final moveRectBefore = tester.getRect(moveFinder);
    final gesture = await tester.startGesture(
      moveRectBefore.center,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(220, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    final moveRectAfter = tester.getRect(moveFinder);
    expect(moveRectAfter.left, closeTo(moveRectBefore.left, 1));
    expect(moveRectAfter.width, closeTo(moveRectBefore.width, 1));
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('resize'), findsNothing);
    expect(find.text('reorder'), findsNothing);
  });

  testWidgets('keeps transport controls present without changing selection', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();

    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-transport-controls')),
      findsOneWidget,
    );
    expect(find.text('Contrôles de lecture à venir'), findsNothing);
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Play'), findsNothing);
    expect(find.text('Stop'), findsNothing);

    _expectTransportControlsPresent(tester);

    final cursorBefore = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    final resetRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
    );
    final playRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    final stopRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
    );
    for (final rect in [resetRect, playRect, stopRect]) {
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle();
    }

    final selectedFaceCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    final cursorAfter = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(selectedFaceCard.selected, isTrue);
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(cursorAfter.left, closeTo(cursorBefore.left, 1));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets(
    'V1-111 initializes transport from playback plan and handles empty timeline',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      _expectTransportControlsPresent(tester);
      expect(_transportButton(tester, 'reset').onPressed, isNotNull);
      expect(_transportButton(tester, 'play').onPressed, isNotNull);
      expect(_transportButton(tester, 'stop').onPressed, isNull);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
        findsOneWidget,
      );
      expect(find.text('0 ms / 3 s'), findsOneWidget);
      expect(find.text('Prévisualisation partielle'), findsOneWidget);
      expect(find.text('runtime'), findsNothing);
      expect(find.text('Flame'), findsNothing);
      expect(find.text('Game' 'State'), findsNothing);

      final emptyProject = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_empty_v1_111',
            title: 'Empty cinematic V1-111',
            timeline: CinematicTimeline(),
          ),
        ],
        includeBridge: false,
      );
      await _pumpBuilder(
        tester,
        _entry(emptyProject, 'cinematic_empty_v1_111'),
        asset: _asset(emptyProject, 'cinematic_empty_v1_111'),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      _expectTransportControlsPresent(tester);
      expect(_transportButton(tester, 'reset').onPressed, isNull);
      expect(_transportButton(tester, 'play').onPressed, isNull);
      expect(_transportButton(tester, 'stop').onPressed, isNull);
      expect(find.text('Aucun bloc à lire'), findsWidgets);
      expect(find.text('0 ms / 0 ms'), findsOneWidget);
    },
  );

  testWidgets('V1-111 plays pauses stops and resets local playback time', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    await tester.pump();
    expect(find.text('Lecture en cours'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('1.2 s / 3 s'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    await tester.pump();
    expect(find.text('Lecture en pause'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('1.2 s / 3 s'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
    );
    await tester.pump();
    expect(find.text('0 ms / 3 s'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final runningAfterResetLabel = tester
        .widget<Text>(
          find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
        )
        .data!;
    expect(runningAfterResetLabel, isNot('0 ms / 3 s'));
    expect(runningAfterResetLabel, endsWith('/ 3 s'));
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
    );
    await tester.pump();
    expect(find.text('0 ms / 3 s'), findsOneWidget);
    expect(find.text('Lecture en cours'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.text('3 s / 3 s'), findsOneWidget);
    expect(find.text('Fin de prévisualisation'), findsOneWidget);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets(
    'V1-111 keeps playback playhead separate from selection probe and editing',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );
      final initialPlayheadRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final advancedPlayheadRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
      );
      expect(advancedPlayheadRect.left, greaterThan(initialPlayheadRect.left));
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );
      _expectTimelineStepSelected(tester, 'step_face');

      final moveTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
      );
      await tester.tapAt(Offset(moveTapRect.left + 16, moveTapRect.top + 12));
      await tester.pump();
      _expectTimelineStepSelected(tester, 'step_move');
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(find.text('700 ms / 3 s'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('700 ms / 3 s'), findsOneWidget);

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
        tester,
        Offset(tick500Rect.left + 6, axisRect.center.dy),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(find.textContaining('Marqueur :'), findsWidgets);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'V1-120 clicking timeline axis seeks playback without changing selection',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackDirectActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final initialAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-step-card-move_direct')),
      );
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'move_direct');

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      final soughtAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      final playbackLabel = tester
          .widget<Text>(
            find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
          )
          .data;
      final playbackTimeMs = int.parse(playbackLabel!.split(' ms').first);
      expect(playbackTimeMs, inInclusiveRange(450, 550));
      expect(soughtAnchor.dx, greaterThan(initialAnchor.dx + 50));
      _expectTimelineStepSelected(tester, 'move_direct');
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(find.textContaining('Marqueur :'), findsNothing);
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-120 clicking timeline bars keeps selection as the only block action',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('0 ms / 3 s'), findsOneWidget);
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'V1-120 clicking empty timeline background seeks playback',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');

      final tick2500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-2500')),
      );
      await tester.tapAt(Offset(tick2500Rect.left + 2, faceTapRect.center.dy));
      await tester.pump();

      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(2450, 2550));
      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(find.textContaining('Marqueur :'), findsNothing);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'V1-120 dragging playback playhead scrubs actor preview without creating mouse probe',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackDirectActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final initialAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      final playheadHandleRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead-handle'),
        ),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final gesture = await tester.startGesture(playheadHandleRect.center);
      await tester.pump();
      await gesture
          .moveTo(Offset(tick500Rect.left + 2, playheadHandleRect.center.dy));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final scrubbedAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      final playbackLabel = tester
          .widget<Text>(
            find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
          )
          .data;
      final playbackTimeMs = int.parse(playbackLabel!.split(' ms').first);
      expect(playbackTimeMs, inInclusiveRange(450, 550));
      expect(scrubbedAnchor.dx, greaterThan(initialAnchor.dx + 50));
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(find.textContaining('Marqueur :'), findsNothing);
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets('V1-120 dragging playback playhead clamps to timeline bounds', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    var playheadHandleRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-playback-playhead-handle')),
    );
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-content')),
    );
    var gesture = await tester.startGesture(playheadHandleRect.center);
    await tester.pump();
    await gesture.moveTo(
      Offset(contentRect.right + 800, playheadHandleRect.center.dy),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_playbackTimeMsFromLabel(tester), 3000);

    final tick1000Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await tester.tapAt(Offset(tick1000Rect.left + 2, axisRect.center.dy));
    await tester.pump();
    expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(950, 1050));

    playheadHandleRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-playback-playhead-handle')),
    );
    gesture = await tester.startGesture(playheadHandleRect.center);
    await tester.pump();
    await gesture.moveTo(
      Offset(contentRect.left - 800, playheadHandleRect.center.dy),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_playbackTimeMsFromLabel(tester), 0);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets(
    'timeline zoom controls resize the grid and keep seek scrub and cursor aligned',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _timeLayoutCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset]);
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      expect(find.text('Zoom timeline 100%'), findsOneWidget);
      final defaultContentWidth = tester
          .getSize(
            find.byKey(const ValueKey('cinematic-builder-time-content')),
          )
          .width;

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-timeline-zoom-in-button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zoom timeline 125%'), findsOneWidget);
      final zoomedContentWidth = tester
          .getSize(
            find.byKey(const ValueKey('cinematic-builder-time-content')),
          )
          .width;
      expect(zoomedContentWidth, greaterThan(defaultContentWidth));

      final faceCardRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      final cursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(cursorRect.center.dx, closeTo(faceCardRect.left, 1));

      final tick1000Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick1000Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(950, 1050));
      _expectTimelineStepSelected(tester, 'step_face');
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );

      final playheadHandleRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead-handle'),
        ),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final gesture = await tester.startGesture(playheadHandleRect.center);
      await tester.pump();
      await gesture
          .moveTo(Offset(tick500Rect.left + 2, playheadHandleRect.center.dy));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(450, 550));
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-timeline-zoom-out-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zoom timeline 100%'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-timeline-zoom-out-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zoom timeline 75%'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-timeline-zoom-reset-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zoom timeline 100%'), findsOneWidget);

      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'timeline zoom trackpad pinch updates zoom without seeking or selecting',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      addTearDown(gesture.removePointer);

      await gesture.panZoomStart(axisRect.center);
      await gesture.panZoomUpdate(axisRect.center, scale: 1.5);
      await tester.pumpAndSettle();
      await gesture.panZoomEnd();
      await tester.pumpAndSettle();

      expect(find.text('Zoom timeline 150%'), findsOneWidget);
      expect(_playbackTimeMsFromLabel(tester), 0);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'V1-120 dragging playback playhead pauses then resumes active preview',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackDirectActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Lecture en cours'), findsWidgets);

      final playheadHandleRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead-handle'),
        ),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final gesture = await tester.startGesture(playheadHandleRect.center);
      await tester.pump();
      await gesture
          .moveTo(Offset(tick500Rect.left + 2, playheadHandleRect.center.dy));
      await tester.pump();
      expect(find.text('Lecture en pause'), findsWidgets);

      await gesture.up();
      await tester.pump();
      expect(find.text('Lecture en cours'), findsWidgets);
      expect(projectChangeCount, 0);
    },
  );

  testWidgets(
    'V1-120 clear probe stop and reset keep probe and playback roles separated',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final tick1000Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-1000')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
        tester,
        Offset(tick500Rect.left + 6, axisRect.center.dy),
      );
      await tester.pump();
      expect(find.textContaining('Marqueur :'), findsWidgets);

      await tester.tapAt(Offset(tick1000Rect.left + 2, axisRect.center.dy));
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(950, 1050));
      expect(find.textContaining('Marqueur :'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      );
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(950, 1050));
      expect(find.textContaining('Marqueur :'), findsNothing);

      await _placeTimelineProbeAt(
        tester,
        Offset(tick500Rect.left + 6, axisRect.center.dy),
      );
      await tester.pump();
      expect(find.textContaining('Marqueur :'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), 0);
      expect(find.textContaining('Marqueur :'), findsWidgets);

      await tester.tapAt(Offset(tick1000Rect.left + 2, axisRect.center.dy));
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(950, 1050));
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
      );
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), 0);
      expect(find.textContaining('Marqueur :'), findsWidgets);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets('V1-120 exposes no-code seek and scrub labels', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);

    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    expect(find.text('Lecture'), findsWidgets);
    expect(find.byTooltip('Glisser pour parcourir'), findsOneWidget);
    final semanticsWidgets = tester.widgetList<Semantics>(
      find.byType(Semantics),
    );
    expect(
      semanticsWidgets.any(
        (widget) =>
            widget.properties.label == 'Prévisualiser ce moment' &&
            widget.properties.hint == 'Lire depuis ce moment',
      ),
      isTrue,
    );
    expect(
      semanticsWidgets.any(
        (widget) =>
            widget.properties.label == 'Tête de lecture' &&
            widget.properties.hint == 'Déplacer la lecture',
      ),
      isTrue,
    );
    expect(find.text('playbackTimeMs'), findsNothing);
    expect(find.text('seek'), findsNothing);
    expect(find.text('scrub'), findsNothing);
    expect(find.text('frameAt'), findsNothing);
    expect(find.text('activeStepIds'), findsNothing);
    expect(find.text('timelineItem'), findsNothing);
    expect(find.text('probe'), findsNothing);
    expect(find.textContaining('runtime'), findsNothing);
  });

  testWidgets(
    'captures V1-120 cinematic preview playback scrub seek ui visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_120_CAPTURE_CINEMATIC_PREVIEW_PLAYBACK_SCRUB_SEEK_UI',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _playbackDirectActorMoveCinematic();
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
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_direct'),
      );
      await tester.tap(moveCard);
      await tester.pumpAndSettle();

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'move_direct');
      final playbackLabel = tester
          .widget<Text>(
            find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
          )
          .data;
      final playbackTimeMs = int.parse(playbackLabel!.split(' ms').first);
      expect(playbackTimeMs, inInclusiveRange(450, 550));
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
        ),
        findsOneWidget,
      );
      expect(find.text('Seek'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('runtime'), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-121 fade out preview overlay follows playback time',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _fadePlaybackCinematic(CinematicTimelineFadeMode.fadeOut);
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

      expect(_fadePreviewOpacity(tester), 0);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final midpointOpacity = _fadePreviewOpacity(tester);
      expect(midpointOpacity, greaterThan(0.35));
      expect(midpointOpacity, lessThan(0.65));
      expect(find.text('Lecture en cours'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final pausedOpacity = _fadePreviewOpacity(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_fadePreviewOpacity(tester), pausedOpacity);
      expect(find.text('Lecture en pause'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();
      expect(_fadePreviewOpacity(tester), 0);
    },
  );

  testWidgets('V1-121 fade in preview overlay clears over playback', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final asset = _fadePlaybackCinematic(CinematicTimelineFadeMode.fadeIn);
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

    expect(_fadePreviewOpacity(tester), 1);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final midpointOpacity = _fadePreviewOpacity(tester);
    expect(midpointOpacity, greaterThan(0.35));
    expect(midpointOpacity, lessThan(0.65));

    await tester.pump(const Duration(milliseconds: 600));
    expect(_fadePreviewOpacity(tester), 0);
  });

  testWidgets(
    'V1-121 seek updates fade preview opacity without mutating project',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _fadePlaybackCinematic(CinematicTimelineFadeMode.fadeOut);
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      final soughtOpacity = _fadePreviewOpacity(tester);
      expect(soughtOpacity, greaterThan(0.35));
      expect(soughtOpacity, lessThan(0.65));
      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(450, 550));
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-121 drag-to-scrub updates fade preview opacity and keeps overlay passive',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _fadePlaybackCinematic(CinematicTimelineFadeMode.fadeOut);
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

      final overlay = tester.widget<IgnorePointer>(
        find.byKey(const ValueKey('cinematic-builder-fade-preview-overlay')),
      );
      expect(overlay.ignoring, isTrue);

      final playheadHandleRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead-handle'),
        ),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final gesture = await tester.startGesture(playheadHandleRect.center);
      await tester.pump();
      await gesture
          .moveTo(Offset(tick500Rect.left + 2, playheadHandleRect.center.dy));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final scrubbedOpacity = _fadePreviewOpacity(tester);
      expect(scrubbedOpacity, greaterThan(0.35));
      expect(scrubbedOpacity, lessThan(0.65));
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'captures V1-121 cinematic fade preview playback visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_121_CAPTURE_CINEMATIC_FADE_PREVIEW_PLAYBACK',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _fadePlaybackCinematic(CinematicTimelineFadeMode.fadeOut);
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

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pumpAndSettle();

      final fadeBlock = find.byKey(
        const ValueKey('cinematic-builder-time-block-fade_fadeOut'),
      );
      await tester.ensureVisible(fadeBlock);
      await tester.pumpAndSettle();
      final fadeBlockRect = tester.getRect(fadeBlock);
      await tester
          .tapAt(Offset(fadeBlockRect.left + 16, fadeBlockRect.top + 8));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-inspector-tab-scene')),
      );
      await tester.pumpAndSettle();

      expect(_fadePreviewOpacity(tester), greaterThan(0.35));
      expect(_fadePreviewOpacity(tester), lessThan(0.65));
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(find.textContaining('runtime'), findsNothing);
      expect(find.text('Flame'), findsNothing);
      final forbiddenStateLabel = ['Game', 'State'].join();
      expect(find.text(forbiddenStateLabel), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-124 active supported camera shows camera preview overlay',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'hold');
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-frame')),
        findsOneWidget,
      );
      expect(find.text('Caméra active'), findsOneWidget);
      expect(find.text('Cadrage caméra prêt'), findsOneWidget);
      expect(find.text('Prévisualisation caméra partielle'), findsNothing);
      expect(
        find.text('Caméra non prévisualisée dans cette version.'),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-124 unsupported camera shows no-code camera fallback message',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'orbit');
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

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      expect(find.text('Caméra active'), findsOneWidget);
      expect(
        find.text('Caméra non prévisualisée dans cette version.'),
        findsOneWidget,
      );
      expect(find.text('Cadrage caméra prêt'), findsNothing);
      expect(find.textContaining('cameraPose'), findsNothing);
      expect(find.textContaining('activeStepId'), findsNothing);
      expect(find.textContaining('unsupported'), findsNothing);
      expect(find.textContaining('progress'), findsNothing);
      expect(find.textContaining('runtime'), findsNothing);
    },
  );

  testWidgets(
    'V1-124 missing camera mode shows Cadrage caméra incomplet',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: null);
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

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      expect(find.text('Cadrage caméra incomplet.'), findsOneWidget);
      expect(find.text('Prévisualisation caméra partielle'), findsNothing);
      expect(find.textContaining('camera.mode'), findsNothing);
    },
  );

  testWidgets(
    'V1-124 no active camera hides camera overlay before and after step',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'reset');
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

      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );

      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final tick1500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-1500')),
      );
      await tester.tapAt(Offset(tick1500Rect.left + 2, axisRect.center.dy));
      await tester.pump();

      expect(_playbackTimeMsFromLabel(tester), inInclusiveRange(1450, 1550));
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'V1-124 Play Pause Stop and Reset update camera overlay from playback time',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'hold');
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Lecture en cours'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      final pausedTime = _playbackTimeMsFromLabel(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_playbackTimeMsFromLabel(tester), pausedTime);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), 0);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
      );
      await tester.pump();
      expect(_playbackTimeMsFromLabel(tester), 0);
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-124 seek and scrub update camera overlay without probe or selection changes',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'hold');
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

      final cameraCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-camera_preview'),
      );
      await tester.tap(cameraCard);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'camera_preview');

      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final tick1500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-1500')),
      );

      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      _expectTimelineStepSelected(tester, 'camera_preview');
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );

      await tester.tapAt(Offset(tick1500Rect.left + 2, axisRect.center.dy));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsNothing,
      );
      _expectTimelineStepSelected(tester, 'camera_preview');

      final playheadHandleRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead-handle'),
        ),
      );
      final gesture = await tester.startGesture(playheadHandleRect.center);
      await tester.pump();
      await gesture
          .moveTo(Offset(tick500Rect.left + 2, playheadHandleRect.center.dy));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      final overlay = tester.widget<IgnorePointer>(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
      );
      expect(overlay.ignoring, isTrue);
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      _expectTimelineStepSelected(tester, 'camera_preview');
    },
  );

  testWidgets(
    'captures V1-124 cinematic camera preview playback ui visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_124_CAPTURE_CINEMATIC_CAMERA_PREVIEW_PLAYBACK_UI',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _cameraPreviewPlaybackCinematic(cameraMode: 'hold');
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

      final cameraCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-camera_preview'),
      );
      await tester.tap(cameraCard);
      await tester.pumpAndSettle();

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await tester.tapAt(Offset(tick500Rect.left + 2, axisRect.center.dy));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-inspector-tab-scene')),
      );
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'camera_preview');
      expect(find.text('Lecture en pause'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-camera-preview-overlay')),
        findsOneWidget,
      );
      expect(find.text('Caméra active'), findsOneWidget);
      expect(find.text('Cadrage caméra prêt'), findsOneWidget);
      expect(find.textContaining('runtime'), findsNothing);
      expect(find.text('Flame'), findsNothing);
      final forbiddenStateLabel = ['Game', 'State'].join();
      expect(find.text(forbiddenStateLabel), findsNothing);
      final forbiddenNextLotLabel = ['V1', '125'].join('-');
      expect(find.text(forbiddenNextLotLabel), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-112 moves direct actorMove actor during playback and resets to start',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackDirectActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final initialAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('0 ms / 1 s'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final playbackStartAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 500));

      final middleAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('Lecture en cours'), findsWidgets);
      expect(find.text('500 ms / 1 s'), findsOneWidget);
      expect(middleAnchor.dx, greaterThan(playbackStartAnchor.dx));
      expect(middleAnchor.dx, lessThan(playbackStartAnchor.dx + 260));
      expect(middleAnchor.dy, closeTo(playbackStartAnchor.dy, 8));

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final pausedAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 400));
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), pausedAnchor);
      expect(find.text('Lecture en pause'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final finalAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(finalAnchor.dx, greaterThan(middleAnchor.dx));
      expect(find.text('1 s / 1 s'), findsOneWidget);
      expect(find.text('Fin de prévisualisation'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), initialAnchor);
      expect(find.text('0 ms / 1 s'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _actorDisplayAnchor(tester, 'actor_lysa').dx,
        greaterThan(initialAnchor.dx),
      );
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
      );
      await tester.pump();
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), initialAnchor);
      expect(find.text('Lecture en cours'), findsNothing);

      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsNothing,
      );
      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-112 follows manual path actorMove poses without mutating waypoints',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackManualPathActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      final beforeWaypoints =
          asset.stageContext!.manualPaths.single.waypointStagePointIds;

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
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final playbackStartAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 400));

      final waypointAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(waypointAnchor.dx, closeTo(playbackStartAnchor.dx, 8));
      expect(waypointAnchor.dy, greaterThan(playbackStartAnchor.dy + 50));
      expect(find.text('400 ms / 1 s'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      final destinationAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(destinationAnchor.dx, greaterThan(waypointAnchor.dx));
      expect(destinationAnchor.dy, closeTo(waypointAnchor.dy, 1));
      expect(find.text('1 s / 1 s'), findsOneWidget);

      expect(
        asset.stageContext!.manualPaths.single.waypointStagePointIds,
        beforeWaypoints,
      );
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-113 direct actorMove preserves sub-tile playback positions',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackDirectActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      var projectChangeCount = 0;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (_) => projectChangeCount += 1,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: asset,
          stageMap: project.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final initialAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final playbackStartAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 100));

      final earlyAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('100 ms / 1 s'), findsOneWidget);
      expect(
        earlyAnchor.dx,
        greaterThan(playbackStartAnchor.dx + 12),
        reason: 'At 100 ms, round() kept the actor visually stuck on start.',
      );
      expect(earlyAnchor.dy, closeTo(playbackStartAnchor.dy, 2));

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final pausedSubTileAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 300));
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), pausedSubTileAnchor);
      expect(find.text('Lecture en pause'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final middleAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('500 ms / 1 s'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      final finalAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('1 s / 1 s'), findsOneWidget);
      expect(
        middleAnchor.dx,
        closeTo((playbackStartAnchor.dx + finalAnchor.dx) / 2, 6),
      );
      expect(middleAnchor.dy, closeTo(playbackStartAnchor.dy, 8));

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), initialAnchor);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final secondPlaybackStartAnchor =
          _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        _actorDisplayAnchor(tester, 'actor_lysa').dx,
        greaterThan(secondPlaybackStartAnchor.dx + 12),
      );
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
      );
      await tester.pump();
      expect(_actorDisplayAnchor(tester, 'actor_lysa'), initialAnchor);

      expect(projectChangeCount, 0);
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-113 manual path actorMove moves before tile rounding threshold',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _playbackManualPathActorMoveCinematic();
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final project = _project(cinematics: [asset], includeBridge: false);
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: project,
        mapData: mapData,
      );
      final beforeProject = project.toJson();
      final beforeAsset = asset.toJson();
      final beforeMapData = mapData.toJson();
      final beforeWaypoints =
          asset.stageContext!.manualPaths.single.waypointStagePointIds;

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
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final playbackStartAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 40));

      final earlyAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('40 ms / 1 s'), findsOneWidget);
      expect(earlyAnchor.dx, closeTo(playbackStartAnchor.dx, 2));
      expect(
        earlyAnchor.dy,
        greaterThan(playbackStartAnchor.dy + 5),
        reason: 'At 40 ms, round() kept the manual path actor on start.',
      );

      await tester.pump(const Duration(milliseconds: 360));
      final segmentAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('400 ms / 1 s'), findsOneWidget);
      expect(segmentAnchor.dx, closeTo(playbackStartAnchor.dx, 8));
      expect(segmentAnchor.dy, greaterThan(earlyAnchor.dy));

      await tester.pump(const Duration(milliseconds: 700));
      final destinationAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(destinationAnchor.dx, greaterThan(segmentAnchor.dx));
      expect(destinationAnchor.dy, closeTo(segmentAnchor.dy, 8));

      expect(
        asset.stageContext!.manualPaths.single.waypointStagePointIds,
        beforeWaypoints,
      );
      expect(project.toJson(), beforeProject);
      expect(asset.toJson(), beforeAsset);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-113 overlay applies sub-tile playback overrides and static fallback',
    (tester) async {
      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '2 acteurs prêts.',
        actors: [
          _testDisplayActor(
            actorId: 'actor_moving',
            label: 'Moving',
            x: 1,
            y: 0,
          ),
          _testDisplayActor(
            actorId: 'actor_static',
            label: 'Static',
            x: 2,
            y: 0,
          ),
        ],
        diagnostics: const [],
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  playbackPoseOverrides: const {
                    'actor_moving': CinematicActorPlaybackOverlayPose(
                      actorId: 'actor_moving',
                      x: 1.25,
                      y: 0.75,
                    ),
                  },
                  mapWidth: 4,
                  mapHeight: 2,
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );

      final movingAnchor = _actorDisplayAnchor(tester, 'actor_moving');
      final staticAnchor = _actorDisplayAnchor(tester, 'actor_static');
      expect(movingAnchor.dx, closeTo(125, 1));
      expect(movingAnchor.dy, closeTo(75, 1));
      expect(staticAnchor.dx, closeTo(250, 1));
      expect(staticAnchor.dy, closeTo(100, 1));
    },
  );

  test(
    'V1-113 adapter falls back when playback pose has no position',
    () {
      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 acteur prêt.',
        actors: [
          _testDisplayActor(
            actorId: 'actor_static',
            label: 'Static',
            x: 2,
            y: 1,
          ),
        ],
        diagnostics: const [],
      );

      final overlayModel = buildCinematicPreviewPlaybackActorOverlayModel(
        displayModel: model,
        playbackFrame: CinematicPreviewPlaybackFrame(
          timeMs: 100,
          clampedTimeMs: 100,
          activeStepIds: const ['face_actor'],
          actorPoses: const [
            CinematicActorPlaybackPose(
              actorId: 'actor_static',
              facing: CinematicActorPreviewDirection.east,
              source: CinematicActorPlaybackPoseSource.actorFace,
              isInterpolated: false,
              activeStepId: 'face_actor',
            ),
          ],
          visibleDiagnostics: const [],
        ),
      );

      expect(overlayModel, isNotNull);
      expect(overlayModel!.poseOverrides, isEmpty);
      final actor = overlayModel.displayModel.actors.single;
      expect(actor.position.x, 2);
      expect(actor.position.y, 1);
      expect(actor.direction, CinematicActorPreviewDirection.east);
    },
  );

  testWidgets(
    'V1-116 actorMove walk renders walking sprite frame and stop returns idle',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      final setup = await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );
      final beforeProject = setup.project.toJson();
      final beforeAsset = setup.asset.toJson();
      final beforeMapData = setup.mapData.toJson();

      expect(_currentActorSpriteSource(tester), _idleSouthSource);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('100 ms / 1 s'), findsOneWidget);
      expect(_currentActorSpriteSource(tester), _walkEastFrame2Source);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final pausedSource = _currentActorSpriteSource(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_currentActorSpriteSource(tester), pausedSource);
      expect(find.text('Lecture en pause'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();

      expect(_currentActorSpriteSource(tester), _idleSouthSource);
      expect(find.text('0 ms / 1 s'), findsOneWidget);
      expect(setup.project.toJson(), beforeProject);
      expect(setup.asset.toJson(), beforeAsset);
      expect(setup.mapData.toJson(), beforeMapData);

      final readyAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: readyAsset,
      );
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Animation acteur prête'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-fallback-details'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'V1-116 actorMove run renders run frame and falls back to walk',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_currentActorSpriteSource(tester), _runEastSource);

      final noRunProject = _animatedLysaProject(
        runAsset,
        includeRunAnimation: false,
      );
      final mapData = _stageMapDataWithActorDisplayFixtures();
      final tileRenderPlan = await _referenceTileRenderPlanFor(
        project: noRunProject,
        mapData: mapData,
      );
      final actorImage = await _loadActorSpriteFixtureImage(tester);
      final actorDisplayModel = _actorDisplayPreviewModelFor(
        project: noRunProject,
        asset: runAsset,
        mapData: mapData,
      );
      final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: actorDisplayModel,
        project: noRunProject,
      );

      await _pumpBuilder(
        tester,
        _entry(noRunProject, runAsset.id),
        asset: runAsset,
        characters: noRunProject.characters,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: runAsset,
          stageMap: noRunProject.maps.single,
          mapData: mapData,
        ),
        backdropTileRenderPlan: _withActorTileset(
          tileRenderPlan,
          actorImage,
        ),
        actorDisplayPreviewModel: actorDisplayModel,
        actorSpritePreviewPlan: actorSpritePreviewPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_currentActorSpriteSource(tester), _walkEastFrame2Source);
    },
  );

  testWidgets(
    'V1-116 manual path actorMove renders walking sprite frame while moving',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackManualPathActorMoveCinematic(),
      );
      final setup = await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );
      final beforeWaypoints =
          asset.stageContext!.manualPaths.single.waypointStagePointIds;

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      final playbackStartAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      await tester.pump(const Duration(milliseconds: 100));

      expect(_currentActorSpriteSource(tester), _walkSouthFrame2Source);
      final movedAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(
        (movedAnchor - playbackStartAnchor).distance,
        greaterThan(8),
      );
      expect(
        asset.stageContext!.manualPaths.single.waypointStagePointIds,
        beforeWaypoints,
      );
      expect(setup.asset.toJson(), asset.toJson());
    },
  );

  testWidgets(
    'captures V1-116 cinematic actor walking animation renderer integration visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_116_CAPTURE_CINEMATIC_ACTOR_WALKING_ANIMATION_RENDERER_INTEGRATION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _animatedLysaPlaybackCinematic(
        _playbackManualPathActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_manual'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_currentActorSpriteSource(tester), _walkSouthFrame2Source);
      expect(find.text('Lecture en cours'), findsOneWidget);
      expect(find.text('100 ms / 1 s'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
        ),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-117 fast actorMove uses playback velocity cadence for rendered frame',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Lecture en cours'), findsWidgets);
      expect(_currentActorSpriteSource(tester), _walkEastFrame2Source);
    },
  );

  testWidgets(
    'V1-117 run playback advances sprite cadence faster than walk',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final walkAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: walkAsset,
        walkDurationMs: 140,
        runDurationMs: 70,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      final walkSource = _currentActorSpriteSource(tester);

      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
        walkDurationMs: 140,
        runDurationMs: 70,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));

      expect(
        walkSource,
        const TilesetSourceRect(x: 1, y: 0, width: 2, height: 2),
      );
      expect(_currentActorSpriteSource(tester), _runEastSource);
    },
  );

  testWidgets(
    'V1-117 playback status chips stay coherent during active and paused animation',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );

      expect(find.text('Aperçu statique'), findsWidgets);
      expect(find.text('Lecture en cours'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Lecture en cours'), findsWidgets);
      expect(find.text('Animation acteur prête'), findsWidgets);
      expect(find.text('Sans lecture'), findsNothing);
      expect(find.text('Acteurs statiques'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();

      expect(find.text('Lecture en pause'), findsWidgets);
      expect(find.text('Sans lecture'), findsNothing);
      expect(find.text('Acteurs statiques'), findsNothing);
    },
  );

  testWidgets(
    'V1-117 fallback animation status is partial and stop returns idle',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      final setup = await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
        includeRunAnimation: false,
      );
      final beforeProject = setup.project.toJson();
      final beforeAsset = setup.asset.toJson();
      final beforeMapData = setup.mapData.toJson();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Animation partielle'), findsWidgets);
      expect(find.text('Sans lecture'), findsNothing);
      expect(_currentActorSpriteSource(tester), _walkEastFrame2Source);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-stop-button')),
      );
      await tester.pump();

      expect(_currentActorSpriteSource(tester), _idleSouthSource);
      expect(setup.project.toJson(), beforeProject);
      expect(setup.asset.toJson(), beforeAsset);
      expect(setup.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-118 ready animation does not show fallback details',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Animation acteur prête'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-fallback-details'),
        ),
        findsNothing,
      );
      expect(find.textContaining('animation de marche indisponible'),
          findsNothing);
    },
  );

  testWidgets(
    'V1-118 partial animation shows no-code fallback details without mutation',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      final setup = await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
        includeRunAnimation: false,
      );
      final beforeProject = setup.project.toJson();
      final beforeAsset = setup.asset.toJson();
      final beforeMapData = setup.mapData.toJson();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Animation partielle'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-fallback-details'),
        ),
        findsOneWidget,
      );
      expect(find.text('Détails de prévisualisation'), findsOneWidget);
      expect(
        find.text(
          'Lysa utilise une animation de secours : animation de marche indisponible.',
        ),
        findsOneWidget,
      );
      for (final token in const [
        'sourceRect',
        'tilesetId',
        'payload',
        'JSON',
        'actorId',
        'map_core',
      ]) {
        expect(find.textContaining(token), findsNothing);
      }
      expect(setup.project.toJson(), beforeProject);
      expect(setup.asset.toJson(), beforeAsset);
      expect(setup.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'V1-118 fallback details remain visible while playback is paused',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
        includeRunAnimation: false,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();

      expect(find.text('Lecture en pause'), findsWidgets);
      expect(find.text('Animation partielle'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-fallback-details'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('animation de marche indisponible'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'captures V1-118 cinematic playback preview diagnostics fallback detail polish visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_118_CAPTURE_CINEMATIC_PLAYBACK_PREVIEW_DIAGNOSTICS_FALLBACK_DETAIL_POLISH',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final runAsset = _animatedLysaPlaybackCinematic(
        _playbackDirectActorMoveCinematic(),
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: runAsset,
        includeRunAnimation: false,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_direct'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lecture en cours'), findsWidgets);
      expect(find.text('Animation partielle'), findsWidgets);
      expect(find.text('Détails de prévisualisation'), findsOneWidget);
      expect(
        find.text(
          'Lysa utilise une animation de secours : animation de marche indisponible.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-playback-playhead'),
        ),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-117 manual path playback uses cadence hint without mutating waypoints',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final asset = _animatedLysaPlaybackCinematic(
        _playbackManualPathActorMoveCinematic(),
      );
      final setup = await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );
      final beforeWaypoints =
          asset.stageContext!.manualPaths.single.waypointStagePointIds;
      final beforeProject = setup.project.toJson();
      final beforeAsset = setup.asset.toJson();
      final beforeMapData = setup.mapData.toJson();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(_currentActorSpriteSource(tester), _walkSouthFrame2Source);
      expect(
        asset.stageContext!.manualPaths.single.waypointStagePointIds,
        beforeWaypoints,
      );
      expect(setup.project.toJson(), beforeProject);
      expect(setup.asset.toJson(), beforeAsset);
      expect(setup.mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'captures V1-117 cinematic actor animation cadence playback status polish visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_117_CAPTURE_CINEMATIC_ACTOR_ANIMATION_CADENCE_STATUS_POLISH',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _animatedLysaPlaybackCinematic(
        _playbackManualPathActorMoveCinematic(includeSecondWaypoint: true),
      );
      await _pumpAnimatedLysaPlaybackBuilder(
        tester,
        asset: asset,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_manual'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_currentActorSpriteSource(tester), _walkSouthFrame2Source);
      expect(find.text('Trajet'), findsWidgets);
      expect(find.text('Manuel'), findsWidgets);
      expect(find.text('Repère A'), findsWidgets);
      expect(find.text('Repère B'), findsWidgets);
      expect(find.text('Lecture en cours'), findsWidgets);
      expect(find.text('Animation acteur prête'), findsWidgets);
      expect(find.text('Acteurs statiques'), findsNothing);
      expect(find.text('Sans lecture'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
        ),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-113 cinematic actor playback smooth motion visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_113_CAPTURE_CINEMATIC_ACTOR_PLAYBACK_SMOOTH_MOTION_SUBTILE',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _playbackManualPathActorMoveCinematic();
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
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final initialAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_manual'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final playbackAnchor = _actorDisplayAnchor(tester, 'actor_lysa');
      expect(find.text('Lecture en cours'), findsOneWidget);
      expect(find.text('400 ms / 1 s'), findsOneWidget);
      expect(
        playbackAnchor.dy,
        greaterThan(initialAnchor.dy + 60),
        reason: 'La Visual Gate doit montrer une pose intermédiaire visible.',
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
        ),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-112 cinematic actorMove preview playback visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_112_CAPTURE_CINEMATIC_ACTORMOVE_PREVIEW_PLAYBACK',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _playbackManualPathActorMoveCinematic();
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
        actorDisplayPreviewModel: _actorDisplayPreviewModelFor(
          project: project,
          asset: asset,
          mapData: mapData,
        ),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-move_manual'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Lecture en cours'), findsOneWidget);
      expect(find.text('400 ms / 1 s'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
        ),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-111 cinematic preview playback transport UI when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_111_CAPTURE_CINEMATIC_PREVIEW_PLAYBACK_TRANSPORT_UI',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final faceTapRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-transport-play-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('Lecture en cours'), findsOneWidget);
      expect(find.text('1.2 s / 3 s'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );
      expect(find.text('Prévisualisation partielle'), findsOneWidget);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('keeps hover help and transport controls after snapped probe', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final tick500Rect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
    );
    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await _placeTimelineProbeAt(
        tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(moveRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-details')),
      findsOneWidget,
    );
    expect(find.text('Survol : Professor → Centre scène'), findsOneWidget);
    expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);

    final helpButton = find.byKey(
      const ValueKey('cinematic-builder-keyboard-help-button'),
    );
    await tester.tap(helpButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
      findsOneWidget,
    );

    _expectTransportControlsPresent(tester);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Marqueur :'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
      findsOneWidget,
    );
    _expectTransportControlsPresent(tester);

    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
  });

  testWidgets('renders polished dense timeline on reference surface', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-preview-placeholder')),
    );
    final timelineRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
    );
    final cameraLaneRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-lane-camera')),
    );
    final faceBarRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-visual-bar-step_face')),
    );
    final resetButtonRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-transport-reset-button')),
    );
    final cursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    final faceCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );

    expect(previewRect.height, lessThanOrEqualTo(450));
    expect(timelineRect.height, greaterThanOrEqualTo(390));
    expect(timelineRect.top, greaterThan(previewRect.bottom));
    expect(cameraLaneRect.height, greaterThanOrEqualTo(36));
    expect(faceBarRect.height, greaterThanOrEqualTo(30));
    expect(resetButtonRect.height, lessThanOrEqualTo(40));
    expect(cursorRect.center.dx, closeTo(faceCardRect.left, 1));

    expect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
      findsOneWidget,
    );
    expect(find.text('0 ms'), findsOneWidget);
    expect(find.text('500 ms'), findsWidgets);
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(find.text('Aucun step'), findsWidgets);
    expect(find.text('Aucun step dans cette piste.'), findsNothing);
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Marche'), findsWidgets);
    expect(find.text('Direct'), findsWidgets);
    for (final key in <String>[
      'cinematic-builder-transport-reset-button',
      'cinematic-builder-transport-play-button',
      'cinematic-builder-transport-stop-button',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Play'), findsNothing);
    expect(find.text('Stop'), findsNothing);

    final selectedFaceBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    expect(selectedFaceBar.selected, isTrue);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('shows hover details without selecting or moving cursor', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-details')),
      findsNothing,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();

    final faceCursorBefore = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_face'), findsWidgets);
    expect(find.text('Professor turns'), findsWidgets);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(faceTapRect.center);
    await tester.pumpAndSettle();

    final hoverDetails = find.byKey(
      const ValueKey('cinematic-builder-hover-details'),
    );
    expect(hoverDetails, findsOneWidget);
    expect(find.text('Survol : Professor turns'), findsOneWidget);
    expect(find.text('Type : Orientation acteur'), findsOneWidget);
    expect(find.text('Piste : Acteur: Professor'), findsOneWidget);
    expect(find.text('Début : 500 ms'), findsOneWidget);
    expect(find.text('Durée : 300 ms visuel'), findsOneWidget);
    expect(find.text('Direction : Droite'), findsOneWidget);

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    await gesture.moveTo(moveRect.center);
    await tester.pumpAndSettle();

    expect(hoverDetails, findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-highlight-step_move')),
      findsOneWidget,
    );
    expect(find.text('Survol : Professor → Centre scène'), findsOneWidget);
    expect(find.text('Type : Déplacement acteur'), findsOneWidget);
    expect(find.text('Piste : Acteur: Professor'), findsOneWidget);
    expect(find.text('Début : 1.1 s'), findsOneWidget);
    expect(find.text('Durée : 1000 ms'), findsOneWidget);
    expect(find.text('Mode : Marche'), findsOneWidget);
    expect(find.text('Chemin : Direct'), findsOneWidget);
    expect(
      find.descendant(of: hoverDetails, matching: find.text('actor_professor')),
      findsNothing,
    );
    expect(
      find.descendant(of: hoverDetails, matching: find.text('target_center')),
      findsNothing,
    );

    final selectedFaceCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    final hoveredMoveCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
    );
    final cursorAfterMoveHover = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(selectedFaceCard.selected, isTrue);
    expect(hoveredMoveCard.selected, isFalse);
    expect(cursorAfterMoveHover.left, closeTo(faceCursorBefore.left, 1));
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(find.text('step_move'), findsNothing);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);

    final timelineRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
    );
    await gesture.moveTo(timelineRect.topLeft - const Offset(16, 16));
    await tester.pumpAndSettle();

    expect(hoverDetails, findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-highlight-step_move')),
      findsNothing,
    );
    final selectedFaceAfterExit = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    expect(selectedFaceAfterExit.selected, isTrue);
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('navigates selected timeline blocks with local keyboard focus', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
      findsOneWidget,
    );
    expect(find.text('Aide clavier'), findsOneWidget);
    expect(find.text('Navigation clavier : ← → ↑ ↓ Home End'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final selectedCameraBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
    );
    final cameraCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
    );
    final cameraCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(selectedCameraBar.selected, isTrue);
    expect(cameraCursorRect.center.dx, closeTo(cameraCardRect.left, 1));
    expect(find.text('Sélection : 0 ms'), findsOneWidget);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.textContaining('1. Camera reveal'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final selectedFaceBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    final faceCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    final faceCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    expect(selectedFaceBar.selected, isTrue);
    expect(faceCursorRect.center.dx, closeTo(faceCardRect.left, 1));
    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(find.text('Professor turns'), findsWidgets);
    expect(find.textContaining('2. Professor turns'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final selectedWaitBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_wait')),
    );
    expect(selectedWaitBar.selected, isTrue);
    expect(find.text('Beat'), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
          )
          .selected,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();

    final selectedSoundBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    final soundCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    final soundCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    expect(selectedSoundBar.selected, isTrue);
    expect(soundCursorRect.center.dx, closeTo(soundCardRect.left, 1));
    expect(find.text('Cue bell'), findsWidgets);
    expect(find.textContaining('6. Cue bell'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(
              const ValueKey('cinematic-builder-step-card-step_sound'),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(
              const ValueKey('cinematic-builder-step-card-step_camera'),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(
              const ValueKey('cinematic-builder-step-card-step_camera'),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets('keyboard navigation scrolls selected timeline block into view', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_longTimelineCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_long_probe',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
    );
    await tester.pumpAndSettle();

    final horizontalScroll = _timelineHorizontalScrollController(tester);
    expect(horizontalScroll.position.pixels, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_wait_9');
    expect(horizontalScroll.position.pixels, greaterThan(0));

    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
    );
    final selectedCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_wait_9')),
    );
    expect(selectedCardRect.left, greaterThanOrEqualTo(viewportRect.left - 1));
    expect(selectedCardRect.right, lessThanOrEqualTo(viewportRect.right + 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_wait_0');
    expect(horizontalScroll.position.pixels, lessThan(1));
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets(
    'shows compact keyboard navigation help without changing timeline selection',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');

      final helpButton = find.byKey(
        const ValueKey('cinematic-builder-keyboard-help-button'),
      );
      final cursorBefore = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );

      expect(helpButton, findsOneWidget);
      expect(find.text('Aide clavier'), findsOneWidget);
      expect(find.text('Navigation clavier : ← → ↑ ↓ Home End'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
        findsNothing,
      );

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
        findsOneWidget,
      );
      expect(find.text('← / →'), findsOneWidget);
      expect(find.text('Bloc précédent / suivant'), findsOneWidget);
      expect(find.text('↑ / ↓'), findsOneWidget);
      expect(find.text('Piste précédente / suivante'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Premier bloc'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Dernier bloc'), findsOneWidget);
      expect(
        find.text(
          'Sélection uniquement — pas de lecture ni déplacement temporel.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);

      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.textContaining('2. Professor turns'), findsOneWidget);
      final cursorAfterOpen = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(cursorAfterOpen.left, closeTo(cursorBefore.left, 1));

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
        findsNothing,
      );
      _expectTimelineStepSelected(tester, 'step_face');
      final cursorAfterClose = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(cursorAfterClose.left, closeTo(cursorBefore.left, 1));
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets(
    'navigates selected timeline blocks vertically with local keyboard focus',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_camera');
      expect(find.text('Sélection : 0 ms'), findsOneWidget);
      expect(find.text('Camera reveal'), findsWidgets);
      expect(find.text('step_camera'), findsWidgets);
      expect(find.textContaining('1. Camera reveal'), findsOneWidget);

      final moveCardRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(moveCardRect.center);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cinematic-builder-hover-details')),
        findsOneWidget,
      );
      expect(find.text('Survol : Professor → Centre scène'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');
      expect(find.text('Sélection : 500 ms'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('step_face'), findsWidgets);
      expect(find.textContaining('2. Professor turns'), findsOneWidget);

      final faceCursorRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      final faceCardRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      expect(faceCursorRect.center.dx, closeTo(faceCardRect.left, 1));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_camera');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_sound');
      expect(find.text('Sélection : 2.7 s'), findsOneWidget);
      expect(find.text('Cue bell'), findsWidgets);
      expect(find.text('step_sound'), findsWidgets);
      expect(find.textContaining('6. Cue bell'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_move');
      expect(find.text('Sélection : 1.1 s'), findsOneWidget);
      expect(find.text('Professor → Centre scène'), findsWidgets);
      expect(find.text('step_move'), findsWidgets);
      expect(
        find.textContaining('4. Professor → Centre scène'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_camera');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_camera');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_fade');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_wait');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_wait');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_move');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_wait');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_sound');

      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets('uses step index as vertical navigation tie break', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_verticalTieBreakCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_vertical_tie_break',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_camera_a');
    expect(find.text('Camera left'), findsWidgets);
    expect(find.text('step_camera_a'), findsWidgets);
  });

  testWidgets(
    'handles vertical navigation without selection and empty timelines',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_wait');
      expect(find.text('Sélection : 800 ms'), findsOneWidget);
      expect(find.text('Beat'), findsWidgets);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);

      final emptyProject = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_empty',
            title: 'Empty cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
        includeBridge: false,
      );
      final emptyBefore = emptyProject.toJson();
      await _pumpBuilder(
        tester,
        _entry(emptyProject, 'cinematic_empty'),
        asset: _asset(emptyProject, 'cinematic_empty'),
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(find.text('Timeline vide'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsNothing,
      );
      expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
      expect(emptyProject.toJson(), emptyBefore);
    },
  );

  testWidgets('keeps keyboard shortcuts local and protects text fields', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    var projectChangeCount = 0;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (_) => projectChangeCount += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(
              const ValueKey('cinematic-builder-step-card-step_sound'),
            ),
          )
          .selected,
      isTrue,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    final faceCursorBefore = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );

    final sceneTab = find.byKey(
      const ValueKey('cinematic-builder-inspector-tab-scene'),
    );
    await tester.tap(sceneTab);
    await tester.pumpAndSettle();

    final labelField = find.byKey(
      const ValueKey('cinematic-builder-movement-target-label-target_center'),
    );
    await tester.ensureVisible(labelField);
    await tester.tap(labelField);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    final selectedFaceBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    final faceCursorAfter = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(selectedFaceBar.selected, isTrue);
    expect(faceCursorAfter.left, closeTo(faceCursorBefore.left, 1));
    expect(find.text('Professor turns'), findsWidgets);
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(find.text('Playing'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(find.text('Seek'), findsNothing);
    expect(projectChangeCount, 0);
    expect(project.toJson(), before);
  });

  testWidgets(
    'keeps vertical keyboard shortcuts local and protects text fields',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final project = _project(cinematics: [_timeLayoutCinematic()]);
      final before = project.toJson();
      var projectChangeCount = 0;
      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (_) => projectChangeCount += 1,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectTimelineStepSelected(tester, 'step_face');
      final faceCursorBefore = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );

      final sceneTab = find.byKey(
        const ValueKey('cinematic-builder-inspector-tab-scene'),
      );
      await tester.tap(sceneTab);
      await tester.pumpAndSettle();

      final labelField = find.byKey(
        const ValueKey('cinematic-builder-movement-target-label-target_center'),
      );
      await tester.ensureVisible(labelField);
      await tester.tap(labelField);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      final faceCursorAfter = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      );
      expect(faceCursorAfter.left, closeTo(faceCursorBefore.left, 1));
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('Professor → Centre scène'), findsWidgets);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Playing'), findsNothing);
      expect(find.text('Scrubber'), findsNothing);
      expect(find.text('Seek'), findsNothing);
      expect(projectChangeCount, 0);
      expect(project.toJson(), before);
    },
  );

  testWidgets('balances sandbox preview and useful timeline grid proportions', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-preview-placeholder')),
    );
    final timelineRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
    );
    final timelineGridRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
    );
    final timeContentRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-content')),
    );
    final cameraLaneRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-lane-camera')),
    );
    final professorLaneFinder = find.byKey(
      const ValueKey('cinematic-builder-lane-actor:actor_professor'),
    );
    final dialogueLaneFinder = find.byKey(
      const ValueKey('cinematic-builder-lane-dialogue'),
    );
    final cameraLaneLabelFinder = find.descendant(
      of: find.byKey(const ValueKey('cinematic-builder-lane-camera')),
      matching: find.text('Caméra'),
    );
    final professorLaneLabelFinder = find.descendant(
      of: professorLaneFinder,
      matching: find.text('Professor'),
    );
    final dialogueLaneLabelFinder = find.descendant(
      of: dialogueLaneFinder,
      matching: find.text('Dialogue'),
    );
    final cameraBarRect = tester.getRect(
      find.byKey(
        const ValueKey('cinematic-builder-time-visual-bar-step_camera'),
      ),
    );
    final audioLaneRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-lane-audio')),
    );

    expect(timelineRect.height, greaterThanOrEqualTo(420));
    expect(timelineGridRect.top - timelineRect.top, lessThanOrEqualTo(90));
    expect(timelineGridRect.height, greaterThanOrEqualTo(335));
    expect(
      timelineGridRect.height,
      greaterThanOrEqualTo(previewRect.height * 0.78),
    );
    expect(cameraLaneRect.width, greaterThanOrEqualTo(124));
    expect(cameraLaneRect.width, lessThanOrEqualTo(136));
    expect(
      timeContentRect.width,
      greaterThanOrEqualTo(timelineGridRect.width * 0.83),
    );
    expect(cameraLaneLabelFinder, findsOneWidget);
    expect(professorLaneLabelFinder, findsOneWidget);
    expect(
      find.descendant(
        of: professorLaneFinder,
        matching: find.textContaining('Acteur:'),
      ),
      findsNothing,
    );
    expect(dialogueLaneLabelFinder, findsOneWidget);
    expect(
      tester.getRect(cameraLaneLabelFinder).width,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getRect(professorLaneLabelFinder).width,
      greaterThanOrEqualTo(68),
    );
    expect(
      tester.getRect(dialogueLaneLabelFinder).width,
      greaterThanOrEqualTo(68),
    );
    expect(cameraLaneRect.height, greaterThanOrEqualTo(46));
    expect(cameraBarRect.height, greaterThanOrEqualTo(34));
    expect(audioLaneRect.bottom, lessThanOrEqualTo(timelineGridRect.bottom));
    expect(previewRect.height, lessThanOrEqualTo(450));
    expect(timelineRect.top, greaterThan(previewRect.bottom));
  });

  testWidgets('lists timeline steps in order with read-only details', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_richCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );

    expect(find.text('Déroulé'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-lane-actor:actor_professor'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-dialogue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-audio')),
      findsOneWidget,
    );
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Aucun step'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Camera to door'), findsWidgets);
    expect(find.text('camera'), findsWidgets);
    expect(find.text('400 ms'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Professor line'), findsWidgets);
    expect(find.text('dialogueLine'), findsWidgets);
    expect(find.text('1200 ms'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Door chime'), findsWidgets);
    expect(find.text('sound'), findsWidgets);
    expect(find.text('300 ms'), findsWidgets);

    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(find.text('Supprimer le bloc'), findsNothing);
    for (final key in <String>[
      'cinematic-builder-duration-ms-field',
      'cinematic-builder-actor-facing-duration-ms-field',
      'cinematic-builder-actor-move-duration-ms-field',
      'cinematic-builder-remove-authoring-step-button',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsNothing);
    }
    expect(project.toJson(), before);
  });

  testWidgets('selects a step locally and updates read-only inspector', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_richCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );

    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();

    final selectedDialogueCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    expect(selectedDialogueCard.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_dialogue'), findsWidgets);
    expect(find.text('Index'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Kind'), findsWidgets);
    expect(find.text('dialogueLine'), findsWidgets);
    expect(find.text('Dialogue'), findsWidgets);
    expect(find.text('Labo sécurisé.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    await tester.pumpAndSettle();

    final selectedSoundCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    expect(selectedSoundCard.selected, isTrue);
    expect(find.text('step_sound'), findsWidgets);
    expect(find.text('Asset'), findsWidgets);
    expect(find.text('door_chime'), findsWidgets);
    expect(find.text('volume = 0.8'), findsOneWidget);
    expect(project.toJson(), before);
  });

  testWidgets('shows lane grouping V0 without enabling actor movement', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_laneShowcaseCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_lane_showcase'),
      asset: _asset(project, 'cinematic_lane_showcase'),
    );

    for (final key in <String>[
      'cinematic-builder-lane-camera',
      'cinematic-builder-lane-actor:actor_professor',
      'cinematic-builder-lane-actor:actor_rival',
      'cinematic-builder-lane-dialogue',
      'cinematic-builder-lane-fx',
      'cinematic-builder-lane-audio',
      'cinematic-builder-lane-transitions',
      'cinematic-builder-lane-time-global',
      'cinematic-builder-lane-other',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }

    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Rival'), findsWidgets);
    expect(find.text('Aucun step'), findsWidgets);
    expect(find.text('Déroulé'), findsOneWidget);
    expect(find.text('9 piste(s)'), findsOneWidget);
    expect(find.text('Déplacer un acteur'), findsOneWidget);
    expect(find.text('Ajoutez d’abord une destination'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-actorMove-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('cinematic-builder-palette-actorMove-button'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.pumpAndSettle();

    final selectedFaceCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    expect(selectedFaceCard.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_face'), findsWidgets);
    expect(find.text('Direction'), findsWidgets);
    expect(project.toJson(), before);
  });

  testWidgets('shows step diagnostics without enabling timeline changes', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_diagnosticCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_diagnostic'),
      asset: _asset(project, 'cinematic_diagnostic'),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1'), findsWidgets);
    expect(find.text('cinematicInvalidStepDuration'), findsWidgets);
    expect(
      find.text(
        'Une durée cinematic doit être comprise entre 100 ms et 30000 ms.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aucune action de correction dans ce lot.'), findsWidgets);
    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(find.text('Sauvegarder'), findsWidgets);
    expect(project.toJson(), before);
  });

  testWidgets('adds a safe draft after selected step and inspects it', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    final addDraftButton = find.byKey(
      const ValueKey('cinematic-builder-add-draft-button'),
    );
    await tester.ensureVisible(addDraftButton);
    await tester.tap(addDraftButton);
    await tester.pumpAndSettle();

    expect(find.text('Bloc brouillon'), findsWidgets);
    expect(find.text('Brouillon'), findsWidgets);
    expect(find.text('marker'), findsWidgets);
    expect(find.text('Statut'), findsWidgets);
    expect(find.text('Placeholder authoring'), findsOneWidget);
    expect(
      find.text('Durée non éditable — brouillon sans effet moteur.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'authoring.kind = draft, authoring.source = cinematic-builder-v0',
      ),
      findsOneWidget,
    );
    final selectedDraftCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
    );
    expect(selectedDraftCard.selected, isTrue);
    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
      ['step_camera', 'step_dialogue', 'step_draft', 'step_sound'],
    );
    expect(latestProject.scenes, project.scenes);
    expect(latestProject.scenarios, project.scenarios);
  });

  testWidgets('removes only the selected draft from the builder', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    final cameraStepCard = find.byKey(
      const ValueKey('cinematic-builder-step-card-step_camera'),
    );
    await tester.ensureVisible(cameraStepCard);
    await tester.tap(cameraStepCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    final addDraftButton = find.byKey(
      const ValueKey('cinematic-builder-add-draft-button'),
    );
    await tester.ensureVisible(addDraftButton);
    await tester.tap(addDraftButton);
    await tester.pumpAndSettle();
    expect(find.text('Bloc brouillon'), findsWidgets);
    final removeButton = find.byKey(
      const ValueKey('cinematic-builder-remove-authoring-step-button'),
    );
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
      findsNothing,
    );
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
      ['step_camera', 'step_dialogue', 'step_sound'],
    );
  });

  testWidgets('adds and edits wait fade and camera basic blocks', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attente'), findsWidgets);
    expect(find.text('Bloc authoring V0'), findsOneWidget);
    expect(find.text('wait'), findsWidgets);
    expect(find.text('1000 ms'), findsWidgets);
    expect(
      latestProject.cinematics.single.timeline.steps.last.kind,
      CinematicTimelineStepKind.wait,
    );
    expect(
      latestProject.cinematics.single.timeline.steps.last.metadata,
      containsPair('authoring.block', 'wait'),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
    );
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.last.durationMs,
      2000,
    );

    final durationField = find.byKey(
      const ValueKey('cinematic-builder-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    expect(durationField, findsOneWidget);
    await tester.enterText(durationField, '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(latestProject.cinematics.single.timeline.steps.last.durationMs, 250);
    expect(find.text('250 ms'), findsWidgets);

    await tester.enterText(durationField, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(latestProject.cinematics.single.timeline.steps.last.durationMs, 250);
    expect(
      find.byKey(const ValueKey('cinematic-builder-duration-validation')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
    );
    await tester.pumpAndSettle();

    final fadeStep = latestProject.cinematics.single.timeline.steps.last;
    expect(fadeStep.kind, CinematicTimelineStepKind.fade);
    expect(fadeStep.metadata, containsPair('fade.mode', 'fadeOut'));
    expect(find.text('Fondu sortant'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
    );
    await tester.pumpAndSettle();

    final cameraStep = latestProject.cinematics.single.timeline.steps.last;
    expect(cameraStep.kind, CinematicTimelineStepKind.camera);
    expect(cameraStep.actorId, isNull);
    expect(cameraStep.targetId, isNull);
    expect(cameraStep.metadata, containsPair('camera.mode', 'hold'));
    expect(find.text('Caméra'), findsWidgets);
    expect(find.text('Hold'), findsWidgets);

    final removeAuthoringStepButton = find.byKey(
      const ValueKey('cinematic-builder-remove-authoring-step-button'),
    );
    await tester.ensureVisible(removeAuthoringStepButton);
    await tester.tap(removeAuthoringStepButton);
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [
        CinematicTimelineStepKind.camera,
        CinematicTimelineStepKind.dialogueLine,
        CinematicTimelineStepKind.sound,
        CinematicTimelineStepKind.wait,
        CinematicTimelineStepKind.fade,
      ],
    );
  });

  testWidgets('adds a required actor before enabling actor facing', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_actor',
          title: 'No actor cinematic',
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_no_actor',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorFaceButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorFace-button'),
    );
    expect(actorFaceButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorFaceButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord un acteur requis'), findsOneWidget);

    await tester.enterText(
      find.byKey(
        const ValueKey('cinematic-builder-required-actor-label-field'),
      ),
      'Lysa',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-required-actor-button')),
    );
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.requiredActors.single.actorId,
      'actor',
    );
    expect(latestProject.cinematics.single.requiredActors.single.label, 'Lysa');
    expect(find.text('Lysa'), findsWidgets);
    expect(tester.widget<PokeMapButton>(actorFaceButton).onPressed, isNotNull);
  });

  testWidgets('renames required actor from expanded actor row', (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_rename_actor',
          title: 'Rename actor cinematic',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
          ],
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rename_actor',
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.enterText(
      find.byKey(const ValueKey('cinematic-builder-actor-label-actor_rival')),
      'Lysa',
    );
    await tester.pumpAndSettle();
    final saveButton = find.byKey(
      const ValueKey('cinematic-builder-save-required-actor-actor_rival'),
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final actor = latestProject.cinematics.single.requiredActors.single;
    expect(actor.actorId, 'actor_rival');
    expect(actor.label, 'Lysa');
    expect(find.text('Lysa'), findsWidgets);
  });

  testWidgets('removes unused required actor from expanded actor row', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_remove_actor',
          title: 'Remove actor cinematic',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.mapEntity,
                mapEntityId: 'entity_rival',
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_rival',
                characterId: 'character_rival',
              ),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_rival',
                kind: CinematicActorInitialPlacementKind.fromMapEntity,
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    var latestProject = project;
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_remove_actor',
      onProjectChanged: (project) => latestProject = project,
    );

    final deleteButton = find.byKey(
      const ValueKey('cinematic-builder-delete-required-actor-actor_rival'),
    );
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    final asset = _asset(latestProject, 'cinematic_remove_actor');
    expect(asset.requiredActors, isEmpty);
    expect(asset.stageContext?.actorBindings, isEmpty);
    expect(asset.stageContext?.actorAppearanceBindings, isEmpty);
    expect(asset.stageContext?.initialPlacements, isEmpty);
    expect(find.text('Rival'), findsNothing);
  });

  testWidgets(
    'keeps required actor delete disabled while actor is used by timeline',
    (tester) async {
      _setLargeSurface(tester);
      final project = _project(
        cinematics: [
          CinematicAsset(
            id: 'cinematic_used_actor',
            title: 'Used actor cinematic',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_face',
                  kind: CinematicTimelineStepKind.actorFace,
                  label: 'Orientation Rival',
                  actorId: 'actor_rival',
                  metadata: const {
                    cinematicTimelineActorDirectionMetadataKey: 'down',
                  },
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      );
      await _pumpBuilderHarness(tester, project, 'cinematic_used_actor');

      final deleteButtonFinder = find.byKey(
        const ValueKey('cinematic-builder-delete-required-actor-actor_rival'),
      );
      await tester.ensureVisible(deleteButtonFinder);
      await tester.pumpAndSettle();
      final deleteButton = tester.widget<PokeMapButton>(deleteButtonFinder);

      expect(deleteButton.onPressed, isNull);
      expect(
        find.text('Cet acteur est utilisé par 1 bloc(s) timeline.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('adds and edits actor facing with actor picker and direction', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorFacingCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_face',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-actorFace-button')),
      findsOneWidget,
    );
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Rival'), findsWidgets);

    final actorFaceButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorFace-button'),
    );
    await tester.ensureVisible(actorFaceButton);
    await tester.tap(actorFaceButton);
    await tester.pumpAndSettle();

    var actorFaceStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorFaceStep.kind, CinematicTimelineStepKind.actorFace);
    expect(actorFaceStep.label, 'Orientation Professor');
    expect(actorFaceStep.actorId, 'actor_professor');
    expect(
      actorFaceStep.metadata,
      containsPair('authoring.block', 'actorFace'),
    );
    expect(actorFaceStep.metadata, containsPair('actor.direction', 'down'));
    expect(actorFaceStep.durationMs, isNull);
    expect(find.text('Orientation Professor'), findsWidgets);
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Direction'), findsWidgets);

    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    expect(durationField, findsOneWidget);
    await tester.enterText(durationField, '1500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    actorFaceStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorFaceStep.durationMs, 1500);
    expect(find.text('1500 ms'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-direction-left')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-direction-left')),
    );
    await tester.pumpAndSettle();

    actorFaceStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorFaceStep.actorId, 'actor_rival');
    expect(actorFaceStep.label, 'Orientation Rival');
    expect(actorFaceStep.metadata, containsPair('actor.direction', 'left'));
    expect(find.text('Rival'), findsWidgets);
    expect(find.text('Gauche'), findsWidgets);

    final removeActorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-remove-authoring-step-button'),
    );
    await tester.ensureVisible(removeActorMoveButton);
    await tester.tap(removeActorMoveButton);
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [CinematicTimelineStepKind.wait],
    );
  });

  testWidgets('enables actor movement only after actor and target exist', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_target',
          title: 'No target cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_no_target',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    expect(actorMoveButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord une destination'), findsOneWidget);

    final targetBtn = find.byKey(
      const ValueKey('cinematic-builder-add-movement-target-button'),
    );
    await tester.ensureVisible(targetBtn);
    await tester.tap(targetBtn);
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.movementTargets.single.targetId,
      'target',
    );
    expect(
      latestProject.cinematics.single.movementTargets.single.label,
      'Destination',
    );
    expect(find.text('Destinations'), findsWidgets);
    expect(find.text('Destination'), findsWidgets);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNotNull);
  });

  testWidgets(
    'binds actor movement destination to a stage point from the action inspector',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      late ProjectManifest latestProject;
      final asset = CinematicAsset(
        id: 'cinematic_actor_move_destination_picker',
        title: 'Actor move destination picker',
        mapId: 'map_lab',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_jean', label: 'Jean'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(targetId: 'target', label: 'Cible'),
        ],
        stageContext: CinematicStageContext(
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Repère 2',
              x: 8.5,
              y: 10.5,
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_move',
              kind: CinematicTimelineStepKind.actorMove,
              label: 'Déplacement Jean',
              actorId: 'actor_jean',
              targetId: 'target',
              durationMs: 800,
              metadata: const {
                cinematicTimelineDraftMetadataKindKey:
                    cinematicTimelineBasicBlockMetadataKindValue,
                cinematicTimelineDraftMetadataSourceKey:
                    cinematicTimelineDraftMetadataSourceValue,
                cinematicTimelineAuthoringBlockMetadataKey:
                    cinematicTimelineActorMoveBlockMetadataValue,
                cinematicTimelineActorMovementModeMetadataKey: 'walk',
                cinematicTimelineActorPathModeMetadataKey: 'manual',
              },
            ),
          ],
        ),
      );
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (project) => latestProject = project,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-step_move'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-inspector-tab-action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repère final du déplacement'), findsOneWidget);
      expect(
        find.text(
          'Choisissez un repère pour que le déplacement puisse être prévisualisé.',
        ),
        findsOneWidget,
      );

      final destinationPoint = find.byKey(
        const ValueKey(
          'cinematic-builder-actor-move-destination-stage-point-target-stage_point_2',
        ),
      );
      await tester.ensureVisible(destinationPoint);
      await tester.tap(destinationPoint);
      await tester.pumpAndSettle();

      final binding = latestProject
          .cinematics.single.stageContext?.movementTargetBindings.single;
      expect(binding, isNotNull);
      expect(binding!.targetId, 'target');
      expect(binding.kind, CinematicMovementTargetBindingKind.stagePoint);
      expect(binding.sourceId, 'stage_point_2');
      expect(find.text('Destination actuelle : Repère 2'), findsOneWidget);
      expect(find.text('Picker label + id stable'), findsNothing);
    },
  );

  testWidgets(
    'V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      late ProjectManifest latestProject;
      final asset = CinematicAsset(
        id: 'cinematic_actor_move_destination_isolation',
        title: 'Actor move destination isolation',
        mapId: 'map_lab',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          CinematicActorRef(actorId: 'actor_jean', label: 'Jean'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre',
          ),
        ],
        stageContext: CinematicStageContext(
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'stage_point_center',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_center',
              label: 'Centre',
              x: 4.5,
              y: 4.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_left',
              label: 'Gauche',
              x: 2.5,
              y: 4.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_right',
              label: 'Droite',
              x: 8.5,
              y: 4.5,
            ),
          ],
        ),
        timeline: CinematicTimeline(),
      );
      final project = _project(cinematics: [asset], includeBridge: false);

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (project) => latestProject = project,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final actorMoveButton = find.byKey(
        const ValueKey('cinematic-builder-palette-actorMove-button'),
      );
      await tester.ensureVisible(actorMoveButton);
      await tester.tap(actorMoveButton);
      await tester.pumpAndSettle();

      final firstMove = latestProject.cinematics.single.timeline.steps.single;
      expect(firstMove.targetId, 'target_center');

      await tester.ensureVisible(actorMoveButton);
      await tester.tap(actorMoveButton);
      await tester.pumpAndSettle();

      final secondMove = latestProject.cinematics.single.timeline.steps.last;
      expect(secondMove.id, isNot(firstMove.id));
      expect(secondMove.targetId, isNot('target_center'));
      expect(secondMove.targetId, isNot(firstMove.targetId));

      final secondTargetBefore = secondMove.targetId!;
      final assetBeforeDestinationEdit = latestProject.cinematics.single;
      expect(assetBeforeDestinationEdit.movementTargets, hasLength(2));
      expect(
        assetBeforeDestinationEdit.stageContext!.movementTargetBindings
            .singleWhere((binding) => binding.targetId == firstMove.targetId)
            .sourceId,
        'stage_point_center',
      );
      expect(
        assetBeforeDestinationEdit.stageContext!.movementTargetBindings
            .singleWhere((binding) => binding.targetId == secondTargetBefore)
            .sourceId,
        'stage_point_center',
      );

      final firstMoveCard = find.byKey(
        ValueKey('cinematic-builder-step-card-${firstMove.id}'),
      );
      await tester.ensureVisible(firstMoveCard);
      await tester.tap(firstMoveCard);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-inspector-tab-action')),
      );
      await tester.pumpAndSettle();

      final firstDestinationButton = find.byKey(
        ValueKey(
          'cinematic-builder-actor-move-destination-stage-point-${firstMove.targetId}-stage_point_left',
        ),
      );
      await tester.ensureVisible(firstDestinationButton);
      await tester.tap(firstDestinationButton);
      await tester.pumpAndSettle();

      final updatedAsset = latestProject.cinematics.single;
      final updatedFirstMove = updatedAsset.timeline.steps.firstWhere(
        (step) => step.id == firstMove.id,
      );
      final updatedSecondMove = updatedAsset.timeline.steps.firstWhere(
        (step) => step.id == secondMove.id,
      );
      expect(updatedFirstMove.targetId, firstMove.targetId);
      expect(updatedSecondMove.targetId, secondTargetBefore);

      final firstBinding = updatedAsset.stageContext!.movementTargetBindings
          .singleWhere(
              (binding) => binding.targetId == updatedFirstMove.targetId);
      final secondBinding = updatedAsset.stageContext!.movementTargetBindings
          .singleWhere(
              (binding) => binding.targetId == updatedSecondMove.targetId);
      expect(firstBinding.sourceId, 'stage_point_left');
      expect(secondBinding.sourceId, 'stage_point_center');
      expect(
        updatedAsset.stageContext!.manualPaths
            .where((path) =>
                path.ownerActorMoveStepId == firstMove.id ||
                path.ownerActorMoveStepId == secondMove.id)
            .toList(),
        isEmpty,
      );
    },
  );

  testWidgets('keeps actor movement disabled without required actor', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_actor_move',
          title: 'No actor move cinematic',
          movementTargets: [
            CinematicMovementTargetRef(targetId: 'target', label: 'Cible'),
          ],
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(tester, project, 'cinematic_no_actor_move');

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    expect(actorMoveButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord un acteur'), findsOneWidget);
  });

  testWidgets('adds edits and removes actor movement authoring block', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorMovementCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_move',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    var actorMoveStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorMoveStep.kind, CinematicTimelineStepKind.actorMove);
    expect(actorMoveStep.label, 'Déplacement Professor');
    expect(actorMoveStep.actorId, 'actor_professor');
    expect(actorMoveStep.targetId, 'target_center');
    expect(actorMoveStep.durationMs, 1000);
    expect(
      actorMoveStep.metadata,
      containsPair('authoring.block', 'actorMove'),
    );
    expect(actorMoveStep.metadata, containsPair('actor.movementMode', 'walk'));
    expect(actorMoveStep.metadata, containsPair('actor.pathMode', 'direct'));
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Centre scène'), findsWidgets);
    expect(find.text('Mode mouvement'), findsOneWidget);
    expect(find.text('Trajet'), findsWidgets);
    expect(find.text('Direct'), findsWidgets);
    expect(find.text('Manuel'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-target-picker-target_exit')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-target-picker-target_exit')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-preset-2000'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-preset-2000'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-decrement-100'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-decrement-100'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-increment-100'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-move-mode-run')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-move-mode-run')),
    );
    await tester.pumpAndSettle();

    actorMoveStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorMoveStep.actorId, 'actor_rival');
    expect(actorMoveStep.targetId, 'target_exit');
    expect(actorMoveStep.durationMs, 2000);
    expect(actorMoveStep.metadata, containsPair('actor.movementMode', 'run'));
    expect(actorMoveStep.metadata, containsPair('actor.pathMode', 'direct'));
    expect(find.text('Rival → Sortie'), findsWidgets);
    expect(find.text('Sortie'), findsWidgets);
    expect(find.text('Course'), findsWidgets);

    final removeActorMoveStepButton = find.byKey(
      const ValueKey('cinematic-builder-remove-authoring-step-button'),
    );
    await tester.ensureVisible(removeActorMoveStepButton);
    await tester.tap(removeActorMoveStepButton);
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [CinematicTimelineStepKind.wait],
    );
  });

  testWidgets('polishes movement target labels and actor movement inspector', (
    tester,
  ) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorMovementCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_move',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Professor marche vers Centre scène en 1000 ms.'),
      findsOneWidget,
    );
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Trajet'), findsWidgets);
    expect(find.text('Direct'), findsWidgets);
    expect(find.text('Manuel'), findsWidgets);

    final sceneTab = find.byKey(
      const ValueKey('cinematic-builder-inspector-tab-scene'),
    );
    await tester.tap(sceneTab);
    await tester.pumpAndSettle();

    final usedDeleteButton = find.byKey(
      const ValueKey('cinematic-builder-delete-movement-target-target_center'),
    );
    await tester.ensureVisible(usedDeleteButton);
    expect(tester.widget<PokeMapButton>(usedDeleteButton).onPressed, isNull);
    expect(
      find.text(
        'Cette destination est utilisée par un bloc Déplacer un acteur.',
      ),
      findsOneWidget,
    );

    final labelField = find.byKey(
      const ValueKey('cinematic-builder-movement-target-label-target_center'),
    );
    await tester.ensureVisible(labelField);
    await tester.enterText(labelField, 'Centre du plateau');
    await tester.enterText(
      find.byKey(
        const ValueKey(
          'cinematic-builder-movement-target-description-target_center',
        ),
      ),
      'Point central authoring.',
    );
    final saveTargetButton = find.byKey(
      const ValueKey('cinematic-builder-save-movement-target-target_center'),
    );
    await tester.ensureVisible(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.tap(saveTargetButton);
    await tester.pumpAndSettle();

    final renamedTarget = latestProject.cinematics.single.movementTargets
        .singleWhere((target) => target.targetId == 'target_center');
    expect(renamedTarget.label, 'Centre du plateau');
    expect(renamedTarget.description, 'Point central authoring.');
    expect(
      latestProject.cinematics.single.timeline.steps.last.label,
      'Déplacement Professor',
    );
    final actionTab = find.byKey(
      const ValueKey('cinematic-builder-inspector-tab-action'),
    );
    await tester.tap(actionTab);
    await tester.pumpAndSettle();
    expect(
      find.text('Professor marche vers Centre du plateau en 1000 ms.'),
      findsOneWidget,
    );
    expect(find.text('Professor → Centre du plateau'), findsWidgets);
    await tester.tap(sceneTab);
    await tester.pumpAndSettle();

    await tester.enterText(labelField, '   ');
    await tester.ensureVisible(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.tap(saveTargetButton);
    await tester.pumpAndSettle();
    expect(find.text('Nom de destination obligatoire'), findsOneWidget);
    expect(
      latestProject.cinematics.single.movementTargets
          .singleWhere((target) => target.targetId == 'target_center')
          .label,
      'Centre du plateau',
    );

    final unusedDeleteButton = find.byKey(
      const ValueKey('cinematic-builder-delete-movement-target-target_exit'),
    );
    await tester.ensureVisible(unusedDeleteButton);
    expect(
      tester.widget<PokeMapButton>(unusedDeleteButton).onPressed,
      isNotNull,
    );
    await tester.tap(unusedDeleteButton);
    await tester.pumpAndSettle();
    expect(
      latestProject.cinematics.single.movementTargets.map(
        (target) => target.targetId,
      ),
      ['target_center'],
    );
    expect(find.text('target_exit'), findsNothing);
  });

  testWidgets('shows empty timeline state without authoring controls', (
    tester,
  ) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_empty',
          title: 'Empty cinematic',
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_empty'),
      asset: _asset(project, 'cinematic_empty'),
    );

    expect(find.text('Empty cinematic'), findsWidgets);
    expect(find.text('Timeline vide'), findsWidgets);
    expect(
      find.text('Cette cinématique ne contient encore aucun bloc.'),
      findsOneWidget,
    );
    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
      findsOneWidget,
    );
  });

  testWidgets('calls back to library from builder header', (tester) async {
    _setLargeSurface(tester);
    var returned = false;
    await _pumpBuilder(
      tester,
      _entry(_project(), 'cinematic_intro'),
      asset: _asset(_project(), 'cinematic_intro'),
      onBackToLibrary: () => returned = true,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(returned, isTrue);
  });

  testWidgets('captures V1-43 builder timeline screenshot when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-44 builder draft screenshot when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_44_CAPTURE_CINEMATIC_BUILDER_DRAFTS',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_richCinematic()]),
      'cinematic_rich',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-45 builder basic blocks screenshot when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_45_CAPTURE_CINEMATIC_BUILDER_BASIC_BLOCKS',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_richCinematic()]),
      'cinematic_rich',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-46 builder actor facing screenshot when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_46_CAPTURE_CINEMATIC_BUILDER_ACTOR_FACING',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_actorFacingCinematic()]),
      'cinematic_actor_face',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-actorFace-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-48 builder lane grouping screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_48_CAPTURE_CINEMATIC_TIMELINE_LANES',
      )) {
        return;
      }

      _setLargeSurface(tester);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_laneVisualGateCinematic()]),
        'cinematic_lane_visual_gate',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
        const Offset(0, 260),
      );
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-49 actor movement block screenshot when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_49_CAPTURE_CINEMATIC_ACTOR_MOVEMENT',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_actorMovementCinematic()]),
      'cinematic_actor_move',
    );
    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_49_cinematic_actor_movement_block_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-50 actor movement target polish screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_50_CAPTURE_CINEMATIC_ACTOR_MOVEMENT_POLISH',
      )) {
        return;
      }

      _setLargeSurface(tester);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_actorMovementCinematic()]),
        'cinematic_actor_move',
      );
      final actorMoveButton = find.byKey(
        const ValueKey('cinematic-builder-palette-actorMove-button'),
      );
      await tester.ensureVisible(actorMoveButton);
      await tester.tap(actorMoveButton);
      await tester.pumpAndSettle();

      final labelField = find.byKey(
        const ValueKey('cinematic-builder-movement-target-label-target_center'),
      );
      await tester.ensureVisible(labelField);
      await tester.enterText(labelField, 'Centre du plateau');
      await tester.enterText(
        find.byKey(
          const ValueKey(
            'cinematic-builder-movement-target-description-target_center',
          ),
        ),
        'Point central authoring.',
      );
      final saveTargetButton = find.byKey(
        const ValueKey('cinematic-builder-save-movement-target-target_center'),
      );
      await tester.ensureVisible(saveTargetButton);
      await tester.pumpAndSettle();
      await tester.tap(saveTargetButton);
      await tester.pumpAndSettle();
      await tester.ensureVisible(labelField);
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_'
        'target_labels_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-51 timeline time axis bar layout when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_51_CAPTURE_CINEMATIC_TIMELINE_BAR_LAYOUT',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    final cameraRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
    );
    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-52 timeline selection cursor when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_52_CAPTURE_CINEMATIC_TIMELINE_SELECTION_CURSOR',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_52_cinematic_timeline_selection_cursor_'
      'playhead_placeholder_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-53 timeline transport controls placeholder when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_53_CAPTURE_CINEMATIC_TIMELINE_TRANSPORT_CONTROLS',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );
      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_53_cinematic_timeline_transport_controls_'
        'placeholder_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-54 timeline visual polish density pass when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_54_CAPTURE_CINEMATIC_TIMELINE_VISUAL_POLISH',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );
      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_54_cinematic_timeline_visual_polish_'
        'density_pass_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-55 timeline hover details polish when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_55_CAPTURE_CINEMATIC_TIMELINE_HOVER_DETAILS',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
    await tester.pumpAndSettle();

    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(moveRect.center);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cinematic-builder-hover-details')),
      findsOneWidget,
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_55_cinematic_timeline_interaction_polish_'
      'hover_details_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-56 timeline bar geometry correction when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_56_CAPTURE_CINEMATIC_TIMELINE_BAR_GEOMETRY',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );
      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();

      final moveRect = tester.getRect(
        find.byKey(
          const ValueKey('cinematic-builder-time-visual-bar-step_move'),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(moveRect.center);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cinematic-builder-hover-details')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_56_cinematic_timeline_bar_geometry_'
        'duration_scale_correction_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-57 timeline keyboard navigation selection polish when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_57_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_NAVIGATION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
        findsOneWidget,
      );
      expect(find.text('Navigation clavier : ← → ↑ ↓ Home End'), findsNothing);
      expect(
        tester
            .widget<PokeMapCard>(
              find.byKey(
                const ValueKey('cinematic-builder-step-card-step_face'),
              ),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_'
        'selection_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-59 cinematic timeline lane vertical navigation when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_59_CAPTURE_CINEMATIC_TIMELINE_VERTICAL_NAVIGATION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
        findsOneWidget,
      );
      expect(find.text('Navigation clavier : ← → ↑ ↓ Home End'), findsNothing);
      _expectTimelineStepSelected(tester, 'step_face');
      expect(
        find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-60 cinematic timeline keyboard navigation help when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_60_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_HELP',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-time-grid-viewport')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
      );
      await tester.pumpAndSettle();

      _expectTimelineStepSelected(tester, 'step_face');
      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-panel')),
        findsOneWidget,
      );
      expect(find.text('← / →'), findsOneWidget);
      expect(find.text('↑ / ↓'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Navigation clavier : ← → ↑ ↓ Home End'), findsNothing);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_'
        'polish_help_overlay_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-62 cinematic timeline mouse time probe when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_62_CAPTURE_CINEMATIC_TIMELINE_MOUSE_TIME_PROBE',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();

      final tick0Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-0')),
      );
      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      final pxPer500Ms = tick500Rect.left - tick0Rect.left;
      await tester.tapAt(
        Offset(tick0Rect.left + pxPer500Ms * 1.5, axisRect.center.dy),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marqueur : 750 ms'), findsOneWidget);
      expect(find.text('Marqueur temps : 750 ms'), findsOneWidget);
      expect(
        find.text('Marqueur local : inspection uniquement.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-time-probe-cursor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-transport-controls')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_'
        'playhead_drag_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-64 cinematic timeline mouse probe snap when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_64_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_SNAP',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
      await tester.pumpAndSettle();

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
          tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(
        find.byKey(const ValueKey('cinematic-builder-transport-controls')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-65 cinematic timeline mouse probe clear controls when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_65_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_CLEAR_CONTROLS',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
      await tester.pumpAndSettle();

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
          tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
      expect(
        find.text('Marqueur local : inspection uniquement.'),
        findsOneWidget,
      );
      expect(find.text('Effacer le marqueur'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-clear-time-probe-button')),
        findsOneWidget,
      );
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('Sélection : 500 ms'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-transport-controls')),
        findsOneWidget,
      );
      _expectTransportControlsPresent(tester);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_'
        'clear_controls_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-66 cinematic timeline mouse probe help when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_66_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_HELP',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      await _pumpBuilderHarness(
        tester,
        _project(cinematics: [_timeLayoutCinematic()]),
        'cinematic_time_layout',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
      await tester.pumpAndSettle();

      final tick500Rect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-tick-500')),
      );
      final axisRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-axis')),
      );
      await _placeTimelineProbeAt(
          tester, Offset(tick500Rect.left + 6, axisRect.center.dy));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-probe-help-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marqueur : 500 ms · début bloc'), findsOneWidget);
      expect(find.text('Aide timeline'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-probe-help-panel')),
        findsOneWidget,
      );
      expect(find.text('Sélection : bloc inspecté.'), findsOneWidget);
      expect(
        find.text('Marqueur : position temporelle locale.'),
        findsOneWidget,
      );
      expect(
        find.text('Alignement : marqueur calé sur une borne utile.'),
        findsOneWidget,
      );
      expect(find.text('Preview : lecture réelle à venir.'), findsOneWidget);
      expect(find.text('Professor turns'), findsWidgets);
      expect(find.text('Sélection : 500 ms'), findsNothing);
      expect(
        find.byKey(const ValueKey('cinematic-builder-keyboard-help-button')),
        findsOneWidget,
      );
      _expectTransportControlsPresent(tester);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_'
        'selection_explanation_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-68 duration inspector editing when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_68_CAPTURE_CINEMATIC_TIMELINE_DURATION_INSPECTOR',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    late ProjectManifest latestProject;
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
    await tester.pumpAndSettle();
    final durationField = find.byKey(
      const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
    );
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '700');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      700,
    );
    expect(durationField, findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-transport-controls')),
      findsOneWidget,
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_68_cinematic_timeline_duration_inspector_'
      'editing_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-69 duration resize handles when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_69_CAPTURE_CINEMATIC_TIMELINE_DURATION_RESIZE',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    late ProjectManifest latestProject;
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_durationResizeCinematic()]),
      'cinematic_duration_resize',
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (project) => latestProject = project,
    );

    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(faceRect.center);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    _expectTimelineStepSelected(tester, 'step_face');
    expect(
      latestProject.cinematics.single.timeline.steps
          .singleWhere((step) => step.id == 'step_face')
          .durationMs,
      greaterThan(500),
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cinematic-builder-transport-controls')),
      findsOneWidget,
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_69_cinematic_timeline_duration_resize_'
      'handles_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-70 duration validation diagnostics polish when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_70_CAPTURE_CINEMATIC_TIMELINE_DURATION_VALIDATION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      var latestProject = _project(cinematics: [_durationResizeCinematic()]);
      await _pumpBuilderHarness(
        tester,
        latestProject,
        'cinematic_duration_resize',
        surfaceSize: _referenceTimelineSurfaceSize,
        onProjectChanged: (project) => latestProject = project,
      );

      final faceRect = tester.getRect(
        find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
      );
      await tester.tapAt(faceRect.center);
      await tester.pumpAndSettle();
      final durationField = find.byKey(
        const ValueKey('cinematic-builder-actor-facing-duration-ms-field'),
      );
      await tester.ensureVisible(durationField);
      await tester.enterText(durationField, '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Bornes : 100–30000 ms · pas 100 ms'), findsOneWidget);
      expect(find.text('Minimum pour ce bloc : 100 ms.'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('cinematic-builder-duration-resize-handle-step_face'),
        ),
        findsOneWidget,
      );
      expect(
        latestProject.cinematics.single.timeline.steps
            .singleWhere((step) => step.id == 'step_face')
            .durationMs,
        500,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-transport-controls')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_70_cinematic_timeline_duration_validation_'
        'diagnostics_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-73 cinematic stage map context editor when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_73_CAPTURE_CINEMATIC_STAGE_CONTEXT_EDITOR',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(
        cinematics: [
          _stageContextCinematic(
            stageContext: CinematicStageContext(
              backdropMode: CinematicStageBackdropMode.projectMap,
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_professor',
                  kind: CinematicActorBindingKind.player,
                ),
              ],
              initialPlacements: [
                CinematicActorInitialPlacement(
                  actorId: 'actor_professor',
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: 'target_center',
                ),
              ],
              movementTargetBindings: [
                CinematicMovementTargetBinding(
                  targetId: 'target_center',
                  kind: CinematicMovementTargetBindingKind.abstractPoint,
                ),
              ],
            ),
          ),
        ],
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_context',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(find.text('Contexte de scène'), findsOneWidget);
      expect(find.text('Map de scène'), findsOneWidget);
      expect(find.text('Lab map'), findsWidgets);
      expect(find.text('Décor depuis la map'), findsWidgets);
      expect(find.text('Acteurs'), findsWidgets);
      expect(find.text('Destinations'), findsWidgets);
      expect(find.text('État de la scène'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-timeline-keyboard-focus')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-transport-controls')),
        findsOneWidget,
      );

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-74 cinematic stage preview readiness polish when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_74_CAPTURE_CINEMATIC_STAGE_PREVIEW_READINESS',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(cinematics: [_stageContextCinematic()]);

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_context',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(find.text('Aperçu sandbox'), findsOneWidget);
      expect(find.text('Contexte de scène'), findsOneWidget);

      final stateTile = find.text('État de la scène');
      await tester.ensureVisible(stateTile);
      await tester.tap(stateTile);
      await tester.pumpAndSettle();

      expect(find.text('Préparation preview'), findsOneWidget);
      expect(find.text('Incomplet'), findsWidgets);
      expect(
        find.textContaining('La preview réelle arrivera plus tard.'),
        findsWidgets,
      );
      expect(find.textContaining('Map de scène — OK'), findsWidgets);
      expect(find.textContaining('Décor — OK'), findsWidgets);
      expect(find.textContaining('Acteurs liés — À compléter'), findsWidgets);
      expect(
        find.textContaining('Départs de scène — À compléter'),
        findsWidgets,
      );
      expect(find.textContaining('Destinations — À compléter'), findsWidgets);
      expect(
        find.textContaining(
          'Sources de la map — OK : aucune source de la map requise',
        ),
        findsWidgets,
      );
      expect(find.text('Lab map'), findsWidgets);
      expect(find.text('Décor depuis la map'), findsWidgets);
      expect(find.text('Acteurs'), findsWidgets);
      expect(find.text('Binding'), findsWidgets);
      expect(find.text('Destinations'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Scène non jouée.'), findsWidgets);
      expect(find.text('Lecture en cours'), findsNothing);
      _expectTransportControlsPresent(tester);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_74_cinematic_stage_context_diagnostics_'
        'preview_readiness_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-77 cinematic stage map source pickers when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_77_CAPTURE_CINEMATIC_STAGE_MAP_PICKERS',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(cinematics: [_stageContextCinematic()]);

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_stage_context',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final mapEventButton = find.byKey(
        const ValueKey(
          'cinematic-builder-target-binding-target_center-mapEvent',
        ),
      );
      await tester.ensureVisible(mapEventButton);
      await tester.tap(mapEventButton);
      await tester.pumpAndSettle();

      expect(find.text('Sources events'), findsWidgets);
      expect(find.text('Gate bell'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey(
            'cinematic-builder-target-binding-target_center-mapEvent-source-event_gate_bell',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-80 cinematic character library picker when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_80_CAPTURE_CINEMATIC_CHARACTER_PICKER',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(
        characters: const [
          ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: 'characters/rival',
            frameWidth: 32,
            frameHeight: 32,
            tags: ['rival', 'cinematic'],
          ),
          ProjectCharacterEntry(
            id: 'character_guard',
            name: 'Garde',
            tilesetId: 'characters/guard',
            frameWidth: 32,
            frameHeight: 32,
            tags: ['port'],
            sortOrder: 1,
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_character_picker_capture',
            title: 'Character picker capture',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  label: 'Entrée rival',
                  durationMs: 500,
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_character_picker_capture',
        surfaceSize: _referenceTimelineSurfaceSize,
      );
      final toggle = find.byKey(
        const ValueKey(
          'cinematic-builder-character-appearance-actor_rival-toggle',
        ),
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('Personnages'), findsWidgets);
      expect(find.text('Rival'), findsWidgets);
      expect(find.text('Garde'), findsWidgets);
      expect(find.text('characters/rival · 32×32'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_80_cinematic_character_library_picker_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-81 cinematic actor appearance drift diagnostics polish when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_81_CAPTURE_CINEMATIC_ACTOR_APPEARANCE_DRIFT',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(
        characters: const [
          ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: 'characters/rival',
            frameWidth: 32,
            frameHeight: 32,
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_character_drift_capture',
            title: 'Character drift capture',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival actor'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.player,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_rival',
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  label: 'Entrée rival',
                  durationMs: 500,
                ),
              ],
            ),
          ),
        ],
        includeBridge: false,
      );

      await _pumpBuilderHarness(
        tester,
        project,
        'cinematic_character_drift_capture',
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('cinematic-builder-stage-actors-section')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('cinematic-builder-inspector-placeholder')),
        const Offset(0, 390),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aperçu sandbox'), findsOneWidget);
      expect(find.text('Acteurs'), findsWidgets);
      expect(find.text('Apparence'), findsWidgets);
      expect(
        find.text('Cet acteur n’est plus en “Cinématique uniquement”.'),
        findsOneWidget,
      );
      expect(
        find.text('L’apparence Character Library ne s’applique plus.'),
        findsOneWidget,
      );
      expect(find.text('Retirer l’apparence'), findsOneWidget);
      expect(find.text('Préparation preview'), findsOneWidget);
      expect(
        find.textContaining('Apparences acteurs — À corriger'),
        findsWidgets,
      );
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      _expectTransportControlsPresent(tester);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_81_cinematic_actor_appearance_readiness_'
        'drift_diagnostics_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-84 cinematic map backdrop preview when requested', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_84_CAPTURE_CINEMATIC_MAP_BACKDROP_PREVIEW',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    final project = _project(cinematics: [_stageContextCinematic()]);
    final asset = _asset(project, 'cinematic_stage_context');
    final stageMapData = _stageMapDataWithVisualLayers();
    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: stageMapData,
      viewportSize: const CinematicMapBackdropViewportSize(
        width: 920,
        height: 260,
      ),
    );

    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_stage_context'),
      asset: asset,
      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      backdropPreviewModel: backdropModel,
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
      findsOneWidget,
    );
    expect(find.text('Décor disponible'), findsOneWidget);
    expect(find.text('Décor seul'), findsWidgets);
    expect(find.text('Déroulé'), findsOneWidget);
    expect(find.text('Lecture en cours'), findsNothing);
    expect(tester.takeException(), isNull);

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
    'captures V1-85 cinematic map backdrop visual primitives when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_85_CAPTURE_CINEMATIC_MAP_BACKDROP_VISUAL_PRIMITIVES',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(cinematics: [_stageContextCinematic()]);
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithVisualLayers();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fallback structurel'), findsOneWidget);
      expect(find.text('6 primitive(s) spatiale(s)'), findsOneWidget);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-86 cinematic map backdrop visual composition when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_86_CAPTURE_CINEMATIC_MAP_BACKDROP_VISUAL_COMPOSITION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final project = _project(cinematics: [_stageContextCinematic()]);
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithVisualLayers();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 360,
        ),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final mapViewportSize = tester.getSize(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-visual-viewport'),
        ),
      );
      expect(mapViewportSize.shortestSide, greaterThanOrEqualTo(220));
      expect(find.text('Fallback structurel'), findsOneWidget);
      expect(find.text('6 primitive(s) spatiale(s)'), findsOneWidget);
      expect(find.text('Lab map'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-inspector-placeholder')),
        findsOneWidget,
      );
      expect(find.text('Décor seul'), findsWidgets);
      expect(find.text('Sans acteurs'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);
      expect(find.text('Professor Oak'), findsNothing);
      expect(find.text('Collision'), findsNothing);
      expect(find.text('Couche collision'), findsNothing);
      expect(find.text('Lecture en cours'), findsNothing);
      _expectTransportControlsPresent(tester);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-88 cinematic map backdrop real tile renderer when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_88_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_RENDERER',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final tilesetImage = await _makeReferenceTilesetImage();
      final project = _project(cinematics: [_stageContextCinematic()]);
      final asset = _asset(project, 'cinematic_stage_context');
      final stageMapData = _stageMapDataWithReferenceBitmapLayer();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 360,
        ),
      );
      final bitmapProject = project.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'lab_tiles',
            name: 'Lab tiles',
            relativePath: 'assets/tilesets/lab.png',
          ),
        ],
        settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      );
      final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
        mapData: stageMapData,
        manifest: bitmapProject,
        tilesets: {
          'lab_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'lab_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_stage_context'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        backdropTileRenderPlan: tileRenderPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(find.text('Décor disponible'), findsOneWidget);
      expect(find.text('Tiles réelles affichées'), findsWidgets);
      expect(find.text('Décor seul'), findsWidgets);
      expect(find.text('Sans acteurs'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Professor Oak'), findsNothing);
      expect(find.text('Collision'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-92 cinematic actor display preview renderer when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_92_CAPTURE_CINEMATIC_ACTOR_DISPLAY_PREVIEW',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final tilesetImage = await _makeReferenceTilesetImage();
      final asset = _actorDisplayPreviewCinematic();
      final project = _project(cinematics: [asset]);
      final stageMapData = _stageMapDataWithActorDisplayFixtures();
      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: asset,
        stageMap: project.maps.single,
        mapData: stageMapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 360,
        ),
      );
      final bitmapProject = project.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'lab_tiles',
            name: 'Lab tiles',
            relativePath: 'assets/tilesets/lab.png',
          ),
        ],
        settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
      );
      final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
        mapData: stageMapData,
        manifest: bitmapProject,
        tilesets: {
          'lab_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'lab_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );
      final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
        cinematic: asset,
        project: project,
        stageMap: project.maps.single,
        mapData: stageMapData,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
      );

      await _pumpBuilder(
        tester,
        _entry(project, 'cinematic_actor_display_preview'),
        asset: asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
        backdropPreviewModel: backdropModel,
        backdropTileRenderPlan: tileRenderPlan,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-actor-display-overlay')),
        findsOneWidget,
      );
      expect(find.text('Animation acteur prête'), findsWidgets);
      expect(find.text('3 acteur(s) placés'), findsWidgets);
      expect(find.text('2 à compléter'), findsWidgets);
      expect(find.text('Aperçu statique'), findsWidgets);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-94 cinematic extended map backdrop visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_94_CAPTURE_CINEMATIC_EXTENDED_MAP_BACKDROP',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _extendedBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, 'cinematic_stage_context'),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(find.text('Tiles réelles affichées'), findsWidgets);
      expect(find.text('7 couche(s) bitmap'), findsWidgets);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(find.text('Neutral event'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-95 cinematic backdrop framing zoom controls when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_95_CAPTURE_CINEMATIC_BACKDROP_FRAMING_ZOOM_CONTROLS',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();

      final pathInstructions = fixture.layerPlan.instructions
          .where((instruction) => instruction.sourceFamily == 'path')
          .toList();
      expect(pathInstructions, isNotEmpty);
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
        findsOneWidget,
      );
      expect(find.text('Carte entière'), findsOneWidget);
      expect(find.text('Vue scène'), findsOneWidget);
      expect(find.text('Zoom 1.25×'), findsOneWidget);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-95-bis cinematic backdrop canvas ux polish visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_95_BIS_CAPTURE_CINEMATIC_BACKDROP_CANVAS_UX',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vue scène'), findsOneWidget);
      expect(find.text('Zoom 1.25×'), findsOneWidget);
      expect(find.text('Grille masquée'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-details')),
        findsNothing,
      );
      expect(find.textContaining('Pan'), findsOneWidget);
      expect(find.text('Déroulé'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-inspector-placeholder')),
        findsOneWidget,
      );
      expect(find.text('Lecture en cours'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-105 cinematic builder ux simplification destination vocabulary visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_105_CAPTURE_CINEMATIC_BUILDER_UX_SIMPLIFICATION',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final asset = _stageContextCinematic(
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
          initialPlacements: [
            CinematicActorInitialPlacement(
              actorId: 'actor_professor',
              kind: CinematicActorInitialPlacementKind.stagePoint,
              stagePointId: 'stage_point_1',
            ),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'stage_point_2',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Repère 1',
              x: 1.5,
              y: 1.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Repère 2',
              x: 2.5,
              y: 2.5,
            ),
          ],
        ),
      );
      final project = _extendedBackdropProject(cinematics: [asset]);
      final fixture = await _extendedBackdropFixture(
        asset: asset,
        project: project,
      );
      final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
        cinematic: fixture.asset,
        project: fixture.project,
        stageMap: fixture.project.maps.single,
        mapData: fixture.mapData,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
      );

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajouter au déroulé'), findsOneWidget);
      expect(find.text('Ajouter un repère'), findsWidgets);
      expect(find.text('Réglages'), findsWidgets);
      expect(find.text('Préparer la scène'), findsWidgets);
      expect(find.text('Destination'), findsWidgets);
      expect(find.text('Repère de scène'), findsWidgets);
      expect(find.text('Position libre'), findsWidgets);
      expect(
        find.textContaining('Personnage ou objet de la map'),
        findsWidgets,
      );
      expect(find.textContaining('Déclencheur de map'), findsWidgets);
      expect(find.text('Timeline cinématique'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-stage-points-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematic-builder-actor-display-overlay')),
        findsOneWidget,
      );
      for (final forbidden in <String>[
        'Ajouter un point',
        'Point abstrait',
        'Point de scène',
        'Cibles de déplacement',
        'Id: target',
        'Vue simple',
      ]) {
        expect(find.text(forbidden), findsNothing);
      }
      expect(find.textContaining('sourceId'), findsNothing);
      expect(find.textContaining('targetId'), findsNothing);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'orders cinematic backdrop placed elements by visual depth around the actor overlay',
    (tester) async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();
      final manifest = _extendedBackdropProject();
      final mapData = _stageMapDataWithExtendedBackdrop().copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'tree_B',
            layerId: 'neutral_objects',
            elementId: 'neutral_tree',
            pos: GridPos(x: 2, y: 2), // bottom = 2 + 2 = 4
          ),
          MapPlacedElement(
            id: 'tree_A',
            layerId: 'neutral_objects',
            elementId: 'neutral_tree',
            pos: GridPos(x: 1, y: 1), // bottom = 1 + 2 = 3
          ),
          MapPlacedElement(
            id: 'tree_C',
            layerId: 'neutral_objects',
            elementId: 'neutral_tree',
            pos: GridPos(x: 3, y: 0), // bottom = 0 + 2 = 2
          ),
        ],
      );

      final beforeManifest = manifest.toJson();
      final beforeMapData = mapData.toJson();

      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: mapData,
        manifest: manifest,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      // Verifies sorting by visual depth (bottom Y): C (2), A (3), B (4)
      final bgInstructions = plan.instructions
          .where(
            (inst) =>
                inst.renderPass ==
                CinematicMapBackdropRenderPass.placedBackground,
          )
          .toList();
      expect(bgInstructions, hasLength(3));
      expect(bgInstructions[0].sourceId, 'tree_C');
      expect(bgInstructions[1].sourceId, 'tree_A');
      expect(bgInstructions[2].sourceId, 'tree_B');

      final fgInstructions = plan.instructions
          .where(
            (inst) =>
                inst.renderPass ==
                CinematicMapBackdropRenderPass.placedForeground,
          )
          .toList();
      expect(fgInstructions, hasLength(3));
      expect(fgInstructions[0].sourceId, 'tree_C');
      expect(fgInstructions[1].sourceId, 'tree_A');
      expect(fgInstructions[2].sourceId, 'tree_B');

      // Verifies it does not mutate project or mapData
      expect(manifest.toJson(), beforeManifest);
      expect(mapData.toJson(), beforeMapData);
    },
  );

  testWidgets(
    'keeps placed foreground above actor placeholders when marked as foreground',
    (tester) async {
      final tilesetImage = await _makeExtendedBackdropTilesetImage();

      // Test with layer name marked as foreground
      final manifest = _extendedBackdropProject();
      final mapData = _stageMapDataWithExtendedBackdrop().copyWith(
        layers: [
          const MapLayer.object(
            id: 'foreground_layer_objects',
            name: 'Foreground Object Layer',
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'tree_foreground',
            layerId: 'foreground_layer_objects',
            elementId: 'neutral_tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      final plan = buildCinematicMapBackdropLayerRenderPlan(
        mapData: mapData,
        manifest: manifest,
        tilesets: {
          'neutral_tiles': CinematicResolvedTilesetAsset.available(
            tilesetId: 'neutral_tiles',
            image: tilesetImage,
            tileWidth: 8,
            tileHeight: 8,
          ),
        },
      );

      // Since the layer is explicitly marked as foreground, all cells (even collision) go to placedForeground pass
      final fgInstructions = plan.instructions
          .where((inst) => inst.sourceId == 'tree_foreground')
          .toList();
      expect(fgInstructions, hasLength(2));
      expect(
        fgInstructions.every(
          (inst) =>
              inst.renderPass ==
              CinematicMapBackdropRenderPass.placedForeground,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'captures V1-96 cinematic backdrop depth z order parity visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_96_CAPTURE_CINEMATIC_BACKDROP_DEPTH_Z_ORDER',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vue scène'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-96-bis real Map Editor ordering fix visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_96_BIS_CAPTURE_REAL_MAP_EDITOR_ORDERING',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vue scène'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-99 cinematic actor sprite renderer visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_99_CAPTURE_CINEMATIC_ACTOR_SPRITE_RENDERER',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      final professorActor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_professor',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 6,
          y: 7,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'neutral_tiles',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final fallbackActor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_unresolved',
        label: 'Missing actor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.unbound,
        bindingKind: CinematicActorBindingKind.unbound,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 9,
          y: 7,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.missingCharacter,
          characterId: 'char_missing',
          tilesetId: 'neutral_tiles',
        ),
        direction: CinematicActorPreviewDirection.north,
        directionSource: CinematicActorPreviewDirectionSource.fallback,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final actorDisplayModel = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '2 actor(s)',
        actors: [professorActor, fallbackActor],
        diagnostics: const [],
      );

      final actorSpritePreviewPlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_professor',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 6, y: 7),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'neutral_tiles',
              sourceTileRect: TilesetSourceRect(
                x: 0,
                y: 0,
                width: 1,
                height: 2,
              ),
              frameWidthTiles: 1,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 6,
              tileY: 7,
              anchorTileX: 6.5,
              anchorTileY: 9.0,
              visualBottom: 9.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint:
                  CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
          CinematicActorSpritePreviewActor(
            actorId: 'actor_unresolved',
            actorLabel: 'Missing actor',
            bindingKind: CinematicActorBindingKind.unbound,
            position: const GridPos(x: 9, y: 7),
            direction: CinematicActorPreviewDirection.north,
            status: CinematicActorSpriteStatus.missingCharacter,
            placeholderFallback: true,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 9,
              tileY: 7,
              anchorTileX: 9.5,
              anchorTileY: 9.0,
              visualBottom: 9.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint:
                  CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      await _pumpBuilder(
        tester,
        _entry(fixture.project, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        actorDisplayPreviewModel: actorDisplayModel,
        actorSpritePreviewPlan: actorSpritePreviewPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vue scène'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-99-bis cinematic actor sprite real asset fidelity visual gate polish v0 when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_99_BIS_CAPTURE_REAL_ACTOR_SPRITE_FIDELITY',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      ui.Image? actorImage;
      await tester.runAsync(() async {
        final file = File(
          'test/fixtures/cinematics/actor_sprite_test_sheet.png',
        );
        final bytes = file.readAsBytesSync();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        actorImage = frame.image;
      });

      // Create a new layer plan with the real actor sprite tileset
      final newLayerPlan = CinematicMapBackdropLayerRenderPlan(
        mapWidth: fixture.layerPlan.mapWidth,
        mapHeight: fixture.layerPlan.mapHeight,
        tileWidth: fixture.layerPlan.tileWidth,
        tileHeight: fixture.layerPlan.tileHeight,
        tilesets: {
          ...fixture.layerPlan.tilesets,
          'real_actor_tileset': CinematicResolvedTilesetAsset.available(
            tilesetId: 'real_actor_tileset',
            image: actorImage!,
            tileWidth: 32,
            tileHeight: 32,
          ),
        },
        instructions: fixture.layerPlan.instructions,
        diagnostics: fixture.layerPlan.diagnostics,
      );

      final professorActor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_professor',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 6,
          y: 7,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'real_actor_tileset',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final fallbackActor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_unresolved',
        label: 'Missing actor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.unbound,
        bindingKind: CinematicActorBindingKind.unbound,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 9,
          y: 7,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.missingCharacter,
          characterId: 'char_missing',
          tilesetId: 'real_actor_tileset',
        ),
        direction: CinematicActorPreviewDirection.north,
        directionSource: CinematicActorPreviewDirectionSource.fallback,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final actorDisplayModel = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '2 actor(s)',
        actors: [professorActor, fallbackActor],
        diagnostics: const [],
      );

      final actorSpritePreviewPlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_professor',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 6, y: 7),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'real_actor_tileset',
              sourceTileRect: TilesetSourceRect(
                x: 0,
                y: 0,
                width: 2,
                height: 2,
              ),
              frameWidthTiles: 2,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 6,
              tileY: 7,
              anchorTileX: 7.0,
              anchorTileY: 9.0,
              visualBottom: 9.0,
              footprintWidthTiles: 2,
              footprintHeightTiles: 2,
              preferredRendererHint:
                  CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
          CinematicActorSpritePreviewActor(
            actorId: 'actor_unresolved',
            actorLabel: 'Missing actor',
            bindingKind: CinematicActorBindingKind.unbound,
            position: const GridPos(x: 9, y: 7),
            direction: CinematicActorPreviewDirection.north,
            status: CinematicActorSpriteStatus.missingCharacter,
            placeholderFallback: true,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 9,
              tileY: 7,
              anchorTileX: 9.5,
              anchorTileY: 9.0,
              visualBottom: 9.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint:
                  CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final updatedManifest = fixture.project.copyWith(
        characters: [
          ...fixture.project.characters,
          ProjectCharacterEntry(
            id: 'char_professor',
            name: 'Professor',
            tilesetId: 'real_actor_tileset',
            frameWidth: 2,
            frameHeight: 2,
            animations: [
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.south,
                frames: [
                  CharacterAnimationFrame(
                    source: const TilesetSourceRect(
                      x: 0,
                      y: 0,
                      width: 2,
                      height: 2,
                    ),
                    durationMs: 150,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpBuilder(
        tester,
        _entry(updatedManifest, fixture.asset.id),
        asset: fixture.asset,
        stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
        backdropPreviewModel: fixture.backdropModel,
        backdropLayerRenderPlan: newLayerPlan,
        actorDisplayPreviewModel: actorDisplayModel,
        actorSpritePreviewPlan: actorSpritePreviewPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-scene-mode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(
          const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
        ),
        const Offset(-120, -80),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vue scène'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'captures V1-102 cinematic preview point placement ui visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_102_CAPTURE_PREVIEW_POINT_PLACEMENT',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      final assetWithPoints = CinematicAsset(
        id: fixture.asset.id,
        title: fixture.asset.title,
        description: fixture.asset.description,
        storylineId: fixture.asset.storylineId,
        chapterId: fixture.asset.chapterId,
        mapId: fixture.asset.mapId,
        tags: fixture.asset.tags,
        requiredActors: fixture.asset.requiredActors,
        movementTargets: fixture.asset.movementTargets,
        stageContext: CinematicStageContext(
          backdropMode: fixture.asset.stageContext?.backdropMode ??
              CinematicStageBackdropMode.projectMap,
          actorBindings: fixture.asset.stageContext?.actorBindings ?? const [],
          actorAppearanceBindings:
              fixture.asset.stageContext?.actorAppearanceBindings ?? const [],
          initialPlacements:
              fixture.asset.stageContext?.initialPlacements ?? const [],
          movementTargetBindings:
              fixture.asset.stageContext?.movementTargetBindings ?? const [],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
          ],
        ),
        timeline: fixture.asset.timeline,
        notes: fixture.asset.notes,
        metadata: fixture.asset.metadata,
        legacyBridge: fixture.asset.legacyBridge,
      );

      final project = _project(cinematics: [assetWithPoints]);

      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: assetWithPoints,
        stageMap: project.maps.single,
        mapData: fixture.mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      await _pumpBuilder(
        tester,
        _entry(project, assetWithPoints.id),
        asset: assetWithPoints,
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // Tap on Point 1 to select it so the inspector shows it
      await tester.tap(find.text('Point 1').last);
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-102-bis — Stage Point Placement UX Discoverability and ESC cancellation',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largePathStudioWaterBackdropFixture();
      final project = _project(cinematics: [fixture.asset]);

      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: fixture.asset,
        stageMap: project.maps.single,
        mapData: fixture.mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      await _pumpBuilderHarness(
        tester,
        project,
        fixture.asset.id,
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // 1. Verify that when no stage points exist, the empty state helper message is displayed
      expect(
        find.text(
          'Aucun repère de scène. Cliquez sur « Ajouter un repère », puis cliquez sur la carte.',
        ),
        findsOneWidget,
      );

      // 2. Verify that the "Ajouter un repère" text button is visible and active
      final addPointBtn = find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-add-stage-point-toggle'),
      );
      expect(addPointBtn, findsOneWidget);
      expect(
        find.descendant(
          of: addPointBtn,
          matching: find.text('Ajouter un repère'),
        ),
        findsOneWidget,
      );

      // 3. Click the "Ajouter un repère" button to enter placement mode
      await tester.tap(addPointBtn);
      await tester.pumpAndSettle();

      // 4. Verify that the button text changes to "Annuler l’ajout" and active placement banner is displayed
      expect(
        find.descendant(
          of: addPointBtn,
          matching: find.text('Annuler l’ajout'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mode placement actif — Cliquez sur la carte pour poser un repère. Échap pour annuler.',
        ),
        findsOneWidget,
      );

      // 5. Test Escape key deactivates the mode
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: addPointBtn,
          matching: find.text('Ajouter un repère'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mode placement actif — Cliquez sur la carte pour poser un repère. Échap pour annuler.',
        ),
        findsNothing,
      );

      // 6. Enter mode again, and verify that clicking on the map canvas places a point
      await tester.tap(addPointBtn);
      await tester.pumpAndSettle();

      final viewport = find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
      );
      final viewportCenter = tester.getCenter(viewport);
      await tester.tapAt(viewportCenter);
      await tester.pumpAndSettle();

      // 7. Verify point was created and mode exited automatically (generated ID is '1', so label is 'Repère 1')
      expect(find.text('Repère 1'), findsNWidgets(2));
      expect(
        find.descendant(
          of: addPointBtn,
          matching: find.text('Ajouter un repère'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mode placement actif — Cliquez sur la carte pour poser un repère. Échap pour annuler.',
        ),
        findsNothing,
      );

      // 8. Verify inspector panel displays the selected point inputs
      expect(
        find.byKey(const ValueKey('cinematic-stage-point-label-input')),
        findsOneWidget,
      );

      // 9. Verify that typing in a TextField and pressing Escape does NOT exit the mode or break the input (it should retain text)
      final labelInput = find.byKey(
        const ValueKey('cinematic-stage-point-label-input'),
      );
      await tester.enterText(labelInput, 'Updated Point');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Updated Point'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'captures V1-102-bis stage point placement ux discoverability visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_102_BIS_CAPTURE_STAGE_POINT_UX_DISCOVERABILITY',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      final assetWithPoints = CinematicAsset(
        id: fixture.asset.id,
        title: fixture.asset.title,
        description: fixture.asset.description,
        storylineId: fixture.asset.storylineId,
        chapterId: fixture.asset.chapterId,
        mapId: fixture.asset.mapId,
        tags: fixture.asset.tags,
        requiredActors: fixture.asset.requiredActors,
        movementTargets: fixture.asset.movementTargets,
        stageContext: CinematicStageContext(
          backdropMode: fixture.asset.stageContext?.backdropMode ??
              CinematicStageBackdropMode.projectMap,
          actorBindings: fixture.asset.stageContext?.actorBindings ?? const [],
          actorAppearanceBindings:
              fixture.asset.stageContext?.actorAppearanceBindings ?? const [],
          initialPlacements:
              fixture.asset.stageContext?.initialPlacements ?? const [],
          movementTargetBindings:
              fixture.asset.stageContext?.movementTargetBindings ?? const [],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
          ],
        ),
        timeline: fixture.asset.timeline,
        notes: fixture.asset.notes,
        metadata: fixture.asset.metadata,
        legacyBridge: fixture.asset.legacyBridge,
      );

      final project = _project(cinematics: [assetWithPoints]);

      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: assetWithPoints,
        stageMap: project.maps.single,
        mapData: fixture.mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      await _pumpBuilder(
        tester,
        _entry(project, assetWithPoints.id),
        asset: assetWithPoints,
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // Tap on Point 1 to select it so the inspector shows it
      await tester.tap(find.text('Point 1').last);
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets(
    'V1-103 — Cinematic Actor Initial Placement from Stage Points V0',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      final fixture = await _largePathStudioWaterBackdropFixture();

      final assetWithPoints = CinematicAsset(
        id: fixture.asset.id,
        title: fixture.asset.title,
        description: fixture.asset.description,
        storylineId: fixture.asset.storylineId,
        chapterId: fixture.asset.chapterId,
        mapId: fixture.asset.mapId,
        tags: fixture.asset.tags,
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: const [],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
          actorAppearanceBindings: const [],
          initialPlacements: const [],
          movementTargetBindings: const [],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
          ],
        ),
        timeline: fixture.asset.timeline,
        notes: fixture.asset.notes,
        metadata: fixture.asset.metadata,
        legacyBridge: fixture.asset.legacyBridge,
      );

      final project = _project(cinematics: [assetWithPoints]);

      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: assetWithPoints,
        stageMap: project.maps.single,
        mapData: fixture.mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      await _pumpBuilderHarness(
        tester,
        project,
        assetWithPoints.id,
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // 1. Select the required actor Professor to open its sidebar inspector
      final actorRow = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Professor' && w.style?.fontSize == 14.0,
      );
      expect(actorRow, findsOneWidget);
      await tester.ensureVisible(actorRow);
      await tester.pumpAndSettle();

      // 2. Verify we see the initial placement choice block in the inspector
      final radioStagePoint = find.byKey(
        const ValueKey(
          'cinematic-builder-initial-placement-actor_professor-stagePoint',
        ),
      );
      expect(radioStagePoint, findsOneWidget);
      await tester.ensureVisible(radioStagePoint);

      // 3. Tap on the stagePoint radio option — auto-selects first point
      await tester.tap(radioStagePoint);
      await tester.pumpAndSettle();

      // 4. Verify the selected point label "Point 1" appears in the subselector
      //    This proves the onUpsertActorInitialPlacement callback was called
      //    with stagePoint kind + stage_point_1 id, and the UI re-rendered.
      final subselectorValue = find.descendant(
        of: find.byKey(
          const ValueKey('cinematic-builder-actor-row-actor_professor'),
        ),
        matching: find.byKey(
          const ValueKey('cinematic-builder-subselector-value'),
        ),
      );
      expect(subselectorValue, findsOneWidget);
      expect(tester.widget<Text>(subselectorValue).data, 'Point 1');
    },
  );

  testWidgets('V1-104 — Cinematic ActorMove Target from Stage Points V0', (
    tester,
  ) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _largePathStudioWaterBackdropFixture();

    final assetWithPoints = CinematicAsset(
      id: fixture.asset.id,
      title: fixture.asset.title,
      description: fixture.asset.description,
      storylineId: fixture.asset.storylineId,
      chapterId: fixture.asset.chapterId,
      mapId: fixture.asset.mapId,
      tags: fixture.asset.tags,
      requiredActors: [
        CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      ],
      movementTargets: [
        CinematicMovementTargetRef(
          targetId: 'target_center',
          label: 'Centre scène',
        ),
      ],
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor_professor',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
        ],
        actorAppearanceBindings: const [],
        initialPlacements: const [],
        movementTargetBindings: const [],
        stagePoints: [
          CinematicStagePoint(
            id: 'stage_point_1',
            label: 'Point 1',
            x: 2.5,
            y: 3.5,
          ),
          CinematicStagePoint(
            id: 'stage_point_2',
            label: 'Point 2',
            x: 8.5,
            y: 10.5,
          ),
        ],
      ),
      timeline: fixture.asset.timeline,
      notes: fixture.asset.notes,
      metadata: fixture.asset.metadata,
      legacyBridge: fixture.asset.legacyBridge,
    );

    final project = _project(cinematics: [assetWithPoints]);

    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: assetWithPoints,
      stageMap: project.maps.single,
      mapData: fixture.mapData,
      viewportSize: const CinematicMapBackdropViewportSize(
        width: 920,
        height: 260,
      ),
    );

    ProjectManifest? updatedManifest;

    await _pumpBuilderHarness(
      tester,
      project,
      assetWithPoints.id,
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: fixture.layerPlan,
      surfaceSize: _referenceTimelineSurfaceSize,
      onProjectChanged: (manifest) {
        updatedManifest = manifest;
      },
    );

    // 1. Open the "Cibles de mouvement" panel by selecting "Centre scène" in the sidebar
    final targetRow = find.descendant(
      of: find.byKey(
        const ValueKey('cinematic-builder-stage-movement-targets-section'),
      ),
      matching: find.text('Centre scène'),
    );
    expect(targetRow, findsOneWidget);
    await tester.ensureVisible(targetRow);
    await tester.pumpAndSettle();

    // 2. Click the "Repère de scène" button choice
    final choiceStagePoint = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-stagePoint',
      ),
    );
    expect(choiceStagePoint, findsOneWidget);
    await tester.ensureVisible(choiceStagePoint);
    await tester.tap(choiceStagePoint);
    await tester.pumpAndSettle();

    // 3. Verify that the StagePointSourcePicker renders with two options: Point 1 and Point 2
    final point1Option = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-stagePoint-source-stage_point_1',
      ),
    );
    final point2Option = find.byKey(
      const ValueKey(
        'cinematic-builder-target-binding-target_center-stagePoint-source-stage_point_2',
      ),
    );
    expect(point1Option, findsOneWidget);
    expect(point2Option, findsOneWidget);

    // 4. Tap on "Point 2"
    await tester.ensureVisible(point2Option);
    await tester.pumpAndSettle();
    await tester.tap(point2Option);
    await tester.pumpAndSettle();

    // 5. Verify the updated manifest has the correct binding in the stage context
    expect(updatedManifest, isNotNull);
    final updatedAsset = updatedManifest!.cinematics.single;
    final binding = updatedAsset.stageContext?.movementTargetBindings.single;
    expect(binding, isNotNull);
    expect(binding!.targetId, 'target_center');
    expect(binding.kind, CinematicMovementTargetBindingKind.stagePoint);
    expect(binding.sourceId, 'stage_point_2');
  });

  testWidgets(
    'captures V1-103 actor initial placement from stage point visual gate',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_103_CAPTURE_ACTOR_INITIAL_PLACEMENT_STAGE_POINT',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      final assetWithPoints = CinematicAsset(
        id: fixture.asset.id,
        title: fixture.asset.title,
        description: fixture.asset.description,
        storylineId: fixture.asset.storylineId,
        chapterId: fixture.asset.chapterId,
        mapId: fixture.asset.mapId,
        tags: fixture.asset.tags,
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: const [],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
          actorAppearanceBindings: [
            CinematicActorAppearanceBinding(
              actorId: 'actor_professor',
              characterId: 'char_professor',
            ),
          ],
          initialPlacements: [
            CinematicActorInitialPlacement(
              actorId: 'actor_professor',
              kind: CinematicActorInitialPlacementKind.stagePoint,
              stagePointId: 'stage_point_1',
            ),
          ],
          movementTargetBindings: const [],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
          ],
        ),
        timeline: fixture.asset.timeline,
        notes: fixture.asset.notes,
        metadata: fixture.asset.metadata,
        legacyBridge: fixture.asset.legacyBridge,
      );

      final updatedManifest = fixture.project.copyWith(
        cinematics: [assetWithPoints],
        characters: [
          ...fixture.project.characters,
          ProjectCharacterEntry(
            id: 'char_professor',
            name: 'Professor',
            tilesetId: 'real_actor_tileset',
            frameWidth: 2,
            frameHeight: 2,
            animations: [
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.south,
                frames: [
                  CharacterAnimationFrame(
                    source: const TilesetSourceRect(
                      x: 0,
                      y: 0,
                      width: 2,
                      height: 2,
                    ),
                    durationMs: 150,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final professorActor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_professor',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
          sourceId: 'stage_point_1',
          sourceLabel: 'Point 1',
          x: 3,
          y: 4,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'real_actor_tileset',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final actorDisplayModel = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor(s)',
        actors: [professorActor],
        diagnostics: const [],
      );

      final actorSpritePreviewPlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_professor',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 3, y: 4),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'real_actor_tileset',
              sourceTileRect: TilesetSourceRect(
                x: 0,
                y: 0,
                width: 2,
                height: 2,
              ),
              frameWidthTiles: 2,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 3,
              tileY: 4,
              anchorTileX: 4.0,
              anchorTileY: 6.0,
              visualBottom: 6.0,
              footprintWidthTiles: 2,
              footprintHeightTiles: 2,
              preferredRendererHint:
                  CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final backdropModel = buildCinematicMapBackdropPreviewModel(
        asset: assetWithPoints,
        stageMap: updatedManifest.maps.single,
        mapData: fixture.mapData,
        viewportSize: const CinematicMapBackdropViewportSize(
          width: 920,
          height: 260,
        ),
      );

      ui.Image? actorImage;
      await tester.runAsync(() async {
        final file = File(
          'test/fixtures/cinematics/actor_sprite_test_sheet.png',
        );
        final bytes = file.readAsBytesSync();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        actorImage = frame.image;
      });

      final backdropLayerPlan = CinematicMapBackdropLayerRenderPlan(
        mapWidth: fixture.layerPlan.mapWidth,
        mapHeight: fixture.layerPlan.mapHeight,
        tileWidth: fixture.layerPlan.tileWidth,
        tileHeight: fixture.layerPlan.tileHeight,
        tilesets: {
          ...fixture.layerPlan.tilesets,
          'real_actor_tileset': CinematicResolvedTilesetAsset.available(
            tilesetId: 'real_actor_tileset',
            image: actorImage!,
            tileWidth: 32,
            tileHeight: 32,
          ),
        },
        instructions: fixture.layerPlan.instructions,
        diagnostics: fixture.layerPlan.diagnostics,
      );

      await _pumpBuilder(
        tester,
        _entry(updatedManifest, assetWithPoints.id),
        asset: assetWithPoints,
        backdropPreviewModel: backdropModel,
        backdropLayerRenderPlan: backdropLayerPlan,
        actorDisplayPreviewModel: actorDisplayModel,
        actorSpritePreviewPlan: actorSpritePreviewPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // Click the actor Professor row to select it so the inspector shows it
      final actorRow = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Professor' && w.style?.fontSize == 14.0,
      );
      await tester.ensureVisible(actorRow);
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );

  testWidgets('captures V1-104 actorMove target from stage point visual gate', (
    tester,
  ) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_104_CAPTURE_ACTOR_MOVE_TARGET_STAGE_POINT',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    final fixture = await _largePathStudioWaterBackdropFixture();

    final assetWithPoints = CinematicAsset(
      id: fixture.asset.id,
      title: fixture.asset.title,
      description: fixture.asset.description,
      storylineId: fixture.asset.storylineId,
      chapterId: fixture.asset.chapterId,
      mapId: fixture.asset.mapId,
      tags: fixture.asset.tags,
      requiredActors: [
        CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      ],
      movementTargets: [
        CinematicMovementTargetRef(
          targetId: 'target_center',
          label: 'Centre scène',
        ),
      ],
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor_professor',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
        ],
        actorAppearanceBindings: [
          CinematicActorAppearanceBinding(
            actorId: 'actor_professor',
            characterId: 'char_professor',
          ),
        ],
        initialPlacements: [
          CinematicActorInitialPlacement(
            actorId: 'actor_professor',
            kind: CinematicActorInitialPlacementKind.stagePoint,
            stagePointId: 'stage_point_1',
          ),
        ],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_center',
            kind: CinematicMovementTargetBindingKind.stagePoint,
            sourceId: 'stage_point_2',
          ),
        ],
        stagePoints: [
          CinematicStagePoint(
            id: 'stage_point_1',
            label: 'Point 1',
            x: 2.5,
            y: 3.5,
          ),
          CinematicStagePoint(
            id: 'stage_point_2',
            label: 'Point 2',
            x: 8.5,
            y: 10.5,
          ),
        ],
      ),
      timeline: fixture.asset.timeline,
      notes: fixture.asset.notes,
      metadata: fixture.asset.metadata,
      legacyBridge: fixture.asset.legacyBridge,
    );

    final updatedManifest = fixture.project.copyWith(
      cinematics: [assetWithPoints],
      characters: [
        ...fixture.project.characters,
        ProjectCharacterEntry(
          id: 'char_professor',
          name: 'Professor',
          tilesetId: 'real_actor_tileset',
          frameWidth: 2,
          frameHeight: 2,
          animations: [
            CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: EntityFacing.south,
              frames: [
                CharacterAnimationFrame(
                  source: const TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: 2,
                    height: 2,
                  ),
                  durationMs: 150,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final professorActor = CinematicActorDisplayPreviewActor(
      actorId: 'actor_professor',
      label: 'Professor',
      role: null,
      bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
      bindingKind: CinematicActorBindingKind.cinematicOnly,
      bindingSourceId: null,
      bindingSourceLabel: null,
      position: const CinematicActorPreviewPosition(
        status: CinematicActorPreviewPositionStatus.resolved,
        sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
        sourceId: 'stage_point_1',
        sourceLabel: 'Point 1',
        x: 3,
        y: 4,
      ),
      appearance: const CinematicActorPreviewAppearance(
        status: CinematicActorPreviewAppearanceStatus.spriteReady,
        characterId: 'char_professor',
        tilesetId: 'real_actor_tileset',
      ),
      direction: CinematicActorPreviewDirection.south,
      directionSource: CinematicActorPreviewDirectionSource.actorFace,
      renderHint: CinematicActorPreviewRenderHint.sprite,
      diagnostics: const [],
    );

    final actorDisplayModel = CinematicActorDisplayPreviewModel(
      status: CinematicActorDisplayPreviewStatus.ready,
      summary: '1 actor(s)',
      actors: [professorActor],
      diagnostics: const [],
    );

    final actorSpritePreviewPlan = CinematicActorSpritePreviewPlan(
      actors: [
        CinematicActorSpritePreviewActor(
          actorId: 'actor_professor',
          actorLabel: 'Professor',
          bindingKind: CinematicActorBindingKind.cinematicOnly,
          position: const GridPos(x: 3, y: 4),
          direction: CinematicActorPreviewDirection.south,
          status: CinematicActorSpriteStatus.spriteReady,
          spriteRef: const CinematicActorSpriteRef(
            characterId: 'char_professor',
            tilesetId: 'real_actor_tileset',
            sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            frameWidthTiles: 2,
            frameHeightTiles: 2,
            direction: CinematicActorPreviewDirection.south,
          ),
          placeholderFallback: false,
          depthHint: const CinematicActorSpriteDepthHint(
            tileX: 3,
            tileY: 4,
            anchorTileX: 4.0,
            anchorTileY: 6.0,
            visualBottom: 6.0,
            footprintWidthTiles: 2,
            footprintHeightTiles: 2,
            preferredRendererHint:
                CinematicActorSpriteRendererHint.hybridRecommended,
          ),
          diagnostics: const [],
        ),
      ],
      diagnostics: const [],
    );

    final backdropModel = buildCinematicMapBackdropPreviewModel(
      asset: assetWithPoints,
      stageMap: updatedManifest.maps.single,
      mapData: fixture.mapData,
      viewportSize: const CinematicMapBackdropViewportSize(
        width: 920,
        height: 260,
      ),
    );

    ui.Image? actorImage;
    await tester.runAsync(() async {
      final file = File('test/fixtures/cinematics/actor_sprite_test_sheet.png');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      actorImage = frame.image;
    });

    final backdropLayerPlan = CinematicMapBackdropLayerRenderPlan(
      mapWidth: fixture.layerPlan.mapWidth,
      mapHeight: fixture.layerPlan.mapHeight,
      tileWidth: fixture.layerPlan.tileWidth,
      tileHeight: fixture.layerPlan.tileHeight,
      tilesets: {
        ...fixture.layerPlan.tilesets,
        'real_actor_tileset': CinematicResolvedTilesetAsset.available(
          tilesetId: 'real_actor_tileset',
          image: actorImage!,
          tileWidth: 32,
          tileHeight: 32,
        ),
      },
      instructions: fixture.layerPlan.instructions,
      diagnostics: fixture.layerPlan.diagnostics,
    );

    await _pumpBuilder(
      tester,
      _entry(updatedManifest, assetWithPoints.id),
      asset: assetWithPoints,
      backdropPreviewModel: backdropModel,
      backdropLayerRenderPlan: backdropLayerPlan,
      actorDisplayPreviewModel: actorDisplayModel,
      actorSpritePreviewPlan: actorSpritePreviewPlan,
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    // Click the target Centre scène row to select it so the inspector shows it
    final targetRow = find.descendant(
      of: find.byKey(
        const ValueKey('cinematic-builder-stage-movement-targets-section'),
      ),
      matching: find.text('Centre scène'),
    );
    await tester.ensureVisible(targetRow);
    await tester.tap(targetRow);
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('V1-108 — Cinematic Manual Path Drawing UI V0', (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final fixture = await _largePathStudioWaterBackdropFixture();

    final assetWithMove = CinematicAsset(
      id: fixture.asset.id,
      title: fixture.asset.title,
      description: fixture.asset.description,
      storylineId: fixture.asset.storylineId,
      chapterId: fixture.asset.chapterId,
      mapId: fixture.asset.mapId,
      tags: fixture.asset.tags,
      requiredActors: [
        CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      ],
      movementTargets: [
        CinematicMovementTargetRef(
          targetId: 'target_center',
          label: 'Centre scène',
        ),
      ],
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor_professor',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
        ],
        actorAppearanceBindings: [
          CinematicActorAppearanceBinding(
            actorId: 'actor_professor',
            characterId: 'char_professor',
          ),
        ],
        initialPlacements: [
          CinematicActorInitialPlacement(
            actorId: 'actor_professor',
            kind: CinematicActorInitialPlacementKind.stagePoint,
            stagePointId: 'stage_point_1',
          ),
        ],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_center',
            kind: CinematicMovementTargetBindingKind.stagePoint,
            sourceId: 'stage_point_2',
          ),
        ],
        stagePoints: [
          CinematicStagePoint(
            id: 'stage_point_1',
            label: 'Point 1',
            x: 2.5,
            y: 3.5,
          ),
          CinematicStagePoint(
            id: 'stage_point_2',
            label: 'Point 2',
            x: 8.5,
            y: 10.5,
          ),
          CinematicStagePoint(
            id: 'stage_point_3',
            label: 'Point 3',
            x: 5.5,
            y: 6.5,
          ),
        ],
      ),
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'step_move',
            kind: CinematicTimelineStepKind.actorMove,
            label: 'Move Professor',
            actorId: 'actor_professor',
            targetId: 'target_center',
            durationMs: 1000,
            metadata: const {
              cinematicTimelineDraftMetadataKindKey:
                  cinematicTimelineBasicBlockMetadataKindValue,
              cinematicTimelineDraftMetadataSourceKey:
                  cinematicTimelineDraftMetadataSourceValue,
              cinematicTimelineAuthoringBlockMetadataKey:
                  cinematicTimelineActorMoveBlockMetadataValue,
              cinematicTimelineActorMovementModeMetadataKey: 'walk',
              cinematicTimelineActorPathModeMetadataKey: 'direct',
            },
          ),
        ],
      ),
      notes: fixture.asset.notes,
      metadata: fixture.asset.metadata,
      legacyBridge: fixture.asset.legacyBridge,
    );

    late ProjectManifest latestProject;
    final project = fixture.project.copyWith(cinematics: [assetWithMove]);

    await _pumpBuilderHarness(
      tester,
      project,
      assetWithMove.id,
      onProjectChanged: (p) => latestProject = p,
      backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
        asset: assetWithMove,
        stageMap: project.maps.single,
        mapData: fixture.mapData,
      ),
      backdropLayerRenderPlan: fixture.layerPlan,
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    // Click on the actorMove step card to inspect it
    final moveCard = find.byKey(
      const ValueKey('cinematic-builder-step-card-step_move'),
    );
    await tester.ensureVisible(moveCard);
    await tester.tap(moveCard);
    await tester.pumpAndSettle();

    // Select the Action tab to see step details in inspector
    final actionTab = find.byKey(
      const ValueKey('cinematic-builder-inspector-tab-action'),
    );
    await tester.tap(actionTab);
    await tester.pumpAndSettle();

    // Verify Direct is selected by default in tabs
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-path-mode-direct'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-path-mode-manual'),
      ),
      findsOneWidget,
    );

    // Select "Manuel" path mode tab
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-path-mode-manual'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify there are no waypoints message
    expect(find.text('Aucun point de passage'), findsOneWidget);

    // Verify the add waypoint button and popup menu exists
    final addWaypointBtn = find.byKey(
      const ValueKey('cinematic-builder-add-waypoint-button'),
    );
    expect(addWaypointBtn, findsOneWidget);

    // Open dropdown menu
    final pickerFinder = find.byKey(
      const ValueKey('cinematic-builder-add-waypoint-picker'),
    );
    await tester.ensureVisible(pickerFinder);
    await tester.tap(pickerFinder);
    await tester.pumpAndSettle();

    final popupItems = find.byWidgetPredicate((w) => w is PopupMenuItem);
    expect(
      find.descendant(of: popupItems, matching: find.text('Point 2')),
      findsNothing,
    );

    // Select Point 3 from the dropdown menu items
    await tester.tap(
      find.descendant(of: popupItems, matching: find.text('Point 3')),
    );
    await tester.pumpAndSettle();

    // Verify Point 3 is now added to the waypoints list
    expect(find.text('Point 3'), findsWidgets);

    // Add another waypoint: Point 1
    await tester.ensureVisible(pickerFinder);
    await tester.tap(pickerFinder);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is PopupMenuItem),
        matching: find.text('Point 1'),
      ),
    );
    await tester.pumpAndSettle();

    // Reorder: Move Point 1 (index 1) up to index 0
    final upBtn = find.byKey(
      const ValueKey('cinematic-builder-manual-path-waypoint-up-1'),
    );
    await tester.ensureVisible(upBtn);
    await tester.tap(upBtn);
    await tester.pumpAndSettle();

    // Remove the first waypoint (which is now Point 1)
    final removeBtn = find.byKey(
      const ValueKey('cinematic-builder-manual-path-waypoint-remove-0'),
    );
    await tester.ensureVisible(removeBtn);
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-manual-path-waypoint-up-1')),
      findsNothing,
    );
    expect(find.text('Point 3'), findsWidgets);

    final finalPaths =
        latestProject.cinematics.single.stageContext?.manualPaths ?? [];
    expect(finalPaths.length, 1);
    expect(finalPaths.single.waypointStagePointIds, ['stage_point_3']);
  });

  testWidgets(
    'V1-108 — adding a waypoint creates the manual path when missing',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);

      final asset = CinematicAsset(
        id: 'cinematic_manual_path_missing',
        title: 'Manual path missing',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scène',
          ),
        ],
        stageContext: CinematicStageContext(
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'stage_point_2',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_3',
              label: 'Point 3',
              x: 5.5,
              y: 6.5,
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_move',
              kind: CinematicTimelineStepKind.actorMove,
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1000,
              metadata: const {
                cinematicTimelineDraftMetadataKindKey:
                    cinematicTimelineBasicBlockMetadataKindValue,
                cinematicTimelineDraftMetadataSourceKey:
                    cinematicTimelineDraftMetadataSourceValue,
                cinematicTimelineAuthoringBlockMetadataKey:
                    cinematicTimelineActorMoveBlockMetadataValue,
                cinematicTimelineActorMovementModeMetadataKey: 'walk',
                cinematicTimelineActorPathModeMetadataKey: 'manual',
              },
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Manual path missing test',
        maps: const [],
        tilesets: const [],
        cinematics: [asset],
      );
      late ProjectManifest latestProject;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (p) => latestProject = p,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-step_move'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();

      final actionTab = find.byKey(
        const ValueKey('cinematic-builder-inspector-tab-action'),
      );
      await tester.tap(actionTab);
      await tester.pumpAndSettle();

      final pickerFinder = find.byKey(
        const ValueKey('cinematic-builder-add-waypoint-picker'),
      );
      await tester.ensureVisible(pickerFinder);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is PopupMenuItem),
          matching: find.text('Point 1'),
        ),
      );
      await tester.pumpAndSettle();

      final paths =
          latestProject.cinematics.single.stageContext?.manualPaths ?? [];
      expect(paths, hasLength(1));
      expect(paths.single.ownerActorMoveStepId, 'step_move');
      expect(paths.single.waypointStagePointIds, ['stage_point_1']);
      expect(
        cinematicTimelineActorPathModeOf(
          latestProject.cinematics.single.timeline.steps.single,
        ),
        CinematicTimelineActorPathMode.manual,
      );
    },
  );

  testWidgets(
    'V1-108 — manual mode reuses an existing path owned by a direct actorMove',
    (tester) async {
      _setLargeSurface(tester, _referenceTimelineSurfaceSize);

      final asset = CinematicAsset(
        id: 'cinematic_manual_path_existing',
        title: 'Manual path existing',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scène',
          ),
        ],
        stageContext: CinematicStageContext(
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'stage_point_2',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 2.5,
              y: 3.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 8.5,
              y: 10.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_3',
              label: 'Point 3',
              x: 5.5,
              y: 6.5,
            ),
          ],
          manualPaths: [
            CinematicManualPath(
              id: 'path_existing',
              label: 'Trajet existant',
              ownerActorMoveStepId: 'step_move',
              waypointStagePointIds: const ['stage_point_3'],
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_move',
              kind: CinematicTimelineStepKind.actorMove,
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1000,
              metadata: const {
                cinematicTimelineDraftMetadataKindKey:
                    cinematicTimelineBasicBlockMetadataKindValue,
                cinematicTimelineDraftMetadataSourceKey:
                    cinematicTimelineDraftMetadataSourceValue,
                cinematicTimelineAuthoringBlockMetadataKey:
                    cinematicTimelineActorMoveBlockMetadataValue,
                cinematicTimelineActorMovementModeMetadataKey: 'walk',
                cinematicTimelineActorPathModeMetadataKey: 'direct',
              },
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Manual path existing test',
        maps: const [],
        tilesets: const [],
        cinematics: [asset],
      );
      late ProjectManifest latestProject;

      await _pumpBuilderHarness(
        tester,
        project,
        asset.id,
        onProjectChanged: (p) => latestProject = p,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-step_move'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();

      final actionTab = find.byKey(
        const ValueKey('cinematic-builder-inspector-tab-action'),
      );
      await tester.tap(actionTab);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-actor-move-path-mode-manual'),
        ),
      );
      await tester.pumpAndSettle();

      final updatedAsset = latestProject.cinematics.single;
      expect(updatedAsset.stageContext?.manualPaths, hasLength(1));
      expect(updatedAsset.stageContext?.manualPaths.single.id, 'path_existing');
      expect(
        cinematicTimelineActorPathModeOf(updatedAsset.timeline.steps.single),
        CinematicTimelineActorPathMode.manual,
      );
    },
  );

  testWidgets(
    'captures V1-108 cinematic manual path drawing ui visual gate when requested',
    (tester) async {
      if (!const bool.fromEnvironment(
        'NS_SCENES_V1_108_CAPTURE_MANUAL_PATH_DRAWING_UI',
      )) {
        return;
      }

      _setLargeSurface(tester, _referenceTimelineSurfaceSize);
      await _loadScreenshotFonts();
      final fixture = await _largePathStudioWaterBackdropFixture();

      final assetWithMove = CinematicAsset(
        id: fixture.asset.id,
        title: fixture.asset.title,
        description: fixture.asset.description,
        storylineId: fixture.asset.storylineId,
        chapterId: fixture.asset.chapterId,
        mapId: fixture.asset.mapId,
        tags: fixture.asset.tags,
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scène',
          ),
        ],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.cinematicOnly,
            ),
          ],
          actorAppearanceBindings: [
            CinematicActorAppearanceBinding(
              actorId: 'actor_professor',
              characterId: 'char_professor',
            ),
          ],
          initialPlacements: [
            CinematicActorInitialPlacement(
              actorId: 'actor_professor',
              kind: CinematicActorInitialPlacementKind.stagePoint,
              stagePointId: 'stage_point_1',
            ),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'stage_point_2',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(
              id: 'stage_point_1',
              label: 'Point 1',
              x: 8.5,
              y: 9.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_2',
              label: 'Point 2',
              x: 40.5,
              y: 35.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_3',
              label: 'Point 3',
              x: 18.5,
              y: 18.5,
            ),
            CinematicStagePoint(
              id: 'stage_point_4',
              label: 'Point 4',
              x: 31.5,
              y: 24.5,
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_move',
              kind: CinematicTimelineStepKind.actorMove,
              label: 'Move Professor',
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1000,
              metadata: const {
                cinematicTimelineDraftMetadataKindKey:
                    cinematicTimelineBasicBlockMetadataKindValue,
                cinematicTimelineDraftMetadataSourceKey:
                    cinematicTimelineDraftMetadataSourceValue,
                cinematicTimelineAuthoringBlockMetadataKey:
                    cinematicTimelineActorMoveBlockMetadataValue,
                cinematicTimelineActorMovementModeMetadataKey: 'walk',
                cinematicTimelineActorPathModeMetadataKey: 'direct',
              },
            ),
          ],
        ),
        notes: fixture.asset.notes,
        metadata: fixture.asset.metadata,
        legacyBridge: fixture.asset.legacyBridge,
      );

      final project = fixture.project.copyWith(cinematics: [assetWithMove]);

      await _pumpBuilderHarness(
        tester,
        project,
        assetWithMove.id,
        backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
          asset: assetWithMove,
          stageMap: project.maps.single,
          mapData: fixture.mapData,
        ),
        backdropLayerRenderPlan: fixture.layerPlan,
        surfaceSize: _referenceTimelineSurfaceSize,
      );

      // Click on the actorMove step card to inspect it
      final moveCard = find.byKey(
        const ValueKey('cinematic-builder-step-card-step_move'),
      );
      await tester.ensureVisible(moveCard);
      await tester.tap(moveCard);
      await tester.pumpAndSettle();

      // Select the Action tab to see step details in inspector
      final actionTab = find.byKey(
        const ValueKey('cinematic-builder-inspector-tab-action'),
      );
      await tester.tap(actionTab);
      await tester.pumpAndSettle();

      // Select "Manuel" path mode tab
      await tester.tap(
        find.byKey(
          const ValueKey('cinematic-builder-actor-move-path-mode-manual'),
        ),
      );
      await tester.pumpAndSettle();

      // Open dropdown menu
      final pickerFinder = find.byKey(
        const ValueKey('cinematic-builder-add-waypoint-picker'),
      );
      await tester.ensureVisible(pickerFinder);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Select Point 3 from the dropdown menu items
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is PopupMenuItem),
          matching: find.text('Point 3'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(pickerFinder);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is PopupMenuItem),
          matching: find.text('Point 4'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Trajet'));
      await tester.pumpAndSettle();

      final screenshotFile = File(
        '../../reports/narrativeStudio/scenes/screenshots/'
        'ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );
}

Future<void> _pumpBuilder(
  WidgetTester tester,
  CinematicsLibraryEntry entry, {
  required CinematicAsset asset,
  VoidCallback? onBackToLibrary,
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
  CinematicMapBackdropPreviewModel? backdropPreviewModel,
  CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan,
  CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  CinematicActorSpritePreviewPlan? actorSpritePreviewPlan,
  bool provideStageMapSourceCatalog = true,
  Size surfaceSize = _defaultBuilderSurfaceSize,
}) async {
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: CinematicBuilderWorkspace(
              entry: entry,
              asset: asset,
              startExpanded: true,
              actorSpritePreviewPlan: actorSpritePreviewPlan,
              stageMaps: const <ProjectMapEntry>[
                ProjectMapEntry(
                  id: 'map_lab',
                  name: 'Lab map',
                  relativePath: 'lab.json',
                ),
              ],
              groups: const <ProjectMapGroup>[],
              characters: characters,
              stageMapSourceCatalog: stageMapSourceCatalog ??
                  (provideStageMapSourceCatalog
                      ? _stageMapSourceCatalog()
                      : null),
              backdropPreviewModel: backdropPreviewModel,
              backdropTileRenderPlan: backdropTileRenderPlan,
              backdropLayerRenderPlan: backdropLayerRenderPlan,
              actorDisplayPreviewModel: actorDisplayPreviewModel,
              onBackToLibrary: onBackToLibrary ?? () {},
              onAddDraftStep: (
                      {required String cinematicId,
                      String? afterStepId}) async =>
                  null,
              onRemoveDraftStep: ({
                required String cinematicId,
                required String stepId,
              }) async =>
                  false,
              onAddBasicBlockStep: ({
                required String cinematicId,
                required CinematicTimelineBasicBlockKind blockKind,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateBasicBlockStep: ({
                required String cinematicId,
                required String stepId,
                int? durationMs,
                CinematicTimelineFadeMode? fadeMode,
                CinematicTimelineCameraMode? cameraMode,
              }) async =>
                  false,
              onAddRequiredActor:
                  ({required String cinematicId, String? label}) async => null,
              onRenameRequiredActor: ({
                required String cinematicId,
                required String actorId,
                required String label,
              }) async =>
                  false,
              onRemoveRequiredActor: ({
                required String cinematicId,
                required String actorId,
              }) async =>
                  false,
              onAddMovementTarget: ({required String cinematicId}) async =>
                  null,
              onUpdateMovementTarget: ({
                required String cinematicId,
                required String targetId,
                required String label,
                String? description,
              }) async =>
                  false,
              onRemoveMovementTarget: ({
                required String cinematicId,
                required String targetId,
              }) async =>
                  false,
              onAddActorFacingStep: ({
                required String cinematicId,
                required String actorId,
                required CinematicTimelineActorFacingDirection direction,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateActorFacingStep: ({
                required String cinematicId,
                required String stepId,
                String? actorId,
                CinematicTimelineActorFacingDirection? direction,
                int? durationMs,
              }) async =>
                  false,
              onAddActorMoveStep: ({
                required String cinematicId,
                required String actorId,
                required String targetId,
                required int durationMs,
                required CinematicTimelineActorMovementMode movementMode,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateActorMoveStep: ({
                required String cinematicId,
                required String stepId,
                String? actorId,
                String? targetId,
                int? durationMs,
                CinematicTimelineActorMovementMode? movementMode,
              }) async =>
                  false,
              onAddActorEmoteStep: ({
                required String cinematicId,
                required String actorId,
                required String emoteId,
                int? durationMs,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateActorEmoteStep: ({
                required String cinematicId,
                required String stepId,
                String? actorId,
                String? emoteId,
                int? durationMs,
              }) async =>
                  false,
              onRemoveAuthoringStep: ({
                required String cinematicId,
                required String stepId,
              }) async =>
                  false,
              onUpdateStageMap:
                  ({required String cinematicId, String? mapId}) async => false,
              onUpdateStageContext: ({
                required String cinematicId,
                required CinematicStageContext stageContext,
              }) async =>
                  false,
              onUpsertActorBinding: ({
                required String cinematicId,
                required CinematicActorBinding binding,
              }) async =>
                  false,
              onUpsertActorAppearanceBinding: ({
                required String cinematicId,
                required CinematicActorAppearanceBinding binding,
              }) async =>
                  false,
              onRemoveActorAppearanceBinding: ({
                required String cinematicId,
                required String actorId,
              }) async =>
                  false,
              onUpsertActorInitialPlacement: ({
                required String cinematicId,
                required CinematicActorInitialPlacement placement,
              }) async =>
                  false,
              onUpsertMovementTargetBinding: ({
                required String cinematicId,
                required CinematicMovementTargetBinding binding,
              }) async =>
                  false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBuilderHarness(
  WidgetTester tester,
  ProjectManifest project,
  String cinematicId, {
  ValueChanged<ProjectManifest>? onProjectChanged,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
  CinematicMapBackdropPreviewModel? backdropPreviewModel,
  CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan,
  CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  bool provideStageMapSourceCatalog = true,
  Size surfaceSize = _defaultBuilderSurfaceSize,
}) async {
  await tester.pumpWidget(
    _BuilderHarness(
      project: project,
      cinematicId: cinematicId,
      onProjectChanged: onProjectChanged,
      stageMapSourceCatalog: stageMapSourceCatalog,
      backdropPreviewModel: backdropPreviewModel,
      backdropTileRenderPlan: backdropTileRenderPlan,
      backdropLayerRenderPlan: backdropLayerRenderPlan,
      actorDisplayPreviewModel: actorDisplayPreviewModel,
      provideStageMapSourceCatalog: provideStageMapSourceCatalog,
      surfaceSize: surfaceSize,
    ),
  );
  await tester.pumpAndSettle();
}

class _BuilderHarness extends StatefulWidget {
  const _BuilderHarness({
    required this.project,
    required this.cinematicId,
    required this.surfaceSize,
    required this.provideStageMapSourceCatalog,
    this.stageMapSourceCatalog,
    this.backdropPreviewModel,
    this.backdropTileRenderPlan,
    this.backdropLayerRenderPlan,
    this.actorDisplayPreviewModel,
    this.onProjectChanged,
  });

  final ProjectManifest project;
  final String cinematicId;
  final Size surfaceSize;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
  final CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final bool provideStageMapSourceCatalog;
  final ValueChanged<ProjectManifest>? onProjectChanged;

  @override
  State<_BuilderHarness> createState() => _BuilderHarnessState();
}

class _BuilderHarnessState extends State<_BuilderHarness> {
  late ProjectManifest _project = widget.project;

  @override
  Widget build(BuildContext context) {
    final entry = _entry(_project, widget.cinematicId);
    final asset = _asset(_project, widget.cinematicId);
    return MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: widget.surfaceSize.width,
            height: widget.surfaceSize.height,
            child: CinematicBuilderWorkspace(
              entry: entry,
              asset: asset,
              startExpanded: true,
              stageMaps: _project.maps,
              groups: _project.groups,
              characters: _project.characters,
              stageMapSourceCatalog: widget.stageMapSourceCatalog ??
                  (widget.provideStageMapSourceCatalog
                      ? _stageMapSourceCatalog()
                      : null),
              backdropPreviewModel: widget.backdropPreviewModel,
              backdropTileRenderPlan: widget.backdropTileRenderPlan,
              backdropLayerRenderPlan: widget.backdropLayerRenderPlan,
              actorDisplayPreviewModel: widget.actorDisplayPreviewModel,
              onBackToLibrary: () {},
              onAddDraftStep: _addDraftStep,
              onRemoveDraftStep: _removeDraftStep,
              onAddBasicBlockStep: _addBasicBlockStep,
              onUpdateBasicBlockStep: _updateBasicBlockStep,
              onAddRequiredActor: _addRequiredActor,
              onRenameRequiredActor: _renameRequiredActor,
              onRemoveRequiredActor: _removeRequiredActor,
              onAddMovementTarget: _addMovementTarget,
              onUpdateMovementTarget: _updateMovementTarget,
              onRemoveMovementTarget: _removeMovementTarget,
              onAddActorFacingStep: _addActorFacingStep,
              onUpdateActorFacingStep: _updateActorFacingStep,
              onAddActorMoveStep: _addActorMoveStep,
              onUpdateActorMoveStep: _updateActorMoveStep,
              onAddActorEmoteStep: _addActorEmoteStep,
              onUpdateActorEmoteStep: _updateActorEmoteStep,
              onRemoveAuthoringStep: _removeAuthoringStep,
              onUpdateStageMap: _updateStageMap,
              onUpdateStageContext: _updateStageContext,
              onUpsertActorBinding: _upsertActorBinding,
              onUpsertActorAppearanceBinding: _upsertActorAppearanceBinding,
              onRemoveActorAppearanceBinding: _removeActorAppearanceBinding,
              onUpsertActorInitialPlacement: _upsertActorInitialPlacement,
              onUpsertMovementTargetBinding: _upsertMovementTargetBinding,
              onUpdateCinematicAsset: _updateCinematicAsset,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _addDraftStep({
    required String cinematicId,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineDraftStep(
      _project,
      cinematicId: cinematicId,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _removeDraftStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final result = removeCinematicTimelineDraftStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<String?> _addBasicBlockStep({
    required String cinematicId,
    required CinematicTimelineBasicBlockKind blockKind,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineBasicBlockStep(
      _project,
      cinematicId: cinematicId,
      blockKind: blockKind,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _updateBasicBlockStep({
    required String cinematicId,
    required String stepId,
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
  }) async {
    final result = updateCinematicTimelineBasicBlockStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      durationMs: durationMs,
      fadeMode: fadeMode,
      cameraMode: cameraMode,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<String?> _addRequiredActor({
    required String cinematicId,
    String? label,
  }) async {
    final result = addCinematicRequiredActor(
      _project,
      cinematicId: cinematicId,
      label: label ?? 'Acteur',
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.actor.actorId;
  }

  Future<bool> _renameRequiredActor({
    required String cinematicId,
    required String actorId,
    required String label,
  }) async {
    final result = renameCinematicRequiredActor(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      label: label,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _removeRequiredActor({
    required String cinematicId,
    required String actorId,
  }) async {
    try {
      final result = removeCinematicRequiredActor(
        _project,
        cinematicId: cinematicId,
        actorId: actorId,
      );
      setState(() => _project = result.updatedProject);
      widget.onProjectChanged?.call(_project);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addMovementTarget({required String cinematicId}) async {
    final result = addCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      label: 'Destination',
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.target.targetId;
  }

  Future<bool> _updateMovementTarget({
    required String cinematicId,
    required String targetId,
    required String label,
    String? description,
  }) async {
    final result = updateCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      targetId: targetId,
      label: label,
      description: description,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.target.targetId == targetId;
  }

  Future<bool> _removeMovementTarget({
    required String cinematicId,
    required String targetId,
  }) async {
    final result = removeCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      targetId: targetId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.removedTarget.targetId == targetId;
  }

  Future<bool> _updateStageMap({
    required String cinematicId,
    String? mapId,
  }) async {
    final result = updateCinematicStageMap(
      _project,
      cinematicId: cinematicId,
      mapId: mapId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _updateStageContext({
    required String cinematicId,
    required CinematicStageContext stageContext,
  }) async {
    final result = updateCinematicStageContext(
      _project,
      cinematicId: cinematicId,
      stageContext: stageContext,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _updateCinematicAsset({
    required String cinematicId,
    required CinematicAsset cinematic,
  }) async {
    final updatedCinematics = List<CinematicAsset>.from(_project.cinematics);
    final idx = updatedCinematics.indexWhere((c) => c.id == cinematicId);
    if (idx != -1) {
      updatedCinematics[idx] = cinematic;
    }
    setState(() {
      _project = _project.copyWith(cinematics: updatedCinematics);
    });
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _upsertActorBinding({
    required String cinematicId,
    required CinematicActorBinding binding,
  }) async {
    final result = upsertCinematicActorBinding(
      _project,
      cinematicId: cinematicId,
      binding: binding,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _upsertActorAppearanceBinding({
    required String cinematicId,
    required CinematicActorAppearanceBinding binding,
  }) async {
    final result = upsertCinematicActorAppearanceBinding(
      _project,
      cinematicId: cinematicId,
      binding: binding,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _removeActorAppearanceBinding({
    required String cinematicId,
    required String actorId,
  }) async {
    final result = removeCinematicActorAppearanceBinding(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _upsertActorInitialPlacement({
    required String cinematicId,
    required CinematicActorInitialPlacement placement,
  }) async {
    final result = upsertCinematicActorInitialPlacement(
      _project,
      cinematicId: cinematicId,
      placement: placement,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _upsertMovementTargetBinding({
    required String cinematicId,
    required CinematicMovementTargetBinding binding,
  }) async {
    final result = upsertCinematicMovementTargetBinding(
      _project,
      cinematicId: cinematicId,
      binding: binding,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<String?> _addActorFacingStep({
    required String cinematicId,
    required String actorId,
    required CinematicTimelineActorFacingDirection direction,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineActorFacingStep(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      direction: direction,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<String?> _addActorMoveStep({
    required String cinematicId,
    required String actorId,
    required String targetId,
    required int durationMs,
    required CinematicTimelineActorMovementMode movementMode,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineActorMoveStep(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _updateActorMoveStep({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    final result = updateCinematicTimelineActorMoveStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id == stepId;
  }

  Future<String?> _addActorEmoteStep({
    required String cinematicId,
    required String actorId,
    required String emoteId,
    int? durationMs,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineActorEmoteStep(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      emoteId: emoteId,
      durationMs: durationMs,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _updateActorEmoteStep({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? emoteId,
    int? durationMs,
  }) async {
    final result = updateCinematicTimelineActorEmoteStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      actorId: actorId,
      emoteId: emoteId,
      durationMs: durationMs,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id == stepId;
  }

  Future<bool> _updateActorFacingStep({
    required String cinematicId,
    required String stepId,
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
    int? durationMs,
  }) async {
    final result = updateCinematicTimelineActorFacingStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      actorId: actorId,
      direction: direction,
      durationMs: durationMs,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id == stepId;
  }

  Future<bool> _removeAuthoringStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final result = removeCinematicTimelineAuthoringStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.removedStep.id == stepId;
  }
}

CinematicAsset _asset(ProjectManifest project, String id) {
  final asset = findCinematicById(project, id);
  if (asset == null) {
    throw StateError('Missing cinematic asset $id');
  }
  return asset;
}

CinematicAsset _actorFacingCinematic() {
  return CinematicAsset(
    id: 'cinematic_actor_face',
    title: 'Actor facing cinematic',
    description: 'Actor picker and facing direction.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Opening wait',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _actorEmoteAuthoringCinematic({
  bool withEmoteStep = true,
  String actorId = 'actor_professor',
  String emoteId = cinematicDefaultActorEmoteId,
}) {
  final actorLabel = switch (actorId) {
    'actor_professor' => 'Professor',
    'actor_rival' => 'Rival',
    _ => actorId,
  };
  final emoteLabel =
      cinematicEmoteCatalogEntryById(emoteId)?.label ?? 'Réaction';
  return CinematicAsset(
    id: 'cinematic_actor_emote',
    title: 'Actor emote cinematic',
    description: 'Actor emote authoring fixture.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Opening wait',
          durationMs: 500,
        ),
        if (withEmoteStep)
          CinematicTimelineStep(
            id: 'step_emote',
            kind: CinematicTimelineStepKind.actorEmote,
            label: '$actorLabel affiche $emoteLabel',
            actorId: actorId,
            durationMs: cinematicTimelineDefaultActorEmoteDurationMs,
            metadata: {
              cinematicTimelineDraftMetadataKindKey:
                  cinematicTimelineBasicBlockMetadataKindValue,
              cinematicTimelineDraftMetadataSourceKey:
                  cinematicTimelineDraftMetadataSourceValue,
              cinematicTimelineAuthoringBlockMetadataKey:
                  cinematicTimelineActorEmoteBlockMetadataValue,
              cinematicTimelineActorEmoteEmoteIdMetadataKey: emoteId,
            },
          ),
      ],
    ),
  );
}

CinematicAsset _actorMovementCinematic() {
  return CinematicAsset(
    id: 'cinematic_actor_move',
    title: 'Actor movement cinematic',
    description: 'Actor movement V0 fixture.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
        description: 'Point central authoring.',
      ),
      CinematicMovementTargetRef(
        targetId: 'target_exit',
        label: 'Sortie',
        description: 'Sortie de scène.',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Opening wait',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _timeLayoutCinematic() {
  return CinematicAsset(
    id: 'cinematic_time_layout',
    title: 'Time layout cinematic',
    description: 'Neutral fixture for timeline bars.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
        description: 'Point central authoring.',
      ),
      CinematicMovementTargetRef(
        targetId: 'target_exit',
        label: 'Sortie',
        description: 'Sortie de scène.',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 0,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move Professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 300,
          assetRef: 'cue_bell',
        ),
      ],
    ),
  );
}

CinematicAsset _durationResizeCinematic() {
  return CinematicAsset(
    id: 'cinematic_duration_resize',
    title: 'Duration resize cinematic',
    description: 'Neutral fixture for duration resize handles.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          durationMs: 500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move Professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'wait',
          },
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'fade',
            cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          },
        ),
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera hold',
          durationMs: 500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'camera',
            cinematicTimelineCameraModeMetadataKey: 'hold',
          },
        ),
        CinematicTimelineStep(
          id: 'step_marker',
          kind: CinematicTimelineStepKind.marker,
          label: 'Draft marker',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineDraftMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
          },
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 400,
          assetRef: 'cue_bell',
        ),
      ],
    ),
  );
}

CinematicAsset _verticalTieBreakCinematic() {
  return CinematicAsset(
    id: 'cinematic_vertical_tie_break',
    title: 'Vertical tie break cinematic',
    description: 'Neutral fixture for vertical keyboard tie breaks.',
    mapId: 'map_lab',
    requiredActors: [CinematicActorRef(actorId: 'actor_guide', label: 'Guide')],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera_a',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera left',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_actor',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Guide turns',
          durationMs: 300,
          actorId: 'actor_guide',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_camera_b',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera right',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _longTimelineCinematic() {
  return CinematicAsset(
    id: 'cinematic_long_probe',
    title: 'Long probe cinematic',
    description: 'Neutral fixture for horizontal probe scroll.',
    mapId: 'map_lab',
    timeline: CinematicTimeline(
      steps: [
        for (var index = 0; index < 10; index += 1)
          CinematicTimelineStep(
            id: 'step_wait_$index',
            kind: CinematicTimelineStepKind.wait,
            label: 'Wait ${index + 1}',
            durationMs: 1000,
          ),
      ],
    ),
  );
}

CinematicAsset _laneShowcaseCinematic() {
  return CinematicAsset(
    id: 'cinematic_lane_showcase',
    title: 'Lane showcase cinematic',
    description: 'Neutral fixture for lane grouping.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera pan',
          durationMs: 400,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          durationMs: 300,
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 900,
          actorId: 'actor_professor',
          dialogueText: 'Tout est prêt.',
        ),
        CinematicTimelineStep(
          id: 'step_fx',
          kind: CinematicTimelineStepKind.fx,
          label: 'Sparkle',
          durationMs: 250,
          assetRef: 'sparkle_fx',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 200,
          assetRef: 'cue_bell',
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _laneVisualGateCinematic() {
  return CinematicAsset(
    id: 'cinematic_lane_visual_gate',
    title: 'Lane visual gate cinematic',
    description: 'Neutral fixture for lane grouping screenshot.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          durationMs: 300,
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 900,
          actorId: 'actor_professor',
          dialogueText: 'Tout est prêt.',
        ),
        CinematicTimelineStep(
          id: 'step_fx',
          kind: CinematicTimelineStepKind.fx,
          label: 'Sparkle',
          durationMs: 250,
          assetRef: 'sparkle_fx',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 200,
          assetRef: 'cue_bell',
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _richCinematic() {
  return CinematicAsset(
    id: 'cinematic_rich',
    title: 'Rich cinematic',
    description: 'Readable step details.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera to door',
          durationMs: 400,
          targetId: 'target_camera_focus',
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 1200,
          actorId: 'actor_professor',
          dialogueText: 'Labo sécurisé.',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Door chime',
          durationMs: 300,
          assetRef: 'door_chime',
          metadata: const {'volume': '0.8'},
        ),
      ],
    ),
  );
}

CinematicAsset _stageContextCinematic({
  String? mapId = 'map_lab',
  CinematicStageContext? stageContext,
}) {
  return CinematicAsset(
    id: 'cinematic_stage_context',
    title: 'Stage context cinematic',
    description: 'Stage context authoring.',
    mapId: mapId,
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    stageContext: stageContext ??
        CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _stageSandboxOnlyCinematic() {
  return CinematicAsset(
    id: 'cinematic_stage_sandbox',
    title: 'Stage sandbox cinematic',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicActorDisplayPreviewActor _focusPreviewActor(
  String actorId, {
  required int x,
  required int y,
}) {
  return CinematicActorDisplayPreviewActor(
    actorId: actorId,
    label: actorId,
    role: null,
    bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
    bindingKind: CinematicActorBindingKind.cinematicOnly,
    bindingSourceId: actorId,
    bindingSourceLabel: actorId,
    position: CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.resolved,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      x: x,
      y: y,
      sourceId: actorId,
      sourceLabel: actorId,
    ),
    appearance: const CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
    ),
    direction: CinematicActorPreviewDirection.south,
    directionSource: CinematicActorPreviewDirectionSource.fallback,
    renderHint: CinematicActorPreviewRenderHint.placeholder,
    diagnostics: const [],
  );
}

CinematicAsset _actorDisplayPreviewCinematic() {
  return CinematicAsset(
    id: 'cinematic_actor_display_preview',
    title: 'Actor display preview',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
      CinematicActorRef(actorId: 'actor_guard', label: 'Garde'),
      CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
      CinematicActorRef(actorId: 'actor_unbound', label: 'Silhouette'),
      CinematicActorRef(actorId: 'actor_missing', label: 'Acteur sans entrée'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_player_start',
        label: 'Entrée joueur',
      ),
      CinematicMovementTargetRef(
        targetId: 'target_lysa_start',
        label: 'Entrée Lysa',
      ),
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_player',
          kind: CinematicActorBindingKind.player,
        ),
        CinematicActorBinding(
          actorId: 'actor_guard',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_guard',
        ),
        CinematicActorBinding(
          actorId: 'actor_lysa',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        CinematicActorBinding(
          actorId: 'actor_unbound',
          kind: CinematicActorBindingKind.unbound,
        ),
        CinematicActorBinding(
          actorId: 'actor_missing',
          kind: CinematicActorBindingKind.player,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_player',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_player_start',
        ),
        CinematicActorInitialPlacement(
          actorId: 'actor_guard',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
        CinematicActorInitialPlacement(
          actorId: 'actor_lysa',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_lysa_start',
        ),
        CinematicActorInitialPlacement(
          actorId: 'actor_unbound',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_lysa_start',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_player_start',
          kind: CinematicMovementTargetBindingKind.mapEvent,
          sourceId: 'event_player_start',
        ),
        CinematicMovementTargetBinding(
          targetId: 'target_lysa_start',
          kind: CinematicMovementTargetBindingKind.mapEvent,
          sourceId: 'event_lysa_start',
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Static camera',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_face_lysa',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Lysa faces east',
          actorId: 'actor_lysa',
          durationMs: 300,
          metadata: const {'actor.direction': 'right'},
        ),
        CinematicTimelineStep(
          id: 'step_move_guard_ignored',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move guard',
          actorId: 'actor_guard',
          targetId: 'target_lysa_start',
          durationMs: 900,
        ),
      ],
    ),
  );
}

CinematicAsset _stageUnknownMapCinematic() {
  return _stageContextCinematic(mapId: 'missing_map');
}

CinematicAsset _stageReadyCinematic() {
  return CinematicAsset(
    id: 'cinematic_stage_ready',
    title: 'Stage ready cinematic',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
      ),
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_professor',
          kind: CinematicActorBindingKind.player,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_professor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_center',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_center',
          kind: CinematicMovementTargetBindingKind.abstractPoint,
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _cameraPreviewPlaybackCinematic({String? cameraMode}) {
  final cameraMetadata = <String, String>{
    cinematicTimelineDraftMetadataKindKey:
        cinematicTimelineBasicBlockMetadataKindValue,
    cinematicTimelineDraftMetadataSourceKey:
        cinematicTimelineDraftMetadataSourceValue,
    cinematicTimelineAuthoringBlockMetadataKey: 'camera',
    if (cameraMode != null) cinematicTimelineCameraModeMetadataKey: cameraMode,
  };
  return CinematicAsset(
    id: 'cinematic_camera_preview_playback',
    title: 'Camera preview playback',
    description: 'Neutral fixture for camera preview playback.',
    mapId: 'map_lab',
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'camera_intro_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Ouverture',
          durationMs: 400,
        ),
        CinematicTimelineStep(
          id: 'camera_preview',
          kind: CinematicTimelineStepKind.camera,
          label: 'Cadrage port',
          durationMs: 800,
          metadata: cameraMetadata,
        ),
        CinematicTimelineStep(
          id: 'camera_outro_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Sortie caméra',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _playbackDirectActorMoveCinematic() {
  return CinematicAsset(
    id: 'cinematic_playback_direct_actor_move',
    title: 'Playback direct actorMove',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(targetId: 'target_port', label: 'Port'),
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_lysa',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_lysa',
          kind: CinematicActorInitialPlacementKind.stagePoint,
          stagePointId: 'start',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_port',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'dest',
        ),
      ],
      stagePoints: [
        CinematicStagePoint(id: 'start', label: 'Départ', x: 1.5, y: 4.5),
        CinematicStagePoint(id: 'dest', label: 'Destination', x: 9.5, y: 4.5),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'move_direct',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Entrée Lysa',
          actorId: 'actor_lysa',
          targetId: 'target_port',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _fadePlaybackCinematic(CinematicTimelineFadeMode fadeMode) {
  final fadeModeName = fadeMode.name;
  return CinematicAsset(
    id: 'cinematic_fade_preview_playback_$fadeModeName',
    title: 'Fade preview playback $fadeModeName',
    mapId: 'map_lab',
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'fade_$fadeModeName',
          kind: CinematicTimelineStepKind.fade,
          label: fadeMode == CinematicTimelineFadeMode.fadeIn
              ? 'Fondu entrant'
              : 'Fondu sortant',
          durationMs: 1000,
          metadata: {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'fade',
            cinematicTimelineFadeModeMetadataKey: fadeModeName,
          },
        ),
        CinematicTimelineStep(
          id: 'wait_after_fade',
          kind: CinematicTimelineStepKind.wait,
          label: 'Attente après fondu',
          durationMs: 500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'wait',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _playbackManualPathActorMoveCinematic({
  bool includeSecondWaypoint = false,
}) {
  return CinematicAsset(
    id: 'cinematic_playback_manual_actor_move',
    title: 'Playback manual actorMove',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(targetId: 'target_port', label: 'Port'),
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_lysa',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_lysa',
          kind: CinematicActorInitialPlacementKind.stagePoint,
          stagePointId: 'start',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_port',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'dest',
        ),
      ],
      stagePoints: [
        CinematicStagePoint(id: 'start', label: 'Départ', x: 1.5, y: 1.5),
        CinematicStagePoint(id: 'wp_a', label: 'Repère A', x: 1.5, y: 5.5),
        if (includeSecondWaypoint)
          CinematicStagePoint(id: 'wp_b', label: 'Repère B', x: 4.5, y: 5.5),
        CinematicStagePoint(id: 'dest', label: 'Destination', x: 7.5, y: 5.5),
      ],
      manualPaths: [
        CinematicManualPath(
          id: 'path_manual',
          label: 'Trajet manuel',
          ownerActorMoveStepId: 'move_manual',
          waypointStagePointIds:
              includeSecondWaypoint ? const ['wp_a', 'wp_b'] : const ['wp_a'],
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'move_manual',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Trajet Lysa',
          actorId: 'actor_lysa',
          targetId: 'target_port',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'manual',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _stageContextTwoActorsCinematic() {
  return CinematicAsset(
    id: 'cinematic_stage_two_actors',
    title: 'Stage two actors cinematic',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_assistant', label: 'Assistant'),
    ],
    stageContext: CinematicStageContext(),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _stageDurationCinematic({CinematicStageContext? stageContext}) {
  return CinematicAsset(
    id: 'cinematic_stage_duration',
    title: 'Stage duration cinematic',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
    ],
    stageContext: stageContext ?? CinematicStageContext(),
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          durationMs: 500,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'down',
          },
        ),
      ],
    ),
  );
}

CinematicAsset _diagnosticCinematic() {
  return CinematicAsset(
    id: 'cinematic_diagnostic',
    title: 'Diagnostic cinematic',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_bad',
          kind: CinematicTimelineStepKind.wait,
          durationMs: -5,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey: 'wait',
          },
        ),
      ],
    ),
  );
}

CinematicsLibraryEntry _entry(ProjectManifest project, String id) {
  final entry = buildCinematicsLibraryReadModel(project).entryById(id);
  if (entry == null) {
    throw StateError('Missing cinematic entry $id');
  }
  return entry;
}

Future<void> _loadScreenshotFonts() async {
  final fontBytes = File(
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ).readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  bool includeBridge = true,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    characters: characters,
    scenes: [
      if (cinematics == null)
        _sceneReferencing(
          id: 'scene_canonical',
          name: 'Canonical scene',
          nodeId: 'node_cinematic',
          nodeTitle: 'Play intro',
          cinematicId: 'cinematic_intro',
        ),
      if (includeBridge)
        _sceneReferencing(
          id: 'scene_bridge',
          name: 'Bridge scene',
          nodeId: 'node_bridge',
          nodeTitle: 'Play bridge',
          cinematicId: 'scenario_cutscene',
        ),
    ],
    scenarios: includeBridge
        ? const <ScenarioAsset>[
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Legacy cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                'authoring.cutsceneSchema': 'cutscene-studio-v0',
              },
            ),
          ]
        : const <ScenarioAsset>[],
    cinematics: [
      ...?cinematics,
      if (cinematics == null)
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          description: 'Camera reveal.',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_camera',
                kind: CinematicTimelineStepKind.camera,
                label: 'Camera reveal',
                durationMs: 500,
              ),
              CinematicTimelineStep(
                id: 'step_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                label: 'Professor reacts',
                durationMs: 250,
                actorId: 'actor_professor',
              ),
            ],
          ),
        ),
    ],
  );
}

ProjectManifest _extendedBackdropProject({List<CinematicAsset>? cinematics}) {
  return _project(cinematics: cinematics, includeBridge: false).copyWith(
    settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'neutral_tiles',
        name: 'Neutral tiles',
        relativePath: 'assets/tilesets/neutral.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'neutral_element_category', name: 'Neutral'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'neutral_tree',
        name: 'Neutral tree',
        tilesetId: 'neutral_tiles',
        categoryId: 'neutral_element_category',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 4, y: 0, height: 2)),
        ],
        collisionProfile: ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]),
      ),
    ],
    terrainPresets: const [
      ProjectTerrainPreset(
        id: 'neutral_grass',
        name: 'Neutral grass',
        terrainType: TerrainType.grass,
        tilesetId: 'neutral_tiles',
        variants: [
          TerrainPresetVariant(
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
          ),
        ],
      ),
    ],
    pathPresets: [
      ProjectPathPreset(
        id: 'neutral_path',
        name: 'Neutral path',
        tilesetId: 'neutral_tiles',
        variants: [
          for (final variant in TerrainPathVariant.values)
            PathPresetVariantMapping(
              variant: variant,
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
              ],
            ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(
      atlases: [
        ProjectSurfaceAtlas(
          id: 'neutral_surface_atlas',
          name: 'Neutral surface atlas',
          tilesetId: 'neutral_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 8, rows: 2),
          ),
        ),
      ],
      animations: [
        ProjectSurfaceAnimation(
          id: 'neutral_surface_animation',
          name: 'Neutral surface animation',
          timeline: SurfaceAnimationTimeline(
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'neutral_surface_atlas',
                  column: 2,
                  row: 0,
                ),
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      presets: [
        ProjectSurfacePreset(
          id: 'neutral_surface',
          name: 'Neutral surface',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'neutral_surface_animation',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

ProjectManifest _pathStudioWaterBackdropProject({
  List<CinematicAsset>? cinematics,
}) {
  return _extendedBackdropProject(cinematics: cinematics).copyWith(
    pathPresets: [
      const ProjectPathPreset(
        id: 'water_base',
        name: 'Water base',
        tilesetId: 'neutral_tiles',
        surfaceKind: PathSurfaceKind.water,
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 7, y: 1))],
          ),
        ],
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water_pattern',
        name: 'Water pattern',
        basePathPresetId: 'water_base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0)),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 0)),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

CinematicStageMapSourceCatalog _stageMapSourceCatalog({MapData? mapData}) {
  return buildCinematicStageMapSourceCatalog(
    stageMap: const ProjectMapEntry(
      id: 'map_lab',
      name: 'Lab map',
      relativePath: 'lab.json',
    ),
    mapData: mapData ?? _stageMapData(),
  );
}

MapData _stageMapData({
  List<MapEntity> entities = const <MapEntity>[
    MapEntity(
      id: 'entity_professor',
      name: 'Professor entity',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 4, y: 6),
      npc: MapEntityNpcData(displayName: 'Professor Oak'),
    ),
    MapEntity(
      id: 'entity_notice',
      name: 'Notice board',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 7, y: 2),
      sign: MapEntitySignData(title: 'Notice board'),
    ),
  ],
  List<MapEventDefinition> events = const <MapEventDefinition>[
    MapEventDefinition(
      id: 'event_gate_bell',
      title: 'Gate bell',
      position: EventPosition(layerId: 'ground', x: 8, y: 3),
      pages: [MapEventPage(pageNumber: 0)],
      type: MapEventType.object,
    ),
  ],
}) {
  return MapData(
    id: 'map_lab',
    name: 'Lab map',
    size: const GridSize(width: 12, height: 10),
    entities: entities,
    events: events,
  );
}

MapData _stageMapDataWithVisualLayers() {
  return _stageMapData().copyWith(
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'lab_tiles',
        tiles: [1, 2, 3, 4],
      ),
      MapLayer.path(
        id: 'path_main',
        name: 'Main path',
        presetId: 'stone_path',
        cells: [true, false, true],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: [true],
      ),
    ],
  );
}

MapData _stageMapDataWithBitmapTileLayer() {
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 2, height: 1),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'lab_tiles',
        tiles: [1, 2],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: [true, false],
      ),
    ],
  );
}

MapData _stageMapDataWithExtendedBackdrop() {
  return _stageMapData(
    entities: const <MapEntity>[
      MapEntity(
        id: 'entity_professor',
        name: 'Professor entity',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(displayName: 'Professor Oak'),
      ),
    ],
    events: const <MapEventDefinition>[
      MapEventDefinition(
        id: 'neutral_event',
        title: 'Neutral event',
        position: EventPosition(layerId: 'ground', x: 3, y: 3),
        pages: [MapEventPage(pageNumber: 0)],
        type: MapEventType.object,
      ),
    ],
  ).copyWith(
    size: const GridSize(width: 4, height: 4),
    layers: [
      const MapLayer.terrain(
        id: 'neutral_terrain',
        name: 'Neutral terrain',
        terrains: [
          TerrainType.grass,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
          TerrainType.none,
        ],
      ),
      const MapLayer.path(
        id: 'neutral_path_layer',
        name: 'Neutral path',
        presetId: 'neutral_path',
        cells: [
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
      const MapLayer.tile(
        id: 'neutral_ground',
        name: 'Neutral ground',
        tilesetId: 'neutral_tiles',
        tiles: [0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      const MapLayer.surface(
        id: 'neutral_surface_layer',
        name: 'Neutral surface',
        placements: [
          SurfaceCellPlacement(x: 0, y: 2, surfacePresetId: 'neutral_surface'),
        ],
      ),
      const MapLayer.object(id: 'neutral_objects', name: 'Neutral objects'),
      MapLayer.environment(
        id: 'neutral_environment',
        name: 'Neutral environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'neutral_ground',
          areas: [
            EnvironmentArea(
              id: 'neutral_area',
              name: 'Neutral area',
              presetId: 'neutral_environment_preset',
              mask: EnvironmentAreaMask(
                width: 4,
                height: 4,
                cells: [
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                  true,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                ],
              ),
              seed: 7,
              generatedPlacementIds: ['neutral_generated_tree'],
            ),
          ],
        ),
      ),
      const MapLayer.tile(
        id: 'neutral_foreground',
        name: 'Neutral foreground',
        tilesetId: 'neutral_tiles',
        tiles: [0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      const MapLayer.collision(
        id: 'neutral_collision',
        name: 'Collision',
        collisions: [
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'neutral_generated_tree',
        layerId: 'neutral_objects',
        elementId: 'neutral_tree',
        pos: GridPos(x: 2, y: 1),
      ),
    ],
  );
}

MapData _stageMapDataWithPathStudioWaterBackdrop() {
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 2, height: 2),
    layers: const [
      MapLayer.path(
        id: 'water_path_layer',
        name: 'Water path',
        presetId: 'water_base',
        cells: [true, true, true, true],
      ),
    ],
  );
}

MapData _stageMapDataWithLargePathStudioWaterBackdrop() {
  final waterCells = List<bool>.filled(55 * 55, true);
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 55, height: 55),
    layers: [
      MapLayer.tile(
        id: 'large_ground',
        name: 'Large ground',
        tilesetId: 'neutral_tiles',
        tiles: List<int>.filled(55 * 55, 5),
      ),
      MapLayer.path(
        id: 'large_water_path_layer',
        name: 'Large water path',
        presetId: 'water_base',
        cells: waterCells,
      ),
    ],
  );
}

MapData _stageMapDataWithLargeBackdrop() {
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 55, height: 55),
    layers: [
      MapLayer.tile(
        id: 'large_ground',
        name: 'Large ground',
        tilesetId: 'neutral_tiles',
        tiles: List<int>.filled(55 * 55, 1),
      ),
    ],
  );
}

MapData _stageMapDataWithActorDisplayFixtures() {
  final tiles = <int>[];
  for (var index = 0; index < 120; index += 1) {
    tiles.add(index.isEven ? 1 : 2);
  }
  return _stageMapData(
    entities: const <MapEntity>[
      MapEntity(
        id: 'entity_guard',
        name: 'Guard entity',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 6, y: 5),
        npc: MapEntityNpcData(displayName: 'Garde'),
      ),
    ],
    events: const <MapEventDefinition>[
      MapEventDefinition(
        id: 'event_player_start',
        title: 'Entrée joueur',
        position: EventPosition(layerId: 'ground', x: 3, y: 4),
        pages: [MapEventPage(pageNumber: 0)],
        type: MapEventType.object,
      ),
      MapEventDefinition(
        id: 'event_lysa_start',
        title: 'Entrée Lysa',
        position: EventPosition(layerId: 'ground', x: 8, y: 3),
        pages: [MapEventPage(pageNumber: 0)],
        type: MapEventType.object,
      ),
    ],
  ).copyWith(
    size: const GridSize(width: 12, height: 10),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'lab_tiles',
        tiles: tiles,
      ),
    ],
  );
}

MapData _stageMapDataWithReferenceBitmapLayer() {
  final tiles = <int>[];
  for (var y = 0; y < 10; y += 1) {
    for (var x = 0; x < 12; x += 1) {
      if (x < 2 || x > 9 || y == 0 || y == 9) {
        tiles.add(3);
      } else if ((x >= 4 && x <= 7) || (y >= 4 && y <= 5)) {
        tiles.add(2);
      } else if ((x + y) % 5 == 0) {
        tiles.add(4);
      } else {
        tiles.add(1);
      }
    }
  }
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 12, height: 10),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'lab_tiles',
        tiles: tiles,
      ),
      const MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: [true],
      ),
    ],
  );
}

Future<ui.Image> _makeTestTilesetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas
    ..drawRect(
      const Rect.fromLTWH(0, 0, 8, 8),
      Paint()..color = const Color(0xFFFF0000),
    )
    ..drawRect(
      const Rect.fromLTWH(8, 0, 8, 8),
      Paint()..color = const Color(0xFF00FF00),
    );
  final picture = recorder.endRecording();
  return picture.toImage(16, 8);
}

Future<ui.Image> _makeExtendedBackdropTilesetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paints = [
    Paint()..color = const Color(0xFF2F6F4E),
    Paint()..color = const Color(0xFF8A7B54),
    Paint()..color = const Color(0xFF526274),
    Paint()..color = const Color(0xFF9EA7B3),
    Paint()..color = const Color(0xFF254E35),
    Paint()..color = const Color(0xFF14311F),
    Paint()..color = const Color(0xFF4A5968),
    Paint()..color = const Color(0xFF6A5572),
  ];
  for (var index = 0; index < paints.length; index += 1) {
    canvas.drawRect(Rect.fromLTWH(index * 8.0, 0, 8, 8), paints[index]);
    canvas.drawRect(Rect.fromLTWH(index * 8.0, 8, 8, 8), paints[index]);
  }
  final picture = recorder.endRecording();
  return picture.toImage(64, 16);
}

Future<ui.Image> _makePathStudioWaterBackdropTilesetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paints = [
    Paint()..color = const Color(0xFF0D6EA8),
    Paint()..color = const Color(0xFF1896D4),
    Paint()..color = const Color(0xFF3DB9E6),
    Paint()..color = const Color(0xFF7DD7F0),
    Paint()..color = const Color(0xFF2F6F4E),
    Paint()..color = const Color(0xFF2F6F4E),
    Paint()..color = const Color(0xFF254E35),
    Paint()..color = const Color(0xFF14311F),
  ];
  for (var index = 0; index < paints.length; index += 1) {
    canvas.drawRect(Rect.fromLTWH(index * 8.0, 0, 8, 8), paints[index]);
    canvas.drawRect(Rect.fromLTWH(index * 8.0, 8, 8, 8), paints[index]);
  }
  final picture = recorder.endRecording();
  return picture.toImage(64, 16);
}

Future<CinematicMapBackdropLayerRenderPlan> _extendedBackdropLayerPlan({
  ProjectManifest? project,
  MapData? mapData,
}) async {
  final tilesetImage = await _makeExtendedBackdropTilesetImage();
  return buildCinematicMapBackdropLayerRenderPlan(
    mapData: mapData ?? _stageMapDataWithExtendedBackdrop(),
    manifest: project ?? _extendedBackdropProject(),
    tilesets: {
      'neutral_tiles': CinematicResolvedTilesetAsset.available(
        tilesetId: 'neutral_tiles',
        image: tilesetImage,
        tileWidth: 8,
        tileHeight: 8,
      ),
    },
  );
}

Future<_ExtendedBackdropFixture> _largeBackdropFixture() {
  return _extendedBackdropFixture(mapData: _stageMapDataWithLargeBackdrop());
}

Future<_ExtendedBackdropFixture> _largePathStudioWaterBackdropFixture() {
  final cinematic = _stageContextCinematic();
  final project = _pathStudioWaterBackdropProject(cinematics: [cinematic]);
  final mapData = _stageMapDataWithLargePathStudioWaterBackdrop();
  final backdropModel = buildCinematicMapBackdropPreviewModel(
    asset: cinematic,
    stageMap: project.maps.single,
    mapData: mapData,
  );
  return _makePathStudioWaterBackdropTilesetImage().then((tilesetImage) {
    final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: mapData,
      manifest: project,
      tilesets: {
        'neutral_tiles': CinematicResolvedTilesetAsset.available(
          tilesetId: 'neutral_tiles',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      },
    );
    return _ExtendedBackdropFixture(
      project: project,
      asset: cinematic,
      mapData: mapData,
      backdropModel: backdropModel,
      layerPlan: layerPlan,
    );
  });
}

Future<_ExtendedBackdropFixture> _extendedBackdropFixture({
  CinematicAsset? asset,
  ProjectManifest? project,
  MapData? mapData,
}) async {
  final cinematic = asset ?? _stageContextCinematic();
  final manifest = project ?? _extendedBackdropProject(cinematics: [cinematic]);
  final stageMapData = mapData ?? _stageMapDataWithExtendedBackdrop();
  final backdropModel = buildCinematicMapBackdropPreviewModel(
    asset: cinematic,
    stageMap: manifest.maps.single,
    mapData: stageMapData,
  );
  final layerPlan = await _extendedBackdropLayerPlan(
    project: manifest,
    mapData: stageMapData,
  );
  return _ExtendedBackdropFixture(
    project: manifest,
    asset: cinematic,
    mapData: stageMapData,
    backdropModel: backdropModel,
    layerPlan: layerPlan,
  );
}

final class _ExtendedBackdropFixture {
  const _ExtendedBackdropFixture({
    required this.project,
    required this.asset,
    required this.mapData,
    required this.backdropModel,
    required this.layerPlan,
  });

  final ProjectManifest project;
  final CinematicAsset asset;
  final MapData mapData;
  final CinematicMapBackdropPreviewModel backdropModel;
  final CinematicMapBackdropLayerRenderPlan layerPlan;
}

Future<ui.Image> _makeReferenceTilesetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paints = [
    Paint()..color = const Color(0xFF31424D),
    Paint()..color = const Color(0xFF516571),
    Paint()..color = const Color(0xFF1D4F73),
    Paint()..color = const Color(0xFF6E5A2E),
  ];
  for (var index = 0; index < paints.length; index += 1) {
    final x = (index % 2) * 8.0;
    final y = (index ~/ 2) * 8.0;
    canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), paints[index]);
    canvas.drawLine(
      Offset(x, y + 7),
      Offset(x + 8, y + 7),
      Paint()
        ..color = const Color(0x66232935)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(x + 7, y),
      Offset(x + 7, y + 8),
      Paint()
        ..color = const Color(0x66232935)
        ..strokeWidth = 1,
    );
  }
  final picture = recorder.endRecording();
  return picture.toImage(16, 16);
}

Future<CinematicMapBackdropTileRenderPlan> _referenceTileRenderPlanFor({
  required ProjectManifest project,
  required MapData mapData,
}) async {
  final tilesetImage = await _makeReferenceTilesetImage();
  final bitmapProject = project.copyWith(
    tilesets: const [
      ProjectTilesetEntry(
        id: 'lab_tiles',
        name: 'Lab tiles',
        relativePath: 'assets/tilesets/lab.png',
      ),
    ],
    settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
  );
  return buildCinematicMapBackdropTileRenderPlan(
    mapData: mapData,
    manifest: bitmapProject,
    tilesets: {
      'lab_tiles': CinematicResolvedTilesetAsset.available(
        tilesetId: 'lab_tiles',
        image: tilesetImage,
        tileWidth: 8,
        tileHeight: 8,
      ),
    },
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: nodeId,
          kind: SceneNodeKind.cinematic,
          title: nodeTitle,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
  );
}

void _expectTimelineStepSelected(WidgetTester tester, String stepId) {
  final card = tester.widget<PokeMapCard>(
    find.byKey(ValueKey('cinematic-builder-step-card-$stepId')),
  );
  expect(card.selected, isTrue);
}

void _expectTransportControlsPresent(WidgetTester tester) {
  for (final key in const [
    'cinematic-builder-transport-reset-button',
    'cinematic-builder-transport-play-button',
    'cinematic-builder-transport-stop-button',
  ]) {
    expect(find.byKey(ValueKey(key)), findsOneWidget);
  }
}

int _playbackTimeMsFromLabel(WidgetTester tester) {
  final label = tester
      .widget<Text>(
        find.byKey(const ValueKey('cinematic-builder-playback-time-label')),
      )
      .data!;
  final elapsed = label.split('/').first.trim();
  if (elapsed.endsWith(' ms')) {
    return int.parse(elapsed.replaceFirst(' ms', ''));
  }
  if (elapsed.endsWith(' s')) {
    final seconds = double.parse(elapsed.replaceFirst(' s', ''));
    return (seconds * 1000).round();
  }
  throw StateError('Unsupported playback label $label');
}

double _fadePreviewOpacity(WidgetTester tester) {
  final finder =
      find.byKey(const ValueKey('cinematic-builder-fade-preview-opacity'));
  if (finder.evaluate().isEmpty) {
    return 0;
  }
  return tester
      .widget<Opacity>(
        finder,
      )
      .opacity;
}

Future<void> _placeTimelineProbeAt(
  WidgetTester tester,
  Offset point,
) async {
  final gesture = await tester.startGesture(
    point,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  await gesture.moveBy(const Offset(24, 0));
  await tester.pump();
  await gesture.moveTo(point);
  await tester.pump();
  await gesture.up();
  await gesture.removePointer();
}

Offset _actorDisplayAnchor(WidgetTester tester, String actorId) {
  return tester
      .getRect(
        find.byKey(ValueKey('cinematic-builder-actor-display-actor-$actorId')),
      )
      .bottomCenter;
}

const _idleSouthSource = TilesetSourceRect(x: 0, y: 1, width: 2, height: 2);
const _walkEastFrame2Source =
    TilesetSourceRect(x: 2, y: 0, width: 2, height: 2);
const _walkSouthFrame2Source =
    TilesetSourceRect(x: 2, y: 1, width: 2, height: 2);
const _runEastFrame1Source = TilesetSourceRect(x: 2, y: 0, width: 2, height: 2);
const _runEastSource = TilesetSourceRect(x: 3, y: 0, width: 2, height: 2);

final class _AnimatedLysaPlaybackSetup {
  const _AnimatedLysaPlaybackSetup({
    required this.asset,
    required this.project,
    required this.mapData,
  });

  final CinematicAsset asset;
  final ProjectManifest project;
  final MapData mapData;
}

Future<_AnimatedLysaPlaybackSetup> _pumpAnimatedLysaPlaybackBuilder(
  WidgetTester tester, {
  required CinematicAsset asset,
  bool includeRunAnimation = true,
  int walkDurationMs = 100,
  int runDurationMs = 90,
}) async {
  final project = _animatedLysaProject(
    asset,
    includeRunAnimation: includeRunAnimation,
    walkDurationMs: walkDurationMs,
    runDurationMs: runDurationMs,
  );
  final mapData = _stageMapDataWithActorDisplayFixtures();
  final tileRenderPlan = await _referenceTileRenderPlanFor(
    project: project,
    mapData: mapData,
  );
  final actorImage = await _loadActorSpriteFixtureImage(tester);
  final actorDisplayModel = _actorDisplayPreviewModelFor(
    project: project,
    asset: asset,
    mapData: mapData,
  );
  final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
    actorDisplayModel: actorDisplayModel,
    project: project,
  );

  await _pumpBuilder(
    tester,
    _entry(project, asset.id),
    asset: asset,
    characters: project.characters,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
    backdropPreviewModel: buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: project.maps.single,
      mapData: mapData,
    ),
    backdropTileRenderPlan: _withActorTileset(tileRenderPlan, actorImage),
    actorDisplayPreviewModel: actorDisplayModel,
    actorSpritePreviewPlan: actorSpritePreviewPlan,
    surfaceSize: _referenceTimelineSurfaceSize,
  );

  return _AnimatedLysaPlaybackSetup(
    asset: asset,
    project: project,
    mapData: mapData,
  );
}

ProjectManifest _animatedLysaProject(
  CinematicAsset asset, {
  required bool includeRunAnimation,
  int walkDurationMs = 100,
  int runDurationMs = 90,
}) {
  return _project(
    cinematics: [asset],
    includeBridge: false,
    characters: [
      _animatedLysaCharacter(
        includeRunAnimation: includeRunAnimation,
        walkDurationMs: walkDurationMs,
        runDurationMs: runDurationMs,
      ),
    ],
  ).copyWith(
    tilesets: const [
      ProjectTilesetEntry(
        id: 'real_actor_tileset',
        name: 'Real actor tileset',
        relativePath: 'test/fixtures/cinematics/actor_sprite_test_sheet.png',
      ),
    ],
  );
}

ProjectCharacterEntry _animatedLysaCharacter({
  required bool includeRunAnimation,
  int walkDurationMs = 100,
  int runDurationMs = 90,
}) {
  return ProjectCharacterEntry(
    id: 'char_lysa',
    name: 'Lysa',
    tilesetId: 'real_actor_tileset',
    frameWidth: 2,
    frameHeight: 2,
    animations: [
      _characterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.south,
        sources: const [_idleSouthSource],
      ),
      _characterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.east,
        sources: const [TilesetSourceRect(x: 0, y: 0, width: 2, height: 2)],
      ),
      _characterAnimation(
        state: CharacterAnimationState.walk,
        direction: EntityFacing.east,
        sources: const [
          TilesetSourceRect(x: 1, y: 0, width: 2, height: 2),
          _walkEastFrame2Source,
        ],
        durationMs: walkDurationMs,
      ),
      _characterAnimation(
        state: CharacterAnimationState.walk,
        direction: EntityFacing.south,
        sources: const [
          TilesetSourceRect(x: 1, y: 1, width: 2, height: 2),
          _walkSouthFrame2Source,
        ],
        durationMs: walkDurationMs,
      ),
      if (includeRunAnimation)
        _characterAnimation(
          state: CharacterAnimationState.run,
          direction: EntityFacing.east,
          sources: const [_runEastFrame1Source, _runEastSource],
          durationMs: runDurationMs,
        ),
    ],
  );
}

CharacterAnimation _characterAnimation({
  required CharacterAnimationState state,
  required EntityFacing direction,
  required List<TilesetSourceRect> sources,
  int durationMs = 150,
}) {
  return CharacterAnimation(
    state: state,
    direction: direction,
    frames: [
      for (final source in sources)
        CharacterAnimationFrame(
          source: source,
          durationMs: durationMs,
        ),
    ],
  );
}

CinematicAsset _animatedLysaPlaybackCinematic(
  CinematicAsset asset, {
  CinematicTimelineActorMovementMode movementMode =
      CinematicTimelineActorMovementMode.walk,
}) {
  final context = asset.stageContext ?? CinematicStageContext();
  return CinematicAsset(
    id: asset.id,
    title: asset.title,
    description: asset.description,
    storylineId: asset.storylineId,
    chapterId: asset.chapterId,
    mapId: asset.mapId,
    tags: asset.tags,
    requiredActors: asset.requiredActors,
    movementTargets: asset.movementTargets,
    stageContext: CinematicStageContext(
      backdropMode: context.backdropMode,
      actorBindings: context.actorBindings,
      actorAppearanceBindings: [
        ...context.actorAppearanceBindings
            .where((binding) => binding.actorId != 'actor_lysa'),
        CinematicActorAppearanceBinding(
          actorId: 'actor_lysa',
          characterId: 'char_lysa',
        ),
      ],
      initialPlacements: context.initialPlacements,
      movementTargetBindings: context.movementTargetBindings,
      stagePoints: context.stagePoints,
      manualPaths: context.manualPaths,
    ),
    timeline: CinematicTimeline(
      steps: [
        for (final step in asset.timeline.steps)
          step.actorId == 'actor_lysa' &&
                  step.kind == CinematicTimelineStepKind.actorMove
              ? _timelineStepWithMovementMode(step, movementMode)
              : step,
      ],
    ),
    notes: asset.notes,
    metadata: asset.metadata,
    legacyBridge: asset.legacyBridge,
  );
}

CinematicTimelineStep _timelineStepWithMovementMode(
  CinematicTimelineStep step,
  CinematicTimelineActorMovementMode movementMode,
) {
  return CinematicTimelineStep(
    id: step.id,
    kind: step.kind,
    label: step.label,
    durationMs: step.durationMs,
    actorId: step.actorId,
    targetId: step.targetId,
    dialogueText: step.dialogueText,
    assetRef: step.assetRef,
    metadata: {
      ...step.metadata,
      cinematicTimelineActorMovementModeMetadataKey: movementMode.name,
    },
  );
}

Future<ui.Image> _loadActorSpriteFixtureImage(WidgetTester tester) async {
  ui.Image? actorImage;
  await tester.runAsync(() async {
    final file = File('test/fixtures/cinematics/actor_sprite_test_sheet.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    actorImage = frame.image;
  });
  return actorImage!;
}

CinematicMapBackdropTileRenderPlan _withActorTileset(
  CinematicMapBackdropTileRenderPlan plan,
  ui.Image actorImage,
) {
  return CinematicMapBackdropTileRenderPlan(
    mapWidth: plan.mapWidth,
    mapHeight: plan.mapHeight,
    tileWidth: plan.tileWidth,
    tileHeight: plan.tileHeight,
    tilesets: {
      ...plan.tilesets,
      'real_actor_tileset': CinematicResolvedTilesetAsset.available(
        tilesetId: 'real_actor_tileset',
        image: actorImage,
        tileWidth: 32,
        tileHeight: 32,
      ),
    },
    instructions: plan.instructions,
    diagnostics: plan.diagnostics,
  );
}

TilesetSourceRect _currentActorSpriteSource(WidgetTester tester) {
  final painters = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<CinematicActorSpritePainter>()
      .toList();
  expect(painters, hasLength(1));
  return painters.single.spriteRef.sourceTileRect;
}

CinematicActorDisplayPreviewActor _testDisplayActor({
  required String actorId,
  required String label,
  required int x,
  required int y,
}) {
  return CinematicActorDisplayPreviewActor(
    actorId: actorId,
    label: label,
    role: null,
    bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
    bindingKind: CinematicActorBindingKind.cinematicOnly,
    bindingSourceId: null,
    bindingSourceLabel: null,
    position: CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.resolved,
      sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
      x: x,
      y: y,
    ),
    appearance: const CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
    ),
    direction: CinematicActorPreviewDirection.south,
    directionSource: CinematicActorPreviewDirectionSource.fallback,
    renderHint: CinematicActorPreviewRenderHint.placeholder,
    diagnostics: const [],
  );
}

CinematicActorDisplayPreviewModel _actorDisplayPreviewModelFor({
  required ProjectManifest project,
  required CinematicAsset asset,
  required MapData mapData,
}) {
  return buildCinematicActorDisplayPreviewModel(
    cinematic: asset,
    project: project,
    stageMap: project.maps.single,
    mapData: mapData,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: mapData),
  );
}

PokeMapButton _transportButton(WidgetTester tester, String action) {
  return tester.widget<PokeMapButton>(
    find.byKey(ValueKey('cinematic-builder-transport-$action-button')),
  );
}

ScrollController _timelineHorizontalScrollController(WidgetTester tester) {
  return tester
      .widget<SingleChildScrollView>(
        find.byKey(const ValueKey('cinematic-builder-time-horizontal-scroll')),
      )
      .controller!;
}

void _setLargeSurface(
  WidgetTester tester, [
  Size surfaceSize = _defaultBuilderSurfaceSize,
]) {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
