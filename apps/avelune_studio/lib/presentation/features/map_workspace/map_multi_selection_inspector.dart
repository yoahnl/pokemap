import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_decor_group_editing.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import 'map_workspace_view_state.dart';

class MapMultiSelectionInspector extends StatelessWidget {
  const MapMultiSelectionInspector({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  String _format(num value) => value is int || value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);

  bool _commit(
    MapDecorGroupEditing editing,
    List<String> ids,
    String raw, {
    required bool horizontal,
  }) {
    final value = num.tryParse(raw.trim().replaceAll(',', '.'));
    if (value == null) return false;
    final moved = horizontal
        ? editing.move(ids, x: value)
        : editing.move(ids, y: value);
    onChanged();
    return moved;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = view.selectedDecorIds(document.current.id).toList();
    final editing = MapDecorGroupEditing(document, project);
    final summary = editing.summarize(ids);
    final spatial = document.current.spatialScene != null;
    final locked = summary.lockedIds.length;
    return SingleChildScrollView(
      key: const ValueKey('map-multi-selection-inspector'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sélection', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            '${summary.ids.length} décors sélectionnés',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Carte : ${document.current.name} · les modifications ne touchent que ces occurrences.',
            style: theme.textTheme.bodySmall,
          ),
          if (locked > 0) ...[
            const SizedBox(height: 8),
            StudioNotice(
              locked == 1
                  ? '1 décor verrouillé sera conservé tel quel.'
                  : '$locked décors verrouillés seront conservés tels quels.',
            ),
          ],
          const SizedBox(height: 12),
          StudioCommitField(
            key: const ValueKey('map-multi-selection-x'),
            label: spatial ? 'Position X' : 'Colonne (X)',
            value: summary.x == null ? '' : _format(summary.x!),
            hint: summary.mixedX ? 'Valeurs différentes' : null,
            tryCommit: (raw) => _commit(editing, ids, raw, horizontal: true),
          ),
          const SizedBox(height: 10),
          StudioCommitField(
            key: const ValueKey('map-multi-selection-y'),
            label: spatial ? 'Position Z' : 'Ligne (Y)',
            value: summary.y == null ? '' : _format(summary.y!),
            hint: summary.mixedY ? 'Valeurs différentes' : null,
            tryCommit: (raw) => _commit(editing, ids, raw, horizontal: false),
          ),
          if (document.error case final error?) ...[
            const SizedBox(height: 8),
            StudioNotice(error, isError: true),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('map-multi-selection-remove'),
                label: summary.editableIds.length == summary.ids.length
                    ? 'Retirer de la carte'
                    : 'Retirer les décors modifiables',
                icon: Icons.delete_outline,
                secondary: true,
                onPressed: summary.editableIds.isEmpty
                    ? null
                    : () {
                        editing.remove(summary.editableIds);
                        view.clearSelection(document);
                        onChanged();
                      },
              ),
              StudioButton(
                key: const ValueKey('map-multi-selection-duplicate'),
                label: 'Dupliquer',
                icon: Icons.copy_all_outlined,
                secondary: true,
                onPressed: summary.editableIds.isEmpty
                    ? null
                    : () {
                        final copies = editing.duplicate(summary.editableIds);
                        if (copies != null && copies.isNotEmpty) {
                          view.select(
                            document,
                            MapSelectionFamily.decor,
                            copies.first,
                          );
                          for (final id in copies.skip(1)) {
                            view.toggleDecorInSelection(document, id);
                          }
                        }
                        onChanged();
                      },
              ),
              if (editing.canRotate)
                for (final (label, degrees) in const [
                  ('↺ 90°', -90.0),
                  ('↻ 90°', 90.0),
                ])
                  StudioButton(
                    key: ValueKey('map-multi-selection-rotate-$degrees'),
                    label: label,
                    secondary: true,
                    onPressed: summary.editableIds.isEmpty
                        ? null
                        : () {
                            editing.rotate(summary.editableIds, degrees);
                            onChanged();
                          },
                  ),
              StudioButton(
                key: const ValueKey('map-multi-selection-clear'),
                label: 'Tout désélectionner',
                variant: StudioButtonVariant.quiet,
                onPressed: () {
                  view.clearSelection(document);
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Maj ou ⌘ + clic sur la carte ou dans Contenu de la carte ajoute ou retire un décor de la sélection.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
