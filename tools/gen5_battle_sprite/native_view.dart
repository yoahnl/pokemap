import 'dart:typed_data';

import 'controller.dart';
import 'indexed_atlas.dart';
import 'mcss_bin.dart';
import 'nanr.dart';
import 'ncer.dart';
import 'nitro_graphics.dart';
import 'nmcr.dart';
import 'source_view.dart';

typedef Gen5NitroSourceView = ({
  Gen5IndexedAtlas indexedAtlas,
  List<({int r, int g, int b})> palette,
  Gen5McssBin info,
  List<Gen5NcerCell> cells,
  List<Gen5NitroSequence> animations,
  List<Gen5NmcrMap> maps,
  List<Gen5NitroSequence> timelines,
});

void _validateNativeEnvelope(
  Uint8List bytes,
  String fileMagic,
  String requiredSection,
) {
  if (bytes.length < 16 ||
      !List.generate(
        4,
        (index) => bytes[index] == fileMagic.codeUnitAt(index),
      ).every((matches) => matches)) {
    throw const FormatException('Invalid native Nitro file');
  }
  final data = ByteData.sublistView(bytes);
  var offset = data.getUint16(12, Endian.little);
  final count = data.getUint16(14, Endian.little);
  if (data.getUint16(4, Endian.little) != 0xfeff ||
      data.getUint16(6, Endian.little) != 0x0100 ||
      data.getUint32(8, Endian.little) != bytes.length ||
      offset < 16 ||
      offset > bytes.length ||
      count == 0) {
    throw const FormatException('Invalid native Nitro header');
  }
  var found = false;
  for (var index = 0; index < count; index++) {
    if (offset > bytes.length - 8) {
      throw const FormatException('Truncated native Nitro section');
    }
    final length = data.getUint32(offset + 4, Endian.little);
    if (length < 8 || length > bytes.length - offset) {
      throw const FormatException('Invalid native Nitro section length');
    }
    if (List.generate(
      4,
      (i) => bytes[offset + i] == requiredSection.codeUnitAt(i),
    ).every((matches) => matches)) {
      if (found) throw const FormatException('Duplicate native Nitro section');
      found = true;
    }
    offset += length;
  }
  if (!found || offset != bytes.length) {
    throw const FormatException('Invalid native Nitro section envelope');
  }
}

Iterable<Gen5NitroFrame> _renderableFrames(Gen5NitroSequence sequence) sync* {
  if (sequence.playbackType == 3 && sequence.loopStart > 0) {
    final terminal = sequence.frames[sequence.loopStart - 1];
    if (terminal.duration > 0) yield terminal;
  }
  for (final frame in sequence.frames.skip(sequence.loopStart)) {
    if (frame.duration > 0) yield frame;
  }
}

void _validateRenderableSequence(Gen5NitroSequence sequence) {
  Gen5SequenceController(sequence);
  for (final frame in _renderableFrames(sequence)) {
    if (frame.scaleX == 0 || frame.scaleY == 0) {
      throw const FormatException('Unvalidated zero scale');
    }
  }
}

Gen5NitroSourceView decodeGen5NitroSourceView({
  required Uint8List ncgr,
  required Uint8List nclr,
  required Uint8List ncer,
  required Uint8List nanr,
  required Uint8List nmcr,
  required Uint8List nmar,
  required Uint8List coordinates,
}) {
  for (final bytes in [ncgr, nclr, ncer, nanr, nmcr, nmar, coordinates]) {
    if (bytes.isEmpty || bytes.length > 1048576) {
      throw const FormatException('Invalid Nitro source asset size');
    }
  }
  _validateNativeEnvelope(ncer, 'RECN', 'KBEC');
  _validateNativeEnvelope(nanr, 'RNAN', 'KNBA');
  _validateNativeEnvelope(nmcr, 'RCMN', 'KBCM');
  _validateNativeEnvelope(nmar, 'RAMN', 'KNBA');
  final indexedAtlas = decodeGen5NcgrAtlas(ncgr);
  final palette = decodeGen5NclrPalette(nclr);
  final info = decodeGen5McssBin(coordinates);
  final cells = decodeGen5Ncer(ncer);
  final animations = decodeGen5Nanr(nanr);
  final maps = decodeGen5Nmcr(nmcr);
  final timelines = decodeGen5Nmar(nmar);
  validateGen5ViewReferences(
    info: info,
    cells: cells,
    animations: animations,
    maps: maps,
    timelines: timelines,
  );
  final reachableMaps = <int>{};
  for (final timeline in timelines) {
    _validateRenderableSequence(timeline);
    for (final frame in _renderableFrames(timeline)) {
      reachableMaps.add(frame.targetIndex);
    }
  }
  final reachableSequences = <int>{};
  final mapSlots = <Map<int, (int, int)>>[];
  for (final index in reachableMaps) {
    final boundSlots = <int, (int, int)>{};
    for (final record in maps[index].records) {
      final slot = record.sharedAnimationIndex;
      final current = boundSlots[slot];
      boundSlots[slot] = (
        current?.$1 ?? record.animationIndex,
        (current?.$2 ?? 0) + 1,
      );
    }
    mapSlots.add(boundSlots);
    reachableSequences.addAll(boundSlots.values.map((entry) => entry.$1));
  }
  final maxObjects = <int, int>{};
  for (final index in reachableSequences) {
    final sequence = animations[index];
    _validateRenderableSequence(sequence);
    var largest = 0;
    for (final frame in _renderableFrames(sequence)) {
      final count = cells[frame.targetIndex].objects.length;
      if (count > largest) largest = count;
    }
    maxObjects[index] = largest;
  }
  for (final slots in mapSlots) {
    var maxParts = 0;
    for (final (sequence, count) in slots.values) {
      maxParts += maxObjects[sequence]! * count;
      if (maxParts > 65536) {
        throw const FormatException('MCSS parts may exceed rendering limit');
      }
    }
  }
  return (
    indexedAtlas: indexedAtlas,
    palette: palette,
    info: info,
    cells: cells,
    animations: animations,
    maps: maps,
    timelines: timelines,
  );
}
