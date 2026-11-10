import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/coordination/resource_definition_lifecycle.dart';
import 'resource_management_dialog.dart';

Future<void> showResourceDuplicate(
  BuildContext context, {
  required ResourceDuplicateSession session,
  required ProjectManifest project,
}) async {
  final originalName = session.name;
  final name = TextEditingController(text: originalName);
  final originalCategory = session.categoryId;
  try {
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: 'Dupliquer la définition de décor',
        submitLabel: 'Créer la copie',
        dirty: () =>
            name.text != originalName || session.categoryId != originalCategory,
        valid: () => session.canApply,
        submit: session.apply,
        fields: (refresh, busy) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('resource-duplicate-name'),
              controller: name,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Nom de la copie'),
              onChanged: (value) {
                session.name = value;
                refresh();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('resource-duplicate-category'),
              initialValue: session.categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final entry in project.elementCategories)
                  DropdownMenuItem(value: entry.id, child: Text(entry.name)),
                if (!project.elementCategories.any(
                  (entry) => entry.id == session.categoryId,
                ))
                  DropdownMenuItem(
                    value: session.categoryId,
                    child: Text(
                      'Catégorie introuvable · ${session.categoryId}',
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) session.categoryId = value;
                      refresh();
                    },
            ),
            const SizedBox(height: 20),
            const Text(
              'Les images restent partagées et les instances déjà posées '
              'ne seront pas remplacées. La nouvelle définition pourra être '
              'modifiée indépendamment dans le préparateur de décor.',
            ),
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
  }
}
