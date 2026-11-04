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
  late List<String> requestedMediaIds;
  late List<Map<String, Object?>> entries;
  late List<int> bytes;

  Map<String, Object?> entry({
    String kind = 'move-clip',
    String hash = _digest,
    String id = 'bw-local-test',
    String? label,
  }) => {
    'id': id,
    'sha256': hash,
    'contentType': 'audio/mpeg',
    'usage': 'battle',
    'representation': 'audio',
    'style': 'gen5-local-clip',
    'metadata': {
      'label': ?label,
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
    requestedMediaIds = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) async {
      if (['surf', 'double-kick', 'present']
          .any((id) => request.uri.path.endsWith('/owners/move/$id'))) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(entries));
      } else if (request.uri.pathSegments.last.startsWith('bw-local-')) {
        mediaRequests++;
        requestedMediaIds.add(request.uri.pathSegments.last);
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

  test('does not select unrecognized variants or ambiguous generic clips', () async {
    entries = [entry(kind: 'move-variant')];
    expect(await WorkshopMoveAudio(origin: origin).load('surf'), isNull);
    entries = [entry(), entry()];
    expect(await WorkshopMoveAudio(origin: origin).load('surf'), isNull);
    expect(mediaRequests, 0);
  });

  test('chooses the one-hit recording for one multi-hit animation', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-two', label: 'Double Kick 2hits.mp3'),
      entry(kind: 'move-variant', id: 'bw-local-one', label: 'Double Kick 1hit.mp3'),
    ];
    expect(await WorkshopMoveAudio(origin: origin).load('double-kick'),
        Uint8List.fromList(utf8.encode('abc')));
    expect(requestedMediaIds, ['bw-local-one']);
  });

  test('keeps the generic recording ahead of one-hit alternatives', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-one', label: 'Double Kick 1hit.mp3'),
      entry(id: 'bw-local-generic'),
    ];
    expect(await WorkshopMoveAudio(origin: origin).load('double-kick'), isNotNull);
    expect(requestedMediaIds, ['bw-local-generic']);
  });

  test('does not guess if several one-hit recordings are available', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-one', label: 'Double Kick 1hit.mp3'),
      entry(kind: 'move-variant', id: 'bw-local-other', label: 'Double Kick 1hit.mp3'),
    ];
    expect(await WorkshopMoveAudio(origin: origin).load('double-kick'), isNull);
    expect(mediaRequests, 0);
  });

  test('uses the damage recording for the default Present animation', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-heal', label: 'Present heal.mp3'),
      entry(kind: 'move-variant', id: 'bw-local-damage', label: 'Present damage.mp3'),
    ];
    expect(await WorkshopMoveAudio(origin: origin).load('present'), isNotNull);
    expect(requestedMediaIds, ['bw-local-damage']);
  });

  test('uses the heal recording for the healing Present variant', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-damage', label: 'Present damage.mp3'),
      entry(kind: 'move-variant', id: 'bw-local-heal', label: 'Present heal.mp3'),
    ];
    final result = await WorkshopMoveAudio(origin: origin)
        .load('present', sourceVariant: 'Present_Variant1');
    expect(result, isNotNull);
    expect(requestedMediaIds, ['bw-local-heal']);
  });

  test('does not guess the sound of an unknown Present variant', () async {
    entries = [
      entry(kind: 'move-variant', id: 'bw-local-damage', label: 'Present damage.mp3'),
      entry(kind: 'move-variant', id: 'bw-local-heal', label: 'Present heal.mp3'),
    ];
    expect(await WorkshopMoveAudio(origin: origin)
        .load('present', sourceVariant: 'Present_Unknown'), isNull);
    expect(mediaRequests, 0);
  });

  test('returns no audio for unknown moves and invalid identifiers', () async {
    expect(await WorkshopMoveAudio(origin: origin).load('missing'), isNull);
    expect(await WorkshopMoveAudio(origin: origin).load('../surf'), isNull);
    expect(mediaRequests, 0);
  });
}
