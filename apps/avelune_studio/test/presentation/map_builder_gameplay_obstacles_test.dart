import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_gameplay_harness.dart';

void main() {
  testWidgets('field obstacles are placed with a visual and configured', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-space-rubric-fieldObjects')),
    );
    await settle(tester);
    expect(
      find.text('Aucun obstacle de terrain sur cette carte.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-obstacle')));
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-add-obstacle-cutTree')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-obstacle-placement')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );

    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);
    expect(active().entities, isEmpty);

    await choose(tester, 'map-gameplay-obstacle-visual', workspaceElement.name);
    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);

    final obstacle = active().entities.single;
    expect(obstacle.fieldObstacle!.kind, FieldObstacleKind.cutTree);
    expect(obstacle.editorVisual!.elementId, workspaceElement.id);
    expect(
      find.byKey(const ValueKey('map-gameplay-obstacle-form')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );

    await choose(
      tester,
      'map-gameplay-obstacle-reset',
      'Disparaît pour de bon',
    );
    expect(
      active().entities.single.fieldObstacle!.resetPolicy,
      FieldObstacleResetPolicy.persistent,
    );

    await choose(tester, 'map-gameplay-obstacle-kind', 'Bloc de glace');
    final ice = active().entities.single.fieldObstacle!;
    expect(ice.kind, FieldObstacleKind.iceBlock);
    expect(ice.resetPolicy, FieldObstacleResetPolicy.mapInstance);
    expect(
      find.byKey(const ValueKey('map-gameplay-obstacle-reset')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-obstacle-delete')),
    );
    await settle(tester);
    expect(active().entities, isEmpty);
  });

  testWidgets('switching rubric clears the passage selection', (tester) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-form')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-space-rubric-spawns')));
    await settle(tester);
    expect(find.byKey(const ValueKey('map-gameplay-warp-form')), findsNothing);
    expect(find.byKey(const ValueKey('map-gameplay-warp-door')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('map-space-rubric-connections')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-door')),
      findsOneWidget,
    );
  });

  testWidgets('neighbour links go through the connection port', (tester) async {
    await openGameplay(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-east')),
    );
    await settle(tester);

    expect(button(tester, 'map-gameplay-connection-apply').onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-connection-offset')),
      '3',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-apply')),
    );
    await settle(tester);
    expect(connections.calls, ['link east b 3']);
    expect(active().connections.single.offset, 3);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-connection')));
    await settle(tester);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('map-gameplay-connection-edge-east')),
          )
          .onSelected,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-apply')),
    );
    await settle(tester);
    expect(connections.calls.last, 'link north b 0');

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-remove')),
    );
    await settle(tester);
    expect(connections.calls.last, 'unlink north');
    expect(active().connections.map((entry) => entry.direction), [
      MapConnectionDirection.east,
    ]);
  });

  testWidgets('an unsaved map cannot change its links', (tester) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-delete')));
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-east')),
    );
    await settle(tester);

    expect(find.textContaining('Enregistrez la carte'), findsOneWidget);
    expect(button(tester, 'map-gameplay-connection-remove').onPressed, isNull);
    expect(connections.calls, isEmpty);
  });
}
