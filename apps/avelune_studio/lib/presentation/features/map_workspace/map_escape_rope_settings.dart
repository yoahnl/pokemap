import '../../../features/map_workspace/application/map_metadata_settings_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'map_catalogue_form_dialog.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_contextual_item_use_settings.dart';

Future<void> showEscapeRopeMapSettings(
  BuildContext context, {
  required MapData map,
  required ProjectManifest project,
  required Future<String?> Function(Map<String, Object?>) save,
  Future<Map<String, String>> Function()? loadItems,
}) {
  final draft = MapMetadataSettingsDraft(map);
  var loadingItems = false;
  String? itemError;
  return showMapCatalogueForm(
    context,
    title: 'Déplacements et Corde Sortie',
    submitLabel: 'Enregistrer',
    additionalBusy: () => loadingItems,
    valid: () => draft.valid(project),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioToggleRow(
          label: 'Autoriser le vélo',
          value: draft.bicycle,
          description: map.mapMetadata.isIndoor
              ? 'Les cartes intérieures interdisent toujours le vélo.'
              : 'Entrer dans une carte interdite remet automatiquement à pied.',
          onChanged: busy
              ? null
              : (value) {
                  draft.bicycle = value;
                  refresh();
                },
        ),
        const SizedBox(height: 12),
        const Text(
          'Associez explicitement les étages d’un même donjon. Le rangement des cartes dans la bibliothèque ne modifie pas ce choix.',
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Donjon de cette carte',
          value: draft.dungeon,
          options: {
            '': 'Aucun donjon',
            for (final group in project.groups) group.id: group.name,
          },
          onChanged: busy
              ? null
              : (value) {
                  draft.dungeon = value;
                  refresh();
                },
        ),
        const SizedBox(height: 12),
        StudioToggleRow(
          label: 'Autoriser la Corde Sortie sur cet étage',
          value: draft.allowed,
          description: 'Le retour utilise l’entrée mémorisée du donjon, sur les cartes 2D et 3D, à pied.',
          onChanged: busy
              ? null
              : (value) {
                  draft.allowed = value;
                  refresh();
                },
        ),
        const SizedBox(height: 16),
        Text('${draft.rules.length} utilisation(s) d’objets dans le décor'),
        if (itemError != null) Text(itemError!),
        StudioButton(
          label: 'Configurer les objets dans le décor',
          secondary: true,
          onPressed: busy || loadItems == null
              ? null
              : () async {
                  loadingItems = true;
                  itemError = null;
                  refresh();
                  try {
                    final items = await loadItems();
                    if (!context.mounted) return;
                    loadingItems = false;
                    refresh();
                    await showContextualItemUseSettings(
                      context,
                      map: map,
                      project: project,
                      items: items,
                      rules: draft.rules,
                      onChanged: (value) {
                        draft.rules = value;
                        draft.rulesEdited = true;
                      },
                    );
                  } on Object catch (error) {
                    itemError =
                        'Le catalogue des objets est indisponible : $error';
                  } finally {
                    loadingItems = false;
                    if (context.mounted) refresh();
                  }
                },
        ),
      ],
    ),
    submit: () => save(draft.parameters),
  );
}
