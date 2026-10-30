import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> command({String output = 'mosaic-image'}) =>
    SceneInteractiveCommand.openImagePuzzle(
        definition: ImagePuzzleDefinition(
      puzzleId: 'mosaic',
      imageResourceId: output,
      rows: 2,
      columns: 2,
      allowedQuarterTurns: [0, 2],
      fixedPieceIds: [0],
      trayCapacity: 2,
      initialPieces: [
        ImagePuzzlePiece(pieceId: 0, slot: 0),
        ImagePuzzlePiece(pieceId: 1, slot: 2, quarterTurns: 2),
        ImagePuzzlePiece(pieceId: 2, slot: 4),
        ImagePuzzlePiece(pieceId: 3, slot: 3)
      ],
    )).toJson();
Map<String, dynamic> scene() => {
      'id': 'puzzle',
      'name': 'Mosaïque',
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'puzzle-node',
            'kind': 'action',
            'payload': {'interactiveCommand': command()}
          },
          {'id': 'end', 'kind': 'end'}
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'puzzle-node',
            'kind': 'default'
          },
          for (final port in ['solved', 'quit'])
            {
              'id': 'leave-$port',
              'fromNodeId': 'puzzle-node',
              'fromPortId': port,
              'toNodeId': 'end',
              'kind': 'actionCompleted'
            }
        ]
      }
    };

