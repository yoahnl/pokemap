import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';

class CharacterInspector extends StatefulWidget {
  const CharacterInspector({
    super.key,
    required this.document,
    required this.project,
    required this.entity,
    required this.visuals,
    required this.onChanged,
    required this.onSelect,
    required this.onEditInteraction,
    this.deletionBlocked = false,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEntity entity;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;
  final ValueChanged<String?> onSelect;
  final ValueChanged<MapEntity> onEditInteraction;
  final bool deletionBlocked;
  @override
  State<CharacterInspector> createState() => _CharacterInspectorState();
}

class _CharacterInspectorState extends State<CharacterInspector> {
  MapData? _inspectedMap;
  ProjectManifest? _inspectedProject;
  String? _deletionProblem;
  String? _inspectedId;
  late final _name = TextEditingController(
    text: widget.entity.inspectorHeadline,
  );
  CharacterEditingCommands get _commands =>
      CharacterEditingCommands(widget.document, widget.project);

  @override
  void didUpdateWidget(CharacterInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity != widget.entity &&
        _name.text != widget.entity.inspectorHeadline) {
      _name.text = widget.entity.inspectorHeadline;
    }
  }

  void _change(VoidCallback action) {
    try {
      action();
    } catch (error) {
      widget.document.error = error.toString();
    }
    widget.onChanged();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final npc = entity.npc!;
    final character = widget.project.characters
        .where((entry) => entry.id == npc.characterId)
        .firstOrNull;
    final visuals = widget.visuals;
    if (_inspectedMap != widget.document.current ||
        _inspectedProject != widget.project ||
        _inspectedId != entity.id) {
      _inspectedMap = widget.document.current;
      _inspectedProject = widget.project;
      _inspectedId = entity.id;
      _deletionProblem = _commands.deletionProblem(entity.id);
    }
    final deletionProblem = widget.deletionBlocked
        ? 'Une interaction non enregistrée utilise ce personnage.'
        : _deletionProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Personnage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (character != null && visuals is CharacterWorkspaceVisuals)
          StudioAssetPreview(
            height: 104,
            child: (visuals as CharacterWorkspaceVisuals).characterThumbnail(
              character,
              size: 96,
              facing: npc.facing,
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('character-name'),
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nom de cette instance'),
          onSubmitted: (name) =>
              _change(() => _commands.update(entity.id, name: name)),
          onTapOutside: (_) {
            if (_name.text != entity.inspectorHeadline) {
              _change(() => _commands.update(entity.id, name: _name.text));
            }
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
        const SizedBox(height: 8),
        Text('Sprite partagé : ${character?.name ?? 'ressource manquante'}'),
        Text(
          'Carte : ${widget.document.current.name} · ${entity.pos.x}, ${entity.pos.y}',
        ),
        const SizedBox(height: 8),
        Text(
          'La profondeur du personnage suit sa position dans le jeu, indépendamment de l’empilement des décors.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<EntityFacing>(
          key: ValueKey('facing-${entity.id}-${npc.facing.name}'),
          initialValue: npc.facing,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Orientation'),
          items: [
            for (final facing in EntityFacing.values)
              DropdownMenuItem(
                value: facing,
                child: Text(switch (facing) {
                  EntityFacing.north => 'Vers le haut',
                  EntityFacing.south => 'Vers le bas',
                  EntityFacing.west => 'Vers la gauche',
                  EntityFacing.east => 'Vers la droite',
                }),
              ),
          ],
          onChanged: (facing) =>
              _change(() => _commands.update(entity.id, facing: facing)),
        ),
        const SizedBox(height: 8),
        StudioChoice(
          label: 'Bloque le passage',
          selected: entity.blocksMovement,
          onTap: () => _change(
            () => _commands.update(entity.id, blocks: !entity.blocksMovement),
          ),
        ),
        const SizedBox(height: 18),
        Text('Interaction', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        const Text('Quand le joueur lui parle'),
        const SizedBox(height: 8),
        StudioButton(
          label: 'Écrire son interaction',
          onPressed: () => widget.onEditInteraction(entity),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            StudioTool(
              label: 'Dupliquer le personnage',
              icon: Icons.copy,
              onPressed: () => _change(
                () => widget.onSelect(_commands.duplicate(entity.id).id),
              ),
            ),
            StudioTool(
              label: 'Supprimer le personnage',
              icon: Icons.delete_outline,
              onPressed: deletionProblem == null
                  ? () => _change(() {
                      _commands.delete(entity.id);
                      widget.onSelect(null);
                    })
                  : null,
            ),
          ],
        ),
        if (deletionProblem != null) ...[
          const SizedBox(height: 8),
          Text(deletionProblem),
        ],
      ],
    );
  }
}
