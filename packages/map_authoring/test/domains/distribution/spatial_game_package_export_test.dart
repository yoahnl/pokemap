import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-export-');
    final source = Directory(p.normalize(
        p.join(Directory.current.path, '..', '..', 'apps', 'hgss_first_map')));
    await for (final file in source.list(recursive: true, followLinks: false)) {
      final path = p.relative(file.path, from: source.path);
      if (file is! File || path.startsWith('.pokemap${p.separator}')) continue;
      final target = File(p.join(root.path, path));
      await target.parent.create(recursive: true);
      await file.copy(target.path);
    }
  });
  tearDown(() async => root.delete(recursive: true));

  test('animated decor requires a capable Player and preserves playback',
      () async {
    final manifestFile = File(p.join(root.path, 'project.json'));
    var manifest = ProjectManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>);
    final model = manifest.models3d.first;
    final bytes = Uint8List.fromList(animatedGlb());
    final source = File(p.join(root.path, 'animation-source.glb'));
    await source.writeAsBytes(bytes);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(root.path);
    final artifacts = LocalArtifactStore(
        allowedSourceRoots: [root.path], maximumArtifactBytes: 1048576);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, artifactStore: artifacts);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final artifactSource = await artifacts.importFile(source.path);
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'door-import',
            actionId: 'model3d.import',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'door-import',
            parameters: {
              'modelId': 'animated-door',
              'name': 'Door',
              'artifactHandle': artifactSource.reference.handle
            }));
    await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'door-import');
    manifest = (await snapshots.load(opened.projectHandle)).manifest;
    final mapFile = File(p.join(root.path, manifest.maps.first.relativePath));
    final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
    final original = map.spatialScene!.instances
        .firstWhere((instance) => instance.modelId == model.id);
    final animated = SpatialModelInstance(
        id: original.id,
        modelId: 'animated-door',
        position: original.position,
        animationIndex: 0,
        animationLoop: false,
        animationSpeed: .25);
    await mapFile.writeAsString(jsonEncode(map
        .copyWith(
            spatialScene: map.spatialScene!.copyWith(instances: [
          for (final instance in map.spatialScene!.instances)
            instance.id == animated.id ? animated : instance
        ]))
        .toJson()));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains('map3d.animation@1'));
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final exported = MapData.fromJson(jsonDecode(utf8.decode(archive
        .findFile('project/${manifest.maps.first.relativePath}')!
        .content)) as Map<String, dynamic>);
    expect(
        exported.spatialScene!.instances
            .firstWhere((instance) => instance.id == original.id),
        animated);
  });

  test('exports the authored 3D map as autonomous localTest exploration',
      () async {
    final manifestFile = File(p.join(root.path, 'project.json'));
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>);
    final atlas = ProjectSmartTileAtlas(
        id: 'cliff',
        name: 'Cliff',
        tilesetId: manifest.tilesets.first.id,
        columns: 4,
        rows: 4);
    await manifestFile.writeAsString(jsonEncode(manifest
        .copyWith(smartTileCatalog: ProjectSmartTileCatalog(atlases: [atlas]))
        .toJson()));
    final mapFile = File(p.join(root.path, manifest.maps.first.relativePath));
    final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
    const cliff = SmartTileFrameRef(atlasId: 'cliff', column: 2, row: 1);
    await mapFile.writeAsString(jsonEncode(map
        .copyWith(spatialScene: map.spatialScene!.copyWith(cliffFrame: cliff))
        .toJson()));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains('map3d@1'));
    expect(artifact.manifest.compatibility.requiredCapabilities,
        isNot(contains('map@1')));
    expect(artifact.manifest.compatibility.projectFormat, 'v9');
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final project = jsonDecode(
        utf8.decode(archive.findFile('project/project.json')!.content));
    final exportedMap = jsonDecode(utf8.decode(archive
        .findFile('project/${manifest.maps.first.relativePath}')!
        .content));
    expect(exportedMap['spatialScene']['cliffFrame'], cliff.toJson());
    expect(archive.findFile('project/${manifest.tilesets.first.relativePath}'),
        isNotNull);
    expect(project['newGame']['enabled'], false);
    expect(project['eventRegistry'], isNull);
    expect(project['dialogues'], isNotEmpty);
    for (final dialogue in project['dialogues']) {
      final compiled = archive.findFile('project/${dialogue['relativePath']}');
      expect(compiled, isNotNull);
      final document =
          const RuntimeDialogueDocumentCodec().decodeUtf8(compiled!.content);
      expect(
          document.nodes
              .expand((n) => n.steps)
              .every((step) => step is RuntimeDialogueLine),
          isTrue);
    }
    for (final model in project['models3d']) {
      expect(archive.findFile('project/${model['relativePath']}'), isNotNull);
    }
    expect(archive.findFile('project/assets/provenance/hgss.json'), isNull);
    await root.delete(recursive: true);
    root = await Directory.systemTemp.createTemp('spatial-export-clean-');
    final package = File(p.join(root.path, 'exploration.avelunegame'))
      ..writeAsBytesSync(artifact.packageBytes);
    final source = _FileSource(package.openSync());
    try {
      expect(
          const GamePackageInspector()
              .inspectSourceSync(source)
              .manifest
              .content
              .treeSha256,
          artifact.manifest.content.treeSha256);
    } finally {
      source.file.closeSync();
    }
    expect(artifact.certification.isCertified, false);
  });
  test('rejects 3D publication explicitly', () async {
    await expectLater(
        const CanonicalGamePackageExportService()
            .build(projectRoot: root, profile: _profile()),
        throwsA(isA<GamePackageExportException>().having(
            (e) => e.code, 'code', 'runtime3d.publication_unsupported')));
  });
}

GamePackageExportProfile _profile() => GamePackageExportProfile(
    gameId: 'games.example.spatial',
    gameVersion: '0.1.0',
    title: 'La halte des falaises',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);

final class _FileSource implements RandomAccessPackageSource {
  _FileSource(this.file);
  final RandomAccessFile file;
  @override
  int get length => file.lengthSync();
  @override
  Uint8List readAtSync(int offset, int length) {
    file.setPositionSync(offset);
    return file.readSync(length);
  }
}
