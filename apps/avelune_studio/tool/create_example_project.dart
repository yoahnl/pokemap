import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  if (arguments.length > 1) {
    stderr.writeln(
      'Usage: dart run tool/create_example_project.dart [dossier]',
    );
    exitCode = 64;
    return;
  }
  final Directory directory;
  if (arguments.isEmpty) {
    directory = await Directory.systemTemp.createTemp(
      'avelune_studio_example_',
    );
  } else {
    final target = p.absolute(arguments.single);
    if (await FileSystemEntity.type(target, followLinks: false) !=
        FileSystemEntityType.notFound) {
      stderr.writeln(
        'Le dossier de sortie existe déjà : aucun fichier modifié.',
      );
      exitCode = 73;
      return;
    }
    directory = await Directory(target).create();
  }
  const manifest = ProjectManifest(
    name: 'Exemple Avelune Studio',
    maps: [],
    tilesets: [],
  );
  await File(p.join(directory.path, 'project.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  stdout.writeln(await directory.resolveSymbolicLinks());
}
