import 'dart:async';
import 'dart:convert';

import 'package:avelune_converter/updates/converter_update_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object> updateIndex({String version = '0.2.0', int build = 2}) => {
  'schemaVersion': 1,
  'product': 'avelune-converter',
  'bundleId': 'com.yoahnl.avelune.converter',
  'channel': 'stable',
  'version': version,
  'buildNumber': build,
  'revision': 'a' * 40,
  'tag': 'avelune-converter-v$version',
  'releaseNotesUrl':
      'https://github.com/yoahnl/pokemap/releases/tag/avelune-converter-v$version',
};

void main() {
  const installed = ConverterInstalledBuild(version: '0.1.0', buildNumber: 1);
  test(
    'Converter checks its isolated channel and retains release provenance',
    () async {
      final client = MockClient((request) async {
        expect(request.url, ConverterUpdateCatalog.indexUri);
        return http.Response(jsonEncode(updateIndex()), 200);
      });
      addTearDown(client.close);
      final result = await ConverterUpdateCatalog(client).check(installed);
      expect(result.status, ConverterUpdateStatus.available);
      expect(result.release!.version, '0.2.0');
      expect(result.release!.buildNumber, 2);
      expect(result.release!.revision, 'a' * 40);
    },
  );

  test(
    'version precedence and build numbers never offer a downgrade',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(updateIndex(version: '0.1.0', build: 2)),
          200,
        ),
      );
      addTearDown(client.close);
      final catalog = ConverterUpdateCatalog(client);
      expect(
        (await catalog.check(installed)).status,
        ConverterUpdateStatus.available,
      );
      for (final build in [
        const ConverterInstalledBuild(version: '0.1.0', buildNumber: 2),
        const ConverterInstalledBuild(version: '0.1.0', buildNumber: 3),
        const ConverterInstalledBuild(version: '0.2.0', buildNumber: 1),
      ]) {
        expect(
          (await catalog.check(build)).status,
          ConverterUpdateStatus.current,
        );
      }
      expect(
        (await catalog.check(
          const ConverterInstalledBuild(version: '0.1.0-dev.1', buildNumber: 9),
        )).status,
        ConverterUpdateStatus.available,
      );
    },
  );

  test('an unpublished first feed is never reported as up to date', () async {
    final client = MockClient((_) async => http.Response('', 404));
    addTearDown(client.close);
    final result = await ConverterUpdateCatalog(client).check(installed);
    expect(result.status, ConverterUpdateStatus.unpublished);
    expect(result.release, isNull);
  });

  test(
    'invalid installed provenance never checks a different product',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(updateIndex()), 200);
      });
      addTearDown(client.close);
      for (final build in [
        const ConverterInstalledBuild(version: 'invalid', buildNumber: 1),
        const ConverterInstalledBuild(version: '0.1.0', buildNumber: 0),
        const ConverterInstalledBuild(
          version: '0.1.0',
          buildNumber: 1,
          bundleId: 'com.yoahnl.pokemap.editor',
        ),
      ]) {
        await expectLater(
          ConverterUpdateCatalog(client).check(build),
          throwsFormatException,
        );
      }
      expect(requests, 0);
    },
  );

  for (final change in <Map<String, Object>>[
    {'product': 'avelune-studio'},
    {'bundleId': 'com.yoahnl.pokemap.editor'},
    {'tag': 'pokemap-v0.2.0'},
    {'releaseNotesUrl': 'https://example.com/update'},
    {
      'releaseNotesUrl': 'https://github.com/yoahnl/pokemap/releases/tag/avelune-converter-v0.2.0?x=1',
    },
    {'revision': 'not-a-revision'},
    {'buildNumber': -1},
    {'version': '0.2.0-beta.1'},
  ]) {
    test('rejects an untrusted or incomplete index $change', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({...updateIndex(), ...change}), 200),
      );
      addTearDown(client.close);
      await expectLater(
        ConverterUpdateCatalog(client).check(installed),
        throwsFormatException,
      );
    });
  }

  test('bounds streamed bytes before decoding the index', () async {
    final client = MockClient.streaming(
      (_, _) async =>
          http.StreamedResponse(Stream.value(List.filled(65537, 32)), 200),
    );
    addTearDown(client.close);
    await expectLater(
      ConverterUpdateCatalog(client).check(installed),
      throwsFormatException,
    );
  });

  test('aborts a stalled HTTP request within the configured timeout', () async {
    final stopped = Completer<void>();
    final client = MockClient.streaming((request, _) async {
      expect(request, isA<http.AbortableRequest>());
      unawaited(
        (request as http.AbortableRequest).abortTrigger!.then((_) {
          stopped.complete();
        }),
      );
      return Completer<http.StreamedResponse>().future;
    });
    addTearDown(client.close);
    await expectLater(
      ConverterUpdateCatalog(
        client,
        timeout: const Duration(milliseconds: 10),
      ).check(installed),
      throwsA(isA<TimeoutException>()),
    );
    await stopped.future;
  });
}
