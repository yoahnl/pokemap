import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:image/image.dart' as image;

Future<PickedResourceImage> characterTestImage(
  Directory directory,
  String name,
  int width,
  int height,
) async {
  final picture = image.Image(width: width, height: height, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 3; column++) {
      image.fillRect(
        picture,
        x1: column * (width ~/ 3),
        y1: row * (height ~/ 4),
        x2: (column + 1) * (width ~/ 3) - 1,
        y2: (row + 1) * (height ~/ 4) - 1,
        color: image.ColorRgba8(40 + row * 40, 90, 80 + column * 50, 255),
      );
    }
  }
  final bytes = Uint8List.fromList(image.encodePng(picture));
  final file = File('${directory.path}/$name.png');
  await file.writeAsBytes(bytes);
  return PickedResourceImage(file.path, name, bytes, width, height);
}
