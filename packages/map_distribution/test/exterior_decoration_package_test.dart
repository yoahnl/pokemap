import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'support/exterior_decoration_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test(
      'one materialized logical Border preserves full native ownership in packages',
      () {
    final files = exteriorDecorationPayload(withBorder: true);
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(
                capabilities: ['map3d@1', MapExteriorDecoration.capabilityId]),
            payloadFiles: files),
        returnsNormally);
    final original = files['project/maps/map.decoration/borders/fence.json']!;
    files.remove('project/maps/map.decoration/borders/fence.json');
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(
                capabilities: ['map3d@1', MapExteriorDecoration.capabilityId]),
            payloadFiles: files),
        throwsA(isA<GamePackageFormatException>()));
    expect(original, isNotEmpty);
  });
  test('legacy registered maps and asset folders keep decoration-looking names',
      () {
    final files = spatialPayload();
    final project = jsonDecode(utf8.decode(files['project/project.json']!))
        as Map<String, dynamic>;
    (project['maps'] as List).single['relativePath'] =
        'maps/map.decoration.json';
    files['project/project.json'] = utf8.encode(jsonEncode(project));
    files['project/maps/map.decoration.json'] =
        files.remove('project/maps/map.json')!;
    files['project/assets/landscape.decoration/empty.json'] = utf8.encode('{}');
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        returnsNormally);
  });
  test(
      'old packages stay unchanged and exterior packages require their capability',
      () {
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: spatialPayload()),
        returnsNormally);
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(),
            payloadFiles: exteriorDecorationPayload()),
        throwsA(isA<GamePackageFormatException>()));
    final result = const GamePackageBuilder().build(
        manifest: spatialManifest(
            capabilities: ['map3d@1', MapExteriorDecoration.capabilityId]),
        payloadFiles: exteriorDecorationPayload());
    expect(
        const GamePackageInspector()
            .inspect(result.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(MapExteriorDecoration.capabilityId));
  });

  test('rejects missing changed and orphan sector documents', () {
    for (final mode in [
      'missing',
      'changed',
      'orphan',
      'summary',
      'identity',
      'unknown'
    ]) {
      final files = exteriorDecorationPayload();
      final path = 'project/maps/map.decoration/west.json';
      if (mode == 'missing') files.remove(path);
      if (mode == 'changed') files[path] = utf8.encode('{}');
      if (mode == 'orphan') files.remove('project/maps/map.decoration.json');
      if (mode == 'summary' || mode == 'identity' || mode == 'unknown') {
        final index =
            jsonDecode(utf8.decode(files['project/maps/map.decoration.json']!))
                as Map<String, dynamic>;
        if (mode == 'summary') {
          (index['sectors'] as List).single['instances'] = 2;
        }
        if (mode == 'identity') (index['definition'] as Map)['mapId'] = 'other';
        if (mode == 'unknown') index['events'] = [];
        files['project/maps/map.decoration.json'] =
            utf8.encode(jsonEncode(index));
      }
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: [
                'map3d@1',
                MapExteriorDecoration.capabilityId
              ]),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()),
          reason: mode);
    }
  });

  test('rejects exterior resource references absent from the project', () {
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(
                capabilities: ['map3d@1', MapExteriorDecoration.capabilityId]),
            payloadFiles: exteriorDecorationPayload(modelId: 'missing-model')),
        throwsA(isA<GamePackageFormatException>()));
  });

  test('host admits feature and older hosts reject its dedicated capability',
      () {
    final host = AveluneRuntimeCompatibility.host();
    expect(host.capabilities, contains(MapExteriorDecoration.capabilityId));
    final oldHost = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.0.0'),
        runtimeApiVersion: host.runtimeApiVersion,
        capabilities:
            host.capabilities.difference({MapExteriorDecoration.capabilityId}),
        supportedProjectFormats: host.supportedProjectFormats,
        currentProjectFormat: 'v9',
        supportedSaveFormats: host.supportedSaveFormats);
    final result = const GamePackageCompatibilityEvaluator().evaluate(
        spatialManifest(
            capabilities: ['map3d@1', MapExteriorDecoration.capabilityId]),
        oldHost);
    expect(result.decision, GamePackageCompatibilityDecision.reject);
    expect(result.missingCapabilities,
        contains(MapExteriorDecoration.capabilityId));
  });
}
