import 'dart:io';

import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';
import 'package:path/path.dart' as p;

const _allowedDestinations = <String>{
  'selbrume/project.json',
  'selbrume/maps/map_port_brisants.json',
  'selbrume/maps/map_marais_salants.json',
  'selbrume/dialogues/lysa_port.yarn',
};

Future<void> main() async {
  final repositoryRoot = _findRepositoryRoot();
  final manifestPath = p.join(
    repositoryRoot.path,
    'examples',
    'playable_runtime_host',
    'event_builder_v2_selbrume_slice',
    'promotion_manifest.json',
  );
  final result = await JournaledFilePromotionRepository(
    repositoryRoot: repositoryRoot.path,
    manifestPath: manifestPath,
    allowedDestinations: _allowedDestinations,
  ).promote();
  stdout.writeln('${result.status.name}: ${result.code}');
  stdout.writeln(result.message);
  if (!result.succeeded) {
    stderr.writeln('Journal conservé: ${result.journalPath}');
    exitCode = 1;
  }
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
