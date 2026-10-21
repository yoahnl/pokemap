import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;
  final reads = <ConverterId>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    reads.add(id);
    return bytes[id]!;
  }
}

({SourceSnapshot snapshot, _Files files}) _fixture({
  Map<String, List<int>> additional = const {},
  List<String> excludedPaths = const [],
  Set<String> directories = const {},
  SourceScanState state = SourceScanState.complete,
}) {
  final png =
      image.encodePng(image.Image(width: 128, height: 192, numChannels: 4));
  final payloads = {
    'PBS/metadata.txt': utf8.encode(
        '[1]\nWalkCharset = player_M\nRunCharset = player_M_run\nCycleCharset = player_M_bike\n[2]\nWalkCharset = player_F\n'),
    'Graphics/Characters/player_M.png': png,
    'Graphics/Characters/player_M_run.png': png,
    'Graphics/Characters/player_M_bike.png': png,
    'Graphics/Characters/player_F.png': png,
    ...additional,
  };
  final entries = <SourceFileEntry>[];
  final bytes = <ConverterId, List<int>>{};
  for (final entry in payloads.entries) {
    final id = ConverterId('outfit:${entries.length}');
    entries.add(SourceFileEntry(
        fileId: id,
        relativePath: entry.key,
        kind: SourceNodeKind.file,
        byteLength: entry.value.length,
        sha256: Sha256Hash(crypto.sha256.convert(entry.value).toString()),
        format: entry.key.endsWith('.png') ? 'raster' : 'text',
        family: 'fixture'));
    bytes[id] = List<int>.from(entry.value);
  }
  for (final directory in directories) {
    entries.add(SourceFileEntry(
        fileId: ConverterId('outfit:directory:${entries.length}'),
        relativePath: directory,
        kind: SourceNodeKind.directory,
        sha256: null,
        byteLength: 0,
        format: 'directory',
        family: 'fixture'));
  }
  return (
    snapshot: SourceSnapshot(
        logicalProjectNamespace: ConverterId('source-outfit-test'),
        policyHash: SourceScanPolicy().canonicalHash,
        entries: entries,
        diagnostics: [],
        excludedPaths: excludedPaths,
        profileEvidence: [],
        state: state),
    files: _Files(bytes)
  );
}

Matcher _code(String value) =>
    isA<ContractError>().having((error) => error.code, 'code', value);

void _pixelsPreserved(SourcePlayerCharacterSheet sheet) {
  final source = image.decodePng(Uint8List.fromList(sheet.imageBytes))!;
  final native = image.decodePng(Uint8List.fromList(sheet.outputBytes))!;
  final offsetX = (64 - sheet.frameWidthPx) ~/ 2;
  final offsetY = 64 - sheet.frameHeightPx;
  expect([native.width, native.height], [256, 256]);
  for (var y = 0; y < native.height; y++) {
    for (var x = 0; x < native.width; x++) {
      final pixel = native.getPixel(x, y);
      final localX = x % 64 - offsetX, localY = y % 64 - offsetY;
      if (localX >= 0 &&
          localX < sheet.frameWidthPx &&
          localY >= 0 &&
          localY < sheet.frameHeightPx) {
        final original = source.getPixel(x ~/ 64 * sheet.frameWidthPx + localX,
            y ~/ 64 * sheet.frameHeightPx + localY);
        expect([pixel.r, pixel.g, pixel.b, pixel.a],
            [original.r, original.g, original.b, original.a]);
      } else {
        expect([pixel.r, pixel.g, pixel.b, pixel.a], [0, 0, 0, 0]);
      }
    }
  }
}