void main() {
  test('puzzle semantics are discoverable on all canonical Scene actions', () {
    for (final id in [
      'scene.upsert',
      'scene.graph.patch',
      'scene.interactive_command.set'
    ]) {
      final contract = SceneActions.descriptors
          .singleWhere((action) => action.id == id)
          .extensions['openImagePuzzle'] as Map;
      expect(contract['imageReference'], 'knownProjectMediaKindImage');
      expect(contract['maximumPieces'], 1024);
      expect(contract['outputPorts'], ['solved', 'quit']);
    }
  });
  for (final kind in [
    'badge',
    'inventoryItem',
    'trainerDefeated',
    'worldState'
  ]) {
    test('mixed puzzle preserves typed $kind condition dependencies', () async {
      final seed = _dependencyProject();
      final sourceId = {
        'badge': 'wing',
        'inventoryItem': 'fruit',
        'trainerDefeated': 'rival',
        'worldState': 'weather'
      }[kind]!;
      final mixed = _mixedScene(
          condition: SceneConditionSource.fromJson({
        'sourceKind': kind,
        'sourceId': sourceId,
        'operator': 'isTrue'
      }));
      final fixture = await _PuzzleFixture.create(
          jsonl: false,
          catalog: true,
          mixedProject: seed,
          sceneValue: mixed,
          resources: _dependencyResources());
      addTearDown(fixture.dispose);
      final next = command();
      (next['definition'] as Map)['allowReset'] = false;
      final parameters = {
        'sceneId': 'puzzle',
        'nodeId': 'puzzle-node',
        'command': next
      };
      final snapshot = await fixture.mutations.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'scene.interactive_command.set',
          parameters: parameters);
      if (kind == 'badge') {
        expect(snapshot.manifest.badges.map((badge) => badge.id), ['wing']);
      }
      if (kind == 'inventoryItem') {
        expect(snapshot.itemCatalog?.entries.map((item) => item.id), ['fruit']);
      }
      if (kind == 'trainerDefeated') {
        expect(
            snapshot.manifest.trainers.map((trainer) => trainer.id), ['rival']);
      }
      if (kind == 'worldState') {
        expect(
            snapshot.manifest.worldRules.map((rule) => rule.id), ['weather']);
        expect(
            snapshot.manifest.facts.map((fact) => fact.id), ['world-enabled']);
      }
      expect(
          snapshot.manifest.facts.any((fact) => fact.id == sourceId), isFalse);
      await fixture.apply(
          await fixture.plan('scene.interactive_command.set', parameters));
      await fixture.reopen();
      expect(await fixture.storedCommand(), next);
    });
  }
  for (final action in [
    'scene.upsert',
    'scene.graph.patch',
    'scene.interactive_command.set'
  ]) {
    test('mixed puzzle loads incoming gift moves for $action', () async {
      final before = _giftCommand();
      final gift = _giftCommand(moves: ['tackle']);
      final mixed =
          _mixedScene(actions: [SceneActionPayload.interactive(before)]);
      final fixture = await _PuzzleFixture.create(
          jsonl: false,
          catalog: true,
          mixedProject: _dependencyProject(),
          sceneValue: mixed,
          resources: _dependencyResources());
      addTearDown(fixture.dispose);
      final node = SceneNode(
          id: 'extra-0',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(gift));
      final parameters = switch (action) {
        'scene.upsert' => {
            'scene':
                _mixedScene(actions: [SceneActionPayload.interactive(gift)])
                    .toJson()
          },
        'scene.graph.patch' => {
            'sceneId': 'puzzle',
            'upsertNodes': [node.toJson()]
          },
        _ => {
            'sceneId': 'puzzle',
            'nodeId': 'extra-0',
            'command': gift.toJson()
          },
      };
      final snapshot = await fixture.mutations.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      expect(snapshot.hasResource('pokemonCatalog:moves'), isTrue);
      await fixture.apply(await fixture.plan(action, parameters));
    });
  }
  for (final dependency in [
    'step',
    'journey',
    'music',
    'sound',
    'starter',
    'mapVariants'
  ]) {
    test(
        'mixed puzzle resolves $dependency without loading unrelated definitions',
        () async {
      final seed = _extraDependencyProject();
      final action = switch (dependency) {
        'step' => SceneActionPayload.consequence(
            SceneConsequence.completeStoryStep(stepId: 'step-enter')),
        'journey' => SceneActionPayload.interactive(
            SceneInteractiveCommand.railJourney(
                commandId: 'trip',
                journeyId: 'T1',
                operation: SceneRailJourneyOperation.begin,
                direction: RailJourneyDirection.outbound,
                doorSide: RailJourneyDoorSide.west)),
        'music' => SceneActionPayload.interactive(
            SceneInteractiveCommand.sceneMusic(
                operation: SceneMusicOperation.play,
                mediaAssetId: 'theme',
                volume: 1)),
        'sound' => SceneActionPayload.interactive(
            SceneInteractiveCommand.playSoundEffect(
                mediaAssetId: 'door', volume: 1)),
        'starter' => SceneActionPayload.consequence(
            SceneConsequence.giveConfiguredStarter(starterOptionId: 'starter')),
        _ => SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({
            'kind': 'actorVisibility',
            'target': {'kind': 'entity', 'mapId': 'room', 'entityId': 'actor'},
            'visible': false
          })),
      };
      final fixture = await _PuzzleFixture.create(
          jsonl: false,
          catalog: true,
          mixedProject: seed,
          sceneValue: _mixedScene(actions: [action]),
          resources: {..._dependencyResources(), ..._mapDependencyResources()});
      addTearDown(fixture.dispose);
      final next = command();
      (next['definition'] as Map)['allowReset'] = false;
      final parameters = {
        'sceneId': 'puzzle',
        'nodeId': 'puzzle-node',
        'command': next
      };
      final snapshot = await fixture.mutations.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'scene.interactive_command.set',
          parameters: parameters);
      switch (dependency) {
        case 'step':
          expect(
              snapshot.manifest.storylines.map((story) => story.id), ['main']);
        case 'journey':
          expect(
              snapshot.manifest.railJourneyCatalog?.journeys
                  .map((journey) => journey.id),
              ['T1']);
        case 'music':
          expect(
              snapshot.manifest.cinematicMediaAssets.map((media) => media.id),
              ['theme']);
        case 'sound':
          expect(
              snapshot.manifest.cinematicMediaAssets.map((media) => media.id),
              ['door']);
        case 'starter':
          expect(
              snapshot.manifest.newGame.starterOptions
                  .map((option) => option.id),
              ['starter']);
        case 'mapVariants':
          expect(snapshot.manifest.characters.map((character) => character.id),
              unorderedEquals(['actor-character', 'second-character']));
      }
      await fixture.apply(
          await fixture.plan('scene.interactive_command.set', parameters));
      await fixture.reopen();
      expect(await fixture.storedCommand(), next);
    });
  }
  final readCounts = <int>[];
  for (final unrelated in [0, 128]) {
    test('catalog puzzle edits stay scoped with $unrelated unrelated scenes',
        () async {
      final fixture = await _PuzzleFixture.create(
          jsonl: false, catalog: true, unrelated: unrelated);
      addTearDown(fixture.dispose);
      final descriptor = await fixture.bytes();
      for (var attempt = 0; attempt < 2; attempt++) {
        fixture.reader.paths.clear();
        final timer = Stopwatch()..start();
        final next = command();
        (next['definition'] as Map)['allowReset'] = attempt == 1;
        final parameters = {
          'sceneId': 'puzzle',
          'nodeId': 'puzzle-node',
          'command': next
        };
        final snapshot = await fixture.mutations.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: 'scene.interactive_command.set',
            parameters: parameters);
        expect(snapshot.manifest.scenes.map((scene) => scene.id), ['puzzle']);
        final plan =
            await fixture.plan('scene.interactive_command.set', parameters);
        expect(plan['_resourceChanges'], 1);
        await fixture.apply(plan);
        timer.stop();
        expect(
            fixture.reader.paths.toSet().intersection(fixture.unrelatedObjects),
            isEmpty);
        readCounts.add(fixture.reader.paths.length);
        await File('${fixture.root.parent.path}/measurements.jsonl')
            .writeAsString(
                '${jsonEncode({
                      'unrelatedScenes': unrelated,
                      'attempt': attempt,
                      'reads': fixture.reader.paths.length,
                      'durableMs': timer.elapsedMilliseconds,
                      'mode':
                          'Dart VM focused API fixture, not release UI certification'
                    })}\n',
                mode: FileMode.append);
        expect(fixture.reader.paths.where((path) => path.endsWith('.png')),
            isEmpty);
        expect(await fixture.bytes(), descriptor);
        expect(await fixture.storedCommand(), next);
      }
      final replacement = {
        'sceneId': 'puzzle',
        'upsertNodes': [
          {
            'id': 'puzzle-node',
            'kind': 'action',
            'payload': {
              'interactiveCommand': {'kind': 'wait', 'durationMs': 0}
            }
          }
        ],
        'removeEdgeIds': ['leave-solved', 'leave-quit'],
        'upsertEdges': [
          {
            'id': 'leave-completed',
            'fromNodeId': 'puzzle-node',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'actionCompleted'
          }
        ]
      };
      fixture.reader.paths.clear();
      await fixture.apply(await fixture.plan('scene.graph.patch', replacement));
      expect(fixture.reader.paths.length, lessThan(180));
      final replacementReceipt = fixture.lastReceiptId!;
      await fixture.mutations.undoMutation(fixture.opened.projectHandle,
          entryId: replacementReceipt, idempotencyKey: 'undo-replacement');
      expect((await fixture.storedCommand())['kind'], 'openImagePuzzle');
      await fixture.mutations.redoMutation(fixture.opened.projectHandle,
          entryId: replacementReceipt, idempotencyKey: 'redo-replacement');
      await fixture.mutations.undoMutation(fixture.opened.projectHandle,
          entryId: replacementReceipt,
          idempotencyKey: 'undo-replacement-again');
      final removal = {
        'sceneId': 'puzzle',
        'removeNodeIds': ['puzzle-node'],
        'removeEdgeIds': ['enter', 'leave-solved', 'leave-quit'],
        'upsertEdges': [
          {
            'id': 'direct',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'default'
          }
        ]
      };
      fixture.reader.paths.clear();
      await fixture.apply(await fixture.plan('scene.graph.patch', removal));
      expect(fixture.reader.paths.length, lessThan(180));
      await fixture.mutations.undoMutation(fixture.opened.projectHandle,
          entryId: fixture.lastReceiptId!, idempotencyKey: 'undo-removal');
      await fixture.reopen();
      expect((await fixture.storedCommand())['definition'],
          (command()['definition'] as Map)..['allowReset'] = true);
      if (unrelated > 0) {
        expect(readCounts[2] - readCounts[0], lessThanOrEqualTo(24));
        expect(readCounts[3] - readCounts[1], lessThanOrEqualTo(24));
      }
      expect(readCounts.last, lessThan(128));
    });
  }
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} authors complete puzzle definition and rejects broken image refs without writing',
        () async {
      final fixture = await _PuzzleFixture.create(jsonl: jsonl);
      addTearDown(fixture.dispose);
      final original = await fixture.bytes();
      final plan = await fixture.plan('scene.upsert', {'scene': scene()});
      expect(await fixture.bytes(), original);
      await fixture.apply(plan);
      expect(await fixture.storedCommand(), command());
      final before = await fixture.bytes();
      await fixture.expectRefusal('scene.interactive_command.set', {
        'sceneId': 'puzzle',
        'nodeId': 'puzzle-node',
        'command': command(output: 'missing')
      });
      expect(await fixture.bytes(), before);
      await fixture.expectRefusal('scene.interactive_command.set', {
        'sceneId': 'puzzle',
        'nodeId': 'puzzle-node',
        'command': command(output: 'sound')
      });
      final malformed = command();
      (malformed['definition'] as Map)['rows'] = 0;
      await expectLater(
          () => fixture.plan('scene.interactive_command.set', {
                'sceneId': 'puzzle',
                'nodeId': 'puzzle-node',
                'command': malformed
              }),
          throwsA(anything));
      expect(await fixture.bytes(), before);
      await fixture.reopen();
      expect(await fixture.storedCommand(), command());
    });
  }
}

