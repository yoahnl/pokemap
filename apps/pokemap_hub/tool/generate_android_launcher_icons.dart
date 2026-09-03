import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;

const _usage =
    'dart run tool/generate_android_launcher_icons.dart [--check | --help]';

void main(List<String> arguments) {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.writeln(_usage);
    stdout.writeln(
      'Generate Android icons from the iOS AppIcon source artwork.',
    );
    stdout.writeln('--check verifies generated files without changing them.');
    return;
  }
  if (arguments.isNotEmpty &&
      (arguments.length != 1 || arguments.single != '--check')) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  try {
    final root = Platform.script.resolve('../');
    final source = File.fromUri(
      root.resolve('ios/Runner/AppIcon.icon/Assets/Avelune_AppIcon_1024.png'),
    );
    final artwork = image.decodePng(source.readAsBytesSync());
    if (artwork == null || artwork.width != artwork.height) {
      throw const FormatException('The source must be a square PNG image.');
    }

    final images = <String, image.Image>{};
    const densities = {
      'ldpi': 0.75,
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    for (final density in densities.entries) {
      final path = 'mipmap-${density.key}';
      final legacy = _resize(artwork, (48 * density.value).round());
      images['$path/ic_launcher.png'] = legacy;
      images['$path/ic_launcher_round.png'] = image.copyCropCircle(legacy);
      images['$path/ic_launcher_foreground.png'] = _foreground(
        artwork,
        (108 * density.value).round(),
        (72 * density.value).round(),
      );
    }
    images['ic_launcher-web.png'] = _resize(artwork, 512);
    images['playstore-icon.png'] = images['ic_launcher-web.png']!;
    images['adaptive-foreground.png'] = _foreground(artwork, 1024, 682);

    final checkOnly = arguments.contains('--check');
    var outdated = 0;
    for (final entry in images.entries) {
      final file = File.fromUri(
        root.resolve('android/app/src/main/res/${entry.key}'),
      );
      final bytes = image.encodePng(entry.value);
      if (checkOnly) {
        if (!file.existsSync() ||
            sha256.convert(file.readAsBytesSync()) != sha256.convert(bytes)) {
          stderr.writeln('Outdated icon: ${entry.key}');
          outdated++;
        }
      } else {
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
      }
    }
    if (outdated != 0) {
      stderr.writeln(
        'Regenerate with: dart run tool/generate_android_launcher_icons.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln(
      '${checkOnly ? 'Verified' : 'Generated'} ${images.length} Android icons.',
    );
  } on Object catch (error) {
    stderr.writeln('Android icon generation failed: $error');
    exitCode = 1;
  }
}

image.Image _resize(image.Image artwork, int size) => image.copyResize(
  artwork,
  width: size,
  height: size,
  interpolation: image.Interpolation.average,
);

image.Image _foreground(image.Image artwork, int size, int artworkSize) =>
    image.compositeImage(
      image.Image(width: size, height: size, numChannels: 4),
      _resize(artwork, artworkSize),
      center: true,
      blend: image.BlendMode.direct,
    );
