import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/ncer.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';
import '../../../tools/gen5_battle_sprite/source_view.dart';

void main() {
  Gen5NitroFrame frame(int target) => Gen5NitroFrame(
    targetIndex: target,
    duration: 1,
    marker: 0,
    transformType: 0,
    rotation: 0,
    scaleX: 4096,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );
  Gen5NitroSequence sequence(int target) => Gen5NitroSequence(
    loopStart: 0,
    playbackType: 2,
    format: 0,
    frames: [frame(target)],
  );
  const quad = Gen5McssQuad(0, 0, 4096, 4096, 0, 0);
  const info = Gen5McssBin(
    width: 1,
    height: 1,
    offsetX: 0,
    offsetY: 0,
    cells: [Gen5McssCell(quad, quad)],
    tail: [],
    idleNodeIndices: [],
  );
  final cells = [Gen5NcerCell(0, [])];
  final maps = [
    const Gen5NmcrMap(1, [Gen5NmcrRecord(0, 0, 0, 0)]),
  ];

  test(
    'checks the closure of timeline, node animation and MCSS cell references',
    () {
      expect(
        () => validateGen5ViewReferences(
          info: info,
          cells: cells,
          animations: [sequence(0), sequence(9)],
          maps: maps,
          timelines: [sequence(0)],
        ),
        returnsNormally,
      );
    },
  );

  test('rejects an invalid reachable cell and an invalid timeline map', () {
    expect(
      () => validateGen5ViewReferences(
        info: info,
        cells: cells,
        animations: [sequence(1)],
        maps: maps,
        timelines: [sequence(0)],
      ),
      throwsFormatException,
    );
    expect(
      () => validateGen5ViewReferences(
        info: info,
        cells: cells,
        animations: [sequence(0)],
        maps: maps,
        timelines: [sequence(1)],
      ),
      throwsFormatException,
    );
  });

  test('rejects a node with a missing shared slot', () {
    expect(
      () => validateGen5ViewReferences(
        info: info,
        cells: cells,
        animations: [sequence(0)],
        maps: [
          const Gen5NmcrMap(0, [Gen5NmcrRecord(0, 0, 0, 0)]),
        ],
        timelines: [sequence(0)],
      ),
      throwsFormatException,
    );
  });

  test('reads 16 palette colors and rejects malformed channels', () {
    final valid = Uint8List.fromList(
      ascii.encode(
        'JASC-PAL\n0100\n16\n${List.filled(16, '16 238 8').join('\n')}\n',
      ),
    );
    final palette = parseGen5SourcePalette(valid);
    expect(palette, hasLength(16));
    expect((palette.first.r, palette.first.g, palette.first.b), (16, 238, 8));
    final invalid = Uint8List.fromList(
      ascii.encode(
        'JASC-PAL\n0100\n16\n${List.filled(16, '16 256 8').join('\n')}\n',
      ),
    );
    expect(() => parseGen5SourcePalette(invalid), throwsFormatException);
  });

  test('checks the expected PNG atlas header and dimensions', () {
    final bytes = Uint8List(33);
    bytes.setRange(0, 8, [137, 80, 78, 71, 13, 10, 26, 10]);
    final data = ByteData.sublistView(bytes);
    data.setUint32(8, 13);
    bytes.setRange(12, 16, ascii.encode('IHDR'));
    data.setUint32(16, 256);
    data.setUint32(20, 128);
    expect(() => validateGen5AtlasHeader(bytes), returnsNormally);
    data.setUint32(20, 129);
    expect(() => validateGen5AtlasHeader(bytes), throwsFormatException);
  });

  test('rejects unsupported views and incomplete verified asset sets', () {
    expect(
      () => decodeGen5SourceView({}, view: 'side', shiny: false),
      throwsFormatException,
    );
    expect(
      () => decodeGen5SourceView({}, view: 'front', shiny: false),
      throwsFormatException,
    );
  });
}