final class _PuzzleFixture {
  _PuzzleFixture(this.root, this.api, this.mutations, this.snapshots,
      this.jsonl, this.catalog, this.reader, this.unrelatedObjects)
      : worker = JsonlWorker(api: api, mutations: mutations);

  final Directory root;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final bool jsonl;
  final bool catalog;
  final _CountingReader reader;
  final Set<String> unrelatedObjects;
  final JsonlWorker worker;
  late OpenedProject opened;
  var sequence = 0;
  String? lastReceiptId;

  File get file => File('${root.path}/project.json');

  static Future<_PuzzleFixture> create(
      {required bool jsonl,
      bool catalog = false,
      int unrelated = 0,
      ProjectManifest? mixedProject,
      SceneAsset? sceneValue,
      Map<String, Object?> resources = const {}}) async {
    final qaRoot = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle-authoring');
    await qaRoot.create(recursive: true);
    final root = await qaRoot.createTemp('deferred-puzzle-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      const ProjectManifest(name: 'Puzzle', maps: [], tilesets: []).toJson(),
    ));
    await Directory('${root.path}/assets').create();
    await File('${root.path}/assets/.pokemap-media.json')
        .writeAsString(jsonEncode(ProjectMediaCatalog(entries: [
      ProjectMediaAsset(
          id: 'mosaic-image',
          label: 'Mosaïque',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'mosaic-source'),
      ProjectMediaAsset(
          id: 'sound',
          label: 'Son',
          kind: ProjectMediaKind.audio,
          sourceAssetId: 'sound-source'),
    ]).toJson()));
    for (final entry in resources.entries) {
      final file = File('${root.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(entry.value));
    }
    final unrelatedObjects = <String>{};
    if (catalog) {
      await File('${root.path}/project.json').delete();
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
          store: store,
          projectId: 'puzzle',
          project: (mixedProject ??
                  const ProjectManifest(name: 'Puzzle', maps: [], tilesets: []))
              .copyWith(scenes: [
            sceneValue ?? SceneAsset.fromJson(scene()),
            for (var i = 0; i < unrelated; i++)
              SceneAsset(
                  id: 'unrelated-$i',
                  name: 'Unrelated $i',
                  graph: SceneGraph(startNodeId: 'start', nodes: [
                    SceneNode(id: 'start', kind: SceneNodeKind.start)
                  ]))
          ]));
      for (var position = 1; position <= unrelated; position++) {
        final entry = (await working.catalog.snapshot.indexEntry(
            CatalogMetadataDocuments.definitionKey('scenes', position)))!;
        unrelatedObjects.add('catalog/objects/${entry.reference.sha256}.json');
      }
    }
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: catalog ? {} : null,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      catalogFileReader: reader,
    );
    final fixture = _PuzzleFixture(root, api, mutations, snapshots, jsonl,
        catalog, reader, unrelatedObjects);
    await fixture.reopen();
    return fixture;
  }

  Future<void> reopen() async {
    opened = await api.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  }

  Future<List<int>> bytes() => file.readAsBytes();

  Future<Map<String, Object?>> plan(
    String action,
    Map<String, Object?> parameters,
  ) async {
    final snapshot = catalog
        ? await mutations.readWorkshopSnapshot(opened.projectHandle,
            actionId: action, parameters: parameters)
        : await snapshots.load(opened.projectHandle);
    final request = AuthoringRequest(
      requestId: 'puzzle-${++sequence}',
      actionId: action,
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'puzzle-$sequence',
      parameters: parameters,
    );
    if (!jsonl) {
      final planned =
          await mutations.planMutation(opened.projectHandle, request);
      return {
        ...planned.toJson(),
        '_resourceChanges': planned.plan.changeSet.changes.length
      };
    }
    final response = await _jsonl('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson(),
    });
    if (response.status != AuthoringResultStatus.success) {
      throw response.error!;
    }
    return response.data;
  }

  Future<void> expectRefusal(
    String action,
    Map<String, Object?> parameters,
  ) async {
    await expectLater(
      () => plan(action, parameters),
      throwsA(jsonl
          ? isA<AuthoringError>().having(
              (error) => error.details['domainCode'],
              'domainCode',
              'scene.publication_blocked',
            )
          : isA<NarrativeAuthoringException>().having(
              (error) => error.code,
              'code',
              'scene.publication_blocked',
            )),
    );
  }

  Future<void> apply(Map<String, Object?> plan) async {
    final Map<String, Object?> result;
    if (jsonl) {
      final response = await _jsonl('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': 'puzzle-apply-$sequence',
      });
      expect(response.status, AuthoringResultStatus.success,
          reason: jsonEncode(response.toJson()));
      result = response.data;
    } else {
      result = await mutations.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'puzzle-apply-$sequence',
      );
    }
    expect((result['receipt']! as Map)['status'], 'applied');
    lastReceiptId = (result['receipt']! as Map)['receiptId'] as String;
  }

  Future<AuthoringResult> _jsonl(
      String command, Map<String, Object?> args) async {
    final encoded = await worker.processLine(jsonEncode({
      'id': 'puzzle-$command-$sequence',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> storedCommand() async {
    if (catalog) {
      final snapshot = await mutations.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: 'scene.upsert',
          parameters: {'scene': scene()});
      return ((snapshot.manifest.scenes.single.graph.nodes
                  .singleWhere((node) => node.id == 'puzzle-node')
                  .payload as SceneActionPayload)
              .interactiveCommand!)
          .toJson();
    }
    final manifest = jsonDecode(await file.readAsString()) as Map;
    final savedScene = (manifest['scenes'] as List).single as Map;
    final graph = savedScene['graph'] as Map;
    final gift = (graph['nodes'] as List).cast<Map>().singleWhere(
          (node) => node['id'] == 'puzzle-node',
        );
    return Map<String, dynamic>.from(
        (gift['payload'] as Map)['interactiveCommand'] as Map);
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

ProjectManifest _dependencyProject() => ProjectManifest.fromJson({
      ...const ProjectManifest(
              name: 'Dependencies',
              maps: [],
              tilesets: [],
              pokemon: ProjectPokemonConfig(
                  enabled: true,
                  ruleset: PokemonRulesetProfile.pokeMapBetaV1,
                  catalogFiles: {'items': 'items.json', 'moves': 'moves.json'}))
          .toJson(),
      'badges': [
        {'id': 'wing', 'label': 'Wing'},
        {'id': 'unused-badge', 'label': 'Unused'}
      ],
      'trainers': [
        const ProjectTrainerEntry(
                id: 'rival',
                name: 'Rival',
                trainerClass: 'Rival',
                team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)])
            .toJson()
      ],
      'facts': [
        NarrativeFactDefinition(id: 'world-enabled', label: 'World enabled')
            .toJson()
      ],
      'worldRules': [
        WorldRuleDefinition(
                id: 'weather',
                label: 'Weather',
                source: const WorldRuleSource(
                    kind: WorldRuleSourceKind.fact,
                    sourceId: 'world-enabled',
                    predicate: WorldRuleSourcePredicate.isTrue),
                target: const WorldRuleTarget(
                    kind: WorldRuleTargetKind.atmosphere, mapId: ''),
                effect:
                    const WorldRuleEffect(kind: WorldRuleEffectKind.atmosphere))
            .toJson()
      ],
    });
Map<String, Object?> _dependencyResources() => {
      'items.json': encodeProjectItemCatalog(const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
                id: 'fruit', displayName: 'Fruit', pocketId: 'materials')
          ])),
      'moves.json': {
        'schemaVersion': 1,
        'kind': 'pokemon_catalog',
        'catalog': 'moves',
        'entries': [
          {'id': 'tackle', 'name': 'Tackle'}
        ]
      },
    };
