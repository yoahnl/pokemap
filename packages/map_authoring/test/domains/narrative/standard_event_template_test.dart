import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/standard_event_template_fixture.dart';

export '../../support/standard_event_template_fixture.dart'
    show templateMap, templateProject, templateSpec, templateItems;

void main() {
  test('scene identity selection rejects an invalid persisted generation', () {
    expect(
        () => standardEventTemplateSceneIds(
            templateSpec(StandardEventTemplateKind.conditionalNpc),
            generation: 'broken'),
        throwsA(isA<NarrativeAuthoringException>()));
  });
  test('first attachment preserves an idle NPC facing west', () {
    final source = templateMap();
    final entity = source.entities.single.copyWith(
      kind: MapEntityKind.npc,
      npc: const MapEntityNpcData(facing: EntityFacing.west),
    );
    final result = compileStandardEventTemplate(
      project: templateProject(),
      maps: [
        source.copyWith(entities: [entity])
      ],
      spec: templateSpec(StandardEventTemplateKind.conditionalNpc),
    );
    expect(result.pages.map((page) => page.appearance.facing),
        everyElement(EntityFacing.west));
    expect(result.map.entities.single.npc!.facing, EntityFacing.west);
  });

  test('recipe parameter ordering does not change its owned map payload', () {
    final spec = templateSpec(StandardEventTemplateKind.conditionalNpc);
    final reversed = StandardEventTemplateSpec(
        kind: spec.kind,
        mapId: spec.mapId,
        entityId: spec.entityId,
        name: spec.name,
        parameters: Map.fromEntries(spec.parameters.entries.toList().reversed));
    final original = compileStandardEventTemplate(
        project: templateProject(), maps: [templateMap()], spec: spec);
    final reordered = compileStandardEventTemplate(
        project: templateProject(), maps: [templateMap()], spec: reversed);
    expect(reordered.map, original.map);
    expect(reordered.events, original.events);
    expect(reordered.scenes, original.scenes);
  });

  test(
      'first attachment refuses an existing patrol and a nonstandard footprint',
      () {
    final map = templateMap();
    final spec = templateSpec(StandardEventTemplateKind.conditionalNpc);
    final original = map.entities.single;
    for (final entity in [
      original.copyWith(
          kind: MapEntityKind.npc,
          npc: const MapEntityNpcData(
              movement: MapEntityNpcMovementConfig(
                  mode: MapEntityNpcMovementMode.patrol))),
      original.copyWith(size: const GridSize(width: 2, height: 1)),
    ]) {
      expect(
          () => compileStandardEventTemplate(
              project: templateProject(),
              maps: [
                map.copyWith(entities: [entity])
              ],
              spec: spec),
          throwsA(isA<NarrativeAuthoringException>()));
    }
  });

  test('page previews use selected resource names', () {
    final project = templateProject().copyWith(dialogues: const [
      ProjectDialogueEntry(
          id: 'hello',
          name: 'Accueil du jardin',
          relativePath: 'dialogues/hello.yarn'),
      ProjectDialogueEntry(
          id: 'after',
          name: 'Retour au jardin',
          relativePath: 'dialogues/after.yarn'),
    ]);
    final result = compileStandardEventTemplate(
        project: project,
        maps: [templateMap()],
        spec: templateSpec(StandardEventTemplateKind.conditionalNpc));
    expect(result.pages.first.actions, ['Dialogue Accueil du jardin']);
  });

  test('editing forks generated scenes and preserves shared historical scenes',
      () {
    final spec = templateSpec(StandardEventTemplateKind.conditionalNpc);
    final initial = compileStandardEventTemplate(
        project: templateProject(), maps: [templateMap()], spec: spec);
    final foreign = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: 'evt_00000000-0000-7000-8000-000000000041',
            name: 'Foreign',
            source: NarrativeEventSourceRef.mapEnter('room'),
            conditions: [],
            sceneId: initial.scenes.first.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 4),
        enabled: true);
    final project = templateProject().copyWith(
        scenes: initial.scenes,
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [...initial.events, foreign],
            legacyClaims: []));
    final changed = StandardEventTemplateSpec(
        kind: spec.kind,
        mapId: spec.mapId,
        entityId: spec.entityId,
        name: 'Updated',
        parameters: spec.parameters);
    final edited = compileStandardEventTemplate(
        project: project, maps: [initial.map], spec: changed);
    expect(
        edited.scenes
            .map((scene) => scene.id)
            .toSet()
            .intersection(initial.scenes.map((scene) => scene.id).toSet()),
        isEmpty);
    expect(edited.events.map((event) => event.id),
        initial.events.map((event) => event.id));
    expect(
        edited.events.first.definitionOrNull!.sceneId, edited.scenes.first.id);
    expect(project.scenes, initial.scenes);
    expect(foreign.definitionOrNull!.sceneId, initial.scenes.first.id);
    final reopened = project.copyWith(
        scenes: [...project.scenes, ...edited.scenes],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [...edited.events, foreign],
            legacyClaims: []));
    expect(
        readStandardEventTemplate(
            project: reopened, map: edited.map, entityId: spec.entityId),
        isNotNull);
    final same = compileStandardEventTemplate(
        project: reopened, maps: [edited.map], spec: changed);
    expect(same.scenes, edited.scenes);
    final collision = project.copyWith(scenes: [
      ...initial.scenes,
      for (final scene in edited.scenes)
        SceneAsset.fromJson(
            {...scene.toJson(), 'name': 'Advanced historical edit'}),
    ]);
    expect(
        () => compileStandardEventTemplate(
            project: collision, maps: [initial.map], spec: changed),
        throwsA(isA<NarrativeAuthoringException>()));
  });

  for (final port in ['received', 'bagFull']) {
    test('pickup executes $port without consuming the retry path', () async {
      final projection = compileStandardEventTemplate(
          project: templateProject(),
          maps: [templateMap()],
          spec: templateSpec(StandardEventTemplateKind.pickup),
          itemCatalog: templateItems());
      final result = await executeTemplateScene(projection.scenes.single,
          interactivePort: port);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, port == 'received' ? 'end' : 'retry');
      final end = projection.scenes.single.graph.nodes
          .singleWhere((node) => node.id == result.finalNodeId);
      expect(
          (end.payload as SceneEndPayload).outcomePolicy,
          port == 'received'
              ? SceneOutcomePolicy.progression
              : SceneOutcomePolicy.retryable);
    });
  }

  for (final hasKey in [false, true]) {
    test(
        'locked door ${hasKey ? 'passes' : 'refuses'} without consuming the key',
        () async {
      final projection = compileStandardEventTemplate(
          project: templateProject(),
          maps: [templateMap()],
          spec: templateSpec(StandardEventTemplateKind.lockedDoor),
          itemCatalog: templateItems());
      final called = <SceneInteractiveCommand>[];
      final result = await executeTemplateScene(projection.scenes.single,
          conditionPort: hasKey ? 'true' : 'false',
          interactivePort: 'completed',
          onInteractive: called.add);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(called.whereType<SceneWarpInteractiveCommand>(),
          hasKey ? hasLength(1) : isEmpty);
      expect(projection.map.entities.single.blocksMovement, isTrue);
      expect(projection.map.entities.single.interactionMode,
          MapEntityInteractionMode.front);
      expect(
          projection.scenes.single.graph.nodes.where((node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).consequence != null),
          isEmpty);
    });
  }

  for (final outcome in ['victory', 'defeat']) {
    test('trainer $outcome follows its native outcome without faking victory',
        () async {
      final projection = compileStandardEventTemplate(
          project: templateProject(),
          maps: [templateMap()],
          spec: templateSpec(StandardEventTemplateKind.trainer));
      final dialogues = <String>[];
      final result = await executeTemplateScene(projection.scenes.single,
          conditionPort: 'false',
          battlePort: outcome,
          onDialogue: dialogues.add);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(dialogues, outcome == 'victory' ? ['hello', 'after'] : ['hello']);
      expect(result.finalNodeId, outcome == 'victory' ? 'end' : 'retry');
    });
  }

  test('already defeated trainer only shows its after dialogue', () async {
    final projection = compileStandardEventTemplate(
        project: templateProject(),
        maps: [templateMap()],
        spec: templateSpec(StandardEventTemplateKind.trainer));
    var battles = 0;
    final dialogues = <String>[];
    final result = await executeTemplateScene(projection.scenes.single,
        conditionPort: 'true',
        onDialogue: dialogues.add,
        onBattle: () => battles++);
    expect(result.status, SceneRuntimeExecutionStatus.completed);
    expect(battles, 0);
    expect(dialogues, ['after']);
  });

  for (final kind in StandardEventTemplateKind.values) {
    test(
        '${kind.name} editing keeps Event IDs, forks Scene IDs and protects the chosen kind',
        () {
      final spec = templateSpec(kind);
      final initial = compileStandardEventTemplate(
          project: templateProject(),
          maps: [templateMap()],
          spec: spec,
          itemCatalog: templateItems());
      final project = templateProject().copyWith(
          scenes: initial.scenes,
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: initial.events,
              legacyClaims: []));
      final edited = compileStandardEventTemplate(
          project: project,
          maps: [initial.map],
          spec: StandardEventTemplateSpec(
              kind: kind,
              mapId: spec.mapId,
              entityId: spec.entityId,
              name: 'Nouveau nom',
              parameters: spec.parameters),
          itemCatalog: templateItems());
      expect(edited.events.map((event) => event.id),
          initial.events.map((event) => event.id));
      expect(edited.scenes.map((scene) => scene.id),
          isNot(initial.scenes.map((scene) => scene.id)));
      final changedKind = templateSpec(
          kind == StandardEventTemplateKind.conditionalNpc
              ? StandardEventTemplateKind.pickup
              : StandardEventTemplateKind.conditionalNpc);
      expect(
          () => compileStandardEventTemplate(
              project: project,
              maps: [initial.map],
              spec: changedKind,
              itemCatalog: templateItems()),
          throwsA(isA<NarrativeAuthoringException>()));
    });

    test('${kind.name} compiles native executable scene plans', () {
      final result = compileStandardEventTemplate(
          project: templateProject(),
          maps: [templateMap()],
          spec: templateSpec(kind),
          itemCatalog: templateItems());
      for (final scene in result.scenes) {
        final plan = buildSceneRuntimePlan(scene);
        expect(plan.canBuild, isTrue,
            reason: plan.diagnostics
                .map((diagnostic) =>
                    '${diagnostic.code.name}: ${diagnostic.message}')
                .join('\n'));
      }
      expect(
          result.events
              .every((event) => narrativeEventIdPattern.hasMatch(event.id)),
          isTrue);
    });
  }

  test('pickup retry keeps presentation and a second instance isolated', () {
    final first = compileStandardEventTemplate(
        project: templateProject(),
        maps: [templateMap()],
        spec: templateSpec(StandardEventTemplateKind.pickup),
        itemCatalog: templateItems());
    final firstEvent = first.events.single.id;
    final project = templateProject().copyWith(
        scenes: first.scenes,
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: first.events,
            legacyClaims: []));
    final map = first.map.copyWith(entities: [
      ...first.map.entities,
      const MapEntity(
          id: 'second',
          name: 'Second',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1))
    ]);
    final original = templateSpec(StandardEventTemplateKind.pickup);
    final second = compileStandardEventTemplate(
        project: project,
        maps: [map],
        spec: StandardEventTemplateSpec(
            kind: original.kind,
            mapId: original.mapId,
            entityId: 'second',
            name: 'Second',
            parameters: original.parameters),
        itemCatalog: templateItems());
    expect(second.events.single.id, isNot(firstEvent));
    final state = GameState(
        saveId: 'test',
        narrativeEventProgress:
            NarrativeEventProgress(consumedNarrativeEventIds: {firstEvent}));
    expect(first.preview(project: project, gameState: state).visible, isFalse);
    expect(second.preview(project: project, gameState: state).visible, isTrue);
    final failed = first.scenes.single.graph.nodes
        .singleWhere((node) => node.id == 'retry');
    expect((failed.payload as SceneEndPayload).outcomePolicy,
        SceneOutcomePolicy.retryable);
  });

  test('advanced scene edits and foreign source ownership are refused', () {
    final spec = templateSpec(StandardEventTemplateKind.conditionalNpc);
    final result = compileStandardEventTemplate(
        project: templateProject(), maps: [templateMap()], spec: spec);
    final scene = result.scenes.first;
    final altered =
        SceneAsset.fromJson({...scene.toJson(), 'name': 'Manual scene edit'});
    final project = templateProject().copyWith(
        scenes: [altered, ...result.scenes.skip(1)],
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: result.events,
            legacyClaims: []));
    expect(
        readStandardEventTemplate(
            project: project, map: result.map, entityId: spec.entityId),
        isNull);
    expect(
        () => compileStandardEventTemplate(
            project: project, maps: [result.map], spec: spec),
        throwsA(isA<Exception>()));
    final foreignMap = templateMap();
    expect(
        () => compileStandardEventTemplate(
            project: project, maps: [foreignMap], spec: spec),
        throwsA(isA<Exception>()));
  });

  test('invalid references and legacy authority are refused', () {
    final spec = templateSpec(StandardEventTemplateKind.pickup);
    expect(
        () => compileStandardEventTemplate(
            project: templateProject(),
            maps: [templateMap()],
            spec: spec,
            itemCatalog:
                const ProjectItemCatalog(schemaVersion: 1, entries: [])),
        throwsA(isA<Exception>()));
    expect(
        () => compileStandardEventTemplate(
            project: templateProject().copyWith(eventRegistry: null),
            maps: [templateMap()],
            spec: spec,
            itemCatalog: templateItems()),
        throwsA(isA<Exception>()));
  });

  test('conditional NPC compiles stable coordinated pages and reopens', () {
    final map = templateMap();
    final project = templateProject();
    final spec = StandardEventTemplateSpec(
      kind: StandardEventTemplateKind.conditionalNpc,
      mapId: map.id,
      entityId: 'guide',
      name: 'Guide',
      parameters: const {
        'factId': 'met',
        'dialogueId': 'hello',
        'alternateDialogueId': 'after',
        'characterId': 'person',
      },
    );
    final result = compileStandardEventTemplate(
      project: project,
      maps: [map],
      spec: spec,
    );
    expect(result.events, hasLength(2));
    expect(result.pages, hasLength(2));
    expect(result.map.entities.single.presentation!.variants, hasLength(2));
    final saved = project.copyWith(
      scenes: result.scenes,
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: result.events,
        legacyClaims: [],
      ),
    );
    expect(
        readStandardEventTemplate(
          project: saved,
          map: result.map,
          entityId: spec.entityId,
        )?.toJson(),
        spec.toJson());
    final edited = compileStandardEventTemplate(
      project: saved,
      maps: [result.map],
      spec: StandardEventTemplateSpec(
        kind: spec.kind,
        mapId: spec.mapId,
        entityId: spec.entityId,
        name: 'Guide renommé',
        parameters: spec.parameters,
      ),
    );
    expect(edited.events.map((event) => event.id),
        result.events.map((event) => event.id));
  });
}

Future<SceneRuntimeExecutionResult> executeTemplateScene(
  SceneAsset scene, {
  String conditionPort = 'true',
  String interactivePort = 'completed',
  String battlePort = 'victory',
  void Function(SceneInteractiveCommand)? onInteractive,
  void Function(String)? onDialogue,
  void Function()? onBattle,
}) async =>
    SceneRuntimeExecutor(
        callbacks: SceneRuntimeExecutionCallbacks(
      evaluateCondition: (_) => conditionPort,
      showDialogue: (intent) {
        onDialogue?.call(intent.dialogueId!);
        return 'completed';
      },
      startBattle: (_) {
        onBattle?.call();
        return battlePort;
      },
      playCinematic: (_) => throw StateError('Unexpected cinematic'),
      applyConsequence: (_) => throw StateError('Unexpected consequence'),
      executeInteractiveCommand: (intent) {
        onInteractive?.call(intent.interactiveCommand!);
        return interactivePort;
      },
    )).execute(buildSceneRuntimePlan(scene).plan!);
