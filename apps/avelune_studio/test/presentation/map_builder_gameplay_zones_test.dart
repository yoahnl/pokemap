import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_gameplay_harness.dart';

void main() {
  testWidgets('movement paints blocked cells and edits movement zones', (
    tester,
  ) async {
    await openGameplay(tester);
    Color? collisions() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter ?? paint.foregroundPainter)
        .whereType<MapEditingOverlay>()
        .single
        .collisionColor;
    expect(collisions(), isNull);

    await tester.tap(find.byKey(const ValueKey('map-space-rubric-movement')));
    await settle(tester);
    expect(collisions(), isNotNull);
    expect(find.text('Aucune case bloquée'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-collision-paint')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-collision-brush')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);
    expect(find.text('1 case bloquée'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-collision-erase')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);
    expect(find.text('Aucune case bloquée'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-collision-erase')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-collision-brush')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-zone')));
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-add-zone-movement')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-zone-placement')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);

    final zone = active().gameplayZones.single;
    expect(zone.kind, GameplayZoneKind.movement);
    expect(
      find.byKey(const ValueKey('map-gameplay-zone-form')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );

    await choose(tester, 'map-gameplay-zone-mode', 'En surf');
    expect(
      active().gameplayZones.single.movement!.requiredMode,
      MovementMode.surf,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('map-gameplay-zone-${zone.id}')),
        matching: find.text('Mode requis · En surf'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-zone-delete')));
    await settle(tester);
    expect(active().gameplayZones, isEmpty);
    expect(
      find.text('Aucune zone de déplacement sur cette carte.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-zone')));
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-add-zone-movementEffect')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);
    expect(
      active().gameplayZones.single.movementEffect!.effectKind,
      MovementEffectZoneKind.slide,
    );

    await choose(tester, 'map-gameplay-zone-effect', 'Coût de déplacement');
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-zone-cost')),
      '0',
    );
    await tester.pump();
    expect(find.text('Entier positif attendu'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-zone-cost')),
      '3',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-zone-cost-apply')),
    );
    await settle(tester);
    final effect = active().gameplayZones.single.movementEffect!;
    expect(effect.effectKind, MovementEffectZoneKind.movementCost);
    expect(effect.movementCost, 3);

    await tester.tap(find.byKey(const ValueKey('map-space-construction')));
    await settle(tester);
    expect(collisions(), isNull);
  });

  testWidgets('encounter zones are painted, bound to a table and erased', (
    tester,
  ) async {
    await openGameplay(
      tester,
      project: workspaceProject.copyWith(
        encounterTables: const [
          ProjectEncounterTable(
            id: 'route-grass',
            name: 'Herbes de la route',
            encounterKind: EncounterKind.walk,
          ),
          ProjectEncounterTable(
            id: 'route-surf',
            name: 'Surf de la route',
            encounterKind: EncounterKind.surf,
          ),
        ],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-encounters')));
    await settle(tester);
    expect(
      find.text('Aucune zone de rencontres sur cette carte.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-encounter-paint')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-encounter-brush')),
      findsOneWidget,
    );
    final canvas = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    await tester.dragFrom(canvas.center, const Offset(48, 0));
    await settle(tester);

    final painted = active().gameplayZones.single;
    expect(painted.kind, GameplayZoneKind.encounter);
    expect(painted.cellMask, isNotNull);
    final cells = painted.cellMask!.length;
    expect(cells, greaterThan(1));
    expect(
      find.byKey(const ValueKey('map-gameplay-encounter-form')),
      findsOneWidget,
    );
    expect(
      find.text('Sans table de rencontres, cette zone ne déclenche rien.'),
      findsOneWidget,
    );

    await choose(tester, 'map-gameplay-encounter-table', 'Surf de la route');
    final bound = active().gameplayZones.single.encounter!;
    expect(bound.encounterTableId, 'route-surf');
    expect(bound.encounterKind, EncounterKind.surf);
    expect(
      find.text('Sans table de rencontres, cette zone ne déclenche rien.'),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('map-gameplay-zone-${painted.id}')),
        matching: find.text('Surf · Surf de la route'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-encounter-erase-from')),
    );
    await settle(tester);
    await tester.tapAt(canvas.center);
    await settle(tester);
    expect(active().gameplayZones.single.cellMask!.length, cells - 1);

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-encounter-rectangle')),
    );
    await settle(tester);
    expect(
      find.byKey(const ValueKey('map-gameplay-zone-placement')),
      findsOneWidget,
    );
    expect(find.text('ZONE DE RENCONTRES'), findsOneWidget);
    await tester.tapAt(canvas.topLeft + const Offset(24, 24));
    await settle(tester);
    expect(active().gameplayZones, hasLength(2));
    expect(active().gameplayZones.last.cellMask, isNull);
  });

  testWidgets('a project without encounter tables says so', (tester) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-encounters')));
    await settle(tester);
    expect(find.textContaining('aucune table de rencontres'), findsOneWidget);
  });
}
