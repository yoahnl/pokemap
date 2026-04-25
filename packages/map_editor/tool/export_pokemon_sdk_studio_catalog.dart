import 'dart:io';

import 'package:map_editor/src/application/tools/export_pokemon_sdk_studio_catalog_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await ExportPokemonSdkStudioCatalogCli(
    stdout: stdout,
    stderr: stderr,
  ).run(args);
}
