import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';

Future<void> showResourceDuplicate(
  BuildContext context, {
  required ResourceItem item,
  required ProjectManifest project,
  required Future<String?> Function(String name, String categoryId) save,
  required bool Function() canApply,
}) async {
  final originalName = '${item.name} — copie';
  final name = TextEditingController(text: originalName);
  var category = item.category;
  try {
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: 'Dupliquer la définition de décor',
        submitLabel: 'Créer la copie',
        dirty: () => name.text != originalName || category != item.category,
        valid: () =>
            canApply() && name.text.trim().isNotEmpty && category.isNotEmpty,
        submit: () => save(name.text, category),
        fields: (refresh, busy) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('resource-duplicate-name'),
              controller: name,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Nom de la copie'),
              onChanged: (_) => refresh(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('resource-duplicate-category'),
              initialValue: category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final entry in project.elementCategories)
                  DropdownMenuItem(value: entry.id, child: Text(entry.name)),
                if (!project.elementCategories.any(
                  (entry) => entry.id == category,
                ))
                  DropdownMenuItem(
                    value: category,
                    child: Text('Catégorie introuvable · $category'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) category = value;
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
