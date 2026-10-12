import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_character_import.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Files implements SourceFilePort {
  _Files(this.payloads);
  final Map<ConverterId, List<int>> payloads;
  final reads = <ConverterId>[];

  @override
  Future<List<int>> read(ConverterId fileId) async {
    reads.add(fileId);
    return payloads[fileId]!;
  }
}

({SourceSnapshot snapshot, _Files files}) _fixture({
  int width = 128,
  int height = 128,
  String charsetName = 'NPC 01',
  String namespace = 'event-characters',
  List<int>? imageBytes,
  bool missing = false,
  bool ambiguous = false,
  SourceNodeKind kind = SourceNodeKind.file,
  bool hash = true,
  int? attestedLength,
  SourceScanState state = SourceScanState.complete,
  bool unrelated = false,
}) {
  final raster = image.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      raster.setPixelRgba(x, y, x % 256, y % 256, 73, 255);
    }
  }
  final bytes = imageBytes ?? image.encodePng(raster);
  final path = 'Graphics/Characters/$charsetName.png';
  final entries = <SourceFileEntry>[];
  final payloads = <ConverterId, List<int>>{};
  void entry(String relativePath, String id, List<int> data) {
    final fileId = ConverterId(id);
    entries.add(SourceFileEntry(
      fileId: fileId,
      relativePath: relativePath,
      kind: kind,
      byteLength:
          kind == SourceNodeKind.file ? attestedLength ?? data.length : 0,
      sha256: hash && kind == SourceNodeKind.file
          ? Sha256Hash(crypto.sha256.convert(data).toString())
          : null,
      family: 'graphics',
      format: 'raster',
    ));
    payloads[fileId] = data;
  }

  if (!missing) entry(path, 'source-npc-image', bytes);
  if (ambiguous) entry(path.toLowerCase(), 'source-npc-ambiguous', bytes);
  if (unrelated) entry('Graphics/Pictures/other.png', 'other-image', bytes);
  return (
    snapshot: SourceSnapshot(
      logicalProjectNamespace: ConverterId(namespace),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: entries,
      diagnostics: const [],
      excludedPaths: const [],
      profileEvidence: const [],
      state: state,
    ),
    files: _Files(payloads),
  );
}

Future<SourceEventCharacterImport> _read(
  ({SourceSnapshot snapshot, _Files files}) fixture, {
  String charsetName = 'NPC 01',
  int pattern = 2,
  int direction = 6,
  NativeWriteLimits limits = const NativeWriteLimits(),
  ScanCancellation? cancellation,
}) =>
    const SourceEventCharacterImporter().read(
      snapshot: fixture.snapshot,
      files: fixture.files,
      charsetName: charsetName,
      sourcePattern: pattern,
      sourceDirection: direction,
      limits: limits,
      cancellation: cancellation,
    );

Matcher _code(String value) =>
    isA<ContractError>().having((error) => error.code, 'code', value);

