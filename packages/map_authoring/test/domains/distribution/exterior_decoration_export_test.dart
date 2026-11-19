import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/exterior_decoration_fixture.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  Future<(Directory, Map<String, List<int>>)> fixture(
      {bool decorated = true, bool withBorder = false}) async {
    final root =
        await Directory.systemTemp.createTemp('exterior-decoration-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = decorated
        ? exteriorDecorationPayload(withBorder: withBorder)
        : spatialPayload();
    if (decorated) {
      const path = 'project/maps/map.json';
      final map = MapData.fromJson(jsonDecode(utf8.decode(files[path]!)));
      files[path] = utf8.encode(jsonEncode(map
          .copyWith(spatialScene: map.spatialScene!.copyWith(instances: []))
          .toJson()));
    }
    if (withBorder) {
      const path = 'project/maps/map.decoration.json';
      const sectorPath = 'maps/map.decoration/west.json';
      final index =
          jsonDecode(utf8.decode(files[path]!)) as Map<String, dynamic>;
      final sector = jsonDecode(utf8.decode(files['project/$sectorPath']!));
      sector['scene']['instances'] = [];
      final bytes = utf8.encode(jsonEncode(sector));
      files['project/$sectorPath'] = bytes;
      index['sectors'].single
        ..['instances'] = 0
        ..['resourceIds'] = []
        ..['revision'] = computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
              relativePath: sectorPath, bytes: bytes)
        ]);
      files[path] = utf8.encode(jsonEncode(index));
    }
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key.substring(8)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    return (root, files);
  }

  Future<GamePackageExportArtifact> export(Directory root) =>
      const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.exterior',
              gameVersion: '0.1.0',
              title: 'Exterior',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr']),
          mode: GamePackageExportMode.localTest);

  test(
      'exports a model used only in an exterior sector without changing authored bytes',
      () async {
    final (root, files) = await fixture();
    final artifact = await export(root);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains(MapExteriorDecoration.capabilityId));
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    for (final path in [
      'project/maps/map.decoration.json',
      'project/maps/map.decoration/west.json',
      'project/assets/models3d/model.glb'
    ]) {
      expect(archive.findFile(path)?.content, files[path]);
    }
    for (final entry in files.entries) {
      expect(await File('${root.path}/${entry.key.substring(8)}').readAsBytes(),
          entry.value);
    }
  });

  test('exports a materialized exterior Border with its exclusive model',
      () async {
    final (root, files) = await fixture(withBorder: true);
    final artifact = await export(root);
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    expect(archive.findFile('project/assets/models3d/model.glb')?.content,
        files['project/assets/models3d/model.glb']);
    expect(
        archive
            .findFile('project/maps/map.decoration/borders/fence.json')
            ?.content,
        files['project/maps/map.decoration/borders/fence.json']);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains(MapExteriorDecoration.capabilityId));
  });

  test('absent document leaves old export capability unchanged', () async {
    final (root, _) = await fixture(decorated: false);
    final artifact = await export(root);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        isNot(contains(MapExteriorDecoration.capabilityId)));
  });

  test('legacy declared map filename is not mistaken for decoration', () async {
    final (root, _) = await fixture(decorated: false);
    final source = File('${root.path}/project.json');
    final project =
        jsonDecode(await source.readAsString()) as Map<String, dynamic>;
    (project['maps'] as List).single['relativePath'] =
        'maps/map.decoration.json';
    await source.writeAsString(jsonEncode(project));
    await File('${root.path}/maps/map.json')
        .rename('${root.path}/maps/map.decoration.json');
    final artifact = await export(root);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        isNot(contains(MapExteriorDecoration.capabilityId)));
  });

  test('missing required sector fails export and preserves definition',
      () async {
    final (root, files) = await fixture();
    await File('${root.path}/maps/map.decoration/west.json').delete();
    expect(() => export(root), throwsA(isA<GamePackageExportException>()));
    expect(await File('${root.path}/maps/map.decoration.json').readAsBytes(),
        files['project/maps/map.decoration.json']);
  });

  test('malformed definition fails export without overwriting it', () async {
    final (root, _) = await fixture();
    final invalid = utf8.encode('{"schemaVersion":99}');
    await File('${root.path}/maps/map.decoration.json').writeAsBytes(invalid);
    expect(() => export(root), throwsA(isA<GamePackageExportException>()));
    expect(await File('${root.path}/maps/map.decoration.json').readAsBytes(),
        invalid);
  });

  test('orphan exterior sector fails export without discarding it', () async {
    final (root, files) = await fixture();
    await File('${root.path}/maps/map.decoration.json').delete();
    await expectLater(
        () => export(root), throwsA(isA<GamePackageExportException>()));
    expect(
        await File('${root.path}/maps/map.decoration/west.json').readAsBytes(),
        files['project/maps/map.decoration/west.json']);
  });
}
