import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('derives deterministic CIN-038 metrics and a passing verdict', () {
    final receipt = PresentationRuntimePerformanceReceipt.fromMeasurements(
      measurements: _validMeasurements(),
      platformSupport: _platformSupport(),
      provenance: _provenance(),
    );

    expect(receipt.passed, isTrue);
    expect(receipt.violations, isEmpty);
    expect(receipt.toJson()['supportedPlatforms'], <String>['macos']);
    expect(receipt.toJson()['deferredPlatforms'], <String>['ios', 'android']);
    final cycles = receipt.toJson()['cycleEvidence']! as List<Object?>;
    expect(cycles, hasLength(50));
    expect(
      cycles.map((entry) => (entry! as Map<String, Object?>)['orientation']),
      orderedEquals(<String>[
        for (var cycle = 1; cycle <= 50; cycle += 1)
          cycle.isOdd ? 'landscape' : 'portrait',
      ]),
    );
    final metrics = receipt.toJson()['metrics']! as Map<String, Object?>;
    expect((metrics['skip']! as Map<String, Object?>)['p95Us'], 50000);
    expect((metrics['rss']! as Map<String, Object?>)['growthBasisPoints'], 500);
    expect(
      (metrics['uiFrames']! as Map<String, Object?>)['withinBudgetBasisPoints'],
      9900,
    );

    final encoded = receipt.encodeCanonical();
    expect(
      PresentationRuntimePerformanceReceipt.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      ).encodeCanonical(),
      encoded,
    );
  });

  test('rejects non-canonical fixtures, platforms and input keys', () {
    final wrongFixture = _validMeasurements();
    (wrongFixture['fixture']! as Map<String, Object?>)['landscapeVideoSha256'] =
        'a' * 64;
    expect(() => _receipt(wrongFixture), throwsA(isA<FormatException>()));

    final unsupportedMatrix = _platformSupport();
    final platforms = unsupportedMatrix['platforms']! as Map<String, Object?>;
    platforms['ios'] = <String, Object?>{'status': 'supported'};
    expect(
      () => PresentationRuntimePerformanceReceipt.fromMeasurements(
        measurements: _validMeasurements(),
        platformSupport: unsupportedMatrix,
        provenance: _provenance(),
      ),
      throwsA(isA<FormatException>()),
    );

    final unexpectedKey = _validMeasurements()..['forged'] = true;
    expect(() => _receipt(unexpectedKey), throwsA(isA<FormatException>()));

    final wrongOrientation = _validMeasurements();
    (_cycleEvidence(wrongOrientation)[1]
            as Map<String, Object?>)['orientation'] =
        'landscape';
    expect(() => _receipt(wrongOrientation), throwsA(isA<FormatException>()));

    final missingCooldown = _validMeasurements();
    (_cycleEvidence(missingCooldown)[49]
            as Map<String, Object?>)['rssAfterCooldownBytes'] =
        1000000;
    expect(() => _receipt(missingCooldown), throwsA(isA<FormatException>()));
  });

  test('fails closed for every CIN-038 performance budget', () {
    final cases = <String, void Function(Map<String, Object?>)>{
      'lifecycle.cycles': (json) => _lifecycle(json)['cycles'] = 49,
      'lifecycle.maximumActiveDecoders': (json) =>
          _lifecycle(json)['maximumActiveDecoders'] = 2,
      'lifecycle.finalActiveDecoders': (json) =>
          _lifecycle(json)['finalActiveDecoders'] = 1,
      'lifecycle.finalMediaHandles': (json) =>
          _lifecycle(json)['finalMediaHandles'] = 1,
      'lifecycle.terminalReceipts': (json) =>
          _lifecycle(json)['terminalReceipts'] = 49,
      'lifecycle.skippedTerminals': (json) =>
          _lifecycle(json)['skippedTerminals'] = 49,
      'rss.growth': (json) {
        _lifecycle(json)['rssCycle50Bytes'] = 1100001;
        (_cycleEvidence(json)[49]
                as Map<String, Object?>)['rssAfterCooldownBytes'] =
            1100001;
      },
      'cycleEvidence.activeDecoderAfterExit': (json) =>
          (_cycleEvidence(json)[12]
                  as Map<String, Object?>)['activeDecoderAfterExit'] =
              1,
      'skip.p95': (json) =>
          _samples(json)['skipUs'] = List<int>.filled(50, 100000),
      'poster.p95': (json) =>
          _samples(json)['posterUs'] = List<int>.filled(50, 500000),
      'videoFirstFrame.p95': (json) =>
          _samples(json)['videoFirstFrameUs'] = List<int>.filled(50, 1000000),
      'mainIsolateStall.max': (json) =>
          _samples(json)['mainIsolateStallUs'] = <int>[100001],
      'uiFrames.withinBudget': (json) => _samples(json)['uiFrameTotalUs'] =
          <int>[...List<int>.filled(98, 10000), 20000, 20000],
    };

    for (final entry in cases.entries) {
      final measurements = _validMeasurements();
      entry.value(measurements);
      final receipt = _receipt(measurements);
      expect(receipt.passed, isFalse, reason: entry.key);
      expect(receipt.violations, contains(entry.key), reason: entry.key);
    }
  });

  test('rejects tampered derived metrics and verdicts', () {
    final json = _receipt(_validMeasurements()).toJson();
    final metrics = json['metrics']! as Map<String, Object?>;
    final skip = metrics['skip']! as Map<String, Object?>;
    skip['p95Us'] = 1;

    expect(
      () => PresentationRuntimePerformanceReceipt.fromJson(json),
      throwsA(isA<FormatException>()),
    );

    final verdict = _receipt(_validMeasurements()).toJson()
      ..['verdict'] = 'failed';
    expect(
      () => PresentationRuntimePerformanceReceipt.fromJson(verdict),
      throwsA(isA<FormatException>()),
    );
  });
}

