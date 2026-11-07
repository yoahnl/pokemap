import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_cliff_levels.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_review.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_cliff_guide.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

ProjectManifest _withDraftOnly(ProjectManifest project, {bool keep = true}) {
  final fence = project.borderCatalog.records.single;
  return project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        if (keep) fence,
        BorderBlueprintRecord(
          id: 'cliff-draft',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: fence.draft.definition,
          ),
        ),
      ],
    ),
  );
}

MapBorderDrawingDraft _start(ProjectManifest project, MapData map) =>
    MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'fence',
      origin: const GridPos(x: 2, y: 2),
      sourceMap: map,
      sourceProject: project,
      featureId: 'review',
      seed: BorderSignedInt64.fromInt(3),
    );

Future<MapWorkspaceViewState> _panel(
  WidgetTester tester,
  ProjectManifest project, {
  void Function(MapWorkspaceViewState view, MapData map)? prepare,
  String query = '',
  VoidCallback? onCreate,
  bool modelsLoaded = true,
  bool modelsLoading = false,
  Future<void> Function()? onLoadModels,
}) async {
  final map = spatialBorderMap();
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
  );
  final view = MapWorkspaceViewState()..tool = StudioMapTool.border;
  view.resourceFilters.query = query;
  prepare?.call(view, map);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => MapBorderToolPanel(
            document: document,
            project: project,
            view: view,
            onChanged: () => setState(() {}),
            onCreateModel: onCreate ?? () {},
            modelsLoaded: modelsLoaded,
            modelsLoading: modelsLoading,
            onLoadModels: onLoadModels,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return view;
}

