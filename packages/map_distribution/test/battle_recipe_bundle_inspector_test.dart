import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/src/battle_recipe_bundle_inspector.dart';
import 'package:map_distribution/src/battle_recipe_sound_inspection.dart';
import 'package:test/test.dart';

void main() {
  Uint8List png(int width, int height) => Uint8List.fromList(
      img.encodePng(img.Image(width: width, height: height)));
  Uint8List opus() => Uint8List.fromList(base64Decode(
      'T2dnUwACAAAAAAAAAADuBLX4AAAAADxbltoBE09wdXNIZWFkAQE4AYC7AAAAAABPZ2dTAAAAAAAAAAAAAO4EtfgBAAAA+C6b8wE8T3B1c1RhZ3MMAAAATGF2ZjYzLjEuMTAyAQAAABwAAABlbmNvZGVyPUxhdmM2My4xLjEwMiBsaWJvcHVzT2dnUwAEmAoAAAAAAADuBLX4AgAAAJbj3V4DAwMD+P/++P/++P/+'));
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

  Uint8List changeLastOggPage(
      Uint8List source, void Function(List<int>, int) change) {
    final bytes = source.toList();
    var offset = 0, last = 0;
    while (offset < source.length) {
      last = offset;
      final count = source[offset + 26];
      offset += 27 + count;
      for (var i = 0; i < count; i++) {
        offset += source[last + 27 + i];
      }
    }
    change(bytes, last);
    bytes.setRange(last + 22, last + 26, [0, 0, 0, 0]);
    var crc = 0;
    for (var i = last; i < bytes.length; i++) {
      crc ^= bytes[i] << 24;
      for (var bit = 0; bit < 8; bit++) {
        crc = ((crc << 1) ^ ((crc & 0x80000000) == 0 ? 0 : 0x04c11db7))
            .toUnsigned(32);
      }
    }
    for (var i = 0; i < 4; i++) {
      bytes[last + 22 + i] = (crc >> (8 * i)) & 0xff;
    }
    return Uint8List.fromList(bytes);
  }

  Uint8List opusHeaders() {
    final source = opus();
    var audioOffset = 0;
    for (var page = 0; page < 2; page++) {
      final count = source[audioOffset + 26];
      final segments =
          source.sublist(audioOffset + 27, audioOffset + 27 + count);
      audioOffset +=
          27 + count + segments.fold<int>(0, (sum, value) => sum + value);
    }
    return Uint8List.sublistView(source, 0, audioOffset);
  }

  Uint8List opusPage(int sequence, int flags, int? granule, List<int> segments,
      List<int> payload) {
    final source = opus();
    final bytes = Uint8List(27 + segments.length + payload.length);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, ascii.encode('OggS'));
    bytes[5] = flags;
    if (granule == null) {
      data.setUint32(6, 0xffffffff, Endian.little);
      data.setUint32(10, 0xffffffff, Endian.little);
    } else {
      data.setUint64(6, granule, Endian.little);
    }
    data.setUint32(
        14,
        ByteData.sublistView(source).getUint32(14, Endian.little),
        Endian.little);
    data.setUint32(18, sequence, Endian.little);
    bytes[26] = segments.length;
    bytes.setRange(27, 27 + segments.length, segments);
    bytes.setRange(27 + segments.length, bytes.length, payload);
    var crc = 0;
    for (final byte in bytes) {
      crc ^= byte << 24;
      for (var bit = 0; bit < 8; bit++) {
        crc = ((crc << 1) ^ ((crc & 0x80000000) == 0 ? 0 : 0x04c11db7))
            .toUnsigned(32);
      }
    }
    data.setUint32(22, crc, Endian.little);
    return bytes;
  }

  Uint8List opusWithPackets(
    int packetCount, {
    int packetsPerPage = 50,
    int? finalPagePackets,
    int samplesPerPacket = 960,
    int initialOffset = 0,
    int finalTrim = 0,
    List<int> packet = const [0xf8, 0xff, 0xfe],
    int Function(int page, int packets, bool isLast)? granule,
  }) {
    final output = BytesBuilder()..add(opusHeaders());
    var emitted = 0, page = 0;
    while (emitted < packetCount) {
      final remaining = packetCount - emitted;
      final count = finalPagePackets == null
          ? remaining.clamp(0, packetsPerPage)
          : remaining <= finalPagePackets
              ? remaining
              : (remaining - finalPagePackets).clamp(0, packetsPerPage);
      emitted += count;
      final isLast = emitted == packetCount;
      output.add(opusPage(
        page + 2,
        isLast ? 4 : 0,
        granule?.call(page, emitted, isLast) ??
            initialOffset +
                emitted * samplesPerPacket -
                (isLast ? finalTrim : 0),
        List.filled(count, packet.length),
        [for (var i = 0; i < count; i++) ...packet],
      ));
      page++;
    }
    return output.takeBytes();
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
    final sound = opus();
    final sample = fixture(png(2, 2), sound: sound, soundType: 'audio/ogg');
    expect(() => inspect(sample, limits()), returnsNormally);
    final invalidChannels = changeFirstOggPage(sound, (bytes) => bytes[37] = 9);
    final invalidGranule = changeFirstOggPage(
        sound,
        (bytes) => ByteData.sublistView(bytes)
            .setUint32(6, 0x7fffffff, Endian.little));
    for (final sound in [invalidChannels, invalidGranule]) {
      final invalid = fixture(png(2, 2), sound: sound, soundType: 'audio/ogg');
      expect(() => inspect(invalid, limits()), throwsFormatException);
    }
  });

  test('accepts bounded zero padding after a complete Ogg sound', () {
    final sounds = [
      opus(),
      File('../map_runtime/assets/audio/battle/se/118-fire02.ogg')
          .readAsBytesSync(),
    ];
    for (final sound in sounds) {
      for (final size in [1, 32, 4096]) {
        final padded = Uint8List.fromList([...sound, ...List.filled(size, 0)]);
        final sample =
            fixture(png(2, 2), sound: padded, soundType: 'audio/ogg');
        expect(() => inspect(sample, limits(maxBundleBytes: 1024 * 1024)),
            returnsNormally,
            reason: 'zero padding: $size bytes');
      }
    }
  });

  test('rejects invalid or oversized data after an Ogg sound', () {
    final sound = opus();
    final corrupted = Uint8List.fromList(sound)..[sound.length - 1] ^= 1;
    final missingEnd = changeLastOggPage(sound, (bytes, offset) {
      bytes[offset + 5] &= ~4;
    });
    final unfinished = changeLastOggPage(sound, (bytes, offset) {
      final lastSegment = offset + 26 + bytes[offset + 26];
      final length = bytes[lastSegment];
      bytes[lastSegment] = 255;
      bytes.addAll(List.filled(255 - length, 0));
    });
    final invalid = {
      'too much padding': [...sound, ...List.filled(4097, 0)],
      'nonzero suffix': [...sound, 0, 1],
      'truncated': [
        ...sound.sublist(0, sound.length - 1),
        ...List.filled(32, 0)
      ],
      'corrupt checksum': [...corrupted, ...List.filled(32, 0)],
      'missing end': [...missingEnd, ...List.filled(32, 0)],
      'unfinished packet': [...unfinished, ...List.filled(32, 0)],
      'reused stream serial': [...sound, ...sound],
    };
    for (final entry in invalid.entries) {
      final sample = fixture(png(2, 2),
          sound: Uint8List.fromList(entry.value), soundType: 'audio/ogg');
      expect(() => inspect(sample, limits(maxBundleBytes: 1024 * 1024)),
          throwsFormatException,
          reason: entry.key);
    }
    final oversized = Uint8List(maxBattleRecipeSoundBytes + 1)
      ..setRange(0, sound.length, sound);
    expect(() => inspectBattleRecipeSound(oversized, 'audio/ogg'),
        throwsFormatException);
  });

  test('rejects long Opus audio hidden behind tiny increasing granules', () {
    final declaredLong = opusWithPackets(6251);
    final hiddenLong = opusWithPackets(6251,
        granule: (page, packets, isLast) => 312 + (page + 1) * 48);
    expect(() => inspectBattleRecipeSound(declaredLong, 'audio/ogg'),
        throwsFormatException);
    expect(() => inspectBattleRecipeSound(hiddenLong, 'audio/ogg'),
        throwsFormatException);
  });

  test('accepts Opus offsets, end trimming and a packet split across pages',
      () {
    final packet = [0xfb, 0x41, 252, 0xff, 0xfe, ...List.filled(252, 0)];
    final split = Uint8List.fromList([
      ...opusHeaders(),
      ...opusPage(2, 0, null, [255], packet.sublist(0, 255)),
      ...opusPage(3, 5, 960, [packet.length - 255], packet.sublist(255)),
    ]);
    final sounds = {
      'initial offset':
          opusWithPackets(100, initialOffset: 12345, finalTrim: 100),
      '120 seconds': opusWithPackets(6001, finalTrim: 648),
      'large valid end trim':
          opusWithPackets(6251, finalPagePackets: 251, finalTrim: 240648),
      'packet split across pages': split,
    };
    for (final entry in sounds.entries) {
      expect(() => inspectBattleRecipeSound(entry.value, 'audio/ogg'),
          returnsNormally,
          reason: entry.key);
    }
  });

  test('rejects inconsistent Opus granules and invalid frame counts', () {
    final sounds = {
      'middle granule': opusWithPackets(150,
          granule: (page, packets, isLast) =>
              page == 1 ? 48048 : packets * 960),
      'end granule beyond packets': opusWithPackets(100,
          granule: (page, packets, isLast) => packets * 960 + (isLast ? 1 : 0)),
      'missing frame count': opusWithPackets(1, packet: [0xfb]),
      'zero frame count': opusWithPackets(1, packet: [0xfb, 0, 0xfe]),
      'packet longer than 120 ms': opusWithPackets(1, packet: [0xfb, 7, 0xfe]),
    };
    for (final entry in sounds.entries) {
      expect(() => inspectBattleRecipeSound(entry.value, 'audio/ogg'),
          throwsFormatException,
          reason: entry.key);
    }
  });

  test('accepts Opus frame durations and valid frame counts', () {
    final cases = <(List<int>, int)>[
      ([0x00, 0xff, 0xfe], 480),
      ([0x18, 0xff, 0xfe], 2880),
      ([0x60, 0xff, 0xfe], 480),
      ([0x68, 0xff, 0xfe], 960),
      ([0x80, 0xff, 0xfe], 120),
      ([0x98, 0xff, 0xfe], 960),
      ([0x81, 0xff, 0xfe], 240),
      ([0x82, 0xff, 0xfe], 240),
      ([0xfb, 6, 0xff, 0xfe], 5760),
    ];
    for (final (packet, samples) in cases) {
      final sound = opusWithPackets(10,
          packetsPerPage: 5, samplesPerPacket: samples, packet: packet);
      expect(
          () => inspectBattleRecipeSound(sound, 'audio/ogg'), returnsNormally,
          reason: 'TOC ${packet.first} with $samples samples');
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
