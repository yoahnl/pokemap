import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../domains/maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../domains/maps/environment_spatial_actions_test.dart'
    show environmentModelGlb;
import 'glb_fixture.dart' show encodeGlb;
import 'resource_index_fixture.dart';

Future<ResourceIndexFixture> createModelReplacementFixture(Directory root,
    {bool placed = false, bool shared = false, bool mixed = false}) async {
  final base = spatialBorderAuthoringFixture(published: true);
  final tree = base.project.models3d.single;
  final other = ProjectModel3dEntry.fromJson({
    ...tree.toJson(),
    'id': 'alternate',
    'name': 'Alternate',
    if (!shared) 'sourceAssetId': 'alternate-source',
    'relativePath': 'assets/models3d/alternate.glb',
  });
  var project = base.project.copyWith(models3d: [tree, other]);
  if (mixed) {
    final json =
        jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>;
    final record = (json['borderCatalog']['records'] as List).single;
    for (final version in [record['draft'], record['latestPublished']]) {
      for (final piece in version['definition']['primitives'] as List) {
        if (piece['role'] == 'lineStraight') piece['sourceModelId'] = other.id;
      }
    }
    project = ProjectManifest.fromJson(json);
  }
  final map = placed
      ? applySpatialBorderFeaturePreview(base.map,
          manifest: project,
          proposedResult: resolveSpatialBorderFeature(
              manifest: project,
              map: base.map,
              layerId: 'border',
              featureId: 'fence'))
      : base.map.copyWith(layers: []);
  final bytes = environmentModelGlb();
  final digest =
      ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
  final assets = AssetCatalog(records: [
    for (final model in [tree, if (!shared) other])
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: digest)
  ]);
  final fixture =
      await ResourceIndexFixture.create(root: root, project: project, maps: [
    map
  ], files: {
    assetCatalogStorageKey: utf8.encode(jsonEncode(assets.toJson())),
    assetBlobStorageKey(digest): bytes,
    'candidate.glb': modelReplacementCandidateGlb(),
    for (final model in project.models3d) model.relativePath: bytes,
  });
  await fixture.prepare();
  return fixture;
}

List<int> modelReplacementCandidateGlb() {
  final bytes = Uint8List.fromList(environmentModelGlb());
  final jsonLength = ByteData.sublistView(bytes).getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  json['nodes'][0]['scale'] = [1.5, 1, 1];
  return encodeGlb(json, bytes.sublist(28 + jsonLength));
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Provide one new project directory.');
  }
  final directory = Directory(arguments.single);
  if (await directory.exists()) throw StateError('The fixture already exists.');
  final fixture = await createModelReplacementFixture(directory, placed: true);
  await fixture.close();
}
