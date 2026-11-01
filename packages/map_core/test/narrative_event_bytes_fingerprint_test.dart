import 'dart:collection';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('NS-EVENT-V2 Phase E hashes raw project bytes with SHA-256', () {
    expect(
      narrativeEventBytesFingerprint(const [0, 1, 2, 255]),
      'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
    );
  });

  test('empty bytes retain the standard raw SHA-256 identity', () {
    expect(
      narrativeEventBytesFingerprint(const []),
      'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('Uint8 bytes retain the existing raw digest', () {
    expect(
      narrativeEventBytesFingerprint(Uint8List.fromList([0, 1, 2, 255])),
      'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
    );
  });

  test('subrange views exclude bytes outside the selected range', () {
    final backing = Uint8List.fromList([99, 0, 1, 2, 255, 88]);
    final view = Uint8List.sublistView(backing, 1, 5);
    expect(
      narrativeEventBytesFingerprint(view),
      'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
    );
    expect(backing, [99, 0, 1, 2, 255, 88]);
  });

  test('unmodifiable byte views keep their raw identity', () {
    final bytes = Uint8List.fromList([0, 1, 2, 255]).asUnmodifiableView();
    expect(
      narrativeEventBytesFingerprint(bytes),
      'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
    );
  });

  test('integer inputs retain eight-bit truncation', () {
    expect(
      narrativeEventBytesFingerprint([-1, 256, 511, -257]),
      'sha256:${sha256.convert([255, 0, 255, 255])}',
    );
  });

  for (final length in [65537, 262145]) {
    test('large Uint8 input matches the portable oracle length=$length', () {
      final bytes = Uint8List.fromList(
        List.generate(length, (index) => index * 31 + 7),
      );
      expect(
        narrativeEventBytesFingerprint(bytes),
        'sha256:${sha256.convert(bytes)}',
      );
    });
    test('large immutable integer input matches the oracle length=$length', () {
      final bytes = List<int>.unmodifiable(
        List.generate(length, (index) => (index * 31 + 7) & 255),
      );
      expect(
        narrativeEventBytesFingerprint(bytes),
        'sha256:${sha256.convert(bytes)}',
      );
    });
  }

  for (final failureIndex in [0, 65537]) {
    test('source error identity survives failure at index=$failureIndex', () {
      final error = StateError('source-$failureIndex');
      expect(
        () => narrativeEventBytesFingerprint(
          _FailingBytes(65539, failureIndex, error),
        ),
        throwsA(same(error)),
      );
      expect(
        narrativeEventBytesFingerprint(const [0, 1, 2, 255]),
        'sha256:3d1f57c984978ef98a18378c8166c1cb8ede02c03eeb6aee7e2f121dfeee3e56',
      );
    });
  }
}

final class _FailingBytes extends ListBase<int> {
  _FailingBytes(this.length, this.failureIndex, this.error);

  @override
  final int length;
  final int failureIndex;
  final Object error;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  int operator [](int index) {
    if (index == failureIndex) throw error;
    return index & 255;
  }

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('immutable');
}
