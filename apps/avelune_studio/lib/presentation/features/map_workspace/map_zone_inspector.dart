import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import 'map_zone_inspector_fields.dart';

class MapZoneInspector extends StatefulWidget {
  const MapZoneInspector({
    super.key,
    required this.document,
    required this.project,
    required this.zone,
    required this.onChanged,
    required this.onDeleted,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapGameplayZone zone;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;

  @override
  State<MapZoneInspector> createState() => _MapZoneInspectorState();
}

class _MapZoneInspectorState extends State<MapZoneInspector> {
  GameplayZoneEditingCommands get _commands =>
      GameplayZoneEditingCommands(widget.document, widget.project);

  void _change(VoidCallback action) {
    action();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final owner = '${widget.document.current.id}/${zone.id}';
    final problem = _commands.coverageProblem(zone);
    final area = zone.area;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Zone de jeu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '${area.size.width} × ${area.size.height} cases '
          'depuis ${area.pos.x}, ${area.pos.y}',
        ),
        if (zone.cellMask != null)
          Text('${zone.cellMask!.length} cases actives, avec trous possibles'),
        const SizedBox(height: 12),
        StudioCommitField(
          key: ValueKey('zone-name-$owner'),
          label: 'Nom',
          value: zone.name,
          onCommit: (value) => _change(() => _commands.rename(zone.id, value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<GameplayZoneKind>(
          key: ValueKey('zone-kind-${zone.id}-${zone.kind.name}'),
          initialValue: _commands.availableKindsFor(zone).contains(zone.kind)
              ? zone.kind
              : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Type'),
          items: [
            for (final kind in _commands.availableKindsFor(zone))
              DropdownMenuItem(
                value: kind,
                child: Text(
                  zoneKindLabel(kind),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (kind) => kind == null
              ? null
              : _change(() => _commands.retype(zone.id, kind)),
        ),
        if (zone.smartTileProvenance != null) ...[
          const SizedBox(height: 6),
          Text(
            'Cette zone suit un terrain automatique. Dessinez une zone indépendante pour utiliser Flash.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!_commands.supportsDarkness) ...[
          const SizedBox(height: 6),
          Text(
            'Flash et les zones sombres sont disponibles sur les cartes 2D uniquement.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (problem != null) ...[
          const SizedBox(height: 6),
          Text(
            problem,
            key: const ValueKey('zone-coverage-problem'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        ...zonePayloadFields(
          context: context,
          zone: zone,
          commands: _commands,
          onChanged: _change,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('zone-priority-${zone.id}-${zone.priority}'),
          initialValue: zone.priority.clamp(0, 3),
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Priorité'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Normale')),
            DropdownMenuItem(value: 1, child: Text('Au-dessus')),
            DropdownMenuItem(value: 2, child: Text('Haute')),
            DropdownMenuItem(value: 3, child: Text('Maximale')),
          ],
          onChanged: (priority) => priority == null
              ? null
              : _change(() => _commands.setPriority(zone.id, priority)),
        ),
        const SizedBox(height: 8),
        Text(
          zone.fieldAction?.actionKind == FieldActionZoneKind.waterfall
              ? 'L’entrée et la sortie restent accessibles. Le trajet est réservé à Cascade ; un passage occupé est refusé avant le départ puis revérifié à chaque pas.'
              : zone.fieldAction?.actionKind == FieldActionZoneKind.dive
              ? 'Les deux points de Plongée relient une arrivée de surface à une arrivée sous-marine. Enregistrez les deux cartes avant de les lier ; Délier annule cette publication.'
              : zone.kind == GameplayZoneKind.fieldAction
              ? 'Les zones sombres superposées restent indépendantes. Le voile le plus sombre s’applique ; Flash éclaire une seule zone à la fois.'
              : 'Quand deux zones se superposent, la priorité la plus haute gagne.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        StudioTool(
          label: 'Supprimer la zone',
          icon: Icons.delete_outline,
          onPressed: () {
            _change(() => _commands.delete(zone.id));
            widget.onDeleted();
          },
        ),
      ],
    );
  }
}
