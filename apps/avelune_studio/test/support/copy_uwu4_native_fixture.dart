import 'dart:io';
import 'package:image/image.dart' as image;

Future<void> copyUwU4NativeFixture(Directory source) async {
  final requested = Platform.environment['UWU4_NATIVE_FIXTURE'];
  if (requested == null || requested.isEmpty) return;
  final target = Directory(requested);
  if (await target.exists()) return;
  await target.create(recursive: true);
  await for (final entry in source.list(recursive: true, followLinks: false)) {
    final relative = entry.path.substring(source.path.length + 1);
    if (entry is Directory) {
      await Directory('${target.path}/$relative').create(recursive: true);
    } else if (entry is File) {
      final destination = File('${target.path}/$relative');
      await destination.parent.create(recursive: true);
      await entry.copy(destination.path);
    }
  }
  final pixels = image.Image(width: 64, height: 48, numChannels: 4);
  image.fill(pixels, color: image.ColorRgba8(215, 139, 73, 255));
  image.fillRect(
    pixels,
    x1: 16,
    y1: 0,
    x2: 47,
    y2: 47,
    color: image.ColorRgba8(92, 172, 103, 255),
  );
  await File(
    '${target.path}-candidate.png',
  ).writeAsBytes(image.encodePng(pixels));
}
