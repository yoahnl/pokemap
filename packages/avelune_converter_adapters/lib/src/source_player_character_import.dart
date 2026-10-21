import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

final class SourcePlayerCharacterSheet {
  SourcePlayerCharacterSheet({
    required this.declaration,
    required this.charsetName,
    String? declaredCharsetName,
    this.selectedOutfit = 0,
    required this.imageFile,
    required List<int> imageBytes,
    required List<int> outputBytes,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.tilesetId,
  })  : declaredCharsetName = declaredCharsetName ?? charsetName,
        imageBytes = List.unmodifiable(imageBytes),
        outputBytes = List.unmodifiable(outputBytes);

  final String declaration;
  final String charsetName;
  final String declaredCharsetName;
  final int selectedOutfit;
  final SourceFileEntry imageFile;
  final List<int> imageBytes;
  final List<int> outputBytes;
  final int sheetWidth;
  final int sheetHeight;
  final String tilesetId;
  String get assetId => 'image_$tilesetId';
  int get frameWidthPx => sheetWidth ~/ 4;
  int get frameHeightPx => sheetHeight ~/ 4;
  int get frameDurationMs => declaration == 'WalkCharset' ? 150 : 100;
  List<CharacterAnimationState> get states => switch (declaration) {
        'WalkCharset' => const [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ],
        'RunCharset' => const [CharacterAnimationState.run],
        'CycleCharset' => const [
            CharacterAnimationState.bicycleIdle,
            CharacterAnimationState.bicycle,
          ],
        _ => throw StateError('Unsupported player charset declaration'),
      };

  Map<String, Object?> get evidence => {
        'declaration': declaration,
        'declaredCharsetName': declaredCharsetName,
        'charsetName': charsetName,
        'selectedOutfit': selectedOutfit,
        'outfitSelection': selectedOutfit == 0
            ? 'baseOutfitZero'
            : charsetName == declaredCharsetName
                ? 'attestedBaseSuffixAbsent'
                : 'attestedOutfitSuffix',
        'imageFile': imageFile.toJson(),
        'sourceOriginal': {
          'rawSha256': imageFile.sha256!.value,
          'byteLength': imageBytes.length,
          'sheetWidth': sheetWidth,
          'sheetHeight': sheetHeight,
          'frameWidthPx': frameWidthPx,
          'frameHeightPx': frameHeightPx,
        },
        'nativeOutput': {
          'rawSha256': crypto.sha256.convert(outputBytes).toString(),
          'byteLength': outputBytes.length,
          'sheetWidth': 256,
          'sheetHeight': 256,
          'frameWidthPx': 64,
          'frameHeightPx': 64,
          'sourceOffsetXPx': (64 - frameWidthPx) ~/ 2,
          'sourceOffsetYPx': 64 - frameHeightPx,
          'policy': 'transparent64PixelFramesSourceBottomCentered',
          'sourcePixelsPreserved': true,
          'sourcePixelsResampled': false,
        },
        'assetId': assetId,
        'tilesetId': tilesetId,
        'states': states
            .map((state) => state == CharacterAnimationState.bicycleIdle
                ? 'bicycle_idle'
                : state.name)
            .toList(),
        'movingFrameOrder': [1, 2, 3, 0],
        'idleFrame': 0,
        'frameDurationMs': frameDurationMs,
        'frameTimingPolicy': 'converterNativeMovementPreview',
        'sourceMovementTimingQualified': false,
      };
}

final class SourcePlayerCharacterImport {
  SourcePlayerCharacterImport({
    required this.sourceSnapshotHash,
    required this.metadataFile,
    required this.imageFile,
    required List<int> imageBytes,
    required List<int> outputBytes,
    required this.selectedHeaderId,
    this.selectedOutfit = 0,
    required this.charsetName,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frameWidthPx,
    required this.frameHeightPx,
    required this.assetId,
    required this.tilesetId,
    required this.character,
    List<SourcePlayerCharacterSheet> sheets = const [],
  })  : imageBytes = List.unmodifiable(imageBytes),
        outputBytes = List.unmodifiable(outputBytes),
        sheets = List.unmodifiable(sheets);

