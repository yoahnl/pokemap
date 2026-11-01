import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/src/battle_recipe_bundle_inspector.dart';
import 'package:test/test.dart';

void main() {
  Uint8List png(int width, int height) => Uint8List.fromList(
      img.encodePng(img.Image(width: width, height: height)));
  Uint8List wav({int rate = 8000, int channels = 1, int samples = 800}) {
    final dataSize = samples * channels;
    final bytes = Uint8List(44 + dataSize + (dataSize & 1));
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, ascii.encode('RIFF'));
    data.setUint32(4, bytes.length - 8, Endian.little);
    bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * channels, Endian.little);
    data.setUint16(32, channels, Endian.little);
    data.setUint16(34, 8, Endian.little);
    bytes.setRange(36, 40, ascii.encode('data'));
    data.setUint32(40, dataSize, Endian.little);
    return bytes;
  }

  Uint8List extensibleWav() {
    final original = wav(rate: 48000, channels: 6, samples: 48);
    final bytes = Uint8List(original.length + 24);
    bytes.setRange(0, 36, original);
    bytes.setRange(60, bytes.length, original, 36);
    final data = ByteData.sublistView(bytes);
    data.setUint32(4, bytes.length - 8, Endian.little);
    data.setUint32(16, 40, Endian.little);
    data.setUint16(20, 0xfffe, Endian.little);
    data.setUint16(36, 22, Endian.little);
    data.setUint16(38, 8, Endian.little);
    data.setUint32(44, 1, Endian.little);
    bytes.setRange(48, 60, [0, 0, 16, 0, 128, 0, 0, 170, 0, 56, 155, 113]);
    return bytes;
  }

  Uint8List changeFirstOggPage(
      Uint8List source, void Function(Uint8List) change) {
    final bytes = Uint8List.fromList(source);
    final count = bytes[26];
    var end = 27 + count;
    for (var i = 0; i < count; i++) {
      end += bytes[27 + i];
    }
    change(bytes);
    final data = ByteData.sublistView(bytes);
    data.setUint32(22, 0, Endian.little);
    var crc = 0;
    for (var i = 0; i < end; i++) {
      crc ^= bytes[i] << 24;
      for (var bit = 0; bit < 8; bit++) {
        crc = ((crc << 1) ^ ((crc & 0x80000000) == 0 ? 0 : 0x04c11db7))
            .toUnsigned(32);
      }
    }
    data.setUint32(22, crc, Endian.little);
    return bytes;
  }

  ({
    BattleMoveRecipeBinding binding,
    Uint8List recipe,
    Map<String, Uint8List> media
  }) fixture(Uint8List texture,
      {Uint8List? second, Uint8List? sound, String soundType = 'audio/ogg'}) {
    final definition = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'emitters': [
        {
          'textureId': 'tex',
          'emissionDurationMs': 100,
          'emissionIntervalMs': 20,
          'particleLifetimeMs': 200,
          'particlesPerEmission': 1
        },
        if (second != null)
          {
            'textureId': 'tex2',
            'emissionDurationMs': 100,
            'emissionIntervalMs': 20,
            'particleLifetimeMs': 200,
            'particlesPerEmission': 1
          },
      ],
    })));
    Map<String, dynamic> resource(
            String id, String role, String mime, Uint8List bytes) =>
        {
          'id': id,
          'role': role,
          'mediaType': mime,
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
        };
    final recipe = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'recipeId': 'fire',
      'revision': '1',
      'moveSourceId': 'flamethrower',
      'variant': 'default',
      'requiredCapabilities': [
        'sequence',
        'startParticle',
        'waitEffects',
        if (sound != null) 'sound'
      ],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test/1'
      },
      'resources': [
        {
          ...resource('particle', 'particleDefinition',
              'application/vnd.avelune.particle+json', definition),
          'definitionVersion': 1,
          'dependencies': ['tex', if (second != null) 'tex2']
        },
        resource('tex', 'texture', 'image/png', texture),
        if (second != null) resource('tex2', 'texture', 'image/png', second),
        if (sound != null) resource('sound', 'sound', soundType, sound),
      ],
      'program': {
        'kind': 'sequence',
        'steps': [
          {
            'kind': 'startParticle',
            'resourceId': 'particle',
            'from': 'userMouth',
            'to': 'targetImpact'
          },
          {'kind': 'waitEffects'},
        ]
      },
    })));
    return (
      binding: BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': 'local-fire',
        'sourceMoveId': 'flamethrower',
        'catalogReleaseId': 'test',
        'recipeId': 'fire',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': sha256.convert(recipe).toString(),
      }),
      recipe: recipe,
      media: {
        'particle': definition,
        'tex': texture,
        if (second != null) 'tex2': second,
        if (sound != null) 'sound': sound
      }
    );
  }

  BattleRecipeBundleLimits limits(
          {int maxTextures = 2,
          int maxTextureBytes = 10000,
          int maxBundleBytes = 20000,
          int maxDimension = 16,
          int maxTexturePixels = 256,
          int maxTotalPixels = 256}) =>
      BattleRecipeBundleLimits(
        maxTextures: maxTextures,
        maxTextureBytes: maxTextureBytes,
        maxBundleBytes: maxBundleBytes,
        maxDimension: maxDimension,
        maxTexturePixels: maxTexturePixels,
        maxTotalPixels: maxTotalPixels,
      );
  const inspector = BattleRecipeBundleInspector();
  const capabilities = {'sequence', 'startParticle', 'waitEffects'};
  InspectedBattleRecipeBundle inspect(
          ({
            BattleMoveRecipeBinding binding,
            Uint8List recipe,
            Map<String, Uint8List> media
          }) sample,
          BattleRecipeBundleLimits policy) =>
      inspector.inspect(
        sample.binding,
        sample.recipe,
        sample.media,
        limits: policy,
        availableCapabilities: {...capabilities, 'sound'},
        expectedProjectMoveId: 'local-fire',
        expectedCatalogReleaseId: 'test',
      );

  test('checks complete PNG and returns immutable verified snapshots', () {
    final sample = fixture(png(2, 3));
    final result = inspect(sample, limits());
    final original = List<int>.of(result.media['tex']!);
    sample.media['tex']![0] = 0;
    sample.recipe[0] = 0;
    expect(result.media['tex'], original);
    expect(() => result.media['tex']![0] = 0, throwsUnsupportedError);
    expect(() => result.recipeBytes[0] = 0, throwsUnsupportedError);
  });

  test('rejects invalid or changed PNG bytes and per-bundle limits', () {
    final sample = fixture(png(4, 4));
    for (final policy in [
      limits(maxTextures: 0),
      limits(maxTextureBytes: 1),
      limits(maxBundleBytes: 10),
      limits(maxDimension: 3),
      limits(maxTexturePixels: 15),
      limits(maxTotalPixels: 15)
    ]) {
      expect(() => inspect(sample, policy), throwsFormatException);
    }
    expect(
        () => inspect((
              binding: sample.binding,
              recipe: sample.recipe,
              media: {
                ...sample.media,
                'tex': Uint8List.fromList([0, 1])
              }
            ), limits()),
        throwsFormatException);
    final invalid = fixture(Uint8List.fromList([0, 1, 2, 3]));
    expect(() => inspect(invalid, limits()), throwsFormatException);
    final corrupted = png(4, 4);
    corrupted[corrupted.length - 1] ^= 1;
    final matchingHashButBadPng = fixture(corrupted);
    expect(
        () => inspect(matchingHashButBadPng, limits()), throwsFormatException);
  });

  test('bounds the sum of pixels and the number of distinct textures', () {
    final sample = fixture(png(4, 4), second: png(4, 4));
    expect(
        () => inspect(sample, limits(maxTexturePixels: 16, maxTotalPixels: 32)),
        returnsNormally);
    expect(
        () => inspect(sample, limits(maxTexturePixels: 16, maxTotalPixels: 31)),
        throwsFormatException);
    expect(
        () => inspect(sample, limits(maxTextures: 1)), throwsFormatException);
  });

  test('refuses invalid sound even when the caller lists the capability', () {
    final sample = fixture(png(2, 2), sound: Uint8List.fromList([1, 2]));
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: {...capabilities, 'sound'},
          expectedProjectMoveId: 'local-fire',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
  });

  test('accepts complete WAV, Ogg Vorbis and MP3 sounds in mixed recipes', () {
    final samples = {
      'audio/wav': '../map_runtime/assets/audio/overworld/jump.wav',
      'audio/ogg': '../map_runtime/assets/audio/battle/se/118-fire02.ogg',
      'audio/mpeg': '../map_runtime/assets/audio/battle/se/stat_rise_up.mp3',
    };
    for (final entry in samples.entries) {
      final sound = File(entry.value).readAsBytesSync();
      final sample = fixture(png(2, 2), sound: sound, soundType: entry.key);
      final result = inspect(sample, limits(maxBundleBytes: 1024 * 1024));
      expect(result.media['sound'], sound, reason: entry.key);
      expect(() => result.media['sound']![0] = 0, throwsUnsupportedError);
    }
    final opus = Uint8List.fromList(base64Decode(
        'T2dnUwACAAAAAAAAAADuBLX4AAAAADxbltoBE09wdXNIZWFkAQE4AYC7AAAAAABPZ2dTAAAAAAAAAAAAAO4EtfgBAAAA+C6b8wE8T3B1c1RhZ3MMAAAATGF2ZjYzLjEuMTAyAQAAABwAAABlbmNvZGVyPUxhdmM2My4xLjEwMiBsaWJvcHVzT2dnUwAEmAoAAAAAAADuBLX4AgAAAJbj3V4DAwMD+P/++P/++P/+'));
    final sample = fixture(png(2, 2), sound: opus, soundType: 'audio/ogg');
    expect(() => inspect(sample, limits()), returnsNormally);
    final invalidChannels = changeFirstOggPage(opus, (bytes) => bytes[37] = 9);
    final invalidGranule = changeFirstOggPage(
        opus,
        (bytes) => ByteData.sublistView(bytes)
            .setUint32(6, 0x7fffffff, Endian.little));
    for (final sound in [invalidChannels, invalidGranule]) {
      final invalid = fixture(png(2, 2), sound: sound, soundType: 'audio/ogg');
      expect(() => inspect(invalid, limits()), throwsFormatException);
    }
  });

  test(
      'rejects truncated, mislabeled or altered sound even with a matching hash',
      () {
    final wav = File('../map_runtime/assets/audio/overworld/jump.wav')
        .readAsBytesSync();
    final ogg = File('../map_runtime/assets/audio/battle/se/118-fire02.ogg')
        .readAsBytesSync();
    final mp3 = File('../map_runtime/assets/audio/battle/se/stat_rise_up.mp3')
        .readAsBytesSync();
    final corruptedOgg = Uint8List.fromList(ogg)..[ogg.length - 4] ^= 1;
    for (final (sound, type) in [
      (Uint8List.sublistView(wav, 0, wav.length - 1), 'audio/wav'),
      (corruptedOgg, 'audio/ogg'),
      (Uint8List.sublistView(mp3, 0, mp3.length - 1), 'audio/mpeg'),
      (wav, 'audio/ogg'),
      (ogg, 'audio/mpeg'),
    ]) {
      final sample = fixture(png(2, 2), sound: sound, soundType: type);
      expect(() => inspect(sample, limits(maxBundleBytes: 1024 * 1024)),
          throwsFormatException,
          reason: type);
    }
  });

  test('enforces sound duration, sample rate, channels and byte limits', () {
    final valid = fixture(png(2, 2),
        sound: wav(samples: 8000 * 120), soundType: 'audio/wav');
    expect(() => inspect(valid, limits(maxBundleBytes: 2 * 1024 * 1024)),
        returnsNormally);
    final extensible = extensibleWav();
    expect(
        () => inspect(
            fixture(png(2, 2), sound: extensible, soundType: 'audio/wav'),
            limits(maxBundleBytes: 10000)),
        returnsNormally);
    final badGuid = Uint8List.fromList(extensible)..[48] = 1;
    final badExtension = Uint8List.fromList(extensible);
    ByteData.sublistView(badExtension).setUint16(36, 23, Endian.little);
    for (final sound in [
      wav(rate: 7999),
      wav(rate: 192001),
      wav(channels: 9),
      wav(samples: 0),
      wav(samples: 8000 * 120 + 1),
      badGuid,
      badExtension,
      Uint8List(8 * 1024 * 1024 + 1),
    ]) {
      final sample = fixture(png(2, 2), sound: sound, soundType: 'audio/wav');
      expect(() => inspect(sample, limits(maxBundleBytes: 10 * 1024 * 1024)),
          throwsFormatException);
    }
    final sample = fixture(png(2, 2), sound: wav(), soundType: 'audio/wav');
    sample.media['sound']![45] ^= 1;
    expect(() => inspect(sample, limits(maxBundleBytes: 10000)),
        throwsFormatException);
  });

  test('refuses foreign bindings and unexpected extra media', () {
    final sample = fixture(png(2, 2));
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: capabilities,
          expectedProjectMoveId: 'other',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
    expect(
      () => inspect((
        binding: sample.binding,
        recipe: sample.recipe,
        media: {
          ...sample.media,
          'extra': Uint8List.fromList([1])
        }
      ), limits()),
      throwsFormatException,
    );
    expect(
      () => inspector.inspect(sample.binding, sample.recipe, sample.media,
          limits: limits(),
          availableCapabilities: {'sequence'},
          expectedProjectMoveId: 'local-fire',
          expectedCatalogReleaseId: 'test'),
      throwsFormatException,
    );
  });
}
