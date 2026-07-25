import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final host = GamePackageHostCompatibility(
    hubVersion: Version.parse('1.2.0'),
    runtimeApiVersion: Version.parse('1.4.0'),
    capabilities: const <String>{
      'dialogue.choices@1',
      'overworld.menu@1',
      'world.shop@1',
    },
    supportedProjectFormats: const <String>{'v1', 'v2'},
    currentProjectFormat: 'v2',
    supportedSaveFormats: const <int>{1},
  );

  group('GamePackageCompatibilityEvaluator', () {
    const evaluator = GamePackageCompatibilityEvaluator();

    test('reproduces Phase 0 accept and migration decisions', () {
      expect(
        evaluator.evaluate(_manifest(), host),
        const GamePackageCompatibilityResult.accept(),
      );
      expect(
        evaluator.evaluate(
          _manifest(projectFormat: 'v1'),
          host,
        ),
        const GamePackageCompatibilityResult.migrate(
          code: 'projectMigrationRequired',
        ),
      );
    });

    test('reproduces Phase 0 rejection codes in stable priority order', () {
      expect(
        evaluator
            .evaluate(
              _manifest(minHubVersion: '1.3.0'),
              host,
            )
            .code,
        'hubTooOld',
      );
      expect(
        evaluator
            .evaluate(
              _manifest(runtimeApi: '>=2.0.0 <3.0.0'),
              host,
            )
            .code,
        'runtimeApiUnsupported',
      );
      final missing = evaluator.evaluate(
        _manifest(capabilities: const <String>['dialogue.choices@2']),
        host,
      );
      expect(missing.code, 'capabilityUnsupported');
      expect(missing.missingCapabilities, <String>['dialogue.choices@2']);
    });

    test('rejects unsupported project and save formats', () {
      final unsupportedProjectHost = GamePackageHostCompatibility(
        hubVersion: host.hubVersion,
        runtimeApiVersion: host.runtimeApiVersion,
        capabilities: host.capabilities,
        supportedProjectFormats: const <String>{'v1'},
        currentProjectFormat: 'v1',
        supportedSaveFormats: host.supportedSaveFormats,
      );
      expect(
        evaluator.evaluate(_manifest(), unsupportedProjectHost).code,
        'projectFormatUnsupported',
      );

      final unsupportedSaveHost = GamePackageHostCompatibility(
        hubVersion: host.hubVersion,
        runtimeApiVersion: host.runtimeApiVersion,
        capabilities: host.capabilities,
        supportedProjectFormats: host.supportedProjectFormats,
        currentProjectFormat: host.currentProjectFormat,
        supportedSaveFormats: const <int>{2},
      );
      expect(
        evaluator.evaluate(_manifest(), unsupportedSaveHost).code,
        'saveFormatUnsupported',
      );
    });

    test('honors inclusive, exclusive, and prerelease SemVer boundaries', () {
      expect(
        evaluator.evaluate(
          _manifest(
            minHubVersion: '1.2.0+contract',
            runtimeApi: '>=1.4.0+contract <2.0.0',
          ),
          host,
        ),
        const GamePackageCompatibilityResult.accept(),
      );
      expect(
        evaluator
            .evaluate(
              _manifest(runtimeApi: '>=1.0.0 <1.4.0'),
              host,
            )
            .code,
        'runtimeApiUnsupported',
      );

      final prereleaseHost = GamePackageHostCompatibility(
        hubVersion: host.hubVersion,
        runtimeApiVersion: Version.parse('2.0.0-beta.2'),
        capabilities: host.capabilities,
        supportedProjectFormats: host.supportedProjectFormats,
        currentProjectFormat: host.currentProjectFormat,
        supportedSaveFormats: host.supportedSaveFormats,
      );
      expect(
        evaluator.evaluate(
          _manifest(runtimeApi: '>=2.0.0-beta.1 <2.0.0'),
          prereleaseHost,
        ),
        const GamePackageCompatibilityResult.accept(),
      );
    });

    test('reports every blocker in the Phase 0 precedence order', () {
      final blocked = evaluator.evaluate(
        _manifest(
          minHubVersion: '2.0.0',
          runtimeApi: '>=2.0.0 <3.0.0',
          projectFormat: 'v3',
          capabilities: const <String>['dialogue.choices@2'],
        ),
        host,
      );

      expect(blocked.code, 'hubTooOld');
      expect(
        blocked.blockingCodes,
        <String>[
          'hubTooOld',
          'runtimeApiUnsupported',
          'capabilityUnsupported',
          'projectFormatUnsupported',
        ],
      );
      expect(blocked.missingCapabilities, <String>['dialogue.choices@2']);
    });

    test('executes every Phase 1 row from the Phase 0 compatibility matrix',
        () {
      final matrix = jsonDecode(
        File(
          '../../reports/product/pokemap_hub/phase_0/compatibility/'
          'compatibility-matrix.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final handled = <String>{};
      final deferredToPhase2 = <String>{
        'C-011',
        'C-012',
        'C-013',
        'C-014',
        'C-015',
        'C-016',
        'C-020',
      };

      for (final rawCase in matrix['cases'] as List) {
        final testCase = rawCase as Map<String, dynamic>;
        final id = testCase['id'] as String;
        if (deferredToPhase2.contains(id)) continue;
        final given = testCase['given'] as Map<String, dynamic>;
        final expected = testCase['expected'] as Map<String, dynamic>;
        if (id.compareTo('C-010') <= 0) {
          final json = _manifestJson();
          if (given.containsKey('packageFormat')) {
            json['packageFormat'] = given['packageFormat'];
          }
          final compatibility = json['compatibility']! as Map<String, Object?>;
          for (final field in <String>[
            'minHubVersion',
            'runtimeApi',
            'projectFormat',
            'requiredCapabilities',
          ]) {
            if (given.containsKey(field)) compatibility[field] = given[field];
          }
          if (id == 'C-002') {
            expect(
              () => const GamePackageManifestCodec().decodeJson(json),
              throwsA(
                isA<GamePackageFormatException>().having(
                  (error) => error.code,
                  'code',
                  expected['code'],
                ),
              ),
              reason: id,
            );
          } else {
            final result = const GamePackageCompatibilityEvaluator().evaluate(
              const GamePackageManifestCodec().decodeJson(json),
              host,
            );
            expect(result.decision.name, expected['decision'], reason: id);
            expect(result.code, expected['code'], reason: id);
          }
        } else {
          final installedJson = given['installed'] as Map<String, dynamic>?;
          final candidateJson = given['candidate'] as Map<String, dynamic>?;
          final installed = GamePackageReleaseIdentity(
            gameId:
                installedJson?['gameId'] as String? ?? 'games.example.complete',
            gameVersion: Version.parse(
              installedJson?['gameVersion'] as String? ??
                  given['currentGameVersion'] as String,
            ),
            treeSha256: installedJson?['treeSha256'] as String? ?? 'a' * 64,
          );
          final candidate = GamePackageReleaseIdentity(
            gameId: candidateJson?['gameId'] as String? ?? installed.gameId,
            gameVersion: Version.parse(
              candidateJson?['gameVersion'] as String? ??
                  given['candidateGameVersion'] as String,
            ),
            treeSha256: candidateJson?['treeSha256'] as String? ?? 'b' * 64,
          );
          final mode = GamePackageActivationMode.values.byName(
            given['activationMode'] as String? ?? 'update',
          );
          final result = const GamePackageReleasePolicy().evaluate(
            installed: installed,
            candidate: candidate,
            mode: mode,
            compatibleSaveSnapshotAvailable:
                given['compatibleSaveSnapshotAvailable'] as bool? ?? false,
          );
          expect(result.decision.name, expected['decision'], reason: id);
          expect(result.code, expected['code'], reason: id);
        }
        handled.add(id);
      }

      expect(
        handled,
        <String>{
          'C-001',
          'C-002',
          'C-003',
          'C-004',
          'C-005',
          'C-006',
          'C-007',
          'C-008',
          'C-009',
          'C-010',
          'C-017',
          'C-018',
          'C-019',
        },
      );
      expect(
        (matrix['cases'] as List)
            .map((value) => (value as Map<String, dynamic>)['id'] as String)
            .toSet()
            .difference(handled),
        deferredToPhase2,
      );
    });
  });
}

GamePackageManifest _manifest({
  String minHubVersion = '1.0.0',
  String runtimeApi = '>=1.0.0 <2.0.0',
  String projectFormat = 'v2',
  List<String> capabilities = const <String>[],
}) {
  final json = _manifestJson(
    minHubVersion: minHubVersion,
    runtimeApi: runtimeApi,
    projectFormat: projectFormat,
    capabilities: capabilities,
  );
  return const GamePackageManifestCodec().decodeJson(json);
}

Map<String, Object?> _manifestJson({
  String minHubVersion = '1.0.0',
  String runtimeApi = '>=1.0.0 <2.0.0',
  String projectFormat = 'v2',
  List<String> capabilities = const <String>[],
}) {
  const projectEntry = GamePackageFileEntry(
    path: 'project/project.json',
    size: 1,
    sha256: '4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7c78e5f6f5e5d85',
  );
  return <String, Object?>{
    'packageFormat': 1,
    'gameId': 'games.example.compatibility',
    'gameVersion': '1.0.0',
    'title': 'Compatibility',
    'author': <String, Object?>{'name': 'Example'},
    'compatibility': <String, Object?>{
      'minHubVersion': minHubVersion,
      'runtimeApi': runtimeApi,
      'projectFormat': projectFormat,
      'saveFormat': 1,
      'compatibilityId': 'main',
      'requiredCapabilities': capabilities,
    },
    'locales': <String, Object?>{
      'default': 'fr',
      'supported': <String>['fr'],
    },
    'content': <String, Object?>{
      'fileCount': 1,
      'totalBytes': 1,
      'treeSha256': ContentTreeHasher.sha256Hex(
        const <GamePackageFileEntry>[projectEntry],
      ),
      'files': <Object?>[
        projectEntry.toJson(),
      ],
    },
  };
}