  final Sha256Hash sourceSnapshotHash;
  final SourceFileEntry metadataFile;
  final SourceFileEntry imageFile;
  final List<int> imageBytes;
  final List<int> outputBytes;
  final int selectedHeaderId;
  final int selectedOutfit;
  final String charsetName;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidthPx;
  final int frameHeightPx;
  final String assetId;
  final String tilesetId;
  final ProjectCharacterEntry character;
  final List<SourcePlayerCharacterSheet> sheets;
  int get nativeFrameWidthPx => 64;
  int get nativeFrameHeightPx => 64;
  int get nativeSheetWidth => nativeFrameWidthPx * 4;
  int get nativeSheetHeight => nativeFrameHeightPx * 4;
  int get sourceOffsetXPx => (nativeFrameWidthPx - frameWidthPx) ~/ 2;
  int get sourceOffsetYPx => nativeFrameHeightPx - frameHeightPx;
  int get depthOffsetPx => frameHeightPx > 32 ? 32 : 1;

  Map<String, Object?> get evidence => {
        'kind': 'sourcePlayerCharacterImport',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'metadataFile': metadataFile.toJson(),
        'imageFile': imageFile.toJson(),
        'selectedHeaderId': selectedHeaderId,
        'selectedOutfit': selectedOutfit,
        'charsetName': charsetName,
        'sheetWidth': sheetWidth,
        'sheetHeight': sheetHeight,
        'frameWidthPx': frameWidthPx,
        'frameHeightPx': frameHeightPx,
        'sourceOriginal': {
          'rawSha256': imageFile.sha256!.value,
          'byteLength': imageBytes.length,
          'sheetWidth': sheetWidth,
          'sheetHeight': sheetHeight,
          'frameWidthPx': frameWidthPx,
          'frameHeightPx': frameHeightPx,
        },
        'nativeOutput': {
          'rawSha256': crypto.sha256.convert(outputBytes).toString(),
          'byteLength': outputBytes.length,
          'sheetWidth': nativeSheetWidth,
          'sheetHeight': nativeSheetHeight,
          'frameWidthPx': nativeFrameWidthPx,
          'frameHeightPx': nativeFrameHeightPx,
          'sourceOffsetXPx': sourceOffsetXPx,
          'sourceOffsetYPx': sourceOffsetYPx,
          'policy': 'transparent64PixelFramesSourceBottomCentered',
          'sourcePixelsPreserved': true,
          'sourcePixelsResampled': false,
        },
        'depthOffsetPx': depthOffsetPx,
        'depthPolicy': 'essentialsStaticWalkingPlayer',
        'depthOracle': {
          'archive': 'Data/Scripts.rxdata',
          'characterSection': 'Game_Character',
          'characterLines': [331, 342],
          'playerSection': 'Game_Player',
          'playerLines': [33, 36],
          'requiresSourceProfileQualification': true,
        },
        'assetId': assetId,
        'tilesetId': tilesetId,
        'characterId': character.id,
        'characterHash': canonicalHashOf(character.toJson()).value,
        'selectionPolicy': selectedOutfit == 0
            ? 'converterPreviewHeader'
            : 'converterPreviewHeaderAndOutfit',
        'sourceIdentitySelectionExecuted': false,
        'sourceScriptsExecuted': 0,
        'collisionFootprintChanged': false,
        'walkFrameOrder': [1, 2, 3, 0],
        'idleFrame': 0,
        'frameTimingPolicy': 'converterNativeMovementPreview',
        'walkFrameDurationMs': 150,
        'sourceMovementTimingQualified': false,
        'animationDeclarations': [
          for (final declaration in const [
            'WalkCharset',
            'RunCharset',
            'CycleCharset',
          ])
            {
              'declaration': declaration,
              'charsetName': declaration == 'WalkCharset'
                  ? charsetName
                  : sheets
                      .where((sheet) => sheet.declaration == declaration)
                      .firstOrNull
                      ?.charsetName,
              'status': declaration == 'WalkCharset' ||
                      sheets.any((sheet) => sheet.declaration == declaration)
                  ? 'imported'
                  : 'notDeclared',
            },
        ],
        'animationSheets': sheets.map((sheet) => sheet.evidence).toList(),
        'declaredAnimationFailurePolicy': 'blockImport',
        'unsupportedSourceProfileSemantics': [
          'sourcePlayerIdentitySelection',
          'sourceStartingMap',
          'sourceStartingInventory',
          'sourceSurfDiveFishAnimations',
        ],
      };
}

final class SourcePlayerCharacterImporter {
  const SourcePlayerCharacterImporter();

