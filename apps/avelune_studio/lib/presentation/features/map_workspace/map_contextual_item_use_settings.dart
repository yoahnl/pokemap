import '../../../features/map_workspace/application/map_metadata_settings_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'map_catalogue_form_dialog.dart';

Future<void> showContextualItemUseSettings(
  BuildContext context, {
  required MapData map,
  required ProjectManifest project,
  required Map<String, String> items,
  required List<ContextualItemUseRule> rules,
  required ValueChanged<List<ContextualItemUseRule>> onChanged,
}) {
  final drafts = rules.map(MapContextualItemUseDraft.fromRule).toList();
  final scenes = {for (final scene in project.scenes) scene.id: scene.name};
  bool valid() => drafts.every((draft) => draft.isValid(map, items, scenes));
  return showMapCatalogueForm(
    context,
    title: 'Objets dans le décor',
    submitLabel: 'Appliquer aux paramètres',
    valid: valid,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Une règle correspondante lance sa scène avant l’effet habituel. Aucun objet n’est retiré automatiquement. La priorité la plus élevée gagne ; une égalité bloque l’utilisation.',
        ),
        for (final indexed in drafts.indexed) ...[
          const SizedBox(height: 16),
          Text(
            'Utilisation ${indexed.$1 + 1}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          StudioSelect(
            label: 'Objet ${indexed.$1 + 1}',
            value: indexed.$2.itemId,
            options: {
              ...items,
              if (indexed.$2.itemId.isNotEmpty &&
                  !items.containsKey(indexed.$2.itemId))
                indexed.$2.itemId: 'Objet absent : ${indexed.$2.itemId}',
            },
            onChanged: busy
                ? null
                : (value) {
                    indexed.$2.itemId = value;
                    refresh();
                  },
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Scène ${indexed.$1 + 1}',
            value: indexed.$2.sceneId,
            options: {
              ...scenes,
              if (indexed.$2.sceneId.isNotEmpty &&
                  !scenes.containsKey(indexed.$2.sceneId))
                indexed.$2.sceneId: 'Scène absente : ${indexed.$2.sceneId}',
            },
            onChanged: busy
                ? null
                : (value) {
                    indexed.$2.sceneId = value;
                    refresh();
                  },
          ),
          StudioToggleRow(
            label: 'Sur une case précise',
            value: indexed.$2.precise,
            onChanged: busy
                ? null
                : (value) {
                    indexed.$2.precise = value;
                    refresh();
                  },
          ),
          if (indexed.$2.precise)
            Row(
              children: [
                Expanded(
                  child: StudioDraftField(
                    key: ValueKey('${indexed.$2.id}-x'),
                    label: 'Case X',
                    value: indexed.$2.x,
                    enabled: !busy,
                    onChanged: (value) {
                      indexed.$2.x = value;
                      refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StudioDraftField(
                    key: ValueKey('${indexed.$2.id}-y'),
                    label: 'Case Y',
                    value: indexed.$2.y,
                    enabled: !busy,
                    onChanged: (value) {
                      indexed.$2.y = value;
                      refresh();
                    },
                  ),
                ),
              ],
            ),
          StudioSelect(
            label: 'Direction ${indexed.$1 + 1}',
            value: indexed.$2.facing,
            options: const {
              '': 'Toutes les directions',
              'north': 'Nord',
              'east': 'Est',
              'south': 'Sud',
              'west': 'Ouest',
            },
            onChanged: busy
                ? null
                : (value) {
                    indexed.$2.facing = value;
                    refresh();
                  },
          ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('${indexed.$2.id}-priority'),
            label: 'Priorité',
            value: indexed.$2.priority,
            enabled: !busy,
            onChanged: (value) {
              indexed.$2.priority = value;
              refresh();
            },
          ),
          if (indexed.$2.condition != null)
            const Text('La condition existante de cette règle est conservée.'),
          if (!indexed.$2.isValid(map, items, scenes))
            const Text(
              'Choisissez un objet et une scène existants, une case dans la carte et une priorité entière entre −1 000 000 et 1 000 000.',
            ),
          StudioButton(
            label: 'Retirer cette utilisation',
            secondary: true,
            onPressed: busy
                ? null
                : () {
                    drafts.removeAt(indexed.$1);
                    refresh();
                  },
          ),
        ],
        const SizedBox(height: 12),
        if (items.isEmpty || scenes.isEmpty)
          const Text(
            'Ajoutez des objets au catalogue Pokémon et une scène au projet pour créer une utilisation.',
          ),
        StudioButton(
          label: 'Ajouter une utilisation',
          secondary: true,
          onPressed:
              busy || drafts.length >= 128 || items.isEmpty || scenes.isEmpty
              ? null
              : () {
                  drafts.add(
                    MapContextualItemUseDraft(
                      'context-item-${DateTime.now().microsecondsSinceEpoch}-${drafts.length}',
                    ),
                  );
                  refresh();
                },
        ),
      ],
    ),
    submit: () async {
      onChanged([for (final draft in drafts) draft.toRule()]);
      return null;
    },
  );
}
