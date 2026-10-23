import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_warp_inspector.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  Future<EditableMapDocument> pump(
    WidgetTester tester, {
    MapData? source,
    ProjectManifest? project,
  }) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = source ?? _map();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, rebuild) => MapWarpInspector(
                  document: document,
                  project: project ?? _project(),
                  warp: document.current.warps.single,
                  onChanged: () => rebuild(() {}),
                  onDeleted: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return document;
  }

  Finder select(String label) => find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );

  Future<void> pick(WidgetTester tester, String label, String value) async {
    await tester.ensureVisible(select(label));
    await tester.tap(
      find.descendant(
        of: select(label),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Appliquer la porte'));
    await tester.tap(find.text('Appliquer la porte'));
    await tester.pumpAndSettle();
  }

  testWidgets('Studio offers native door configuration on an active 3D warp', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Porte animée'), findsOneWidget);
  });

  testWidgets(
    'model clips and cardinal exit are saved atomically and are undoable',
    (tester) async {
      final document = await pump(tester);
      final original = document.current;
      await tester.tap(find.text('Porte animée'));
      await tester.pumpAndSettle();
      expect(document.current, original);
      expect(find.text('Porte de la maison · 4.5, 3.5'), findsOneWidget);
      await pick(tester, 'Animation d’ouverture', 'Fermer');
      await pick(tester, 'Animation de fermeture', 'Ouvrir');
      await pick(tester, 'Case de dégagement', 'Est · 5, 3');
      await apply(tester);
      expect(document.error, isNull);
      expect(
        document.current.warps.single.door,
        const MapWarpDoor(
          instanceId: 'house-door',
          openAnimationIndex: 1,
          closeAnimationIndex: 0,
          exitPos: GridPos(x: 5, y: 3),
        ),
      );
      expect(document.current.spatialScene, original.spatialScene);
      expect(document.current.layers, original.layers);
      expect(document.current.warps.single.targetMapId, 'room');
      expect(
        document.current.warps.single.targetPos,
        const GridPos(x: 2, y: 2),
      );
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, original);
      document.restore(redo: true);
      expect(document.current.warps.single.door!.openAnimationIndex, 1);
    },
  );

  testWidgets('removing a door leaves the normal passage and is undoable', (
    tester,
  ) async {
    final document = await pump(tester, source: _boundMap());
    final original = document.current;
    await tester.tap(find.text('Porte animée'));
    await tester.pumpAndSettle();
    expect(find.text('Modèle de porte'), findsNothing);
    await apply(tester);
    expect(document.current.warps.single.door, isNull);
    expect(
      document.current.warps.single.targetPos,
      original.warps.single.targetPos,
    );
    expect(document.current.spatialScene, original.spatialScene);
    document.restore(redo: false);
    expect(document.current, original);
  });

  testWidgets('a single valid clip can be used for opening and closing', (
    tester,
  ) async {
    final document = await pump(tester, project: _project(singleClip: true));
    await tester.tap(find.text('Porte animée'));
    await tester.pumpAndSettle();
    await apply(tester);
    final door = document.current.warps.single.door!;
    expect(door.openAnimationIndex, 0);
    expect(door.closeAnimationIndex, 0);
    expect(document.error, isNull);
  });

  testWidgets(
    'switching to a passive arrival explicitly clears the local door',
    (tester) async {
      final document = await pump(tester, source: _boundMap());
      await pick(tester, 'Utilisation', 'Point d’arrivée');
      expect(
        document.current.warps.single.triggerMode,
        MapWarpTriggerMode.sceneOnly,
      );
      expect(document.current.warps.single.door, isNull);
      expect(find.text('Porte animée'), findsNothing);
      document.restore(redo: false);
      expect(document.current, _boundMap());
    },
  );

  testWidgets('2D passages do not expose 3D door configuration', (
    tester,
  ) async {
    await pump(tester, source: _map().copyWith(spatialScene: null));
    expect(find.text('Porte animée'), findsNothing);
  });

  testWidgets(
    'an unresolved saved model is explicit and never silently rebound',
    (tester) async {
      final document = await pump(
        tester,
        source: _boundMap(),
        project: _project().copyWith(models3d: []),
      );
      expect(
        find.textContaining('Référence introuvable : house-door'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Placez un modèle avec une animation'),
        findsOneWidget,
      );
      expect(document.current, _boundMap());
      expect(find.text('Appliquer la porte'), findsNothing);
      await tester.tap(find.text('Porte animée'));
      await tester.pumpAndSettle();
      await apply(tester);
      expect(document.current.warps.single.door, isNull);
    },
  );

  testWidgets('automatically playing models are excluded from the picker', (
    tester,
  ) async {
    final source = _map();
    final instance = source.spatialScene!.instances.single;
    await pump(
      tester,
      source: source.copyWith(
        spatialScene: source.spatialScene!.copyWith(
          instances: [instance.copyWith(animationIndex: 0)],
        ),
      ),
    );
    await tester.tap(find.text('Porte animée'));
    await tester.pumpAndSettle();
    final picker = tester.widget<StudioSelect>(select('Modèle de porte'));
    expect(picker.options, isEmpty);
    expect(documentApply(tester).onPressed, isNull);
  });

  testWidgets(
    'the picker binds the chosen local instance rather than its model',
    (tester) async {
      final map = _map();
      final first = map.spatialScene!.instances.single;
      final document = await pump(
        tester,
        source: map.copyWith(
          spatialScene: map.spatialScene!.copyWith(
            instances: [
              first,
              SpatialModelInstance(
                id: 'second-door',
                modelId: first.modelId,
                position: Model3dVector3(x: 6.5, y: 0, z: 3.5),
                blocksMovement: false,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Porte animée'));
      await tester.pumpAndSettle();
      await pick(tester, 'Modèle de porte', 'Porte de la maison · 6.5, 3.5');
      await apply(tester);
      expect(document.current.warps.single.door!.instanceId, 'second-door');
      expect(document.current.spatialScene!.instances, hasLength(2));
    },
  );

  testWidgets('the exit picker only offers cardinal cells inside the map', (
    tester,
  ) async {
    final map = _map();
    await pump(
      tester,
      source: map.copyWith(
        warps: [map.warps.single.copyWith(pos: const GridPos(x: 0, y: 0))],
      ),
    );
    await tester.tap(find.text('Porte animée'));
    await tester.pumpAndSettle();
    expect(tester.widget<StudioSelect>(select('Case de dégagement')).options, {
      '0,1': 'Sud · 0, 1',
      '1,0': 'Est · 1, 0',
    });
  });

  test('invalid clip selection never mutates the document or history', () {
    final map = _map();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    final commands = WarpEditingCommands(document, _project());
    expect(
      () => commands.configureDoor(
        'house',
        const MapWarpDoor(
          instanceId: 'house-door',
          openAnimationIndex: 99,
          closeAnimationIndex: 1,
          exitPos: GridPos(x: 4, y: 4),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(document.current, map);
    expect(document.undoCount, 0);
  });

  test(
    'retargeting preserves an existing door and never rewrites geometry',
    () {
      final map = _boundMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
      );
      WarpEditingCommands(
        document,
        _project(),
      ).retarget('house', targetPos: const GridPos(x: 3, y: 2));
      expect(document.current.warps.single.door, map.warps.single.door);
      expect(document.current.spatialScene, map.spatialScene);
      document.restore(redo: false);
      expect(document.current, map);
    },
  );
}

StudioButton documentApply(WidgetTester tester) => tester.widget<StudioButton>(
  find.byWidgetPredicate(
    (widget) => widget is StudioButton && widget.label == 'Appliquer la porte',
  ),
);

MapData _boundMap() {
  final map = _map();
  return map.copyWith(
    warps: [
      map.warps.single.copyWith(
        door: const MapWarpDoor(
          instanceId: 'house-door',
          openAnimationIndex: 0,
          closeAnimationIndex: 1,
          exitPos: GridPos(x: 4, y: 4),
        ),
      ),
    ],
  );
}

MapData _map() => MapData(
  id: 'village',
  name: 'Village',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: 'house-door',
        modelId: 'door-model',
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
        blocksMovement: false,
      ),
    ],
  ),
  warps: [
    MapWarp(
      id: 'house',
      pos: const GridPos(x: 4, y: 3),
      targetMapId: 'room',
      targetPos: const GridPos(x: 2, y: 2),
    ),
  ],
);

ProjectManifest _project({bool singleClip = false}) => ProjectManifest(
  name: 'Doors',
  version: ProjectVersion.v9,
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  maps: const [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'room', name: 'Maison', relativePath: 'room.json'),
  ],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'door-model',
      name: 'Porte de la maison',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 2,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .25),
          if (!singleClip)
            Model3dAnimation(index: 1, name: 'Fermer', durationSeconds: .25),
        ],
      ),
    ),
  ],
);
