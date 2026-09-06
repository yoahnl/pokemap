import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../authoring_api/authoring_mutation_adapter.dart';
import '../authoring_api/editor_receipt_presenter.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

final class PokemonMenuSpriteImportPreview {
  const PokemonMenuSpriteImportPreview({
    required this.projectRoot,
    required this.revision,
    required this.batches,
    required this.handles,
    required this.preserved,
    required this.unavailable,
  });

  final String projectRoot;
  final String revision;
  final List<List<Map<String, Object?>>> batches;
  final Set<String> handles;
  final int preserved;
  final List<String> unavailable;

  int get additions => batches.fold(0, (count, batch) => count + batch.length);
}

final class ImportPokemonMenuSpritesUseCase {
  ImportPokemonMenuSpritesUseCase({
    required this.repository,
    required this.mutations,
  });

  final PokemonReadRepository repository;
  final AuthoringMutationAdapter mutations;
  int _sequence = 0;

  Future<PokemonMenuSpriteImportPreview> preview(
    ProjectWorkspace workspace, {
    required String sourceDirectory,
    bool includeMissingPortraits = false,
    PokemonSpriteSourceCatalog? sourceCatalog,
    Future<String?> Function(String relativePath)? resolveSourceFile,
    void Function(String relativePath, List<int> bytes)? verifySourceArtifact,
  }) async {
    final initialRevision = await mutations.readRevision(workspace.projectRoot);
    final sourceRepository = repository;
    if (sourceRepository is PokemonSpeciesSnapshotController) {
      (sourceRepository as PokemonSpeciesSnapshotController)
          .invalidateSpeciesSnapshot(workspace);
    }
    final root = await Directory(sourceDirectory).resolveSymbolicLinks();
    Future<String> sourcePath(String relative) async {
      final resolved = await File(
        p.join(root, relative),
      ).resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw const FormatException('Une image sort du dossier source choisi.');
      }
      return resolved;
    }