SceneInteractiveCommand _giftCommand({List<String>? moves}) =>
    SceneInteractiveCommand.fromJson({
      'kind': 'receivePokemonFromCatalog',
      'speciesId': 'bird',
      'formId': 'normal',
      'level': 5,
      'nicknamePolicy': 'offer',
      'nicknameMaxGraphemes': 12,
      'pokedexPresentationPolicy': 'whenNewAndPokedexVisible',
      if (moves != null) 'moveIds': moves
    });
SceneAsset _mixedScene(
    {SceneConditionSource? condition,
    List<SceneActionPayload> actions = const []}) {
  final targets = [
    for (var i = 0; i < actions.length; i++) 'extra-$i',
    'puzzle-node'
  ];
  return SceneAsset(
      id: 'puzzle',
      name: 'Mixed puzzle',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if (condition != null)
          SceneNode(
              id: 'check',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(conditionSource: condition)),
        for (final (index, payload) in actions.indexed)
          SceneNode(
              id: 'extra-$index', kind: SceneNodeKind.action, payload: payload),
        SceneNode(
            id: 'puzzle-node',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.fromJson(command()))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'enter',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: condition == null ? targets.first : 'check',
            kind: SceneEdgeKind.defaultFlow),
        if (condition != null)
          for (final port in ['true', 'false'])
            SceneEdge(
                id: 'check-$port',
                fromNodeId: 'check',
                fromPortId: port,
                toNodeId: targets.first,
                kind: port == 'true'
                    ? SceneEdgeKind.conditionTrue
                    : SceneEdgeKind.conditionFalse),
        for (final (index, payload) in actions.indexed)
          for (final port
              in payload.interactiveCommand?.outputPortIds ?? ['completed'])
            SceneEdge(
                id: 'extra-$index-$port',
                fromNodeId: 'extra-$index',
                fromPortId: port,
                toNodeId: targets[index + 1],
                kind: SceneEdgeKind.actionCompleted),
        for (final port in ['solved', 'quit'])
          SceneEdge(
              id: port,
              fromNodeId: 'puzzle-node',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted),
      ]));
}

