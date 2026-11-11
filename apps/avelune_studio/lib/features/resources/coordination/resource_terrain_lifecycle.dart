import 'dart:math';

import 'package:map_core/map_core_domain.dart';

import '../../terrains/application/terrain_draft_controller.dart';
import '../../terrains/domain/terrain_connections.dart';
import '../../terrains/domain/terrain_draft_compatibility.dart';
import '../application/resource_catalog.dart';
import '../application/resource_lifecycle_publication.dart';
import '../application/resource_terrain_actions.dart';
import '../application/resource_terrain_lifecycle_controller.dart';
import '../domain/resource_mutation_preparation.dart';
import 'resource_navigation.dart';
import 'resource_replacement_workflow.dart';
import 'resource_terrain_management.dart';

class TerrainManagementOwners {
  TerrainManagementOwners(this.navigation, Map<String, Object?> target)
    : owners = navigation
          .terrainManagementModels(target)
          .where((owner) => owner.dirty)
          .toList();

  final ResourceNavigation navigation;
  final List<TerrainDraftController> owners;
  bool _saving = false;

  bool get canSave =>
      !_saving && !navigation.isDisposed && navigation.pendingReceipt == null;

  bool get _current =>
      !navigation.isDisposed &&
      owners.every(
        (owner) => identical(navigation.terrains[owner.draft.id], owner),
      );

  Future<String?> save() async {
    if (!canSave || !_current) {
      return 'Les préparations ont changé. Rouvrez l’opération.';
    }
    _saving = true;
    try {
      for (final owner in owners) {
        if (!_current) {
          return 'Les préparations ont changé. Rouvrez l’opération.';
        }
        if (!await owner.save(navigation.mutate)) {
          return owner.error ?? 'La préparation n’a pas pu être enregistrée.';
        }
      }
      return _current && owners.every((owner) => !owner.dirty)
          ? null
          : 'Une préparation a changé pendant l’enregistrement. Votre saisie est conservée.';
    } finally {
      _saving = false;
    }
  }
}

Future<void> runTerrainResourceManagement({
  required ResourceNavigation navigation,
  required TerrainResourceAction action,
  required String name,
  required bool Function() isActive,
  required Future<bool> Function(TerrainManagementOwners) confirmOwnerSave,
  required Future<void> Function(ResourceTerrainLifecycleController) present,
  String? presetId,
  String? draftId,
}) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? retained;
  ResourceTerrainLifecycleController? controller;
  String? createdDraftId;
  final target = presetId != null
      ? <String, Object?>{'presetId': presetId}
      : <String, Object?>{'draftId': draftId};
  final localOnly =
      draftId != null &&
      !navigation.workspace.project!.smartTileCatalog.drafts.any(
        (draft) => draft.id == draftId,
      );
  final remove = action == TerrainResourceAction.deleteDraft;
  final duplicate = action == TerrainResourceAction.duplicate;
  final unique =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
  final newDraft = 'draft-terrain-copy-$unique';
  try {
    if (!(remove && localOnly)) {
      final owners = TerrainManagementOwners(navigation, target);
      if (owners.owners.isNotEmpty && !await confirmOwnerSave(owners)) return;
    }
    if (!isActive() || navigation.isDisposed) return;
    final revision = await navigation.captureResourceRevision();
    if (!isActive() || navigation.isDisposed) return;
    controller = ResourceTerrainLifecycleController(
      name: name,
      duplicate: duplicate,
      removing: remove,
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null,
      prepareOperation: (value) async {
        if (retained != null) await navigation.releasePreparation(retained!);
        retained = null;
        if (remove && localOnly) return null;
        return retained = await navigation.prepareOperation(
          remove
              ? draftId != null
                    ? 'smart_tile.preset.draft.delete'
                    : 'smart_tile.preset.delete'
              : duplicate
              ? 'smart_tile.preset.duplicate'
              : 'smart_tile.preset.rename',
          {
            ...target,
            if (!remove) 'name': value,
            if (duplicate) ...{
              'newDraftId': newDraft,
              'targetPresetId': 'terrain-copy-$unique',
            },
          },
          expectedSnapshotRevision: revision,
        );
      },
      publish: (preparation) async {
        if (remove && localOnly) {
          navigation.discardLocalTerrain(draftId);
          return const ResourceLifecyclePublicationResult(
            error: null,
            publicationCommitted: true,
          );
        }
        final result = await applyResourceLifecyclePublication(
          navigation,
          preparation!,
          confirmDestructive: preparation.confirmationRequired,
        );
        if (result.error == null && duplicate) createdDraftId = newDraft;
        return result;
      },
    );
    await present(controller);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    controller?.dispose();
    try {
      await controller?.settle();
    } finally {
      try {
        if (retained != null) await navigation.releasePreparation(retained!);
      } finally {
        navigation.endManagementDialog();
      }
    }
  }
  if (createdDraftId != null && isActive() && !navigation.isDisposed) {
    final draft = navigation.workspace.project!.smartTileCatalog.drafts
        .where((entry) => entry.id == createdDraftId)
        .firstOrNull;
    if (draft != null) navigation.resumeTerrain(draft);
  }
}

String terrainPreparationStatus(
  ResourceNavigation navigation,
  ProjectSmartTileAuthoringDraft draft,
) {
  final model = navigation.terrains[draft.id];
  if (model != null) return model.statusLabel;
  final project = navigation.workspace.project!;
  final preset = project.smartTileCatalog.presets
      .where((preset) => preset.id == draft.targetPresetId)
      .firstOrNull;
  if (preset == null) return 'Brouillon enregistré';
  if (terrainDraftCompatibilityProblem(project, draft) != null) {
    return 'Préparation liée à une publication';
  }
  return terrainDraftPreset(draft) == preset
      ? 'Version publiée'
      : 'Modifications non publiées';
}

ResourceItem? terrainPreparationPublication(
  ResourceNavigation navigation,
  ProjectSmartTileAuthoringDraft draft,
) {
  final preset = navigation.workspace.project!.smartTileCatalog.presets
      .where(
        (entry) =>
            entry.id == draft.sourcePresetId ||
            entry.id == draft.targetPresetId,
      )
      .firstOrNull;
  if (preset == null) {
    navigation.setImportError(
      'La publication liée est absente. Cette préparation n’est pas un terrain placé sur une carte.',
    );
    return null;
  }
  return ResourceItem(
    id: preset.id,
    name: preset.name,
    kind: ResourceKind.terrains,
    terrain: preset,
  );
}

Future<void> runTerrainPreparationAction({
  required ResourceNavigation navigation,
  required ProjectSmartTileAuthoringDraft draft,
  required TerrainResourceAction action,
  required void Function(ResourceItem publication) openUsages,
  required Future<void> Function({
    required String name,
    required String draftId,
  })
  manage,
}) async {
  if (action == TerrainResourceAction.usages) {
    final publication = terrainPreparationPublication(navigation, draft);
    if (publication != null) openUsages(publication);
    return;
  }
  await manage(name: draft.name, draftId: draft.id);
}
