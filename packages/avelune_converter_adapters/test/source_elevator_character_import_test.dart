import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

final class _OverrideFiles implements SourceFilePort {
  _OverrideFiles(this.original, this.fileId, this.bytes);
  final SourceFilePort original;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) async =>
      id == fileId ? List.of(bytes) : original.read(id);
}

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final supplemental = Platform
          .environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS']
          ?.split('|') ??
      const <String>[];
  group('historical tall source charset fixture', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {40}, supplementalRoots: supplemental);
      source = fixture.source;
      files = fixture.files;
    });
    test(
        'exact 80 pixel elevator panels retain every RGBA pixel in 96 pixel frames',
        () async {
      final imported = await const SourceEventCharacterImporter().read(
          snapshot: source.snapshot,
          files: files,
          charsetName: 'OBJ_FRLG_Elevator',
          sourcePattern: 0,
          sourceDirection: 2);
      expect(imported.character.frameHeight, 3);
      expect(imported.nativeFrameHeightPx, 96);
      expect(imported.sourceOffsetYPx, 16);
      expect(imported.depthOffsetPx, 31);
      final original =
          image.decodePng(Uint8List.fromList(imported.imageBytes))!;
      final native = image.decodePng(Uint8List.fromList(imported.outputBytes))!;
      expect((native.width, native.height), (256, 384));
      for (var row = 0; row < 4; row++) {
        for (var column = 0; column < 4; column++) {
          for (var y = 0; y < 80; y++) {
            for (var x = 0; x < 32; x++) {
              final before = original.getPixel(column * 32 + x, row * 80 + y);
              final after =
                  native.getPixel(column * 64 + 16 + x, row * 96 + 16 + y);
              expect([after.r, after.g, after.b, after.a],
                  [before.r, before.g, before.b, before.a]);
            }
          }
        }
      }
      for (var row = 0; row < 4; row++) {
        for (var column = 0; column < 4; column++) {
          for (var y = 0; y < 96; y++) {
            for (var x = 0; x < 64; x++) {
              if (x < 16 || x >= 48 || y < 16) {
                expect(native.getPixel(column * 64 + x, row * 96 + y).a, 0);
              }
            }
          }
        }
      }
      for (final clip in imported.character.animations) {
        expect(clip.frames.single.source.height, 96);
      }
      expect(4 * 32 + 32 - 96 + imported.sourceOffsetYPx, 4 * 32 + 32 - 80);
    });

    test('changed source pixels and native image quotas are refused',
        () async {
      final entry = source.snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Graphics/Characters/OBJ_FRLG_Elevator.png');
      final bytes = await files.read(entry.fileId);
      final raster = image.decodePng(Uint8List.fromList(bytes))!;
      raster.setPixelRgba(0, 0, 255, 0, 0, 255);
      final changed = image.encodePng(raster);
      await expectLater(
          const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: _OverrideFiles(files, entry.fileId, changed),
              charsetName: 'OBJ_FRLG_Elevator',
              sourcePattern: 0,
              sourceDirection: 2),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'source.event_character.source_changed')));
      await expectLater(
          const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: files,
              charsetName: 'OBJ_FRLG_Elevator',
              sourcePattern: 0,
              sourceDirection: 2,
              limits: const NativeWriteLimits(maxImagePixels: 65536)),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              'source.event_character.image_limit')));
    });
  },
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);
}
