import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';

final class SourceEventCharacterImport {
  const SourceEventCharacterImport._({
    required this.sourceSnapshotHash,
    required this.imageFile,
    required this.charsetName,
    required this.sourcePattern,
    required this.sourceDirection,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.character,
    required this.artifact,
    required this.imageBytes,
    required this.mutations,
  });

  final Sha256Hash sourceSnapshotHash;
  final SourceFileEntry imageFile;
  final String charsetName;
  final int sourcePattern;
  final int sourceDirection;
  final int sheetWidth;
  final int sheetHeight;
  final ProjectCharacterEntry character;
  final NativeArtifact artifact;
  final List<int> imageBytes;
  final List<NativeMutation> mutations;
  int get frameWidthPx => sheetWidth ~/ 4;
  int get frameHeightPx => sheetHeight ~/ 4;
  String get tilesetId => character.tilesetId;
  String get assetId => 'image_$tilesetId';
  List<int> get outputBytes => artifact.bytes;
  int get nativeFrameWidthPx => 64;
  int get nativeFrameHeightPx => character.frameHeight * 32;
  int get sourceOffsetXPx => 32 - frameWidthPx ~/ 2;
  int get sourceOffsetYPx => nativeFrameHeightPx - frameHeightPx;
  int get depthOffsetPx => frameHeightPx > 32 ? 31 : 0;
  List<NativeArtifact> get artifacts => List.unmodifiable([artifact]);
  EntityFacing get facing => _facing(sourceDirection);
  String get bindingKey => sourceEventCharacterBindingKey(
        characterName: charsetName,
        pattern: sourcePattern,
        direction: sourceDirection,
      );
  SourceEventCharacterBinding get binding => SourceEventCharacterBinding(
        characterId: character.id,
        sourceSnapshotHash: sourceSnapshotHash,
        sourceFileId: imageFile.fileId,
        sourceFileHash: imageFile.sha256!,
        sourcePattern: sourcePattern,
        sourceDirection: sourceDirection,
      );
  Map<String, Object?> get evidence => {
        'kind': 'sourceEventCharacterImport',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'imageFile': imageFile.toJson(),
        'charsetName': charsetName,
        'sourcePattern': sourcePattern,
        'sourceDirection': sourceDirection,
        'sourceOriginal': {
          'rawSha256': imageFile.sha256!.value,
          'byteLength': imageBytes.length,
          'sheetWidth': sheetWidth,
          'sheetHeight': sheetHeight,
          'frameWidthPx': frameWidthPx,
          'frameHeightPx': frameHeightPx,
          'frameLayoutPolicy': 'rmxpIntegerDivision4x4',
          'usedWidthPx': frameWidthPx * 4,
          'usedHeightPx': frameHeightPx * 4,
          'ignoredRightColumns': sheetWidth % 4,
          'ignoredBottomRows': sheetHeight % 4,
          'ignoredPixelCount':
              sheetWidth * sheetHeight - frameWidthPx * 4 * frameHeightPx * 4,
        },
        'nativeOutput': {
          'rawSha256': artifact.rawSha256.value,
          'byteLength': outputBytes.length,
          'sheetWidth': 256,
          'sheetHeight': nativeFrameHeightPx * 4,
          'frameWidthPx': nativeFrameWidthPx,
          'frameHeightPx': nativeFrameHeightPx,
          'sourceOffsetXPx': sourceOffsetXPx,
          'sourceOffsetYPx': sourceOffsetYPx,
          'policy': nativeFrameHeightPx == 64 ? 'transparent64PixelFramesRmxpOriginBottomAligned' : 'transparent64x96PixelFramesRmxpOriginBottomAligned',
          'requiredBy': 'overworldActorMinimumTwoTileFrame',
        },
        'initialFrame': {
          'sourcePattern': sourcePattern,
          'sourceDirection': sourceDirection,
          'facing': facing.name,
          'x': sourcePattern * frameWidthPx,
          'y': _row(sourceDirection) * frameHeightPx,
          'width': frameWidthPx,
          'height': frameHeightPx,
        },
        'sourcePixelsPreserved': sheetWidth % 4 == 0 && sheetHeight % 4 == 0,
        'sourceRenderedPixelsPreserved': true,
        'sourcePixelsResampled': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'sourceMovementTimingQualified': false,
        'sourceAutonomousMovementQualified': false,
        'sourceDepthOffsetPx': depthOffsetPx,
        'sourceDepthOracle': {
          'archive': 'Data/Scripts.rxdata',
          'section': 'Game_Character',
          'sourceProfileQualificationRequired': true,
        },
        'targetDepthProjectionQualified': false,
        'characterId': character.id,
        'characterHash': canonicalHashOf(character.toJson()).value,
        'tilesetId': tilesetId,
        'assetId': assetId,
        'bindingKey': bindingKey,
        'operationIds':
            mutations.map((entry) => entry.operationId.value).toList(),
        'animationPolicy': 'fourCardinalFixedSourcePatternIdleClips',
        'unsupportedSourceSemantics': [
          'sourceStepAnimation',
          'sourceAutonomousMovement',
          'sourceWalkAnimation',
        ],
      };
}

