import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

void main() {
  final blobs = List.generate(
      4097,
      (index) => NativeArtifact(
          bytes: utf8.encode('{"id":$index}'), mediaType: 'application/json'));
  const world = NativeWriteLimits(maxArtifacts: 4096);
  Matcher failure(String code) =>
      isA<NativeWriteException>().having((error) => error.code, 'code', code);

  test('the hard ceiling names the unique blob budget', () {
    expect(nativeMaxUniqueArtifacts, 4096);
  });

  for (final role in ['output', 'source', 'disjoint', 'shared']) {
    test('4096 unique blobs are admitted for $role roles', () {
      final (outputs, sources) = switch (role) {
        'output' => (blobs.take(4096).toList(), <NativeArtifact>[]),
        'source' => (<NativeArtifact>[], blobs.take(4096).toList()),
        'disjoint' => (
            blobs.take(2048).toList(),
            blobs.skip(2048).take(2048).toList()
          ),
        _ => (blobs.take(4096).toList(), blobs.take(4096).toList()),
      };
      expect(
          validateNativeArtifactCount(
              artifacts: outputs, sourceArtifacts: sources, limits: world),
          4096);
    });
    test('4097 unique blobs are refused for $role roles', () {
      final (outputs, sources) = switch (role) {
        'output' => (blobs, <NativeArtifact>[]),
        'source' => (<NativeArtifact>[], blobs),
        'disjoint' => (blobs.take(2048).toList(), blobs.skip(2048).toList()),
        _ => (blobs.take(4096).toList(), [blobs.first, blobs.last]),
      };
      expect(
          () => validateNativeArtifactCount(
              artifacts: outputs, sourceArtifacts: sources, limits: world),
          throwsA(failure('native.quota.draft')));
    });
  }

  test('derived Border blobs participate in the same unique count', () {
    expect(
        validateNativeArtifactCount(
            artifacts: blobs.take(4095).toList(),
            sourceArtifacts: [],
            derivedArtifacts: [blobs[4095], blobs.first],
            limits: world,
            quotaCode: 'native.border.quota'),
        4096);
    expect(
        () => validateNativeArtifactCount(
            artifacts: blobs.take(4096).toList(),
            sourceArtifacts: [],
            derivedArtifacts: [blobs.last],
            limits: world,
            quotaCode: 'native.border.quota'),
        throwsA(failure('native.border.quota')));
  });

  for (final count in [32, 512, 1024, 2048]) {
    test('explicit $count blob budget remains exact', () {
      final limits = NativeWriteLimits(maxArtifacts: count);
      expect(
          validateNativeArtifactCount(
              artifacts: blobs.take(count).toList(),
              sourceArtifacts: blobs.take(count).toList(),
              limits: limits),
          count);
      expect(
          () => validateNativeArtifactCount(
              artifacts: blobs.take(count).toList(),
              sourceArtifacts: [blobs[count]],
              limits: limits),
          throwsA(failure('native.quota.draft')));
    });
  }

  test('duplicate handles within either retained role are refused', () {
    for (final source in [false, true]) {
      expect(
          () => validateNativeArtifactCount(
              artifacts: source ? [] : [blobs.first, blobs.first],
              sourceArtifacts: source ? [blobs.first, blobs.first] : [],
              limits: world),
          throwsA(failure('native.artifact.duplicate')));
    }
  });

  test('matching bytes with conflicting media cannot alias a shared handle',
      () {
    final json = blobs.first;
    final png = NativeArtifact(bytes: json.bytes);
    expect(png.handle, json.handle);
    expect(
        () => validateNativeArtifactCount(
            artifacts: [json], sourceArtifacts: [png], limits: world),
        throwsA(failure('native.artifact.conflict')));
    expect(() => json.bytes[0] = 0, throwsUnsupportedError);
    final different = NativeArtifact(bytes: [...json.bytes, 0]);
    expect(different.handle, isNot(json.handle));
    expect(
        () => NativeArtifact(
            bytes: different.bytes, expectedSha256: json.rawSha256),
        throwsA(failure('native.artifact.hash')));
    expect(
        validateNativeArtifactCount(
            artifacts: [json], sourceArtifacts: [different], limits: world),
        2);
  });
}
