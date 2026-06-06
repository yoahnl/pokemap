import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematics_library_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const _referenceCinematicSurfaceSize = Size(1663, 926);

void main() {
  testWidgets('shows empty state and creates a cinematic shell',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(project: _project(cinematics: const [], includeBridge: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget);
    expect(find.text('Aucune cinématique canonique'), findsOneWidget);
    expect(find.text('Créer une cinématique'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('cinematics-library-create-title-field')),
      'Opening Camera',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-create-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opening Camera'), findsWidgets);
    expect(find.text('Timeline vide'), findsWidgets);
    expect(find.textContaining('Builder V2'), findsWidgets);
  });

  testWidgets('lists canonical and bridge entries with read-only details',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('Legacy cutscene'), findsWidgets);
    expect(find.text('1 scène'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-scenario_cutscene')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bridge legacy — pas un CinematicAsset canonique',
      ),
      findsOneWidget,
    );
    expect(find.text('Bridge legacy Scenario/Cutscene'), findsOneWidget);
    expect(
      find.textContaining(
        'Les bridges legacy viennent de l’ancien Cutscene Studio',
      ),
      findsOneWidget,
    );
    expect(find.text('Migration future'), findsOneWidget);
    expect(find.text('Sauvegarder les métadonnées'), findsNothing);
  });

  testWidgets('shows timeline summary and scene usages for canonical entry',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Résumé timeline'), findsOneWidget);
    expect(find.text('Map stage'), findsOneWidget);
    expect(find.text('Lab map'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('sandbox uniquement'), findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsOneWidget);
    expect(find.text('actor_professor'), findsWidgets);
    expect(find.text('Canonical scene'), findsOneWidget);
    expect(find.text('Play intro'), findsOneWidget);
    expect(find.text('Supprimer la cinématique'), findsOneWidget);
    expect(
      tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('cinematics-library-delete-button')),
      ),
      isNotNull,
    );
  });

  testWidgets('shows stage diagnostics count for canonical entry',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
          cinematics: [
            CinematicAsset(
              id: 'cinematic_stage_diagnostic',
              title: 'Stage diagnostic cinematic',
              stageContext: CinematicStageContext(
                backdropMode: CinematicStageBackdropMode.projectMap,
              ),
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
            ),
          ],
          includeBridge: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map stage'), findsOneWidget);
    expect(find.text('Aucune map'), findsOneWidget);
    expect(find.text('1 diagnostic stage'), findsOneWidget);
  });

  testWidgets('shows preview readiness summary for incomplete stage context',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
          cinematics: [
            CinematicAsset(
              id: 'cinematic_stage_preview_summary',
              title: 'Stage preview summary cinematic',
              mapId: 'map_lab',
              requiredActors: [
                CinematicActorRef(
                  actorId: 'actor_professor',
                  label: 'Professor',
                ),
              ],
              movementTargets: [
                CinematicMovementTargetRef(
                  targetId: 'target_center',
                  label: 'Centre scène',
                ),
              ],
              stageContext: CinematicStageContext(
                backdropMode: CinematicStageBackdropMode.projectMap,
              ),
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
            ),
          ],
          includeBridge: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('contexte incomplet'), findsOneWidget);
  });

  testWidgets('shows preview summary for actor appearance drift',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
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
              id: 'cinematic_appearance_drift_summary',
              title: 'Appearance drift summary cinematic',
              mapId: 'map_lab',
              requiredActors: [
                CinematicActorRef(
                  actorId: 'actor_rival',
                  label: 'Rival actor',
                ),
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
                    label: 'Beat',
                    durationMs: 500,
                  ),
                ],
              ),
            ),
          ],
          includeBridge: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('apparence à corriger'), findsOneWidget);
  });

  testWidgets('opens builder shell for canonical cinematic and returns',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsOneWidget,
    );
    expect(find.text('Cinematic Builder V0'), findsOneWidget);
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);
    expect(find.text('Aperçu sandbox'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematics-library-workspace')),
      findsOneWidget,
    );
    expect(find.text('Bibliothèque'), findsWidgets);
  });

  testWidgets('loads stage map source catalog when opening builder',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();

    final mapEntityButton = find.byKey(
      const ValueKey(
        'cinematic-builder-actor-binding-actor_professor-mapEntity',
      ),
    );
    await tester.ensureVisible(mapEntityButton);
    await tester.tap(mapEntityButton);
    await tester.pumpAndSettle();

    expect(find.text('Professor Oak'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey(
          'cinematic-builder-actor-binding-actor_professor-mapEntity-source-entity_professor',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('wires loaded stage map snapshot into static backdrop preview',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
          cinematics: [
            CinematicAsset(
              id: 'cinematic_backdrop_preview',
              title: 'Backdrop preview cinematic',
              mapId: 'map_lab',
              stageContext: CinematicStageContext(
                backdropMode: CinematicStageBackdropMode.projectMap,
              ),
              timeline: CinematicTimeline(
                steps: [
                  CinematicTimelineStep(
                    id: 'step_wait',
                    kind: CinematicTimelineStepKind.wait,
                    label: 'Hold',
                    durationMs: 500,
                  ),
                ],
              ),
            ),
          ],
          includeBridge: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_backdrop_preview')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
      findsOneWidget,
    );
    expect(find.text('Carte du projet (statique)'), findsOneWidget);
    expect(find.text('Lab map'), findsWidgets);
    expect(find.text('12 x 10 tuiles'), findsOneWidget);
    expect(find.text('Décor seul'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
      ),
      findsOneWidget,
    );
    expect(find.text('Fallback structurel'), findsOneWidget);
    expect(find.text('3 primitive(s) spatiale(s)'), findsOneWidget);
    expect(find.text('Library ground · 2 · tile'), findsOneWidget);
    expect(find.text('Library path · 1 · path'), findsOneWidget);
    expect(find.text('Aperçu sandbox'), findsNothing);
  });

  testWidgets('wires actor display preview model into builder', (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_actor_display_wiring',
          title: 'Actor display wiring',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(
              actorId: 'actor_professor',
              label: 'Professor',
            ),
          ],
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.mapEntity,
                mapEntityId: 'entity_professor',
              ),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.fromMapEntity,
              ),
            ],
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Hold',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
    );

    await tester.pumpWidget(
      _Harness(
        project: project,
        stageMapSnapshots: {'map_lab': _stageMapData()},
      ),
    );
    await _pumpAsyncFrames(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-entry-cinematic_actor_display_wiring'),
      ),
    );
    await _pumpAsyncFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await _pumpAsyncFrames(tester);

    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-actor-display-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'cinematic-builder-actor-display-actor-actor_professor',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Acteurs statiques'), findsWidgets);
    expect(find.text('1 acteur(s) placés'), findsWidgets);
    expect(find.text('Sans lecture'), findsWidgets);
  });

  testWidgets(
      'wires project tileset assets into cinematic real tile backdrop plan',
      (tester) async {
    _setLargeSurface(tester);
    final tilesetPath = await _writeTestTilesetImage();
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_real_backdrop',
          title: 'Real backdrop cinematic',
          mapId: 'map_lab',
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Hold',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
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
    final beforeProject = project.toJson();
    final stageMapData = _stageMapData();
    final beforeMapData = stageMapData.toJson();

    await tester.pumpWidget(
      _Harness(
        project: project,
        stageMapSnapshots: {'map_lab': stageMapData},
        resolveTilesetPath: (tilesetId) =>
            tilesetId == 'lab_tiles' ? tilesetPath : null,
      ),
    );
    await _pumpAsyncFrames(tester);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_real_backdrop')),
    );
    await _pumpAsyncFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await _flushRealAsyncWork(tester);
    await _pumpAsyncFrames(tester);

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
    expect(find.text('Tiles réelles affichées'), findsWidgets);
    expect(find.text('2 tuile(s) bitmap'), findsOneWidget);
    expect(find.text('Fallback structurel'), findsNothing);
    expect(find.text('Sans acteurs'), findsWidgets);
    expect(find.text('Sans lecture'), findsWidgets);

    for (final key in <String>[
      'cinematic-builder-transport-reset-button',
      'cinematic-builder-transport-play-button',
      'cinematic-builder-transport-stop-button',
    ]) {
      final button = tester.widget<PokeMapButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull);
    }

    expect(project.toJson(), beforeProject);
    expect(stageMapData.toJson(), beforeMapData);
  });

  testWidgets('falls back structurally when project tileset asset is missing',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_missing_backdrop_asset',
          title: 'Missing backdrop asset cinematic',
          mapId: 'map_lab',
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Hold',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
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
    final stageMapData = _stageMapData();

    await tester.pumpWidget(
      _Harness(
        project: project,
        stageMapSnapshots: {'map_lab': stageMapData},
        resolveTilesetPath: (_) => null,
      ),
    );
    await _pumpAsyncFrames(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-entry-cinematic_missing_backdrop_asset'),
      ),
    );
    await _pumpAsyncFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await _flushRealAsyncWork(tester);
    await _pumpAsyncFrames(tester);

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
    expect(find.text('3 primitive(s) spatiale(s)'), findsOneWidget);
    expect(find.text('Image de tileset introuvable pour lab_tiles.'),
        findsOneWidget);
    expect(find.text('Tiles réelles affichées'), findsNothing);
  });

  testWidgets('loads project tileset assets into a cinematic tile render plan',
      (tester) async {
    final tilesetPath = await _writeTestTilesetImage();
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_real_backdrop',
          title: 'Real backdrop cinematic',
          mapId: 'map_lab',
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Hold',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
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
    final stageMapData = _stageMapData();
    final previewModel = buildCinematicMapBackdropPreviewModel(
      asset: project.cinematics.single,
      stageMap: project.maps.single,
      mapData: stageMapData,
      availableTilesetIds: const {'lab_tiles'},
    );

    expect(previewModel.isAvailable, isTrue);

    final plan = await tester.runAsync(
      () => CinematicMapBackdropTilePlanLoader().load(
        manifest: project,
        mapData: stageMapData,
        previewModel: previewModel,
        resolveTilesetPath: (tilesetId) =>
            tilesetId == 'lab_tiles' ? tilesetPath : null,
      ),
    );

    expect(plan, isNotNull);
    expect(plan!.hasBitmapInstructions, isTrue);
    expect(plan.instructions, hasLength(2));
    expect(plan.diagnostics, isEmpty);
  });

  test('collects visible tile layer tilesets from layer and map defaults', () {
    const mapData = MapData(
      id: 'map_lab',
      name: 'Lab map',
      tilesetId: 'default_tiles',
      size: GridSize(width: 3, height: 1),
      layers: [
        MapLayer.tile(
          id: 'inherits_default',
          name: 'Inherits default',
          tiles: [1, 0, 0],
        ),
        MapLayer.tile(
          id: 'explicit',
          name: 'Explicit tileset',
          tilesetId: 'explicit_tiles',
          tiles: [0, 2, 0],
        ),
        MapLayer.tile(
          id: 'empty',
          name: 'Empty layer',
          tilesetId: 'empty_tiles',
          tiles: [0, 0, 0],
        ),
        MapLayer.tile(
          id: 'hidden',
          name: 'Hidden layer',
          tilesetId: 'hidden_tiles',
          isVisible: false,
          tiles: [1, 1, 1],
        ),
        MapLayer.tile(
          id: 'transparent',
          name: 'Transparent layer',
          tilesetId: 'transparent_tiles',
          opacity: 0,
          tiles: [1, 1, 1],
        ),
      ],
    );

    expect(
      collectCinematicMapBackdropTileLayerTilesetIds(mapData),
      {'default_tiles', 'explicit_tiles'},
    );
  });

  testWidgets('adds a draft from builder and refreshes library summary',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bloc brouillon'), findsWidgets);
    expect(find.text('Brouillon'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget);
    expect(find.text('3 step(s)'), findsWidgets);
  });

  testWidgets('adds a basic block from builder and refreshes library summary',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attente'), findsWidgets);
    expect(find.text('Bloc authoring V0'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget);
    expect(find.text('3 step(s)'), findsWidgets);
    expect(find.text('1750 ms estimé(s)'), findsWidgets);
  });

  testWidgets('adds an actor facing block from builder and refreshes summary',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await tester.pumpAndSettle();
    final actorFaceButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorFace-button'));
    await tester.ensureVisible(actorFaceButton);
    await tester.tap(actorFaceButton);
    await tester.pumpAndSettle();

    expect(find.text('Orientation Professor'), findsWidgets);
    expect(find.text('Professor'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget);
    expect(find.text('3 step(s)'), findsWidgets);
    expect(find.textContaining('actorFace'), findsWidgets);
    expect(find.textContaining('actor_professor'), findsWidgets);
  });

  testWidgets('keeps legacy bridge out of canonical builder shell',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-scenario_cutscene')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      findsNothing,
    );
    expect(
      find.text('Bridge legacy — pas un CinematicAsset canonique'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsNothing,
    );
  });

  testWidgets('edits metadata and deletes only unused canonicals',
      (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _Harness(
        project: _project(
          extraCinematics: [
            CinematicAsset(
              id: 'cinematic_unused',
              title: 'Unused cinematic',
              timeline: CinematicTimeline(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
    );
    await tester.pumpAndSettle();

    final deleteButton =
        find.byKey(const ValueKey('cinematics-library-delete-button'));
    expect(tester.widget<PokeMapButton>(deleteButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('cinematics-library-title-field')),
      'Intro cinematic edited',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-save-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Intro cinematic edited'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_unused')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<PokeMapButton>(deleteButton).onPressed, isNotNull);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmer suppression'), findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Unused cinematic'), findsNothing);
  });

  testWidgets(
      'captures V1-89 real tile backdrop integration screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_89_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_INTEGRATION',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceCinematicSurfaceSize);
    await _loadScreenshotFonts();
    final tilesetPath = await _writeTestTilesetImage();
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_real_backdrop',
          title: 'Real backdrop cinematic',
          mapId: 'map_lab',
          stageContext: CinematicStageContext(
            backdropMode: CinematicStageBackdropMode.projectMap,
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                label: 'Hold',
                durationMs: 500,
              ),
            ],
          ),
        ),
      ],
      includeBridge: false,
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
    final stageMapData = _stageMapData();

    await tester.pumpWidget(
      _Harness(
        project: project,
        stageMapSnapshots: {'map_lab': stageMapData},
        resolveTilesetPath: (tilesetId) =>
            tilesetId == 'lab_tiles' ? tilesetPath : null,
        surfaceSize: _referenceCinematicSurfaceSize,
      ),
    );
    await _pumpAsyncFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('cinematic-entry-cinematic_real_backdrop')),
    );
    await _pumpAsyncFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
    );
    await _flushRealAsyncWork(tester);
    await _pumpAsyncFrames(tester);

    expect(
      find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
      findsOneWidget,
    );
    expect(find.text('Tiles réelles affichées'), findsWidgets);
    expect(find.text('2 tuile(s) bitmap'), findsOneWidget);
    expect(find.text('Fallback structurel'), findsNothing);
    expect(find.text('Timeline par pistes'), findsOneWidget);
    expect(find.text('Sans acteurs'), findsWidgets);
    expect(find.text('Sans lecture'), findsWidgets);
    expect(tester.takeException(), isNull);

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_'
      'integration_fidelity_polish_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-38 Cinematics Library screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_38_CAPTURE_CINEMATICS_LIBRARY',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await tester.pumpWidget(_Harness(project: _project()));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_38_cinematics_library_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematics-library-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });
}

