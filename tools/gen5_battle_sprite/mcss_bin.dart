import 'dart:typed_data';

final class Gen5McssQuad {
  const Gen5McssQuad(
    this.x,
    this.y,
    this.width,
    this.height,
    this.textureX,
    this.textureY,
  );

  final int x, y, width, height, textureX, textureY;
}

final class Gen5McssCell {
  const Gen5McssCell(this.primary, this.secondary);

  final Gen5McssQuad primary, secondary;
}

final class Gen5McssBin {
  const Gen5McssBin({
    required this.width,
    required this.height,
    required this.offsetX,
    required this.offsetY,
    required this.cells,
    required this.tail,
    required this.idleNodeIndices,
  });

  final int width, height, offsetX, offsetY;
  final List<Gen5McssCell> cells;
  final List<int> tail, idleNodeIndices;
}

Gen5McssBin decodeGen5McssBin(Uint8List bytes) {
  if (bytes.length < 14) throw const FormatException('Truncated MCSS data');
  final data = ByteData.sublistView(bytes);
  final count = data.getUint32(0, Endian.little);
  if (count == 0 || count > 4096 || count > (bytes.length - 14) ~/ 48) {
    throw const FormatException('Invalid MCSS cell count');
  }
  Gen5McssQuad quad(int offset) => Gen5McssQuad(
    data.getInt32(offset, Endian.little),
    data.getInt32(offset + 4, Endian.little),
    data.getInt32(offset + 8, Endian.little),
    data.getInt32(offset + 12, Endian.little),
    data.getInt32(offset + 16, Endian.little),
    data.getInt32(offset + 20, Endian.little),
  );
  final cells = <Gen5McssCell>[];
  for (var i = 0; i < count; i++) {
    final offset = 12 + i * 48;
    cells.add(Gen5McssCell(quad(offset), quad(offset + 24)));
  }
  final tailStart = 12 + count * 48;
  final tail = bytes.sublist(tailStart);
  final idleCount = tail[0];
  if (idleCount != 255 && idleCount > tail.length - 2) {
    throw const FormatException('Truncated MCSS idle nodes');
  }
  return Gen5McssBin(
    width: data.getUint16(4, Endian.little),
    height: data.getUint16(6, Endian.little),
    offsetX: data.getInt16(8, Endian.little),
    offsetY: data.getInt16(10, Endian.little),
    cells: List.unmodifiable(cells),
    tail: List.unmodifiable(tail),
    idleNodeIndices: List.unmodifiable(
      idleCount == 255 ? <int>[] : tail.sublist(2, 2 + idleCount),
    ),
  );
}
