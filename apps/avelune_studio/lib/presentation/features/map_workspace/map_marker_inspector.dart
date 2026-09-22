import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_entity_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

class MapMarkerInspector extends StatefulWidget {
  const MapMarkerInspector({
    super.key,
    required this.document,
    required this.project,
    required this.entity,
    required this.onChanged,
    required this.onDeleted,
    this.draftBlocked,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEntity entity;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final bool Function(String)? draftBlocked;

  @override
  State<MapMarkerInspector> createState() => _MapMarkerInspectorState();
}

class _MapMarkerInspectorState extends State<MapMarkerInspector> {
  MapEntityEditingCommands get _commands =>
      MapEntityEditingCommands(widget.document, widget.project);

  void _change(VoidCallback action) {
    try {
      action();
    } catch (error) {
      widget.document.error = error is StateError
          ? error.message
          : error.toString();
    }
    widget.onChanged();
  }

  String? get _deletionProblem =>
      _commands.deletionProblem(widget.entity.id) ??
      (widget.draftBlocked?.call(widget.entity.id) == true
          ? 'Une interaction en cours d’écriture utilise cet élément. '
                'Enregistrez-la ou retirez sa liaison avant de le supprimer.'
          : null);

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final owner = '${widget.document.current.id}/${entity.id}';
    final spawn = entity.spawn;
    final sign = entity.sign;
    final blocked = _deletionProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spawn != null ? 'Point d’apparition' : 'Panneau',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.document.current.name} · ${entity.pos.x}, ${entity.pos.y}',
        ),
        const SizedBox(height: 12),
        if (spawn != null) ...[
          DropdownButtonFormField<EntitySpawnRole>(
            key: ValueKey('spawn-role-${entity.id}-${spawn.role.name}'),
            initialValue: spawn.role,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Rôle'),
            items: const [
              DropdownMenuItem(
                value: EntitySpawnRole.playerStart,
                child: Text(
                  'Départ du joueur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: EntitySpawnRole.npcSpawn,
                child: Text(
                  'Apparition PNJ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: EntitySpawnRole.event,
                child: Text(
                  'Événement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: EntitySpawnRole.debug,
                child: Text(
                  'Mise au point',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (role) => role == null
                ? null
                : _change(() => _commands.updateSpawn(entity.id, role: role)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EntityFacing>(
            key: ValueKey('spawn-facing-${entity.id}-${spawn.facing.name}'),
            initialValue: spawn.facing,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Regard'),
            items: const [
              DropdownMenuItem(
                value: EntityFacing.north,
                child: Text('Vers le haut'),
              ),
              DropdownMenuItem(
                value: EntityFacing.south,
                child: Text('Vers le bas'),
              ),
              DropdownMenuItem(
                value: EntityFacing.west,
                child: Text('Vers la gauche'),
              ),
              DropdownMenuItem(
                value: EntityFacing.east,
                child: Text('Vers la droite'),
              ),
            ],
            onChanged: (facing) => facing == null
                ? null
                : _change(
                    () => _commands.updateSpawn(entity.id, facing: facing),
                  ),
          ),
          if (spawn.role == EntitySpawnRole.playerStart) ...[
            const SizedBox(height: 8),
            Text(
              'Le jeu démarre ici. Une carte sans départ du joueur ne peut pas '
              'être jouée.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        if (sign != null) ...[
          StudioCommitField(
            key: ValueKey('sign-title-$owner'),
            label: 'Titre',
            value: sign.title,
            onCommit: (value) =>
                _change(() => _commands.updateSign(entity.id, title: value)),
          ),
          const SizedBox(height: 12),
          StudioCommitField(
            key: ValueKey('sign-text-$owner'),
            label: 'Texte affiché',
            value: sign.plainText,
            maxLines: 4,
            onCommit: (value) => _change(
              () => _commands.updateSign(entity.id, plainText: value),
            ),
          ),
          const SizedBox(height: 12),
          StudioChoice(
            label: 'Bloque le passage',
            selected: entity.blocksMovement,
            onTap: () => _change(
              () => _commands.setBlocking(
                entity.id,
                blocks: !entity.blocksMovement,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (blocked != null) ...[
          Text(
            blocked,
            key: const ValueKey('marker-deletion-problem'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        StudioTool(
          label: blocked != null
              ? 'Suppression bloquée par l’histoire'
              : spawn != null
              ? 'Supprimer ce départ'
              : 'Supprimer le panneau',
          icon: Icons.delete_outline,
          onPressed: blocked != null
              ? null
              : () {
                  _change(() => _commands.delete(entity.id));
                  widget.onDeleted();
                },
        ),
      ],
    );
  }
}
