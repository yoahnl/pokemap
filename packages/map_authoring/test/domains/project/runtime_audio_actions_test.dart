import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('map audio gain is discoverable with bounded nullable input', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final worker = JsonlWorker(api: h.readApi, mutations: h.mutations);
    final result = jsonDecode(await worker.processLine(
            jsonEncode({'id': 'describe', 'command': 'describe', 'args': {}})))
        as Map<String, dynamic>;
    final actions = (result['data'] as Map)['mutationActions'] as List;
    final descriptor = actions
        .cast<Map>()
        .singleWhere((entry) => entry['id'] == 'map.audio.update');
    final extensions = descriptor['extensions'] as Map;
    expect(extensions['parameterNames'], contains('musicVolume'));
    final schema = extensions['inputSchema'] as Map;
    final volume = (schema['properties'] as Map)['musicVolume'] as Map;
    expect(volume['type'], ['number', 'null']);
    expect(volume['minimum'], 0);
    expect(volume['maximum'], 1);
    expect(extensions['omittedFields'], 'preserved');
  });

  test('direct API preserves omitted gain and clears only explicit null',
      () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final before = await h.map();
    await h
        .update('map.audio.update', {'mapId': 'route', 'musicVolume': 0.375});
    expect((await h.map()).mapMetadata.toJson()['musicVolume'], 0.375);
    await h.update('map.audio.update',
        {'mapId': 'route', 'musicPath': 'assets/music/route.ogg'});
    final gained = await h.map();
    expect(gained.mapMetadata.toJson()['musicVolume'], 0.375);
    expect(gained.copyWith(mapMetadata: before.mapMetadata), before);
    await h.update('map.audio.update', {'mapId': 'route', 'musicVolume': null});
    final cleared = await h.map();
    expect(cleared.mapMetadata.toJson()['musicVolume'], isNull);
    expect(cleared.mapMetadata.musicPath, 'assets/music/route.ogg');
  });

  test('JSONL plans and applies exact zero and full gain with strict reload',
      () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    for (final volume in [0, 1]) {
      await h.updateJsonl({'mapId': 'route', 'musicVolume': volume});
      expect((await h.map()).mapMetadata.toJson()['musicVolume'],
          volume.toDouble());
    }
    await h.updateJsonl({'mapId': 'route', 'musicVolume': null});
    expect((await h.map()).mapMetadata.toJson()['musicVolume'], isNull);
  });

  for (final value in [
    -0.01,
    1.01,
    double.nan,
    double.infinity,
    '0.8',
    true,
    ''
  ]) {
    test('rejects invalid map gain $value without modifying project bytes',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await File('${h.root.path}/maps/route.json').readAsBytes();
      await expectLater(
          h.update(
              'map.audio.update', {'mapId': 'route', 'musicVolume': value}),
          throwsA(anything));
      expect(
          await File('${h.root.path}/maps/route.json').readAsBytes(), before);
    });
  }

  test('project battle audio rejects a map-only music gain', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final before = await h.project();
    await expectLater(
        h.update('project.battle_audio.update', {'musicVolume': 0.8}),
        throwsA(anything));
    expect(await h.project(), before);
  });

  test('map audio changes preserve all other authored map data', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final before = await h.map();
    await h.update('map.audio.update', {
      'mapId': 'route',
      'musicPath': 'assets/music/route.ogg',
    });
    final after = await h.map();
    expect(after.mapMetadata.musicPath, 'assets/music/route.ogg');
    expect(after.copyWith(mapMetadata: before.mapMetadata), before);
    expect(after.mapMetadata.copyWith(musicPath: null), before.mapMetadata);
  });

  test('battle defaults support partial changes and explicit clearing',
      () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    await h.update('project.battle_audio.update', {
      'wildBattleMusicPath': 'assets/music/route.ogg',
      'trainerBattleMusicPath': 'assets/music/route.ogg',
    });
    await h.update('project.battle_audio.update', {
      'wildVictoryMusicPath': 'assets/music/route.ogg',
    });
    expect((await h.project()).battleAudio?.trainerBattleMusicPath,
        'assets/music/route.ogg');
    await h.update('project.battle_audio.update', {
      'wildBattleMusicPath': null,
      'trainerBattleMusicPath': '',
      'wildVictoryMusicPath': null,
    });
    expect((await h.project()).battleAudio, isNull);
  });

  for (final path in [
    '/Users/author/music.ogg',
    '../outside.ogg',
    'assets/music/missing.ogg',
    'assets/music/image.png',
  ]) {
    test('rejects invalid audio reference $path without changing files',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.project();
      await expectLater(
        h.update('project.battle_audio.update', {'wildBattleMusicPath': path}),
        throwsA(anything),
      );
      expect(await h.project(), before);
    });
  }
}