final class SourceEventCharacterImporter {
  const SourceEventCharacterImporter();

  Future<SourceEventCharacterImport> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    required String charsetName,
    required int sourcePattern,
    required int sourceDirection,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    if (snapshot.state != SourceScanState.complete) {
      throw ContractError('source.event_character.snapshot_incomplete', r'$',
          'Event character import requires a complete source snapshot.');
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_ -]{0,127}$').hasMatch(charsetName) ||
        charsetName.trim() != charsetName) {
      throw ContractError('source.event_character.charset_invalid', r'$',
          'The source character must name one static PNG without a path.');
    }
    if (sourcePattern < 0 || sourcePattern > 3) {
      throw ContractError('source.event_character.pattern_invalid', r'$',
          'The source pattern must select one of four original columns.');
    }
    if (!const [2, 4, 6, 8].contains(sourceDirection)) {
      throw ContractError('source.event_character.direction_invalid', r'$',
          'The source direction must be an attested RMXP cardinal direction.');
    }
    if (limits.maxMutations < 7) {
      throw ContractError('source.event_character.mutation_limit', r'$',
          'Event character import requires seven canonical mutations.');
    }
    final path = 'Graphics/Characters/$charsetName.png';
    final matching = snapshot.entries
        .where((entry) =>
            sourcePathCollisionKey(entry.relativePath) ==
            sourcePathCollisionKey(path))
        .toList();
    if (matching.length > 1) {
      throw ContractError('source.event_character.image_ambiguous', path,
          'The source character image cannot have ambiguous file identities.');
    }
    if (matching.isEmpty || matching.single.relativePath != path) {
      throw ContractError('source.event_character.image_missing', path,
          'The exact source character image is absent from the snapshot.');
    }
    final entry = matching.single;
    if (entry.kind != SourceNodeKind.file || entry.sha256 == null) {
      throw ContractError('source.event_character.image_unattested', path,
          'The source character image must be a hashed regular file.');
    }
    if (entry.byteLength > 4194304 ||
        entry.byteLength > limits.maxArtifactBytes ||
        entry.byteLength > limits.maxTotalArtifactBytes ||
        limits.maxImagePixels < 65536) {
      throw ContractError('source.event_character.image_limit', path,
          'The source or native character atlas exceeds its image quota.');
    }
    final rawBytes = await files.read(entry.fileId);
    cancel.check();
    if (rawBytes.length != entry.byteLength ||
        rawBytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(rawBytes).toString() != entry.sha256!.value) {
      throw ContractError('source.event_character.source_changed', path,
          'The source character bytes differ from the attested snapshot.');
    }
    final bytes = Uint8List.fromList(rawBytes).asUnmodifiableView();
    final (width, height) = _geometry(bytes, path, limits);
    final nativeHeight = height ~/ 4 > 64 ? 96 : 64;
    if (limits.maxImagePixels < 256 * nativeHeight * 4) {
      throw ContractError('source.event_character.image_limit', path, 'The native character atlas exceeds its image quota.');
    }
    final outputBytes = _nativePixels(bytes, width, height, path);
    cancel.check();
    if (outputBytes.length > limits.maxArtifactBytes ||
        bytes.length + outputBytes.length > limits.maxTotalArtifactBytes) {
      throw ContractError('source.event_character.image_limit', path,
          'The native character pixels exceed the admitted artifact quota.');
    }
    final artifact = NativeArtifact(bytes: outputBytes, limits: limits);
    final imageIdentity = {
      'kind': 'sourceEventCharacterImage',
      'version': 1,
      'namespace': snapshot.logicalProjectNamespace.value,
      'sourceFileId': entry.fileId.value,
      'sourcePath': path,
      'sourceFileHash': entry.sha256!.value,
    };
    final imageKey = canonicalHashOf(imageIdentity).value.substring(0, 32);
    final characterKey = canonicalHashOf({
      ...imageIdentity,
      'kind': 'sourceEventCharacter',
      'sourcePattern': sourcePattern,
    }).value.substring(0, 32);
    final tilesetId = 'source_event_$imageKey';
    final assetId = 'image_$tilesetId';
    final characterId = 'source-event-$characterKey';
    final stableName = 'Source Event $characterKey';
    final character = ProjectCharacterEntry(
      id: characterId,
      name: '$charsetName · pattern $sourcePattern',
      tilesetId: tilesetId,
      frameWidth: 2,
      frameHeight: nativeHeight ~/ 32,
      tags: const ['sourceImported', 'sourceStaticEventCharacter'],
      animations: [
        for (final direction in const [2, 4, 6, 8])
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: _facing(direction),
            sourceAssetId: assetId,
            loop: false,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(
                  x: sourcePattern * 64,
                  y: _row(direction) * nativeHeight,
                  width: 64,
                  height: nativeHeight,
                ),
                durationMs: 150,
              ),
            ],
          ),
      ],
    );
    NativeMutation mutation(String suffix, String action, List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
          operationId: ConverterId(suffix == 'image'
              ? 'source-event-image-$imageKey'
              : 'source-event-character-$characterKey-$suffix'),
          actionId: action,
          sourceEntityIds: [entry.fileId],
          targetEntityIds: targets.map(ConverterId.new).toList(),
          parameters: parameters,
          limits: limits,
        );
    final mutations = [
      mutation('image', 'tileset.import_image', [
        tilesetId,
        assetId
      ], {
        'artifactHandle': artifact.handle,
        'tilesetId': tilesetId,
        'name': charsetName,
        'tileWidth': 32,
        'tileHeight': 32,
      }),
      mutation('identity', 'characterStudio.character.create', [
        characterId
      ], {
        'name': stableName,
        'tilesetId': tilesetId,
        'frameWidth': character.frameWidth,
        'frameHeight': character.frameHeight,
        'tags': character.tags,
      }),
      mutation('label', 'characterStudio.character.update', [
        characterId
      ], {
        'characterId': characterId,
        'name': character.name,
      }),
      for (final clip in character.animations)
        mutation('idle-${clip.direction.name}',
            'characterStudio.animationClip.upsert', [
          characterId
        ], {
          'characterId': characterId,
          'kind': 'system',
          'state': clip.state.name,
          'direction': clip.direction.name,
          'sourceAssetId': clip.sourceAssetId,
          'loop': clip.loop,
          'frames': clip.frames.map((frame) => frame.toJson()).toList(),
        }),
    ];
    return SourceEventCharacterImport._(
      sourceSnapshotHash: snapshot.canonicalHash,
      imageFile: entry,
      charsetName: charsetName,
      sourcePattern: sourcePattern,
      sourceDirection: sourceDirection,
      sheetWidth: width,
      sheetHeight: height,
      character: character,
      artifact: artifact,
      imageBytes: bytes,
      mutations: List.unmodifiable(mutations),
    );
  }
}

