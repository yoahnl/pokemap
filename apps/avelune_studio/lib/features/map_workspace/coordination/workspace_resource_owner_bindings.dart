import 'package:map_core/map_core_domain.dart';

import '../application/map_workspace_controller.dart';
import '../application/map_workspace_editing_state.dart';
import '../../pokemon/application/pokemon_workspace_controller.dart';
import '../../pokemon/application/pokemon_combat_controller.dart';
import '../../dialogues/application/dialogue_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../cinematics/application/cinematic_workspace_controller.dart';
import '../../resources/coordination/resource_navigation.dart';
import '../../resources/domain/resource_port.dart';

class WorkspaceResourceOwnerBindings {
  WorkspaceResourceOwnerBindings({
    required this.controller,
    required this.views,
    required this.pokemon,
    required this.dialogues,
    required this.narrative,
    required this.cinematics,
    required this.drawEnvironment,
    required this.retainBrush,
  });

  final MapWorkspaceController controller;
  final Map<String, MapWorkspaceEditingState> Function() views;
  final PokemonWorkspaceController? Function() pokemon;
  final DialogueWorkspaceController? Function() dialogues;
  final NarrativeWorkspaceController? Function() narrative;
  final CinematicWorkspaceController? Function() cinematics;
  final Future<void> Function(EnvironmentPreset) drawEnvironment;
  final void Function() retainBrush;

  Future<bool> replaceCatalogModelSource(
    ResourceNavigation? resources,
    String modelId, {
    required Future<ResourceMutationReceipt?> Function(
      ResourceNavigation,
      String,
    )
    replace,
  }) async {
    if (resources == null || resources.busy) {
      throw const ResourceFailure(
        'Le remplacement est indisponible pour le moment.',
      );
    }
    final pending = resources.pendingReceipt;
    if (pending != null) {
      if (!pending.changedModels.containsKey(modelId) &&
          !_receiptReplacesModelSource(pending, modelId)) {
        throw const ResourceFailure(
          'Terminez l’actualisation de la ressource précédente.',
        );
      }
      if (await resources.retryReconciliation()) return true;
    } else {
      final receipt = await replace(resources, modelId);
      if (receipt != null) return true;
      if (resources.error == null) return false;
    }
    throw ResourceFailure(
      resources.error ?? 'Le modèle ne peut pas être actualisé.',
      partialReceipt: resources.pendingReceipt,
    );
  }

  void bind(ResourceNavigation? resources) {
    resources?.drawEnvironment = drawEnvironment;
    resources?.additionalCharacterOwners = characterDraftOwners;
    resources?.characterSourceProblem = (ids) =>
        dialogues()?.characterSourceProblem(ids) ??
        narrativeCharacterSourceProblem(ids);
    resources?.characterSourcesChanged = (ids) {
      final project = controller.project;
      if (project != null) {
        pokemon()?.combat?.reconcileCharacterReferences(
          project,
          resources.pendingReceipt?.changedMaps ?? const {},
        );
      }
      dialogues()?.invalidateCharacterSources(ids);
      for (final id in ids) {
        narrative()?.invalidateCleanDialogueSessions(id);
      }
    };
    resources?.borderDrawingOwner = (blueprintId) {
      for (final entry in views().entries) {
        if (entry.value.borderDraft?.blueprintId == blueprintId) {
          final name =
              controller.documents[entry.key]?.current.name ?? entry.key;
          return 'Carte · $name · tracé de bordure en cours';
        }
      }
      return null;
    };
  }

  List<String> characterDraftOwners(String characterId) => [
    ?pokemon()?.combat?.characterDraftOwner(characterId),
    ...?dialogues()?.characterDraftOwners(characterId),
    if (narrative() != null)
      for (final session in narrative()!.sessions.values)
        if (session.dirty &&
            [session.current, session.saved].any(
              (state) => state.dialogue.branches.any(
                (branch) =>
                    branch.lines.any((line) => line.speakerId == characterId),
              ),
            ))
          'Interaction · ${session.current.dialogue.entry.name}',
    for (final asset in cinematics()?.entries ?? <CinematicAsset>[])
      if (cinematics()?.accessProblem(asset.id) != null &&
          [
            asset,
            ...?controller.project?.cinematics.where((c) => c.id == asset.id),
          ].any(
            (value) =>
                value.stageContext?.actorAppearanceBindings.any(
                  (binding) => binding.characterId == characterId,
                ) ??
                false,
          ))
        'Cinématique · ${asset.title}',
  ];

  String? narrativeCharacterSourceProblem(Set<String> ids) {
    for (final id in ids) {
      final problem = narrative()?.dialogueInteractionAccessProblem(id);
      if (problem != null) return problem;
    }
    return null;
  }

  void reconcileBrushes() {
    final project = controller.project;
    if (project == null) return;
    var changed = false;
    for (final entry in views().entries) {
      if (!controller.hasCompleteProject &&
          entry.key != controller.active?.base.mapId) {
        continue;
      }
      final view = entry.value;
      final characterId = view.character?.id;
      if (characterId != null) {
        final before = view.character;
        view.character = project.characters
            .where((character) => character.id == characterId)
            .firstOrNull;
        changed |= before != view.character;
        if (view.character == null && view.tool == StudioMapTool.character) {
          view.tool = StudioMapTool.select;
        }
      }
      final brushId = view.brush?.id;
      if (brushId != null) {
        final before = view.brush;
        view.brush = project.elements
            .where((element) => element.id == brushId)
            .firstOrNull;
        changed |= before != view.brush;
        if (view.brush == null && view.tool == StudioMapTool.place) {
          view.tool = StudioMapTool.select;
        }
      }
      final tileId = view.tile?.tilesetId;
      if (tileId != null && !project.tilesets.any((t) => t.id == tileId)) {
        view.tile = null;
        changed = true;
        if (view.tool == StudioMapTool.paint) view.tool = StudioMapTool.select;
      }
      final terrainId = view.terrain?.id;
      if (terrainId != null) {
        final before = view.terrain;
        view.terrain = project.smartTileCatalog.presets
            .where((preset) => preset.id == terrainId)
            .firstOrNull;
        changed |= before != view.terrain;
        if (view.terrain == null && view.tool == StudioMapTool.terrain) {
          view.tool = StudioMapTool.select;
        }
      }
      final borderId = view.borderBlueprintId;
      if (borderId != null &&
          !project.borderCatalog.records.any(
            (record) =>
                record.id == borderId &&
                !record.isDeprecated &&
                record.latestPublished != null,
          )) {
        view.borderBlueprintId = null;
        changed = true;
        if (view.tool == StudioMapTool.border) view.tool = StudioMapTool.select;
      }
    }
    if (changed) retainBrush();
  }
}

bool _receiptReplacesModelSource(
  ResourceMutationReceipt receipt,
  String modelId,
) {
  if (receipt.actionId != 'model3d.source.replace') return false;
  final before = receipt.before.models3d
      .where((model) => model.id == modelId)
      .firstOrNull;
  final after = receipt.manifest.models3d
      .where((model) => model.id == modelId)
      .firstOrNull;
  if (before == null ||
      after == null ||
      before.sourceAssetId != after.sourceAssetId ||
      before.relativePath != after.relativePath) {
    return false;
  }
  return before != after ||
      (receipt.changedPaths.contains(after.relativePath) &&
          receipt.pathRevisions[after.relativePath] != null &&
          receipt.resourceRevisions['asset:${after.sourceAssetId}'] != null);
}
