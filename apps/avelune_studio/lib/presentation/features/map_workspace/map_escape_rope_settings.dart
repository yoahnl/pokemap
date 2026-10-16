import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'map_catalogue_form_dialog.dart';

Future<void> showEscapeRopeMapSettings(
  BuildContext context, {
  required MapData map,
  required ProjectManifest project,
  required Future<String?> Function(Map<String, Object?>) save,
}) {
  var dungeon = map.mapMetadata.escapeRopeDungeonId ?? '';
  var allowed = map.mapMetadata.allowEscapeRope;
  return showMapCatalogueForm(
    context,
    title: 'Corde Sortie',
    submitLabel: 'Enregistrer',
    valid: () =>
        dungeon.isEmpty || project.groups.any((group) => group.id == dungeon),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Associez explicitement les étages d’un même donjon. Le rangement des cartes dans la bibliothèque ne modifie pas ce choix.',
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Donjon de cette carte',
          value: dungeon,
          options: {
            '': 'Aucun donjon',
            for (final group in project.groups) group.id: group.name,
          },
          onChanged: busy
              ? null
              : (value) {
                  dungeon = value;
                  refresh();
                },
        ),
        const SizedBox(height: 12),
        StudioToggleRow(
          label: 'Autoriser la Corde Sortie sur cet étage',
          value: allowed,
          description: 'Le retour utilise l’entrée mémorisée du donjon. Disponible sur les cartes 2D, à pied.',
          onChanged: busy
              ? null
              : (value) {
                  allowed = value;
                  refresh();
                },
        ),
      ],
    ),
    submit: () => save({
      'mapId': map.id,
      'escapeRopeDungeonId': dungeon.isEmpty ? null : dungeon,
      'allowEscapeRope': allowed,
    }),
  );
}
