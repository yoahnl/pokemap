import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  try {
    final options = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      if (!['--project', '--source'].contains(arguments[index]) ||
          index + 1 == arguments.length ||
          options.containsKey(arguments[index])) {
        throw const FormatException(
            'Usage: --project <absolute project> [--source <pack directory>]');
      }
      options[arguments[index]] = arguments[index + 1];
    }
    final project = options['--project'];
    if (project == null) throw const FormatException('--project is required.');
    final source = options['--source'] ??
        p.normalize(p.join(
            p.dirname(Platform.script.toFilePath()),
            '..',
            '..',
            '..',
            'apps',
            'avelune_studio',
            'assets',
            'pokemon',
            'capture_sprites'));
    final result = await provisionProjectCaptureSprites(
      projectPath: project,
      loadPack: () async {
        if (await FileSystemEntity.type(source, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw const FormatException(
              'Expected a source directory without symlinks.');
        }
        for (final name in ['manifest.json', 'sprites.zip']) {
          if (await FileSystemEntity.type(p.join(source, name),
                  followLinks: false) !=
              FileSystemEntityType.file) {
            throw const FormatException(
                'Expected source files without symlinks.');
          }
        }
        return ProjectCaptureSpritePack(
          manifestBytes:
              await File(p.join(source, 'manifest.json')).readAsBytes(),
          archiveBytes: await File(p.join(source, 'sprites.zip')).readAsBytes(),
        );
      },
    );
    stdout.writeln(jsonEncode(result));
  } on ProjectCaptureSpriteProvisioningPartialFailure catch (error) {
    stderr.writeln(jsonEncode(error.toJson()));
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Capture sprite provisioning failed: $error');
    exitCode = 1;
  }
}
