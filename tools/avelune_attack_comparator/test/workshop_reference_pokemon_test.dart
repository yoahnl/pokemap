import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_attack_compare/workshop_reference_pokemon.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps reference URLs to the documented attackers and targets', () async {
    final doc = jsonDecode(
      await File('assets/bw2/reference_pokemon.json').readAsString(),
    ) as Map<String, dynamic>;
    final references = doc['references'] as Map<String, dynamic>;
    expect(references, hasLength(559));
    expect(
      referencePokemonForUrl(references,
          'https://archives.bulbagarden.net/media/upload/5/5d/Dig_V.png'),
      (attacker: 'dugtrio', target: 'jigglypuff'),
    );
    expect(
      referencePokemonForUrl(references,
          'https://archives.bulbagarden.net/media/upload/d/d4/Surf_V.png?replay=1'),
      (attacker: 'herdier', target: 'trubbish'),
    );
    expect(referencePokemonForUrl(references, null), isNull);
    expect(referencePokemonForUrl({'bad.png': ['../secret', 'pidgey']},
        'https://example.org/bad.png'), isNull);
  });

  final qaRoot = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
  group('reference sprites from the private API', () {
    late Directory root;
    late HttpServer server;
    late WorkshopReferencePokemonStore store;
    late Map<String, int> requests;
    late bool corruptAnimated;
    late bool unavailable;
    late bool unavailableNames;
    Completer<void>? responseGate;
    Completer<void>? requestArrived;
    final gif = base64Decode(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAAAAAAALAAAAAABAAEAAAIBRAA7',
    );
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+nr1sAAAAASUVORK5CYII=',
    );

    setUp(() async {
      root = await Directory(qaRoot!).createTemp('reference-pokemon-');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      requests = {};
      corruptAnimated = false;
      unavailable = false;
      unavailableNames = false;
      responseGate = null;
      requestArrived = null;
      server.listen((request) async {
        final path = request.uri.path;
        requests[path] = (requests[path] ?? 0) + 1;
        if (path.contains('/releases/')) {
          if (unavailableNames) {
            request.response.statusCode = HttpStatus.serviceUnavailable;
            await request.response.close();
            return;
          }
          final id = request.uri.pathSegments.last;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'names': {'fr': switch (id) {
            'dugtrio' => 'Triopikeur',
            'jigglypuff' => 'Rondoudou',
            _ => id,
          }}}));
        } else if (path.contains('/media/')) {
          if (responseGate case final gate?) {
            if (requestArrived case final arrived?) {
              if (!arrived.isCompleted) arrived.complete();
            }
            await gate.future;
          }
          if (unavailable) {
            request.response.statusCode = HttpStatus.notFound;
          } else {
            final animated = path.endsWith('-animated');
            final bytes = animated ? gif : png;
            request.response.headers.contentType = ContentType.parse(
              animated ? 'image/gif' : 'image/png',
            );
            request.response.headers.set(HttpHeaders.etagHeader,
              '"sha256-${corruptAnimated && animated ? '0' * 64 : sha256.convert(bytes)}"');
            request.response.add(bytes);
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      store = WorkshopReferencePokemonStore(
        root: root,
        origin: Uri.parse('http://${server.address.address}:${server.port}'),
      );
    });

    tearDown(() async {
      if (responseGate case final gate?) {
        if (!gate.isCompleted) gate.complete();
      }
      await server.close(force: true);
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('loads both GIFs, preserves existing media and reuses local files', () async {
      final existing = File('${root.path}/data/pokemon/media/dugtrio.json');
      await existing.parent.create(recursive: true);
      await existing.writeAsString(jsonEncode({
        'speciesId': 'dugtrio', 'defaultFormId': 'base',
        'variants': {'base': {'icon': 'assets/icon.png'}},
      }));
      const pair = (attacker: 'dugtrio', target: 'jigglypuff');
      final result = await store.prepare(pair);
      expect(result?.attacker, (id: 'dugtrio', name: 'Triopikeur'));
      expect(result?.target, (id: 'jigglypuff', name: 'Rondoudou'));
      final doc = jsonDecode(await existing.readAsString()) as Map;
      expect((doc['variants'] as Map)['base']['icon'], 'assets/icon.png');
      expect((doc['variants'] as Map)['base']['backAnimated'],
          'assets/pokemon/comparator/dugtrio-back.gif');
      expect(await File('${root.path}/assets/pokemon/comparator/dugtrio-back.gif')
          .readAsBytes(), gif);
      expect(await File('${root.path}/assets/pokemon/comparator/jigglypuff-front.gif')
          .readAsBytes(), gif);
      final count = requests.values.fold<int>(0, (a, b) => a + b);
      expect(await store.prepare(pair), result);
      expect(requests.values.fold<int>(0, (a, b) => a + b), count);
    });

    test('falls back to a checked static sprite if the GIF is corrupt', () async {
      corruptAnimated = true;
      final result = await store.prepare((attacker: 'dugtrio', target: 'jigglypuff'));
      expect(result, isNotNull);
      final doc = jsonDecode(await File('${root.path}/data/pokemon/media/dugtrio.json')
          .readAsString()) as Map;
      expect((doc['variants'] as Map)['base']['backStatic'],
          'assets/pokemon/comparator/dugtrio-back.png');
      expect(await File('${root.path}/assets/pokemon/comparator/dugtrio-back.gif')
          .exists(), isFalse);
      corruptAnimated = false;
      expect(await store.prepare((attacker: 'dugtrio', target: 'jigglypuff')), isNotNull);
      final retried = jsonDecode(await File('${root.path}/data/pokemon/media/dugtrio.json')
          .readAsString()) as Map;
      expect((retried['variants'] as Map)['base']['backAnimated'],
          'assets/pokemon/comparator/dugtrio-back.gif');
    });

    test('keeps both views when the same species appears on both sides', () async {
      const pair = (attacker: 'ditto', target: 'ditto');
      final results = await Future.wait([store.prepare(pair), store.prepare(pair)]);
      expect(results.every((value) => value != null), isTrue);
      final doc = jsonDecode(await File('${root.path}/data/pokemon/media/ditto.json')
          .readAsString()) as Map;
      final base = (doc['variants'] as Map)['base'] as Map;
      expect(base['backAnimated'], 'assets/pokemon/comparator/ditto-back.gif');
      expect(base['frontAnimated'], 'assets/pokemon/comparator/ditto-front.gif');
    });

    test('returns no pair if a media is unavailable or the request is obsolete', () async {
      unavailable = true;
      expect(await store.prepare((attacker: 'dugtrio', target: 'jigglypuff')), isNull);
      final before = requests.values.fold<int>(0, (a, b) => a + b);
      expect(await store.prepare((attacker: 'dugtrio', target: 'jigglypuff'),
          isCurrent: () => false), isNull);
      expect(requests.values.fold<int>(0, (a, b) => a + b), before);
      expect(await File('${root.path}/data/pokemon/media/dugtrio.json').exists(), isFalse);
    });

    test('retries temporary failures rather than caching missing data', () async {
      const pair = (attacker: 'dugtrio', target: 'jigglypuff');
      unavailable = true;
      unavailableNames = true;
      expect(await store.prepare(pair), isNull);
      unavailable = false;
      final withoutNames = await store.prepare(pair);
      expect(withoutNames?.attacker.name, 'dugtrio');
      unavailableNames = false;
      final retry = await store.prepare(pair);
      expect(retry?.attacker.name, 'Triopikeur');
      expect(retry?.target.name, 'Rondoudou');
    });

    test('waits for outstanding downloads before closing', () async {
      responseGate = Completer<void>();
      requestArrived = Completer<void>();
      final pending = store.prepare((attacker: 'dugtrio', target: 'jigglypuff'));
      await requestArrived!.future.timeout(const Duration(seconds: 2));
      final closing = store.close();
      responseGate!.complete();
      await closing;
      expect(await pending, isNull);
      await root.delete(recursive: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await root.exists(), isFalse);
    });
  }, skip: qaRoot == null);
}