PresentationRuntimePerformanceReceipt _receipt(
  Map<String, Object?> measurements,
) => PresentationRuntimePerformanceReceipt.fromMeasurements(
  measurements: measurements,
  platformSupport: _platformSupport(),
  provenance: _provenance(),
);

Map<String, Object?> _lifecycle(Map<String, Object?> json) =>
    json['lifecycle']! as Map<String, Object?>;

Map<String, Object?> _samples(Map<String, Object?> json) =>
    json['samples']! as Map<String, Object?>;

List<Object?> _cycleEvidence(Map<String, Object?> json) =>
    json['cycleEvidence']! as List<Object?>;

Map<String, Object?> _validMeasurements() => <String, Object?>{
  'schemaVersion': 1,
  'benchmark': 'presentation_runtime_cin_038',
  'target':
      'integration_test/presentation_runtime_performance_journey_test.dart',
  'executionMode': 'flutter-profile',
  'platform': 'macos',
  'fixture': <String, Object?>{
    'landscapeVideoAsset': 'assets/certification/intro_landscape_h264_aac.mp4',
    'landscapeVideoSha256':
        '5191da50cdedd4203edc1ccca5e1c3055d7f19c616fb570b0c8af992358fe591',
    'portraitVideoAsset': 'assets/certification/intro_portrait_h264_aac.mp4',
    'portraitVideoSha256':
        'a4759a929512ef967d8a58905f22923e6f15e86707fd7f9100f844880a3972de',
    'posterAsset': 'assets/avelune/artwork/fallback_moonlit_path.webp',
    'posterSha256':
        'd0d048a67dfc9b514d39ec9133ac5c547f5e89c83bde27ba73aa10c75d3a4e10',
  },
  'lifecycle': <String, Object?>{
    'cycles': 50,
    'maximumActiveDecoders': 1,
    'finalActiveDecoders': 0,
    'finalMediaHandles': 0,
    'terminalReceipts': 50,
    'skippedTerminals': 50,
    'rssCycle5Bytes': 1000000,
    'rssCycle50Bytes': 1050000,
  },
  'samples': <String, Object?>{
    'skipUs': List<int>.filled(50, 50000),
    'posterUs': List<int>.filled(50, 200000),
    'videoFirstFrameUs': List<int>.filled(50, 500000),
    'mainIsolateStallUs': List<int>.filled(100, 10000),
    'uiFrameTotalUs': <int>[...List<int>.filled(99, 10000), 20000],
  },
  'cycleEvidence': <Map<String, Object?>>[
    for (var cycle = 1; cycle <= 50; cycle += 1)
      <String, Object?>{
        'cycle': cycle,
        'orientation': cycle.isOdd ? 'landscape' : 'portrait',
        'replay': (cycle + 1) ~/ 2,
        'lifecycle': 'pause-resume',
        'activeDecoderAfterExit': 0,
        'rssAfterCooldownBytes': switch (cycle) {
          5 => 1000000,
          50 => 1050000,
          _ => 1000000,
        },
      },
  ],
};

Map<String, Object?> _platformSupport() => <String, Object?>{
  'schemaVersion': 1,
  'platforms': <String, Object?>{
    'macos': <String, Object?>{'status': 'supported'},
    'ios': <String, Object?>{'status': 'xcode-cloud-target'},
    'android': <String, Object?>{'status': 'build-target'},
    'windows': <String, Object?>{'status': 'build-and-launch-target'},
    'linux': <String, Object?>{'status': 'build-and-launch-target'},
  },
};

Map<String, Object?> _provenance() => <String, Object?>{
  'commit': 'a' * 40,
  'treeState': 'clean',
  'treeFingerprint': 'b' * 64,
  'os': 'macos',
  'osVersion': 'macOS 15',
  'architecture': 'arm64',
  'dartVersion': '3.10.0',
  'flutterVersion': '3.46.0-0.3.pre',
  'flutterRevision': '677d472756f83c14371dd8cc624387065f3d32a7',
  'command': <String>[
    'dart',
    'run',
    'bin/certify_presentation_runtime_performance.dart',
    '--repository-root',
    '../..',
  ],
};
