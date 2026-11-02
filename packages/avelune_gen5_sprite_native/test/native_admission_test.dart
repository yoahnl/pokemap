import 'dart:ffi';
import 'dart:typed_data';

import 'package:avelune_gen5_sprite_native/src/native_bindings.dart';
import 'package:test/test.dart';

Uint8List bank(String header, String section, int sectionLength) {
  final bytes = Uint8List(16 + sectionLength);
  bytes.setRange(0, 4, header.codeUnits);
  bytes.setRange(16, 20, section.codeUnits);
  ByteData.sublistView(bytes).setUint32(20, sectionLength, Endian.little);
  return bytes;
}

Uint8List cells({int count = 1}) {
  final bytes = bank('RECN', 'KBEC', 32 + count * 14);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, count, Endian.little);
  data.setUint32(28, 24, Endian.little);
  for (var i = 0; i < count; i++) {
    data.setUint16(48 + i * 8, 1, Endian.little);
    data.setUint32(52 + i * 8, i * 6, Endian.little);
  }
  return bytes;
}

Uint8List maps({int count = 1, int records = 1}) {
  final bytes = bank('RCMN', 'KBCM', 24 + count * 8 + records * 8);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, count, Endian.little);
  data.setUint32(28, 16, Endian.little);
  for (var i = 0; i < count; i++) {
    data.setUint16(40 + i * 8, records, Endian.little);
  }
  return bytes;
}

Uint8List animations(String magic, {int count = 1, int frames = 1}) {
  final bytes = bank(magic, 'KNBA', 24 + count * 16 + frames * 8 + 2);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, count, Endian.little);
  data.setUint32(28, 16, Endian.little);
  data.setUint32(32, 16 + count * 16, Endian.little);
  data.setUint32(36, 16 + count * 16 + frames * 8, Endian.little);
  for (var i = 0; i < count; i++) {
    data.setUint16(40 + i * 16, frames, Endian.little);
  }
  for (var i = 0; i < frames; i++) {
    data.setUint16(40 + count * 16 + i * 8 + 4, 1, Endian.little);
  }
  return bytes;
}

Uint8List oversizedTransform(String magic) {
  final bytes = bank(magic, 'KNBA', 64);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 16, Endian.little);
  data.setUint32(32, 32, Endian.little);
  data.setUint32(36, 40, Endian.little);
  data.setUint16(40, 1, Endian.little);
  data.setUint16(44, 1, Endian.little);
  data.setUint16(60, 1, Endian.little);
  data.setInt32(68, 32 * 4096, Endian.little);
  data.setInt32(72, 4096, Endian.little);
  return bytes;
}

Uint8List rectangles({int width = 8, int height = 8, int u = 0, int v = 0}) {
  final bytes = Uint8List(62);
  final data = ByteData.sublistView(bytes);
  data.setInt32(0, 1, Endian.little);
  data.setInt32(20, width * 4096, Endian.little);
  data.setInt32(24, height * 4096, Endian.little);
  data.setInt32(28, u * 4096, Endian.little);
  data.setInt32(32, v * 4096, Endian.little);
  return bytes;
}

Uint8List rectanglesWithInvalidSecondCell() {
  final bytes = Uint8List(110);
  bytes.setRange(0, 60, rectangles());
  final data = ByteData.sublistView(bytes);
  data.setInt32(0, 2, Endian.little);
  data.setInt32(68, 17 * 4096, Endian.little);
  data.setInt32(72, 8 * 4096, Endian.little);
  data.setInt32(76, 240 * 4096, Endian.little);
  return bytes;
}

Uint8List twoFrameCellSwitch() {
  final bytes = bank('RNAN', 'KNBA', 60);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 16, Endian.little);
  data.setUint32(32, 32, Endian.little);
  data.setUint32(36, 48, Endian.little);
  data.setUint16(40, 2, Endian.little);
  data.setUint16(60, 1, Endian.little);
  data.setUint32(64, 2, Endian.little);
  data.setUint16(68, 1, Endian.little);
  data.setUint16(74, 1, Endian.little);
  return bytes;
}

int render({
  Uint8List? ncer,
  Uint8List? nanr,
  Uint8List? nmcr,
  Uint8List? nmar,
  Uint8List? info,
  Uint8List? tiles,
  Uint8List? output,
  int tick = 0,
}) {
  final allocations = <Pointer<Void>>[];
  Pointer<T> allocate<T extends NativeType>(int size) {
    final pointer = probeAlloc(size);
    if (pointer == nullptr) throw StateError('Native allocation failed');
    allocations.add(pointer);
    return pointer.cast<T>();
  }

  Pointer<Uint8> copy(Uint8List bytes) {
    final pointer = allocate<Uint8>(bytes.length);
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    return pointer;
  }

  try {
    ncer ??= cells();
    nanr ??= animations('RNAN');
    nmcr ??= maps();
    nmar ??= animations('RAMN');
    final request = allocate<ProbeRequest>(sizeOf<ProbeRequest>());
    request.ref
      ..tiles = copy(tiles ?? Uint8List(16384))
      ..tileSize = 16384
      ..ncer = copy(ncer)
      ..ncerSize = ncer.length
      ..nanr = copy(nanr)
      ..nanrSize = nanr.length
      ..nmcr = copy(nmcr)
      ..nmcrSize = nmcr.length
      ..nmar = copy(nmar)
      ..nmarSize = nmar.length
      ..timeline = 0
      ..tick = tick
      ..minX = -64
      ..minY = -64
      ..width = 128
      ..height = 128
      ..childMode = 0
      ..parentCompleted = 0;
    info ??= rectangles();
    final pixels = allocate<Uint8>(16384);
    final result = probeRenderRectangles(
      request,
      pixels,
      16384,
      allocate<Int32>(264 * sizeOf<Int32>()),
      264,
      copy(info),
      info.length,
    );
    output?.setAll(0, pixels.asTypedList(16384));
    return result;
  } finally {
    for (final pointer in allocations.reversed) {
      probeFree(pointer);
    }
  }
}

