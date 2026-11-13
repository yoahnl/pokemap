import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
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

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: 'Scène $id',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'start-end',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

class _EventPort implements EventPort {
  _EventPort(this.maps);

  final MapWorkspaceController maps;
  final published = <String>[];

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    published.add(id);
    final before = maps.project!;
    final registry = before.eventRegistry!;
    final records = [
      for (final record in registry.records)
        if (record.id != id) record,
      ?current,
    ];
    return ResourceMutationReceipt(
      before: before,
      manifest: before.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: records,
          legacyClaims: registry.legacyClaims,
        ),
      ),
      beforeRevision: 'r${published.length - 1}',
      revision: 'r${published.length}',
      changedPaths: const ['project.json'],
    );
  }
}

NarrativeEventRecord _event(
  String name,
  NarrativeEventSourceRef source, {
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
  int order = 0,
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
    order: order,
  ),
  enabled: true,
);

final _project = workspaceProject.copyWith(
  scenes: [
    for (final id in [
      'meeting',
      'after-starter',
      'leaving',
      'arrival',
      'elsewhere',
      'greeting',
    ])
      _scene('scene-$id'),
  ],
  characters: const [
    ProjectCharacterEntry(id: 'rival', name: 'Silver', tilesetId: 'atlas'),
    ProjectCharacterEntry(
      id: 'elm',
      name: 'Professeur Orme',
      tilesetId: 'atlas',
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [
      _event('meeting', NarrativeEventSourceRef.entityInteract('a', 'luth')),
      _event(
        'after-starter',
        NarrativeEventSourceRef.entityInteract('a', 'luth'),
        reuse: NarrativeEventReusePolicy.reusable,
        order: 1,
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
      npc: MapEntityNpcData(facing: EntityFacing.east, characterId: 'rival'),
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

  Future<void> open(
    WidgetTester tester, {
    ProjectManifest? project,
    Future<ProjectMediaCatalog?> Function(ProjectManifest project)? loadMedia,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort(manifest: project ?? _project);
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
      zoneName: () => 'Nouvelle zone',
      loadMedia: loadMedia,
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

  testWidgets('the add button places characters, signs and story zones', (
    tester,
  ) async {
    await open(tester);
    Finder key(String value) => find.byKey(ValueKey(value));

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-character'));
    await tester.pump();
    await tester.pump();
    expect(key('map-story-character-elm'), findsOneWidget);
    await tester.enterText(key('map-story-character-search'), 'orme');
    await tester.pump();
    expect(key('map-story-character-rival'), findsNothing);
    await tester.tap(key('map-story-character-elm'));
    await tester.pump();
    expect(view.tool, StudioMapTool.character);
    expect(
      find.text('Cliquez sur la carte pour poser Professeur Orme.'),
      findsOneWidget,
    );

    final placed = CharacterEditingCommands(
      maps.active!,
      maps.project!,
    ).place(view.character!, const GridPos(x: 9, y: 9));
    view.select(maps.active!, MapSelectionFamily.character, placed.id);
    story.reconcile();
    await tester.pump();
    expect(view.tool, StudioMapTool.select);
    expect(story.adding, isNull);
    expect(story.selected?.id, placed.id);
    expect(key('map-story-properties-entity:${placed.id}'), findsOneWidget);

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-zone'));
    await tester.pump();
    expect(view.tool, StudioMapTool.zone);
    expect(find.text('Dessinez la zone sur la carte.'), findsOneWidget);
    expect(
      story.addZone(
        const MapRect(
          pos: GridPos(x: 4, y: 4),
          size: GridSize(width: 2, height: 2),
        ),
      ),
      isTrue,
    );
    await tester.pump();
    final zone = maps.active!.current.triggers.last;
    expect(zone.name, 'Nouvelle zone');
    expect(zone.type, TriggerType.event);
    expect(view.selectedFor('a', MapSelectionFamily.trigger), zone.id);
    expect(view.tool, StudioMapTool.select);
    expect(
      story.addZone(
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      ),
      isFalse,
    );

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-sign'));
    await tester.pump();
    expect(view.tool, StudioMapTool.sign);
    await tester.tap(key('map-story-add'));
    await tester.pump();
    expect(view.tool, StudioMapTool.select);
    expect(key('map-story-add-sign'), findsNothing);

    await tester.tap(key('map-story-element-entity:luth'));
    await tester.pump();
    tester.widget<StudioSelect>(key('map-story-appearance')).onChanged!('elm');
    await tester.pump();
    expect(
      maps.active!.current.entities
          .singleWhere((item) => item.id == 'luth')
          .npc!
          .characterId,
      'elm',
    );
  });

  testWidgets('behaviours are edited as a draft and published on save', (
    tester,
  ) async {
    await open(tester);
    Finder key(String value) => find.byKey(ValueKey(value));
    NarrativeEventRecord recordOf(String name) => story.behaviours
        .registry(maps.project!)!
        .records
        .singleWhere((record) => record.name == name);
    StudioSelect select(String value) =>
        tester.widget<StudioSelect>(key(value));

    await tester.tap(key('map-story-element-entity:luth'));
    await tester.pump();
    select('map-story-after').onChanged!('eachTime');
    await tester.pump();
    expect(recordOf('meeting').reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(recordOf('meeting').enabledOrNull, isTrue);
    expect(story.dirty, isTrue);
    expect(
      maps.project!.eventRegistry!.records.first.reusePolicy,
      NarrativeEventReusePolicy.oneShot,
    );

    select('map-story-then').onChanged!('scene-greeting');
    await tester.pump();
    expect(recordOf('meeting').sceneId, 'scene-greeting');

    await tester.tap(key('map-story-behaviour-add'));
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsOneWidget);
    expect(recordOf('Comportement 3').draftOrNull, isNotNull);
    await tester.tap(key('map-story-behaviour-active'));
    await tester.pump();
    expect(story.error, isNotNull);
    expect(recordOf('Comportement 3').enabledOrNull, isNot(isTrue));
    select('map-story-then').onChanged!('scene-greeting');
    await tester.pump();
    await tester.tap(key('map-story-behaviour-active'));
    await tester.pump();
    expect(recordOf('Comportement 3').enabledOrNull, isTrue);

    await tester.tap(key('map-story-behaviour-delete'));
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsNothing);
    story.undo();
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsOneWidget);
    story.redo();
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsNothing);

    final port = _EventPort(maps);
    expect(await story.publish(port), isTrue);
    expect(port.published, hasLength(1));
    expect(story.dirty, isFalse);
    final saved = maps.project!.eventRegistry!.records.singleWhere(
      (record) => record.name == 'meeting',
    );
    expect(saved.sceneId, 'scene-greeting');
    expect(saved.reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(await story.publish(null), isTrue);
  });

  testWidgets('an edit that cannot re-enable a behaviour says so', (
    tester,
  ) async {
    final registry = _project.eventRegistry!;
    await open(
      tester,
      project: _project.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: [
            for (final record in registry.records)
              if (record.name == 'after-starter')
                _event(
                  'after-starter',
                  NarrativeEventSourceRef.entityInteract('a', 'luth'),
                  reuse: NarrativeEventReusePolicy.reusable,
                )
              else
                record,
          ],
          legacyClaims: registry.legacyClaims,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('map-story-element-entity:luth')),
    );
    await tester.pump();
    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('map-story-after')))
        .onChanged!('eachTime');
    await tester.pump();

    expect(story.selectedBehaviour!.enabledOrNull, isFalse);
    expect(
      find.textContaining('Ce comportement a été désactivé'),
      findsOneWidget,
    );
  });

  for (final withMedia in [true, false]) {
    testWidgets(
      'scenes using other maps, rewards and images ${withMedia ? 'keep' : 'without media block'} behaviour edits',
      (tester) async {
        final puzzle = SceneOpenImagePuzzleInteractiveCommand(
          definition: ImagePuzzleDefinition(
            puzzleId: 'kabuto',
            imageResourceId: 'kabuto-image',
            rows: 2,
            columns: 2,
          ),
        );
        final claim = SceneInteractiveCommand.claimPeriodicReward(
          definition: PeriodicItemRewardDefinition(
            rewardId: 'daily',
            label: 'Baie',
            itemId: 'berry',
            quantity: 1,
          ),
        );
        final project = _project.copyWith(
          scenes: [
            ..._project.scenes,
            _actingScene(
              'scene-garden',
              SceneActionPayload.consequence(
                SceneConsequence.setNpcPresence(
                  mapId: 'b',
                  entityId: 'gardener',
                  present: false,
                ),
              ),
              const ['completed'],
            ),
            _actingScene(
              'scene-puzzle',
              SceneActionPayload.interactive(puzzle),
              puzzle.outputPortIds,
            ),
            _actingScene(
              'scene-berry',
              SceneActionPayload.interactive(claim),
              claim.outputPortIds,
              actionId: 'claim',
            ),
            _rewardCheckScene(),
          ],
        );
        await open(
          tester,
          project: project,
          loadMedia: (_) async => withMedia
              ? ProjectMediaCatalog(
                  entries: [
                    ProjectMediaAsset(
                      id: 'kabuto-image',
                      label: 'Kabuto',
                      kind: ProjectMediaKind.image,
                      sourceAssetId: 'kabuto-source',
                    ),
                  ],
                )
              : null,
        );
        expect(story.ready, isFalse);
        await story.prepare();
        expect(story.ready, isTrue);
        expect(story.error, isNull);

        await tester.tap(
          find.byKey(const ValueKey('map-story-element-entity:luth')),
        );
        await tester.pump();
        tester
            .widget<StudioSelect>(find.byKey(const ValueKey('map-story-after')))
            .onChanged!('eachTime');
        await tester.pump();

        final meeting = story.behaviours
            .registry(maps.project!)!
            .records
            .singleWhere((record) => record.name == 'meeting');
        if (withMedia) {
          expect(story.error, isNull);
          expect(meeting.reusePolicy, NarrativeEventReusePolicy.reusable);
          bool buildable(NarrativeEventProjectCatalog catalog, String id) =>
              catalog.scenes
                  .singleWhere((entry) => entry.scene.id == id)
                  .buildable;
          final strict = buildNarrativeEventProjectCatalog(
            project: maps.project!,
            maps: [story.map!],
          );
          final scoped = story.behaviours
              .context(maps.project!, story.map!)
              .catalog;
          for (final id in [
            'scene-garden',
            'scene-puzzle',
            'scene-berry-check',
          ]) {
            expect(buildable(strict, id), isFalse, reason: id);
            expect(buildable(scoped, id), isTrue, reason: id);
          }
        } else {
          expect(story.error, isNotNull);
          expect(meeting.reusePolicy, NarrativeEventReusePolicy.oneShot);
        }
      },
    );
  }
}

SceneAsset _actingScene(
  String id,
  SceneActionPayload payload,
  List<String> ports, {
  String actionId = 'act',
}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: actionId, kind: SceneNodeKind.action, payload: payload),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: actionId,
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ports)
        SceneEdge(
          id: port,
          fromNodeId: actionId,
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

SceneAsset _rewardCheckScene() => SceneAsset(
  id: 'scene-berry-check',
  name: 'scene-berry-check',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource.periodicRewardAvailable(
            reference: PeriodicRewardReference(
              sceneId: 'scene-berry',
              nodeId: 'claim',
              rewardId: 'daily',
            ),
            expectedValue: true,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'check',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'true',
        fromNodeId: 'check',
        fromPortId: 'true',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'false',
        fromNodeId: 'check',
        fromPortId: 'false',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  ),
);
