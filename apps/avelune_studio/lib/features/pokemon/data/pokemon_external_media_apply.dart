import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_external_import_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_gen5_battle_import.dart';
import 'pokemon_external_gif_import.dart';
import 'pokemon_external_media_import.dart';

final class PokemonExternalMediaApply {
  const PokemonExternalMediaApply({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    this.gen5Source,
    this.isCurrent,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AveluneGen5BattleSource? gen5Source;
  final bool Function()? isCurrent;

  PokemonExternalMediaImport get _media => PokemonExternalMediaImport(
    session: session,
    mapAdapter: mapAdapter,
    reader: reader,
    isCurrent: isCurrent,
  );

  Future<PokemonExternalImportResult> apply({
    required PokemonExternalImportPreview preview,
    required PokemonExternalImportPlan plan,
    required List<PokemonSpeciesSummary> indexed,
  }) async {
    final selected = plan.selected;
    final warnings = [...preview.warnings];
    var gen5Imported = false;
    var gifImported = false;
    var cryImported = false;
    var pngImported = false;
    var requiresReopen = false;
    final bundle = preview.gen5Bundle;
    final gen5 = gen5Source;
    final importsSpecies = selected.any(
      (item) => item.family == PokemonDocumentFamily.species,
    );
    final speciesDocument = preview.documents.firstWhere(
      (item) => item.family == PokemonDocumentFamily.species,
    );
    final retainedSpecies =
        !importsSpecies && speciesDocument.beforeBytes != null
        ? PokemonSpeciesFile.fromJson(
            (jsonDecode(utf8.decode(speciesDocument.beforeBytes!)) as Map)
                .cast<String, dynamic>(),
          )
        : null;
    final canImportGen5 =
        importsSpecies ||
        (retainedSpecies != null &&
            retainedSpecies.id == preview.speciesId &&
            retainedSpecies.nationalDex == bundle?.nationalDex &&
            retainedSpecies.forms.isBaseForm);
    if (bundle != null && !canImportGen5) {
      warnings.add(
        'Aucune animation ajoutée : la forme ou l’identité de la fiche '
        'Pokémon existante ne correspond pas.',
      );
    } else if (bundle != null && gen5 != null) {
      try {
        final result =
            await PokemonGen5BattleImport(
              session: session,
              mapAdapter: mapAdapter,
              reader: reader,
              source: gen5,
            ).apply(
              bundle: bundle,
              projectSpeciesId: preview.speciesId,
              speciesPath: speciesDocument.relativePath,
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
    final sharedGifMedia = pokemonReferenceOwners(
      indexed,
      PokemonDocumentFamily.media,
      preview.speciesId,
    ).any((owner) => owner != preview.speciesId);
    if (gifs != null && gifs.media.isNotEmpty && !requiresReopen) {
      try {
        final speciesDocument = preview.documents.firstWhere(
          (item) => item.family == PokemonDocumentFamily.species,
        );
        if (!sharedGifMedia) {
          gifImported =
              await PokemonExternalGifImport(
                session: session,
                mapAdapter: mapAdapter,
                reader: reader,
                isCurrent: isCurrent,
              ).importGifs(
                gifs,
                preview.speciesId,
                speciesDocument.relativePath,
                speciesDocument.document['nationalDex'] as int,
              );
        }
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
    final sharedCryMedia = pokemonReferenceOwners(
      indexed,
      PokemonDocumentFamily.media,
      preview.speciesId,
    ).any((owner) => owner != preview.speciesId);
    if (preview.cry != null && sharedCryMedia) {
      warnings.add('La fiche média partagée a été conservée.');
    } else if (preview.cry != null && !requiresReopen) {
      try {
        final speciesPath = preview.documents
            .firstWhere((item) => item.family == PokemonDocumentFamily.species)
            .relativePath;
        cryImported = await _media.importCry(
          preview.cry!,
          preview.speciesId,
          speciesPath,
        );
        warnings.add(
          cryImported
              ? 'Cri importé.'
              : 'Le cri ou la fiche média existante a été conservé(e).',
        );
      } on Object {
        requiresReopen = true;
        warnings.add(
          'L’import du cri est incertain. Rouvrez le projet avant de réessayer.',
        );
      }
    }
    final pngs = preview.pngSelection;
    if (pngs != null &&
        pngs.media.isNotEmpty &&
        !sharedGifMedia &&
        !requiresReopen) {
      try {
        pngImported = await _media.importPngs(
          pngs,
          preview.speciesId,
          speciesDocument.relativePath,
          speciesDocument.document['nationalDex'] as int,
        );
        warnings.add(
          pngImported
              ? 'Images PNG disponibles importées.'
              : 'Les images existantes ou la fiche média ont été conservées.',
        );
      } on Object {
        requiresReopen = true;
        warnings.add(
          'L’import des images PNG est incertain. Rouvrez le projet avant de réessayer.',
        );
      }
    } else if (pngs != null && pngs.media.isNotEmpty && sharedGifMedia) {
      warnings.add('La fiche média partagée a été conservée.');
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
      cryImported: cryImported,
      pngImported: pngImported,
      requiresReopen: requiresReopen,
    );
  }
}
