import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  test('gameplay packages preserve typed facts and scenes through inspection',
      () {
    final files = _payload();
    final built = const GamePackageBuilder()
        .build(manifest: _manifest(), payloadFiles: files);
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    expect(inspected.manifest.compatibility.requiredCapabilities,
        contains('map3d.gameplay@1'));
  });

  test('exploration capability alone still rejects gameplay data', () {
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: _payload()),
        throwsA(isA<GamePackageFormatException>()));
  });

  test(
      'gameplay capability never grants 2D or substitutes the base 3D capability',
      () {
    for (final capabilities in [
      ['map3d.gameplay@1'],
      ['map@1', 'map3d.gameplay@1'],
      ['map@1', 'map3d@1', 'map3d.gameplay@1']
    ]) {
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: capabilities),
              payloadFiles: _payload()),
          throwsA(isA<GamePackageFormatException>()));
    }
  });

  test('an exploration-only host cannot accept the gameplay profile', () {
    final host = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.0.0'),
        runtimeApiVersion: Version.parse('1.0.0'),
        capabilities: {'map3d@1'},
        supportedProjectFormats: {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: {1});
    final result =
        const GamePackageCompatibilityEvaluator().evaluate(_manifest(), host);
    expect(result.decision, GamePackageCompatibilityDecision.reject);
    expect(result.missingCapabilities, ['map3d.gameplay@1']);
  });

  test('the profile accepts authored dialogue choices and outcomes', () {
    final files = _payload();
    final project = _project(files).copyWith(dialogues: [
      const ProjectDialogueEntry(
          id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.json')
    ]);
    final document = RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(title: 'Start', steps: [
        RuntimeDialogueChoiceBlock([
          RuntimeDialogueChoice(
              text: 'Yes',
              steps: [RuntimeDialogueLine('Accepted')],
              outcomeId: 'yes')
        ])
      ])
    ]);
    files['project/dialogues/talk.json'] =
        utf8.encode(jsonEncode(document.toJson()));
    _write(files, project);
    expect(
        () => const GamePackageBuilder()
            .build(manifest: _manifest(), payloadFiles: files),
        returnsNormally);
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>()));
  });

  test('unsupported scene semantics fail with a precise profile diagnostic',
      () {
    for (final payload in [
      SceneActionPayload(actionKind: 'legacy-script'),
      SceneActionPayload.interactive(SceneInteractiveCommand.moveNpc(
          mapId: 'map', entityId: 'npc', warpId: 'warp')),
      SceneCinematicPayload(cinematicId: 'movie'),
      SceneBattlePayload(battleKind: 'unknown'),
      SceneConditionPayload(
          conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.partyState,
              sourceId: 'party',
              operator: SceneConditionOperator.isTrue))
    ]) {
      final files = _payload();
      final original = _project(files);
      final scene = SceneAsset(
          id: 'unsupported',
          name: 'Unsupported',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'unsupported', kind: payload.kind, payload: payload)
          ], edges: []));
      final project = original.copyWith(scenes: [scene]);
      expect(
          () => const GamePackageSpatialProjectValidator(gameplay: true)
              .validate(project, (path) => files[path]),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'code',
              'runtime3d.gameplay_unsupported')));
    }
  });

  test('generic Event V2 custom objects retain canonical editor visuals', () {
    final files = _visualPayload();
    expect(
        () => const GamePackageBuilder()
            .build(manifest: _manifest(), payloadFiles: files),
        returnsNormally);
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>()));
  });

  test('gameplay signs require closed authored dialogues', () {
    for (final invalid in [null, 'plainText', 'script', 'missing', 'node']) {
      final files = _payload();
      _write(
          files,
          _project(files).copyWith(dialogues: [
            const ProjectDialogueEntry(
                id: 'sign-talk',
                name: 'Sign',
                relativePath: 'dialogues/sign.json')
          ]));
      files['project/dialogues/sign.json'] =
          utf8.encode(jsonEncode(RuntimeDialogueDocument(nodes: [
        RuntimeDialogueNode(
            title: 'Start', steps: [RuntimeDialogueLine('Read')])
      ]).toJson()));
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      files['project/maps/map.json'] =
          utf8.encode(jsonEncode(map.copyWith(entities: [
        MapEntity(
            id: 'sign',
            kind: MapEntityKind.sign,
            pos: const GridPos(x: 2, y: 2),
            blocksMovement: true,
            sign: MapEntitySignData(
                title: 'Welcome',
                plainText: invalid == 'plainText' ? 'Legacy' : '',
                dialogue: DialogueRef(
                    dialogueId: invalid == 'missing' ? 'missing' : 'sign-talk',
                    scriptPathRelative:
                        invalid == 'script' ? 'legacy.yarn' : '',
                    startNode: invalid == 'node' ? 'Missing' : 'Start')))
      ]).toJson()));
      GamePackageBuildResult build() => const GamePackageBuilder()
          .build(manifest: _manifest(), payloadFiles: files);
      expect(
          build,
          invalid == null
              ? returnsNormally
              : throwsA(isA<GamePackageFormatException>()),
          reason: '$invalid');
    }
  });

  test('arrival markers never substitute the default player start', () {
    for (final role in [EntitySpawnRole.other, EntitySpawnRole.npcSpawn]) {
      final files = _payload();
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      final marker = MapEntity(
          id: 'arrival',
          kind: MapEntityKind.spawn,
          pos: const GridPos(x: 2, y: 2),
          spawn: MapEntitySpawnData(role: role));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(
          map.copyWith(entities: [...map.entities, marker]).toJson()));
      GamePackageBuildResult build() => const GamePackageBuilder()
          .build(manifest: _manifest(), payloadFiles: files);
      expect(
          build,
          role == EntitySpawnRole.other
              ? returnsNormally
              : throwsA(isA<GamePackageFormatException>()));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(
          entities: [marker],
          mapMetadata: const MapMetadata(defaultSpawnId: 'arrival')).toJson()));
      expect(build, throwsA(isA<GamePackageFormatException>()));
    }
  });

  test(
      'custom visual frames and images remain closed and NPCs require characters',
      () {
    for (final invalid in ['frame', 'image', 'character']) {
      final files = _visualPayload();
      final project = _project(files);
      if (invalid == 'frame') {
        _write(
            files,
            project.copyWith(elementCategories: [
              const ProjectElementCategory(id: 'objects', name: 'Objects')
            ], elements: [
              project.elements.single.copyWith(frames: [
                const TilesetVisualFrame(
                    source: TilesetSourceRect(x: 2, y: 0, width: 1, height: 1))
              ])
            ]));
      } else if (invalid == 'image') {
        files.remove('project/assets/hero.png');
      } else {
        final map = MapData.fromJson(
            jsonDecode(utf8.decode(files['project/maps/map.json']!))
                as Map<String, dynamic>);
        files['project/maps/map.json'] =
            utf8.encode(jsonEncode(map.copyWith(entities: [
          map.entities.single.copyWith(
              kind: MapEntityKind.npc,
              npc: const MapEntityNpcData(characterId: 'missing'))
        ]).toJson()));
      }
      expect(
          () => const GamePackageBuilder()
              .build(manifest: _manifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()),
          reason: invalid);
    }
  });

  test('moving NPCs and automatic sight battles remain unsupported', () {
    for (final sight in [0, 2]) {
      final files = _payload();
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      files['project/maps/map.json'] =
          utf8.encode(jsonEncode(map.copyWith(entities: [
        MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(
                characterId: 'hero',
                lineOfSightRange: sight,
                movement: sight == 0
                    ? const MapEntityNpcMovementConfig(
                        mode: MapEntityNpcMovementMode.scriptedOnly)
                    : const MapEntityNpcMovementConfig()))
      ]).toJson()));
      expect(
          () => const GamePackageBuilder()
              .build(manifest: _manifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    }
  });
}

