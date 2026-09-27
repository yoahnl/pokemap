import 'dart:io';

import 'package:image/image.dart' as image;

Future<void> main() async {
  final source = File(
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_256x256.png',
  );
  final icon = image.decodePng(await source.readAsBytes());
  if (icon == null) {
    throw const FormatException('Avelune Studio app icon is not a PNG.');
  }

  final destination = File('windows/runner/resources/app_icon.ico');
  await destination.parent.create(recursive: true);
  await destination.writeAsBytes(image.encodeIco(icon));
}
