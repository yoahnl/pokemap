import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageInstallReceiptCodec', () {
    const codec = GamePackageInstallReceiptCodec();
    final receipt = GamePackageInstallReceipt(
      receiptFormat: 1,
      securityPolicyVersion: 1,
      gameId: 'games.example.receipt',
      gameVersion: Version.parse('1.2.3'),
      treeSha256: 'a' * 64,
      manifestSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      validatedAt: DateTime.utc(2026, 7, 25, 10, 29),
      installedAt: DateTime.utc(2026, 7, 25, 10, 30),
      source: GamePackageInstallSource.localFile,
      signatureStatus: PackageSignatureStatus.notPresent,
      validation: const GamePackageInstallValidation(
        compatibility: GamePackageInstallCompatibility.accept,
      ),
    );

    test('round-trips a canonical durable receipt', () {
      final bytes = codec.encodeCanonicalUtf8(receipt);
      final decoded = codec.decodeUtf8(bytes);

      expect(decoded.toJson(), receipt.toJson());
      expect(decoded.installedAt.isUtc, isTrue);
    });

    test('rejects unknown, future, and malformed receipt values', () {
      final unknown = receipt.toJson()..['future'] = true;
      _expectCode(() => codec.decodeJson(unknown), 'unknownField');

      final future = receipt.toJson()..['receiptFormat'] = 2;
      _expectCode(() => codec.decodeJson(future), 'unsupportedReceiptFormat');

      final localTime = receipt.toJson()
        ..['installedAt'] = '2026-07-25T10:30:00+02:00';
      _expectCode(() => codec.decodeJson(localTime), 'invalidInstalledAt');

      final normalizedInvalidDate = receipt.toJson()
        ..['installedAt'] = '2026-02-30T10:00:00.000Z';
      _expectCode(
        () => codec.decodeJson(normalizedInvalidDate),
        'invalidInstalledAt',
      );

      final untrustedCatalog = receipt.toJson()..['source'] = 'publicCatalog';
      _expectCode(
        () => codec.decodeJson(untrustedCatalog),
        'invalidReceiptTrust',
      );

      final failedGate = receipt.toJson();
      (failedGate['validation']! as Map<String, Object?>)['loadSmoke'] =
          'failed';
      _expectCode(
        () => codec.decodeJson(failedGate),
        'invalidReceiptValidation',
      );

      final invalidDates = receipt.toJson()
        ..['validatedAt'] = '2026-07-25T10:31:00.000Z';
      _expectCode(() => codec.decodeJson(invalidDates), 'invalidReceiptDates');
    });
  });
}

void _expectCode(void Function() operation, String code) {
  expect(
    operation,
    throwsA(
      isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', code),
    ),
  );
}
