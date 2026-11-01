import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/indexed_atlas.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/ncer.dart';
import '../../../tools/gen5_battle_sprite/native_view.dart';
import '../../../tools/gen5_battle_sprite/nitro_graphics.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

Uint8List _ncgr() {
  final bytes = Uint8List(0x4040);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RGCN'));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0101, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 2, Endian.little);
  bytes.setRange(16, 20, ascii.encode('RAHC'));
  data.setUint32(20, 0x4020, Endian.little);
  data.setUint16(24, 16, Endian.little);
  data.setUint16(26, 32, Endian.little);
  data.setUint32(28, 3, Endian.little);
  data.setUint32(36, 1, Endian.little);
  data.setUint32(40, 0x4000, Endian.little);
  data.setUint32(44, 0x18, Endian.little);
  for (var i = 0; i < 0x4000; i++) {
    bytes[0x30 + i] = (i * 7) & 0xff;
  }
  bytes.setRange(0x4030, 0x4034, ascii.encode('SOPC'));
  data.setUint32(0x4034, 16, Endian.little);
  return bytes;
}

Uint8List _nclr() {
  final bytes = Uint8List(72);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RLCN'));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0100, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 1, Endian.little);
  bytes.setRange(16, 20, ascii.encode('TTLP'));
  data.setUint32(20, 56, Endian.little);
  data.setUint32(24, 0x000a0004, Endian.little);
  data.setUint32(32, 32, Endian.little);
  data.setUint32(36, 16, Endian.little);
  for (var i = 0; i < 16; i++) {
    data.setUint16(40 + i * 2, i | (i << 5) | (i << 10), Endian.little);
  }
  data.setUint16(44, 31, Endian.little);
  data.setUint16(46, 31 << 5, Endian.little);
  data.setUint16(48, 31 << 10, Endian.little);
  return bytes;
}

Uint8List _ncer() {
  final bytes = Uint8List(62);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RECN'));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0100, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 1, Endian.little);
  bytes.setRange(16, 20, ascii.encode('KBEC'));
  data.setUint32(20, 46, Endian.little);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 24, Endian.little);
  data.setUint16(48, 1, Endian.little);
  return bytes;
}

Uint8List _animation({
  bool timeline = false,
  int target = 0,
  int playback = 2,
  List<int> durations = const [3],
}) {
  final extra = (durations.length - 1) * 8;
  final bytes = Uint8List(96 + extra);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode(timeline ? 'RAMN' : 'RNAN'));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0100, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 1, Endian.little);
  bytes.setRange(16, 20, ascii.encode('KNBA'));
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(24, 1, Endian.little);
  data.setUint16(26, 1, Endian.little);
  data.setUint32(28, 24, Endian.little);
  data.setUint32(32, 40, Endian.little);
  data.setUint32(36, 48 + extra, Endian.little);
  data.setUint16(48, durations.length, Endian.little);
  data.setUint16(52, 1, Endian.little);
  data.setUint32(56, playback, Endian.little);
  for (var i = 0; i < durations.length; i++) {
    data.setUint16(68 + i * 8, durations[i], Endian.little);
  }
  data.setUint16(72 + extra, target, Endian.little);
  data.setInt32(76 + extra, 4096, Endian.little);
  data.setInt32(80 + extra, 4096, Endian.little);
  return bytes;
}

Uint8List _animationWithUnreachableSequence() {
  final source = _animation();
  final bytes = Uint8List(source.length + 16);
  bytes.setRange(0, 48, source);
  bytes.setRange(48, 64, source, 48);
  bytes.setRange(64, 80, source, 48);
  bytes.setRange(80, bytes.length, source, 64);
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(24, 2, Endian.little);
  data.setUint16(26, 2, Endian.little);
  data.setUint32(32, 56, Endian.little);
  data.setUint32(36, 64, Endian.little);
  data.setUint32(72, 5, Endian.little);
  return bytes;
}

