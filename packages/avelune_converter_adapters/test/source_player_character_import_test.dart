import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);

  final Map<ConverterId, List<int>> bytes;
  final List<ConverterId> reads = [];

  @override
  Future<List<int>> read(ConverterId fileId) async {
    reads.add(fileId);
    return bytes[fileId]!;
  }
}

({SourceSnapshot snapshot, _Files files}) _fixture({
  String metadata = '\uFEFF[0]\r\nStartMoney = 3000\r\n'
      '[1]\r\nTrainerType = player_M\r\nWalkCharset = player_M\r\n'
      'RunCharset = player_M_run\r\n[2]\r\nWalkCharset = player_F\r\n',
  int width = 128,
  int height = 192,
  image.Image? sourceSheet,
  bool femaleImage = true,
  bool maleImage = true,
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
    expect(result.evidence['frameTimingPolicy'], 'converterPreview150ms');
    expect(result.evidence['sourceMovementTimingQualified'], isFalse);
    expect(fixture.files.reads,
        [result.metadataFile.fileId, result.imageFile.fileId]);
    expect(() => result.imageBytes[0] = 0, throwsUnsupportedError);
    expect(() => result.outputBytes[0] = 0, throwsUnsupportedError);
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