    final catalog =
        sourceCatalog ??
        PokemonSpriteSourceCatalog.fromJson(
          jsonDecode(
                await File(
                  await sourcePath('data/species.json'),
                ).readAsString(),
              )
              as Map<String, dynamic>,
        );
    final mediaIds = (await repository.listMediaIds(workspace)).toSet();
    final handles = <String>{};
    final staged = <String, String>{};
    final entries = <Map<String, Object?>>[];
    final unavailable = <String>[];
    var preserved = 0;
    try {
      final speciesPaths = (await repository.listSpeciesFiles(
        workspace,
      )).toList();
      for (final path in speciesPaths..sort()) {
        final species = await repository.readSpeciesByRelativePath(
          workspace,
          path,
        );
        final media = mediaIds.contains(species.refs.media)
            ? await repository.readMediaById(workspace, species.refs.media)
            : null;
        final qualified = catalog.qualify(
          species: [species],
          media: {species.id: ?media},
        );
        for (final form in qualified) {
          final formId = form['formId']! as String;
          final sourceId = form['sourceId'] as String?;
          final variant = media?.variants[formId];
          for (final role in [
            PokemonMediaImportRole.icon,
            PokemonMediaImportRole.party,
            if (includeMissingPortraits) PokemonMediaImportRole.portrait,
          ]) {
            final existing = switch (role) {
              PokemonMediaImportRole.icon => variant?.icon,
              PokemonMediaImportRole.party => variant?.party,
              PokemonMediaImportRole.portrait => variant?.portrait,
            };
            if (existing != null && existing.isNotEmpty) {
              preserved++;
              continue;
            }
            final label = '${species.id}/$formId/${role.name}';
            if (sourceId == null) {
              unavailable.add('$label : forme sans correspondance explicite');
              continue;
            }
            final homeId = PokemonSpriteSourceCatalog.homeMediaIdentity(
              sourceId,
            );
            var relative = role == PokemonMediaImportRole.portrait
                ? 'src/previews/gen9/$sourceId.png'
                : 'src/minisprites/pokemon/home/$homeId.png';
            var availablePath = resolveSourceFile == null
                ? p.join(root, relative)
                : await resolveSourceFile(relative);
            if ((availablePath == null ||
                    !await File(availablePath).exists()) &&
                role != PokemonMediaImportRole.portrait) {
              relative = 'src/previews/gen9/$sourceId.png';
              availablePath = resolveSourceFile == null
                  ? p.join(root, relative)
                  : await resolveSourceFile(relative);
            }
            if (availablePath == null || !await File(availablePath).exists()) {
              unavailable.add('$label : image absente');
              continue;
            }
            final resolved = await File(availablePath).resolveSymbolicLinks();
            if (!p.isWithin(root, resolved)) {
              throw const FormatException(
                'Une image sort du dossier source choisi.',
              );
            }
            var handle = staged[resolved];
            if (handle == null) {
              final artifact = await mutations.stageArtifact(
                workspace.projectRoot,
                sourcePath: resolved,
                declaredMediaType: 'image/png',
              );
              handle = artifact.reference.handle;
              if (!handles.add(handle)) {
                await mutations.releaseArtifact(
                  workspace.projectRoot,
                  handle: handle,
                );
              }
              if (verifySourceArtifact != null) {
                verifySourceArtifact(
                  relative,
                  await mutations.readArtifact(
                    workspace.projectRoot,
                    handle: handle,
                  ),
                );
              }
              staged[resolved] = handle;
            }
            entries.add(
              PokemonMediaImportEntry(
                speciesId: species.id,
                formId: formId,
                role: role,
                artifactHandle: handle,
              ).toJson(),
            );
          }
        }
      }
      if (await mutations.readRevision(workspace.projectRoot) !=
          initialRevision) {
        throw const EditorAuthoringMutationFailure(
          code: 'editor.menu_source_stale',
          message:
              'Le projet a changé pendant la préparation. Relancez la récupération.',
        );
      }
      final batches = <List<Map<String, Object?>>>[];
      var revision = initialRevision;
      for (var start = 0; start < entries.length; start += 100) {
        final batch = entries.sublist(
          start,
          (start + 100).clamp(0, entries.length),
        );
        final plan = await mutations.plan(
          workspace.projectRoot,
          actionId: 'pokemon.media.import',
          parameters: {'entries': batch},
          idempotencyKey: _identity('preview'),
          expectedRevision: revision,
          dryRun: true,
        );
        revision = plan.snapshotRevision;
        final added = (plan.preview['added'] as List).cast<Map>();
        final accepted = added.map(_entryKey).toSet();
        preserved += (plan.preview['preserved'] as List).length;
        for (final conflict
            in (plan.preview['conflicts'] as List).cast<Map>()) {
          if (conflict['resolution'] == 'skip') {
            unavailable.add(
              '${_entryKey(conflict)} : conflit avec une image du projet',
            );
          }
        }
        final selected = batch
            .where((entry) => accepted.contains(_entryKey(entry)))
            .toList();
        if (selected.isNotEmpty) batches.add(List.unmodifiable(selected));
      }
      return PokemonMenuSpriteImportPreview(
        projectRoot: workspace.projectRoot,
        revision: revision,
        batches: List.unmodifiable(batches),
        handles: Set.unmodifiable(handles),
        preserved: preserved,
        unavailable: List.unmodifiable(unavailable),
      );
    } on Object {
      await _release(workspace.projectRoot, handles);
      rethrow;
    }
  }

  Future<int> execute(PokemonMenuSpriteImportPreview preview) async {
    var revision = preview.revision;
    var applied = 0;
    for (final batch in preview.batches) {
      if (await mutations.readRevision(preview.projectRoot) != revision) {
        throw const EditorAuthoringMutationFailure(
          code: 'editor.menu_source_stale',
          message:
              'Le projet a changé. Relancez la récupération des miniatures.',
        );
      }
      final plan = await mutations.plan(
        preview.projectRoot,
        actionId: 'pokemon.media.import',
        parameters: {'entries': batch},
        idempotencyKey: _identity('import'),
        expectedRevision: revision,
      );
      if (plan.preview['idempotent'] == true) continue;
      final result = await mutations.apply(
        plan,
        operationId: _identity('apply'),
      );
      revision = result.snapshotRevision;
      applied += (plan.preview['added'] as List).length;
    }
    return applied;
  }

  Future<void> release(PokemonMenuSpriteImportPreview preview) =>
      _release(preview.projectRoot, preview.handles);

  Future<void> _release(String root, Set<String> handles) async {
    for (final handle in handles) {
      try {
        await mutations.releaseArtifact(root, handle: handle);
      } on EditorAuthoringMutationFailure catch (error) {
        if (error.code != 'editor.authoring_session_stale') rethrow;
      }
    }
  }

  String _identity(String phase) =>
      'menu-sprites-$phase-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  String _entryKey(Map entry) =>
      '${entry['speciesId']}/${entry['formId']}/${entry['role']}';
}
