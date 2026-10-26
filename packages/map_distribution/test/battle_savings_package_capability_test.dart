import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  const policy = ProjectBattleSavingsConfig(
      enabledFactId: 'enabled',
      balanceFactId: 'balance',
      percentage: 25,
      maximumBalance: 999999);
  final project = ProjectManifest(
      name: 'Savings package',
      maps: [],
      tilesets: [],
      battleSavings: policy,
      facts: [
        NarrativeFactDefinition(id: 'enabled', label: 'Enabled'),
        NarrativeFactDefinition(
            id: 'balance',
            label: 'Balance',
            initialValue: NarrativeValue.integer(0)),
      ]);
  for (final portable in [false, true]) {
    Map<String, List<int>> payload(ProjectManifest value) {
      if (!portable) {
        return {
          'project/project.json': utf8.encode(jsonEncode(value.toJson())),
        };
      }
      final publication = PortableCatalogPublication.encodeProject(value);
      return {
        'project/project.json': utf8.encode(jsonEncode(publication.descriptor)),
        for (final object in publication.storage.objects.entries)
          'project/catalog/objects/${object.key}.json': object.value,
      };
    }

    test(
        'savings policy requires capability before admission portable=$portable',
        () {
      final files = payload(project);
      final originals = {
        for (final entry in files.entries) entry.key: List<int>.of(entry.value)
      };
      expect(
          () => const GamePackageBuilder()
              .build(manifest: _manifest(savings: false), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.message,
              'message',
              contains(ProjectBattleSavingsConfig.capabilityId))));
      expect(files, originals);
    });
    test('savings policy admits with declared capability portable=$portable',
        () {
      final built = const GamePackageBuilder().build(
          manifest: _manifest(savings: true), payloadFiles: payload(project));
      final inspected = GamePackageInspector(
              hostCompatibility: AveluneRuntimeCompatibility.host())
          .inspect(built.packageBytes);
      expect(inspected.compatibility?.decision,
          GamePackageCompatibilityDecision.accept);
      final files = _payload(built.packageBytes);
      final restored =
          const GamePackageProjectValidator(GamePackageSecurityPolicy())
              .validate(inspected.manifest,
                  Uint8List.fromList(files['project/project.json']!),
                  payloadPaths: files.keys.toSet(),
                  readPayload: (path) => files[path]);
      expect(restored.battleSavings, policy);
      expect(restored.facts, project.facts);
    });
    test(
        'absent policy keeps historical capability requirements portable=$portable',
        () {
      final built = const GamePackageBuilder().build(
          manifest: _manifest(savings: false),
          payloadFiles: payload(project.copyWith(battleSavings: null)));
      final inspected = GamePackageInspector(
              hostCompatibility: AveluneRuntimeCompatibility.host())
          .inspect(built.packageBytes);
      expect(inspected.compatibility?.decision,
          GamePackageCompatibilityDecision.accept);
      expect(inspected.manifest.compatibility.requiredCapabilities,
          isNot(contains(ProjectBattleSavingsConfig.capabilityId)));
    });
  }
  test(
      'valid portable package cannot shed its required savings capability at project preflight',
      () {
    final built = const GamePackageBuilder()
        .build(manifest: _manifest(savings: true), payloadFiles: {
      'project/project.json': utf8.encode(jsonEncode(project.toJson())),
    });
    final files = _payload(built.packageBytes);
    final json = built.manifest.toJson();
    (json['compatibility'] as Map)['requiredCapabilities'] = built
        .manifest.compatibility.requiredCapabilities
        .where((value) => value != ProjectBattleSavingsConfig.capabilityId)
        .toList();
    final stripped = const GamePackageManifestCodec().decodeJson(json);
    final originalBytes = List<int>.of(built.packageBytes);
    final strippedBytes = DeterministicZipEncoder.encode([
      for (final file in ZipDecoder().decodeBytes(built.packageBytes).files)
        MapEntry(
            file.name,
            file.name == 'game-manifest.json'
                ? CanonicalJson.encodeUtf8(stripped.toJson())
                : file.content),
    ]);
    expect(
        () => const GamePackageInspector().inspect(strippedBytes),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains(ProjectBattleSavingsConfig.capabilityId))));
    expect(built.packageBytes, originalBytes);
    expect(
        () => const GamePackageProjectValidator(GamePackageSecurityPolicy())
            .validate(
                stripped, Uint8List.fromList(files['project/project.json']!),
                payloadPaths: files.keys.toSet(),
                readPayload: (path) => files[path]),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains(ProjectBattleSavingsConfig.capabilityId))));
  });
}

Map<String, List<int>> _payload(List<int> bytes) => {
      for (final file in ZipDecoder().decodeBytes(bytes).files)
        if (file.name != 'game-manifest.json') file.name: file.content,
    };

GamePackageManifest _manifest({required bool savings}) {
  final json = spatialManifest(capabilities: [
    'map@1',
    if (savings) ProjectBattleSavingsConfig.capabilityId
  ]).toJson();
  (json['compatibility'] as Map).addAll(<String, Object?>{
    'projectFormat': 'v8',
    'minHubVersion': '0.1.0',
    'saveFormat': SaveEnvelopeCodec.currentSaveFormat
  });
  return const GamePackageManifestCodec().decodeJson(json);
}
