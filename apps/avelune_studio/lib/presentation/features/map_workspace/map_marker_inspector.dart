import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_entity_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';

class MapMarkerInspector extends StatefulWidget {
  const MapMarkerInspector({
    super.key,
    required this.document,
    required this.project,
    required this.entity,
    required this.onChanged,
    required this.onDeleted,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEntity entity;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;

  @override
  State<MapMarkerInspector> createState() => _MapMarkerInspectorState();
}

class _MapMarkerInspectorState extends State<MapMarkerInspector> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  String? _appliedTo;

  MapEntityEditingCommands get _commands =>
      MapEntityEditingCommands(widget.document, widget.project);

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  void _syncFields() {
    final sign = widget.entity.sign;
    if (sign == null || _appliedTo == widget.entity.id) return;
    _appliedTo = widget.entity.id;
    _title.text = sign.title;
    _text.text = sign.plainText;
  }

  void _change(VoidCallback action) {
    action();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    _syncFields();
    final entity = widget.entity;
    final spawn = entity.spawn;
    final sign = entity.sign;
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
          TextField(
            key: const ValueKey('sign-title'),
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titre'),
            onSubmitted: (value) =>
                _change(() => _commands.updateSign(entity.id, title: value)),
            onTapOutside: (_) {
              if (_title.text != sign.title) {
                _change(
                  () => _commands.updateSign(entity.id, title: _title.text),
                );
              }
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('sign-text'),
            controller: _text,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(labelText: 'Texte affiché'),
            onTapOutside: (_) {
              if (_text.text != sign.plainText) {
                _change(
                  () => _commands.updateSign(entity.id, plainText: _text.text),
                );
              }
              FocusManager.instance.primaryFocus?.unfocus();
            },
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
        StudioTool(
          label: spawn != null ? 'Supprimer ce départ' : 'Supprimer le panneau',
          icon: Icons.delete_outline,
          onPressed: () {
            _change(() => _commands.delete(entity.id));
            widget.onDeleted();
          },
        ),
      ],
    );
  }
}
