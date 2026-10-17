import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import '../maps/canonical_border_ground_composer.dart';
import '../maps/canonical_border_snapshot_compiler.dart';

Future<
        (
          Map<String, List<BorderSnapshotContentFrame>>,
          Map<BorderGroundVariantRole, List<BorderSnapshotContentFrame>>
        )>
    prepareResourcePackBorderSources(ProjectManifest manifest,
        BorderBlueprintRecord record, CanonicalBorderPngReader read) async {
  final primitives = <String, List<BorderSnapshotContentFrame>>{};
  for (final primitive in record.latestPublished!.definition.primitives) {
    if (primitive.isSpatial) continue;
    final element = manifest.elements
        .where((e) => e.id == primitive.sourceElementId)
        .firstOrNull;
    if (element == null) _fail('border_source_missing');
    final prepared =
        await prepareResourcePackElementSource(manifest, element, read);
    primitives[primitive.id] = [
      for (var index = 0; index < prepared.files.length; index++)
        BorderSnapshotContentFrame(
            sourceRectPx: prepared.snapshot.frames[index].sourceRectPx,
            durationMs: prepared.snapshot.frames[index].durationMs,
            transparentColorArgb:
                prepared.snapshot.frames[index].transparentColorArgb,
            rgbaBytes: img
                .decodePng(prepared.files[index].bytes)!
                .getBytes(order: img.ChannelOrder.rgba))
    ];
  }
  final ground = record.latestPublished!.definition.ground;
  final grounds = ground == null
      ? <BorderGroundVariantRole, List<BorderSnapshotContentFrame>>{}
      : {
          for (final entry in (await const CanonicalBorderGroundComposer()
                  .composeAllRoles(
                      manifest: manifest,
                      sourceSmartTilePresetId: ground.sourceSmartTilePresetId,
                      readPng: read))
              .entries)
            entry.key: entry.value.map((frame) => frame.contentFrame).toList()
        };
  return (primitives, grounds);
}

Future<CanonicalBorderSnapshotPreparation> prepareResourcePackElementSource(
    ProjectManifest manifest,
    ProjectElementEntry element,
    CanonicalBorderPngReader read) async {
  final frames = <CanonicalBorderSourceFrame>[];
  for (final frame in element.frames) {
    final tileset = manifest.tilesets
        .where((t) =>
            t.id ==
            (frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId))
        .firstOrNull;
    if (tileset == null || tileset.source == null) {
      _fail('border_source_missing');
    }
    final resolved = const ProjectTilesetVisualResolver().resolve(
        source: tileset.source!,
        selection:
            ProjectTilesetVisualSelection.regularAtlas(source: frame.source),
        cellWidth: manifest.settings.tileWidth,
        cellHeight: manifest.settings.tileHeight);
    for (final visual in resolved.frames) {
      final duration =
          frame.durationMs ?? (visual.durationMs > 0 ? visual.durationMs : 100);
      final color = tileset.transparentColor;
      final argb = color == null
          ? null
          : 0xff000000 | color.red << 16 | color.green << 8 | color.blue;
      final single = visual.slices.length == 1 ? visual.slices.single : null;
      if (single != null &&
          single.sourceRect.width == single.destinationRect.width &&
          single.sourceRect.height == single.destinationRect.height) {
        final rect = single.sourceRect;
        frames.add(CanonicalBorderSourceFrame(
            sourceProjectRelativePath: tileset.relativePath,
            encodedImageBytes: await read(tileset, single.assetId),
            sourceRectPx: BorderPixelRect(
                x: rect.x, y: rect.y, width: rect.width, height: rect.height),
            durationMs: duration,
            transparentColorArgb: argb));
        continue;
      }
      final pixels = img.Image(
          width: visual.bounds.width,
          height: visual.bounds.height,
          numChannels: 4);
      for (final slice in visual.slices) {
        final source = img
            .decodePng(Uint8List.fromList(await read(tileset, slice.assetId)));
        if (source == null) _fail('border_source_invalid');
        final rect = slice.sourceRect;
        if (rect.x < 0 ||
            rect.y < 0 ||
            rect.x + rect.width > source.width ||
            rect.y + rect.height > source.height) {
          _fail('border_source_invalid');
        }
        img.compositeImage(
            pixels,
            img.copyCrop(source,
                x: rect.x, y: rect.y, width: rect.width, height: rect.height),
            dstX: slice.destinationRect.x - visual.bounds.x,
            dstY: slice.destinationRect.y - visual.bounds.y,
            dstW: slice.destinationRect.width,
            dstH: slice.destinationRect.height);
      }
      frames.add(CanonicalBorderSourceFrame(
          sourceProjectRelativePath: tileset.relativePath,
          encodedImageBytes: img.encodePng(pixels),
          durationMs: duration,
          transparentColorArgb: argb));
    }
  }
  return const CanonicalBorderSnapshotCompiler()
      .prepare(sourceElementId: element.id, frames: frames);
}

Never _fail(String code) => throw FormatException('resource_pack.$code');
