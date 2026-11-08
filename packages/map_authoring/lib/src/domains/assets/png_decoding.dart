import 'dart:typed_data';

import 'package:image/image.dart' as image;

bool decodesAsSingleFramePng(
  List<int> bytes, {
  required int width,
  required int height,
}) {
  try {
    final decoded = image.decodePng(Uint8List.fromList(bytes));
    return decoded != null &&
        decoded.width == width &&
        decoded.height == height &&
        decoded.numFrames == 1;
  } on Object {
    return false;
  }
}
