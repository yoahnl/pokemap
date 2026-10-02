import 'dart:math';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../../features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import 'resource_catalog.dart';
import 'resource_lifecycle_bindings.dart';
import 'resource_management_bindings.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';
import 'resource_terrain_actions.dart';
import 'resource_terrain_deletion_dialog.dart';
import 'resource_terrain_management.dart';
import 'resource_terrain_management_dialog.dart';
import 'resource_terrain_owner_guard.dart';

void manageTerrainItem(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
  TerrainResourceAction action,
) => manageTerrainResource(
  context,
  navigation,
  action,
  name: item.name,
  presetId: item.id,
);

Future<void> manageTerrainResource(
  BuildContext context,
  ResourceNavigation navigation,
  TerrainResourceAction action, {
  required String name,
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
  Future<ResourceMutationPreparation>? pending;
  String? createdDraftId;
  String? snapshotRevision;
  final target = presetId != null
      ? <String, Object?>{'presetId': presetId}
      : <String, Object?>{'draftId': draftId};
  final localOnly =
      draftId != null &&
      !navigation.workspace.project!.smartTileCatalog.drafts.any(
        (draft) => draft.id == draftId,
      );
  final remove = action == TerrainResourceAction.deleteDraft;
  Future<ResourceMutationPreparation> prepare(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    if (retained != null) await navigation.releasePreparation(retained!);
    retained = null;
    pending = navigation.prepareOperation(
      actionId,
      parameters,
      expectedSnapshotRevision: snapshotRevision,
    );
    return retained = await pending!;
  }

  Future<String?> apply(ResourceMutationPreparation preparation) async {
    try {
      await navigation.applyPrepared(
        preparation,
        confirmDestructive: preparation.confirmationRequired,
      );
      return null;
    } on Object catch (failure) {
      return navigation.pendingReceipt != null
          ? 'L’opération a été publiée. Fermez puis utilisez « Relire le résultat » ; ne relancez pas la modification.'
          : '$failure';
    }
  }

  try {
    if (!(remove && localOnly) &&
        !await resolveTerrainManagementOwner(context, navigation, target)) {
      return;
    }
    if (!context.mounted || navigation.isDisposed) return;
    snapshotRevision = await navigation.captureResourceRevision();
    if (!context.mounted || navigation.isDisposed) return;
    if (remove) {
      await showResourceManagementRoute(
        context,
        (_) => ResourceTerrainDeletionDialog(
          name: name,
          draft: draftId != null,
          canApply: () =>
              !navigation.isDisposed && navigation.pendingReceipt == null,
          prepare: () async => localOnly
              ? null
              : await prepare(
                  draftId != null
                      ? 'smart_tile.preset.draft.delete'
                      : 'smart_tile.preset.delete',
                  target,
                ),
          apply: (preparation) async {
            if (localOnly) {
              navigation.discardLocalTerrain(draftId);
              return null;
            }
            return apply(preparation!);
          },
        ),
      );
    } else {
      final duplicate = action == TerrainResourceAction.duplicate;
      final unique =
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      final newDraft = 'draft-terrain-copy-$unique';
      await showResourceManagementRoute(
        context,
        (_) => ResourceTerrainManagementDialog(
          title: duplicate
              ? 'Dupliquer le terrain ou chemin'
              : 'Renommer le terrain ou chemin',
          name: duplicate ? '$name — copie' : name,
          duplicate: duplicate,
          description: duplicate
              ? '${draftId == null ? 'Version publiée' : 'Brouillon enregistré'} : $name. Une nouvelle préparation indépendante sera créée, sans publication. Les PNG restent partagés et les cartes gardent leur terrain actuel.'
              : 'Seul le nom ${draftId == null ? 'de la publication et de ses préparations liées' : 'de ce brouillon'} change. Aucun raccord modifié n’est publié.',
          canApply: () =>
              !navigation.isDisposed && navigation.pendingReceipt == null,
          submit: (value) async {
            if (!duplicate && value.trim() == name.trim()) return null;
            try {
              final parameters = {
                ...target,
                'name': value,
                if (duplicate) ...{
                  'newDraftId': newDraft,
                  'targetPresetId': 'terrain-copy-$unique',
                },
              };
              final preparation = await prepare(
                duplicate
                    ? 'smart_tile.preset.duplicate'
                    : 'smart_tile.preset.rename',
                parameters,
              );
              final error = await apply(preparation);
              if (error == null && duplicate) createdDraftId = newDraft;
              return error;
            } on Object catch (failure) {
              return '$failure';
            }
          },
        ),
      );
    }
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (pending != null) {
      try {
        retained = await pending;
      } on Object {
        retained = null;
      }
    }
    try {
      if (retained != null) await navigation.releasePreparation(retained!);
    } finally {
      navigation.endManagementDialog();
    }
  }
  if (createdDraftId != null && !navigation.isDisposed) {
    final draft = navigation.workspace.project!.smartTileCatalog.drafts
        .where((entry) => entry.id == createdDraftId)
        .firstOrNull;
    if (draft != null) navigation.resumeTerrain(draft);
  }
}

void renameResourceOrTerrain(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) {
  if (item.terrain != null) {
    manageTerrainItem(context, navigation, item, TerrainResourceAction.rename);
  } else {
    openResourceInformation(context, navigation, item);
  }
}

void duplicateResourceOrTerrain(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) {
  if (item.terrain != null) {
    manageTerrainItem(
      context,
      navigation,
      item,
      TerrainResourceAction.duplicate,
    );
  } else {
    duplicateResourceDefinition(context, navigation, item);
  }
}

void removeResourceOrTerrain(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) {
  if (item.terrain != null) {
    manageTerrainItem(
      context,
      navigation,
      item,
      TerrainResourceAction.deleteDraft,
    );
  } else {
    removeResourceDefinition(context, navigation, item);
  }
}

String terrainPreparationStatus(
  ResourceNavigation navigation,
  ProjectSmartTileAuthoringDraft draft,
) {
  final model = navigation.terrains[draft.id];
  if (model != null) return model.statusLabel;
  final preset = navigation.workspace.project!.smartTileCatalog.presets
      .where((preset) => preset.id == draft.targetPresetId)
      .firstOrNull;
  if (preset == null) return 'Brouillon enregistré';
  if (terrainDraftCompatibilityProblem(navigation.workspace.project!, draft) !=
      null) {
    return 'Préparation liée à une publication';
  }
  return terrainDraftPreset(draft) == preset
      ? 'Version publiée'
      : 'Modifications non publiées';
}

void manageTerrainPreparation(
  BuildContext context,
  ResourceNavigation navigation,
  ProjectSmartTileAuthoringDraft draft,
  TerrainResourceAction action,
) {
  if (action == TerrainResourceAction.usages) {
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
      return;
    }
    openResourceUsages(
      context,
      navigation,
      ResourceItem(
        id: preset.id,
        name: preset.name,
        kind: ResourceKind.terrains,
        terrain: preset,
      ),
    );
    return;
  }
  manageTerrainResource(
    context,
    navigation,
    action,
    name: draft.name,
    draftId: draft.id,
  );
}