  Future<SourcePlayerCharacterImport> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    int selectedHeaderId = 1,
    int selectedOutfit = 0,
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    if (snapshot.state != SourceScanState.complete) {
      throw ContractError('source.player.snapshot_incomplete', r'$',
          'Player character import requires a complete source snapshot.');
    }
    if (selectedHeaderId <= 0 || selectedHeaderId > 65535) {
      throw ContractError('source.player.header_invalid', r'$',
          'An explicit bounded player metadata header is required.');
    }
    if (selectedOutfit < 0 || selectedOutfit > 65535) {
      throw ContractError('source.player.outfit_invalid', r'$',
          'An explicit outfit from zero through 65535 is required.');
    }
    final metadataFile = _findFile(
        snapshot, 'PBS/metadata.txt', 'source.player.metadata_missing');
    if (metadataFile.byteLength > 65536) {
      throw ContractError('source.player.metadata_limit',
          metadataFile.relativePath, 'Player metadata exceeds its byte quota.');
    }
    final metadataBytes = await _readAttested(metadataFile, files, cancel);
    final charsets = _playerCharsets(metadataBytes, selectedHeaderId);
    final resolved = {
      for (final declaration in const [
        'WalkCharset',
        'RunCharset',
        'CycleCharset'
      ])
        if (charsets[declaration] case final baseCharset?)
          declaration: _outfitImage(snapshot, baseCharset, selectedOutfit),
    };
    final identity = canonicalHashOf({
      'kind': 'sourcePlayerCharacterIdentity',
      'version': 1,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'metadataPath': metadataFile.relativePath,
      'selectedHeaderId': selectedHeaderId,
      if (selectedOutfit != 0) ...{
        'selectedOutfit': selectedOutfit,
        'resolvedCharsetImages': [
          for (final entry in resolved.entries)
            {
              'declaration': entry.key,
              'charsetName': entry.value.charsetName,
              'sourcePath': entry.value.imageFile.relativePath,
              'sourceSha256': entry.value.imageFile.sha256!.value,
            },
        ],
      },
    }).value;
    final shortIdentity = identity.substring(0, 16);
    final tilesetId = 'source_player_${identity.substring(0, 32)}';
    final sheets = <SourcePlayerCharacterSheet>[];
    for (final declaration in const [
      'WalkCharset',
      'RunCharset',
      'CycleCharset',
    ]) {
      final selection = resolved[declaration];
      if (selection == null) continue;
      final charsetName = selection.charsetName;
      final imageFile = selection.imageFile;
      final imagePath = imageFile.relativePath;
      if (imageFile.byteLength > 4194304) {
        throw ContractError('source.player.image_limit', imagePath,
            'Player sprite sheet exceeds its byte quota.');
      }
      final imageBytes = await _readAttested(imageFile, files, cancel);
      final (width, height) = _sheetGeometry(imageBytes, imagePath);
      final outputBytes =
          _nativeSheetBytes(imageBytes, width, height, imagePath, cancel);
      sheets.add(SourcePlayerCharacterSheet(
        declaration: declaration,
        charsetName: charsetName,
        declaredCharsetName: charsets[declaration]!,
        selectedOutfit: selectedOutfit,
        imageFile: imageFile,
        imageBytes: imageBytes,
        outputBytes: outputBytes,
        sheetWidth: width,
        sheetHeight: height,
        tilesetId: switch (declaration) {
          'RunCharset' => '${tilesetId}_run',
          'CycleCharset' => '${tilesetId}_cycle',
          _ => tilesetId,
        },
      ));
    }
    cancel.check();
    final walk = sheets.first;
    const rows = {
      EntityFacing.south: 0,
      EntityFacing.west: 1,
      EntityFacing.east: 2,
      EntityFacing.north: 3,
    };
    final character = ProjectCharacterEntry(
      id: 'essentials-player-$shortIdentity',
      name: 'Essentials Player $shortIdentity',
      tilesetId: tilesetId,
      frameWidth: 2,
      frameHeight: 2,
      animations: [
        for (final sheet in sheets)
          for (final direction in rows.entries)
            for (final state in sheet.states)
              CharacterAnimation(
                state: state,
                direction: direction.key,
                sourceAssetId: sheet.assetId,
                frames: [
                  for (final column in state == CharacterAnimationState.idle ||
                          state == CharacterAnimationState.bicycleIdle
                      ? const [0]
                      : const [1, 2, 3, 0])
                    CharacterAnimationFrame(
                      source: TilesetSourceRect(
                        x: column * 64,
                        y: direction.value * 64,
                        width: 64,
                        height: 64,
                      ),
                      durationMs: sheet.frameDurationMs,
                    ),
                ],
              ),
      ],
    );
    return SourcePlayerCharacterImport(
      sourceSnapshotHash: snapshot.canonicalHash,
      metadataFile: metadataFile,
      imageFile: walk.imageFile,
      imageBytes: walk.imageBytes,
      outputBytes: walk.outputBytes,
      selectedHeaderId: selectedHeaderId,
      selectedOutfit: selectedOutfit,
      charsetName: walk.charsetName,
      sheetWidth: walk.sheetWidth,
      sheetHeight: walk.sheetHeight,
      frameWidthPx: walk.frameWidthPx,
      frameHeightPx: walk.frameHeightPx,
      assetId: walk.assetId,
      tilesetId: tilesetId,
      character: character,
      sheets: sheets,
    );
  }
}