Uint8List _animationWithSeparateFrames({
  bool timeline = false,
  int firstDuration = 0,
  int firstTarget = 0,
  int loopStart = 0,
  int playback = 2,
}) {
  final source = _animation(
    timeline: timeline,
    durations: [firstDuration, 3],
    playback: playback,
  );
  final bytes = Uint8List(source.length + 16)
    ..setRange(0, source.length, source);
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(50, loopStart, Endian.little);
  data.setUint32(72, 16, Endian.little);
  data.setUint16(80, firstTarget, Endian.little);
  data.setInt32(84, 0, Endian.little);
  data.setInt32(100, 4096, Endian.little);
  data.setInt32(104, 4096, Endian.little);
  return bytes;
}

Uint8List _animationWithUnreachableZeroScale() {
  final source = _animationWithUnreachableSequence();
  final bytes = Uint8List(source.length + 24);
  bytes.setRange(0, 80, source);
  bytes.setRange(80, 88, source, 80);
  bytes.setRange(88, 96, source, 80);
  bytes.setRange(96, 112, source, 88);
  bytes.setRange(112, 128, source, 88);
  bytes.setRange(128, bytes.length, source, 104);
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint32(36, 72, Endian.little);
  data.setUint32(72, 2, Endian.little);
  data.setUint32(76, 8, Endian.little);
  data.setUint32(88, 16, Endian.little);
  data.setInt32(116, 0, Endian.little);
  return bytes;
}

Uint8List _opposingAnimations() {
  final bytes = Uint8List(116)..setRange(0, 48, _animation());
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(24, 2, Endian.little);
  data.setUint16(26, 4, Endian.little);
  data.setUint32(32, 56, Endian.little);
  data.setUint32(36, 88, Endian.little);
  for (var index = 0; index < 2; index++) {
    final entry = 48 + index * 16;
    data.setUint16(entry, 2, Endian.little);
    data.setUint32(entry + 8, 2, Endian.little);
    data.setUint32(entry + 12, index * 16, Endian.little);
  }
  for (var index = 0; index < 4; index++) {
    final frame = 80 + index * 8;
    data.setUint32(frame, (index == 1 || index == 2) ? 2 : 0, Endian.little);
    data.setUint16(frame + 4, 3, Endian.little);
  }
  data.setUint16(114, 1, Endian.little);
  return bytes;
}

Uint8List _withAdditionalSection(Uint8List source, {bool duplicate = false}) {
  final bytes = Uint8List(source.length + 8)
    ..setRange(0, source.length, source);
  bytes.setRange(
    source.length,
    source.length + 4,
    duplicate ? source.sublist(16, 20) : ascii.encode('ARTX'),
  );
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(14, 2, Endian.little);
  data.setUint32(source.length + 4, 8, Endian.little);
  return bytes;
}

Uint8List _nmcr() {
  final bytes = Uint8List(64);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RCMN'));
  data.setUint16(4, 0xfeff, Endian.little);
  data.setUint16(6, 0x0100, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint16(12, 16, Endian.little);
  data.setUint16(14, 1, Endian.little);
  bytes.setRange(16, 20, ascii.encode('KBCM'));
  data.setUint32(20, 48, Endian.little);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 24, Endian.little);
  data.setUint16(48, 1, Endian.little);
  data.setUint16(50, 1, Endian.little);
  return bytes;
}

Uint8List _nmcrWithSharedSlot() {
  final source = _nmcr();
  final bytes = Uint8List(source.length + 8)
    ..setRange(0, source.length, source)
    ..setRange(source.length, source.length + 8, source, 56);
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(48, 2, Endian.little);
  data.setUint16(64, 1, Endian.little);
  return bytes;
}

