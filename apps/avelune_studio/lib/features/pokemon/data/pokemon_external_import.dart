import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_external_import_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_index_projection.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_external_import_helpers.dart';
import 'pokemon_gen5_battle_import.dart';

final class PokemonExternalImport {
  PokemonExternalImport({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    required this.source,
    required this.loadIndex,
    this.gen5Source,
    this.gifSource,
    this.isCurrent,
  }) : _search = SearchExternalPokemonSpeciesUseCase(
         externalSourceRepository: source,
         queryResolver: const PokemonExternalQueryResolver(),
       );

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final PokemonExternalSourceRepository source;
  final AveluneGen5BattleSource? gen5Source;
  final AveluneBattleGifSource? gifSource;
  final bool Function()? isCurrent;
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
    final pokemon = await optionalExternalPayload(
      () => source.fetchPokeApiPokemonPayload(canonicalId),
      'Apprentissages et médias externes indisponibles',
      warnings,
    );
    final evolutionPayload = await optionalExternalPayload(
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
    Gen5BattleSourceBundle? gen5Bundle;
    final gen5 = gen5Source;
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      warnings.add(
        'L’animation Noir/Blanc 2 nécessite un catalogue de travail.',
      );
    } else if (gen5 == null ||
        species.nationalDex < 1 ||
        species.nationalDex > 649 ||
        !species.forms.isBaseForm) {
      warnings.add(
        'L’animation Noir/Blanc 2 n’est pas disponible pour cette espèce.',
      );
    } else {
      try {
        final snapshot = await gen5.fetch(
          species: canonicalId,
          nationalDex: species.nationalDex,
        );
        if (snapshot == null) {
          warnings.add('L’animation Noir/Blanc 2 est absente de la source.');
        } else {
          gen5Bundle = gen5BattleSourceBundleFromSnapshot(snapshot);
        }
      } on Object {
        warnings.add('L’animation Noir/Blanc 2 est indisponible ou invalide.');
      }
    }
    PokemonBattleGifSelection? gifSelection;
    if (species.nationalDex >= 1 &&
        species.nationalDex <= 649 &&
        species.forms.isBaseForm &&
        gifSource == null) {
      warnings.add('Les GIF de secours ne sont pas disponibles pour ce projet.');
    } else if (gifSource != null &&
        species.nationalDex >= 1 &&
        species.nationalDex <= 649 &&
        species.forms.isBaseForm) {
      try {
        gifSelection = await gifSource!.fetch(
          speciesId: canonicalId,
          nationalDex: species.nationalDex,
        );
        if (gifSelection.missing.isNotEmpty) {
          warnings.add('Certains GIF de secours ne sont pas disponibles.');
        }
      } on Object {
        warnings.add('Les GIF de secours sont indisponibles ou invalides.');
      }
    }
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
      'Les cris ne sont pas téléchargés par cet import.',
    );
    final config = baseline.manifest.pokemon;
    final indexed = (await loadIndex()).entries;
    final existing = indexed
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
      PokemonJsonDocument.fromJson(externalDocumentKind(family), json);
      final beforeBytes = await readOptionalPokemonResource(
        reader: reader,
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (beforeBytes != null && family != PokemonDocumentFamily.species) {
        final existing = PokemonJsonDocument.fromJson(
          externalDocumentKind(family),
          (jsonDecode(utf8.decode(beforeBytes)) as Map).cast<String, dynamic>(),
        ).toJson();
        final reference = path
            .split('/')
            .last
            .replaceAll(RegExp(r'\.json$'), '');
        final ownerIds = {
          ...pokemonReferenceOwners(indexed, family, reference),
          if (family == PokemonDocumentFamily.learnset &&
                  refs['learnset'] == reference ||
              family == PokemonDocumentFamily.evolution &&
                  refs['evolution'] == reference)
            species.id,
        };
        if (!pokemonCompanionBelongsTo(
          family: family,
          ownerSpeciesId: species.id,
          reference: reference,
          declaredSpeciesId: existing['speciesId'] as String? ?? '',
          knownSpeciesIds: {for (final entry in indexed) entry.id, species.id},
          referencingSpeciesIds: ownerIds,
        )) {
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
      inventorySignature: pokemonInventorySignature(indexed),
      documents: List.unmodifiable(documents),
      warnings: List.unmodifiable(warnings),
      gen5Bundle: gen5Bundle,
      gifSelection: gifSelection,
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
    if (pokemonInventorySignature((await loadIndex()).entries) !=
        preview.inventorySignature) {
      throw const PokemonWorkspaceFailure(
        'Les références Pokémon ont changé depuis l’aperçu. Reprévisualisez.',
      );
    }
    for (final item in preview.documents) {
      final current = await readOptionalPokemonResource(
        reader: reader,
        projectRoot: session.directoryPath,
        relativePath: item.relativePath,
      );
      if (!samePokemonBytes(current, item.beforeBytes)) {
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
    final plan = preview.plan(conflictPolicy);
    final selected = plan.selected;
    if (selected.isNotEmpty) {
      await PokemonDocumentTransaction(
        session: session,
        mapAdapter: mapAdapter,
        reader: reader,
      ).apply(
        externalWriteRequests(selected),
        expectedDependencies: retainedExternalDependencies(
          preview,
          plan,
          conflictPolicy,
        ),
      );
    }
    final warnings = [...preview.warnings];
    var gen5Imported = false;
    var gifImported = false;
    var requiresReopen = false;
    final bundle = preview.gen5Bundle;
    final gen5 = gen5Source;
    final importsSpecies = selected.any(
      (item) => item.family == PokemonDocumentFamily.species,
    );
    if (bundle != null && !importsSpecies) {
      warnings.add(
        'Aucune animation ajoutée : la fiche Pokémon existante a été conservée.',
      );
    } else if (bundle != null && gen5 != null) {
      try {
        final speciesPath = preview.documents
            .firstWhere((item) => item.family == PokemonDocumentFamily.species)
            .relativePath;
        final result =
            await PokemonGen5BattleImport(
              session: session,
              mapAdapter: mapAdapter,
              reader: reader,
              source: gen5,
            ).apply(
              bundle: bundle,
              projectSpeciesId: preview.speciesId,
              speciesPath: speciesPath,
              isCurrent: isCurrent ?? () => true,
            );
        gen5Imported = result.status == AveluneGen5ImportStatus.imported;
        warnings.add(
          gen5Imported
              ? 'Animation Noir/Blanc 2 importée.'
              : 'Animation Noir/Blanc 2 déjà présente.',
        );
        if (result.refreshRequired) {
          requiresReopen = true;
          warnings.add('Rouvrez le projet pour vérifier l’animation importée.');
        }
      } on Object {
        requiresReopen = true;
        warnings.add(
          'L’état de l’import de l’animation Noir/Blanc 2 est incertain. '
          'Rouvrez le projet et vérifiez les données existantes avant de réessayer.',
        );
      }
    }
    final gifs = preview.gifSelection;
    if (gifs != null &&
        gifs.media.isNotEmpty &&
        importsSpecies &&
        !requiresReopen) {
      try {
        final speciesPath = preview.documents
            .firstWhere((item) => item.family == PokemonDocumentFamily.species)
            .relativePath;
        gifImported = await _importGifs(gifs, preview.speciesId, speciesPath);
        if (!gifImported) {
          warnings.add('La fiche média existante a été conservée.');
        }
      } on Object {
        requiresReopen = true;
        warnings.add(
          'L’import des GIF de secours est incertain. '
          'Rouvrez le projet avant de réessayer.',
        );
      }
    }
    return PokemonExternalImportResult(
      speciesId: preview.speciesId,
      created: plan.created,
      overwritten: plan.overwritten,
      skipped: plan.kept,
      excluded: plan.excluded.length,
      warnings: List.unmodifiable(warnings),
      gen5Imported: gen5Imported,
      gifImported: gifImported,
      requiresReopen: requiresReopen,
    );
  }

  Future<bool> _importGifs(
    PokemonBattleGifSelection selection,
    String speciesId,
    String speciesPath,
  ) async {
    if (isCurrent?.call() == false) throw StateError('La sélection a changé.');
    final speciesBytes = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: speciesPath,
    );
    if (speciesBytes == null) throw StateError('La fiche Pokémon est absente.');
    final species = PokemonSpeciesFile.fromJson(
      (jsonDecode(utf8.decode(speciesBytes)) as Map).cast<String, dynamic>(),
    );
    if (species.id != speciesId ||
        !species.forms.isBaseForm ||
        species.refs.media != speciesId) {
      return false;
    }
    final baseline = await mapAdapter.resourceBaseline(session);
    final mediaPath = pokemonDocumentPath(
      baseline.manifest.pokemon.mediaDir,
      speciesId,
    );
    final before = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: mediaPath,
    );
    final Map<String, dynamic> document;
    if (before == null) {
      document = {
        'schemaVersion': currentPokemonMediaSchemaVersion,
        'speciesId': speciesId,
        'defaultFormId': 'base',
        'variants': {'base': <String, dynamic>{}},
      };
    } else {
      final decoded = jsonDecode(utf8.decode(before));
      if (decoded is! Map ||
          decoded['schemaVersion'] != currentPokemonMediaSchemaVersion ||
          decoded['speciesId'] != speciesId ||
          decoded['defaultFormId'] != 'base' ||
          decoded['variants'] is! Map ||
          (decoded['variants'] as Map)['base'] is! Map) {
        return false;
      }
      document = decoded.cast<String, dynamic>();
    }
    final variants = (document['variants'] as Map).cast<String, dynamic>();
    final variant = (variants['base'] as Map).cast<String, dynamic>();
    final artifacts = <String, List<int>>{};
    for (final entry in selection.media.entries) {
      final role = entry.key.name;
      final existing = variant[role];
      if (existing != null &&
          (existing is! String || existing.trim().isNotEmpty)) {
        continue;
      }
      variant[role] = 'assets/pokemon/battle-gifs/${entry.value.sha256}.gif';
      artifacts[role] = entry.value.bytes;
    }
    if (artifacts.isEmpty) return false;
    await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: reader,
    ).applyBattleGifs(
      PokemonDocumentWriteRequest(
        family: PokemonDocumentFamily.media,
        relativePath: mediaPath,
        beforeBytes: before,
        document: document,
      ),
      species: (
        resourceIdentity: pokemonSpeciesResourceIdentity(speciesId),
        relativePath: speciesPath,
        beforeBytes: speciesBytes,
      ),
      gifs: artifacts,
    );
    return true;
  }
}
