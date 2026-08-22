import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-084 — the hold receipt refuses every shape of false green.
///
/// The ticket names its own main risk: "fausse certification sur fakes". A hold
/// that decodes nothing answers instantly, a run with 3 cycles never warms up,
/// and a leaked timer is invisible unless something counts it. So these tests
/// are almost all negative: each one is a way a run could look certified while
/// proving nothing, and each must be refused with a message naming the path.
void main() {
  test('a complete measurement is certified', () {
    final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
      measurements: _measurements(),
      provenance: _provenance(),
    );

    expect(receipt.passed, isTrue, reason: receipt.violations.toString());
    expect(receipt.platform, 'macos');
    expect(receipt.violations, isEmpty);
    // The budget it was judged against travels with the verdict, so a later
    // reader can tell a pass under a loosened budget from a real one.
    expect(receipt.toJson()['budgets'], isA<Map<String, Object?>>());
  });

  group('a substitute media stack is refused outright', () {
    for (final substitute in const <String>[
      'FakeVideoDecoder',
      'StubDecoder',
      'MockPlatformDecoder',
      'NoopDecoder',
      'NullDecoder',
      'DummyDecoder',
    ]) {
      test('$substitute cannot certify a hold', () {
        expect(
          () => PresentationHoldPerformanceReceipt.fromMeasurements(
            measurements: _measurements(decoder: substitute),
            provenance: _provenance(),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('substitute'),
            ),
          ),
        );
      });
    }

    test('a decoder that decoded no frame is refused', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(decodedVideoFrames: 0),
          provenance: _provenance(),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a run that rendered no caption is refused', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(renderedCaptionCues: 0),
          provenance: _provenance(),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a residual resource fails the receipt, per exit and per resource', () {
    for (final reason in PresentationHoldPerformanceReceipt.exitReasons) {
      for (final resource
          in PresentationHoldPerformanceReceipt.residualResources) {
        test('$reason leaking $resource is a named violation', () {
          final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
            measurements: _measurements(
              residual: (reason: reason, resource: resource, count: 1),
            ),
            provenance: _provenance(),
          );

          expect(receipt.passed, isFalse);
          expect(receipt.violations, <String>['teardown.$reason.$resource']);
        });
      }
    }

    test('the two resources CIN-038 cannot see are among them', () {
      expect(
        PresentationHoldPerformanceReceipt.residualResources,
        containsAll(<String>['activeTimers', 'activeSubscriptions']),
      );
    });
  });

  group('a run that did not really run is refused', () {
    test('fewer than fifty cycles', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(cycles: 3),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('holdCycles'),
          ),
        ),
      );
    });

    test('an input that was never answered', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(answeredInputs: 49),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('never held'),
          ),
        ),
      );
    });

    test('a single orientation', () {
      final measurements = _measurements();
      (measurements['orientations']! as Map<String, Object?>)
          .remove('portrait');
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: measurements,
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('portrait'),
          ),
        ),
      );
    });

    test('a dirty tree', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(),
          provenance: _provenance(treeState: 'dirty'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a platform is judged against its own budget or not at all', () {
    test('an undeclared platform is refused rather than averaged', () {
      expect(
        () => PresentationHoldPerformanceReceipt.fromMeasurements(
          measurements: _measurements(platform: 'ios'),
          provenance: _provenance(),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('another platform average'),
          ),
        ),
      );
    });

    test('a slow hold is a violation, not a rejection', () {
      final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
        measurements: _measurements(inputToDisplayUs: 400000),
        provenance: _provenance(),
      );

      expect(receipt.passed, isFalse);
      expect(
        receipt.violations,
        containsAll(<String>[
          'landscape.inputToDisplay.p95',
          'portrait.inputToDisplay.p95',
        ]),
        reason: 'both orientations are judged separately',
      );
    });

    test('resident memory that keeps growing is a violation', () {
      final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
        measurements: _measurements(rssAfterCycle50Bytes: 900 * 1024 * 1024),
        provenance: _provenance(),
      );

      expect(receipt.violations, contains('memory.rssGrowth'));
    });
  });

  test('the receipt round-trips through JSON', () {
    final receipt = PresentationHoldPerformanceReceipt.fromMeasurements(
      measurements: _measurements(),
      provenance: _provenance(),
    );
    final restored = PresentationHoldPerformanceReceipt.fromJson(
      receipt.toJson(),
    );

    expect(restored.toJson(), receipt.toJson());
    expect(restored.passed, isTrue);
  });
}

Map<String, Object?> _measurements({
  String platform = 'macos',
  String decoder = 'AVFoundationVideoDecoder',
  int decodedVideoFrames = 3120,
  int renderedCaptionCues = 100,
  int cycles = 50,
  int? answeredInputs,
  int inputToDisplayUs = 42000,
  int inputToResumeUs = 61000,
  int slowFrames = 1,
  int rssAfterCycle50Bytes = 214 * 1024 * 1024,
  ({String reason, String resource, int count})? residual,
}) {
  Map<String, Object?> orientation() => <String, Object?>{
        'holdCycles': cycles,
        'answeredInputs': answeredInputs ?? cycles,
        'inputToDisplayUs': <int>[
          for (var index = 0; index < cycles; index += 1)
            inputToDisplayUs + index,
        ],
        'inputToResumeUs': <int>[
          for (var index = 0; index < cycles; index += 1)
            inputToResumeUs + index,
        ],
        'slowFrames': slowFrames,
      };

  return <String, Object?>{
    'schemaVersion': 1,
    'benchmark': 'presentation_hold_cin_084',
    'target':
        'integration_test/presentation_hold_performance_journey_test.dart',
    'executionMode': 'flutter-profile',
    'platform': platform,
    'mediaPipeline': <String, Object?>{
      'decoderImplementation': decoder,
      'audioSinkImplementation': 'CoreAudioSink',
      'decodedVideoFrames': decodedVideoFrames,
      'renderedCaptionCues': renderedCaptionCues,
    },
    'orientations': <String, Object?>{
      'landscape': orientation(),
      'portrait': orientation(),
    },
    'teardown': <String, Object?>{
      for (final reason in PresentationHoldPerformanceReceipt.exitReasons)
        reason: <String, Object?>{
          for (final resource
              in PresentationHoldPerformanceReceipt.residualResources)
            resource: residual != null &&
                    residual.reason == reason &&
                    residual.resource == resource
                ? residual.count
                : 0,
        },
    },
    'memory': <String, Object?>{
      'rssAfterCycle5Bytes': 198 * 1024 * 1024,
      'rssAfterCycle50Bytes': rssAfterCycle50Bytes,
    },
  };
}

Map<String, Object?> _provenance({String treeState = 'clean'}) =>
    <String, Object?>{
      'commit': '0123456789abcdef0123456789abcdef01234567',
      'treeState': treeState,
      'os': 'macos 27.0.0',
      'device': 'macOS desktop',
      'flutterVersion': '3.46.0-0.3.pre',
      'recordedAtUtc': '2026-08-22T00:00:00.000Z',
    };
