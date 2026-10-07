import 'dart:convert';
import 'dart:typed_data';

Uint8List normalizeGlbAccessors(Uint8List bytes) {
  final header = ByteData.sublistView(bytes);
  final jsonLength = header.getUint32(12, Endian.little);
  final json =
      jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
          as Map<String, dynamic>;
  final binOffset = 28 + jsonLength;
  final binary = BytesBuilder()..add(bytes.sublist(binOffset));
  final views = json['bufferViews'] as List;
  for (final raw in (json['materials'] as List? ?? const [])) {
    final material = raw as Map<String, dynamic>;
    material.putIfAbsent('pbrMetallicRoughness', () => <String, dynamic>{});
  }
  final accessors = json['accessors'] as List;
  for (final raw in accessors) {
    final accessor = raw as Map<String, dynamic>;
    final view = views[accessor['bufferView'] as int] as Map<String, dynamic>;
    final componentSize = switch (accessor['componentType']) {
      5120 || 5121 => 1,
      5122 || 5123 => 2,
      5125 || 5126 => 4,
      _ => throw const FormatException('Unsupported accessor component.'),
    };
    final components = switch (accessor['type']) {
      'SCALAR' => 1,
      'VEC2' => 2,
      'VEC3' => 3,
      'VEC4' || 'MAT2' => 4,
      'MAT3' => 9,
      'MAT4' => 16,
      _ => throw const FormatException('Unsupported accessor type.'),
    };
    final size = componentSize * components;
    final count = accessor['count'] as int;
    final stride = (view['byteStride'] as int?) ?? size;
    final start =
        binOffset +
        ((view['byteOffset'] as int?) ?? 0) +
        ((accessor['byteOffset'] as int?) ?? 0);
    final alignedOffset = (binary.length + 3) ~/ 4 * 4;
    if (alignedOffset > binary.length) {
      binary.add(Uint8List(alignedOffset - binary.length));
    }
    for (var i = 0; i < count; i++) {
      binary.add(
        Uint8List.sublistView(
          bytes,
          start + i * stride,
          start + i * stride + size,
        ),
      );
    }
    accessor['bufferView'] = views.length;
    accessor.remove('byteOffset');
    views.add({
      'buffer': 0,
      'byteOffset': alignedOffset,
      'byteLength': count * size,
    });
  }
  (json['buffers'] as List).first['byteLength'] = binary.length;
  final encoded = utf8.encode(jsonEncode(json));
  final paddedJson = (encoded.length + 3) ~/ 4 * 4;
  final paddedBinary = (binary.length + 3) ~/ 4 * 4;
  final result = Uint8List(28 + paddedJson + paddedBinary);
  final data = ByteData.sublistView(result);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, result.length, Endian.little);
  data.setUint32(12, paddedJson, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  result.fillRange(20, 20 + paddedJson, 32);
  result.setRange(20, 20 + encoded.length, encoded);
  data.setUint32(20 + paddedJson, paddedBinary, Endian.little);
  data.setUint32(24 + paddedJson, 0x004e4942, Endian.little);
  result.setRange(
    28 + paddedJson,
    28 + paddedJson + binary.length,
    binary.takeBytes(),
  );
  return result;
}
