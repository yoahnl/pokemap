import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);

  final Map<ConverterId, List<int>> bytes;
  final List<ConverterId> reads = [];
  void Function(ConverterId)? onRead;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    reads.add(fileId);
    onRead?.call(fileId);
    return bytes[fileId]!;
  }
}

({SourceSnapshot snapshot, _Files files}) _fixture({
  String metadata = '\uFEFF[0]\r\nStartMoney = 3000\r\n'
      '[1]\r\nTrainerType = player_M\r\nWalkCharset = player_M\r\n'
      '[2]\r\nWalkCharset = player_F\r\n',
  int width = 128,
  int height = 192,
  image.Image? sourceSheet,
  bool femaleImage = true,
  bool maleImage = true,
  Map<String, List<int>?> extraFiles = const {},
  SourceScanState state = SourceScanState.complete,
}) {
  final png =
      image.encodePng(sourceSheet ?? image.Image(width: width, height: height));
  final payloads = <String, List<int>>{
    'PBS/metadata.txt': utf8.encode(metadata),
    if (maleImage) 'Graphics/Characters/player_M.png': png,
    if (femaleImage) 'Graphics/Characters/player_F.png': png,
    'Graphics/Characters/player_M_run.png': png,
    'Data/Scripts.rxdata': [4, 8, 0],
  };
  for (final entry in extraFiles.entries) {
    if (entry.value == null) {
      payloads.remove(entry.key);
    } else {
      payloads[entry.key] = entry.value!;
    }
  }
  final entries = <SourceFileEntry>[];
  final byId = <ConverterId, List<int>>{};
  for (final item in payloads.entries) {
    final fileId = ConverterId('fixture:${entries.length}');
    entries.add(SourceFileEntry(
      fileId: fileId,
      relativePath: item.key,
      kind: SourceNodeKind.file,
      byteLength: item.value.length,
      sha256: Sha256Hash(crypto.sha256.convert(item.value).toString()),
      format: item.key.endsWith('.png') ? 'raster' : 'text',
      family: item.key.startsWith('Graphics/') ? 'graphics' : 'data',
    ));
    byId[fileId] = item.value;
  }
  return (
    snapshot: SourceSnapshot(
      logicalProjectNamespace: ConverterId('source-player-test'),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: entries,
      diagnostics: const [],
      excludedPaths: const [],
      profileEvidence: const [],
      state: state,
    ),
    files: _Files(byId),
  );
}

Matcher _code(String code) =>
    isA<ContractError>().having((error) => error.code, 'code', code);

