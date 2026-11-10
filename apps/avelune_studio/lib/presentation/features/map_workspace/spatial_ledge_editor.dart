import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/spatial_ledge_editing_commands.dart';

import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

import 'package:avelune_studio/features/map_workspace/application/traversal_labels.dart';

class SpatialLedgeEditor extends StatefulWidget {
  const SpatialLedgeEditor({
    super.key,
    required this.document,
    required this.project,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final VoidCallback onChanged;
  @override
  State<SpatialLedgeEditor> createState() => _SpatialLedgeEditorState();
}

class _SpatialLedgeEditorState extends State<SpatialLedgeEditor> {
  String? _selectedId;

  SpatialLedgeEditingCommands get _commands =>
      SpatialLedgeEditingCommands(widget.document, widget.project);

  bool _commit(List<SpatialLedge> ledges) {
    final committed = _commands.configure(ledges);
    widget.onChanged();
    setState(() {});
    return committed;
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.document.current.spatialScene!;
    final ledges = scene.navigation.ledges;
    final selected =
        ledges.where((ledge) => ledge.id == _selectedId).firstOrNull ??
        ledges.firstOrNull;
    bool edit(String key, Object value) {
      final committed = _commands.edit(selected!, ledges, key, value);
      widget.onChanged();
      setState(() {});
      return committed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Talus à sens unique',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const StudioNotice(
          'Le joueur saute automatiquement depuis la case de départ vers une arrivée libre. Le retour est bloqué. Le Pokémon compagnon suit le même trajet.',
        ),
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('spatial-ledge-add'),
          label: 'Ajouter un talus',
          onPressed: widget.document.saving
              ? null
              : () {
                  final ledge = _commands.next();
                  if (_commit([...ledges, ledge])) {
                    _selectedId = ledge.id;
                  }
                },
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Talus',
            value: selected.id,
            options: {
              for (var i = 0; i < ledges.length; i++)
                ledges[i].id:
                    'Talus ${i + 1} · X ${ledges[i].x}, Y ${ledges[i].z}',
            },
            onChanged: widget.document.saving
                ? null
                : (id) => setState(() => _selectedId = id),
          ),
          for (final field in [
            ('x', 'Départ X'),
            ('z', 'Départ Y'),
            ('distance', 'Distance (cases)'),
            ('durationMs', 'Durée (ms)'),
            ('height', 'Hauteur du saut (cases)'),
          ]) ...[
            const SizedBox(height: 8),
            StudioCommitField(
              key: ValueKey('spatial-ledge-${field.$1}'),
              label: field.$2,
              value: '${selected.toJson()[field.$1]}',
              tryCommit: (text) {
                final result = _commands.editText(
                  selected,
                  ledges,
                  field.$1,
                  text,
                );
                widget.onChanged();
                setState(() {});
                return result;
              },
            ),
          ],
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Sens du saut',
            value: selected.direction.name,
            options: const {
              'north': 'Vers le haut',
              'south': 'Vers le bas',
              'east': 'Vers la droite',
              'west': 'Vers la gauche',
            },
            onChanged: widget.document.saving
                ? null
                : (value) => edit('direction', value),
          ),
          const SizedBox(height: 8),
          Text('Arrivée : X ${selected.landingX}, Y ${selected.landingZ}'),
          Text(
            spatialLedgeSummary(selected),
            key: const ValueKey('spatial-ledge-summary'),
          ),
          StudioButton(
            key: const ValueKey('spatial-ledge-delete'),
            label: 'Retirer ce talus',
            onPressed: widget.document.saving
                ? null
                : () => _commit(
                    ledges.where((ledge) => ledge.id != selected.id).toList(),
                  ),
          ),
        ],
      ],
    );
  }
}