List<int> _nativeSheetBytes(Uint8List bytes, int width, int height, String path,
    ScanCancellation cancellation) {
  final frameWidth = width ~/ 4;
  final frameHeight = height ~/ 4;
  if (frameWidth > 64 || frameHeight > 64) {
    throw ContractError('source.player.native_frame_geometry', path,
        'Source player frames must fit a native 64 pixel frame without resampling.');
  }
  final source = image.decodePng(bytes)!;
  final raster = image.Image(
      width: 256,
      height: 256,
      numChannels: 4,
      format: source.format == image.Format.uint16
          ? image.Format.uint16
          : image.Format.uint8);
  final offsetX = (64 - frameWidth) ~/ 2;
  final offsetY = 64 - frameHeight;
  for (var row = 0; row < 4; row++) {
    cancellation.check();
    for (var column = 0; column < 4; column++) {
      for (var y = 0; y < frameHeight; y++) {
        for (var x = 0; x < frameWidth; x++) {
          final pixel =
              source.getPixel(column * frameWidth + x, row * frameHeight + y);
          raster.setPixelRgba(column * 64 + offsetX + x, row * 64 + offsetY + y,
              pixel.r, pixel.g, pixel.b, pixel.a);
        }
      }
    }
  }
  return image.encodePng(raster, level: 6);
}

({String charsetName, SourceFileEntry imageFile}) _outfitImage(
    SourceSnapshot snapshot, String baseCharset, int outfit) {
  final basePath = 'Graphics/Characters/$baseCharset.png';
  if (outfit == 0) {
    return (
      charsetName: baseCharset,
      imageFile: _findFile(snapshot, basePath, 'source.player.image_missing')
    );
  }
  final charsetName = '${baseCharset}_$outfit';
  final stem = sourcePathCollisionKey('Graphics/Characters/$charsetName');
  final candidates = {
    stem,
    for (final extension in ['png', 'gif', 'jpg', 'jpeg', 'bmp'])
      '$stem.$extension',
  };
  for (final excluded in snapshot.excludedPaths) {
    final key = sourcePathCollisionKey(excluded);
    if (candidates.any(
        (candidate) => candidate == key || candidate.startsWith('$key/'))) {
      throw ContractError('source.player.outfit_absence_unattested', excluded,
          'Excluded bitmap paths cannot establish unique outfit selection or absence.');
    }
  }
  final matches = snapshot.entries
      .where((entry) =>
          candidates.contains(sourcePathCollisionKey(entry.relativePath)))
      .toList();
  if (matches.length > 1) {
    throw ContractError('source.player.outfit_ambiguous', basePath,
        'The outfit bitmap must resolve to one unique attested file.');
  }
  if (matches.isEmpty) {
    return (
      charsetName: baseCharset,
      imageFile: _findFile(snapshot, basePath, 'source.player.image_missing')
    );
  }
  final entry = matches.single;
  if (entry.kind != SourceNodeKind.file || entry.sha256 == null) {
    throw ContractError('source.player.outfit_unattested', entry.relativePath,
        'The selected outfit bitmap must be one attested regular file.');
  }
  if (sourcePathCollisionKey(entry.relativePath) != '$stem.png') {
    throw ContractError(
        'source.player.outfit_bitmap_unsupported',
        entry.relativePath,
        'The attested outfit bitmap must use the supported static PNG format.');
  }
  return (charsetName: charsetName, imageFile: entry);
}

SourceFileEntry _findFile(
    SourceSnapshot snapshot, String path, String missingCode) {
  for (final entry in snapshot.entries) {
    if (entry.relativePath != path) continue;
    if (entry.kind != SourceNodeKind.file || entry.sha256 == null) {
      break;
    }
    return entry;
  }
  throw ContractError(missingCode, path,
      'The required player source file is not attested by the snapshot.');
}

Future<Uint8List> _readAttested(SourceFileEntry entry, SourceFilePort files,
    ScanCancellation cancellation) async {
  cancellation.check();
  final bytes = await files.read(entry.fileId);
  cancellation.check();
  if (bytes.length != entry.byteLength ||
      bytes.any((value) => value < 0 || value > 255) ||
      crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
    throw ContractError('source.player.source_changed', entry.relativePath,
        'Player source bytes differ from their attested snapshot.');
  }
  return Uint8List.fromList(bytes);
}

