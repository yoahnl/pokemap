import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_import_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_import_preview_match.dart';

final class PokemonJsonImport {
  const PokemonJsonImport({
    required this.session,
    required this.mapAdapter,
    required this.reader,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;

  Future<PokemonLocalImportPreview> preview(String absolutePath) async {
    if (!p.isAbsolute(absolutePath) ||
        p.extension(absolutePath).toLowerCase() != '.json') {
      throw const PokemonWorkspaceFailure(
        'Choisissez un fichier JSON d’espèce.',
      );
    }
    final manifest = (await mapAdapter.resourceBaseline(session)).manifest;
    if (!manifest.pokemon.enabled) {
      throw const PokemonWorkspaceFailure(
        'La configuration Pokémon est désactivée.',
      );
    }
    final source = await File(absolutePath).readAsBytes();
    final species = _validated(PokemonDocumentFamily.species, source);
    final identity = species['id'] as String;
    final references = (species['refs'] as Map).cast<String, dynamic>();
    final forms = (species['forms'] as Map?)?.cast<String, dynamic>() ?? {};
    final baseFormId = forms['baseFormId'] as String? ?? '';
    final isBaseForm = forms['isBaseForm'] as bool? ?? true;
    final directory = p.dirname(absolutePath);
    final siblingDirectory = p.basename(directory).toLowerCase() == 'species'
        ? p.dirname(directory)
        : null;
    final configured = manifest.pokemon;
    final presentEntries = await _speciesFiles(configured);
    final knownSpeciesIds = {
      identity,
      for (final entry in presentEntries) entry.$1,
    };
    final sameIdentity = presentEntries
        .where((entry) => entry.$1 == identity)
        .toList();
    if (sameIdentity.length > 1) {
      throw PokemonWorkspaceFailure(
        'Plusieurs fiches utilisent déjà $identity.',
      );
    }
    final targetSpecies = sameIdentity.isEmpty
        ? p.posix.join(configured.speciesDir, p.basename(absolutePath))
        : sameIdentity.single.$2;
    if (presentEntries.any(
      (entry) => entry.$2 == targetSpecies && entry.$1 != identity,
    )) {
      throw PokemonWorkspaceFailure(
        'Le chemin $targetSpecies appartient déjà à une autre espèce.',
      );
    }
    final items = <PokemonLocalImportItem>[
      await _item(
        PokemonDocumentFamily.species,
        absolutePath,
        targetSpecies,
        source,
        species,
      ),
    ];
    for (final (family, folder, targetDirectory, referenceKey) in [
      (
        PokemonDocumentFamily.learnset,
        'learnsets',
        configured.learnsetsDir,
        'learnset',
      ),
      (
        PokemonDocumentFamily.evolution,
        'evolutions',
        configured.evolutionsDir,
        'evolution',
      ),
      (PokemonDocumentFamily.media, 'media', configured.mediaDir, 'media'),
    ]) {
      final reference = (references[referenceKey] as String?)?.trim() ?? '';
      if (reference.isEmpty || siblingDirectory == null) continue;
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(reference)) {
        throw PokemonWorkspaceFailure('Référence $referenceKey invalide.');
      }
      final companion = p.join(siblingDirectory, folder, '$reference.json');
      final file = File(companion);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final document = _validated(family, bytes);
      if (!pokemonCompanionBelongsTo(
        family: family,
        ownerSpeciesId: identity,
        reference: reference,
        declaredSpeciesId: document['speciesId'] as String? ?? '',
        knownSpeciesIds: knownSpeciesIds,
        ownerBaseFormId: baseFormId,
        ownerIsBaseForm: isBaseForm,
      )) {
        throw PokemonWorkspaceFailure(
          'Le compagnon $reference ne concerne pas $identity.',
        );
      }
      items.add(
        await _item(
          family,
          companion,
          p.posix.join(targetDirectory, '$reference.json'),
          bytes,
          document,
          ownerSpeciesId: identity,
          reference: reference,
          knownSpeciesIds: knownSpeciesIds,
          ownerBaseFormId: baseFormId,
          ownerIsBaseForm: isBaseForm,
        ),
      );
    }
    final planned = const PokemonImportPlanner().preview(
      sourceId: absolutePath,
      requiresNetwork: false,
      allowNetwork: false,
      documents: [
        for (final item in items)
          PokemonJsonDocument.fromJson(_kind(item.family), item.document),
      ],
    );
    final names = (species['names'] as Map?)?.cast<String, dynamic>() ?? {};
    return PokemonLocalImportPreview(
      speciesId: identity,
      name: '${names['fr'] ?? names['en'] ?? identity}',
      items: List.unmodifiable(items),
      fingerprint: planned.fingerprint,
    );
  }

  Future<String> apply(
    PokemonLocalImportPreview preview, {
    required bool confirmOverwrite,
  }) async {
    if (preview.hasConflicts && !confirmOverwrite) {
      throw const PokemonWorkspaceFailure(
        'Confirmez le remplacement des documents existants.',
      );
    }
    final refreshed = await this.preview(preview.items.first.sourcePath);
    if (refreshed.fingerprint != preview.fingerprint ||
        !samePokemonImportPreviewTargets(refreshed, preview)) {
      throw const PokemonWorkspaceFailure(
        'La source ou le projet a changé depuis l’aperçu. Reprévisualisez.',
      );
    }
    await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: reader,
    ).apply([
      for (final item in preview.items)
        PokemonDocumentWriteRequest(
          family: item.family,
          relativePath: item.relativePath,
          beforeBytes: item.beforeBytes,
          document: item.document,
        ),
    ]);
    return preview.speciesId;
  }

