import 'dart:io';

import 'package:map_editor/src/features/game_export/application/game_package_export_profile.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_service.dart';
import 'package:map_editor/src/features/game_export/infrastructure/game_package_export_profile_store.dart';
import 'package:map_editor/src/features/game_export/infrastructure/hub_install_request_publisher.dart';

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  if (options == null) {
    _usage();
    exitCode = 64;
    return;
  }
  if (options.help) {
    _usage();
    return;
  }

  try {
    final projectRoot = Directory(options.projectRoot!);
    final profile = options.profilePath == null
        ? await GamePackageExportProfileStore(
            projectRoot: projectRoot,
          ).load()
        : GamePackageExportProfile.decodeUtf8(
            await File(options.profilePath!).readAsBytes(),
          );
    if (profile == null) {
      stderr.writeln(
        'Export refusé [missingExportProfile] : configurez d’abord '
        'les métadonnées de publication dans l’éditeur.',
      );
      exitCode = 2;
      return;
    }

    final artifact = await const GamePackageExportService().exportToFile(
      projectRoot: projectRoot,
      profile: profile,
      outputFile: File(options.outputPath!),
    );
    if (options.hubInboxPath != null) {
      await HubInstallRequestPublisher(
        inbox: Directory(options.hubInboxPath!),
      ).publish(artifact.packageBytes);
    }
    stdout.writeln(
      'Package certifié : ${artifact.manifest.gameId} '
      '${artifact.manifest.gameVersion} '
      '(${artifact.manifest.content.fileCount} fichiers).',
    );
  } on GamePackageExportException catch (error) {
    stderr.writeln('Export refusé [${error.code}] : ${error.message}');
    exitCode = 2;
  } on Object {
    stderr.writeln(
      'Export refusé [unexpectedExportFailure] : '
      'le package ne peut pas être produit.',
    );
    exitCode = 1;
  }
}

_ExportOptions? _parseArguments(List<String> arguments) {
  String? projectRoot;
  String? profilePath;
  String? outputPath;
  String? hubInboxPath;
  var help = false;

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--help' || argument == '-h') {
      help = true;
      continue;
    }
    if (!<String>{
      '--project',
      '--profile',
      '--output',
      '--hub-inbox',
    }.contains(argument)) {
      return null;
    }
    if (index + 1 >= arguments.length) return null;
    final value = arguments[++index].trim();
    if (value.isEmpty) return null;
    switch (argument) {
      case '--project':
        projectRoot = value;
        break;
      case '--profile':
        profilePath = value;
        break;
      case '--output':
        outputPath = value;
        break;
      case '--hub-inbox':
        hubInboxPath = value;
        break;
    }
  }
  if (help) return const _ExportOptions(help: true);
  if (projectRoot == null || outputPath == null) return null;
  return _ExportOptions(
    projectRoot: projectRoot,
    profilePath: profilePath,
    outputPath: outputPath,
    hubInboxPath: hubInboxPath,
  );
}

void _usage() {
  stdout.writeln(
    'Usage: dart run tool/export_pokemap_game.dart '
    '--project <dossier> --output <jeu.pokemapgame> '
    '[--profile <profil.json>] [--hub-inbox <dossier>]',
  );
}

final class _ExportOptions {
  const _ExportOptions({
    this.help = false,
    this.projectRoot,
    this.profilePath,
    this.outputPath,
    this.hubInboxPath,
  });

  final bool help;
  final String? projectRoot;
  final String? profilePath;
  final String? outputPath;
  final String? hubInboxPath;
}
