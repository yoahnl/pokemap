import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  for (final version in ['0.3.31+331', '0.3.37+337']) {
    for (final (kind, format, mapId, digest) in [
      (
        'overworld',
        'v8',
        'runtime_harbor',
        version == '0.3.31+331'
            ? '889914c913424b9225afba1ce26593f9141d140be6e35938a95164a9788bd9ea'
            : '2e78698b1744aa8723c1ac9f2960a784462de96f2e84108e1a7d9cd3f121d0fd'
      ),
      (
        'spatial',
        'v9',
        'map',
        version == '0.3.31+331'
            ? '6e239501d583ad4732bbe0902eb274d69b3a000f55f96abd9c231d501acd7d7a'
            : 'd2a504a0bfc62bafe506edf3308cec6e7fef0d66490c05f014693828d74e1c22'
      ),
    ]) {
      test('reads the frozen Studio $version $kind canonical export', () {
        final bytes = _package(kind, version: version);
        final original = List<int>.of(bytes);
        expect(sha256.convert(bytes).toString(), digest);
        final inspection = GamePackageInspector(
          hostCompatibility: AveluneRuntimeCompatibility.host(),
        ).inspect(bytes);
        final project = _project(bytes, inspection.manifest);

        expect(inspection.compatibility?.decision,
            GamePackageCompatibilityDecision.accept);
        expect(inspection.manifest.gameVersion,
            Version.parse(version == '0.3.31+331' ? '1.2.0' : '1.3.0'));
        expect(inspection.manifest.compatibility.projectFormat, format);
        expect(inspection.manifest.compatibility.saveFormat, 2);
        expect(project.version.name, format);
        expect(project.maps.single.id, mapId);
        expect(project.pokemon.enabled, isFalse);
        expect(project.partyCompanion.enabled, isFalse);
        expect(project.contactDevice, isNull);
        if (kind == 'overworld') {
          expect(project.name, 'Les Îles Claires');
          expect(project.shops.single.entries.single.price, 60);
          expect(project.facts.map((fact) => fact.id),
              contains('fact_mist_source_resolved'));
          expect(project.scenes.map((scene) => scene.id),
              containsAll(['scene_harbor_shop', 'scene_harbor_heal']));
        } else {
          expect(project.name, 'Exploration');
          expect(project.characters.single.id, 'hero');
          expect(project.characters.single.animations, hasLength(4));
          expect(project.settings.dimension, ProjectDimension.threeD);
        }
        expect(bytes, original);
        expect(_package(kind, version: version), original);
      });

      test(
          'a newer host retaining API 1.4 reads the frozen $version $kind export',
          () {
        final baseline = AveluneRuntimeCompatibility.host();
        final upgraded = GamePackageHostCompatibility(
          hubVersion: Version.parse('5.0.0'),
          runtimeApiVersion: Version.parse('2.0.0'),
          supportedRuntimeApiVersions: {
            ...baseline.supportedRuntimeApiVersions,
            Version.parse('2.0.0'),
          },
          capabilities: baseline.capabilities,
          supportedProjectFormats: baseline.supportedProjectFormats,
          currentProjectFormat: baseline.currentProjectFormat,
          currentProjectFormats: baseline.currentProjectFormats,
          supportedSaveFormats: baseline.supportedSaveFormats,
        );
        final inspection = GamePackageInspector(hostCompatibility: upgraded)
            .inspect(_package(kind, version: version));
        expect(inspection.compatibility?.decision,
            GamePackageCompatibilityDecision.accept);
        expect(
            _project(_package(kind, version: version), inspection.manifest)
                .maps
                .single
                .id,
            mapId);
      });
    }
  }

  for (final (field, value, code) in <(String, Object, String?)>[
    ('packageFormat', 999, null),
    ('runtimeApi', '>=99.0.0 <100.0.0', 'runtimeApiUnsupported'),
    ('projectFormat', 'v999', null),
    ('saveFormat', 999, 'saveFormatUnsupported'),
    (
      'requiredCapabilities',
      ['catalog.partitioned@2', 'map.future@999'],
      'capabilityUnsupported'
    ),
  ]) {
    test('rejects unknown $field without changing any archive bytes', () {
      final bytes = _package('overworld');
      final original = List<int>.of(bytes);
      final future = _changeContract(bytes, field, value);
      final untouchedFuture = List<int>.of(future);
      final error = isA<GamePackageFormatException>();
      expect(
        () => GamePackageInspector(
          hostCompatibility: AveluneRuntimeCompatibility.host(),
        ).inspect(future),
        throwsA(
            code == null ? error : error.having((e) => e.code, 'code', code)),
      );
      expect(bytes, original);
      expect(future, untouchedFuture);
    });
  }
}

Uint8List _package(String kind, {String version = '0.3.31+331'}) =>
    base64Decode(
      File('test/fixtures/compatibility/avelune_studio_${version.replaceAll(RegExp(r'[.+]'), '_')}/'
              '$kind.avelunegame.base64')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s'), ''),
    );

ProjectManifest _project(List<int> bytes, GamePackageManifest manifest) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final payload = <String, List<int>>{
    for (final file in archive.files)
      if (file.name != 'game-manifest.json') file.name: file.content,
  };
  return const GamePackageProjectValidator(GamePackageSecurityPolicy())
      .validate(
    manifest,
    Uint8List.fromList(payload['project/project.json']!),
    payloadPaths: payload.keys.toSet(),
    readPayload: (path) => payload[path],
  );
}

Uint8List _changeContract(List<int> bytes, String field, Object value) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final manifest = jsonDecode(
    utf8.decode(archive.findFile('game-manifest.json')!.content),
  ) as Map<String, dynamic>;
  if (field == 'packageFormat') {
    manifest[field] = value;
  } else {
    (manifest['compatibility'] as Map)[field] = value;
  }
  return DeterministicZipEncoder.encode([
    for (final file in archive.files)
      MapEntry(
          file.name,
          file.name == 'game-manifest.json'
              ? CanonicalJson.encodeUtf8(manifest)
              : file.content),
  ]);
}