  Future<PokemonLocalImportItem> _item(
    PokemonDocumentFamily family,
    String sourcePath,
    String relativePath,
    List<int> sourceBytes,
    Map<String, dynamic> document, {
    String? ownerSpeciesId,
    String? reference,
    Set<String> knownSpeciesIds = const {},
    String ownerBaseFormId = '',
    bool ownerIsBaseForm = true,
  }) async {
    final beforeBytes = await _optional(relativePath);
    if (beforeBytes != null && family != PokemonDocumentFamily.species) {
      final existing = _validated(family, beforeBytes);
      if (!pokemonCompanionBelongsTo(
        family: family,
        ownerSpeciesId: ownerSpeciesId!,
        reference: reference!,
        declaredSpeciesId: existing['speciesId'] as String? ?? '',
        knownSpeciesIds: knownSpeciesIds,
        ownerBaseFormId: ownerBaseFormId,
        ownerIsBaseForm: ownerIsBaseForm,
      )) {
        throw PokemonWorkspaceFailure(
          'Le document $relativePath appartient déjà à '
          '${existing['speciesId']}.',
        );
      }
    }
    return PokemonLocalImportItem(
      family: family,
      sourcePath: sourcePath,
      relativePath: relativePath,
      sourceBytes: sourceBytes,
      beforeBytes: beforeBytes,
      document: document,
    );
  }

  Future<List<(String, String)>> _speciesFiles(
    ProjectPokemonConfig config,
  ) async {
    final directory = reader as ProjectDirectoryReader;
    try {
      final files = await directory.listFiles(
        projectRoot: session.directoryPath,
        relativeDirectory: config.speciesDir,
      );
      return [
        for (final path in files.where((path) => path.endsWith('.json')))
          (
            (jsonDecode(
                      utf8.decode(
                        await reader.readBytes(
                          projectRoot: session.directoryPath,
                          relativePath: path,
                        ),
                      ),
                    )
                    as Map)['id']
                as String,
            path,
          ),
      ];
    } on WorkspaceAccessException catch (error) {
      if (error.code == 'workspace.directory_missing') return const [];
      rethrow;
    }
  }

  Future<List<int>?> _optional(String path) async {
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
    if (probe.status == ProjectResourceProbeStatus.missing) return null;
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw PokemonWorkspaceFailure('Destination inaccessible : $path');
    }
    return reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
  }

  Map<String, dynamic> _validated(
    PokemonDocumentFamily family,
    List<int> bytes,
  ) {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'Le document Pokémon doit être un objet JSON.',
      );
    }
    return Map<String, dynamic>.from(
      PokemonJsonDocument.fromJson(_kind(family), value).toJson(),
    );
  }

  PokemonDocumentKind _kind(PokemonDocumentFamily family) => switch (family) {
    PokemonDocumentFamily.species => PokemonDocumentKind.species,
    PokemonDocumentFamily.learnset => PokemonDocumentKind.learnset,
    PokemonDocumentFamily.evolution => PokemonDocumentKind.evolution,
    PokemonDocumentFamily.media => PokemonDocumentKind.media,
  };
}
