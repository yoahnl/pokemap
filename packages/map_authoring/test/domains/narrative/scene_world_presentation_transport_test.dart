import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneAsset _scene(String id, SceneInteractiveCommand command) => SceneAsset(
    id: id,
    name: id,
    metadata: const {'keep': 'metadata'},
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'action',
          kind: SceneNodeKind.action,
          title: 'Keep title',
          description: 'Keep description',
          payload: SceneActionPayload.interactive(command,
              actionKind: 'keep-action',
              parameters: const {'keep': 'parameter'})),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'action',
          kind: SceneEdgeKind.defaultFlow),
      for (final port in command.outputPortIds)
        SceneEdge(
            id: port,
            fromNodeId: 'action',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
    ]));

void main() {
  test('canonical actions describe independent bounded world waits', () {
    for (final id in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      final descriptor = SceneActions.descriptors.singleWhere((d) => d.id == id);
      final wait = descriptor.extensions['wait'] as Map;
      expect(wait['parameters'], ['durationMs']);
      expect(wait['durationMsRange'], [0, 2147483647]);
      expect(wait['durationUnit'], 'milliseconds');
      expect(wait['completion'], 'elapsed');
      expect(wait['outputPorts'], ['completed']);
      expect(wait['actorReference'], 'none');
      expect(wait['projectDimension'], 'twoD');
    }
  });

  test('canonical action describes bounded presentation data', () {
    for (final id in ['scene.interactive_command.set', 'scene.upsert']) {
      final descriptor =
          SceneActions.descriptors.singleWhere((value) => value.id == id);
      expect(descriptor.extensions['worldTone'], isA<Map>());
      expect(descriptor.extensions['playSoundEffect'], isA<Map>());
      final tone = descriptor.extensions['worldTone'] as Map;
      final sound = descriptor.extensions['playSoundEffect'] as Map;
      expect(
          tone['parameters'], ['red', 'green', 'blue', 'gray', 'durationMs']);
      expect(tone['rgbRange'], [-255, 255]);
      expect(tone['grayRange'], [0, 255]);
      expect(tone['projectDimension'], 'twoD');
      expect(sound['projectDimension'], 'twoD');
      expect(tone['durationMsRange'], [0, 2147483647]);
      expect(tone['completion'], 'scheduled');
      expect(sound['mediaReference'], 'knownNonLoopingSound');
      expect(sound['volumeRange'], [0, 1]);
      expect(sound['completion'], 'started');
      expect(sound['unsupportedParameters'], ['pitch']);
    }
  });

  test('canonical scene upsert and graph patch cannot bypass sound validation',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final invalid = _scene(
        'edit',
        SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'missing', volume: 0.8));
    for (final action in ['scene.upsert', 'scene.graph.patch']) {
      final before = await fixture.projectFile.readAsBytes();
      final id = 'bypass-${++fixture.sequence}';
      final request = AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: fixture.workspace.value,
          expectedRevision: (await fixture.snapshot()).revision,
          idempotencyKey: id,
          parameters: action == 'scene.upsert'
              ? {'scene': invalid.toJson()}
              : {
                  'sceneId': 'edit',
                  'upsertNodes': [invalid.graph.nodes[1].toJson()]
                });
      final result = await fixture.command('plan', {
        'projectHandle': fixture.project.value,
        'request': request.toJson()
      });
      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error!.details['domainCode'], 'scene.publication_blocked');
      expect(await fixture.projectFile.readAsBytes(), before);
    }
  });

  for (final jsonl in [false, true]) {
    test('${jsonl ? 'JSONL' : 'direct API'} rejects 3D presentation on every semantic entrypoint before writes', () async {
      for (final command in [
        SceneInteractiveCommand.wait(durationMs: 400),
        SceneInteractiveCommand.worldTone(red: -255, green: 0, blue: 0, gray: 0, durationMs: 300),
        SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: .8),
      ]) {
      final initial = switch (command) {
        SceneWaitInteractiveCommand() => SceneInteractiveCommand.wait(durationMs: 1),
        SceneWorldToneInteractiveCommand() => SceneInteractiveCommand.worldTone(
          red: 0, green: 0, blue: 0, gray: 0, durationMs: 1),
        _ => SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: 1),
      };
      final f = await _Fixture.create(spatial: true, initialCommand: initial);
      addTearDown(f.dispose);
      final before = await f.projectFile.readAsBytes();
      final mapBefore = await f.mapFile.readAsBytes();
      final scene = _scene('edit', command);
      for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
        final id = '3d-${++f.sequence}';
        final request = AuthoringRequest(requestId: id, actionId: action, actionVersion: 1,
          workspaceHandle: f.workspace.value, expectedRevision: (await f.snapshot()).revision,
          idempotencyKey: id, parameters: switch (action) {
            'scene.upsert' => {'scene': scene.toJson()},
            'scene.graph.patch' => {'sceneId': 'edit', 'upsertNodes': [scene.graph.nodes[1].toJson()]},
            _ => {'sceneId': 'edit', 'nodeId': 'action', 'command': command.toJson()},
          });
        if (jsonl) {
          final result = await f.command('plan', {'projectHandle': f.project.value,
            'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure, reason: action);
          expect(jsonEncode(result.error!.details), contains('commandUnsupportedDimension'));
        } else {
          await expectLater(f.mutations.plan(f.project, request),
            throwsA(isA<NarrativeAuthoringException>().having((e) => e.code,
              'code', 'scene.publication_blocked')), reason: action);
        }
        expect(await f.projectFile.readAsBytes(), before);
        expect(await f.mapFile.readAsBytes(), mapBefore);
      }
      }
    });

    test('${jsonl ? 'JSONL' : 'direct API'} world wait persists without an actor and reopens', () async {
      final fixture = await _Fixture.create(initialCommand: SceneInteractiveCommand.wait(durationMs: 1));
      addTearDown(fixture.dispose);
      final mapBefore = await fixture.mapFile.readAsBytes();
      final draft = (await fixture.snapshot()).manifest.scenes
          .singleWhere((s) => s.id == 'unrelated-draft');
      for (final duration in [0, 400, 2147483647]) {
        final command = SceneInteractiveCommand.wait(durationMs: duration);
        final request = await fixture.request(command.toJson());
        final before = await fixture.projectFile.readAsBytes();
        final planned = jsonl
            ? await fixture.success('plan', {'projectHandle': fixture.project.value,
                'request': request.toJson()})
            : await fixture.mutations.plan(fixture.project, request);
        expect(await fixture.projectFile.readAsBytes(), before);
        if (jsonl) {
          await fixture.success('apply', {'projectHandle': fixture.project.value,
              'planId': planned['planId'], 'operationId': '${request.requestId}-apply'});
        } else {
          await fixture.mutations.apply(fixture.project, planId: planned['planId']! as String,
              operationId: '${request.requestId}-apply');
        }
        final scene = (await fixture.snapshot()).manifest.scenes.singleWhere((s) => s.id == 'edit');
        final node = scene.graph.nodes.singleWhere((n) => n.id == 'action');
        final payload = node.payload as SceneActionPayload;
        expect(payload.interactiveCommand, command);
        expect(payload.parameters, {'keep': 'parameter'});
        expect(payload.actionKind, 'keep-action');
        expect(node.title, 'Keep title');
        expect(scene.graph.edges.where((e) => e.fromNodeId == 'action')
            .map((e) => e.fromPortId), ['completed']);
        expect(await fixture.mapFile.readAsBytes(), mapBefore);
      }
      for (final duration in <Object?>[null, -1, 0.5, 2147483648, '400']) {
        final before = await fixture.projectFile.readAsBytes();
        final request = await fixture.request({'kind': 'wait', 'durationMs': duration});
        final result = await fixture.command('plan', {'projectHandle': fixture.project.value,
            'request': request.toJson()});
        expect(result.status, AuthoringResultStatus.failure);
        expect(await fixture.projectFile.readAsBytes(), before);
      }
      final stable = await fixture.projectFile.readAsBytes();
      await fixture.success('close', {'workspaceHandle': fixture.workspace.value});
      await fixture.open();
      expect(await fixture.projectFile.readAsBytes(), stable);
      final snapshot = await fixture.snapshot();
      expect(snapshot.manifest.scenes.singleWhere((s) => s.id == 'unrelated-draft'), draft);
      final command = (snapshot.manifest.scenes.singleWhere((s) => s.id == 'edit')
          .graph.nodes.singleWhere((n) => n.id == 'action').payload as SceneActionPayload)
          .interactiveCommand;
      expect(command, SceneInteractiveCommand.wait(durationMs: 2147483647));
    });

    final transport = jsonl ? 'JSONL' : 'direct API';
    test('$transport retains world tone and sound, scope, refs and cold reopen',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final draftBefore = (await fixture.snapshot())
          .manifest
          .scenes
          .singleWhere((scene) => scene.id == 'unrelated-draft');
      final mapBefore = await fixture.mapFile.readAsBytes();
      for (final command in [
        SceneInteractiveCommand.worldTone(
            red: -255, green: -254.5, blue: 20, gray: 10, durationMs: 300),
        SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'door', volume: 0.8),
      ]) {
        final before = await fixture.projectFile.readAsBytes();
        final request = await fixture.request(command.toJson());
        final planned = jsonl
            ? await fixture.success('plan', {
                'projectHandle': fixture.project.value,
                'request': request.toJson()
              })
            : await fixture.mutations.plan(fixture.project, request);
        expect(await fixture.projectFile.readAsBytes(), before);
        expect(await fixture.mapFile.readAsBytes(), mapBefore);
        if (jsonl) {
          await fixture.success('apply', {
            'projectHandle': fixture.project.value,
            'planId': planned['planId'],
            'operationId': '${request.requestId}-apply'
          });
        } else {
          await fixture.mutations.apply(fixture.project,
              planId: planned['planId']! as String,
              operationId: '${request.requestId}-apply');
        }
        final after = await fixture.snapshot();
        final updated =
            after.manifest.scenes.singleWhere((scene) => scene.id == 'edit');
        final node =
            updated.graph.nodes.singleWhere((node) => node.id == 'action');
        final payload = node.payload as SceneActionPayload;
        expect(payload.interactiveCommand, command);
        expect(payload.actionKind, 'keep-action');
        expect(payload.parameters, {'keep': 'parameter'});
        expect(node.title, 'Keep title');
        expect(node.description, 'Keep description');
        expect(updated.metadata, {'keep': 'metadata'});
        expect(
            after.manifest.scenes
                .singleWhere((scene) => scene.id == 'unrelated-draft'),
            draftBefore);
        expect(await fixture.mapFile.readAsBytes(), mapBefore);
      }
      final snapshot = await fixture.snapshot();
      final references = ProjectReferenceIndex.fromSnapshot(snapshot);
      final edge = references.edges.singleWhere(
          (edge) => edge.owner.id == 'edit' && edge.target.kind == 'media');
      expect(edge.target.id, 'door');
      expect(edge.resolution, NarrativeDependencyResolution.resolved);
      expect(
          references.diagnostics
              .any((diagnostic) => diagnostic.target.id == 'missing'),
          isTrue);
      final stable = await fixture.projectFile.readAsBytes();
      await fixture
          .success('close', {'workspaceHandle': fixture.workspace.value});
      await fixture.open();
      expect((await fixture.snapshot()).revision, snapshot.revision);
      expect(await fixture.projectFile.readAsBytes(), stable);
      final query = await fixture.success('query', {
        'projectHandle': fixture.project.value,
        'request': AuthoringQueryRequest(
            resourceKind: 'scene',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['edit']).toJson()
      });
      expect(jsonEncode(query), contains('playSoundEffect'));
      expect(jsonEncode(query), contains('door'));
    });

    test(
        '$transport rejects missing wrong-kind and looping sound before writes',
        () async {
      for (final mediaId in ['missing', 'music', 'fx', 'loop']) {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        final before = await fixture.projectFile.readAsBytes();
        final request = await fixture.request(
            SceneInteractiveCommand.playSoundEffect(
                    mediaAssetId: mediaId, volume: 0.8)
                .toJson());
        if (jsonl) {
          final result = await fixture.command('plan', {
            'projectHandle': fixture.project.value,
            'request': request.toJson()
          });
          expect(result.status, AuthoringResultStatus.failure, reason: mediaId);
          expect(
              result.error!.details['domainCode'], 'scene.publication_blocked');
        } else {
          await expectLater(
              fixture.mutations.plan(fixture.project, request),
              throwsA(isA<NarrativeAuthoringException>().having(
                  (error) => error.code, 'code', 'scene.publication_blocked')),
              reason: mediaId);
        }
        expect(await fixture.projectFile.readAsBytes(), before);
      }
    });

    test('$transport rejects invalid numeric payloads and unrepresented pitch',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      for (final value in [
        {
          ...SceneInteractiveCommand.playSoundEffect(
                  mediaAssetId: 'door', volume: 0.8)
              .toJson(),
          'volume': 1.01
        },
        {
          ...SceneInteractiveCommand.playSoundEffect(
                  mediaAssetId: 'door', volume: 0.8)
              .toJson(),
          'pitch': 100
        },
        {
          ...SceneInteractiveCommand.worldTone(
                  red: 0, green: 0, blue: 0, gray: 0, durationMs: 0)
              .toJson(),
          'durationMs': 300.0
        },
        {
          ...SceneInteractiveCommand.worldTone(
                  red: 0, green: 0, blue: 0, gray: 0, durationMs: 0)
              .toJson(),
          'red': 'NaN'
        },
      ]) {
        final before = await fixture.projectFile.readAsBytes();
        final request = await fixture.request(value);
        if (jsonl) {
          final result = await fixture.command('plan', {
            'projectHandle': fixture.project.value,
            'request': request.toJson()
          });
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.details['domainCode'],
              'scene.graph.payload_invalid');
        } else {
          await expectLater(
              fixture.mutations.plan(fixture.project, request),
              throwsA(isA<NarrativeAuthoringException>().having(
                  (error) => error.code,
                  'code',
                  'scene.graph.payload_invalid')));
        }
        expect(await fixture.projectFile.readAsBytes(), before);
      }
    });
  }
}

