import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:test/test.dart';

const _densities = {
  'ldpi': 0.75,
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  final resources = Directory('android/app/src/main/res');
  final artwork =
      image.decodePng(
        File(
          'ios/Runner/AppIcon.icon/Assets/Avelune_AppIcon_1024.png',
        ).readAsBytesSync(),
      )!;

  for (final density in _densities.entries) {
    final path = '${resources.path}/mipmap-${density.key}';
    final size = (48 * density.value).round();

    test('legacy ${density.key} uses the current Avelune artwork', () {
      final icon =
          image.decodePng(File('$path/ic_launcher.png').readAsBytesSync())!;
      final expected = image.copyResize(
        artwork,
        width: size,
        height: size,
        interpolation: image.Interpolation.average,
      );

      expect(icon.width, size);
      expect(icon.height, size);
      expect(
        icon.getBytes(order: image.ChannelOrder.rgba),
        expected.getBytes(order: image.ChannelOrder.rgba),
      );
    });

    test('round ${density.key} preserves the centre and clears corners', () {
      final icon =
          image.decodePng(
            File('$path/ic_launcher_round.png').readAsBytesSync(),
          )!;
      final legacy =
          image.decodePng(File('$path/ic_launcher.png').readAsBytesSync())!;

      expect(icon.width, size);
      expect(icon.height, size);
      expect(icon.getPixel(0, 0).a, 0);
      expect(icon.getPixel(size - 1, size - 1).a, 0);
      expect(
        icon.getPixel(size ~/ 2, size ~/ 2).toList(),
        legacy.getPixel(size ~/ 2, size ~/ 2).toList(),
      );
    });

    test('adaptive ${density.key} fits artwork in the inner viewport', () {
      final file = File('$path/ic_launcher_foreground.png');
      expect(file.existsSync(), isTrue);
      if (!file.existsSync()) return;
      final icon = image.decodePng(file.readAsBytesSync())!;
      final canvasSize = (108 * density.value).round();
      final artworkSize = (72 * density.value).round();
      final inset = (canvasSize - artworkSize) ~/ 2;
      final expected = image.copyResize(
        artwork,
        width: artworkSize,
        height: artworkSize,
        interpolation: image.Interpolation.average,
      );

      expect(icon.width, canvasSize);
      expect(icon.height, canvasSize);
      expect(icon.getPixel(0, 0).a, 0);
      expect(icon.getPixel(inset - 1, canvasSize ~/ 2).a, 0);
      final centre = image.copyCrop(
        icon,
        x: inset,
        y: inset,
        width: artworkSize,
        height: artworkSize,
      );
      expect(
        centre.getBytes(order: image.ChannelOrder.rgba),
        expected.getBytes(order: image.ChannelOrder.rgba),
      );
    });
  }

  test('manifest declares the standard and round launcher icons', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
  });

  test('both adaptive entrypoints reference the generated foreground', () {
    for (final name in ['ic_launcher', 'ic_launcher_round']) {
      final xml =
          File(
            '${resources.path}/mipmap-anydpi-v26/$name.xml',
          ).readAsStringSync();

      expect(xml, contains('<adaptive-icon'));
      expect(xml, contains('@color/ic_launcher_background'));
      expect(xml, contains('@mipmap/ic_launcher_foreground'));
    }
  });

  test('generator check accepts all current assets without writing', () async {
    final before =
        File(
          '${resources.path}/mipmap-xxxhdpi/ic_launcher.png',
        ).statSync().modified;
    final result = await Process.run('dart', [
      'run',
      'tool/generate_android_launcher_icons.dart',
      '--check',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('Verified 21 Android icons.'));
    expect(
      File(
        '${resources.path}/mipmap-xxxhdpi/ic_launcher.png',
      ).statSync().modified,
      before,
    );
  });

  test('generator rejects unknown options without writing', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/generate_android_launcher_icons.dart',
      '--unknown',
    ]);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('[--check | --help]'));
  });

  test(
    'generator recreates icons and detects drift in an isolated tree',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avelune-icons-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final script = File(
        '${directory.path}/tool/generate_android_launcher_icons.dart',
      );
      script.parent.createSync(recursive: true);
      File('tool/generate_android_launcher_icons.dart').copySync(script.path);
      final source = File(
        '${directory.path}/ios/Runner/AppIcon.icon/Assets/Avelune_AppIcon_1024.png',
      );
      source.parent.createSync(recursive: true);
      source.writeAsBytesSync(
        image.encodePng(image.Image(width: 8, height: 8, numChannels: 4)),
      );
      final arguments = [
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        script.path,
      ];

      final generated = await Process.run(
        'dart',
        arguments,
        workingDirectory: Directory.systemTemp.path,
      );
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
      expect(generated.stdout, contains('Generated 21 Android icons.'));
      final output = Directory('${directory.path}/android/app/src/main/res');
      expect(output.listSync(recursive: true).whereType<File>(), hasLength(21));

      final valid = await Process.run('dart', [...arguments, '--check']);
      expect(valid.exitCode, 0, reason: '${valid.stderr}');
      final corrupted = File('${output.path}/mipmap-mdpi/ic_launcher.png');
      corrupted.writeAsBytesSync([0]);
      final stale = await Process.run('dart', [...arguments, '--check']);
      expect(stale.exitCode, 1);
      expect(
        stale.stderr,
        contains('Outdated icon: mipmap-mdpi/ic_launcher.png'),
      );
      expect(corrupted.readAsBytesSync(), [0]);

      source.writeAsBytesSync(
        image.encodePng(image.Image(width: 8, height: 4)),
      );
      final invalid = await Process.run('dart', arguments);
      expect(invalid.exitCode, 1);
      expect(
        invalid.stderr,
        contains('The source must be a square PNG image.'),
      );
      expect(corrupted.readAsBytesSync(), [0]);
    },
  );
}