void main() {
  test(
    'only published profiles are offered and drafts point to the workshop',
    () {
      final choices = mapBorderProfileChoices(
        _withDraftOnly(spatialBorderProject()),
      );
      expect(choices.ready.map((record) => record.id), ['fence']);
      expect(choices.drafts.map((record) => record.id), ['cliff-draft']);
    },
  );

  test('a published profile lists its segments, corners and ends', () {
    final definition = spatialBorderProject()
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition;
    expect(
      mapBorderProfilePieces(definition),
      'Pièces : 1 segment · 1 coin · 1 extrémité',
    );
  });

  test('a closed contour has no ends and an open one keeps two', () {
    final project = spatialBorderProject();
    final definition =
        project.borderCatalog.records.single.latestPublished!.definition;
    final open = _start(
      project,
      spatialBorderMap(),
    ).addAngle(const GridPos(x: 6, y: 2)).addAngle(const GridPos(x: 6, y: 6));
    final openReview = mapBorderDraftReview(open, definition);
    expect(openReview.facts.first, 'Contour ouvert · 2 extrémités · 1 angle');
    expect(openReview.warnings, isEmpty);

    final closed = open
        .addAngle(const GridPos(x: 2, y: 6))
        .addAngle(const GridPos(x: 2, y: 2));
    expect(closed.closed, isTrue);
    final closedReview = mapBorderDraftReview(closed, definition);
    expect(
      closedReview.facts.first,
      'Contour fermé · aucune extrémité · 4 angles',
    );
    expect(closedReview.warnings, isEmpty);
  });

  test('a profile without corner pieces warns before an angled contour', () {
    final project = spatialBorderProject(straightOnly: true);
    final definition =
        project.borderCatalog.records.single.latestPublished!.definition;
    final review = mapBorderDraftReview(
      _start(
        project,
        spatialBorderMap(),
      ).addAngle(const GridPos(x: 6, y: 2)).addAngle(const GridPos(x: 6, y: 6)),
      definition,
    );
    expect(review.warnings.single, contains('aucune pièce de coin'));
  });

  testWidgets(
    'no published profile reads as one state with the workshop next',
    (tester) async {
      var opened = 0;
      await _panel(
        tester,
        _withDraftOnly(spatialBorderProject(), keep: false),
        onCreate: () => opened++,
      );
      expect(
        find.textContaining('Aucun modèle de bordure linéaire n’est publié'),
        findsOneWidget,
      );
      expect(find.textContaining('1 modèle en brouillon'), findsOneWidget);
      expect(find.text('Effacer les filtres'), findsNothing);
      await tester.tap(find.text('Créer un modèle'));
      expect(opened, 1);
    },
  );

  testWidgets(
    'filters hiding every profile offer to clear them, not to create',
    (tester) async {
      final view = await _panel(tester, spatialBorderProject(), query: 'zzz');
      expect(
        find.textContaining('Aucune bordure ne correspond aux filtres'),
        findsOneWidget,
      );
      expect(find.text('Créer un modèle'), findsNothing);
      await tester.tap(find.text('Effacer les filtres'));
      await tester.pump();
      expect(view.resourceFilters.query, isEmpty);
      expect(find.byKey(const ValueKey('border-model-picker')), findsOneWidget);
    },
  );

  test('an invalid high level is refused before any write', () {
    expect(
      () => terrainSurfaceNumber('haut', 'La hauteur'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('La hauteur'),
        ),
      ),
    );
    expect(terrainSurfaceNumber('1,5', 'La hauteur'), 1.5);
  });

  testWidgets(
    'a partial map session asks to load models instead of denying them',
    (tester) async {
      var loads = 0;
      await _panel(
        tester,
        _withDraftOnly(spatialBorderProject(), keep: false),
        modelsLoaded: false,
        onLoadModels: () async => loads++,
      );
      expect(find.textContaining('dans ce projet'), findsNothing);
      expect(find.textContaining('pas encore chargés'), findsOneWidget);
      await tester.tap(find.text('Charger les modèles de bordure'));
      await tester.pump();
      expect(loads, 1);
    },
  );

  testWidgets('loading border models shows progress and cannot start twice', (
    tester,
  ) async {
    await _panel(
      tester,
      _withDraftOnly(spatialBorderProject(), keep: false),
      modelsLoaded: false,
      modelsLoading: true,
      onLoadModels: () async {},
    );
    expect(
      find.textContaining('Chargement des modèles de bordure'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Charger les modèles de bordure'), findsNothing);
  });

  MapBorderDrawingDraft along(
    int row, {
    bool reverse = false,
    MapData? source,
    ProjectManifest? project,
  }) {
    final map = source ?? spatialBorderMap();
    final from = GridPos(x: reverse ? 8 : 2, y: row);
    final to = GridPos(x: reverse ? 2 : 8, y: row);
    return MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'fence',
      origin: from,
      sourceMap: map,
      sourceProject: project ?? spatialBorderProject(),
      featureId: 'cliff',
      seed: BorderSignedInt64.fromInt(5),
    ).addAngle(to);
  }

  test('the contour reads low and high levels and the wall side', () {
    final draft = along(4);
    final levels = mapCliffLevels(
      spatialBorderMap(),
      draft.anchors,
      alignment: draft.alignment,
    )!;
    expect(levels.lowLevel, 0);
    expect(levels.highLevel, 2);
    expect(levels.highSide, MapCliffSide.right);
    expect(
      mapCliffLevelsSummary(levels),
      'Bas 0 · haut 2 · paroi à droite du tracé',
    );
    final reversed = along(4, reverse: true);
    expect(
      mapCliffLevels(
        spatialBorderMap(),
        reversed.anchors,
        alignment: reversed.alignment,
      )!.highSide,
      MapCliffSide.left,
    );
  });

  test('a flat contour sends back to the height step', () {
    final state = mapCliffGuideState(
      map: spatialBorderMap(),
      definition: spatialBorderProject()
          .borderCatalog
          .records
          .single
          .latestPublished!
          .definition,
      draft: along(1),
    );
    expect(state.step, MapCliffStep.height);
    expect(state.message, contains('le sol est plat'));
  });

  test('decors standing on the contour are named before applying', () {
    final base = spatialBorderMap();
    final map = base.copyWith(
      spatialScene: base.spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'lamp',
            modelId: 'oak',
            position: Model3dVector3(x: 3.5, y: 0, z: 4.5),
          ),
          SpatialModelInstance(
            id: 'far',
            modelId: 'oak',
            position: Model3dVector3(x: 10.5, y: 0, z: 8.5),
          ),
        ],
      ),
    );
    final draft = along(4);
    final levels = mapCliffLevels(
      map,
      draft.anchors,
      alignment: draft.alignment,
    )!;
    expect(levels.coveredDecorIds, ['lamp']);
    expect(
      mapCliffLevelsSummary(levels),
      endsWith('1 décor le long du tracé'),
    );
  });

  test('moving an angle keeps the contour and refuses a point outside', () {
    final draft = _start(
      spatialBorderProject(),
      spatialBorderMap(),
    ).addAngle(const GridPos(x: 6, y: 2)).addAngle(const GridPos(x: 6, y: 6));
    final moved = draft.moveAngle(2, const GridPos(x: 6, y: 8));
    expect(moved.anchors, const [
      GridPos(x: 2, y: 2),
      GridPos(x: 6, y: 2),
      GridPos(x: 6, y: 8),
    ]);
    expect(moved.featureId, draft.featureId);
    expect(moved.canFinish, isTrue);
    expect(
      () => draft.moveAngle(1, const GridPos(x: 40, y: 2)),
      throwsA(isA<ValidationException>()),
    );
    expect(draft.removeLastAngle()!.anchors, hasLength(2));
  });

  test('hovering keeps the exterior origin of the contour', () {
    final map = spatialBorderMap();
    final draft = MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'fence',
      origin: const GridPos(x: 1, y: 1),
      logicalOrigin: const GridPos(x: -4, y: -3),
    );
    expect(
      draft.pointAt(const GridPos(x: 3, y: 1)).logicalOrigin,
      const GridPos(x: -4, y: -3),
    );
  });

  test('the review states passage and ground before applying', () {
    final definition = spatialBorderProject()
        .borderCatalog
        .records
        .single
        .latestPublished!
        .definition;
    final review = mapBorderDraftReview(along(4), definition);
    expect(
      review.facts,
      contains('Passage : la paroi bloque le joueur sur tout le tracé.'),
    );
  });

  test('an applied cliff undoes, redoes and reloads as native data', () {
    final project = spatialBorderProject();
    final map = spatialBorderMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    MapBorderEditingCommands(
      document,
      project,
    ).finish(along(4, source: map, project: project));
    final applied = document.current;
    expect(applied.layers.whereType<BorderLayer>(), isNotEmpty);
    document.restore(redo: false);
    expect(document.current, map);
    document.restore(redo: true);
    expect(document.current, applied);
    final reloaded = MapData.fromJson(
      jsonDecode(jsonEncode(applied.toJson())) as Map<String, dynamic>,
    );
    expect(
      reloaded.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .id,
      'cliff',
    );
  });

  testWidgets('the guide walks height, profile, contour and review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final view = await _panel(
      tester,
      spatialBorderProject(),
      prepare: (view, map) {
        view.borderBlueprintId = 'fence';
        view.borderDraft = along(4);
      },
    );
    expect(find.byKey(const ValueKey('map-cliff-guide')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('map-cliff-guide-message')))
          .data,
      'Revue : Bas 0 · haut 2 · paroi à droite du tracé.',
    );
    await tester.tap(find.byKey(const ValueKey('border-move-angle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Angle 2 · 8, 4').last);
    await tester.pumpAndSettle();
    expect(view.borderMovingAngle, 1);
    await tester.tap(find.byKey(const ValueKey('map-cliff-relief')));
    await tester.pump();
    expect(view.tool, StudioMapTool.terrain);
    expect(view.spatialTerrainMode, SpatialTerrainMode.relief);
  });
}