void main() {
  test('preserves the PNG and selects the exact fixed source pattern',
      () async {
    final fixture = _fixture();
    final result = await _read(fixture);
    expect(result.imageBytes, fixture.files.payloads[result.imageFile.fileId]);
    expect(crypto.sha256.convert(result.imageBytes).toString(),
        result.imageFile.sha256!.value);
    expect(result.artifact.rawSha256, isNot(result.imageFile.sha256));
    expect(result.frameWidthPx, 32);
    expect(result.frameHeightPx, 32);
    expect(result.character.frameWidth, 2);
    expect(result.character.frameHeight, 2);
    expect(result.character.animations, hasLength(4));
    expect(result.facing, EntityFacing.east);
    expect(result.binding.sourcePattern, 2);
    expect(result.binding.sourceDirection, 6);
    expect(result.binding.sourceSnapshotHash, fixture.snapshot.canonicalHash);
    expect(result.binding.sourceFileId, result.imageFile.fileId);
    expect(result.binding.sourceFileHash, result.imageFile.sha256);
    expect(
        result.bindingKey,
        sourceEventCharacterBindingKey(
            characterName: 'NPC 01', pattern: 2, direction: 6));
    const rows = {
      EntityFacing.south: 0,
      EntityFacing.west: 1,
      EntityFacing.east: 2,
      EntityFacing.north: 3,
    };
    for (final row in rows.entries) {
      final clip = result.character.animations
          .singleWhere((clip) => clip.direction == row.key);
      expect(clip.state, CharacterAnimationState.idle);
      expect(clip.frames, hasLength(1));
      expect(clip.sourceAssetId, result.assetId);
      expect(clip.frames.single.source,
          TilesetSourceRect(x: 128, y: row.value * 64, width: 64, height: 64));
    }
    expect(result.evidence['sourcePixelsPreserved'], isTrue);
    expect(result.evidence['sourcePixelsResampled'], isFalse);
    expect(result.evidence['sourceScriptsExecuted'], 0);
    expect(result.evidence['sourceMovementTimingQualified'], isFalse);
    expect(result.evidence['initialFrame'], {
      'sourcePattern': 2,
      'sourceDirection': 6,
      'facing': 'east',
      'x': 64,
      'y': 64,
      'width': 32,
      'height': 32,
    });
    expect(fixture.files.reads, [result.imageFile.fileId]);
    expect(() => result.imageBytes[0] = 0, throwsUnsupportedError);
    expect(() => result.mutations.clear(), throwsUnsupportedError);
  });

  test('emits canonical image, stable identity, label and four idle actions',
      () async {
    final result = await _read(_fixture());
    expect(result.artifacts, [result.artifact]);
    expect(result.mutations.map((mutation) => mutation.actionId), [
      'tileset.import_image',
      'characterStudio.character.create',
      'characterStudio.character.update',
      ...List.filled(4, 'characterStudio.animationClip.upsert'),
    ]);
    final import = result.mutations[0];
    expect(import.parameters['artifactHandle'], result.artifact.handle);
    expect(import.parameters['tileWidth'], 32);
    expect(import.parameters['tileHeight'], 32);
    expect(import.targetEntityIds.map((id) => id.value),
        [result.tilesetId, result.assetId]);
    final create = result.mutations[1];
    expect(
        (create.parameters['name'] as String)
            .toLowerCase()
            .replaceAll(' ', '-'),
        result.character.id);
    expect(result.character.name, 'NPC 01 · pattern 2');
    expect(result.mutations[2].parameters, {
      'characterId': result.character.id,
      'name': result.character.name,
    });
    for (final mutation in result.mutations) {
      expect(mutation.sourceEntityIds, [result.imageFile.fileId]);
      expect(mutation.actionId, isNot('characterStudio.character.setDefault'));
      expect(mutation.actionId, isNot('map.save'));
    }
    final operations =
        result.mutations.map((mutation) => mutation.operationId).toSet();
    expect(operations, hasLength(7));
  });

  test('keeps identity independent of snapshot changes and facing', () async {
    final first = await _read(_fixture());
    final changedSnapshot =
        await _read(_fixture(unrelated: true), direction: 2);
    expect(first.sourceSnapshotHash, isNot(changedSnapshot.sourceSnapshotHash));
    expect(first.character.id, changedSnapshot.character.id);
    expect(first.tilesetId, changedSnapshot.tilesetId);
    expect(first.artifact.handle, changedSnapshot.artifact.handle);
    expect(first.bindingKey, isNot(changedSnapshot.bindingKey));
    final changedPattern = await _read(_fixture(), pattern: 3);
    expect(first.character.id, isNot(changedPattern.character.id));
    expect(first.tilesetId, changedPattern.tilesetId);
    final changedNamespace = await _read(_fixture(namespace: 'other-source'));
    expect(first.character.id, isNot(changedNamespace.character.id));
    final changedPixels = image.Image(width: 128, height: 128, numChannels: 4);
    changedPixels.setPixelRgba(0, 0, 255, 0, 0, 255);
    final changedImage =
        await _read(_fixture(imageBytes: image.encodePng(changedPixels)));
    expect(first.character.id, isNot(changedImage.character.id));
    expect(first.tilesetId, isNot(changedImage.tilesetId));
  });

  test('shares one canonical image mutation across source patterns', () async {
    final first = await _read(_fixture(), pattern: 0);
    final second = await _read(_fixture(), pattern: 3);
    expect(first.mutations.first.toJson(0), second.mutations.first.toJson(0));
    expect(first.character.id, isNot(second.character.id));
    expect(first.artifact.handle, second.artifact.handle);
  });

  for (final entry in {
    2: EntityFacing.south,
    4: EntityFacing.west,
    6: EntityFacing.east,
    8: EntityFacing.north
  }.entries) {
    test('maps RMXP source direction ${entry.key} without guessing', () async {
      expect(
          (await _read(_fixture(), direction: entry.key)).facing, entry.value);
    });
  }

  test('admits bounded 4x4 frames including standard Essentials heights',
      () async {
    for (final size in [
      (128, 128),
      (128, 160),
      (128, 192),
      (256, 128),
      (256, 256),
      (100, 120)
    ]) {
      final result = await _read(_fixture(width: size.$1, height: size.$2));
      expect(result.frameWidthPx, size.$1 ~/ 4);
      expect(result.frameHeightPx, size.$2 ~/ 4);
      expect(result.character.frameWidth, 2);
      expect(result.character.frameHeight, 2);
    }
  });

  test('copies every source pixel and pads only transparent native pixels',
      () async {
    final fixture = _fixture(height: 192);
    final result = await _read(fixture, pattern: 3, direction: 8);
    final original = image.decodePng(Uint8List.fromList(result.imageBytes))!;
    final native = image.decodePng(Uint8List.fromList(result.outputBytes))!;
    expect((native.width, native.height), (256, 256));
    expect(result.sourceOffsetXPx, 16);
    expect(result.sourceOffsetYPx, 16);
    expect(result.depthOffsetPx, 31);
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        for (var y = 0; y < 64; y++) {
          for (var x = 0; x < 64; x++) {
            final actual = native.getPixel(column * 64 + x, row * 64 + y);
            if (x >= 16 && x < 48 && y >= 16) {
              final expected =
                  original.getPixel(column * 32 + x - 16, row * 48 + y - 16);
              expect([actual.r, actual.g, actual.b, actual.a],
                  [expected.r, expected.g, expected.b, expected.a]);
            } else {
              expect(actual.a, 0);
            }
          }
        }
      }
    }
    expect((await _read(_fixture())).depthOffsetPx, 0);
  });

  test('rejects incomplete snapshots before reading', () async {
    final fixture = _fixture(state: SourceScanState.partial);
    await expectLater(_read(fixture),
        throwsA(_code('source.event_character.snapshot_incomplete')));
    expect(fixture.files.reads, isEmpty);
  });

  test('rejects missing and non-file image entries without reading', () async {
    for (final entry in [
      (_fixture(missing: true), 'source.event_character.image_missing'),
      (
        _fixture(kind: SourceNodeKind.directory),
        'source.event_character.image_unattested'
      )
    ]) {
      await expectLater(_read(entry.$1), throwsA(_code(entry.$2)));
      expect(entry.$1.files.reads, isEmpty);
    }
  });

  test('canonical snapshot rejects ambiguous, linked or unhashed source assets',
      () {
    expect(() => _fixture(ambiguous: true),
        throwsA(_code('source.snapshot_collision')));
    expect(() => _fixture(kind: SourceNodeKind.link),
        throwsA(_code('source.snapshot_incomplete')));
    expect(() => _fixture(hash: false),
        throwsA(_code('source.snapshot_incomplete')));
  });

  test('rejects dynamic names, path traversal and extensions before reading',
      () async {
    for (final name in [
      '',
      '../NPC',
      '/NPC',
      'NPC/other',
      r'NPC\other',
      'NPC.png',
      ' NPC',
      'NPC ',
      'NPC\nother'
    ]) {
      final fixture = _fixture();
      await expectLater(_read(fixture, charsetName: name),
          throwsA(_code('source.event_character.charset_invalid')));
      expect(fixture.files.reads, isEmpty);
    }
  });

  test('rejects invalid source pattern and direction before reading', () async {
    for (final pattern in [-1, 4]) {
      final fixture = _fixture();
      await expectLater(_read(fixture, pattern: pattern),
          throwsA(_code('source.event_character.pattern_invalid')));
      expect(fixture.files.reads, isEmpty);
    }
    await expectLater(_read(_fixture(), direction: 0),
        throwsA(_code('source.event_character.direction_invalid')));
  });

  test('rejects changed bytes or length against the snapshot hash', () async {
    final fixture = _fixture();
    fixture.files.payloads.values.first[0] = 0;
    await expectLater(_read(fixture),
        throwsA(_code('source.event_character.source_changed')));
    await expectLater(_read(_fixture(attestedLength: 1)),
        throwsA(_code('source.event_character.source_changed')));
  });

  test('rejects sheet and frame layouts the native atlas cannot express',
      () async {
    for (final size in [(127, 128), (128, 129), (512, 128), (128, 512)]) {
      await expectLater(_read(_fixture(width: size.$1, height: size.$2)),
          throwsA(_code('source.event_character.sheet_geometry')));
    }
  });

  test('rejects malformed PNG and a valid PNG with trailing bytes', () async {
    await expectLater(_read(_fixture(imageBytes: [0, 1, 2])),
        throwsA(_code('source.event_character.image_invalid')));
    final fixture = _fixture();
    final bytes = fixture.files.payloads.values.first;
    await expectLater(_read(_fixture(imageBytes: [...bytes, 0])),
        throwsA(_code('source.event_character.image_invalid')));
  });

  test('applies image, artifact and mutation quotas before producing output',
      () async {
    final fixture = _fixture();
    await expectLater(
        _read(fixture, limits: const NativeWriteLimits(maxArtifactBytes: 33)),
        throwsA(_code('source.event_character.image_limit')));
    expect(fixture.files.reads, isEmpty);
    await expectLater(
        _read(_fixture(), limits: const NativeWriteLimits(maxImagePixels: 100)),
        throwsA(_code('source.event_character.image_limit')));
    await expectLater(
        _read(_fixture(), limits: const NativeWriteLimits(maxMutations: 6)),
        throwsA(_code('source.event_character.mutation_limit')));
    await expectLater(
        _read(_fixture(),
            limits: const NativeWriteLimits(maxTotalArtifactBytes: 33)),
        throwsA(_code('source.event_character.image_limit')));
  });

  test('honors cancellation before source reads', () async {
    final fixture = _fixture();
    final cancellation = ScanCancellation()..cancel();
    await expectLater(_read(fixture, cancellation: cancellation),
        throwsA(_code('source.cancelled')));
    expect(fixture.files.reads, isEmpty);
  });
}
