import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_external_import_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_index_projection.dart';

final class PokemonExternalImport {
  PokemonExternalImport({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    required this.source,
    required this.loadIndex,
  }) : _search = SearchExternalPokemonSpeciesUseCase(
         externalSourceRepository: source,
         queryResolver: const PokemonExternalQueryResolver(),
       );

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final PokemonExternalSourceRepository source;
  final Future<PokemonWorkspaceIndex> Function() loadIndex;
  final SearchExternalPokemonSpeciesUseCase _search;

  Future<PokemonExternalSearch> search(String query) async {
    final result = await _search.execute(query);
    return PokemonExternalSearch(
      suggestions: [
        for (final suggestion in result.suggestions)
          PokemonExternalSuggestion(
            id: suggestion.speciesId,
            name: suggestion.primaryName,
            nationalDex: suggestion.nationalDex,
            generation: suggestion.generation,
          ),
      ],
      message: result.message,
    );
  }

  Future<PokemonExternalImportPreview> preview(String selectedId) async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (!baseline.manifest.pokemon.enabled) {
      throw const PokemonWorkspaceFailure(
        'La configuration Pokémon est désactivée.',
      );
    }
    final pokeApiSpecies = await source.fetchPokeApiPokemonSpeciesPayload(
      selectedId,
    );
    final canonicalId = (pokeApiSpecies['name'] as String?)?.trim();
    if (canonicalId == null || canonicalId.isEmpty) {
      throw const PokemonWorkspaceFailure(
        'La source ne fournit pas l’identité canonique de cette espèce.',
      );
    }
    final showdown = await source.fetchShowdownSpeciesPayload(canonicalId);
    final warnings = <String>[];
    final pokemon = await _optional(
      () => source.fetchPokeApiPokemonPayload(canonicalId),
      'Apprentissages et médias externes indisponibles',
      warnings,
    );
    final evolutionPayload = await _optional(
      () => source.fetchPokeApiEvolutionChainPayload(canonicalId),
      'Chaîne d’évolution externe indisponible',
      warnings,
    );
    final species = const PokeApiPokemonSpeciesEnricher().enrich(
      species: const ShowdownPokemonSpeciesConverter().convert(
        showdown,
        fallbackGeneration: switch ((pokeApiSpecies['generation']
            as Map?)?['name']) {
          'generation-i' => 1,
          'generation-ii' => 2,
          'generation-iii' => 3,
          'generation-iv' => 4,
          'generation-v' => 5,
          'generation-vi' => 6,
          'generation-vii' => 7,
          'generation-viii' => 8,
          'generation-ix' => 9,
          _ => null,
        },
      ),
      pokemonSpeciesPayload: pokeApiSpecies,
      pokemonPayload: pokemon,
    );
    PokemonLearnsetFile? learnset;
    PokemonEvolutionFile? evolution;
    if (pokemon != null) {
      try {
        learnset = const PokeApiPokemonLearnsetConverter().convert(
          speciesId: species.id,
          payload: pokemon,
        );
      } on Object catch (error) {
        warnings.add('Apprentissages non convertis : $error');
      }
    }
    if (evolutionPayload != null) {
      try {
        evolution = const PokeApiPokemonEvolutionConverter().convert(
          speciesId: species.id,
          payload: evolutionPayload,
        );
      } on Object catch (error) {
        warnings.add('Évolution non convertie : $error');
      }
    }
    warnings.add(
      'Les images et cris externes ne sont pas téléchargés par cet import.',
    );
    final config = baseline.manifest.pokemon;
    final existing = (await loadIndex()).entries
        .where((entry) => entry.id == species.id)
        .firstOrNull;
    final speciesPath =
        existing?.relativePath ?? '${config.speciesDir}/${species.id}.json';
    final speciesBefore = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: speciesPath,
    );
    final speciesDocument = species.toJson().cast<String, dynamic>();
    if (speciesBefore != null) {
      final saved = PokemonSpeciesFile.fromJson(
        (jsonDecode(utf8.decode(speciesBefore)) as Map).cast<String, dynamic>(),
      );
      if (saved.id != species.id) {
        throw PokemonWorkspaceFailure(
          'Le chemin $speciesPath appartient déjà à ${saved.id}.',
        );
      }
      speciesDocument['refs'] = saved.refs.toJson();
    }
    final refs = Map<String, dynamic>.from(speciesDocument['refs'] as Map);
    if (learnset != null && '${refs['learnset'] ?? ''}'.trim().isEmpty) {
      refs['learnset'] = species.id;
    }
    if (evolution != null &&
        (evolution.preEvolution != null || evolution.evolutions.isNotEmpty) &&
        '${refs['evolution'] ?? ''}'.trim().isEmpty) {
      refs['evolution'] = species.id;
    }
    speciesDocument['refs'] = refs;
    final documents = <PokemonExternalDocument>[];
    Future<void> add(
      PokemonDocumentFamily family,
      String path,
      Map<String, dynamic> json,
    ) async {
      PokemonJsonDocument.fromJson(_kind(family), json);
      final beforeBytes = await readOptionalPokemonResource(
        reader: reader,
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (beforeBytes != null && family != PokemonDocumentFamily.species) {
        final existing = PokemonJsonDocument.fromJson(
          _kind(family),
          (jsonDecode(utf8.decode(beforeBytes)) as Map).cast<String, dynamic>(),
        ).toJson();
        if (existing['speciesId'] != json['speciesId']) {
          throw PokemonWorkspaceFailure(
            'Le document $path appartient déjà à ${existing['speciesId']}.',
          );
        }
      }
      documents.add(
        PokemonExternalDocument(
          family: family,
          relativePath: path,
          beforeBytes: beforeBytes,
          document: json,
        ),
      );
    }

    await add(PokemonDocumentFamily.species, speciesPath, speciesDocument);
    if (learnset != null) {
      await add(
        PokemonDocumentFamily.learnset,
        '${config.learnsetsDir}/${refs['learnset']}.json',
        learnset.toJson().cast<String, dynamic>(),
      );
    }
    if (evolution != null &&
        (evolution.preEvolution != null || evolution.evolutions.isNotEmpty)) {
      await add(
        PokemonDocumentFamily.evolution,
        '${config.evolutionsDir}/${refs['evolution']}.json',
        evolution.toJson().cast<String, dynamic>(),
      );
    }
    return PokemonExternalImportPreview(
      speciesId: species.id,
      name: species.names['fr'] ?? species.names['en'] ?? species.id,
      projectRevision: baseline.revision,
      documents: List.unmodifiable(documents),
      warnings: List.unmodifiable(warnings),
    );
  }

  Future<PokemonExternalImportResult> apply(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy conflictPolicy,
  ) async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (baseline.revision != preview.projectRevision) {
      throw const PokemonWorkspaceFailure(
        'Le projet a changé depuis l’aperçu. Reprévisualisez.',
      );
    }
    for (final item in preview.documents) {
      final current = await readOptionalPokemonResource(
        reader: reader,
        projectRoot: session.directoryPath,
        relativePath: item.relativePath,
      );
      if (!_same(current, item.beforeBytes)) {
        throw PokemonWorkspaceFailure(
          '${item.relativePath} a changé depuis l’aperçu. Reprévisualisez.',
        );
      }
    }
    if (conflictPolicy == PokemonExternalConflictPolicy.failOnConflict &&
        preview.hasConflicts) {
      throw const PokemonWorkspaceFailure(
        'Des documents existent déjà. Choisissez Ignorer ou Remplacer.',
      );
    }
    final selected = [
      for (final item in preview.documents)
        if (!item.conflict ||
            conflictPolicy != PokemonExternalConflictPolicy.skipExisting)
          item,
    ];
    if (selected.isNotEmpty) {
      await PokemonDocumentTransaction(
        session: session,
        mapAdapter: mapAdapter,
        reader: reader,
      ).apply([
        for (final item in selected)
          PokemonDocumentWriteRequest(
            family: item.family,
            relativePath: item.relativePath,
            beforeBytes: item.beforeBytes,
            document: item.document,
          ),
      ]);
    }
    return PokemonExternalImportResult(
      speciesId: preview.speciesId,
      created: selected.where((item) => !item.conflict).length,
      overwritten: selected.where((item) => item.conflict).length,
      skipped: preview.documents.length - selected.length,
      warnings: preview.warnings,
    );
  }

  Future<Map<String, dynamic>?> _optional(
    Future<Map<String, dynamic>> Function() load,
    String label,
    List<String> warnings,
  ) async {
    try {
      return await load();
    } on Object catch (error) {
      warnings.add('$label : $error');
      return null;
    }
  }

  PokemonDocumentKind _kind(PokemonDocumentFamily family) => switch (family) {
    PokemonDocumentFamily.species => PokemonDocumentKind.species,
    PokemonDocumentFamily.learnset => PokemonDocumentKind.learnset,
    PokemonDocumentFamily.evolution => PokemonDocumentKind.evolution,
    PokemonDocumentFamily.media => PokemonDocumentKind.media,
  };

  bool _same(List<int>? a, List<int>? b) {
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
