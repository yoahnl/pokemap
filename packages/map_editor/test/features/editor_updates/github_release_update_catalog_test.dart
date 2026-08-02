import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_catalog.dart';
import 'package:map_editor/src/features/editor_updates/infrastructure/github_release_update_catalog.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  final indexUri = Uri.parse(
    'https://github.com/yoahnl/pokemap/releases/download/'
    'pokemap-editor-update-stable/pokemap-update-index.json',
  );

  GithubReleaseUpdateCatalog catalogFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return GithubReleaseUpdateCatalog(
      client: MockClient(handler),
      indexUri: indexUri,
      requestTimeout: const Duration(seconds: 1),
    );
  }

  test('returns a newer stable release', () async {
    final catalog = catalogFor(
      (_) async => http.Response(_indexJson(version: '0.3.1'), 200),
    );

    final release = await catalog.latestStable(Version.parse('0.3.0'));

    expect(release?.version, Version.parse('0.3.1'));
    expect(release?.tag, 'pokemap-v0.3.1');
    expect(release?.publishedAt, DateTime.utc(2026, 8, 3, 12));
  });

  test('ignores equal and older versions', () async {
    final equal = catalogFor(
      (_) async => http.Response(_indexJson(version: '0.3.0'), 200),
    );
    final older = catalogFor(
      (_) async => http.Response(_indexJson(version: '0.2.9'), 200),
    );

    expect(await equal.latestStable(Version.parse('0.3.0')), isNull);
    expect(await older.latestStable(Version.parse('0.3.0')), isNull);
  });

  test('rejects prereleases on the stable channel', () async {
    final catalog = catalogFor(
      (_) async => http.Response(
        _indexJson(
          version: '0.4.0-beta.1',
          tag: 'pokemap-v0.4.0-beta.1',
        ),
        200,
      ),
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(
        isA<EditorUpdateCatalogException>().having(
          (error) => error.code,
          'code',
          EditorUpdateCatalogFailureCode.invalidVersion,
        ),
      ),
    );
  });

  test('rejects unknown schema and non-stable channels', () async {
    final badSchema = catalogFor(
      (_) async => http.Response(_indexJson(schemaVersion: 2), 200),
    );
    final badChannel = catalogFor(
      (_) async => http.Response(_indexJson(channel: 'beta'), 200),
    );

    await expectLater(
      badSchema.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.invalidSchema)),
    );
    await expectLater(
      badChannel.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.invalidChannel)),
    );
  });

  test('rejects malformed json and mismatched tags', () async {
    final malformed = catalogFor(
      (_) async => http.Response('{', 200),
    );
    final mismatchedTag = catalogFor(
      (_) async => http.Response(
        _indexJson(version: '0.3.1', tag: 'pokemap-v0.3.2'),
        200,
      ),
    );

    await expectLater(
      malformed.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.invalidJson)),
    );
    await expectLater(
      mismatchedTag.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.invalidTag)),
    );
  });

  test('rejects oversized responses before parsing', () async {
    final catalog = GithubReleaseUpdateCatalog(
      client: MockClient(
        (_) async => http.Response(_indexJson(version: '0.3.1'), 200),
      ),
      indexUri: indexUri,
      maxResponseBytes: 32,
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.responseTooLarge)),
    );
  });

  test('rejects release notes outside the trusted repository', () async {
    final catalog = catalogFor(
      (_) async => http.Response(
        _indexJson(
          releaseNotesUrl: 'https://example.com/pokemap-v0.3.1',
        ),
        200,
      ),
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.untrustedUrl)),
    );
  });

  test('rejects a final redirect outside trusted release hosts', () async {
    final catalog = catalogFor(
      (_) async => http.Response(
        _indexJson(),
        200,
        request: http.Request(
          'GET',
          Uri.parse('https://example.com/pokemap-update-index.json'),
        ),
      ),
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.untrustedUrl)),
    );
  });

  test('maps request timeouts to a typed recoverable failure', () async {
    final catalog = GithubReleaseUpdateCatalog(
      client: MockClient((_) => Completer<http.Response>().future),
      indexUri: indexUri,
      requestTimeout: const Duration(milliseconds: 5),
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(_catalogFailure(EditorUpdateCatalogFailureCode.timeout)),
    );
  });

  test('maps non-success status codes without exposing response bodies',
      () async {
    final catalog = catalogFor(
      (_) async => http.Response('secret upstream response', 503),
    );

    await expectLater(
      catalog.latestStable(Version.parse('0.3.0')),
      throwsA(
        isA<EditorUpdateCatalogException>()
            .having(
              (error) => error.code,
              'code',
              EditorUpdateCatalogFailureCode.httpStatus,
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('secret upstream response')),
            ),
      ),
    );
  });

  test('keeps 404, 429 and server status codes distinguishable', () async {
    for (final statusCode in [404, 429, 503]) {
      final catalog = catalogFor(
        (_) async => http.Response('private body', statusCode),
      );

      await expectLater(
        catalog.latestStable(Version.parse('0.3.0')),
        throwsA(
          isA<EditorUpdateCatalogException>().having(
            (error) => error.message,
            'message',
            allOf(contains('$statusCode'), isNot(contains('private body'))),
          ),
        ),
      );
    }
  });
}

Matcher _catalogFailure(EditorUpdateCatalogFailureCode code) {
  return isA<EditorUpdateCatalogException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

String _indexJson({
  int schemaVersion = 1,
  String channel = 'stable',
  String version = '0.3.1',
  String? tag,
  String releaseNotesUrl =
      'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
}) {
  return jsonEncode({
    'schemaVersion': schemaVersion,
    'channel': channel,
    'version': version,
    'tag': tag ?? 'pokemap-v$version',
    'publishedAt': '2026-08-03T12:00:00Z',
    'releaseNotesUrl': releaseNotesUrl,
  });
}
