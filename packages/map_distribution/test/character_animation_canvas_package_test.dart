import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final portable in [false, true]) {
    Map<String, List<int>> payload({required bool extended}) {
      final files = spatialPayload();
      final source = jsonDecode(utf8.decode(files['project/project.json']!));
      if (extended) {
        source['characters'][0]['animations'][0]
            ['presentationReferenceHeightPx'] = 32;
      }
      final project = ProjectManifest.fromJson(source);
      files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
      if (portable) {
        final publication = PortableCatalogPublication.encodeProject(project);
        files['project/project.json'] =
            utf8.encode(jsonEncode(publication.descriptor));
        for (final object in publication.storage.objects.entries) {
          files['project/catalog/objects/${object.key}.json'] = object.value;
        }
      }
      return files;
    }

    test(
        'extended animation canvas requires explicit capability portable=$portable',
        () {
      final files = payload(extended: true);
      final before = {
        for (final entry in files.entries) entry.key: List<int>.of(entry.value)
      };
      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest(false),
          payloadFiles: files,
        ),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.message,
          'message',
          contains(CharacterAnimationCanvasCapabilities.capabilityId),
        )),
      );
      expect(files, before);
    });

    test('current Player admits declared animation canvas portable=$portable',
        () {
      final built = const GamePackageBuilder().build(
        manifest: _manifest(true),
        payloadFiles: payload(extended: true),
      );
      final inspected = GamePackageInspector(
        hostCompatibility: AveluneRuntimeCompatibility.host(),
      ).inspect(built.packageBytes);
      expect(inspected.compatibility?.decision,
          GamePackageCompatibilityDecision.accept);
    });

    test(
        'historical canvases keep their capability contract portable=$portable',
        () {
      final built = const GamePackageBuilder().build(
        manifest: _manifest(false),
        payloadFiles: payload(extended: false),
      );
      expect(built.manifest.compatibility.requiredCapabilities,
          isNot(contains(CharacterAnimationCanvasCapabilities.capabilityId)));
      expect(
          GamePackageInspector(
            hostCompatibility: AveluneRuntimeCompatibility.host(),
          ).inspect(built.packageBytes).compatibility?.decision,
          GamePackageCompatibilityDecision.accept);
    });
  }
}

GamePackageManifest _manifest(bool canvas) {
  final json = spatialManifest(capabilities: [
    'map3d@1',
    if (canvas) CharacterAnimationCanvasCapabilities.capabilityId,
  ]).toJson();
  (json['compatibility'] as Map<String, Object?>).addAll(<String, Object?>{
    'minHubVersion': '0.1.0',
    'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
  });
  return const GamePackageManifestCodec().decodeJson(json);
}
