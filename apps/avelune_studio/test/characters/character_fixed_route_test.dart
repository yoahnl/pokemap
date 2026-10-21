import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/characters/character_inspector.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  testWidgets('Studio authors a random step without an invented direction', (
    tester,
  ) async {
    final fixture = _fixture();
    await _surface(tester, fixture);
    await _select(tester, 'npc-fixed-route-kind-0', 'Pas aléatoire');
    final movement = fixture.$1.current.entities.single.npc!.movement;
    expect(movement.routeSteps.first, const MapEntityNpcRouteStep.randomMove());
    expect(
      find.byKey(const ValueKey('npc-fixed-route-direction-0')),
      findsNothing,
    );
    expect(
      MapData.fromJson(fixture.$1.current.toJson())
          .entities
          .single
          .npc!
          .movement,
      movement,
    );
    expect(fixture.$1.undoCount, 1);
    fixture.$1.restore(redo: false);
    expect(
      fixture.$1.current.entities.single.npc!.movement.routeSteps.first,
      const MapEntityNpcRouteStep.face(direction: EntityFacing.west),
    );
    expect(tester.takeException(), isNull);
  });

  test('Studio typed command preserves NPC bindings and native history', () {
    final fixture = _fixture();
    final commands = CharacterEditingCommands(fixture.$1, fixture.$2);
    final original = fixture.$1.current;
    final next = original.entities.single.npc!.movement.copyWith(
      routeSteps: const [
        MapEntityNpcRouteStep.move(direction: EntityFacing.east),
        MapEntityNpcRouteStep.face(direction: EntityFacing.north),
      ],
    );
    commands.setMovementConfiguration('npc', next);
    final committed = fixture.$1.current;
    expect(committed.entities.single.npc!.movement, next);
    expect(committed.entities.single.npc!.counterInteractionSides, [
      EntityFacing.north,
    ]);
    expect(committed.entities.single.npc!.characterId, guide.id);
    expect(committed.entities.single.pos, original.entities.single.pos);
    expect(MapData.fromJson(committed.toJson()), committed);
    fixture.$1.restore(redo: false);
    expect(fixture.$1.current, original);
    fixture.$1.restore(redo: true);
    expect(fixture.$1.current, committed);
  });

  testWidgets(
    'Studio inspector guides typed actions, order and scoped suspension',
    (tester) async {
      final fixture = _fixture();
      await _surface(tester, fixture);
      await _select(tester, 'npc-fixed-route-kind-0', 'Avancer');
      await _select(tester, 'npc-fixed-route-direction-0', 'Est');
      final up = find.byTooltip('Monter l’action 2');
      await tester.ensureVisible(up);
      await tester.tap(up);
      await tester.pumpAndSettle();
      var movement = fixture.$1.current.entities.single.npc!.movement;
      expect(movement.routeSteps, const [
        MapEntityNpcRouteStep.randomFacing(),
        MapEntityNpcRouteStep.move(direction: EntityFacing.east),
      ]);
      expect(
        movement.suspendWhenInstanceBoolean,
        MapEntityNpcRouteInstanceBoolean(key: 'npc.autonomousRouteStopped'),
      );
      expect(fixture.$1.current.entities.single.npc!.counterInteractionSides, [
        EntityFacing.north,
      ]);
      await _select(tester, 'npc-fixed-route-suspension', 'Ne pas suspendre');
      expect(
        fixture
            .$1
            .current
            .entities
            .single
            .npc!
            .movement
            .suspendWhenInstanceBoolean,
        isNull,
      );
      await _select(tester, 'npc-fixed-route-suspension', 'Après la victoire');
      movement = fixture.$1.current.entities.single.npc!.movement;
      expect(
        movement.suspendWhenInstanceBoolean?.key,
        'npc.autonomousRouteStopped',
      );
      final encoded = MapData.fromJson(fixture.$1.current.toJson());
      expect(encoded.entities.single.npc!.movement, movement);
      expect(fixture.$1.undoCount, 5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Studio timing fields reject invalid values before history mutation',
    (tester) async {
      final fixture = _fixture();
      await _surface(tester, fixture);
      final field = find.descendant(
        of: find.byKey(const ValueKey('npc-fixed-route-duration')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(fixture.$1.undoCount, 0);
      expect(
        fixture.$1.current.entities.single.npc!.movement.stepDurationMs,
        250,
      );
      expect(
        find.text('La durée du pas doit être comprise entre 1 et 60 000 ms.'),
        findsOneWidget,
      );
      await tester.enterText(field, '480');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        fixture.$1.current.entities.single.npc!.movement.stepDurationMs,
        480,
      );
      expect(fixture.$1.undoCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('3D Studio cannot offer or commit a new fixed route', (
    tester,
  ) async {
    final fixture = _fixture(spatial: true);
    final before = fixture.$1.current;
    final commands = CharacterEditingCommands(fixture.$1, fixture.$2);
    expect(
      () => commands.setMovementConfiguration('npc', _movement()),
      throwsStateError,
    );
    expect(fixture.$1.current, before);
    expect(fixture.$1.undoCount, 0);
    await _surface(tester, fixture);
    final picker = find.byKey(const ValueKey('npc-movement-mode'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.text('Suite de pas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

MapEntityNpcMovementConfig _movement() => MapEntityNpcMovementConfig(
  mode: MapEntityNpcMovementMode.fixedRoute,
  pauseDurationMs: 1600,
  stepDurationMs: 250,
  routeSteps: const [
    MapEntityNpcRouteStep.face(direction: EntityFacing.west),
    MapEntityNpcRouteStep.randomFacing(),
  ],
  suspendWhenInstanceBoolean: MapEntityNpcRouteInstanceBoolean(
    key: 'npc.autonomousRouteStopped',
  ),
);

(EditableMapDocument, ProjectManifest) _fixture({bool spatial = false}) {
  final map = workspaceMap('a').copyWith(
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    entities: [
      MapEntity(
        id: 'npc',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 4),
        npc: MapEntityNpcData(
          characterId: guide.id,
          displayName: 'Guide',
          counterInteractionSides: const [EntityFacing.north],
          movement: spatial ? const MapEntityNpcMovementConfig() : _movement(),
        ),
      ),
    ],
  );
  final project = workspaceProject.copyWith(
    settings: workspaceProject.settings.copyWith(
      dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
    ),
    characters: [guide],
    scenes: [
      SceneAsset(
        id: 'win',
        name: 'Après la victoire',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'stop',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setMapEventInstanceBoolean(
                  mapId: 'a',
                  eventId: 'npc',
                  key: 'npc.autonomousRouteStopped',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'begin',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'stop',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'done',
              fromNodeId: 'stop',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      ),
    ],
  );
  return (
    EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
    ),
    project,
  );
}

Future<void> _surface(
  WidgetTester tester,
  (EditableMapDocument, ProjectManifest) fixture,
) async {
  tester.view.physicalSize = const Size(1024, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 340,
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: CharacterInspector(
                document: fixture.$1,
                project: fixture.$2,
                entity: fixture.$1.current.entities.single,
                visuals: WorkspaceTestVisuals(),
                onChanged: () => setState(() {}),
                onSelect: (_) {},
                onEditInteraction: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String key, String value) async {
  final picker = find.byKey(ValueKey(key));
  await tester.ensureVisible(picker);
  await tester.tap(picker);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}
