import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../characters/character_removal_dialog.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';

Future<void> removeStudioCharacter(
  BuildContext context,
  ResourceNavigation navigation,
  ProjectCharacterEntry character,
) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  final retained = <ResourceMutationPreparation>[];
  final pending = <Future<ResourceMutationPreparation>>[];
  ResourceMutationPreparation? applicable;
  Future<ResourceMutationPreparation> prepare(
    String action,
    Map<String, Object?> parameters,
    String revision,
  ) async {
    final future = navigation
        .prepareOperation(
          action,
          parameters,
          expectedSnapshotRevision: revision,
        )
        .then((preparation) {
          retained.add(preparation);
          return preparation;
        });
    pending.add(future);
    return future;
  }

  try {
    await showResourceManagementRoute(
      context,
      (_) => CharacterRemovalDialog(
        name: character.name,
        canApply: () =>
            !navigation.isDisposed && navigation.pendingReceipt == null,
        ownerLabel: (dependency) => characterRemovalOwnerLabel(
          navigation.workspace.project!,
          dependency,
        ),
        inspect: () async => prepare('characterStudio.character.deletePlan', {
          'characterId': character.id,
        }, await navigation.captureResourceRevision()),
        prepare: (resolution, revision) async {
          if (applicable != null) {
            await navigation.releasePreparation(applicable!);
            retained.remove(applicable);
            applicable = null;
          }
          return applicable = await prepare(
            'characterStudio.character.delete',
            {'characterId': character.id, ...resolution},
            revision,
          );
        },
        apply: (plan) async {
          try {
            await navigation.applyPrepared(plan, confirmDestructive: true);
            return null;
          } on Object catch (failure) {
            return navigation.pendingReceipt != null
                ? 'Le retrait est publié. Fermez puis relisez le résultat ; ne rejouez pas l’opération.'
                : '$failure';
          }
        },
      ),
    );
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    for (final future in pending) {
      try {
        await future;
      } on Object {
        continue;
      }
    }
    try {
      for (final preparation in retained) {
        await navigation.releasePreparation(preparation);
      }
    } finally {
      navigation.endManagementDialog();
    }
  }
}

String characterRemovalOwnerLabel(ProjectManifest project, Map dependency) {
  final kind = dependency['sourceKind'];
  final id = dependency['sourceId'];
  final mapId = RegExp(
    r'^\$\.maps\[([^\]]+)\]',
  ).firstMatch('${dependency['path']}')?.group(1);
  final name = switch (kind) {
    'defaultPlayer' => 'Joueur par défaut',
    'newGameAvatar' => 'Avatar de nouvelle partie',
    'mapNpc' =>
      'Carte ${project.maps.where((entry) => entry.id == mapId).firstOrNull?.name ?? id}',
    'trainer' =>
      'Dresseur ${project.trainers.where((entry) => entry.id == id).firstOrNull?.name ?? id}',
    'dialogue' =>
      'Dialogue ${project.dialogues.where((entry) => entry.id == id).firstOrNull?.name ?? id}',
    'cinematicAppearance' || 'cinematicCustomAnimation' => 'Cinématique $id',
    'sceneCustomAnimation' => 'Scène $id',
    _ => '$kind · $id',
  };
  return '$name · ${dependency['path']}';
}
