import 'package:avelune_studio/presentation/features/events/event_context_map.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/map_workspace_fixture.dart';

void main() {
  testWidgets('resizing keeps the same map point centered at the same zoom', (
    tester,
  ) async {
    final transform = TransformationController();
    addTearDown(transform.dispose);
    await _mount(tester, transform);
    final viewer = find.byKey(const ValueKey('event-context-viewport'));
    final centerBefore = transform.toScene(
      tester.getSize(viewer).center(Offset.zero),
    );
    final scale = transform.value.getColumn(0).length;
    await _mount(tester, transform, size: const Size(500, 160));
    final centerAfter = transform.toScene(
      tester.getSize(viewer).center(Offset.zero),
    );
    expect(centerAfter.dx, closeTo(centerBefore.dx, .001));
    expect(centerAfter.dy, closeTo(centerBefore.dy, .001));
    expect(transform.value.getColumn(0).length, closeTo(scale, .001));
    expect(tester.takeException(), isNull);
  });
  testWidgets('changing source kind cannot reselect the old entity overlay', (
    tester,
  ) async {
    final transform = TransformationController();
    addTearDown(transform.dispose);
    NarrativeEventSourceRef? selected;
    await _mount(
      tester,
      transform,
      source: NarrativeEventSourceRef.entityInteract('station', 'chief'),
      choosing: NarrativeEventSourceKind.triggerEnter,
      selectable: {NarrativeEventSourceRef.triggerEnter('station', 'platform')},
      onChoose: (value) => selected = value,
    );
    expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('event-target:platform')));
    await tester.pump();
    expect(
      selected,
      NarrativeEventSourceRef.triggerEnter('station', 'platform'),
    );
  });

  testWidgets('context does not outline an entity homonym on another map', (
    tester,
  ) async {
    final transform = TransformationController();
    addTearDown(transform.dispose);
    await _mount(
      tester,
      transform,
      source: NarrativeEventSourceRef.entityInteract('other', 'chief'),
    );
    expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
  });

  testWidgets(
    'source picking follows the transformed target and is read only',
    (tester) async {
      final transform = TransformationController(
        Matrix4.identity()
          ..translateByDouble(50, 60, 0, 1)
          ..scaleByDouble(1.5, 1.5, 1, 1),
      );
      addTearDown(transform.dispose);
      NarrativeEventSourceRef? selected;
      await _mount(
        tester,
        transform,
        choosing: NarrativeEventSourceKind.entityInteract,
        selectable: {
          NarrativeEventSourceRef.entityInteract('station', 'chief'),
        },
        onChoose: (source) => selected = source,
      );
      expect(find.byKey(const ValueKey('event-target:spawn')), findsNothing);
      final target = find.byKey(const ValueKey('event-target:chief'));
      expect(target, findsOneWidget);
      await tester.tap(target);
      await tester.pump();
      expect(
        selected,
        NarrativeEventSourceRef.entityInteract('station', 'chief'),
      );
      expect(transform.value.getMaxScaleOnAxis(), 1.5);
      expect(
        _map.entities.singleWhere((e) => e.id == 'chief').pos,
        const GridPos(x: 3, y: 3),
      );
    },
  );

  testWidgets('map source cannot be chosen when catalog marks it unavailable', (
    tester,
  ) async {
    final transform = TransformationController();
    addTearDown(transform.dispose);
    var choices = 0;
    await _mount(
      tester,
      transform,
      choosing: NarrativeEventSourceKind.mapEnter,
      selectable: {},
      onChoose: (_) => choices++,
    );
    await tester.tapAt(tester.getCenter(find.byType(EventContextMap)));
    await tester.pump();
    expect(choices, 0);
  });

  testWidgets('zoom controls respect viewport bounds and Escape cancels pick', (
    tester,
  ) async {
    final transform = TransformationController();
    addTearDown(transform.dispose);
    var cancelled = false;
    await _mount(
      tester,
      transform,
      choosing: NarrativeEventSourceKind.entityInteract,
      onCancel: () => cancelled = true,
    );
    transform.value = Matrix4.identity()..scaleByDouble(8, 8, 1, 1);
    await tester.tap(find.byTooltip('Agrandir le contexte'));
    await tester.pump();
    expect(transform.value.getMaxScaleOnAxis(), closeTo(8, .00001));
    transform.value = Matrix4.identity()..scaleByDouble(.15, .15, 1, 1);
    await tester.tap(find.byTooltip('Réduire le contexte'));
    await tester.pump();
    expect(transform.value.getColumn(0).length, closeTo(.15, .00001));
    await tester.tap(find.byTooltip('Agrandir le contexte'));
    await tester.pump();
    expect(transform.value.getColumn(0).length, closeTo(.1875, .00001));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(cancelled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester,
  TransformationController transform, {
  NarrativeEventSourceRef? source,
  NarrativeEventSourceKind? choosing,
  Set<NarrativeEventSourceRef>? selectable,
  ValueChanged<NarrativeEventSourceRef>? onChoose,
  VoidCallback? onCancel,
  Size size = const Size(600, 450),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: EventContextMap(
              map: _map,
              project: workspaceProject,
              visuals: WorkspaceTestVisuals(),
              transform: transform,
              source: source,
              chooseKind: choosing,
              selectableSources: selectable,
              onChoose: onChoose,
              onCancel: onCancel,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _map = MapData(
  id: 'station',
  name: 'Gare',
  size: GridSize(width: 8, height: 8),
  layers: [],
  triggers: [
    MapTrigger(
      id: 'platform',
      name: 'Quai',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
  entities: [
    MapEntity(
      id: 'chief',
      name: 'Chef',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 3),
    ),
    MapEntity(
      id: 'spawn',
      name: 'Départ',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);