Uint8List _nmcrWithTwoMaps() {
  final bytes = Uint8List(80)..setRange(0, 48, _nmcr());
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(24, 2, Endian.little);
  data.setUint16(48, 1, Endian.little);
  data.setUint16(50, 1, Endian.little);
  data.setUint16(56, 1, Endian.little);
  data.setUint16(58, 1, Endian.little);
  data.setUint32(60, 8, Endian.little);
  data.setUint16(72, 1, Endian.little);
  return bytes;
}

Uint8List _ncerWithObjectCounts(List<int> counts) {
  final objectStart = 48 + counts.length * 8;
  final total = counts.fold<int>(0, (sum, count) => sum + count);
  final bytes = Uint8List(objectStart + total * 6)..setRange(0, 48, _ncer());
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(24, counts.length, Endian.little);
  var offset = 0;
  for (var index = 0; index < counts.length; index++) {
    data.setUint16(48 + index * 8, counts[index], Endian.little);
    data.setUint32(52 + index * 8, offset, Endian.little);
    offset += counts[index] * 6;
  }
  return bytes;
}

Uint8List _nmcrWithRecordCount(int count) {
  final bytes = Uint8List(56 + count * 8)..setRange(0, 56, _nmcr());
  final data = ByteData.sublistView(bytes);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(20, bytes.length - 16, Endian.little);
  data.setUint16(48, count, Endian.little);
  return bytes;
}

Uint8List _nmcrWithOpposingSlots(int countPerSlot) {
  final bytes = _nmcrWithRecordCount(countPerSlot * 2);
  final data = ByteData.sublistView(bytes);
  data.setUint16(50, 2, Endian.little);
  for (var index = countPerSlot; index < countPerSlot * 2; index++) {
    final record = 56 + index * 8;
    data.setUint16(record, 1, Endian.little);
    data.setUint16(record + 6, 0x0100, Endian.little);
  }
  return bytes;
}

Uint8List _coordinatesWithCellCount(int count) {
  final bytes = Uint8List(12 + count * 48 + 2);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, count, Endian.little);
  data.setUint16(4, 8, Endian.little);
  data.setUint16(6, 8, Endian.little);
  return bytes;
}

Uint8List _coordinates() {
  final bytes = Uint8List(62);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 1, Endian.little);
  data.setUint16(4, 8, Endian.little);
  data.setUint16(6, 8, Endian.little);
  return bytes;
}

Gen5NitroSourceView _view({
  Uint8List? animation,
  Uint8List? cellBank,
  Uint8List? mapBank,
  Uint8List? timelineBank,
  Uint8List? coordinateBank,
}) => decodeGen5NitroSourceView(
  ncgr: _ncgr(),
  nclr: _nclr(),
  ncer: cellBank ?? _ncer(),
  nanr: animation ?? _animation(),
  nmcr: mapBank ?? _nmcr(),
  nmar: timelineBank ?? _animation(timeline: true),
  coordinates: coordinateBank ?? _coordinates(),
);

