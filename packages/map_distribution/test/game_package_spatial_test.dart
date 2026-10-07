import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'support/glb_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  final validator =
      const GamePackageContentValidator(GamePackageSecurityPolicy());
  void validateGlb(List<int> bytes, {bool blob = false}) => validator.validate(
      GamePackageFileEntry(
          path: blob
              ? 'project/assets/.pokemap-store/${'a' * 64}.blob'
              : 'project/assets/model.glb',
          size: bytes.length,
          sha256: 'a' * 64,
          mediaType: 'model/gltf-binary'),
      Uint8List.fromList(bytes));
  test('accepts complete standalone GLB data and canonical GLB blobs', () {
    validateGlb(triangleGlb());
    validateGlb(texturedGlb(), blob: true);
  });
  test('rejects truncated, external and over-quota GLB texture content', () {
    for (final bytes in [
      triangleGlb().sublist(0, 28),
      triangleGlb(edit: (j) => j['buffers'][0]['uri'] = 'outside.bin'),
      texturedGlb(oversized: true)
    ]) {
      expect(
          () => validateGlb(bytes), throwsA(isA<GamePackageFormatException>()));
    }
    final strict = const GamePackageContentValidator(
        GamePackageSecurityPolicy(maxImagePixels: 0));
    final bytes = texturedGlb();
    expect(
        () => strict.validate(
            GamePackageFileEntry(
                path: 'project/assets/m.glb',
                size: bytes.length,
                sha256: 'a' * 64),
            Uint8List.fromList(bytes)),
        throwsA(isA<GamePackageFormatException>()));
  });
  test('inspects >1MiB logical GLB and GLB blobs in memory and through a file',
      () {
    final payload = spatialPayload(largeModel: true);
    final built = const GamePackageBuilder()
        .build(manifest: spatialManifest(), payloadFiles: payload);
    final memory = const GamePackageInspector().inspect(built.packageBytes);
    final file = File(
        '${Directory.systemTemp.path}/spatial-package-${DateTime.now().microsecondsSinceEpoch}.avelunegame')
      ..writeAsBytesSync(built.packageBytes);
    final source = _FileSource(file.openSync());
    try {
      final streamed = const GamePackageInspector().inspectSourceSync(source);
      expect(streamed.manifest.content.treeSha256,
          memory.manifest.content.treeSha256);
    } finally {
      source.file.closeSync();
      file.deleteSync();
    }
  });
  final changes =
      <String, void Function(Map<String, dynamic>, Map<String, List<int>>)>{
    'false model bounds': (p, _) =>
        p['models3d'][0]['inspection']['bounds']['max']['x'] = 99,
    'missing model': (p, _) => p['models3d'] = [],
    'missing hero image source': (p, _) =>
        p['characters'][0]['animations'][0]['sourceAssetId'] = 'absent',
    'frame outside image': (p, _) => p['characters'][0]['animations'][0]
        ['frames'][0]['source']['width'] = 33,
    'invalid duration': (p, _) =>
        p['characters'][0]['animations'][0]['frames'][0]['durationMs'] = 0,
    'new game': (p, _) => p['newGame']['enabled'] = true,
    'pokemon': (p, _) => p['pokemon']['enabled'] = true,
    'invalid artifact fingerprint': (_, files) {
      final json = jsonDecode(
          utf8.decode(files['project/assets/.pokemap-assets.json']!));
      json['records'][0]['artifact']['digest'] = 'sha256:${'a' * 64}';
      json['records'][0]['artifact']['handle'] =
          'artifact://sha256/${'a' * 64}';
      files['project/assets/.pokemap-assets.json'] =
          utf8.encode(jsonEncode(json));
    },
    'tampered blob': (_, files) {
      final key = files.keys.firstWhere(
          (key) => key.endsWith('.blob') && files[key]!.first == 0x89);
      files[key] = [...files[key]!]..[files[key]!.length - 1] ^= 1;
    },
    'missing model bytes': (_, files) =>
        files.remove('project/assets/models3d/model.glb'),
    'navigation missing': (_, files) {
      final json = jsonDecode(utf8.decode(files['project/maps/map.json']!));
      json['spatialScene'].remove('navigation');
      files['project/maps/map.json'] = utf8.encode(jsonEncode(json));
    },
    'animation index missing': (_, files) {
      final json = jsonDecode(utf8.decode(files['project/maps/map.json']!));
      json['spatialScene']['instances'][0]['animationIndex'] = 0;
      files['project/maps/map.json'] = utf8.encode(jsonEncode(json));
    },
    'npc': (_, files) {
      final json = jsonDecode(utf8.decode(files['project/maps/map.json']!));
      json['entities'] = [{}];
      files['project/maps/map.json'] = utf8.encode(jsonEncode(json));
    },
  };
  for (final entry in changes.entries) {
    test('rejects ${entry.key}', () {
      final files = spatialPayload();
      final project = jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>;
      entry.value(project, files);
      files['project/project.json'] = utf8.encode(jsonEncode(project));
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
  test('rejects a dimension/capability mismatch', () {
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(capabilities: ['map@1']),
            payloadFiles: spatialPayload()),
        throwsA(isA<GamePackageFormatException>()));
  });
  test('models3d participate in the project collection quota', () {
    final payload = spatialPayload();
    expect(
        () => const GamePackageProjectValidator(
                GamePackageSecurityPolicy(maxProjectCollectionEntries: 3))
            .validate(spatialManifest(),
                Uint8List.fromList(payload['project/project.json']!),
                payloadPaths: payload.keys.toSet(),
                readPayload: (path) => payload[path]),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'projectComplexityExceeded')));
  });
  test('unused provenance does not require a logical runtime payload', () {
    final files = spatialPayload();
    final catalogue =
        jsonDecode(utf8.decode(files['project/assets/.pokemap-assets.json']!));
    catalogue['records'].add({
      'id': 'unused',
      'logicalPath': 'assets/provenance/source.json',
      'artifact': {
        'digest': 'sha256:${'a' * 64}',
        'handle': 'artifact://sha256/${'a' * 64}',
        'mediaType': 'text/plain',
        'byteLength': 10
      },
      'usages': [],
      'tags': []
    });
    files['project/assets/.pokemap-assets.json'] =
        utf8.encode(jsonEncode(catalogue));
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    expect(
        () => const GamePackageSpatialProjectValidator()
            .validate(project, (path) => files[path]),
        returnsNormally);
  });
}

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