void main() {
  test(
      'imports declared running and cycling clips from their own source sheets',
      () async {
    final fixture = _fixture(
      metadata: '[1]\nWalkCharset = player_M\n'
          'RunCharset = player_M_run\nCycleCharset = player_M_bike\n',
      extraFiles: {
        'Graphics/Characters/player_M_bike.png': image
            .encodePng(image.Image(width: 192, height: 192, numChannels: 4)),
      },
    );
    final result = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    expect(result.character.animations, hasLength(20));
    for (final state in [
      CharacterAnimationState.run,
      CharacterAnimationState.bicycleIdle,
      CharacterAnimationState.bicycle,
    ]) {
      final clips = result.character.animations
          .where((clip) => clip.state == state)
          .toList();
      expect(clips.map((clip) => clip.direction).toSet(),
          EntityFacing.values.toSet());
      expect(
          clips.every((clip) => clip.sourceAssetId != result.assetId), isTrue);
      for (final clip in clips) {
        expect(
            clip.frames.map((frame) => frame.source.x),
            state == CharacterAnimationState.bicycleIdle
                ? [0]
                : [64, 128, 192, 0]);
        expect(clip.frames.every((frame) => frame.durationMs == 100), isTrue);
      }
    }
    final run = result.character.animations
        .firstWhere((clip) => clip.state == CharacterAnimationState.run);
    final bicycle = result.character.animations
        .firstWhere((clip) => clip.state == CharacterAnimationState.bicycle);
    expect(run.sourceAssetId, isNot(bicycle.sourceAssetId));
    expect(fixture.files.reads, hasLength(4));
  });

  test('imports source pixels, cardinal rows and honest preview selection',
      () async {
    final fixture = _fixture();
    final result = await const SourcePlayerCharacterImporter().read(
      snapshot: fixture.snapshot,
      files: fixture.files,
    );
    expect(result.selectedHeaderId, 1);
    expect(result.charsetName, 'player_M');
    expect(result.sheetWidth, 128);
    expect(result.sheetHeight, 192);
    expect(result.frameWidthPx, 32);
    expect(result.frameHeightPx, 48);
    expect(result.depthOffsetPx, 32);
    expect(result.sourceSnapshotHash, fixture.snapshot.canonicalHash);
    expect(result.metadataFile.relativePath, 'PBS/metadata.txt');
    expect(result.imageFile.relativePath, 'Graphics/Characters/player_M.png');
    expect(result.imageBytes, fixture.files.bytes[result.imageFile.fileId]);
    expect(result.character.tilesetId, result.tilesetId);
    expect(result.character.frameWidth, 2);
    expect(result.character.frameHeight, 2);
    expect(result.nativeSheetWidth, 256);
    expect(result.nativeSheetHeight, 256);
    expect(result.sourceOffsetXPx, 16);
    expect(result.sourceOffsetYPx, 16);
    expect(result.assetId, 'image_${result.tilesetId}');
    expect(result.character.id,
        result.character.name.toLowerCase().replaceAll(' ', '-'));
    expect(result.character.animations, hasLength(8));
    const rows = {
      EntityFacing.south: 0,
      EntityFacing.west: 1,
      EntityFacing.east: 2,
      EntityFacing.north: 3,
    };
    for (final direction in rows.entries) {
      final idle = result.character.animations.singleWhere((animation) =>
          animation.state == CharacterAnimationState.idle &&
          animation.direction == direction.key);
      final walk = result.character.animations.singleWhere((animation) =>
          animation.state == CharacterAnimationState.walk &&
          animation.direction == direction.key);
      expect(idle.sourceAssetId, result.assetId);
      expect(walk.sourceAssetId, result.assetId);
      expect(idle.frames, hasLength(1));
      expect(idle.frames.single.source.x, 0);
      expect(walk.frames, hasLength(4));
      const walkColumns = [1, 2, 3, 0];
      for (var frame = 0; frame < 4; frame++) {
        final rect = walk.frames[frame].source;
        expect(rect.x, walkColumns[frame] * 64);
        expect(rect.y, direction.value * 64);
        expect(rect.width, 64);
        expect(rect.height, 64);
      }
    }
    expect(result.evidence['selectionPolicy'], 'converterPreviewHeader');
    expect(result.evidence['sourceIdentitySelectionExecuted'], isFalse);
    expect(result.evidence['collisionFootprintChanged'], isFalse);
    expect(result.evidence['depthOffsetPx'], 32);
    expect(result.evidence['sourceScriptsExecuted'], 0);
    expect(result.evidence['walkFrameOrder'], [1, 2, 3, 0]);
    expect(
        result.evidence['frameTimingPolicy'], 'converterNativeMovementPreview');
    expect(result.evidence['walkFrameDurationMs'], 150);
    expect(result.evidence['sourceMovementTimingQualified'], isFalse);
    expect(fixture.files.reads,
        [result.metadataFile.fileId, result.imageFile.fileId]);
    expect(() => result.imageBytes[0] = 0, throwsUnsupportedError);
    expect(() => result.outputBytes[0] = 0, throwsUnsupportedError);
  });

  test('records absent optional declarations without inventing clips',
      () async {
    final fixture = _fixture();
    final result = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    expect(result.evidence['animationDeclarations'], [
      {
        'declaration': 'WalkCharset',
        'charsetName': 'player_M',
        'status': 'imported'
      },
      {
        'declaration': 'RunCharset',
        'charsetName': null,
        'status': 'notDeclared'
      },
      {
        'declaration': 'CycleCharset',
        'charsetName': null,
        'status': 'notDeclared'
      },
    ]);
    expect(result.character.animations, hasLength(8));
    expect(fixture.files.reads, hasLength(2));
  });

  for (final declaration in ['RunCharset', 'CycleCharset']) {
    test('rejects animated $declaration sheets before normalization', () async {
      final animated = image.Image(width: 128, height: 192, numChannels: 4);
      animated.addFrame(image.Image(width: 128, height: 192, numChannels: 4));
      final bytes = image.encodePng(animated);
      expect(image.PngDecoder().startDecode(bytes)!.numFrames, 2);
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = animated_player\n',
          extraFiles: {'Graphics/Characters/animated_player.png': bytes});
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.image_animation')));
    });

    test('rejects correctly attested malformed $declaration PNG data',
        () async {
      final bytes =
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4));
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = malformed_player\n',
          extraFiles: {
            'Graphics/Characters/malformed_player.png': bytes.sublist(0, 33)
          });
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.image_invalid')));
    });

    test('rejects malformed $declaration rather than treating it as absent',
        () async {
      final fixture =
          _fixture(metadata: '[1]\nWalkCharset = player_M\n$declaration\n');
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.metadata_invalid')));
      expect(fixture.files.reads, hasLength(1));
    });

    test('rejects duplicate $declaration before image reads', () async {
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = player_M_run\n$declaration = player_M_run\n');
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.metadata_ambiguous')));
      expect(fixture.files.reads, hasLength(1));
    });

    for (final value in ['../player_M_run', '/player_M_run', '']) {
      test('rejects unsafe or empty $declaration value "$value"', () async {
        final fixture = _fixture(
            metadata: '[1]\nWalkCharset = player_M\n$declaration = $value\n');
        await expectLater(
            const SourcePlayerCharacterImporter()
                .read(snapshot: fixture.snapshot, files: fixture.files),
            throwsA(_code('source.player.charset_invalid')));
        expect(fixture.files.reads, hasLength(1));
      });
    }

    test('blocks a declared but absent $declaration sheet', () async {
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = missing_player\n');
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.image_missing')));
    });

    test('validates $declaration sheet geometry', () async {
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = extra_player\n',
          extraFiles: {
            'Graphics/Characters/extra_player.png': image.encodePng(
                image.Image(width: 192, height: 191, numChannels: 4)),
          });
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.sheet_geometry')));
    });

    test('rejects $declaration frames too large for transparent padding',
        () async {
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = extra_player\n',
          extraFiles: {
            'Graphics/Characters/extra_player.png': image.encodePng(
                image.Image(width: 260, height: 192, numChannels: 4)),
          });
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.native_frame_geometry')));
    });

    test('refuses changed $declaration bytes', () async {
      final fixture = _fixture(
          metadata: '[1]\nWalkCharset = player_M\n'
              '$declaration = player_M_run\n');
      final sheet = fixture.snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Graphics/Characters/player_M_run.png');
      fixture.files.bytes[sheet.fileId]![0] ^= 1;
      await expectLater(
          const SourcePlayerCharacterImporter()
              .read(snapshot: fixture.snapshot, files: fixture.files),
          throwsA(_code('source.player.source_changed')));
    });
  }

  test('rejects optional sheet byte quota before requesting its bytes',
      () async {
    final fixture = _fixture(
        metadata: '[1]\nWalkCharset = player_M\nRunCharset = large_player\n',
        extraFiles: {
          'Graphics/Characters/large_player.png': List.filled(4194305, 0),
        });
    await expectLater(
        const SourcePlayerCharacterImporter()
            .read(snapshot: fixture.snapshot, files: fixture.files),
        throwsA(_code('source.player.image_limit')));
    final sheet = fixture.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Graphics/Characters/large_player.png');
    expect(fixture.files.reads, isNot(contains(sheet.fileId)));
  });

  test('observes cancellation during optional sheet read', () async {
    final fixture = _fixture(
        metadata: '[1]\nWalkCharset = player_M\nRunCharset = player_M_run\n');
    final cancellation = ScanCancellation();
    final sheet = fixture.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Graphics/Characters/player_M_run.png');
    fixture.files.onRead = (fileId) {
      if (fileId == sheet.fileId) cancellation.cancel();
    };
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            cancellation: cancellation),
        throwsA(_code('source.cancelled')));
  });

  test('optional images cannot bypass the cumulative source witness budget',
      () async {
    final fixture = _fixture(
        metadata: '[1]\nWalkCharset = player_M\nRunCharset = player_M_run\n');
    final recording = SourceSemanticWitnessFiles(fixture.snapshot,
        fixture.files, const NativeWriteLimits(maxArtifacts: 2), null);
    await expectLater(
        const SourcePlayerCharacterImporter()
            .read(snapshot: fixture.snapshot, files: recording),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'semantics.witness.quota')));
    expect(fixture.files.reads, hasLength(2));
  });

  test('complete source inventory rejects optional image case collisions', () {
    expect(
        () => _fixture(extraFiles: {
              'Graphics/Characters/PLAYER_M_RUN.png': [1, 2, 3],
            }),
        throwsA(_code('source.snapshot_collision')));
  });

  test('pads run and bicycle sheets without changing any source RGBA pixel',
      () async {
    final originals = <String, image.Image>{
      'RunCharset': image.Image(width: 128, height: 192, numChannels: 4),
      'CycleCharset': image.Image(width: 192, height: 192, numChannels: 4),
    };
    for (final source in originals.values) {
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, (x + y) % 256, (7 * x + y) % 256,
              (x + 13 * y) % 256, const [0, 1, 127, 255][(x + y) % 4]);
        }
      }
    }
    final fixture = _fixture(
        metadata: '[1]\nWalkCharset = player_M\n'
            'RunCharset = player_M_run\nCycleCharset = player_M_bike\n',
        extraFiles: {
          'Graphics/Characters/player_M_run.png':
              image.encodePng(originals['RunCharset']!),
          'Graphics/Characters/player_M_bike.png':
              image.encodePng(originals['CycleCharset']!),
        });
    final result = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    for (final sheet in result.sheets.skip(1)) {
      final source = originals[sheet.declaration]!;
      final raster = image.decodePng(Uint8List.fromList(sheet.outputBytes))!;
      final offsetX = (64 - sheet.frameWidthPx) ~/ 2;
      final offsetY = 64 - sheet.frameHeightPx;
      for (var y = 0; y < raster.height; y++) {
        for (var x = 0; x < raster.width; x++) {
          final pixel = raster.getPixel(x, y);
          final localX = x % 64 - offsetX;
          final localY = y % 64 - offsetY;
          if (localX >= 0 &&
              localX < sheet.frameWidthPx &&
              localY >= 0 &&
              localY < sheet.frameHeightPx) {
            final original = source.getPixel(
                x ~/ 64 * sheet.frameWidthPx + localX,
                y ~/ 64 * sheet.frameHeightPx + localY);
            expect([pixel.r, pixel.g, pixel.b, pixel.a],
                [original.r, original.g, original.b, original.a]);
          } else {
            expect([pixel.r, pixel.g, pixel.b, pixel.a], [0, 0, 0, 0]);
          }
        }
      }
      final native = sheet.evidence['nativeOutput'] as Map;
      expect(native['rawSha256'],
          crypto.sha256.convert(sheet.outputBytes).toString());
      expect(native['sourcePixelsPreserved'], isTrue);
      expect(native['sourcePixelsResampled'], isFalse);
      expect(() => sheet.imageBytes[0] = 0, throwsUnsupportedError);
      expect(() => sheet.outputBytes[0] = 0, throwsUnsupportedError);
    }
    expect(() => result.sheets.clear(), throwsUnsupportedError);
    final again = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    expect(again.evidence, result.evidence);
    expect(again.sheets.map((sheet) => sheet.outputBytes),
        result.sheets.map((sheet) => sheet.outputBytes));
  });

  test(
      'imports only the selected female header animations without identity drift',
      () async {
    final fixture = _fixture(
        metadata: '[1]\nWalkCharset = ../ignored\nRunCharset = missing\n'
            '[2]\nWalkCharset = player_F\nRunCharset = player_F_run\n'
            'CycleCharset = player_F_bike\nSurfCharset = unsupported_surf\n',
        extraFiles: {
          'Graphics/Characters/player_F_run.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
          'Graphics/Characters/player_F_bike.png': image
              .encodePng(image.Image(width: 192, height: 192, numChannels: 4)),
        });
    final result = await const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot, files: fixture.files, selectedHeaderId: 2);
    final original = _fixture();
    final baseline = await const SourcePlayerCharacterImporter().read(
        snapshot: original.snapshot,
        files: original.files,
        selectedHeaderId: 2);
    expect(result.character.id, baseline.character.id);
    expect(result.character.name, baseline.character.name);
    expect(result.character.tilesetId, baseline.character.tilesetId);
    expect(result.character.frameWidth, baseline.character.frameWidth);
    expect(result.character.frameHeight, baseline.character.frameHeight);
    expect(result.depthOffsetPx, baseline.depthOffsetPx);
    expect(result.character.animations.take(8), baseline.character.animations);
    expect(result.sheets.map((sheet) => sheet.charsetName),
        ['player_F', 'player_F_run', 'player_F_bike']);
    expect(fixture.files.reads, hasLength(4));
    expect(result.character.animations, hasLength(20));
  });

  test('pads every native frame without changing any source RGBA pixel',
      () async {
    final source = image.Image(width: 128, height: 192, numChannels: 4);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, (x + 3 * y) % 256, (7 * x + y) % 256,
            (11 * x + 13 * y) % 256, const [0, 1, 127, 255][(x + y) % 4]);
      }
    }
    final fixture = _fixture(sourceSheet: source);
    final result = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    final raster = image.decodePng(Uint8List.fromList(result.outputBytes))!;
    expect(raster.width, 256);
    expect(raster.height, 256);
    for (var y = 0; y < raster.height; y++) {
      for (var x = 0; x < raster.width; x++) {
        final pixel = raster.getPixel(x, y);
        final frameX = x % 64;
        final frameY = y % 64;
        if (frameX >= 16 && frameX < 48 && frameY >= 16) {
          final original = source.getPixel(
              x ~/ 64 * 32 + frameX - 16, y ~/ 64 * 48 + frameY - 16);
          expect([pixel.r, pixel.g, pixel.b, pixel.a],
              [original.r, original.g, original.b, original.a]);
        } else {
          expect([pixel.r, pixel.g, pixel.b, pixel.a], [0, 0, 0, 0]);
        }
      }
    }
    expect(result.imageBytes, fixture.files.bytes[result.imageFile.fileId]);
    final originalEvidence = result.evidence['sourceOriginal'] as Map;
    final nativeEvidence = result.evidence['nativeOutput'] as Map;
    expect(originalEvidence['rawSha256'], result.imageFile.sha256!.value);
    expect(originalEvidence['frameHeightPx'], 48);
    expect(nativeEvidence['rawSha256'],
        crypto.sha256.convert(result.outputBytes).toString());
    expect(nativeEvidence['frameHeightPx'], 64);
    expect(nativeEvidence['sourcePixelsPreserved'], isTrue);
    expect(nativeEvidence['sourcePixelsResampled'], isFalse);
    expect(result.depthOffsetPx, 32);
    final again = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    expect(again.outputBytes, result.outputBytes);
  });

  test('native padding does not change the source normal-height depth bonus',
      () async {
    final fixture = _fixture(height: 128);
    final result = await const SourcePlayerCharacterImporter()
        .read(snapshot: fixture.snapshot, files: fixture.files);
    expect(result.frameHeightPx, 32);
    expect(result.nativeFrameHeightPx, 64);
    expect(result.sourceOffsetYPx, 32);
    expect(result.depthOffsetPx, 1);
  });

  test('rejects source frames that cannot fit without resampling', () async {
    final fixture = _fixture(width: 260);
    await expectLater(
        const SourcePlayerCharacterImporter()
            .read(snapshot: fixture.snapshot, files: fixture.files),
        throwsA(_code('source.player.native_frame_geometry')));
  });

  test('explicit female header preserves its own attested source image',
      () async {
    final fixture = _fixture();
    final result = await const SourcePlayerCharacterImporter().read(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedHeaderId: 2,
    );
    expect(result.selectedHeaderId, 2);
    expect(result.charsetName, 'player_F');
    expect(result.imageFile.relativePath, 'Graphics/Characters/player_F.png');
    expect(fixture.files.reads,
        [result.metadataFile.fileId, result.imageFile.fileId]);
  });

  test('rejects an unrequested or absent avatar header', () async {
    final fixture = _fixture();
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
        selectedHeaderId: 3,
      ),
      throwsA(_code('source.player.header_missing')),
    );
    expect(fixture.files.reads, hasLength(1));
  });

  test('rejects duplicate declarations rather than choosing the last value',
      () async {
    final fixture = _fixture(
      metadata: '[1]\nWalkCharset = player_M\nWalkCharset = player_F\n',
    );
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.metadata_ambiguous')),
    );
    expect(fixture.files.reads, hasLength(1));
  });

  test('refuses a charset path escape before requesting an image', () async {
    final fixture = _fixture(metadata: '[1]\nWalkCharset = ../player_M\n');
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.charset_invalid')),
    );
    expect(fixture.files.reads, hasLength(1));
  });

  test('fails explicitly when the requested sheet is not in the snapshot',
      () async {
    final fixture = _fixture(maleImage: false);
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.image_missing')),
    );
    expect(fixture.files.reads, hasLength(1));
  });

  test('refuses changed metadata bytes even with a permissive file port',
      () async {
    final fixture = _fixture();
    final metadata = fixture.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'PBS/metadata.txt');
    fixture.files.bytes[metadata.fileId]![0] ^= 1;
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.source_changed')),
    );
    expect(fixture.files.reads, [metadata.fileId]);
  });

  test('refuses changed image bytes before decoding a native animation',
      () async {
    final fixture = _fixture();
    final sheet = fixture.snapshot.entries.singleWhere(
        (entry) => entry.relativePath == 'Graphics/Characters/player_M.png');
    fixture.files.bytes[sheet.fileId]![0] ^= 1;
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.source_changed')),
    );
    expect(fixture.files.reads, hasLength(2));
  });

  test('rejects incomplete inventories before any source read', () async {
    final fixture = _fixture(state: SourceScanState.partial);
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.snapshot_incomplete')),
    );
    expect(fixture.files.reads, isEmpty);
  });

  test('rejects sheets that cannot form exactly four cardinal rows', () async {
    final fixture = _fixture(height: 191);
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.sheet_geometry')),
    );
  });

  test('rejects oversized metadata before reserving a source read', () async {
    final fixture = _fixture(metadata: 'a' * 65537);
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
      ),
      throwsA(_code('source.player.metadata_limit')),
    );
    expect(fixture.files.reads, isEmpty);
  });

  test('observes cancellation before reading source files', () async {
    final fixture = _fixture();
    await expectLater(
      const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
        cancellation: ScanCancellation()..cancel(),
      ),
      throwsA(_code('source.cancelled')),
    );
    expect(fixture.files.reads, isEmpty);
  });
}
