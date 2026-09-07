import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
      version: ProjectVersion.v6,
      maps: [
        ProjectMapEntry(
            id: 'route', name: 'Route', relativePath: 'maps/route.json')
      ],
      tilesets: const [],
    );
    const map = MapData(
      id: 'route',
      name: 'Route',
      version: ProjectVersion.v6,
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
  Future<ProjectManifest> project() async => ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>);
  Future<void> dispose() => root.delete(recursive: true);
}
