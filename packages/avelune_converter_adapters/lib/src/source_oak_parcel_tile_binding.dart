import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceOakParcelTileBinding {
  SourceOakParcelTileBinding._(
      {required this.program,
      required this.event,
      required this.character,
      required this.artifact,
      required this.mutations,
      required this.sourceImage,
      required this.sourceBytes,
      required this.sourceTileId,
      required this.cropX,
      required this.cropY,
      required this.eventHash});
  final SourceOakParcelProgram program;
  final SourceEventDefinition event;
  final ProjectCharacterEntry character;
  final NativeArtifact artifact;
  final List<NativeMutation> mutations;
  final SourceFileEntry sourceImage;
  final List<int> sourceBytes;
  final int sourceTileId, cropX, cropY;
  final Sha256Hash eventHash;

  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis) {
    if (source.snapshot.canonicalHash != program.sourceSnapshotHash ||
        source.canonicalHash != program.normalizationHash ||
        analysis.profile.canonicalHash != program.profileHash) {
      return false;
    }
    final current = analysis.events
        .where((value) => value.identity == event.identity)
        .toList();
    return current.length == 1 &&
        _companionShape(current.single) &&
        canonicalHashOf(_companionEvidence(current.single)) == eventHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceOakParcelTilePresentation',
        'sourceIdentity': event.identity.value,
        'sourceSnapshotHash': program.sourceSnapshotHash.value,
        'normalizationHash': program.normalizationHash.value,
        'profileHash': program.profileHash.value,
        'oakProgramHash': program.programHash.value,
        'eventHash': eventHash.value,
        'sourceTileId': sourceTileId,
        'sourceImage': sourceImage.toJson(),
        'sourceCrop': {'x': cropX, 'y': cropY, 'width': 32, 'height': 32},
        'sourcePixelsResampled': false,
        'sourceRenderedPixelsPreserved': true,
        'nativeOutputSha256': artifact.rawSha256.value,
        'nativeCharacterId': character.id,
        'nativeFrame': {
          'width': 64,
          'height': 64,
          'offsetX': 16,
          'offsetY': 32
        },
        'nativeAtlasPolicy': 'fourIdenticalCardinalIdleFrames',
        'requiredBlankSelfSwitch': 'A',
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourceOakParcelTileBindingResolver {
  const SourceOakParcelTileBindingResolver();
  Future<Map<ConverterId, SourceOakParcelTileBinding>> read({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceOakParcelProgram program,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) async {
    limits.validate();
    final analyzer =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    final maps = source.maps
        .where((map) => map.map.sourceMapId == program.sourceMapId)
        .toList();
    if (!analysis.profile.isQualified ||
        maps.length != 1 ||
        source.snapshot.state != SourceScanState.complete ||
        source.snapshot.canonicalHash != program.sourceSnapshotHash ||
        source.canonicalHash != program.normalizationHash ||
        analysis.profile.canonicalHash != program.profileHash ||
        !program.isBoundTo(
            source: source,
            profile: analysis.profile,
            event: maps.single.map.events.singleWhere(
                (e) => e.sourceEventId == program.sourceEventId))) {
      throw const NativeWriteException('events.oak_tile.source_binding',
          'Source tile actors require their exact complete parcel program.');
    }
    final original = analyzer.analyze();
    final props = <SourceEventDefinition>[];
    for (final id in const [12, 15]) {
      final candidates = analysis.events
          .where((e) =>
              e.sourceMapId == program.sourceMapId && e.sourceEventId == id)
          .toList();
      final fresh = original.eventAt(program.sourceMapId, id);
      if (candidates.length != 1 ||
          fresh == null ||
          !_companionShape(candidates.single) ||
          canonicalJsonOf(_companionEvidence(candidates.single)) !=
              canonicalJsonOf(_companionEvidence(fresh)) ||
          candidates.single.pages[1].condition.children.single.factId !=
              analyzer.selfFactId(program.sourceMapId, id, 'A')) {
        throw const NativeWriteException('events.oak_tile.companion',
            'Both source tile actors must preserve their complete original pages.');
      }
      props.add(candidates.single);
    }
    final tilesets = source.tilesets
        .where((set) => set.sourceTilesetId == maps.single.map.sourceTilesetId)
        .toList();
    final atlases = tilesets.length == 1
        ? tilesets.single.images
            .where((image) => image.role == 'tileset')
            .toList()
        : const <NormalizedMediaReference>[];
    final entry = atlases.length == 1 && atlases.single.state == 'resolved'
        ? atlases.single.sourceFile
        : null;
    if (entry == null ||
        entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        entry.format != 'raster' ||
        !entry.relativePath.toLowerCase().endsWith('.png') ||
        source.snapshot.entries
                .where((candidate) =>
                    sourcePathCollisionKey(candidate.relativePath) ==
                    sourcePathCollisionKey(entry.relativePath))
                .length !=
            1 ||
        !source.snapshot.entries.any((candidate) =>
            canonicalJsonOf(candidate.toJson()) ==
            canonicalJsonOf(entry.toJson()))) {
      throw const NativeWriteException('events.oak_tile.atlas',
          'The source event tile requires its unique admitted PNG atlas.');
    }
    final uniqueTileCount =
        props.map((event) => event.pages.first.graphic!.tileId).toSet().length;
    if (uniqueTileCount + 1 > limits.maxArtifacts ||
        uniqueTileCount * 7 > limits.maxMutations) {
      throw const NativeWriteException('events.oak_tile.quota',
          'Tile actor dependencies exceed their cumulative count quota.');
    }
    if (entry.byteLength > limits.maxArtifactBytes ||
        entry.byteLength > limits.maxTotalArtifactBytes ||
        limits.maxMutations < 7 ||
        limits.maxArtifacts < 1 ||
        limits.maxImagePixels < 16384) {
      throw const NativeWriteException('events.oak_tile.quota',
          'Tile actor import exceeds its bounded budget.');
    }
    final bytes = await files.read(entry.fileId);
    if (bytes.length != entry.byteLength ||
        bytes.any((b) => b < 0 || b > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw const NativeWriteException('events.oak_tile.source_changed',
          'The source atlas differs from its attested bytes.');
    }
    final dimensions =
        const NativePngValidator().headerDimensions(bytes, limits: limits);
    const NativePngValidator().validate(bytes, limits: limits);
    if (dimensions.$1 != 256 || dimensions.$2 % 32 != 0) {
      throw const NativeWriteException('events.oak_tile.geometry',
          'A source tile atlas must have eight complete 32 pixel columns.');
    }
    if (dimensions.$1 * dimensions.$2 + uniqueTileCount * 16384 >
        limits.maxTotalImagePixels) {
      throw const NativeWriteException('events.oak_tile.quota',
          'Tile actors exceed their cumulative pixel quota.');
    }
    final decoded = image.decodePng(Uint8List.fromList(bytes));
    if (decoded == null ||
        decoded.width != dimensions.$1 ||
        decoded.height != dimensions.$2) {
      throw const NativeWriteException('events.oak_tile.decode',
          'Source pixels must decode at their original dimensions.');
    }
    final output = <ConverterId, SourceOakParcelTileBinding>{};
    final outputHashes = <String>{};
    var cumulativeBytes = bytes.length;
    for (final event in props) {
      final tile = event.pages.first.graphic!.tileId;
      final x = ((tile - 384) % 8) * 32, y = ((tile - 384) ~/ 8) * 32;
      if (y + 32 > decoded.height ||
          tile >= tilesets.single.passages.xSize ||
          tile >= tilesets.single.priorities.xSize) {
        throw const NativeWriteException('events.oak_tile.bounds',
            'The source tile must exist in its image and passage tables.');
      }
      final raster = image.Image(
          width: 64,
          height: 256,
          numChannels: 4,
          format: decoded.format == image.Format.uint16
              ? image.Format.uint16
              : image.Format.uint8);
      for (var row = 0; row < 4; row++) {
        for (var dy = 0; dy < 32; dy++) {
          for (var dx = 0; dx < 32; dx++) {
            final pixel = decoded.getPixel(x + dx, y + dy);
            raster.setPixelRgba(
                16 + dx,
                row * 64 + 32 + dy,
                pixel.r,
                pixel.g,
                pixel.b,
                decoded.palette?.getAlpha(pixel.index.toInt()) ?? pixel.a);
          }
        }
      }
      final encoded = image.encodePng(raster, level: 6);
      if (bytes.length + encoded.length > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('events.oak_tile.quota',
            'Tile actor output exceeds its cumulative byte quota.');
      }
      final artifact = NativeArtifact(bytes: encoded, limits: limits);
      if (outputHashes.add(artifact.rawSha256.value)) {
        cumulativeBytes += encoded.length;
      }
      if (cumulativeBytes > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('events.oak_tile.quota',
            'Tile actors exceed their cumulative byte quota.');
      }

      final key = canonicalHashOf({
        'kind': 'sourceOakParcelTile',
        'namespace': source.snapshot.logicalProjectNamespace.value,
        'sourceFile': entry.toJson(),
        'sourceTileId': tile,
        'nativeFrameWidth': 64,
        'nativeFrameHeight': 64
      }).value.substring(0, 32);
      final tilesetId = 'source_oak_tile_$key',
          characterId = 'source-oak-tile-$key';
      final assetId = 'image_$tilesetId', stableName = 'Source Oak Tile $key';
      final character = ProjectCharacterEntry(
          id: characterId,
          name: stableName,
          tilesetId: tilesetId,
          frameWidth: 2,
          frameHeight: 2,
          tags: const [
            'sourceImported',
            'sourceStaticEventTile'
          ],
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                  state: CharacterAnimationState.idle,
                  direction: direction,
                  sourceAssetId: assetId,
                  loop: false,
                  frames: [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0,
                            y: direction.index * 64,
                            width: 64,
                            height: 64),
                        durationMs: 150),
                  ]),
          ]);
      NativeMutation mutation(String suffix, String action,
              Map<String, Object?> parameters, List<String> targets) =>
          NativeMutation(
              operationId: ConverterId('source-oak-tile-$key-$suffix'),
              actionId: action,
              sourceEntityIds: [entry.fileId],
              targetEntityIds: targets.map(ConverterId.new).toList(),
              parameters: parameters,
              limits: limits);
      final mutations = [
        mutation('image', 'tileset.import_image', {
          'artifactHandle': artifact.handle,
          'tilesetId': tilesetId,
          'name': stableName,
          'tileWidth': 32,
          'tileHeight': 32
        }, [
          tilesetId,
          assetId
        ]),
        mutation('identity', 'characterStudio.character.create', {
          'name': stableName,
          'tilesetId': tilesetId,
          'frameWidth': 2,
          'frameHeight': 2,
          'tags': character.tags
        }, [
          characterId
        ]),
        mutation('label', 'characterStudio.character.update',
            {'characterId': characterId, 'name': stableName}, [characterId]),
        for (final clip in character.animations)
          mutation('idle-${clip.direction.name}',
              'characterStudio.animationClip.upsert', {
            'characterId': characterId,
            'kind': 'system',
            'state': clip.state.name,
            'direction': clip.direction.name,
            'sourceAssetId': assetId,
            'loop': false,
            'frames': clip.frames.map((frame) => frame.toJson()).toList(),
          }, [
            characterId
          ]),
      ];
      output[event.identity] = SourceOakParcelTileBinding._(
          program: program,
          event: event,
          character: character,
          artifact: artifact,
          mutations: List.unmodifiable(mutations),
          sourceImage: entry,
          sourceBytes: Uint8List.fromList(bytes).asUnmodifiableView(),
          sourceTileId: tile,
          cropX: x,
          cropY: y,
          eventHash: canonicalHashOf(_companionEvidence(event)));
    }
    return Map.unmodifiable(output);
  }
}