Future<void> _loadScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
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

class _Harness extends StatefulWidget {
  const _Harness({
    required this.project,
    this.stageMapSnapshots,
    this.resolveTilesetPath,
    this.surfaceSize = const Size(1280, 820),
  });

  final ProjectManifest project;
  final Map<String, MapData?>? stageMapSnapshots;
  final String? Function(String tilesetId)? resolveTilesetPath;
  final Size surfaceSize;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ProjectManifest _project = widget.project;

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            width: widget.surfaceSize.width,
            height: widget.surfaceSize.height,
            child: CinematicsLibraryWorkspace(
              project: _project,
              startExpanded: true,
              onCreateCinematicShell: ({required String title}) async {
                final id = _nextCinematicId(title);
                final result = addCinematicAsset(
                  _project,
                  CinematicAsset(
                    id: id,
                    title: title,
                    timeline: CinematicTimeline(),
                  ),
                );
                setState(() => _project = result.updatedProject);
                return id;
              },
              onUpdateCinematicMetadata: ({
                required String cinematicId,
                required String title,
                required String description,
                required String notes,
              }) async {
                final existing = findCinematicById(_project, cinematicId);
                if (existing == null) {
                  return false;
                }
                final result = updateCinematicAsset(
                  _project,
                  CinematicAsset(
                    id: existing.id,
                    title: title,
                    description: description,
                    storylineId: existing.storylineId,
                    chapterId: existing.chapterId,
                    mapId: existing.mapId,
                    tags: existing.tags,
                    requiredActors: existing.requiredActors,
                    movementTargets: existing.movementTargets,
                    stageContext: existing.stageContext,
                    timeline: existing.timeline,
                    notes: notes,
                    metadata: existing.metadata,
                    legacyBridge: existing.legacyBridge,
                  ),
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onRemoveCinematic: ({required String cinematicId}) async {
                final result = removeCinematicAsset(_project, cinematicId);
                setState(() => _project = result.updatedProject);
                return true;
              },
              onAddTimelineDraft: ({
                required String cinematicId,
                String? afterStepId,
              }) async {
                final result = addCinematicTimelineDraftStep(
                  _project,
                  cinematicId: cinematicId,
                  afterStepId: afterStepId,
                );
                setState(() => _project = result.updatedProject);
                return result.step.id;
              },
              onRemoveTimelineDraft: ({
                required String cinematicId,
                required String stepId,
              }) async {
                final result = removeCinematicTimelineDraftStep(
                  _project,
                  cinematicId: cinematicId,
                  stepId: stepId,
                );
                setState(() => _project = result.updatedProject);
                return result.removedStep.id == stepId;
              },
              onAddTimelineBasicBlock: ({
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
                return result.step.id;
              },
              onUpdateTimelineBasicBlock: ({
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
                return result.step.id == stepId;
              },
              onAddRequiredActor: ({
                required String cinematicId,
                String? label,
              }) async {
                final result = addCinematicRequiredActor(
                  _project,
                  cinematicId: cinematicId,
                  label: label ?? 'Acteur',
                );
                setState(() => _project = result.updatedProject);
                return result.actor.actorId;
              },
              onRenameRequiredActor: ({
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
                return result.actor.actorId == actorId;
              },
              onRemoveRequiredActor: ({
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
                  return result.actor.actorId == actorId;
                } on ArgumentError {
                  return false;
                }
              },
              onAddMovementTarget: ({required String cinematicId}) async {
                final result = addCinematicMovementTarget(
                  _project,
                  cinematicId: cinematicId,
                  label: 'Cible',
                );
                setState(() => _project = result.updatedProject);
                return result.target.targetId;
              },
              onUpdateMovementTarget: ({
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
                return result.target.targetId == targetId;
              },
              onRemoveMovementTarget: ({
                required String cinematicId,
                required String targetId,
              }) async {
                final result = removeCinematicMovementTarget(
                  _project,
                  cinematicId: cinematicId,
                  targetId: targetId,
                );
                setState(() => _project = result.updatedProject);
                return result.removedTarget.targetId == targetId;
              },
              onAddTimelineActorFacing: ({
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
                return result.step.id;
              },
              onUpdateTimelineActorFacing: ({
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
                return result.step.id == stepId;
              },
              onAddTimelineActorMove: ({
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
                return result.step.id;
              },
              onUpdateTimelineActorMove: ({
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
                return result.step.id == stepId;
              },
              onRemoveTimelineAuthoringStep: ({
                required String cinematicId,
                required String stepId,
              }) async {
                final result = removeCinematicTimelineAuthoringStep(
                  _project,
                  cinematicId: cinematicId,
                  stepId: stepId,
                );
                setState(() => _project = result.updatedProject);
                return result.removedStep.id == stepId;
              },
              onUpdateStageMap: ({
                required String cinematicId,
                String? mapId,
              }) async {
                final result = updateCinematicStageMap(
                  _project,
                  cinematicId: cinematicId,
                  mapId: mapId,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onUpdateStageContext: ({
                required String cinematicId,
                required CinematicStageContext stageContext,
              }) async {
                final result = updateCinematicStageContext(
                  _project,
                  cinematicId: cinematicId,
                  stageContext: stageContext,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onUpsertActorBinding: ({
                required String cinematicId,
                required CinematicActorBinding binding,
              }) async {
                final result = upsertCinematicActorBinding(
                  _project,
                  cinematicId: cinematicId,
                  binding: binding,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onUpsertActorAppearanceBinding: ({
                required String cinematicId,
                required CinematicActorAppearanceBinding binding,
              }) async {
                final result = upsertCinematicActorAppearanceBinding(
                  _project,
                  cinematicId: cinematicId,
                  binding: binding,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onRemoveActorAppearanceBinding: ({
                required String cinematicId,
                required String actorId,
              }) async {
                final result = removeCinematicActorAppearanceBinding(
                  _project,
                  cinematicId: cinematicId,
                  actorId: actorId,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onUpsertActorInitialPlacement: ({
                required String cinematicId,
                required CinematicActorInitialPlacement placement,
              }) async {
                final result = upsertCinematicActorInitialPlacement(
                  _project,
                  cinematicId: cinematicId,
                  placement: placement,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onUpsertMovementTargetBinding: ({
                required String cinematicId,
                required CinematicMovementTargetBinding binding,
              }) async {
                final result = upsertCinematicMovementTargetBinding(
                  _project,
                  cinematicId: cinematicId,
                  binding: binding,
                );
                setState(() => _project = result.updatedProject);
                return true;
              },
              onLoadStageMapSnapshot: (mapId) async {
                final snapshots = widget.stageMapSnapshots;
                if (snapshots != null) {
                  return snapshots[mapId];
                }
                return mapId == 'map_lab' ? _stageMapData() : null;
              },
              onResolveBackdropTilesetPath: widget.resolveTilesetPath,
              onOpenLegacyCutsceneStudio: () {},
            ),
          ),
        ),
      ),
    );
  }

  String _nextCinematicId(String title) {
    final slug = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = slug.isEmpty ? 'cinematic' : 'cinematic_$slug';
    final existingIds = _project.cinematics.map((asset) => asset.id).toSet();
    if (!existingIds.contains(base)) {
      return base;
    }
    var index = 2;
    while (existingIds.contains('${base}_$index')) {
      index++;
    }
    return '${base}_$index';
  }
}

Future<String> _writeTestTilesetImage() async {
  final directory = Directory.systemTemp.createTempSync('pokemap_v1_89_tiles_');
  final file = File('${directory.path}/lab.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABAAAAAICAYAAADwdn+XAAAAGklEQVR42mP4bxz6Hx82PtOBFzOMGjAcDAAA2PFDEKrJEdAAAAAASUVORK5CYII=',
      ),
    );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return file.path;
}

MapData _stageMapData() {
  return const MapData(
    id: 'map_lab',
    name: 'Lab map',
    size: GridSize(width: 12, height: 10),
    layers: [
      MapLayer.tile(
        id: 'library_ground',
        name: 'Library ground',
        tilesetId: 'lab_tiles',
        tiles: [1, 0, 2],
      ),
      MapLayer.path(
        id: 'library_path',
        name: 'Library path',
        presetId: 'library_path_preset',
        cells: [false, true, false],
      ),
    ],
    entities: [
      MapEntity(
        id: 'entity_professor',
        name: 'Professor entity',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 6),
        npc: MapEntityNpcData(displayName: 'Professor Oak'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate_bell',
        title: 'Gate bell',
        position: EventPosition(layerId: 'ground', x: 8, y: 3),
        pages: [MapEventPage(pageNumber: 0)],
        type: MapEventType.object,
      ),
    ],
  );
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  List<CinematicAsset> extraCinematics = const [],
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
            CinematicActorRef(
              actorId: 'actor_professor',
              label: 'Professor',
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
                id: 'step_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                label: 'Professor reacts',
                durationMs: 250,
                actorId: 'actor_professor',
              ),
            ],
          ),
        ),
      ...extraCinematics,
    ],
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

void _setLargeSurface(
  WidgetTester tester, [
  Size surfaceSize = const Size(1280, 860),
]) {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpAsyncFrames(
  WidgetTester tester, {
  int frames = 6,
}) async {
  for (var i = 0; i < frames; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _flushRealAsyncWork(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}
