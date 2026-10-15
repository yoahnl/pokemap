import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

void main() {
  test('allows an explicit bounded 512 artifact native catalogue study', () {
    const limits = NativeWriteLimits(maxArtifacts: 512);
    expect(limits.validate, returnsNormally);
    expect(limits.maxMutations, 256);
    expect(limits.maxArtifactBytes, 16777216);
    expect(limits.maxTotalArtifactBytes, 67108864);
    expect(limits.maxTotalDraftJsonBytes, 67108864);
  });

  test('keeps the default artifact budget small', () {
    const limits = NativeWriteLimits();
    expect(limits.maxArtifacts, 32);
    expect(limits.validate, returnsNormally);
  });

  for (final count in [-1, 0, 513, 1000000]) {
    test('refuses an invalid artifact count $count', () {
      expect(NativeWriteLimits(maxArtifacts: count).validate,
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.invalid_limits')));
    });
  }
}
