import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/exterior_decoration_fixture.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  final qaRoot = Directory(
      '/Users/karim/Library/Caches/AveluneQA/exterior-decoration-export');
  setUpAll(() => qaRoot.create(recursive: true));
  tearDownAll(() async {
    if (await qaRoot.exists() && await qaRoot.list().isEmpty) {
      await qaRoot.delete();
    }
  });

  Future<(Directory, Map<String, List<int>>)> fixture(
      {bool decorated = true, bool withBorder = false}) async {
    final root = await qaRoot.createTemp('case-');
    addTearDown(() => root.delete(recursive: true));
    final files = decorated
        ? exteriorDecorationPayload(withBorder: withBorder)
        : spatialPayload();
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
      'exports exterior sidecars and all models without changing authored bytes',
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

  test('exports one whole materialized logical Border document unchanged',
      () async {
    final (root, files) = await fixture(withBorder: true);
    final artifact = await export(root);
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
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
