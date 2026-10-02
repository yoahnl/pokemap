import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';
import 'resource_terrain_management.dart';

Future<bool> resolveTerrainManagementOwner(
  BuildContext context,
  ResourceNavigation navigation,
  Map<String, Object?> target,
) async {
  final owners = navigation
      .terrainManagementModels(target)
      .where((model) => model.dirty)
      .toList();
  if (owners.isEmpty) return true;
  var proceed = false;
  await showResourceManagementRoute(
    context,
    (_) => ResourceManagementDialog(
      title: 'Enregistrer la préparation avant de continuer ?',
      submitLabel: 'Enregistrer et continuer',
      dirty: () => false,
      valid: () => navigation.pendingReceipt == null && !navigation.isDisposed,
      fields: (_, busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Préparations concernées : ${owners.map((model) => model.draft.name).join(' · ')}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Les raccords seront enregistrés comme brouillons, sans publication. Les autres préparations et cartes restent inchangées.',
          ),
          const SizedBox(height: 12),
          StudioButton(
            label: 'Rester avec mes modifications',
            secondary: true,
            onPressed: busy ? null : () => Navigator.pop(context),
          ),
        ],
      ),
      submit: () async {
        for (final owner in owners) {
          if (!await owner.save(navigation.mutate)) {
            return owner.error ?? 'La préparation n’a pas pu être enregistrée.';
          }
        }
        proceed = true;
        return null;
      },
    ),
  );
  return proceed;
}
