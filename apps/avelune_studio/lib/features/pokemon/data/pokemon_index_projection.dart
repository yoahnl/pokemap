import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart' show WorkspaceAccessException;
import 'package:map_core/map_core.dart';

import '../domain/pokemon_workspace_models.dart';
import 'pokemon_moves_projection.dart';

String projectPokemonName(Map<String, dynamic> names, String fallback) {
  for (final key in ['fr', 'en']) {
    final value = names[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return fallback;
}

Future<List<PokemonSpeciesSummary>> loadPokemonSpeciesIndex({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
}) async {
  if (reader is! ProjectDirectoryReader) {
    throw const PokemonWorkspaceFailure('Inventaire des espèces indisponible.');
  }
  late final List<String> files;
  try {
    files = await (reader as ProjectDirectoryReader).listFiles(
      projectRoot: projectRoot,
      relativeDirectory: config.speciesDir,
    );
  } on WorkspaceAccessException catch (error) {
    if (error.code == 'workspace.directory_missing') return const [];
    throw PokemonWorkspaceFailure('Inventaire inaccessible : $error');
  }
  final entries = <PokemonSpeciesSummary>[];
  final identities = <String>{};
  for (final path in files.where((path) => path.endsWith('.json'))) {
    final bytes = await reader.readBytes(
      projectRoot: projectRoot,
      relativePath: path,
    );
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw PokemonWorkspaceFailure('Fiche Pokémon illisible : $path');
    }
    final index = PokemonSpeciesIndexEntry.fromJson(json, relativePath: path);
    if (!identities.add(index.id)) {
      throw PokemonWorkspaceFailure(
        'Identifiant d’espèce répété : ${index.id}.',
      );
    }
    final classification =
        (json['classification'] as Map?)?.cast<String, dynamic>() ?? {};
    final names = (json['names'] as Map?)?.cast<String, dynamic>() ?? {};
    entries.add(
      PokemonSpeciesSummary(
        id: index.id,
        name: projectPokemonName(names, index.primaryName),
        nationalDex: index.nationalDex,
        generation: (json['genIntroduced'] as num?)?.toInt() ?? 0,
        types: index.types,
        formIds: index.formIds,
        baseFormId: ((json['forms'] as Map?)?['baseFormId'] as String?) ?? '',
        isBaseForm: ((json['forms'] as Map?)?['isBaseForm'] as bool?) ?? true,
        mediaRelativePath: switch (((json['refs'] as Map?)?['media'] as String?)
                ?.trim() ??
            '') {
          '' => '',
          final reference => '${config.mediaDir}/$reference.json',
        },
        learnsetReference:
            ((json['refs'] as Map?)?['learnset'] as String?) ?? '',
        evolutionReference:
            ((json['refs'] as Map?)?['evolution'] as String?) ?? '',
        mediaReference: ((json['refs'] as Map?)?['media'] as String?) ?? '',
        enabled: classification['isEnabledInProject'] != false,
        relativePath: path,
      ),
    );
  }
  entries.sort((a, b) {
    final number = a.nationalDex.compareTo(b.nationalDex);
    return number == 0 ? a.id.compareTo(b.id) : number;
  });
  return List.unmodifiable(entries);
}

Future<PokemonMovesCatalogView> loadPokemonMoves({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
  required String locale,
}) async {
  final path = config.catalogFiles['moves'];
  if (path == null || path.isEmpty) {
    return const PokemonMovesCatalogView(
      entries: [],
      relativePath: '',
      problem: 'Aucun catalogue d’attaques configuré.',
    );
  }
  try {
    final bytes = await reader.readBytes(
      projectRoot: projectRoot,
      relativePath: path,
    );
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Catalogue non objet.');
    }
    return projectPokemonMoves(PokemonCatalogFile.fromJson(json), path, locale);
  } on Object catch (error) {
    return PokemonMovesCatalogView(
      entries: const [],
      relativePath: path,
      problem: 'Catalogue absent ou illisible : $error',
    );
  }
}

Future<List<int>?> readOptionalPokemonResource({
  required ProjectFileReader reader,
  required String projectRoot,
  required String relativePath,
}) async {
  final probe = reader;
  if (probe is ProjectResourceProbeReader) {
    final result = await (probe as ProjectResourceProbeReader).probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (result.status == ProjectResourceProbeStatus.missing) return null;
    if (result.status != ProjectResourceProbeStatus.exists) {
      throw PokemonWorkspaceFailure('Ressource inaccessible : $relativePath');
    }
  }
  return reader.readBytes(projectRoot: projectRoot, relativePath: relativePath);
}
