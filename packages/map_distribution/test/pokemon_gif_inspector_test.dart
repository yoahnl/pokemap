import 'dart:convert';
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

  test('game packages accept bounded GIFs and content-addressed GIF blobs', () {
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    for (final path in [
      'project/assets/pokemon/battle.gif',
      'project/sprites/pokemon/battle.gif',
      'project/assets/.pokemap-store/${'a' * 64}.blob',
    ]) {
      expect(
        () => validator.validate(
          GamePackageFileEntry(
            path: path,
            size: sample.length,
            sha256: '0' * 64,
            mediaType: 'image/gif',
          ),
          sample,
        ),
        returnsNormally,
      );
    }
  });

  test('GIFs cannot bypass excluded project directories', () {
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    for (final path in ['project/saves/battle.gif', 'project/cache/battle.gif']) {
      expect(
        () => validator.validate(
          GamePackageFileEntry(
            path: path,
            size: sample.length,
            sha256: '0' * 64,
            mediaType: 'image/gif',
          ),
          sample,
        ),
        throwsA(isA<GamePackageFormatException>()),
      );
    }
  });

  test('rejects malformed GIFs, wrong MIME and excessive encoded size', () {
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    GamePackageFileEntry entry({int? size, String? mediaType = 'image/gif'}) =>
        GamePackageFileEntry(
          path: 'project/assets/pokemon/battle.gif',
          size: size ?? sample.length,
          sha256: '0' * 64,
          mediaType: mediaType,
        );
    expect(
      () => validator.validate(entry(), Uint8List.sublistView(sample, 0, 12)),
      throwsA(isA<GamePackageFormatException>()),
    );
    expect(
      () => validator.validate(
        entry(),
        Uint8List.sublistView(sample, 0, sample.length - 1),
      ),
      throwsA(isA<GamePackageFormatException>()),
    );
    expect(
      () => validator.validate(entry(mediaType: 'image/png'), sample),
      throwsA(isA<GamePackageFormatException>()),
    );
    expect(
      () => validator.validate(entry(size: 32 * 1024 * 1024 + 1), sample),
      throwsA(isA<GamePackageFormatException>()),
    );
    expect(
      () => const GamePackageContentValidator(
        GamePackageSecurityPolicy(maxImageDimension: 1),
      ).validate(entry(), sample),
      throwsA(isA<GamePackageFormatException>()),
    );
  });

  test('admits up to 500 frames while retaining the decoded pixel limit', () {
    final frame = image.Image(width: 2, height: 2);
    Uint8List gif(int count) {
      final encoder = image.GifEncoder();
      for (var i = 0; i < count; i++) {
        encoder.addFrame(frame);
      }
      return Uint8List.fromList(encoder.finish()!);
    }
    GamePackageFileEntry entry(Uint8List bytes) => GamePackageFileEntry(
      path: 'project/assets/pokemon/battle.gif',
      size: bytes.length,
      sha256: '0' * 64,
      mediaType: 'image/gif',
    );
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    for (final count in [338, 500]) {
      final bytes = gif(count);
      expect(const PokemonGifInspector().inspect(bytes).frameCount, count);
      expect(() => validator.validate(entry(bytes), bytes), returnsNormally);
    }
    final excessive = gif(501);
    expect(
      () => validator.validate(entry(excessive), excessive),
      throwsA(isA<GamePackageFormatException>()),
    );
    final long = gif(338);
    expect(
      () => const GamePackageContentValidator(
        GamePackageSecurityPolicy(maxImagePixels: 1000),
      ).validate(entry(long), long),
      throwsA(isA<GamePackageFormatException>()),
    );
  });

  test('content-only JSON inspection does not infer Pokemon media scope', () {
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());
    for (final field in [
      'frontAnimated',
      'backAnimated',
      'frontShinyAnimated',
      'backShinyAnimated',
      'frontFemaleAnimated',
      'backFemaleAnimated',
      'frontShinyFemaleAnimated',
      'backShinyFemaleAnimated',
    ]) {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {'base': {field: '../outside.gif'}},
      })));
      expect(
        () => validator.validate(
          GamePackageFileEntry(
            path: 'project/data/pokemon/media/oshawott.json',
            size: bytes.length,
            sha256: '0' * 64,
            mediaType: 'application/json',
          ),
          bytes,
        ),
        returnsNormally,
        reason: field,
      );
    }
  });

  test('preserves the old treatment of unknown schema v1 fields', () {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {'base': {'frontAnimated': '../legacy-extension'}},
    })));
    expect(
      () => const GamePackageContentValidator(GamePackageSecurityPolicy())
          .validate(
        GamePackageFileEntry(
          path: 'project/data/pokemon/media/oshawott.json',
          size: bytes.length,
          sha256: '0' * 64,
          mediaType: 'application/json',
        ),
        bytes,
      ),
      returnsNormally,
    );
  });
}