bool _companionShape(SourceEventDefinition event) {
  if (event.pages.length != 2 || event.isQuarantined) return false;
  final first = event.pages.first, empty = event.pages.last;
  final graphic = first.graphic, blank = empty.graphic;
  if (graphic == null ||
      blank == null ||
      first.triggerCode != 0 ||
      empty.triggerCode != 0 ||
      first.condition.kind != SourceEventConditionKind.always ||
      empty.condition.kind != SourceEventConditionKind.all ||
      empty.condition.children.length != 1 ||
      empty.condition.children.single.kind !=
          SourceEventConditionKind.selfSwitch ||
      !empty.condition.children.single.expectedValue ||
      empty.body.nodes.any((node) => node is! SourceAnnotationNode) ||
      first.body.nodes.isEmpty ||
      first.body.nodes.any(
          (node) => node is! SourceTextNode && node is! SourceAnnotationNode)) {
    return false;
  }
  if (graphic.tileId < 384 || graphic.tileId > 65535 || blank.tileId != 0) {
    return false;
  }
  return [graphic, blank].every((pose) =>
      pose.characterName.isEmpty &&
      pose.hue == 0 &&
      pose.direction == 2 &&
      pose.pattern == 0 &&
      pose.opacity == 255 &&
      pose.blendType == 0 &&
      pose.moveType == 0 &&
      pose.moveSpeed == 3 &&
      pose.moveFrequency == 3 &&
      pose.walkAnime &&
      !pose.stepAnime &&
      !pose.directionFix &&
      !pose.through &&
      !pose.alwaysOnTop);
}

Map<String, Object?> _companionEvidence(SourceEventDefinition event) => {
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'identity': event.identity.value,
      'sourceFileId': event.sourceFileId.value,
      'x': event.x,
      'y': event.y,
      'name': event.name,
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'condition': page.condition.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tileId': page.graphic!.tileId,
                    'characterName': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blendType': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'moveRouteNodeId': page.graphic!.moveRouteNodeId,
                  },
            'texts': [
              for (final node in page.body.nodes)
                if (node is SourceTextNode)
                  {'text': node.text, 'span': node.span.toJson()}
            ],
          }
      ],
    };