EntityFacing _facing(int direction) => switch (direction) {
      2 => EntityFacing.south,
      4 => EntityFacing.west,
      6 => EntityFacing.east,
      8 => EntityFacing.north,
      _ => throw StateError('An admitted RMXP direction is required.'),
    };

int _row(int direction) => switch (direction) {
      2 => 0,
      4 => 1,
      6 => 2,
      8 => 3,
      _ => throw StateError('An admitted RMXP direction is required.'),
    };

(int, int) _geometry(Uint8List bytes, String path, NativeWriteLimits limits) {
  late final (int, int) dimensions;
  try {
    dimensions =
        const NativePngValidator().headerDimensions(bytes, limits: limits);
  } on NativeWriteException catch (error) {
    throw ContractError(
        error.code == 'native.quota.image'
            ? 'source.event_character.image_limit'
            : 'source.event_character.image_invalid',
        path,
        'The source character must be a bounded static PNG.');
  }
  final (width, height) = dimensions;
  if (width < 4 || height < 4 || width > 256 || height > 384) {
    throw ContractError('source.event_character.sheet_geometry', path,
        'The source requires sixteen integer frames between 1 by 1 and 64 by 96 pixels.');
  }
  try {
    const NativePngValidator().validate(bytes, limits: limits);
  } catch (_) {
    throw ContractError('source.event_character.image_invalid', path,
        'The original PNG must decode exactly without animation or trailing data.');
  }
  return dimensions;
}

List<int> _nativePixels(Uint8List bytes, int width, int height, String path) {
  final source = image.decodePng(bytes);
  if (source == null || source.width != width || source.height != height) {
    throw ContractError('source.event_character.image_invalid', path,
        'The source character pixels cannot be decoded at their attested dimensions.');
  }
  if (width == 256 && height == 256) {
    return bytes;
  }
  final frameWidth = width ~/ 4;
  final frameHeight = height ~/ 4;
  final offsetX = 32 - frameWidth ~/ 2;
  final nativeHeight = frameHeight > 64 ? 96 : 64;
  final offsetY = nativeHeight - frameHeight;
  final raster = image.Image(
    width: 256,
    height: nativeHeight * 4,
    numChannels: 4,
    format: source.format == image.Format.uint16
        ? image.Format.uint16
        : image.Format.uint8,
  );
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 0; y < frameHeight; y++) {
        for (var x = 0; x < frameWidth; x++) {
          final pixel =
              source.getPixel(column * frameWidth + x, row * frameHeight + y);
          raster.setPixelRgba(column * 64 + offsetX + x, row * nativeHeight + offsetY + y,
              pixel.r, pixel.g, pixel.b, pixel.a);
        }
      }
    }
  }
  return image.encodePng(raster, level: 6);
}