void main() {
  test('accepts a small complete synthetic frame', () {
    expect(render(), 0);
  });

  test('draws the second cell rectangle above the first', () {
    final info = rectangles();
    ByteData.sublistView(info)
      ..setInt32(44, 8 * 4096, Endian.little)
      ..setInt32(48, 8 * 4096, Endian.little)
      ..setInt32(52, 8 * 4096, Endian.little);
    final tiles = Uint8List(16384)
      ..fillRange(0, 32, 0x11)
      ..fillRange(32, 64, 0x22)
      ..[32] = 0x20;
    final output = Uint8List(16384);

    expect(render(info: info, tiles: tiles, output: output), 0);
    expect(output[64 * 128 + 64], 1);
    expect(output[64 * 128 + 65], 2);
  });

  test('preserves the layering between separate animation records', () {
    final info = Uint8List(110)..setRange(0, 60, rectangles());
    ByteData.sublistView(info)
      ..setInt32(0, 2, Endian.little)
      ..setInt32(44, 8 * 4096, Endian.little)
      ..setInt32(48, 8 * 4096, Endian.little)
      ..setInt32(52, 8 * 4096, Endian.little)
      ..setInt32(68, 8 * 4096, Endian.little)
      ..setInt32(72, 8 * 4096, Endian.little)
      ..setInt32(76, 16 * 4096, Endian.little);
    final nanr = bank('RNAN', 'KNBA', 76);
    ByteData.sublistView(nanr)
      ..setUint16(24, 2, Endian.little)
      ..setUint32(28, 16, Endian.little)
      ..setUint32(32, 48, Endian.little)
      ..setUint32(36, 64, Endian.little)
      ..setUint16(40, 1, Endian.little)
      ..setUint16(56, 1, Endian.little)
      ..setUint32(68, 8, Endian.little)
      ..setUint16(76, 1, Endian.little)
      ..setUint32(80, 2, Endian.little)
      ..setUint16(84, 1, Endian.little)
      ..setUint16(90, 1, Endian.little);
    final nmcr = maps(records: 2);
    ByteData.sublistView(nmcr).setUint16(56, 1, Endian.little);
    final tiles = Uint8List(16384)
      ..fillRange(0, 32, 0x11)
      ..fillRange(32, 64, 0x22)
      ..fillRange(64, 96, 0x33);
    final output = Uint8List(16384);

    expect(
      render(
        ncer: cells(count: 2),
        nanr: nanr,
        nmcr: nmcr,
        info: info,
        tiles: tiles,
        output: output,
      ),
      0,
    );
    expect(output[64 * 128 + 64], 2);
  });

  test('accepts atlas rectangles larger than 64 pixels', () {
    expect(render(info: rectangles(width: 72, height: 80)), 0);
  });

  test('renders whole-pixel rectangles that do not fill their last tile', () {
    for (final (width, height, u, v) in [
      (23, 8, 0, 0),
      (39, 16, 32, 0),
      (48, 41, 40, 0),
      (23, 9, 232, 112),
    ]) {
      final output = Uint8List(16384);
      expect(
        render(
          info: rectangles(width: width, height: height, u: u, v: v),
          tiles: Uint8List(16384)..fillRange(0, 16384, 0x11),
          output: output,
        ),
        0,
      );
      expect(output.where((pixel) => pixel != 0).length, width * height);
    }
  });

  test('rejects fractional-pixel rectangle sizes', () {
    final info = rectangles(width: 23);
    ByteData.sublistView(info).setInt32(20, 23 * 4096 + 1, Endian.little);
    expect(render(info: info), -30);
  });

  test('only rejects an invalid atlas cell when a frame selects it', () {
    final ncer = cells(count: 2);
    final nanr = twoFrameCellSwitch();
    final info = rectanglesWithInvalidSecondCell();
    expect(render(ncer: ncer, nanr: nanr, info: info), 0);
    expect(render(ncer: ncer, nanr: nanr, info: info, tick: 1), -30);
  });

  test('rejects rectangles that extend beyond the atlas', () {
    expect(render(info: rectangles(width: 256, u: 8)), -30);
    expect(render(info: rectangles(height: 136)), -30);
    expect(render(info: rectangles(width: 17, u: 240)), -30);
    expect(render(info: rectangles(height: 17, v: 112)), -30);
  });

  test('rejects overlapping map tables with excessive total records', () {
    expect(render(nmcr: maps(count: 65, records: 128)), -4);
  });

  test('rejects overlapping animation tables with excessive total frames', () {
    expect(render(nanr: animations('RNAN', count: 65, frames: 128)), -4);
    expect(render(nmar: animations('RAMN', count: 65, frames: 128)), -4);
  });

  test('rejects transforms outside the supported range', () {
    expect(render(nmar: oversizedTransform('RAMN')), -5);
    expect(render(nanr: oversizedTransform('RNAN')), -5);
  });
}
