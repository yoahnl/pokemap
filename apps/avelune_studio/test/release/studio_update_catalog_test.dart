import 'dart:convert';

import 'package:avelune_studio/features/updates/studio_update_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, Object> index({
    String version = '0.3.8',
    String? tag,
    String? notes,
  }) {
    final releaseTag = tag ?? 'pokemap-v$version';
    return {
      'schemaVersion': 1,
      'channel': 'stable',
      'version': version,
      'tag': releaseTag,
      'publishedAt': '2026-09-27T12:00:00.000Z',
      'releaseNotesUrl':
          notes ?? 'https://github.com/yoahnl/pokemap/releases/tag/$releaseTag',
    };
  }

  test('offers the Studio migration to an installed PokeMap version', () async {
    final client = MockClient((request) async {
      expect(request.url, StudioUpdateCatalog.indexUri);
      return http.Response(jsonEncode(index()), 200);
    });

    final release = await StudioUpdateCatalog(client).newerThan('0.3.7');

    expect(release?.version, '0.3.8');
    expect(
      release?.notesUri.toString(),
      'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.8',
    );
    client.close();
  });

  test('does not offer the installed or an older release', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(index()), 200),
    );
    final catalog = StudioUpdateCatalog(client);

    expect(await catalog.newerThan('0.3.8'), isNull);
    expect(await catalog.newerThan('0.3.9'), isNull);
    client.close();
  });

  test('rejects a release that leaves the signed legacy channel', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(index(tag: 'avelune-v0.3.8')), 200),
    );

    await expectLater(
      StudioUpdateCatalog(client).newerThan('0.3.7'),
      throwsA(isA<FormatException>()),
    );
    client.close();
  });

  test('rejects release notes outside the trusted repository', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode(index(notes: 'https://example.com/download')),
        200,
      ),
    );

    await expectLater(
      StudioUpdateCatalog(client).newerThan('0.3.7'),
      throwsA(isA<FormatException>()),
    );
    client.close();
  });
}
