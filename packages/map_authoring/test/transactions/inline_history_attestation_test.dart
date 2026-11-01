import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

void main() {
  for (final length in [0, 65535, 65536, 65537, 262143, 262144, 262145]) {
    test(
        'owned inline history attestation is stable and correctly framed $length',
        () async {
      final values = List<int>.generate(length, (i) => i % 251);
      final payload =
          AuthoringPayload.inline(values, storageKey: 'maps/été😀.json');
      final expected = await inspectAuthoringResourceRevision(
          payload.openRead(),
          storageKey: 'authoring-history-blob',
          byteLength: length);
      final first = inspectAuthoringHistoryBlob(payload);
      final second = inspectAuthoringHistoryBlob(payload);
      expect(identical(first, second), isTrue);
      if (values.isNotEmpty) values[0] ^= 1;
      expect(await first, expected);
      expect(await inspectAuthoringHistoryBlob(payload), expected);
      expect(expected.resourceRevision, isNot(payload.resourceRevision));
      expect(() => payload.inlineBytes.add(0), throwsUnsupportedError);
    });
  }

  test(
      'stored sources remain fresh and reject mutation after a valid inspection',
      () async {
    var bytes = <int>[1, 2, 3];
    var reads = 0;
    Stream<List<int>> source() async* {
      reads++;
      yield List<int>.of(bytes);
    }

    final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'maps/a.json',
        byteLength: bytes.length,
        rawSha256: sha256.convert(bytes).toString(),
        openRead: source);
    expect(isImmutableAuthoringInlinePayload(payload), isFalse);
    final first = await inspectAuthoringHistoryBlob(payload);
    final afterFirst = reads;
    expect(await inspectAuthoringHistoryBlob(payload), first);
    expect(reads, afterFirst + 1);
    bytes = [9, 2, 3];
    await expectLater(
        inspectAuthoringHistoryBlob(payload),
        throwsA(isA<AuthoringPayloadException>()
            .having((e) => e.code, 'code', 'payload.source_mismatch')));
    await payload.release();
  });

  for (final nested in [false, true]) {
    test('ready attestation preserves cancellation checks nested=$nested',
        () async {
      final payload =
          AuthoringPayload.inline([1, 2, 3], storageKey: 'maps/a.json');
      await inspectAuthoringHistoryBlob(payload);
      var cancelled = false;
      var checks = 0;
      void check() {
        checks++;
        if (cancelled) throw StateError('cancelled');
      }

      final guarded = payload.checkingPreparation(check);
      final target = nested ? guarded.checkingPreparation(() {}) : guarded;
      expect(isImmutableAuthoringInlinePayload(target), isTrue);
      final pending = inspectAuthoringHistoryBlob(target);
      cancelled = true;
      await expectLater(
          pending, throwsA(isA<AuthoringPayloadPreparationAborted>()));
      expect(checks, greaterThan(0));
      await expectLater(inspectAuthoringHistoryBlob(target),
          throwsA(isA<AuthoringPayloadPreparationAborted>()));
    });
  }

  test('cancelled first computation does not poison the immutable attestation',
      () async {
    final payload = AuthoringPayload.inline(List<int>.filled(262145, 1),
        storageKey: 'maps/a.json');
    var cancelled = false;
    final guarded = payload.checkingPreparation(() {
      if (cancelled) throw StateError('cancelled');
    });
    final pending = inspectAuthoringHistoryBlob(guarded);
    cancelled = true;
    await expectLater(
        pending, throwsA(isA<AuthoringPayloadPreparationAborted>()));
    final expected = await inspectAuthoringResourceRevision(payload.openRead(),
        storageKey: 'authoring-history-blob', byteLength: payload.byteLength);
    expect(await inspectAuthoringHistoryBlob(payload), expected);
  });
}
