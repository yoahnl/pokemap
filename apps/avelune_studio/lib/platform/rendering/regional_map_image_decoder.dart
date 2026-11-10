import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../features/regional_map/domain/regional_map_port.dart';

Future<({Uint8List bytes, int width, int height})?> decodeRegionalMapImage(
  RegionalMapPort port,
  String path,
) async {
  try {
    final bytes = await port.readImage(path);
    if (bytes == null) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return (
          bytes: bytes,
          width: frame.image.width,
          height: frame.image.height,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  } on Object catch (error) {
    throw StateError('$error');
  }
}
