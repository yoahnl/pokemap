import 'dart:convert';
import 'dart:typed_data';

import 'indexed_atlas.dart';
import 'lz11.dart';
import 'mcss_bin.dart';
import 'nanr.dart';
import 'ncer.dart';
import 'nmcr.dart';

final class Gen5DecodedSourceView {
  const Gen5DecodedSourceView({
    required this.atlas,
    required this.indexedAtlas,
    required this.palette,
    required this.info,
    required this.cells,
    required this.animations,
    required this.maps,
    required this.timelines,
  });

  final Uint8List atlas;
  final Gen5IndexedAtlas indexedAtlas;
  final List<({int r, int g, int b})> palette;
  final Gen5McssBin info;
  final List<Gen5NcerCell> cells;
  final List<Gen5NitroSequence> animations, timelines;
  final List<Gen5NmcrMap> maps;
}

void validateGen5AtlasHeader(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 ||
      !List.generate(8, (i) => bytes[i] == signature[i]).every((v) => v)) {
    throw const FormatException('Invalid Gen 5 atlas PNG header');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(8) != 13 ||
      ascii.decode(bytes.sublist(12, 16)) != 'IHDR' ||
      data.getUint32(16) != 256 ||
      data.getUint32(20) != 128) {
    throw const FormatException('Invalid Gen 5 atlas dimensions');
  }
}

List<({int r, int g, int b})> parseGen5SourcePalette(Uint8List bytes) {
  final lines = const LineSplitter().convert(ascii.decode(bytes));
  if (lines.length != 19 ||
      lines[0].trim() != 'JASC-PAL' ||
      lines[1].trim() != '0100' ||
      lines[2].trim() != '16') {
    throw const FormatException('Invalid Gen 5 palette header');
  }
  final result = <({int r, int g, int b})>[];
  for (final line in lines.skip(3)) {
    final parts = line.trim().split(RegExp(r'\s+'));
    final values = parts.map(int.tryParse).toList();
    if (values.length != 3 ||
        values.any((v) => v == null || v < 0 || v > 255)) {
      throw const FormatException('Invalid Gen 5 palette color');
    }
    result.add((r: values[0]!, g: values[1]!, b: values[2]!));
  }
  return List.unmodifiable(result);
}

Gen5DecodedSourceView decodeGen5SourceView(
  Map<String, Uint8List> assets, {
  required String view,
  required bool shiny,
}) {
  if (view != 'front' && view != 'back') {
    throw const FormatException('Invalid Gen 5 view');
  }
  Uint8List asset(String name) =>
      assets[name] ??
      (throw FormatException('Missing Gen 5 source asset: $name'));
  final atlas = asset('$view.png');
  final indexedAtlas = decodeGen5IndexedAtlas(atlas);
  final palette = parseGen5SourcePalette(
    asset(shiny ? 'shiny.pal' : 'normal.pal'),
  );
  final cells = decodeGen5Ncer(asset('${view}_cells.ncer'));
  final animations = decodeGen5Nanr(
    decodeGen5Lz11(asset('${view}_animations.nanr.lz11')),
  );
  final maps = decodeGen5Nmcr(asset('${view}_multi_cells.nmcr'));
  final timelines = decodeGen5Nmar(asset('${view}_multi_animations.nmar'));
  final info = decodeGen5McssBin(asset('${view}_info.bin'));
  validateGen5ViewReferences(
    info: info,
    cells: cells,
    animations: animations,
    maps: maps,
    timelines: timelines,
  );
  return Gen5DecodedSourceView(
    atlas: atlas,
    indexedAtlas: indexedAtlas,
    palette: palette,
    info: info,
    cells: cells,
    animations: animations,
    maps: maps,
    timelines: timelines,
  );
}

void validateGen5ViewReferences({
  required Gen5McssBin info,
  required List<Gen5NcerCell> cells,
  required List<Gen5NitroSequence> animations,
  required List<Gen5NmcrMap> maps,
  required List<Gen5NitroSequence> timelines,
}) {
  if (info.cells.isEmpty ||
      cells.length != info.cells.length ||
      timelines.isEmpty) {
    throw const FormatException('Invalid MCSS view banks');
  }
  final reachableMaps = <int>{};
  for (final timeline in timelines) {
    if (timeline.frames.isEmpty)
      throw const FormatException('Empty MCSS timeline');
    for (final frame in timeline.frames) {
      if (frame.targetIndex < 0 || frame.targetIndex >= maps.length) {
        throw const FormatException('Invalid MCSS timeline reference');
      }
      reachableMaps.add(frame.targetIndex);
    }
  }
  final reachableSequences = <int>{};
  for (final index in reachableMaps) {
    final map = maps[index];
    for (final node in map.records) {
      if (node.sharedAnimationIndex >= map.sharedAnimationCount ||
          node.nodePlaybackMode > 1 ||
          node.animationIndex < 0 ||
          node.animationIndex >= animations.length) {
        throw const FormatException('Invalid MCSS node reference');
      }
      reachableSequences.add(node.animationIndex);
    }
  }
  for (final index in reachableSequences) {
    final sequence = animations[index];
    if (sequence.frames.isEmpty)
      throw const FormatException('Empty MCSS sequence');
    for (final frame in sequence.frames) {
      if (frame.targetIndex < 0 || frame.targetIndex >= info.cells.length) {
        throw const FormatException('Invalid MCSS cell reference');
      }
    }
  }
}
