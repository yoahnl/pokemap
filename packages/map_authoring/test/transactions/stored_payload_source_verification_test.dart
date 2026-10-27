import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

void main() {
  test('framed source verification reads once and preserves replay integrity',
      () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final expected = AuthoringPayload.inline(bytes, storageKey: 'source.bin');
    var reads = 0;
    List<int> source = bytes;
    final payload = await AuthoringPayload.verifiedResource(
      storageKey: 'source.bin',
      byteLength: bytes.length,
      resourceRevision: expected.resourceRevision,
      openRead: () {
        reads++;
        return Stream.value(source);
      },
    );
    addTearDown(payload.release);
    expect(reads, 1);
    expect(payload.rawSha256, expected.rawSha256);
    expect(payload.contentDigest, expected.contentDigest);
    expect(await payload.readBytes(), bytes);
    source = [9, 2, 3, 4];
    await expectLater(
        payload.readBytes(),
        throwsA(isA<AuthoringPayloadException>()
            .having((error) => error.code, 'code', 'payload.source_mismatch')));
  });
  for (final wrong in ['revision', 'key', 'length']) {
    test('framed source verification rejects wrong $wrong', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final expected = AuthoringPayload.inline(bytes, storageKey: 'source.bin');
      await expectLater(
          AuthoringPayload.verifiedResource(
            storageKey: wrong == 'key' ? 'other.bin' : 'source.bin',
            byteLength: wrong == 'length' ? bytes.length + 1 : bytes.length,
            resourceRevision: wrong == 'revision'
                ? 'sha256:${'0' * 64}'
                : expected.resourceRevision,
            openRead: () => Stream.value(bytes),
          ),
          throwsA(isA<AuthoringPayloadException>().having(
              (error) => error.code,
              'code',
              wrong == 'length'
                  ? 'payload.length_mismatch'
                  : 'payload.source_mismatch')));
    });
  }
  test(
      'stored factory rejects a false framed revision with a correct raw digest',
      () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    await expectLater(
      AuthoringPayload.verifiedSource(
        storageKey: 'assets/été😀.bin',
        byteLength: bytes.length,
        rawSha256: sha256.convert(bytes).toString(),
        resourceRevision: 'sha256:${'0' * 64}',
        openRead: () => Stream.value(bytes),
      ),
      throwsA(isA<AuthoringPayloadException>()
          .having((error) => error.code, 'code', 'payload.source_mismatch')),
    );
  });

  for (final size in [17, (256 << 10) + 17]) {
    for (final mutation in [
      'same-length',
      'shorter',
      'longer',
      'negative',
      'overflow'
    ]) {
      test('stored read rejects $mutation source at $size bytes', () async {
        final original =
            Uint8List.fromList(List.generate(size, (index) => index % 251));
        List<int> current = original;
        final payload = await AuthoringPayload.verifiedSource(
          storageKey: './assets//été\\灯😀.bin',
          byteLength: size,
          rawSha256: sha256.convert(original).toString(),
          openRead: () => Stream.value(current),
        );
        addTearDown(payload.release);
        final revision = payload.resourceRevision;
        final content = payload.contentDigest;
        current = original.toList();
        switch (mutation) {
          case 'same-length':
            current[size - 1] ^= 1;
          case 'shorter':
            current.removeLast();
          case 'longer':
            current.add(0);
          case 'negative':
            current[size - 1] = -1;
          case 'overflow':
            current[size - 1] = 256;
        }
        await expectLater(
          payload.readBytes(),
          throwsA(isA<AuthoringPayloadException>().having(
            (error) => error.code,
            'code',
            mutation == 'same-length'
                ? 'payload.source_mismatch'
                : 'payload.length_mismatch',
          )),
        );
        expect(payload.resourceRevision, revision);
        expect(payload.contentDigest, content);
        current = original;
        expect(await payload.readBytes(), original);
      });
    }

    test('stored read preserves chunking and upstream errors at $size bytes',
        () async {
      final bytes =
          Uint8List.fromList(List.generate(size, (index) => index % 251));
      final failure = StateError('source failed');
      var fail = false;
      var closed = false;
      Stream<List<int>> chunks() async* {
        try {
          yield bytes.sublist(0, 7);
          if (fail) throw failure;
          yield bytes.sublist(7);
        } finally {
          closed = true;
        }
      }

      final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/été😀.bin',
        byteLength: size,
        rawSha256: sha256.convert(bytes).toString(),
        openRead: chunks,
      );
      addTearDown(payload.release);
      expect(await payload.openRead().map((chunk) => chunk.length).toList(),
          [7, size - 7]);
      fail = true;
      closed = false;
      await expectLater(payload.readBytes(), throwsA(same(failure)));
      expect(closed, isTrue);
      fail = false;
      expect(await payload.readBytes(), bytes);
    });

    test(
        'stored read cancels its source and refuses reads after release at $size bytes',
        () async {
      final bytes = Uint8List(size);
      var listening = 0;
      var closed = 0;
      var releases = 0;
      Stream<List<int>> chunks() async* {
        listening++;
        try {
          yield bytes.sublist(0, 7);
          yield bytes.sublist(7);
        } finally {
          closed++;
        }
      }

      final payload = await AuthoringPayload.verifiedSource(
        storageKey: 'assets/source.bin',
        byteLength: size,
        rawSha256: sha256.convert(bytes).toString(),
        openRead: chunks,
        release: () async {
          releases++;
        },
      );
      expect(listening, 1);
      expect(await payload.openRead().first, Uint8List(7));
      expect(listening, 2);
      expect(closed, 2);
      await payload.release();
      await payload.release();
      await expectLater(
          payload.readBytes(),
          throwsA(
            isA<AuthoringPayloadException>()
                .having((error) => error.code, 'code', 'payload.released'),
          ));
      expect(listening, 2);
      expect(releases, 1);
    });
  }
}
