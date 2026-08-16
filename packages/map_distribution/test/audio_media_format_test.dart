import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('detectAudioMediaFormat', () {
    final cases = <({
      String name,
      List<int> bytes,
      AudioMediaFormat format,
    })>[
      (
        name: 'ogg',
        bytes: <int>[0x4f, 0x67, 0x67, 0x53, 0x00],
        format: AudioMediaFormat.ogg,
      ),
      (
        name: 'mp3 with ID3',
        bytes: <int>[0x49, 0x44, 0x33, 0x04],
        format: AudioMediaFormat.mp3,
      ),
      (
        name: 'mp3 frame',
        bytes: <int>[0xff, 0xfb, 0x94, 0xc4],
        format: AudioMediaFormat.mp3,
      ),
      (
        name: 'wav',
        bytes: <int>[
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x41,
          0x56,
          0x45,
        ],
        format: AudioMediaFormat.wav,
      ),
      (
        name: 'flac',
        bytes: <int>[0x66, 0x4c, 0x61, 0x43, 0x00],
        format: AudioMediaFormat.flac,
      ),
      (
        name: 'm4a',
        bytes: <int>[0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70],
        format: AudioMediaFormat.m4a,
      ),
      (
        name: 'aac adts',
        bytes: <int>[0xff, 0xf1, 0x50, 0x80],
        format: AudioMediaFormat.aac,
      ),
    ];

    for (final testCase in cases) {
      test('detects ${testCase.name}', () {
        expect(
          detectAudioMediaFormat(Uint8List.fromList(testCase.bytes)),
          testCase.format,
        );
      });
    }

    test('does not mistake AAC ADTS for MP3', () {
      expect(
        detectAudioMediaFormat(
          Uint8List.fromList(<int>[0xff, 0xf9, 0x50, 0x80]),
        ),
        AudioMediaFormat.aac,
      );
    });

    test('rejects unknown bytes', () {
      expect(
        detectAudioMediaFormat(Uint8List.fromList(<int>[1, 2, 3, 4])),
        isNull,
      );
    });
  });

  group('GamePackageContentValidator audio formats', () {
    const validator = GamePackageContentValidator(GamePackageSecurityPolicy());

    test('accepts AAC with a matching extension and media type', () {
      final bytes = Uint8List.fromList(<int>[0xff, 0xf1, 0x50, 0x80]);

      expect(
        () => validator.validate(
          GamePackageFileEntry(
            path: 'project/assets/cries/sample.aac',
            size: bytes.length,
            sha256: '0' * 64,
            mediaType: 'audio/aac',
          ),
          bytes,
        ),
        returnsNormally,
      );
    });

    test('rejects MP3 bytes disguised with an OGG extension', () {
      final bytes = Uint8List.fromList(<int>[0xff, 0xfb, 0x94, 0xc4]);

      expect(
        () => validator.validate(
          GamePackageFileEntry(
            path: 'project/assets/cries/sample.ogg',
            size: bytes.length,
            sha256: '0' * 64,
            mediaType: 'audio/ogg',
          ),
          bytes,
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'executableContent',
          ),
        ),
      );
    });
  });
}
