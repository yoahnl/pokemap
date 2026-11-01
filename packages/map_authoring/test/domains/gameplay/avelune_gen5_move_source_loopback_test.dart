import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

final class _LoopbackTransport implements PokemonBoundedExternalHttpTransport {
  _LoopbackTransport(this.origin) {
    if (origin.scheme != 'http' ||
        !{'127.0.0.1', 'localhost', '::1'}.contains(origin.host) ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError('Test origin must be loopback HTTP');
    }
  }

  final Uri origin;
  final HttpClient _client = HttpClient();
  final List<Uri> requests = [];

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    requests.add(uri);
    final destination = origin.replace(path: uri.path, query: uri.query);
    final request = await _client.getUrl(destination).timeout(timeout);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });
    final bytes = await collectPokemonExternalBytes(
      response,
      maximumBytes: maximumBytes,
      timeout: timeout,
    );
    return PokemonExternalHttpResponse(
      statusCode: response.statusCode,
      headers: responseHeaders,
      body: '',
      bodyBytes: bytes,
    );
  }

  void close() => _client.close(force: true);
}

void main() {
  final origin = Platform.environment['AVELUNE_GEN5_MOVE_TEST_ORIGIN'];
  final release = Platform.environment['AVELUNE_GEN5_MOVE_TEST_RELEASE'];
  final configured = origin != null &&
      origin.isNotEmpty &&
      release != null &&
      release.isNotEmpty;

  test(
    'reads the real local API snapshot and refuses incomplete conversion',
    () async {
      final transport = _LoopbackTransport(Uri.parse(origin!));
      addTearDown(transport.close);
      final source = AveluneGen5MoveSource(
        client: transport,
        baseUri: 'https://source-test.invalid/v1/snapshots',
        release: release!,
      );
      final snapshot =
          await source.fetch(moveId: 'flamethrower', sourceMoveId: 53);
      expect(transport.requests.single.path,
          '/v1/snapshots/$release/gen5-move/53');
      expect(snapshot, isNotNull);
      final diagnostic = snapshot!.diagnostic;
      expect(diagnostic.sourceRevision,
          '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c');
      expect(diagnostic.scriptSha256,
          '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9');
      expect(diagnostic.particleSha256,
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9');
      expect(diagnostic.textureSha256ByName, {
        'texture00':
            'd03979b4d9e7cc4146cd28313006fc7e770e8aa83c8bffb06797f8cb5076bab1',
        'texture01':
            'a3dbf0ea435572f668f8ba2beb676587036035fdb6989a4583605dfa68d9e06e',
        'texture02':
            '3d10133124483c7c68bf8ef9df9e50d8a2bab9ed4c0f9882b5291ce8bc96260f',
        'texture03':
            '3eee20e4f1adbc946d4623f42fe12203fcd4919ec23988aa8fb2b932203bf137',
        'texture04':
            'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
        'texture05':
            '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
      });
      expect(diagnostic.emitterOrder, [0, 1, 3, 2]);
      expect(diagnostic.requiredTextures, hasLength(6));
      expect(diagnostic.missingTextures, isEmpty);
      expect(diagnostic.soundReferences, hasLength(6));
      expect(
          diagnostic.blockers, contains(Gen5BattleSourceBlocker.soundPlayback));
      expect(diagnostic.requireConvertible, throwsStateError);
      expect(snapshot.redistributionStatus, 'unverified');
      expect(snapshot.playbackStatus, 'not-supported');
    },
    skip: configured
        ? false
        : 'Requires an isolated local Gen 5 move API fixture',
  );
}
