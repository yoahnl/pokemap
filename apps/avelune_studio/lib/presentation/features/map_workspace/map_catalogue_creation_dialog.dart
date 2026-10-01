import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_catalogue_form_dialog.dart';
import 'map_library_tree.dart';

typedef CreateMapFromForm =
    Future<String?> Function({
      required String name,
      required int width,
      required int height,
      required MapRole role,
      String? groupId,
      String? tilesetId,
    });

Future<void> showNewMapDialog(
  BuildContext context, {
  required ProjectManifest project,
  required CreateMapFromForm onCreate,
  String? initialGroupId,
  String Function()? submitLabel,
}) {
  var name = '',
      width = '${project.settings.defaultMapWidth}',
      height = '${project.settings.defaultMapHeight}',
      group = initialGroupId ?? '';
  var role = MapRole.exterior;
  var tileset = '';
  bool valid() =>
      name.trim().isNotEmpty &&
      (int.tryParse(width) ?? 0) > 0 &&
      (int.tryParse(height) ?? 0) > 0;
  return showMapCatalogueForm(
    context,
    title: 'Nouvelle carte',
    submitLabel: 'Créer la carte',
    currentSubmitLabel: submitLabel,
    valid: valid,
    submit: () => onCreate(
      name: name.trim(),
      width: int.parse(width),
      height: int.parse(height),
      role: role,
      groupId: group.isEmpty ? null : group,
      tilesetId: tileset.isEmpty ? null : tileset,
    ),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioDraftField(
          key: const ValueKey('new-map-name'),
          value: name,
          label: 'Nom de la carte',
          enabled: !busy,
          onChanged: (value) {
            name = value;
            refresh();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('new-map-width'),
                value: width,
                label: 'Largeur (cases)',
                enabled: !busy,
                errorText: (int.tryParse(width) ?? 0) > 0
                    ? null
                    : 'Entier positif requis',
                onChanged: (value) {
                  width = value;
                  refresh();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('new-map-height'),
                value: height,
                label: 'Hauteur (cases)',
                enabled: !busy,
                errorText: (int.tryParse(height) ?? 0) > 0
                    ? null
                    : 'Entier positif requis',
                onChanged: (value) {
                  height = value;
                  refresh();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Dossier de la carte',
          value: group,
          options: mapLibraryFolderLabels(project.groups),
          onChanged: busy
              ? null
              : (value) {
                  group = value;
                  refresh();
                },
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Rôle de la carte',
          value: role.name,
          options: {
            for (final value in MapRole.values) value.name: mapRoleLabel(value),
          },
          onChanged: busy
              ? null
              : (value) {
                  role = MapRole.values.byName(value);
                  refresh();
                },
        ),
        if (project.tilesets.isNotEmpty) ...[
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Planche par défaut',
            value: tileset,
            options: {
              '': 'Choix du projet',
              for (final entry in project.tilesets) entry.id: entry.name,
            },
            onChanged: busy
                ? null
                : (value) {
                    tileset = value;
                    refresh();
                  },
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Cases : ${project.settings.tileWidth} × ${project.settings.tileHeight} px · grille du projet',
        ),
        const SizedBox(height: 8),
        const Text(
          'La carte sera vide et éditable. Configurez ensuite son décor, ses passages et son départ pour y jouer.',
        ),
      ],
    ),
  );
}

String mapRoleLabel(MapRole role) => switch (role) {
  MapRole.exterior => 'Extérieur',
  MapRole.interior => 'Intérieur',
  MapRole.basement => 'Sous-sol',
  MapRole.upper_floor => 'Étage',
  MapRole.connector => 'Liaison',
  MapRole.gate => 'Entrée',
  MapRole.room => 'Pièce',
  MapRole.section => 'Section',
  MapRole.sub_area => 'Sous-zone',
};
