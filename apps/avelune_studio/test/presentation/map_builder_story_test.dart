import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

var _events = 0;

NarrativeEventRecord _event(
  String name,
  NarrativeEventSourceRef source, {
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${(++_events).toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene-$name',
    reusePolicy: reuse,
    resetPolicy: reset,
    priority: 0,
    order: 0,
  ),
  enabled: true,
);

final _project = workspaceProject.copyWith(
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [
      _event('meeting', NarrativeEventSourceRef.entityInteract('a', 'luth')),
      _event(
        'after-starter',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
        reuse: NarrativeEventReusePolicy.reusable,
      ),
      _event(
        'leaving',
        NarrativeEventSourceRef.triggerEnter('a', 'departure'),
        reset: const NarrativeEventResetPolicy.onMapReentry(),
      ),
      _event('arrival', NarrativeEventSourceRef.mapEnter('a')),
      _event('elsewhere', NarrativeEventSourceRef.mapEnter('b')),
    ],
    legacyClaims: [],
  ),
);

MapData _map() => workspaceMap('a').copyWith(
  entities: const [
    MapEntity(
      id: 'luth',
      name: 'Luth',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(facing: EntityFacing.east),
    ),
    MapEntity(
      id: 'rival',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 6, y: 4),
      npc: MapEntityNpcData(displayName: 'Rival'),
    ),
    MapEntity(
      id: 'board',
      name: 'Panneau du village',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 8, y: 1),
      sign: MapEntitySignData(plainText: 'Bourg Geon'),
    ),
  ],
  triggers: const [
    MapTrigger(
      id: 'departure',
      name: 'Départ vers la route',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 3),
      ),
    ),
    MapTrigger(
      id: 'camera',
      name: 'Caméra',
      type: TriggerType.camera,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
);

void main() {
  late MapWorkspaceController maps;
  late MapEditingViewportSession view;
  late MapBuilderStoryBinding story;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort(manifest: _project);
    port.saved['a'] = _map();
    maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    view = MapEditingViewportSession();
    final tick = ValueNotifier(0);
    addTearDown(tick.dispose);
    story = MapBuilderStoryBinding(
      maps: maps,
      changed: () => tick.value++,
      view: () => view,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: tick,
            builder: (context, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapBuilderStoryPanel(
                  outline: mapBuilderSpaceOutline(
                    MapBuilderSpace.story,
                    AppLocalizations.of(context),
                  )!,
                  binding: story,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (story.selected) {
                      final element? => MapBuilderStoryInspector(
                        binding: story,
                        element: element,
                      ),
                      null => const Text('rien'),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String subtitle(WidgetTester tester, String key) => tester
      .widget<StudioChoice>(find.byKey(ValueKey('map-story-element-$key')))
      .subtitle!;

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
    expect(find.text('scene-meeting'), findsOneWidget);

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
    expect(find.text('CARTE'), findsOneWidget);
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
