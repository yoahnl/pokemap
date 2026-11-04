import 'dart:async';

import 'package:avelune_attack_compare/workshop_reference_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waits for the selected reference to finish loading', () async {
    final requests = <({String? url, int id})>[];
    final playback = WorkshopReferencePlayback(
      display: (url, id) async => requests.add((url: url, id: id)),
      timeout: const Duration(milliseconds: 100),
    );
    var finished = false;
    final result = playback.show('https://example.com/reference.png').then((value) {
      finished = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(requests, hasLength(1));
    expect(finished, isFalse);
    playback.report(requests.single.id, loaded: true);
    expect(await result, isTrue);
    playback.close();
  });

  test('ignores a late result after the user changes the attack', () async {
    final requests = <({String? url, int id})>[];
    final playback = WorkshopReferencePlayback(
      display: (url, id) async => requests.add((url: url, id: id)),
      timeout: const Duration(milliseconds: 100),
    );
    final previous = playback.show('https://example.com/first.png');
    await Future<void>.delayed(Duration.zero);
    final current = playback.show('https://example.com/second.png');
    await Future<void>.delayed(Duration.zero);
    expect(await previous, isFalse);
    var currentFinished = false;
    unawaited(current.then((_) => currentFinished = true));
    playback.report(requests.first.id, loaded: true);
    await Future<void>.delayed(Duration.zero);
    expect(currentFinished, isFalse);
    playback.report(requests.last.id, loaded: true);
    expect(await current, isTrue);
    playback.close();
  });

  test('a missing, failed or timed-out reference does not block playback', () async {
    final requests = <({String? url, int id})>[];
    final playback = WorkshopReferencePlayback(
      display: (url, id) async => requests.add((url: url, id: id)),
      timeout: const Duration(milliseconds: 30),
    );
    expect(await playback.show(null), isFalse);
    final failed = playback.show('https://example.com/failed.png');
    await Future<void>.delayed(Duration.zero);
    playback.report(requests.last.id, loaded: false);
    expect(await failed, isFalse);
    expect(await playback.show('https://example.com/timeout.png'), isFalse);
    playback.close();
  });

  test('closing releases a pending load and prevents new requests', () async {
    var requests = 0;
    final playback = WorkshopReferencePlayback(
      display: (url, id) async => requests++,
      timeout: const Duration(milliseconds: 100),
    );
    final pending = playback.show('https://example.com/reference.png');
    await Future<void>.delayed(Duration.zero);
    playback.close();
    expect(await pending, isFalse);
    expect(await playback.show('https://example.com/again.png'), isFalse);
    expect(requests, 1);
  });
}
