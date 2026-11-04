import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_attack_compare/workshop_move_audio.dart';
import 'package:flutter_test/flutter_test.dart';

const _digest =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

void main() {
  late HttpServer server;
  late Uri origin;
  var mediaRequests = 0;
  late List<Map<String, Object?>> entries;
  late List<int> bytes;

  Map<String, Object?> entry({
    String kind = 'move-clip',
    String hash = _digest,
  }) => {
    'id': 'bw-local-test',
    'sha256': hash,
    'contentType': 'audio/mpeg',
    'usage': 'battle',
    'representation': 'audio',
    'style': 'gen5-local-clip',
    'metadata': {
      'provenance': {
        'kind': kind,
        'file': {'size': 3},
      },
    },
  };

  setUp(() async {
    entries = [entry()];
    bytes = utf8.encode('abc');
    mediaRequests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) async {
      if (request.uri.path.endsWith('/owners/move/surf')) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(entries));
      } else if (request.uri.path.endsWith('/bw-local-test')) {
        mediaRequests++;
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        request.response.add(bytes);
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  test('loads the unique generic move clip and verifies its bytes', () async {
    final result = await WorkshopMoveAudio(origin: origin).load('surf');
    expect(result, Uint8List.fromList(utf8.encode('abc')));
    expect(mediaRequests, 1);
  });

  test('rejects altered bytes', () async {
    bytes = utf8.encode('bad');
    expect(await WorkshopMoveAudio(origin: origin).load('surf'), isNull);
  });

  test('does not select variants or ambiguous generic clips', () async {
    entries = [entry(kind: 'move-variant')];
    expect(await WorkshopMoveAudio(origin: origin).load('surf'), isNull);
    entries = [entry(), entry()];
    expect(await WorkshopMoveAudio(origin: origin).load('surf'), isNull);
    expect(mediaRequests, 0);
  });

  test('returns no audio for unknown moves and invalid identifiers', () async {
    expect(await WorkshopMoveAudio(origin: origin).load('missing'), isNull);
    expect(await WorkshopMoveAudio(origin: origin).load('../surf'), isNull);
    expect(mediaRequests, 0);
  });
}