void main() {
  test('decodes the linear 4-bit Nitro battle atlas in pixel order', () {
    final source = _ncgr();
    final atlas = decodeGen5NcgrAtlas(source);
    expect(atlas.width, 256);
    expect(atlas.height, 128);
    for (final byteIndex in [0, 1, 127, 128, 0x3fff]) {
      final packed = source[0x30 + byteIndex];
      expect(atlas.indices[byteIndex * 2], packed & 15);
      expect(atlas.indices[byteIndex * 2 + 1], packed >> 4);
    }
    expect(() => atlas.indices[0] = 1, throwsUnsupportedError);
  });

  test('atlas indices are validated and detached from mutable input', () {
    final input = Uint8List(256 * 128)..[0] = 3;
    final atlas = Gen5IndexedAtlas.fromIndices(input);
    input[0] = 5;
    expect(atlas.indices[0], 3);
    expect(
      () => Gen5IndexedAtlas.fromIndices(Uint8List(2)),
      throwsFormatException,
    );
    expect(
      () => Gen5IndexedAtlas.fromIndices(Uint8List(256 * 128)..[0] = 16),
      throwsFormatException,
    );
  });

  test('decodes a BGR555 palette and keeps index zero transparent', () {
    final palette = decodeGen5NclrPalette(_nclr());
    expect(palette, hasLength(16));
    expect(palette[0], (r: 0, g: 0, b: 0));
    expect(palette[1], (r: 8, g: 8, b: 8));
    expect(palette[2], (r: 255, g: 0, b: 0));
    expect(palette[3], (r: 0, g: 255, b: 0));
    expect(palette[4], (r: 0, g: 0, b: 255));
    expect(palette[15], (r: 123, g: 123, b: 123));
    final rgba = colorizeGen5IndexedAtlas(
      decodeGen5NcgrAtlas(_ncgr()),
      palette,
    );
    expect(rgba.sublist(0, 4), [0, 0, 0, 0]);
    expect(rgba.sublist(8, 12), [57, 57, 57, 255]);
  });

  test('rejects malformed or unsupported NCGR layouts', () {
    final cases = <Uint8List>[
      Uint8List.fromList(_ncgr().sublist(0, 100)),
      _ncgr()..[0] = 0,
      _ncgr()..[4] = 0,
      _ncgr()..[6] = 2,
      _ncgr()..[16] = 0,
      _ncgr()..[24] = 15,
      _ncgr()..[28] = 4,
      _ncgr()..[32] = 0x10,
      _ncgr()..[34] = 0x10,
      _ncgr()..[36] = 0,
      _ncgr()..[40] = 1,
      _ncgr()..[44] = 0xff,
      _ncgr()..[0x4034] = 0xff,
    ];
    for (final candidate in cases) {
      expect(() => decodeGen5NcgrAtlas(candidate), throwsFormatException);
    }
  });

  test('rejects malformed or truncated NCLR palettes', () {
    final cases = <Uint8List>[
      Uint8List.fromList(_nclr().sublist(0, 71)),
      _nclr()..[0] = 0,
      _nclr()..[4] = 0,
      _nclr()..[6] = 2,
      _nclr()..[16] = 0,
      _nclr()..[20] = 24,
      _nclr()..[24] = 3,
      _nclr()..[26] = 9,
      _nclr()..[28] = 1,
      _nclr()..[32] = 30,
      _nclr()..[36] = 0xff,
    ];
    for (final candidate in cases) {
      expect(() => decodeGen5NclrPalette(candidate), throwsFormatException);
    }
  });

  test('joins raw Nitro graphics and animation banks into playable nodes', () {
    final view = _view();
    final controller = Gen5MultiCellController(
      cells: view.cells,
      animations: view.animations,
      maps: view.maps,
      timeline: view.timelines.single,
    );
    expect(view.indexedAtlas.indices, hasLength(256 * 128));
    expect(view.palette, hasLength(16));
    expect(view.info.cells, hasLength(1));
    expect(controller.nodes.single.cellIndex, 0);
    expect(controller.parts, hasLength(1));
    controller.advance();
    expect(controller.nodes.single.cellIndex, 0);
  });

  test('rejects cross-bank references that target a missing cell', () {
    expect(
      () => _view(animation: _animation(target: 1)),
      throwsFormatException,
    );
  });

  test('rejects oversized native animation banks before decoding', () {
    expect(() => _view(animation: Uint8List(1048577)), throwsFormatException);
  });

  test('rejects missing, truncated and duplicate sections in native banks', () {
    for (final kind in ['cell', 'animation', 'map', 'timeline']) {
      final source = switch (kind) {
        'cell' => _ncer(),
        'animation' => _animation(),
        'map' => _nmcr(),
        _ => _animation(timeline: true),
      };
      final missing = Uint8List.fromList(source)..[14] = 2;
      final truncated = _withAdditionalSection(source)..[source.length + 4] = 9;
      final duplicate = _withAdditionalSection(source, duplicate: true);
      final undeclared = _withAdditionalSection(source)..[14] = 1;
      final invalidHeader = Uint8List.fromList(source)..[12] = 0;
      for (final bytes in [
        missing,
        truncated,
        duplicate,
        undeclared,
        invalidHeader,
      ]) {
        expect(
          () => switch (kind) {
            'cell' => _view(cellBank: bytes),
            'animation' => _view(animation: bytes),
            'map' => _view(mapBank: bytes),
            _ => _view(timelineBank: bytes),
          },
          throwsFormatException,
          reason: '$kind must validate every declared section',
        );
      }
    }
  });

  test('accepts a complete additional section in each native bank', () {
    expect(
      () => _view(cellBank: _withAdditionalSection(_ncer())),
      returnsNormally,
    );
    expect(
      () => _view(animation: _withAdditionalSection(_animation())),
      returnsNormally,
    );
    expect(
      () => _view(mapBank: _withAdditionalSection(_nmcr())),
      returnsNormally,
    );
    expect(
      () => _view(
        timelineBank: _withAdditionalSection(_animation(timeline: true)),
      ),
      returnsNormally,
    );
  });

  test(
    'rejects unsupported controller sequences reachable from the native view',
    () {
      for (final invalid in [
        _animation(playback: 0),
        _animation(playback: 5),
        _animation(durations: [0]),
        _animation(durations: [3, 0])..[50] = 1,
      ]) {
        expect(() => _view(animation: invalid), throwsFormatException);
      }
      for (final invalid in [
        _animation(timeline: true, playback: 0),
        _animation(timeline: true, playback: 5),
        _animation(timeline: true, durations: [0]),
        _animation(timeline: true, durations: [3, 0])..[50] = 1,
      ]) {
        expect(() => _view(timelineBank: invalid), throwsFormatException);
      }
    },
  );

  test('allows zero-duration frames when a reachable active frame exists', () {
    final view = _view(
      animation: _animation(durations: [0, 3]),
      timelineBank: _animation(timeline: true, durations: [0, 3]),
    );
    final controller = Gen5MultiCellController(
      cells: view.cells,
      animations: view.animations,
      maps: view.maps,
      timeline: view.timelines.single,
    );
    expect(controller.nodes.single.cellIndex, 0);
  });

  test(
    'validates controller compatibility only for reachable child sequences',
    () {
      final animation = _animationWithUnreachableSequence();
      expect(() => _view(animation: animation), returnsNormally);
      final map = _nmcr()..[56] = 1;
      expect(
        () => _view(animation: animation, mapBank: map),
        throwsFormatException,
      );
    },
  );

  test('rejects reachable zero scales before the parts renderer sees them', () {
    for (final parent in [false, true]) {
      for (final offset in [76, 80]) {
        final invalid = _animation(timeline: parent);
        ByteData.sublistView(invalid).setInt32(offset, 0, Endian.little);
        final cells = decodeGen5Ncer(_ncer());
        final animations = decodeGen5Nanr(parent ? _animation() : invalid);
        final maps = decodeGen5Nmcr(_nmcr());
        final timeline = decodeGen5Nmar(
          parent ? invalid : _animation(timeline: true),
        ).single;
        final controller = Gen5MultiCellController(
          cells: cells,
          animations: animations,
          maps: maps,
          timeline: timeline,
        );
        expect(() => controller.parts, throwsFormatException);
        expect(
          () =>
              parent ? _view(timelineBank: invalid) : _view(animation: invalid),
          throwsFormatException,
          reason: 'parent=$parent scale offset=$offset',
        );
      }
    }
  });

  test('permits zero scale in frames the controller cannot display', () {
    for (final parent in [false, true]) {
      for (final beforeLoop in [false, true]) {
        final sequence = _animationWithSeparateFrames(
          timeline: parent,
          firstDuration: beforeLoop ? 3 : 0,
          loopStart: beforeLoop ? 1 : 0,
        );
        final view = parent
            ? _view(timelineBank: sequence)
            : _view(animation: sequence);
        final controller = Gen5MultiCellController(
          cells: view.cells,
          animations: view.animations,
          maps: view.maps,
          timeline: view.timelines.single,
        );
        expect(controller.parts, hasLength(1));
        controller.advance();
        expect(controller.parts, hasLength(1));
      }
    }
  });

  test('permits unreachable zero-scale child sequences', () {
    final animation = _animationWithUnreachableZeroScale();
    expect(() => _view(animation: animation), returnsNormally);
    expect(
      () => _view(animation: animation, mapBank: _nmcr()..[56] = 1),
      throwsFormatException,
    );
  });

  test('does not validate a shadowed shared-slot sequence as reachable', () {
    final view = _view(
      animation: _animationWithUnreachableSequence(),
      mapBank: _nmcrWithSharedSlot(),
    );
    final controller = Gen5MultiCellController(
      cells: view.cells,
      animations: view.animations,
      maps: view.maps,
      timeline: view.timelines.single,
    );
    expect(controller.parts, hasLength(2));
  });

  test('does not treat skipped parent maps as controller-reachable', () {
    for (final beforeLoop in [false, true]) {
      final view = _view(
        animation: _animationWithUnreachableSequence(),
        mapBank: _nmcrWithTwoMaps(),
        timelineBank: _animationWithSeparateFrames(
          timeline: true,
          firstDuration: beforeLoop ? 3 : 0,
          firstTarget: 1,
          loopStart: beforeLoop ? 1 : 0,
        ),
      );
      final controller = Gen5MultiCellController(
        cells: view.cells,
        animations: view.animations,
        maps: view.maps,
        timeline: view.timelines.single,
      );
      expect(controller.parts, hasLength(1));
    }
  });

  test('rejects zero scale reached by nonlooping reverse playback', () {
    for (final parent in [false, true]) {
      final sequence = _animationWithSeparateFrames(
        timeline: parent,
        firstDuration: 3,
        loopStart: 1,
        playback: 3,
      );
      final timeline = parent
          ? sequence
          : _animation(timeline: true, durations: [100]);
      final animation = parent ? _animation() : sequence;
      final controller = Gen5MultiCellController(
        cells: decodeGen5Ncer(_ncer()),
        animations: decodeGen5Nanr(animation),
        maps: decodeGen5Nmcr(_nmcr()),
        timeline: decodeGen5Nmar(timeline).single,
      );
      for (var i = 0; i < 6; i++) {
        controller.advance();
      }
      expect(() => controller.parts, throwsFormatException);
      expect(
        () => _view(animation: animation, timelineBank: timeline),
        throwsFormatException,
        reason: 'parent=$parent',
      );
    }
  });

  test('validates the terminal map of nonlooping reverse playback', () {
    final timeline = _animationWithSeparateFrames(
      timeline: true,
      firstDuration: 3,
      firstTarget: 1,
      loopStart: 1,
      playback: 3,
    );
    ByteData.sublistView(timeline).setInt32(84, 4096, Endian.little);
    final animations = _animationWithUnreachableSequence();
    final maps = _nmcrWithTwoMaps();
    final controller = Gen5MultiCellController(
      cells: decodeGen5Ncer(_ncer()),
      animations: decodeGen5Nanr(animations),
      maps: decodeGen5Nmcr(maps),
      timeline: decodeGen5Nmar(timeline).single,
    );
    expect(() {
      for (var i = 0; i < 6; i++) {
        controller.advance();
      }
    }, throwsFormatException);
    expect(
      () => _view(animation: animations, mapBank: maps, timelineBank: timeline),
      throwsFormatException,
    );
  });

  test('ignores a zero-duration terminal frame in reverse playback', () {
    for (final parent in [false, true]) {
      final sequence = _animationWithSeparateFrames(
        timeline: parent,
        loopStart: 1,
        playback: 3,
      );
      final timeline = parent
          ? sequence
          : _animation(timeline: true, durations: [100]);
      final animation = parent ? _animation() : sequence;
      final view = _view(animation: animation, timelineBank: timeline);
      final controller = Gen5MultiCellController(
        cells: view.cells,
        animations: view.animations,
        maps: view.maps,
        timeline: view.timelines.single,
      );
      for (var i = 0; i < 6; i++) {
        controller.advance();
      }
      expect(controller.parts, hasLength(1));
    }
  });

  test('bounds the number of renderable parts before controller rendering', () {
    final cells = _ncerWithObjectCounts([128]);
    final atLimit = _nmcrWithRecordCount(512);
    final view = _view(cellBank: cells, mapBank: atLimit);
    final controller = Gen5MultiCellController(
      cells: view.cells,
      animations: view.animations,
      maps: view.maps,
      timeline: view.timelines.single,
    );
    expect(controller.parts, hasLength(65536));

    final overflow = _nmcrWithRecordCount(513);
    final unsafe = Gen5MultiCellController(
      cells: decodeGen5Ncer(cells),
      animations: decodeGen5Nanr(_animation()),
      maps: decodeGen5Nmcr(overflow),
      timeline: decodeGen5Nmar(_animation(timeline: true)).single,
    );
    expect(() => unsafe.parts, throwsFormatException);
    expect(
      () => _view(cellBank: cells, mapBank: overflow),
      throwsFormatException,
    );
  });

  test(
    'ignores cells used only by zero-duration frames when bounding parts',
    () {
      final view = _view(
        cellBank: _ncerWithObjectCounts([127, 128]),
        coordinateBank: _coordinatesWithCellCount(2),
        mapBank: _nmcrWithRecordCount(513),
        animation: _animationWithSeparateFrames(firstTarget: 1),
      );
      final controller = Gen5MultiCellController(
        cells: view.cells,
        animations: view.animations,
        maps: view.maps,
        timeline: view.timelines.single,
      );
      expect(controller.parts, hasLength(65151));
    },
  );

  test('rejects an unproven combined bound even when sampled phases fit', () {
    final cells = _ncerWithObjectCounts([128, 0]);
    final animations = _opposingAnimations();
    final maps = _nmcrWithOpposingSlots(257);
    final timeline = _animation(timeline: true, durations: [100]);
    final controller = Gen5MultiCellController(
      cells: decodeGen5Ncer(cells),
      animations: decodeGen5Nanr(animations),
      maps: decodeGen5Nmcr(maps),
      timeline: decodeGen5Nmar(timeline).single,
    );
    for (var tick = 0; tick < 7; tick++) {
      expect(controller.parts, hasLength(32896));
      controller.advance();
    }
    expect(
      () => _view(
        animation: animations,
        cellBank: cells,
        mapBank: maps,
        coordinateBank: _coordinatesWithCellCount(2),
        timelineBank: timeline,
      ),
      throwsFormatException,
    );
  });

  test('rejects unsupported versions of each native animation bank', () {
    for (final kind in ['cell', 'animation', 'map', 'timeline']) {
      final source = switch (kind) {
        'cell' => _ncer(),
        'animation' => _animation(),
        'map' => _nmcr(),
        _ => _animation(timeline: true),
      };
      for (final version in [0, 0x0101, 0xffff]) {
        final bytes = Uint8List.fromList(source);
        ByteData.sublistView(bytes).setUint16(6, version, Endian.little);
        expect(
          () => switch (kind) {
            'cell' => _view(cellBank: bytes),
            'animation' => _view(animation: bytes),
            'map' => _view(mapBank: bytes),
            _ => _view(timelineBank: bytes),
          },
          throwsFormatException,
          reason: '$kind version $version',
        );
      }
    }
  });
}
