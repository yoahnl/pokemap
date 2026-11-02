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

Uint8List cells() {
  final bytes = bank('RECN', 'KBEC', 46);
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, 1, Endian.little);
  data.setUint32(28, 24, Endian.little);
  data.setUint16(48, 1, Endian.little);
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

int render({
  Uint8List? ncer,
  Uint8List? nanr,
  Uint8List? nmcr,
  Uint8List? nmar,
  Uint8List? info,
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
      ..tiles = copy(Uint8List(16384))
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
      ..tick = 0
      ..minX = -64
      ..minY = -64
      ..width = 128
      ..height = 128
      ..childMode = 0
      ..parentCompleted = 0;
    info ??= rectangles();
    return probeRenderRectangles(
      request,
      allocate<Uint8>(16384),
      16384,
      allocate<Int32>(264 * sizeOf<Int32>()),
      264,
      copy(info),
      info.length,
    );
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

  test('accepts atlas rectangles larger than 64 pixels', () {
    expect(render(info: rectangles(width: 72, height: 80)), 0);
  });

  test('rejects rectangles that extend beyond the atlas', () {
    expect(render(info: rectangles(width: 256, u: 8)), -30);
    expect(render(info: rectangles(height: 136)), -30);
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
