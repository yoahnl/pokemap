import 'dart:async';
import 'dart:math';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_move_recipe_choice.dart';
import '../domain/pokemon_workspace_models.dart';

final class PokemonMoveRecipeImport {
  PokemonMoveRecipeImport._({
    required this.session,
    required this.mapAdapter,
    required this.media,
    required this._handles,
    required this._opened,
    required this._api,
    required this._artifacts,
  });

  static Future<PokemonMoveRecipeImport> open({
    required ProjectSession session,
    required LocalMapWorkspaceAdapter mapAdapter,
    required AvelunePokemonMediaSource media,
    ProjectFileReader reader = const LocalProjectFileReader(),
  }) async {
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      throw StateError(
        'Un projet de travail est nécessaire pour importer une animation.',
      );
    }
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
      initializeSceneOwners: false,
    ).openProject(session.directoryPath);
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [session.directoryPath],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    );
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      artifactStore: artifacts,
      catalogFileReader: reader,
    );
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
    } on Object {
      handles.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
    return PokemonMoveRecipeImport._(
      session: session,
      mapAdapter: mapAdapter,
      media: media,
      handles: handles,
      opened: opened,
      api: api,
      artifacts: artifacts,
    );
  }

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AvelunePokemonMediaSource media;
  final WorkspaceHandleStore _handles;
  final OpenedProject _opened;
  final LocalMapAuthoringMutationApi _api;
  final LocalArtifactStore _artifacts;
  bool _closed = false;
  int _active = 0;
  Completer<void>? _idle;
  Future<void>? _closing;

  static const _limits = BattleRecipeBundleLimits(
    maxTextures: 256,
    maxTextureBytes: 8 * 1024 * 1024,
    maxBundleBytes: 64 * 1024 * 1024,
    maxDimension: 2048,
    maxTexturePixels: 4000000,
    maxTotalPixels: 16000000,
  );

  static String _catalogId(String projectMoveId) {
    final id = battleRecipeCatalogMoveId(projectMoveId, allowUnknown: true);
    if (id == null) {
      throw const FormatException(
        'Cette attaque ne correspond pas au catalogue Avelune.',
      );
    }
    return id;
  }

  Future<T> _use<T>(Future<T> Function() action) async {
    if (_closed) throw StateError('L’atelier Pokémon est fermé.');
    _active++;
    try {
      return await action();
    } finally {
      _active--;
      if (_active == 0) {
        _idle?.complete();
        _idle = null;
      }
    }
  }

  void _requireCurrent(bool Function()? isCurrent) {
    if (_closed || isCurrent?.call() == false) {
      throw StateError('La sélection a changé. Import annulé.');
    }
  }

  Future<List<PokemonMoveRecipeChoice>> listForMove(String projectMoveId) =>
      _use(() async {
        final entries = await BattleMoveRecipeCatalogSource(media)
            .list(projectMoveId, manualSelection: true);
        return List.unmodifiable([
          for (final entry in entries)
            PokemonMoveRecipeChoice(
              catalogMoveId: entry.catalogMoveId,
              mediaId: entry.mediaId,
              sourceMoveId: entry.binding.sourceMoveId,
              recipeSha256: entry.binding.recipeSha256,
              variant: entry.binding.variant,
              revision: entry.binding.revision,
              style: entry.style,
            ),
        ]);
      });

  Future<bool> importChoice(
    String projectMoveId,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  }) => _use(() async {
    _requireCurrent(isCurrent);
    if (choice.catalogMoveId != _catalogId(projectMoveId)) {
      throw const FormatException(
        'Cette animation appartient à une autre attaque.',
      );
    }
    final fetched = await AveluneMoveRecipeSource(media).fetch(
      catalogMoveId: choice.catalogMoveId,
      sourceMoveId: choice.sourceMoveId,
      projectMoveId: projectMoveId,
      mediaId: choice.mediaId,
      limits: _limits,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    _requireCurrent(isCurrent);
    if (fetched.binding.recipeSha256 != choice.recipeSha256 ||
        fetched.binding.variant != choice.variant ||
        fetched.binding.revision != choice.revision) {
      throw StateError(
        'L’animation a changé. Actualisez la liste avant de réessayer.',
      );
    }
    return mapAdapter.withResourceMutation(() async {
      _requireCurrent(isCurrent);
      final staged = <String>[];
      try {
        final recipe = await _artifacts.put(fetched.bundle.recipeBytes);
        staged.add(recipe.reference.handle);
        final resources = <Map<String, Object?>>[];
        for (final resource in fetched.bundle.recipe.resources) {
          final artifact = await _artifacts.put(
            fetched.bundle.media[resource.id]!,
          );
          staged.add(artifact.reference.handle);
          resources.add({
            'id': resource.id,
            'sha256': resource.sha256Hex,
            'mediaType': resource.mediaType,
            'artifactHandle': artifact.reference.handle,
          });
        }
        _requireCurrent(isCurrent);
        final parameters = <String, Object?>{
          'projectBinding': BattleRecipeProjectBinding(
            binding: fetched.binding,
            catalogMoveId: fetched.catalogMoveId,
            recipeMediaId: fetched.recipeMediaId,
          ).toJson(),
          'recipeHandle': recipe.reference.handle,
          'resources': resources,
        };
        final snapshot = await _api.readWorkshopSnapshot(
          _opened.projectHandle,
          actionId: 'pokemon.move_recipe.import',
          parameters: parameters,
        );
        final operation =
            'studio_move_recipe_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        final plan = await _api.planMutation(
          _opened.projectHandle,
          AuthoringRequest(
            requestId: operation,
            actionId: 'pokemon.move_recipe.import',
            actionVersion: 1,
            workspaceHandle: _opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true},
          ),
        );
        _requireCurrent(isCurrent);
        if (plan.plan.changeSet.changes.isEmpty) return false;
        try {
          await _api.applyMutation(
            _opened.projectHandle,
            planId: plan.planId,
            operationId: operation,
            precondition: () async => _requireCurrent(isCurrent),
          );
        } on Object {
          _requireCurrent(isCurrent);
          throw PokemonWorkspaceFailure(
            'L’import a été interrompu. Si le projet demande une récupération, '
            'ouvrez-le puis lancez-la avant de réessayer. Référence : $operation',
          );
        }
        return true;
      } finally {
        for (final handle in staged) {
          await _artifacts.release(handle);
        }
      }
    });
  });

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    if (_active > 0) {
      _idle ??= Completer<void>();
      await _idle!.future;
    }
    try {
      await _api.detachWorkspace(_opened.workspaceHandle);
    } finally {
      _handles.closeWorkspace(_opened.workspaceHandle);
    }
  }
}
