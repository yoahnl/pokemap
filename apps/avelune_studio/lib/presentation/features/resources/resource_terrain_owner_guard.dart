import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';
import '../../../features/resources/coordination/resource_terrain_lifecycle.dart';

Future<bool> resolveTerrainManagementOwner(
  BuildContext context,
  TerrainManagementOwners session,
) async {
  var proceed = false;
  await showResourceManagementRoute(
    context,
    (_) => ResourceManagementDialog(
      title: 'Enregistrer la préparation avant de continuer ?',
      submitLabel: 'Enregistrer et continuer',
      dirty: () => false,
      valid: () => session.canSave,
      fields: (_, busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Préparations concernées : ${session.owners.map((model) => model.draft.name).join(' · ')}',
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
        final error = await session.save();
        if (error != null) return error;
        proceed = true;
        return null;
      },
    ),
  );
  return proceed;
}