const _originDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_origin_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _destinationDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.east,
  stationPlacedElementId: 'door_destination_east',
  vehiclePlacedElementId: 'door_vehicle_east',
);

const _dependencyJourney = RailJourneyDefinition(
  id: 'T1',
  label: 'Origin to destination',
  origin: RailJourneyEndpoint(
    stationMapId: 'map_origin_station',
    boardingArea: MapRect(
      pos: GridPos(x: 2, y: 3),
      size: GridSize(width: 3, height: 2),
    ),
    trainEntryPos: GridPos(x: 1, y: 4),
    stationArrivalPos: GridPos(x: 3, y: 6),
    doors: <RailJourneyEndpointDoor>[_originDoor],
  ),
  destination: RailJourneyEndpoint(
    stationMapId: 'map_destination_station',
    boardingArea: MapRect(
      pos: GridPos(x: 4, y: 2),
      size: GridSize(width: 2, height: 3),
    ),
    trainEntryPos: GridPos(x: 6, y: 4),
    stationArrivalPos: GridPos(x: 7, y: 6),
    doors: <RailJourneyEndpointDoor>[_destinationDoor],
  ),
  vehicleMapId: 'map_train_car',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
);

ProjectManifest _extraDependencyProject() => _dependencyProject().copyWith(
      storylines: [
        StorylineAsset(
            id: 'main',
            type: StorylineType.main,
            title: 'Main',
            chapters: [
              StorylineChapter(
                  id: 'chapter',
                  title: 'Chapter',
                  order: 0,
                  steps: [
                    StorylineStep(id: 'step-enter', title: 'Enter', order: 0)
                  ])
            ]),
        StorylineAsset(
            id: 'unused-story', type: StorylineType.sideQuest, title: 'Unused')
      ],
      railJourneyCatalog: RailJourneyCatalog(journeys: [
        _dependencyJourney,
        _dependencyJourney.copyWith(id: 'unused-journey')
      ]),
      newGame: const ProjectNewGameConfig(starterOptions: [
        ProjectStarterOption(
            id: 'starter',
            label: 'Starter',
            pokemon: PlayerPokemon(
                speciesId: 'bird', natureId: 'calm', abilityId: 'keen-eye')),
        ProjectStarterOption(
            id: 'unused-starter',
            label: 'Unused',
            pokemon: PlayerPokemon(
                speciesId: 'bird', natureId: 'calm', abilityId: 'keen-eye'))
      ]),
      cinematicMediaAssets: [
        CinematicMediaAsset(
            id: 'theme',
            label: 'Theme',
            kind: CinematicMediaAssetKind.music,
            relativePath: 'audio/theme.wav',
            loopByDefault: true),
        CinematicMediaAsset(
            id: 'door',
            label: 'Door',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'audio/door.wav'),
        CinematicMediaAsset(
            id: 'unused-audio',
            label: 'Unused',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'audio/unused.wav')
      ],
      maps: [
        for (final id in [
          'room',
          'map_origin_station',
          'map_destination_station',
          'map_train_car'
        ])
          ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json')
      ],
      tilesets: const [
        ProjectTilesetEntry(
            id: 'sheet', name: 'Sheet', relativePath: 'assets/actor.png')
      ],
      characters: [
        for (final id in [
          'actor-character',
          'second-character',
          'unused-character'
        ])
          ProjectCharacterEntry(
              id: id,
              name: id,
              tilesetId: 'sheet',
              animations: [
                for (final direction in EntityFacing.values)
                  CharacterAnimation(
                      state: CharacterAnimationState.idle,
                      direction: direction,
                      frames: const [
                        CharacterAnimationFrame(
                            source: TilesetSourceRect(x: 0, y: 0))
                      ])
              ])
      ],
    );
Map<String, Object?> _mapDependencyResources() => {
      for (final id in [
        'room',
        'map_origin_station',
        'map_destination_station',
        'map_train_car'
      ])
        'maps/$id.json': MapData(
            id: id,
            name: id,
            size: const GridSize(width: 16, height: 16),
            entities: [
              if (id == 'room')
                MapEntity(
                    id: 'actor',
                    kind: MapEntityKind.custom,
                    pos: const GridPos(x: 0, y: 0),
                    presentation: MapEntityPresentation(variants: [
                      for (final character in [
                        'actor-character',
                        'second-character'
                      ])
                        MapEntityPresentationVariant(
                            id: character,
                            condition:
                                NarrativeEventConditionExpression.all(const []),
                            characterId: character,
                            blocksMovement: true)
                    ]))
            ]).toJson(),
    };
