import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final portable in [false, true]) {
    for (final enabled in [false, true]) {
      test(
          'explicit Surf enabled=$enabled requires capability portable=$portable',
          () {
        final project = ProjectManifest(
            name: 'Surf',
            maps: [],
            tilesets: [],
            settings:
                ProjectSettings(surf: ProjectSurfSettings(enabled: enabled)));
        final files = _payload(project, portable);
        expect(
            () => const GamePackageBuilder()
                .build(manifest: _manifest(false), payloadFiles: files),
            throwsA(isA<GamePackageFormatException>().having(
                (error) => error.message,
                'message',
                contains('gameplay.surf@1'))));
        final built = const GamePackageBuilder()
            .build(manifest: _manifest(true), payloadFiles: files);
        final inspected = GamePackageInspector(
                hostCompatibility: AveluneRuntimeCompatibility.host())
            .inspect(built.packageBytes);
        expect(inspected.compatibility?.decision,
            GamePackageCompatibilityDecision.accept);
      });
    }
    test(
        'absent Surf preserves historical capability requirements portable=$portable',
        () {
      final project = ProjectManifest(name: 'Legacy', maps: [], tilesets: []);
      final built = const GamePackageBuilder().build(
          manifest: _manifest(false),
          payloadFiles: _payload(project, portable));
      expect(built.manifest.compatibility.requiredCapabilities,
          isNot(contains('gameplay.surf@1')));
    });
  }
}

Map<String, List<int>> _payload(ProjectManifest project, bool portable) {
  if (!portable)
    return {'project/project.json': utf8.encode(jsonEncode(project.toJson()))};
  final publication = PortableCatalogPublication.encodeProject(project);
  return {
    'project/project.json': utf8.encode(jsonEncode(publication.descriptor)),
    for (final object in publication.storage.objects.entries)
      'project/catalog/objects/${object.key}.json': object.value
  };
}

GamePackageManifest _manifest(bool surf) {
  final json =
      spatialManifest(capabilities: ['map@1', if (surf) 'gameplay.surf@1'])
          .toJson();
  (json['compatibility'] as Map).addAll(<String, Object?>{
    'projectFormat': 'v8',
    'minHubVersion': '0.1.0',
    'saveFormat': SaveEnvelopeCodec.currentSaveFormat
  });
  return const GamePackageManifestCodec().decodeJson(json);
}
