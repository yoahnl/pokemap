import 'dart:async';

import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    ProjectManifest? project,
    SceneNodePayload? current,
    Future<MapData> Function(String)? loadMap,
    required ValueChanged<SceneNodePayload> onApply,
  }) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 440,
            child: SceneActionForm(
              project: project ?? _project(),
              current: current,
              loadMap: loadMap ?? (id) async => _map(id),
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pick(WidgetTester tester, String label, String value) async {
    final select = find.byWidgetPredicate(
      (widget) => widget is StudioSelect && widget.label == label,
    );
    await tester.tap(
      find.descendant(
        of: select,
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  StudioButton apply(WidgetTester tester) => tester.widget<StudioButton>(
    find.byWidgetPredicate(
      (widget) =>
          widget is StudioButton &&
          (widget.label == 'Ajouter l’action' ||
              widget.label == 'Appliquer l’action'),
    ),
  );

  testWidgets(
    'placed decor and inspected clip produce a typed action without IDs',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await pump(tester, onApply: applied.add);
      await pick(tester, 'Commande', 'Jouer une animation de décor 3D');
      await pick(tester, 'Carte', 'Village');
      expect(apply(tester).onPressed, isNull);
      await pick(tester, 'Décor placé', 'Porte NB2 · (2.5, 3.5)');
      await pick(tester, 'Animation du décor', 'Ouvrir · 0.12 s');
      expect(find.text('Conserver le passage actuel'), findsOneWidget);
      await pick(tester, 'Passage après l’animation', 'Laisser passer');
      await tester.enterText(find.byType(TextField), '.25');
      await tester.pump();
      await tester.tap(find.text('Ajouter l’action'));
      expect(
        (applied.single as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.playModelAnimation(
          mapId: 'village',
          instanceId: 'village-door',
          animationIndex: 0,
          speed: .25,
          blocksMovementAfter: false,
        ),
      );
    },
  );

  testWidgets(
    'map change clears dependent references and rejects invalid speeds',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await pump(
        tester,
        current: SceneActionPayload.interactive(
          SceneInteractiveCommand.playModelAnimation(
            mapId: 'village',
            instanceId: 'village-door',
            animationIndex: 1,
          ),
        ),
        onApply: applied.add,
      );
      expect(find.text('Fermer · 0.12 s'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '17');
      await tester.pump();
      expect(apply(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(apply(tester).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(apply(tester).onPressed, isNotNull);
      await pick(tester, 'Carte', 'Forêt');
      expect(find.text('Fermer · 0.12 s'), findsNothing);
      expect(apply(tester).onPressed, isNull);
      expect(applied, isEmpty);
      await pick(tester, 'Décor placé', 'Porte NB2 · (2.5, 3.5)');
      expect(apply(tester).onPressed, isNull);
    },
  );

  testWidgets('late map response cannot restore stale decor choices', (
    tester,
  ) async {
    final first = Completer<MapData>(), second = Completer<MapData>();
    await pump(
      tester,
      loadMap: (id) => id == 'village' ? first.future : second.future,
      onApply: (_) {},
    );
    await pick(tester, 'Commande', 'Jouer une animation de décor 3D');
    await pick(tester, 'Carte', 'Village');
    await pick(tester, 'Carte', 'Forêt');
    second.complete(_map('forest'));
    await tester.pumpAndSettle();
    first.complete(
      _map(
        'village',
      ).copyWith(spatialScene: MapSpatialScene(width: 8, depth: 8)),
    );
    await tester.pumpAndSettle();
    final decor = tester.widget<StudioSelect>(
      find.byWidgetPredicate(
        (widget) => widget is StudioSelect && widget.label == 'Décor placé',
      ),
    );
    expect(decor.options.keys, ['forest-door']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '2D projects cannot select the 3D command and retain existing content',
    (tester) async {
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.playModelAnimation(
          mapId: 'village',
          instanceId: 'village-door',
          animationIndex: 0,
        ),
      );
      await pump(
        tester,
        project: _project().copyWith(settings: const ProjectSettings()),
        current: original,
        onApply: (_) => fail('Must remain unchanged'),
      );
      final command = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (widget) => widget is StudioSelect && widget.label == 'Commande',
        ),
      );
      expect(
        command.options.containsKey(NarrativeCommandIds.playModelAnimation),
        isFalse,
      );
      expect(find.textContaining('paramètres avancés'), findsOneWidget);
      expect(apply(tester).onPressed, isNull);
    },
  );

  testWidgets('missing clip stays explicit and cannot publish', (tester) async {
    await pump(
      tester,
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.playModelAnimation(
          mapId: 'village',
          instanceId: 'village-door',
          animationIndex: 9,
        ),
      ),
      onApply: (_) => fail('Invalid clip'),
    );
    expect(find.textContaining('Référence introuvable : 9'), findsOneWidget);
    expect(apply(tester).onPressed, isNull);
  });
}

ProjectManifest _project() => ProjectManifest(
  name: 'Animation 3D',
  maps: const [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'forest', name: 'Forêt', relativePath: 'forest.json'),
  ],
  tilesets: [],
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  models3d: [
    ProjectModel3dEntry(
      id: 'door',
      name: 'Porte NB2',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: .2),
        ),
        meshCount: 1,
        triangleCount: 4,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .12),
          Model3dAnimation(index: 1, name: 'Fermer', durationSeconds: .12),
        ],
      ),
    ),
  ],
);

MapData _map(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: '$id-door',
        modelId: 'door',
        position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
      ),
    ],
  ),
);
