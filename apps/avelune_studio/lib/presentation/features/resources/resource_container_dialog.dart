import 'package:flutter/material.dart';
import 'resource_catalog.dart';
import 'resource_containers.dart';
import 'resource_management_dialog.dart';

Future<void> showResourceContainerEditor(
  BuildContext context, {
  required ResourceKind family,
  required List<ResourceContainer> containers,
  required Future<String?> Function(
    String action,
    Map<String, Object?> parameters,
  )
  save,
  ResourceContainer? initial,
}) async {
  final name = TextEditingController(text: initial?.name ?? '');
  var parent = initial?.parentId;
  final id =
      initial?.id ??
      'studio_${family.name}_${DateTime.now().microsecondsSinceEpoch}';
  final noun = containerTitle(family);
  try {
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: initial == null
            ? '${family == ResourceKind.images ? 'Nouveau' : 'Nouvelle'} $noun'
            : 'Modifier ${family == ResourceKind.images ? 'le' : 'la'} $noun',
        submitLabel: initial == null ? 'Créer' : 'Enregistrer',
        dirty: () =>
            name.text != (initial?.name ?? '') || parent != initial?.parentId,
        valid: () => name.text.trim().isNotEmpty,
        submit: () => save(
          containerAction(family, 'upsert'),
          containerParameters(
            family,
            ResourceContainer(id, name.text, parent, initial?.sortOrder ?? 0),
          ),
        ),
        fields: (refresh, busy) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('resource-container-name'),
              controller: name,
              enabled: !busy,
              decoration: InputDecoration(
                labelText:
                    'Nom ${family == ResourceKind.images ? 'du' : 'de la'} $noun',
              ),
              onChanged: (_) => refresh(),
            ),
            if (family != ResourceKind.terrains) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('resource-container-parent'),
                initialValue: parent ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Parent'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('À la racine')),
                  for (final entry in containers.where(
                    (entry) => entry.id != id,
                  ))
                    DropdownMenuItem(value: entry.id, child: Text(entry.name)),
                  if (parent != null &&
                      !containers.any(
                        (entry) => entry.id == parent && entry.id != id,
                      ))
                    DropdownMenuItem(
                      value: parent,
                      enabled: false,
                      child: Text('Parent introuvable · $parent'),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        parent = value == '' ? null : value;
                        refresh();
                      },
              ),
            ] else ...[
              const SizedBox(height: 16),
              const Text(
                'Les catégories de terrains sont une liste, sans parent.',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Ce rangement ne déplace aucun fichier image et ne modifie '
              'pas la portée des ressources dans le jeu.',
            ),
            if (initial != null) ...[
              const SizedBox(height: 12),
              SelectableText('Identifiant : ${initial.id}'),
            ],
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
  }
}

Future<void> showResourceMove(
  BuildContext context, {
  required ResourceItem item,
  required List<ResourceContainer> containers,
  required Future<String?> Function(
    String action,
    Map<String, Object?> parameters,
  )
  save,
}) async {
  var destination = item.category;
  await showResourceManagementRoute(
    context,
    (_) => ResourceManagementDialog(
      title: 'Déplacer « ${item.name} »',
      submitLabel: 'Déplacer',
      dirty: () => destination != item.category,
      valid: () => item.kind != ResourceKind.decors || destination.isNotEmpty,
      submit: () {
        final (action, parameters) = resourceMoveParameters(
          item,
          destination.isEmpty ? null : destination,
        );
        return save(action, parameters);
      },
      fields: (refresh, busy) => DropdownButtonFormField<String>(
        key: const ValueKey('resource-move-destination'),
        initialValue: destination,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Destination'),
        items: [
          if (item.kind == ResourceKind.decors && destination.isEmpty)
            const DropdownMenuItem(
              value: '',
              enabled: false,
              child: Text('Destination requise'),
            ),
          if (item.kind != ResourceKind.decors)
            DropdownMenuItem(
              value: '',
              child: Text(
                item.kind == ResourceKind.images
                    ? 'Sans dossier'
                    : 'Sans catégorie',
              ),
            ),
          for (final entry in containers)
            DropdownMenuItem(value: entry.id, child: Text(entry.name)),
          if (destination.isNotEmpty &&
              !containers.any((entry) => entry.id == destination))
            DropdownMenuItem(
              value: destination,
              child: Text('Destination introuvable · $destination'),
            ),
        ],
        onChanged: busy
            ? null
            : (value) {
                if (value != null) destination = value;
                refresh();
              },
      ),
    ),
  );
}
