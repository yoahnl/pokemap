import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  final sample = Uint8List.fromList(image.encodeGif(
    image.Image(width: 2, height: 2)
      ..addFrame(image.Image(width: 2, height: 2)),
  ));

  test('inspects all frames without claiming runtime playback', () {
    final info = const PokemonGifInspector().inspect(sample);
    expect(info.width, 2);
    expect(info.height, 2);
    expect(info.frameCount, 2);
  });

  test('rejects truncation, invalid frame bounds and extra content', () {
    final truncated = Uint8List.sublistView(sample, 0, sample.length - 1);
    expect(() => const PokemonGifInspector().inspect(truncated),
        throwsFormatException);
    final oversizedFrame = Uint8List.fromList(sample);
    final frameIndex = oversizedFrame.indexOf(0x2c, 13);
    expect(frameIndex, greaterThan(0));
    oversizedFrame[frameIndex + 5] = 3;
    expect(() => const PokemonGifInspector().inspect(oversizedFrame),
        throwsFormatException);
    expect(
        () => const PokemonGifInspector()
            .inspect(Uint8List.fromList([...sample, 1])),
        throwsFormatException);
  });

  test('bounds frames and total decoded canvas pixels before decoding', () {
    expect(() => const PokemonGifInspector(maxFrames: 1).inspect(sample),
        throwsFormatException);
    expect(() => const PokemonGifInspector(maxCanvasPixels: 7).inspect(sample),
        throwsFormatException);
  });

  test('game packages keep refusing GIF until runtime compatibility is added',
      () {
    expect(
      () => const GamePackageContentValidator(GamePackageSecurityPolicy())
          .validate(
        GamePackageFileEntry(
          path: 'project/assets/pokemon/battle.gif',
          size: sample.length,
          sha256: '0' * 64,
          mediaType: 'image/gif',
        ),
        sample,
      ),
      throwsA(isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', 'executableContent')),
    );
  });
}