ProjectManifest _project(Map<String, List<int>> files) =>
    ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>);

void _write(Map<String, List<int>> files, ProjectManifest project) {
  files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
}

GamePackageManifest _manifest() =>
    spatialManifest(capabilities: ['map3d@1', 'map3d.gameplay@1']);

Map<String, List<int>> _payload() {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>);
  final scene = SceneAsset(
      id: 'quest',
      name: 'Quest',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'grant',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'quest.done', value: true))),
        SceneNode(id: 'end', kind: SceneNodeKind.end)
      ], edges: [
        SceneEdge(
            id: 'start-grant',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'grant',
            kind: SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'grant-end',
            fromNodeId: 'grant',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted)
      ]));
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
      facts: [NarrativeFactDefinition(id: 'quest.done', label: 'Quest done')],
      scenes: [scene]).toJson()));
  return files;
}

Map<String, List<int>> _visualPayload() {
  final files = _payload();
  final project = _project(files);
  _write(
      files,
      project.copyWith(
          elementCategories: [
            const ProjectElementCategory(id: 'objects', name: 'Objects')
          ],
          elements: [
            const ProjectElementEntry(
                id: 'object-image',
                name: 'Object image',
                tilesetId: 'hero-atlas',
                categoryId: 'objects',
                frames: [
                  TilesetVisualFrame(
                      source:
                          TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
                ])
          ],
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              legacyClaims: const [],
              records: [
                NarrativeEventRecord.configuredStructurallyUnchecked(
                    NarrativeEventDefinition(
                        id: 'evt_019dafe0-0000-7000-8000-000000000001',
                        name: 'Generic interaction',
                        source: NarrativeEventSourceRef.entityInteract(
                            'map', 'generic-object'),
                        sceneId: 'quest',
                        conditions: const [],
                        reusePolicy: NarrativeEventReusePolicy.reusable,
                        priority: 0,
                        order: 0,
                        resetPolicy: const NarrativeEventResetPolicy.never()),
                    enabled: true)
              ])));
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!))
          as Map<String, dynamic>);
  files['project/maps/map.json'] =
      utf8.encode(jsonEncode(map.copyWith(entities: [
    const MapEntity(
        id: 'generic-object',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
        editorVisual: MapEntityEditorVisual(elementId: 'object-image'))
  ]).toJson()));
  return files;
}
