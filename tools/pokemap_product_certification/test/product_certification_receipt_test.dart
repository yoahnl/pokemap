import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('receipt is deterministic, redacted and fail-closed', () {
    final receipt = ProductCertificationReceipt(
      runId: 'phase8-neutral-20260725',
      createdAt: DateTime.utc(2026, 7, 25, 12),
      releaseCommit: '9d03e6377ce2',
      gameId: 'games.pokemap.certification.neutral',
      gameVersion: '1.0.0',
      packageSha256: 'a' * 64,
      installedTreeSha256: 'b' * 64,
      evidence: const <ProductCertificationEvidence>[
        ProductCertificationEvidence(
          id: ProductCertificationEvidenceId.neutralGame,
          status: ProductCertificationEvidenceStatus.passed,
          summary: 'Neutral package exported and installed.',
          command: 'flutter test test/neutral_game_package_test.dart',
          resultSha256:
              '1111111111111111111111111111111111111111111111111111111111111111',
        ),
        ProductCertificationEvidence(
          id: ProductCertificationEvidenceId.offlineJourney,
          status: ProductCertificationEvidenceStatus.passed,
          summary: 'Offline journey executed.',
          command: 'flutter test test/offline_save_continue_test.dart',
          resultSha256:
              '2222222222222222222222222222222222222222222222222222222222222222',
        ),
        ProductCertificationEvidence(
          id: ProductCertificationEvidenceId.releaseLifecycle,
          status: ProductCertificationEvidenceStatus.blocked,
          summary: 'Integrated release lifecycle evidence is unavailable.',
          command: null,
          resultSha256: null,
        ),
        ProductCertificationEvidence(
          id: ProductCertificationEvidenceId.killAndPerformance,
          status: ProductCertificationEvidenceStatus.blocked,
          summary: 'Pinned reference-runner evidence is unavailable.',
          command: null,
          resultSha256: null,
        ),
        ProductCertificationEvidence(
          id: ProductCertificationEvidenceId.macosDistribution,
          status: ProductCertificationEvidenceStatus.blocked,
          summary: 'Developer ID Application identity is unavailable.',
          command: null,
          resultSha256: null,
        ),
      ],
    );

    expect(receipt.verdict, ProductCertificationVerdict.noGo);
    expect(receipt.blockingEvidenceIds, <ProductCertificationEvidenceId>[
      ProductCertificationEvidenceId.releaseLifecycle,
      ProductCertificationEvidenceId.killAndPerformance,
      ProductCertificationEvidenceId.macosDistribution,
    ]);
    final encoded = receipt.encodeCanonical();
    expect(encoded, jsonEncode(receipt.toJson()));
    expect(encoded, isNot(contains('/Users/')));
    expect(encoded, isNot(contains('karim')));
    expect(encoded, isNot(contains('Developer ID Application:')));
    expect(
      ProductCertificationReceipt.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      ).encodeCanonical(),
      encoded,
    );
  });

  test('receipt rejects secrets, absolute paths and missing evidence', () {
    ProductCertificationReceipt build(String summary) =>
        ProductCertificationReceipt(
          runId: 'phase8-neutral-20260725',
          createdAt: DateTime.utc(2026, 7, 25),
          releaseCommit: '9d03e6377ce2',
          gameId: 'games.pokemap.certification.neutral',
          gameVersion: '1.0.0',
          packageSha256: 'a' * 64,
          installedTreeSha256: 'b' * 64,
          evidence: <ProductCertificationEvidence>[
            for (final id in ProductCertificationEvidenceId.values)
              ProductCertificationEvidence(
                id: id,
                status: ProductCertificationEvidenceStatus.passed,
                summary: id == ProductCertificationEvidenceId.neutralGame
                    ? summary
                    : 'Passed.',
                command: 'flutter test test/evidence.dart',
                resultSha256: 'a' * 64,
              ),
          ],
        );

    expect(
      () => build('/Users/example/package.avelunegame'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => build('NOTARY_PASSWORD=secret'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => build('apiKey: sk-examplecredential'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => build('Authorization: Bearer abcdefghijklmnop'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => build('Evidence: file:///Users/example/result.json'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => build(r'Evidence: C:\Users\example\result.json'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => ProductCertificationReceipt(
        runId: 'phase8-neutral-20260725',
        createdAt: DateTime.utc(2026, 7, 25),
        releaseCommit: '9d03e6377ce2',
        gameId: 'games.pokemap.certification.neutral',
        gameVersion: '1.0.0',
        packageSha256: 'a' * 64,
        installedTreeSha256: 'b' * 64,
        evidence: const <ProductCertificationEvidence>[],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
