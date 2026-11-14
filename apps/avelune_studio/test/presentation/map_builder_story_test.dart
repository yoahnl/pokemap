import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_harness.dart';

void main() {
  testWidgets('the story list groups the map elements with their state', (
    tester,
  ) async {
    await open(tester);

    expect(subtitle(tester, 'entity:luth'), '2 comportements');
    expect(subtitle(tester, 'entity:rival'), 'À configurer');
    expect(subtitle(tester, 'entity:board'), 'Configuré');
    expect(subtitle(tester, 'trigger:departure'), '1 comportement');
    expect(subtitle(tester, 'map:a'), '1 comportement');
    expect(find.text('Arrivée à a'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-story-element-trigger:camera')),
      findsNothing,
    );
    expect(find.text('1 élément à configurer sur cette carte'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('map-story-search')),
      'pann',
    );
    await tester.pump();
    expect(find.byType(StudioChoice), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('map-story-search')), '');
    await tester.pump();

    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('map-story-filter')))
        .onChanged!('zone');
    await tester.pump();
    expect(find.byType(StudioChoice), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-story-element-trigger:departure')),
      findsOneWidget,
    );
  });

  testWidgets('selecting an element shows its behaviours and properties', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('rien'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-story-element-entity:luth')),
    );
    await tester.pump();
    expect(view.selectedFor('a', MapSelectionFamily.character), 'luth');
    expect(find.text('PERSONNAGE'), findsOneWidget);
    expect(find.text('a · X 3 · Y 2'), findsOneWidget);
    expect(find.text('COMPORTEMENTS · 2'), findsOneWidget);
    expect(find.text('Le joueur interagit'), findsOneWidget);
    expect(find.text('Une seule fois'), findsOneWidget);
    expect(find.text('Scène scene-meeting'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-story-behaviour-1')));
    await tester.pump();
    expect(find.text('À chaque fois'), findsOneWidget);

    await tester.tap(find.text('Propriétés'));
    await tester.pump();
    expect(find.text('Est'), findsOneWidget);
    expect(find.text('Aucun dresseur'), findsOneWidget);
    expect(find.text('Immobile'), findsOneWidget);
    await tester.tap(find.text('Comportement'));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('map-story-element-trigger:departure')),
    );
    await tester.pump();
    expect(view.selectedFor('a', MapSelectionFamily.trigger), 'departure');
    expect(find.text('Le joueur entre dans la zone'), findsOneWidget);
    expect(find.text('Une fois par visite'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-story-element-map:a')));
    await tester.pump();
    expect(view.hasSelectionIn('a'), isFalse);
    expect(find.text('ÉVÉNEMENT'), findsOneWidget);
    expect(find.text('En arrivant sur la carte'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-story-element-entity:rival')),
    );
    await tester.pump();
    expect(find.text('Aucun comportement pour l’instant.'), findsOneWidget);
  });

  testWidgets('the properties tab edits the element in the map draft', (
    tester,
  ) async {
    await open(tester);
    MapEntity entity(String id) =>
        maps.active!.current.entities.singleWhere((item) => item.id == id);
    Finder key(String value) => find.byKey(ValueKey(value));
    Future<void> commit(String field, String text) async {
      await tester.enterText(key(field), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    await tester.tap(key('map-story-element-entity:luth'));
    await tester.pump();
    await tester.tap(find.text('Propriétés'));
    await tester.pump();

    await commit('map-story-name', 'Luth la sage');
    expect(entity('luth').name, 'Luth la sage');
    expect(entity('luth').npc!.displayName, 'Luth la sage');
    expect(find.text('Luth la sage'), findsWidgets);

    await commit('map-story-x', '25');
    expect(entity('luth').pos, const GridPos(x: 3, y: 2));
    expect(find.text('Cette position sort de la carte.'), findsOneWidget);
    await commit('map-story-x', '5');
    expect(entity('luth').pos, const GridPos(x: 5, y: 2));
    expect(find.text('Cette position sort de la carte.'), findsNothing);

    tester.widget<StudioSelect>(key('map-story-facing')).onChanged!('north');
    await tester.pump();
    expect(entity('luth').npc!.facing, EntityFacing.north);
    await tester.tap(key('map-story-blocks'));
    await tester.pump();
    expect(entity('luth').blocksMovement, isFalse);
    tester.widget<StudioSelect>(key('map-story-movement')).onChanged!('patrol');
    await tester.pump();
    expect(entity('luth').npc!.movement.mode, MapEntityNpcMovementMode.patrol);

    final before = maps.active!.current;
    expect(story.setTrainer(story.selected!, 'ghost'), isFalse);
    expect(maps.active!.current, same(before));
    expect(story.error, isNotNull);

    maps.restore(redo: false);
    expect(entity('luth').npc!.movement.mode, MapEntityNpcMovementMode.idle);

    await tester.tap(key('map-story-element-trigger:departure'));
    await tester.pump();
    await commit('map-story-width', '3');
    final trigger = maps.active!.current.triggers.singleWhere(
      (item) => item.id == 'departure',
    );
    expect(trigger.area.size, const GridSize(width: 3, height: 3));
    await commit('map-story-height', '40');
    expect(
      maps.active!.current.triggers
          .singleWhere((item) => item.id == 'departure')
          .area
          .size
          .height,
      3,
    );

    await tester.tap(key('map-story-element-entity:board'));
    await tester.pump();
    await tester.enterText(key('map-story-sign-text'), 'Bienvenue');
    await tester.tap(key('map-story-name'));
    await tester.pump();
    expect(entity('board').sign!.plainText, 'Bienvenue');
  });
}