final class _Harness {
  _Harness(this.root, this.readApi, this.mutations, this.snapshots);

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  var sequence = 0;

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('runtime-audio-');
    await Directory('${root.path}/maps').create();
    await Directory('${root.path}/assets/music').create(recursive: true);
    final manifest = ProjectManifest(
      name: 'Audio fixture',
      version: ProjectVersion.v8,
      maps: [
        ProjectMapEntry(
            id: 'route', name: 'Route', relativePath: 'maps/route.json')
      ],
      tilesets: const [],
    );
    const map = MapData(
      id: 'route',
      name: 'Route',
      version: ProjectVersion.v8,
      size: GridSize(width: 2, height: 2),
      layers: [],
      mapMetadata: MapMetadata(displayName: 'Route', tags: ['outdoor']),
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    await File('${root.path}/maps/route.json')
        .writeAsString(jsonEncode(map.toJson()));
    final records = <AssetRecord>[];
    for (final entry
        in {'route.ogg': 'audio/ogg', 'image.png': 'image/png'}.entries) {
      final bytes = utf8.encode(entry.key);
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: entry.value);
      records.add(AssetRecord(
          id: entry.key,
          logicalPath: 'assets/music/${entry.key}',
          artifact: artifact));
      await File('${root.path}/assets/music/${entry.key}').writeAsBytes(bytes);
      final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
    }
    await File('${root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: records).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    return _Harness(
        root,
        AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy, fileReader: reader, handles: handles),
            snapshotLoader: snapshots),
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots),
        snapshots);
  }

  Future<void> update(String actionId, Map<String, Object?> parameters) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final snapshot = await snapshots.load(opened.projectHandle);
    final id = 'audio-${sequence++}';
    final plan = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
            requestId: id,
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            dryRun: false));
    await mutations.apply(opened.projectHandle,
        planId: plan['planId']! as String, operationId: id);
  }

  Future<MapData> map() async => MapData.fromJson(
      jsonDecode(await File('${root.path}/maps/route.json').readAsString())
          as Map<String, dynamic>);
  Future<void> updateJsonl(Map<String, Object?> parameters) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final snapshot = await snapshots.load(opened.projectHandle);
    final id = 'audio-jsonl-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: 'map.audio.update',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: id,
        dryRun: false);
    final worker = JsonlWorker(api: readApi, mutations: mutations);
    Future<AuthoringResult> command(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                jsonEncode({'id': command, 'command': command, 'args': args})))
            as Map<String, dynamic>);
    final before = await File('${root.path}/maps/route.json').readAsBytes();
    final planned = await command('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(planned.status, AuthoringResultStatus.success);
    expect(await File('${root.path}/maps/route.json').readAsBytes(), before);
    final applied = await command('apply', {
      'projectHandle': opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': id
    });
    expect(applied.status, AuthoringResultStatus.success);
    final reloaded = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(reloaded.loadDiagnostics, isEmpty);
    expect(
        reloaded.maps
            .singleWhere((map) => map.id == 'route')
            .mapMetadata
            .toJson()['musicVolume'],
        parameters['musicVolume']);
  }

  Future<ProjectManifest> project() async => ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>);
  Future<void> dispose() => root.delete(recursive: true);
}
