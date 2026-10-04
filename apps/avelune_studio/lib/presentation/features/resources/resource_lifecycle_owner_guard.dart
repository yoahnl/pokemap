import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_catalog.dart';
import 'resource_navigation.dart';
import 'resource_management_dialog.dart';

Future<bool> resolveResourceDecorOwner(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item, {
  bool duplicate = false,
}) async {
  if (item.element == null || navigation.decorDraftFor(item.id) == null) {
    return true;
  }
  var save = false;
  await showResourceManagementRoute(
    context,
    (dialogContext) => AlertDialog(
      title: const Text('Enregistrer ce décor avant de continuer ?'),
      content: Text(
        '« ${item.name} » possède un brouillon. Seule cette définition sera '
        'enregistrée ; les autres préparations et cartes restent intactes.',
      ),
      actions: [
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(dialogContext),
        ),
        StudioButton(
          label: duplicate
              ? 'Enregistrer et dupliquer'
              : 'Enregistrer et réanalyser',
          onPressed: () {
            save = true;
            Navigator.pop(dialogContext);
          },
        ),
      ],
    ),
  );
  return save && await navigation.saveDecorOwner(item.id);
}