Map<String, String> _playerCharsets(Uint8List bytes, int selectedHeaderId) {
  late String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw ContractError('source.player.metadata_invalid', 'PBS/metadata.txt',
        'Player metadata must be bounded UTF-8 text.');
  }
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  var currentHeader = -1;
  var foundHeader = false;
  final charsets = <String, String>{};
  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.split('#').first.trim();
    if (line.isEmpty) continue;
    final header = RegExp(r'^\[([0-9]{1,5})\]$').firstMatch(line);
    if (header != null) {
      currentHeader = int.parse(header.group(1)!);
      if (currentHeader == selectedHeaderId) {
        if (foundHeader) {
          throw ContractError('source.player.metadata_ambiguous',
              'PBS/metadata.txt', 'The selected player header is duplicated.');
        }
        foundHeader = true;
      }
      continue;
    }
    if (line.startsWith('[')) {
      throw ContractError('source.player.metadata_invalid', 'PBS/metadata.txt',
          'Player metadata contains an unsupported section header.');
    }
    if (currentHeader != selectedHeaderId) continue;
    final declaration =
        RegExp(r'^(WalkCharset|RunCharset|CycleCharset)\s*=\s*(.*)$')
            .firstMatch(line);
    if (declaration == null) {
      if (RegExp(r'^(WalkCharset|RunCharset|CycleCharset)\b').hasMatch(line)) {
        throw ContractError(
            'source.player.metadata_invalid',
            'PBS/metadata.txt',
            'A player charset declaration must contain an assignment.');
      }
      continue;
    }
    final name = declaration.group(1)!;
    if (charsets.containsKey(name)) {
      throw ContractError('source.player.metadata_ambiguous',
          'PBS/metadata.txt', 'The selected $name is duplicated.');
    }
    final value = declaration.group(2)!.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_ -]{0,127}$').hasMatch(value)) {
      throw ContractError('source.player.charset_invalid', 'PBS/metadata.txt',
          '$name must name one static character PNG without a path.');
    }
    charsets[name] = value;
  }
  if (!foundHeader || !charsets.containsKey('WalkCharset')) {
    throw ContractError('source.player.header_missing', 'PBS/metadata.txt',
        'The selected player header has no static WalkCharset declaration.');
  }
  return charsets;
}

(int, int) _sheetGeometry(Uint8List bytes, String path) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 ||
      !Iterable<int>.generate(8)
          .every((index) => bytes[index] == signature[index]) ||
      ByteData.sublistView(bytes).getUint32(8) != 13 ||
      ascii.decode(bytes.sublist(12, 16), allowInvalid: true) != 'IHDR') {
    throw ContractError('source.player.image_invalid', path,
        'The source player sheet must be a valid PNG image.');
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width <= 0 ||
      height <= 0 ||
      width > 1024 ||
      height > 1024 ||
      width % 4 != 0 ||
      height % 4 != 0) {
    throw ContractError('source.player.sheet_geometry', path,
        'The player PNG must contain exactly four bounded frames in four cardinal rows.');
  }
  var offset = 8;
  var chunks = 0;
  var ended = false;
  while (offset < bytes.length) {
    if (++chunks > 4096 || offset > bytes.length - 12) {
      throw ContractError('source.player.image_invalid', path,
          'The source player PNG has invalid chunk boundaries.');
    }
    final length = data.getUint32(offset);
    if (length > bytes.length - offset - 12) {
      throw ContractError('source.player.image_invalid', path,
          'The source player PNG has a truncated chunk.');
    }
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (const {'acTL', 'fcTL', 'fdAT'}.contains(type)) {
      throw ContractError('source.player.image_animation', path,
          'The source player sheet must be one static PNG image.');
    }
    if (offset != 8 && type == 'IHDR') {
      throw ContractError('source.player.image_invalid', path,
          'The source player PNG has a repeated image header.');
    }
    offset += length + 12;
    if (type == 'IEND') {
      if (length != 0 || offset != bytes.length) {
        throw ContractError('source.player.image_invalid', path,
            'The source player PNG must end at its terminator.');
      }
      ended = true;
      break;
    }
  }
  if (!ended) {
    throw ContractError('source.player.image_invalid', path,
        'The source player PNG has no image terminator.');
  }
  try {
    final decoded = image.decodePng(bytes);
    if (decoded == null || decoded.width != width || decoded.height != height) {
      throw const FormatException('Invalid player PNG data');
    }
  } catch (_) {
    throw ContractError('source.player.image_invalid', path,
        'The source player PNG cannot be decoded.');
  }
  return (width, height);
}
