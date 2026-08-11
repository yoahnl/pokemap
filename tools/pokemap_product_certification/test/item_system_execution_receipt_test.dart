import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  group('ItemSystemExecutionReceipt', () {
    test('computes its digest from a canonical payload', () {
      final receipt = _completeReceipt(
        payload: <String, Object?>{
          'z': <Object?>[2, 1],
          'a': <String, Object?>{'second': true, 'first': 'value'},
        },
      );
      final expectedPayload = jsonEncode(<String, Object?>{
        'a': <String, Object?>{'first': 'value', 'second': true},
        'z': <Object?>[2, 1],
      });

      expect(
        receipt.payloadSha256,
        sha256.convert(utf8.encode(expectedPayload)).toString(),
      );
      expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
      expect(receipt.toJson().values, isNot(contains('CERTIFIED')));
    });

    test('round-trips only when revision and payload still match', () {
      final source = _completeReceipt();
      final decoded = ItemSystemExecutionReceipt.fromJson(
        source.toJson(),
        expectedSourceRevision: _revision,
      );

      expect(decoded.toJson(), source.toJson());

      final forgedDigest = source.toJson()..['payloadSha256'] = _sha('forged');
      expect(
        () => ItemSystemExecutionReceipt.fromJson(
          forgedDigest,
          expectedSourceRevision: _revision,
        ),
        throwsFormatException,
      );
      expect(
        () => ItemSystemExecutionReceipt.fromJson(
          source.toJson(),
          expectedSourceRevision: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate unknown and non-executed capabilities', () {
      final source = _completeReceipt().toJson();
      final duplicate = Map<String, Object?>.from(source)
        ..['attemptedCapabilities'] = <String>[
          'bag_schema',
          'bag_schema',
          'catalog_schema',
          'legacy_rejection',
          'save_schema',
        ];
      final unknown = Map<String, Object?>.from(source)
        ..['attemptedCapabilities'] = <String>[
          'bag_schema',
          'catalog_schema',
          'legacy_rejection',
          'save_schema',
          'synthetic_success',
        ]
        ..['succeededCapabilities'] = <String>[
          'bag_schema',
          'catalog_schema',
          'legacy_rejection',
          'save_schema',
          'synthetic_success',
        ];
      final nonExecuted = Map<String, Object?>.from(source)
        ..['attemptedCapabilities'] = <String>[
          'bag_schema',
          'catalog_schema',
          'legacy_rejection',
        ];

      for (final invalid in <Map<String, Object?>>[
        duplicate,
        unknown,
        nonExecuted,
      ]) {
        expect(
          () => ItemSystemExecutionReceipt.fromJson(
            invalid,
            expectedSourceRevision: _revision,
          ),
          throwsFormatException,
        );
      }
    });

    test('derives partial and failed verdicts from observed outcomes', () {
      final partial = ItemSystemExecutionReceipt.record(
        level: ItemSystemProofLevel.schemaL0,
        sourceRevision: _revision,
        fixtureSha256: _sha('fixture'),
        payload: const <String, Object?>{'observed': 'catalog'},
        attemptedCapabilities: const <String>{'catalog_schema'},
        succeededCapabilities: const <String>{'catalog_schema'},
        producer: 'schema-collector',
        runnerVersion: '1.0.0',
        recordedAtUtc: DateTime.utc(2026, 8, 12),
      );
      final failed = ItemSystemExecutionReceipt.record(
        level: ItemSystemProofLevel.schemaL0,
        sourceRevision: _revision,
        fixtureSha256: _sha('fixture'),
        payload: const <String, Object?>{'observed': 'catalog'},
        attemptedCapabilities: const <String>{'catalog_schema'},
        succeededCapabilities: const <String>{},
        failedCapabilities: const <String>{'catalog_schema'},
        producer: 'schema-collector',
        runnerVersion: '1.0.0',
        recordedAtUtc: DateTime.utc(2026, 8, 12),
      );

      expect(partial.verdict, ItemSystemExecutionVerdict.partial);
      expect(failed.verdict, ItemSystemExecutionVerdict.failed);
    });
  });
}

ItemSystemExecutionReceipt _completeReceipt({
  Map<String, Object?> payload = const <String, Object?>{'observed': true},
}) {
  final capabilities = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
    ItemSystemProofLevel.schemaL0,
  );
  return ItemSystemExecutionReceipt.record(
    level: ItemSystemProofLevel.schemaL0,
    sourceRevision: _revision,
    fixtureSha256: _sha('fixture'),
    payload: payload,
    attemptedCapabilities: capabilities,
    succeededCapabilities: capabilities,
    producer: 'schema-collector',
    runnerVersion: '1.0.0',
    recordedAtUtc: DateTime.utc(2026, 8, 12),
  );
}

String _sha(String value) => sha256.convert(utf8.encode(value)).toString();

const _revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
