import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  const codec = GamePackageInstallRequestCodec();
  final request = GamePackageInstallRequest(
    requestId: 'export-20260725-0001',
    packageFileName: 'export-20260725-0001.pokemapgame',
    packageSha256:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    createdAt: DateTime.utc(2026, 7, 25, 8, 30),
  );

  test('round-trips a canonical relative install request', () {
    final bytes = codec.encodeCanonicalUtf8(request);
    final decoded = codec.decodeUtf8(bytes);

    expect(decoded, request);
    expect(
      utf8.decode(bytes),
      '{"createdAt":"2026-07-25T08:30:00.000Z",'
      '"packageFileName":"export-20260725-0001.pokemapgame",'
      '"packageSha256":"0123456789abcdef0123456789abcdef'
      '0123456789abcdef0123456789abcdef",'
      '"requestId":"export-20260725-0001","schemaVersion":1}',
    );
  });

  test('rejects traversal, unknown fields and non-canonical JSON', () {
    final base = request.toJson();
    for (final invalid in <Map<String, Object?>>[
      <String, Object?>{
        ...base,
        'packageFileName': '../game.pokemapgame',
      },
      <String, Object?>{
        ...base,
        'packageFileName': '/tmp/game.pokemapgame',
      },
      <String, Object?>{...base, 'packageSha256': 'not-a-digest'},
      <String, Object?>{...base, 'requestId': 'UPPER CASE'},
      <String, Object?>{...base, 'createdAt': '2026-07-25T10:30:00+02:00'},
      <String, Object?>{...base, 'executable': true},
    ]) {
      expect(
        () => codec.decodeJson(invalid),
        throwsA(isA<GamePackageFormatException>()),
        reason: invalid.toString(),
      );
    }
    expect(
      () => codec.decodeUtf8(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(base)),
      ),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'nonCanonicalInstallRequest',
        ),
      ),
    );
  });
}
