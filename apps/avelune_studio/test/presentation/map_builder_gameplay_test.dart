import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'map_builder_gameplay_harness.dart';

void main() {
  testWidgets('the game space lists the neighbours and passages of the map', (
    tester,
  ) async {
    await openGameplay(tester);

    expect(find.byKey(const ValueKey('map-library')), findsNothing);
    final neighbour = find.byKey(
      const ValueKey('map-gameplay-connection-east'),
    );
    expect(
      find.descendant(of: neighbour, matching: find.text('Jardin')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: neighbour,
        matching: find.text('Bord est · décalage 1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-door')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-search')),
      'introuvable',
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('map-gameplay-warp-door')), findsNothing);
    expect(find.text('Aucun passage sur cette carte.'), findsOneWidget);
  });

  testWidgets('the game space speaks the chosen language', (tester) async {
    await openGameplay(tester, locale: const Locale('en'));

    expect(find.text('Neighbour maps'), findsOneWidget);
    expect(find.text('east edge · offset 1'), findsOneWidget);
    expect(find.text('Cell 4, 5'), findsOneWidget);
    expect(find.text('Cartes voisines'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);
    expect(find.text('Screen transition'), findsOneWidget);
    expect(find.text('Delete this passage'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '9000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(
      find.text('The duration must be between 1 and 5000 ms.'),
      findsOneWidget,
    );
  });

  testWidgets('a selected passage edits its arrival, transition and removal', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);

    expect(
      find.byKey(const ValueKey('map-gameplay-warp-form')),
      findsOneWidget,
    );
    expect(button(tester, 'map-gameplay-warp-apply').onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-x')),
      '7',
    );
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '600',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(active().warps.single.targetPos, const GridPos(x: 7, y: 3));
    expect(active().warps.single.transition.durationSeconds, .6);
    expect(find.text('Non enregistré'), findsOneWidget);

    await choose(tester, 'map-gameplay-warp-transition', 'Instantanée');
    expect(active().warps.single.transition.type, MapWarpTransitionType.none);

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '9000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(find.textContaining('entre 1 et 5000 ms'), findsOneWidget);
    expect(active().warps.single.transition.durationSeconds, .6);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-delete')));
    await settle(tester);
    expect(active().warps, isEmpty);
    expect(find.byKey(const ValueKey('map-gameplay-warp-form')), findsNothing);
  });

  testWidgets('placing a passage arms the map tool until one is placed', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-warp')));
    await settle(tester);

    expect(
      find.byKey(const ValueKey('map-gameplay-warp-placement')),
      findsOneWidget,
    );
    await choose(tester, 'map-gameplay-warp-placement-target', 'Jardin');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Passage',
    );

    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);

    expect(active().warps, hasLength(2));
    final placed = active().warps.last;
    expect(placed.targetMapId, 'b');
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-form')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );

    await tester.tap(find.byKey(const ValueKey('map-space-construction')));
    await settle(tester);
    expect(find.byKey(const ValueKey('map-library')), findsOneWidget);
  });

  testWidgets('starting points are placed, edited and removed from their rubric', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-spawns')));
    await settle(tester);

    expect(find.byKey(const ValueKey('map-gameplay-add')), findsNothing);
    expect(find.text('Aucun point de départ sur cette carte.'), findsOneWidget);
    expect(
      find.text(
        'Aucun départ du joueur : cette carte ne peut pas démarrer seule.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-spawn')));
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-spawn-placement')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      isNot('Sélection'),
    );

    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);

    final spawn = active().entities.single;
    expect(spawn.kind, MapEntityKind.spawn);
    expect(
      find.byKey(const ValueKey('map-gameplay-spawn-form')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );
    expect(
      find.byKey(ValueKey('map-gameplay-spawn-${spawn.id}')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aucun départ du joueur : cette carte ne peut pas démarrer seule.',
      ),
      findsNothing,
    );

    await choose(tester, 'map-gameplay-spawn-facing', 'Gauche');
    expect(active().entities.single.spawn!.facing, EntityFacing.west);

    await choose(tester, 'map-gameplay-spawn-role', 'Événement');
    expect(active().entities.single.spawn!.role, EntitySpawnRole.event);
    expect(
      find.text(
        'Aucun départ du joueur : cette carte ne peut pas démarrer seule.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-spawn-default')));
    await settle(tester);
    expect(active().mapMetadata.defaultSpawnId, spawn.id);

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-spawn-name')),
      'Sortie du labo',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(active().entities.single.name, 'Sortie du labo');

    await tester.tap(find.byKey(const ValueKey('map-gameplay-spawn-delete')));
    await settle(tester);
    expect(active().entities, isEmpty);
    expect(active().mapMetadata.defaultSpawnId, isNull);
    expect(
      find.byKey(const ValueKey('map-gameplay-spawn-form')),
      findsNothing,
    );
  });
}
