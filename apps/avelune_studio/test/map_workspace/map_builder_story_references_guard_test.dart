import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

NarrativeEventRegistry _registry(List<NarrativeEventRecord> records) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: records,
      legacyClaims: const [],
    );

NarrativeEventRecord _event(
  int index,
  String name,
  NarrativeEventSourceRef source,
) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: index,
  ),
  enabled: true,
);

final _scene = SceneAsset(
  id: 'scene',
  name: 'Scène',
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

final _meeting = _event(
  1,
  'meeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);
final _greeting = _event(
  2,
  'greeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);
final _guarded = _event(
  3,
  'guarded',
  NarrativeEventSourceRef.entityInteract('a', 'start'),
);

MapData _map() => workspaceMap('a').copyWith(
  entities: const [
    MapEntity(
      id: 'luth',
      name: 'Luth',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(displayName: 'Luth'),
    ),
    MapEntity(
      id: 'board',
      name: 'Panneau du village',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 8, y: 1),
      sign: MapEntitySignData(plainText: 'Bourg Geon'),
    ),
    MapEntity(
      id: 'start',
      name: 'Arrivée',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 12, y: 3),
      blocksMovement: false,
      spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
    ),
    MapEntity(
      id: 'other-start',
      name: 'Autre arrivée',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 14, y: 3),
      blocksMovement: false,
      spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
    ),
  ],
  triggers: const [
    MapTrigger(
      id: 'departure',
      name: 'Départ vers la route',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 1, y: 6),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
);

void main() {
  late MapWorkspaceController maps;
  late MapEditingViewportSession view;
  late MapBuilderStoryBinding story;
  late MapBuilderInputSession input;

  Future<void> open(ProjectManifest project, MapData map) async {
    final port = WorkspaceMemoryPort(manifest: project);
    port.saved[map.id] = map;
    maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    view = MapEditingViewportSession();
    addTearDown(view.dispose);
    story = MapBuilderStoryBinding(
      maps: maps,
      changed: () {},
      view: () => view,
    );
    input = MapBuilderInputSession(
      controller: maps,
      view: () => view,
      story: story,
    );
    addTearDown(input.dispose);
  }

  Future<void> openVillage({List<NarrativeEventRecord> more = const []}) =>
      open(
        workspaceProject.copyWith(
          scenes: [_scene],
          eventRegistry: _registry([_meeting, _greeting, ...more]),
        ),
        _map(),
      );

  void pressDelete({LogicalKeyboardKey key = LogicalKeyboardKey.delete}) =>
      mapEditingShortcuts(
            maps,
            view,
            (action) => action(),
            contextAt: input.contextAt,
          ).entries
          .firstWhere((entry) => entry.key.triggers?.contains(key) == true)
          .value();

  void menuDelete(GridPos cell, MapContextFamily family) {
    input.open(cell);
    input.select(input.targets.singleWhere((item) => item.family == family));
    input.run(MapContextCommand.delete);
  }

  MapStoryElement element(String key) => story.elements!.byKey(key)!;

  List<String> entityIds() => [
    for (final entity in maps.active!.current.entities) entity.id,
  ];

  group('elements of a 2D map', () {
    setUp(openVillage);
    const saved = 2;

    test('an element without behaviour is still deleted', () {
      view.select(maps.active!, MapSelectionFamily.marker, 'board');
      pressDelete();
      expect(entityIds(), isNot(contains('board')));
      expect(maps.active!.error, isNull);

      menuDelete(const GridPos(x: 1, y: 6), MapContextFamily.trigger);
      expect(maps.active!.current.triggers, isEmpty);
      expect(maps.active!.error, isNull);
    });

    test('a saved behaviour refuses the deletion and is named', () {
      view.select(maps.active!, MapSelectionFamily.character, 'luth');
      for (final key in [
        LogicalKeyboardKey.delete,
        LogicalKeyboardKey.backspace,
      ]) {
        maps.active!.error = null;
        pressDelete(key: key);
        expect(entityIds(), contains('luth'));
        expect(maps.active!.error, 'carrier:Luth:meeting, greeting');
      }

      maps.active!.error = null;
      menuDelete(const GridPos(x: 3, y: 2), MapContextFamily.character);
      expect(entityIds(), contains('luth'));
      expect(maps.active!.error, 'carrier:Luth:meeting, greeting');
      expect(input.contextOpen, isFalse);
      expect(maps.active!.canUndo, isFalse);
    });

    test('a behaviour that only lives in the draft refuses the deletion', () {
      expect(
        story.addBehaviour(element('entity:board')),
        isTrue,
        reason: story.error,
      );
      expect(story.addBehaviour(element('trigger:departure')), isTrue);
      expect(story.dirty, isTrue);
      expect(maps.project!.eventRegistry!.records, hasLength(saved));

      view.select(maps.active!, MapSelectionFamily.marker, 'board');
      pressDelete();
      expect(entityIds(), contains('board'));
      expect(maps.active!.error, 'carrier:Panneau du village:Comportement 1');

      maps.active!.error = null;
      menuDelete(const GridPos(x: 8, y: 1), MapContextFamily.marker);
      expect(entityIds(), contains('board'));
      expect(maps.active!.error, 'carrier:Panneau du village:Comportement 1');

      view.select(maps.active!, MapSelectionFamily.trigger, 'departure');
      pressDelete();
      expect(maps.active!.current.triggers, hasLength(1));
      expect(maps.active!.error, 'carrier:Départ vers la route:Comportement 1');

      maps.active!.error = null;
      menuDelete(const GridPos(x: 1, y: 6), MapContextFamily.trigger);
      expect(maps.active!.current.triggers, hasLength(1));
      expect(maps.active!.error, 'carrier:Départ vers la route:Comportement 1');
    });

    test('the deletion goes through once the draft removed the behaviours', () {
      expect(
        story.addBehaviour(element('entity:board')),
        isTrue,
        reason: story.error,
      );
      story.undo();
      view.select(maps.active!, MapSelectionFamily.marker, 'board');
      pressDelete();
      expect(entityIds(), isNot(contains('board')));

      for (final record in element('entity:luth').behaviours) {
        expect(story.deleteBehaviour(record), isTrue, reason: story.error);
      }
      expect(maps.project!.eventRegistry!.records, hasLength(saved));
      view.select(maps.active!, MapSelectionFamily.character, 'luth');
      pressDelete();
      expect(maps.active!.error, isNull);
      expect(entityIds(), isNot(contains('luth')));
    });

    test('the context menu deletes once the draft removed the behaviours', () {
      for (final record in element('entity:luth').behaviours) {
        expect(story.deleteBehaviour(record), isTrue, reason: story.error);
      }
      menuDelete(const GridPos(x: 3, y: 2), MapContextFamily.character);
      expect(maps.active!.error, isNull);
      expect(entityIds(), isNot(contains('luth')));
    });

    test(
      'the delete buttons of the game space follow the same guard',
      () async {
        await openVillage(more: [_guarded]);
        final gameplay = MapBuilderGameplayBinding(
          maps: maps,
          view: () => view,
          port: null,
          isActive: () => true,
          changed: () {},
          labels: () => lookupAppLocalizations(const Locale('fr')),
          entityDeletionProblem: (id) =>
              story.deletionProblem(MapStoryElementTarget.entity, id),
          storyProject: story.behaviours.project,
        );

        gameplay.editEntities((commands) => commands.delete('start'));
        expect(entityIds(), contains('start'));
        expect(gameplay.entityError, 'carrier:Arrivée:guarded');

        gameplay.editEntities((commands) => commands.delete('other-start'));
        expect(entityIds(), isNot(contains('other-start')));
        expect(gameplay.entityError, isNull);

        expect(story.deleteBehaviour(_guarded), isTrue, reason: story.error);
        gameplay.editEntities((commands) => commands.delete('start'));
        expect(gameplay.entityError, isNull);
        expect(entityIds(), isNot(contains('start')));
      },
    );
  });

  group('3D decors used as triggers', () {
    late String houseName;

    setUp(() async {
      const root = 'test/fixtures/spatial_first_map';
      final project = ProjectManifest.fromJson(
        jsonDecode(File('$root/project.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(File('$root/maps/first-map.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      houseName = project.models3d
          .singleWhere((model) => model.id == 'house')
          .name;
      await open(
        project.copyWith(
          scenes: [_scene],
          eventRegistry: _registry([
            _event(
              1,
              'door',
              NarrativeEventSourceRef.modelInteract(map.id, 'house_31'),
            ),
          ]),
        ),
        map,
      );
    });

    List<String> instanceIds() => [
      for (final instance in maps.active!.current.spatialScene!.instances)
        instance.id,
    ];

    test('a decor carrying a behaviour is not deleted', () {
      view.select(maps.active!, MapSelectionFamily.decor, 'house_31');
      pressDelete();
      expect(instanceIds(), contains('house_31'));
      expect(maps.active!.error, 'carrier:$houseName:door');

      maps.active!.error = null;
      menuDelete(const GridPos(x: 2, y: 1), MapContextFamily.decor);
      expect(instanceIds(), contains('house_31'));
      expect(maps.active!.error, 'carrier:$houseName:door');
    });

    test('a decor is deleted once the draft removed its behaviour', () {
      final door = story.elements!.byKey('model:house_31')!.behaviours.single;
      expect(door.name, 'door');
      expect(story.deleteBehaviour(door), isTrue, reason: story.error);
      view.select(maps.active!, MapSelectionFamily.decor, 'house_31');
      pressDelete();
      expect(maps.active!.error, isNull);
      expect(instanceIds(), isNot(contains('house_31')));
    });

    test(
      'the 3D view and erase tools cannot delete a decor carrying a behaviour',
      () {
        maps.modelDeletionGuard = story.modelDeletionProblem;
        addTearDown(() => maps.modelDeletionGuard = null);
        final commands = SpatialModelEditingCommands(
          maps.active!,
          maps.project!,
        );

        expect(commands.delete('house_31'), isFalse);
        expect(instanceIds(), contains('house_31'));
        expect(maps.active!.error, 'carrier:$houseName:door');

        maps.active!.error = null;
        expect(commands.delete('stairs_1'), isTrue);
        expect(instanceIds(), isNot(contains('stairs_1')));

        final door = story.elements!.byKey('model:house_31')!.behaviours.single;
        expect(story.deleteBehaviour(door), isTrue, reason: story.error);
        expect(commands.delete('house_31'), isTrue);
        expect(maps.active!.error, isNull);
        expect(instanceIds(), isNot(contains('house_31')));
      },
    );

    test('a decor without behaviour is still deleted', () {
      view.select(maps.active!, MapSelectionFamily.decor, 'stairs_1');
      pressDelete();
      expect(maps.active!.error, isNull);
      expect(instanceIds(), isNot(contains('stairs_1')));
    });
  });
}
