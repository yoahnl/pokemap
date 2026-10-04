import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('usage snapshot excludes binaries without poisoning full snapshot cache',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('usage_projection_');
    addTearDown(() => directory.delete(recursive: true));
    final root = await directory.resolveSymbolicLinks();
    final png = [1, 2, 3];
    final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
    final asset = AssetRecord(
        id: 'icon',
        logicalPath: 'assets/pokemon/menu/icon.png',
        artifact: artifact);
    final project = const ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [],
        pokemon: ProjectPokemonConfig(
            enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    Future<void> write(String path, List<int> bytes) async {
      final file = File('$root/$path');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    await write('project.json', utf8.encode(jsonEncode(project.toJson())));
    await write(assetCatalogStorageKey,
        utf8.encode(jsonEncode(AssetCatalog(records: [asset]).toJson())));
    await write(asset.logicalPath, png);
    await write(assetBlobStorageKey(artifact), png);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(root);
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    final profiles = <ProjectSnapshotLoadProfile>[];
    final loader = ProjectSnapshotLoader(
        handles: handles,
        snapshotCache: ProjectSnapshotCache(),
        profileSink: profiles.add);
    final usage = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection);
    expect(
        usage.resourceFingerprints.keys
            .any((key) => key.startsWith('assetBlob:')),
        isFalse);
    expect(usage.resourceFingerprints.containsKey('asset:icon'), isFalse);
    expect(profiles.last.assetBlobVerifications, 0);
    final cached = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection);
    expect(cached.revision, usage.revision);
    expect(profiles.last.cacheHit, isTrue);
    final full = await loader.load(opened.projectHandle);
    expect(full.resourceFingerprints.containsKey('asset:icon'), isTrue);
    expect(
        full.resourceFingerprints
            .containsKey(assetBlobResourceIdentity(artifact.digest)),
        isTrue);
    expect(profiles.last.cacheHit, isFalse);
    expect(profiles.last.assetBlobVerifications, 1);
    final next = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection);
    expect(next.revision, usage.revision);
    expect(next.resourceFingerprints.containsKey('asset:icon'), isFalse);
    await File('$root/${assetBlobStorageKey(artifact)}').writeAsBytes([8, 9]);
    await expectLater(
        ProjectSnapshotLoader(handles: handles).load(opened.projectHandle),
        throwsA(isA<ProjectSnapshotException>()
            .having((e) => e.code, 'code', 'project.asset_blob_mismatch')));
  });
}
