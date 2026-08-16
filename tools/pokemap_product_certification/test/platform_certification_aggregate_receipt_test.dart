import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('aggregates six explicit platform receipts at one release SHA', () {
    final receipt = PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: _platformSupport(),
      platformEvidence: _platformEvidence(),
      provenance: _provenance(),
    );

    expect(receipt.passed, isTrue);
    expect(receipt.blockingPlatforms, isEmpty);
    final json = receipt.toJson();
    expect(json['releaseCommit'], 'a' * 40);
    expect(json['bundleVersion'], '1.0.1+3');
    expect(json['verdict'], 'passed');
    expect(json, isNot(contains('average')));
    final platforms = json['platforms']! as List<Object?>;
    expect(platforms, hasLength(6));
    expect(
      platforms.map((entry) => (entry! as Map<String, Object?>)['platform']),
      <String>['macos', 'ios', 'android', 'windows', 'linux', 'web'],
    );
    expect(
      (platforms.first as Map<String, Object?>)['packageManager'],
      'spm-only',
    );

    final encoded = receipt.encodeCanonical();
    expect(
      PlatformCertificationAggregateReceipt.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      ).encodeCanonical(),
      encoded,
    );
  });

  test('fails the aggregate when one structurally valid receipt is red', () {
    final evidence = _platformEvidence();
    final platforms = evidence['platforms']! as List<Object?>;
    (platforms[2]! as Map<String, Object?>)['status'] = 'failed';

    final receipt = PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: _platformSupport(),
      platformEvidence: evidence,
      provenance: _provenance(),
    );

    expect(receipt.passed, isFalse);
    expect(receipt.blockingPlatforms, <String>['android']);
    expect(receipt.toJson()['verdict'], 'failed');
  });

  test('rejects incomplete, deceptive or CocoaPods-backed evidence', () {
    final missingPlatform = _platformEvidence();
    (missingPlatform['platforms']! as List<Object?>).removeLast();
    expect(() => _receipt(missingPlatform), throwsA(isA<FormatException>()));

    final deceptiveWeb = _platformEvidence();
    final web =
        (deceptiveWeb['platforms']! as List<Object?>).last!
            as Map<String, Object?>;
    web['verdict'] = 'supported';
    expect(() => _receipt(deceptiveWeb), throwsA(isA<FormatException>()));

    final cocoaPods = _platformEvidence();
    final macos =
        (cocoaPods['platforms']! as List<Object?>).first!
            as Map<String, Object?>;
    macos['packageManager'] = 'cocoapods';
    expect(() => _receipt(cocoaPods), throwsA(isA<FormatException>()));

    final mixedMatrix = _platformSupport();
    final matrix = mixedMatrix['platforms']! as Map<String, Object?>;
    final windows = matrix['windows']! as Map<String, Object?>;
    final capabilities = windows['capabilities']! as Map<String, Object?>;
    capabilities['video'] = 'supported';
    expect(
      () => PlatformCertificationAggregateReceipt.fromInputs(
        platformSupport: mixedMatrix,
        platformEvidence: _platformEvidence(),
        provenance: _provenance(),
      ),
      throwsA(isA<FormatException>()),
    );

    final extendedMatrix = _platformSupport()..['unexpected'] = true;
    expect(
      () => PlatformCertificationAggregateReceipt.fromInputs(
        platformSupport: extendedMatrix,
        platformEvidence: _platformEvidence(),
        provenance: _provenance(),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

PlatformCertificationAggregateReceipt _receipt(Map<String, Object?> evidence) =>
    PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: _platformSupport(),
      platformEvidence: evidence,
      provenance: _provenance(),
    );

Map<String, Object?> _platformSupport() => <String, Object?>{
  'schemaVersion': 2,
  'platforms': <String, Object?>{
    'macos': _support('supported', 'supported'),
    'ios': _support('xcode-cloud-target', 'supported'),
    'android': _support('build-target', 'supported'),
    'windows': _support(
      'build-and-launch-target',
      'target',
      video: 'fallback-only',
    ),
    'linux': _support(
      'build-and-launch-target',
      'target',
      video: 'fallback-only',
    ),
    'web': _support('unsupported', 'unsupported'),
  },
};

Map<String, Object?> _support(
  String status,
  String capability, {
  String? video,
}) => <String, Object?>{
  'status': status,
  'capabilities': <String, Object?>{
    'image': capability,
    'audio': capability,
    'video': video ?? capability,
    'captions': capability,
  },
};

Map<String, Object?> _platformEvidence() => <String, Object?>{
  'schemaVersion': 1,
  'platforms': <Object?>[
    _evidence(
      platform: 'macos',
      verdict: 'supported',
      ticket: 'BETA-CIN-045',
      commit: '1' * 40,
      build: 'passed',
      smoke: 'passed',
      packageManager: 'spm-only',
      bundleId: 'app.pokemap.hub',
    ),
    _evidence(
      platform: 'ios',
      verdict: 'supported',
      ticket: 'BETA-CIN-046',
      commit: '2' * 40,
      build: 'passed',
      smoke: 'passed',
      packageManager: 'spm-only',
      bundleId: 'com.yoahnl.avelune.player',
      limitations: const <String>['physical-launch-deferred'],
    ),
    _evidence(
      platform: 'android',
      verdict: 'supported',
      ticket: 'BETA-CIN-046',
      commit: '2' * 40,
      build: 'passed',
      smoke: 'equivalent',
      packageManager: 'gradle',
      bundleId: 'com.yoahnl.avelune.player',
      limitations: const <String>['device-smoke-unavailable'],
    ),
    _evidence(
      platform: 'windows',
      verdict: 'fallback-only',
      ticket: 'BETA-CIN-047',
      commit: '3' * 40,
      build: 'target',
      smoke: 'target',
      packageManager: 'native-runner',
      limitations: const <String>['video-poster-fallback-required'],
    ),
    _evidence(
      platform: 'linux',
      verdict: 'fallback-only',
      ticket: 'BETA-CIN-047',
      commit: '3' * 40,
      build: 'target',
      smoke: 'target',
      packageManager: 'native-runner',
      limitations: const <String>['video-poster-fallback-required'],
    ),
    _evidence(
      platform: 'web',
      verdict: 'out-of-scope',
      ticket: 'BETA-CIN-047',
      commit: '3' * 40,
      build: 'not-applicable',
      smoke: 'not-applicable',
      packageManager: 'none',
      limitations: const <String>['no-certified-runner'],
    ),
  ],
};

Map<String, Object?> _evidence({
  required String platform,
  required String verdict,
  required String ticket,
  required String commit,
  required String build,
  required String smoke,
  required String packageManager,
  String? bundleId,
  List<String> limitations = const <String>[],
}) => <String, Object?>{
  'platform': platform,
  'verdict': verdict,
  'status': 'passed',
  'sourceTicket': ticket,
  'sourceCommit': commit,
  'build': build,
  'smoke': smoke,
  'policy': 'passed',
  'packageManager': packageManager,
  'bundleId': bundleId,
  'commands': <String>['flutter test test/release/platform_gate_test.dart'],
  'limitations': limitations,
};

Map<String, Object?> _provenance() => <String, Object?>{
  'releaseCommit': 'a' * 40,
  'treeState': 'clean',
  'treeFingerprint': 'b' * 64,
  'platformSupportSha256': 'c' * 64,
  'pluginLockSha256': 'd' * 64,
  'bundleVersion': '1.0.1+3',
  'pluginVersions': <String, Object?>{
    'audioplayers': '6.8.1',
    'video_player': '2.13.0',
  },
};
