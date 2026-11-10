import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_catalogue_form_dialog.dart';
import '../../../features/map_workspace/application/map_catalogue_choices.dart';

export '../../../features/map_workspace/application/map_catalogue_choices.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';

typedef CreateMapFromForm = Future<String?> Function({
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
  final spatial = project.settings.dimension == ProjectDimension.threeD;
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
      tilesetId: spatial || tileset.isEmpty ? null : tileset,
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
        if (spatial) ...[
          const SizedBox(height: 12),
          const Text(
            'Une carte 3D n’utilise pas de planche de tuiles : son sol se peint ensuite avec les terrains du projet.',
          ),
        ] else if (project.tilesets.isNotEmpty) ...[
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Planche par défaut',
            value: tileset,
            options: newMapSheetOptions(project),
            onChanged: busy
                ? null
                : (value) {
                    tileset = value;
                    refresh();
                  },
          ),
          const SizedBox(height: 6),
          const Text(
            'Elle sert aux tuiles de cette carte qui ne désignent pas leur propre planche. La palette Tuiles garde toutes les planches du projet.',
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