final class _Fixture {
  _Fixture(
      this.directory, this.api, this.snapshots, this.mutations, this.worker);
  final Directory directory;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get projectFile => File('${directory.path}/project.json');
  File get mapFile => File('${directory.path}/maps/map.json');

  static Future<_Fixture> create({SceneInteractiveCommand? initialCommand, bool spatial = false}) async {
    final directory =
        await Directory.systemTemp.createTemp('world-presentation-transport-');
    final map = MapData(
        version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [],
        warps: const [
          MapWarp(
              id: 'arrival',
              pos: GridPos(x: 1, y: 1),
              targetMapId: 'map',
              targetPos: GridPos(x: 1, y: 1),
              triggerMode: MapWarpTriggerMode.onBump)
        ]);
    final manifest =
        ProjectManifest(version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
        name: 'QA', maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
    ], tilesets: const [], scenes: [
      _scene(
          'edit',
          initialCommand ?? SceneInteractiveCommand.warp(
              destinationMapId: 'map', warpId: 'arrival')),
      _scene(
          'unrelated-draft',
          SceneInteractiveCommand.playSoundEffect(
              mediaAssetId: 'missing', volume: 0.8)),
    ], cinematicMediaAssets: [
      for (final id in ['door', 'loop', 'music', 'fx'])
        CinematicMediaAsset(
            id: id,
            label: id,
            kind: id == 'music'
                ? CinematicMediaAssetKind.music
                : id == 'fx'
                    ? CinematicMediaAssetKind.cinematicFx
                    : CinematicMediaAssetKind.sound,
            relativePath: 'audio/$id.wav',
            loopByDefault: id == 'loop'),
    ]);
    await Directory('${directory.path}/maps').create();
    await Directory('${directory.path}/audio').create();
    await File('${directory.path}/maps/map.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final wav = Uint8List(46);
    final data = ByteData.sublistView(wav);
    wav.setRange(0, 4, utf8.encode('RIFF'));
    data.setUint32(4, 38, Endian.little);
    wav.setRange(8, 16, utf8.encode('WAVEfmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 8000, Endian.little);
    data.setUint32(28, 16000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, utf8.encode('data'));
    data.setUint32(40, 2, Endian.little);
    for (final id in ['door', 'loop', 'music', 'fx']) {
      await File('${directory.path}/audio/$id.wav').writeAsBytes(wav);
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final fixture = _Fixture(
        directory,
        api,
        snapshots,
        mutations,
        JsonlWorker(
            api: api,
            mutations: mutations,
            commandTimeout: const Duration(seconds: 60)));
    await fixture.open();
    return fixture;
  }

  Future<AuthoringResult> command(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'command-${++sequence}',
        'command': command,
        'args': args
      }))) as Map<String, dynamic>);
  Future<Map<String, Object?>> success(
      String name, Map<String, Object?> args) async {
    final result = await command(name, args);
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<void> open() async {
    final result = await success('open', {'projectRoot': directory.path});
    workspace = WorkspaceHandle(result['workspaceHandle']! as String);
    project = ProjectHandle(result['projectHandle']! as String);
  }

  Future<ProjectSnapshot> snapshot() => snapshots.load(project);
  Future<AuthoringRequest> request(Map<String, Object?> command) async =>
      AuthoringRequest(
          requestId: 'edit-${++sequence}',
          actionId: 'scene.interactive_command.set',
          actionVersion: 1,
          workspaceHandle: workspace.value,
          expectedRevision: (await snapshot()).revision,
          idempotencyKey: 'edit-$sequence',
          parameters: {
            'sceneId': 'edit',
            'nodeId': 'action',
            'command': command
          });
  Future<void> dispose() async {
    await success('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}