void main() {
  test(
      'outfit one selects per-declaration suffixes and preserves every RGBA pixel',
      () async {
    final source = image.Image(width: 128, height: 192, numChannels: 4);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(
            x, y, x % 256, y % 256, (x + y) % 256, [0, 127, 255][(x + y) % 3]);
      }
    }
    final png = image.encodePng(source);
    final fixture = _fixture(additional: {
      for (final name in ['player_M', 'player_M_run', 'player_M_bike'])
        'Graphics/Characters/${name}_1.png': png,
    });
    final result = await const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot, files: fixture.files, selectedOutfit: 1);
    expect(result.selectedOutfit, 1);
    expect(result.evidence['selectedOutfit'], 1);
    expect(result.charsetName, 'player_M_1');
    expect(result.sheets.map((sheet) => sheet.charsetName),
        ['player_M_1', 'player_M_run_1', 'player_M_bike_1']);
    for (final sheet in result.sheets) {
      expect(sheet.evidence['outfitSelection'], 'attestedOutfitSuffix');
      _pixelsPreserved(sheet);
    }
    final again = await const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot, files: fixture.files, selectedOutfit: 1);
    expect(again.evidence, result.evidence);
    expect(again.character, result.character);
  });

  test(
      'absent suffix falls back independently while outfit identity remains distinct',
      () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_run_1.png':
          image.encodePng(image.Image(width: 192, height: 192, numChannels: 4))
    });
    final importer = const SourcePlayerCharacterImporter();
    final base =
        await importer.read(snapshot: fixture.snapshot, files: fixture.files);
    final selected = await importer.read(
        snapshot: fixture.snapshot, files: fixture.files, selectedOutfit: 1);
    expect(selected.sheets.map((sheet) => sheet.charsetName),
        ['player_M', 'player_M_run_1', 'player_M_bike']);
    expect(selected.sheets.first.evidence['outfitSelection'],
        'attestedBaseSuffixAbsent');
    expect(selected.character.id, isNot(base.character.id));
  });

  test('explicit outfit zero preserves prior IDs and ignores suffix zero',
      () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_0.png': [0]
    });
    final result = await const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot, files: fixture.files, selectedOutfit: 0);
    final identity = canonicalHashOf({
      'kind': 'sourcePlayerCharacterIdentity',
      'version': 1,
      'logicalProjectNamespace': fixture.snapshot.logicalProjectNamespace.value,
      'metadataPath': 'PBS/metadata.txt',
      'selectedHeaderId': 1
    }).value;
    expect(
        result.character.id, 'essentials-player-${identity.substring(0, 16)}');
    expect(result.tilesetId, 'source_player_${identity.substring(0, 32)}');
    expect(result.charsetName, 'player_M');
  });

  for (final value in [-1, 65536]) {
    test('invalid outfit $value is rejected before any source read', () async {
      final fixture = _fixture();
      await expectLater(
          const SourcePlayerCharacterImporter().read(
              snapshot: fixture.snapshot,
              files: fixture.files,
              selectedOutfit: value),
          throwsA(_code('source.player.outfit_invalid')));
      expect(fixture.files.reads, isEmpty);
    });
  }

  test('outfit upper boundary has an attested base fallback', () async {
    final fixture = _fixture();
    final result = await const SourcePlayerCharacterImporter().read(
        snapshot: fixture.snapshot,
        files: fixture.files,
        selectedOutfit: 65535);
    expect(result.evidence['selectedOutfit'], 65535);
    expect(result.charsetName, 'player_M');
  });

  test('incomplete inventory cannot authorize suffix absence', () async {
    final fixture = _fixture(state: SourceScanState.partial);
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.snapshot_incomplete')));
  });

  test('excluded suffix cannot silently fall back', () async {
    final fixture =
        _fixture(excludedPaths: ['Graphics/Characters/player_M_1.png']);
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.outfit_absence_unattested')));
  });

  test('unsupported suffix bitmap cannot silently fall back', () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_1.jpg': [1, 2, 3]
    });
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.outfit_bitmap_unsupported')));
  });

  test('two source bitmap formats cannot make outfit selection ambiguous',
      () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_1.png':
          image.encodePng(image.Image(width: 128, height: 192)),
      'Graphics/Characters/player_M_1.jpg': [1, 2, 3],
    });
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.outfit_ambiguous')));
  });

  test('a suffix directory cannot make fallback appear safe', () async {
    final fixture =
        _fixture(directories: {'Graphics/Characters/player_M_1.png'});
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.outfit_unattested')));
  });

  test('excluded character directory prevents attesting suffix absence',
      () async {
    final fixture = _fixture(excludedPaths: ['Graphics/Characters']);
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.outfit_absence_unattested')));
  });

  test('case-colliding suffixes are rejected by the complete inventory', () {
    expect(
        () => _fixture(additional: {
              'Graphics/Characters/player_M_1.png': [1],
              'Graphics/Characters/PLAYER_M_1.png': [2],
            }),
        throwsA(_code('source.snapshot_collision')));
  });

  test('present malformed suffix blocks fallback to a valid base', () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_1.png': [1, 2, 3]
    });
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.image_invalid')));
  });

  test('changed suffix bytes block fallback to a valid base', () async {
    final fixture = _fixture(additional: {
      'Graphics/Characters/player_M_1.png':
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4))
    });
    final id = fixture.snapshot.entries
        .singleWhere((entry) => entry.relativePath.endsWith('player_M_1.png'))
        .fileId;
    fixture.files.bytes[id]![0] ^= 1;
    await expectLater(
        const SourcePlayerCharacterImporter().read(
            snapshot: fixture.snapshot,
            files: fixture.files,
            selectedOutfit: 1),
        throwsA(_code('source.player.source_changed')));
  });

  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  for (final variant in [(1, 'M'), (2, 'F')]) {
    test(
        'real Kanto ${variant.$2} outfit one imports three unresampled original sheets',
        () async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {1, 2, 7},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                      '')
                  .split('|')
                  .where((value) => value.isNotEmpty)
                  .toList());
      final result = await const SourcePlayerCharacterImporter().read(
          snapshot: fixture.source.snapshot,
          files: fixture.files,
          selectedHeaderId: variant.$1,
          selectedOutfit: 1);
      expect(result.sheets.map((sheet) => sheet.charsetName), [
        'player_${variant.$2}_1',
        'player_${variant.$2}_run_1',
        'player_${variant.$2}_bike_1'
      ]);
      for (final sheet in result.sheets) {
        expect(sheet.evidence['outfitSelection'], 'attestedOutfitSuffix');
        _pixelsPreserved(sheet);
      }
      final evidence = {
        'kind': 'attestedSourceOutfitPixels',
        'headerId': variant.$1,
        'gender': variant.$2,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'sourceSnapshotHash': fixture.source.snapshot.canonicalHash.value,
        'allOriginalPixelsPreserved': true,
        'import': result.evidence,
      };
      final output = Platform.environment['AVELUNE_OUTFIT_RECEIPT'];
      if (output != null) {
        await File('$output.${variant.$2}.json')
            .writeAsString(jsonEncode(evidence), flush: true);
      }
      stdout.writeln(jsonEncode(evidence));
    }, skip: root == null || snapshot == null);
  }
}
