import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

final class SourcePlayerCharacterImport {
  SourcePlayerCharacterImport({
    required this.sourceSnapshotHash,
    required this.metadataFile,
    required this.imageFile,
    required List<int> imageBytes,
    required List<int> outputBytes,
    required this.selectedHeaderId,
    required this.charsetName,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frameWidthPx,
    required this.frameHeightPx,
    required this.assetId,
    required this.tilesetId,
    required this.character,
  })  : imageBytes = List.unmodifiable(imageBytes),
        outputBytes = List.unmodifiable(outputBytes);

  final Sha256Hash sourceSnapshotHash;
  final SourceFileEntry metadataFile;
  final SourceFileEntry imageFile;
  final List<int> imageBytes;
  final List<int> outputBytes;
  final int selectedHeaderId;
  final String charsetName;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidthPx;
  final int frameHeightPx;
  final String assetId;
  final String tilesetId;
  final ProjectCharacterEntry character;
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
        'selectionPolicy': 'converterPreviewHeader',
        'sourceIdentitySelectionExecuted': false,
        'sourceScriptsExecuted': 0,
        'collisionFootprintChanged': false,
        'walkFrameOrder': [1, 2, 3, 0],
        'idleFrame': 0,
        'frameTimingPolicy': 'converterPreview150ms',
        'sourceMovementTimingQualified': false,
        'unsupportedSourceProfileSemantics': [
          'sourcePlayerIdentitySelection',
          'sourceStartingMap',
          'sourceStartingInventory',
          'sourceRunCycleSurfFishAnimations',
        ],
      };
}

final class SourcePlayerCharacterImporter {
  const SourcePlayerCharacterImporter();

  Future<SourcePlayerCharacterImport> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    int selectedHeaderId = 1,
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
    final metadataFile = _findFile(
        snapshot, 'PBS/metadata.txt', 'source.player.metadata_missing');
    if (metadataFile.byteLength > 65536) {
      throw ContractError('source.player.metadata_limit',
          metadataFile.relativePath, 'Player metadata exceeds its byte quota.');
    }
    final metadataBytes = await _readAttested(metadataFile, files, cancel);
    final charsetName = _walkCharset(metadataBytes, selectedHeaderId);
    final imagePath = 'Graphics/Characters/$charsetName.png';
    final imageFile =
        _findFile(snapshot, imagePath, 'source.player.image_missing');
    if (imageFile.byteLength > 4194304) {
      throw ContractError('source.player.image_limit', imagePath,
          'Player sprite sheet exceeds its byte quota.');
    }
    final imageBytes = await _readAttested(imageFile, files, cancel);
    final (width, height) = _sheetGeometry(imageBytes, imagePath);
    final outputBytes = _nativeSheetBytes(imageBytes, width, height, imagePath);
    cancel.check();
    final identity = canonicalHashOf({
      'kind': 'sourcePlayerCharacterIdentity',
      'version': 1,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'metadataPath': metadataFile.relativePath,
      'selectedHeaderId': selectedHeaderId,
    }).value;
    final shortIdentity = identity.substring(0, 16);
    final tilesetId = 'source_player_${identity.substring(0, 32)}';
    final assetId = 'image_$tilesetId';
    final frameWidth = width ~/ 4;
    final frameHeight = height ~/ 4;
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
        for (final direction in rows.entries)
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ])
            CharacterAnimation(
              state: state,
              direction: direction.key,
              sourceAssetId: assetId,
              frames: [
                for (final column in state == CharacterAnimationState.idle
                    ? const [0]
                    : const [1, 2, 3, 0])
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(
                      x: column * 64,
                      y: direction.value * 64,
                      width: 64,
                      height: 64,
                    ),
                    durationMs: 150,
                  ),
              ],
            ),
      ],
    );
    return SourcePlayerCharacterImport(
      sourceSnapshotHash: snapshot.canonicalHash,
      metadataFile: metadataFile,
      imageFile: imageFile,
      imageBytes: imageBytes,
      outputBytes: outputBytes,
      selectedHeaderId: selectedHeaderId,
      charsetName: charsetName,
      sheetWidth: width,
      sheetHeight: height,
      frameWidthPx: frameWidth,
      frameHeightPx: frameHeight,
      assetId: assetId,
      tilesetId: tilesetId,
      character: character,
    );
  }
}

List<int> _nativeSheetBytes(
    Uint8List bytes, int width, int height, String path) {
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

String _walkCharset(Uint8List bytes, int selectedHeaderId) {
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
  String? charset;
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
    final declaration = RegExp(r'^WalkCharset\s*=\s*(.*)$').firstMatch(line);
    if (declaration == null) continue;
    if (charset != null) {
      throw ContractError('source.player.metadata_ambiguous',
          'PBS/metadata.txt', 'The selected WalkCharset is duplicated.');
    }
    final value = declaration.group(1)!.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_ -]{0,127}$').hasMatch(value)) {
      throw ContractError('source.player.charset_invalid', 'PBS/metadata.txt',
          'WalkCharset must name one static character PNG without a path.');
    }
    charset = value;
  }
  if (!foundHeader || charset == null) {
    throw ContractError('source.player.header_missing', 'PBS/metadata.txt',
        'The selected player header has no static WalkCharset declaration.');
  }
  return charset;
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
