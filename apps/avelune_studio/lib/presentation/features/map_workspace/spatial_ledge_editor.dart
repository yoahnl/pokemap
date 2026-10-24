import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

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

  bool _commit(List<SpatialLedge> ledges) {
    if (widget.document.saving) return false;
    try {
      final map = widget.document.current;
      widget.document.commit(
        const SpatialMapOperations().configureNavigation(
          map,
          map.spatialScene!.navigation.copyWith(ledges: ledges),
          models: widget.project.models3d,
        ),
      );
      widget.document.error = null;
      widget.onChanged();
      setState(() {});
      return true;
    } on FormatException {
      widget.document.error = 'Le départ et l’arrivée doivent rester dans la carte. Un talus ne permet pas de monter. Vérifiez aussi la durée et la hauteur du saut.';
      widget.onChanged();
      setState(() {});
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.document.current.spatialScene!;
    final ledges = scene.navigation.ledges;
    final selected =
        ledges.where((ledge) => ledge.id == _selectedId).firstOrNull ??
        ledges.firstOrNull;
    bool edit(String key, Object value) {
      try {
        final next = SpatialLedge.fromJson({...selected!.toJson(), key: value});
        return _commit([
          for (final ledge in ledges)
            if (ledge.id == next.id) next else ledge,
        ]);
      } on Object {
        widget.document.error = 'Choisissez des coordonnées entières, une distance de 2 à 4 cases, une durée de 100 à 2000 ms et une hauteur de 0 à 4 cases.';
        widget.onChanged();
        return false;
      }
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
                  var number = 1;
                  while (ledges.any((ledge) => ledge.id == 'ledge-$number')) {
                    number++;
                  }
                  final id = 'ledge-$number';
                  final x = scene.navigation.spawn.x.floor();
                  final z = scene.navigation.spawn.z.floor();
                  final direction = z + 2 < scene.depth
                      ? SpatialRampDirection.south
                      : SpatialRampDirection.north;
                  if (_commit([
                    ...ledges,
                    SpatialLedge(id: id, x: x, z: z, direction: direction),
                  ]))
                    _selectedId = id;
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
                if (widget.document.saving) return false;
                final value = field.$1 == 'height'
                    ? double.tryParse(text.replaceAll(',', '.'))
                    : int.tryParse(text);
                return value != null && edit(field.$1, value);
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
