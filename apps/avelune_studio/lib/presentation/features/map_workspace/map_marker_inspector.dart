import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_entity_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import 'healing_display_controls.dart';
import 'interactive_encounter_controls.dart';
import 'entity_presentation_controls.dart';

class MapMarkerInspector extends StatefulWidget {
  const MapMarkerInspector({
    super.key,
    required this.document,
    required this.project,
    required this.entity,
    required this.onChanged,
    required this.onDeleted,
    this.referenceGuard,
    this.elementPreview,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapEntity entity;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final MapReferenceGuard? referenceGuard;
  final Widget Function(ProjectElementEntry)? elementPreview;

  @override
  State<MapMarkerInspector> createState() => _MapMarkerInspectorState();
}

class _MapMarkerInspectorState extends State<MapMarkerInspector> {
  MapEntityEditingCommands get _commands => MapEntityEditingCommands(
    widget.document,
    widget.project,
    draftGuard: widget.referenceGuard,
  );

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

  String? get _deletionProblem => _commands.deletionProblem(widget.entity.id);

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final owner = '${widget.document.current.id}/${entity.id}';
    final spawn = entity.spawn;
    final sign = entity.sign;
    final blocked = _deletionProblem;
    final healingDisplay = entity.healingDisplay;
    final canConfigureHealingDisplay =
        entity.kind == MapEntityKind.custom &&
        !entity.blocksMovement &&
        entity.size.width == 1 &&
        entity.size.height == 1 &&
        entity.npc == null &&
        entity.sign == null &&
        entity.item == null &&
        entity.spawn == null &&
        entity.fieldObstacle == null &&
        entity.editorVisual == null &&
        !healingDisplayHasCollisionOverride(entity) &&
        widget.document.current.spatialScene == null &&
        widget.document.current.version != ProjectVersion.v9 &&
        widget.project.settings.dimension == ProjectDimension.twoD;
    final canConfigureFieldObstacle =
        entity.kind == MapEntityKind.custom &&
        entity.blocksMovement &&
        entity.size.width == 1 &&
        entity.size.height == 1 &&
        entity.npc == null &&
        entity.sign == null &&
        entity.item == null &&
        entity.spawn == null &&
        widget.document.current.spatialScene == null &&
        widget.document.current.version != ProjectVersion.v9 &&
        widget.project.settings.dimension == ProjectDimension.twoD &&
        entity.editorVisual != null &&
        widget.project.elements
                .where(
                  (element) => element.id == entity.editorVisual!.elementId,
                )
                .length ==
            1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntityPresentationControls(entity: entity, project: widget.project,
          map: widget.document.current,
          onChanged: (value) => _change(() => _commands.setPresentation(entity.id, value))),
        Text(
          spawn != null
              ? 'Point d’apparition'
              : entity.interactiveEncounter?.trigger == InteractiveEncounterTrigger.headbutt
              ? 'Arbre à Coud’Boule'
              : entity.fieldObstacle != null
              ? switch (entity.fieldObstacle!.kind) {
                  FieldObstacleKind.cutTree => 'Arbre à couper',
                  FieldObstacleKind.strengthBoulder => 'Rocher à pousser',
                  FieldObstacleKind.rockSmashRock => 'Rocher à briser',
                  FieldObstacleKind.iceBlock => 'Bloc de glace',
                }
              : healingDisplay != null
              ? 'Boules de soin'
              : 'Panneau',
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
        if (canConfigureHealingDisplay) ...[
          const SizedBox(height: 12),
          HealingDisplayControls(
            key: ValueKey('healing-display-${entity.id}'),
            entity: entity,
            project: widget.project,
            elementPreview: widget.elementPreview,
            onChanged: (display) =>
                _change(() => _commands.setHealingDisplay(entity.id, display)),
          ),
        ],
        if (canConfigureFieldObstacle && entity.interactiveEncounter?.trigger != InteractiveEncounterTrigger.headbutt) ...[
          const SizedBox(height: 12),
          for (final kind in FieldObstacleKind.values)
            StudioChoice(
              key: ValueKey(switch (kind) {
                FieldObstacleKind.cutTree => 'field-obstacle-cut-tree',
                FieldObstacleKind.strengthBoulder =>
                  'field-obstacle-strength-boulder',
                FieldObstacleKind.rockSmashRock =>
                  'field-obstacle-rock-smash-rock',
                FieldObstacleKind.iceBlock => 'field-obstacle-ice-block',
              }),
              label: switch (kind) {
                FieldObstacleKind.cutTree => 'Arbre à couper',
                FieldObstacleKind.strengthBoulder => 'Rocher à pousser',
                FieldObstacleKind.rockSmashRock => 'Rocher à briser',
                FieldObstacleKind.iceBlock => 'Bloc de glace',
              },
              subtitle: switch (kind) {
                FieldObstacleKind.cutTree =>
                  'Requiert Coupe débloquée et un Pokémon apte à l’utiliser.',
                FieldObstacleKind.strengthBoulder =>
                  'Requiert Force débloquée et un Pokémon apte à l’utiliser. Sur une zone Glissade, le rocher continue jusqu’à un obstacle ou la sortie de la zone.',
                FieldObstacleKind.rockSmashRock => 'Requiert Éclate-Roc débloquée et un Pokémon apte à l’utiliser.',
                FieldObstacleKind.iceBlock => 'Se pousse au contact, sans capacité. Sur la glace, continue jusqu’à un obstacle ou un sol normal.',
              },
              selected: entity.fieldObstacle?.kind == kind,
              onTap: entity.interactiveEncounter != null ? null : () => _change(
                () => _commands.setFieldObstacle(
                  entity.id,
                  entity.fieldObstacle?.kind == kind
                      ? null
                      : MapEntityFieldObstacleData(kind: kind, resetPolicy: kind == FieldObstacleKind.cutTree || kind == FieldObstacleKind.rockSmashRock ? entity.fieldObstacle?.resetPolicy ?? FieldObstacleResetPolicy.mapInstance : FieldObstacleResetPolicy.mapInstance),
                ),
              ),
            ),
          if (entity.fieldObstacle?.kind == FieldObstacleKind.cutTree || entity.fieldObstacle?.kind == FieldObstacleKind.rockSmashRock) ...[
            const SizedBox(height: 8),
            StudioSelect(
              key: const ValueKey('field-obstacle-reset'),
              label: 'Après utilisation', value: entity.fieldObstacle!.resetPolicy.name,
              options: const {'persistent': 'Conservé dans la sauvegarde', 'mapInstance': 'Réapparaît à la nouvelle instance'},
              onChanged: (value) => _change(() => _commands.setFieldObstacle(entity.id,
                MapEntityFieldObstacleData(kind: entity.fieldObstacle!.kind, resetPolicy: FieldObstacleResetPolicy.values.byName(value)))),
            ),
          ],
          if (entity.fieldObstacle != null) ...[
            const SizedBox(height: 6),
            Text(
              entity.fieldObstacle?.kind == FieldObstacleKind.strengthBoulder
                  ? 'Position et activation de Force : réinitialisées avec la carte.'
                  : entity.fieldObstacle!.resetPolicy == FieldObstacleResetPolicy.persistent ? 'L’obstacle utilisé reste retiré dans la sauvegarde.' : 'Réapparition : à la réinitialisation de la carte.',
            ),
          ],
        ],
        if (canConfigureFieldObstacle && (entity.fieldObstacle == null || entity.fieldObstacle?.kind == FieldObstacleKind.rockSmashRock)) ...[
          const SizedBox(height: 12),
          InteractiveEncounterControls(entity: entity, project: widget.project, onChanged: (payload) => _change(() => _commands.setInteractiveEncounter(entity.id, payload))),
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
              : entity.interactiveEncounter?.trigger == InteractiveEncounterTrigger.headbutt
              ? 'Supprimer cet arbre'
              : entity.fieldObstacle != null
              ? entity.fieldObstacle!.kind == FieldObstacleKind.iceBlock
                    ? 'Supprimer ce bloc'
                    : entity.fieldObstacle!.kind == FieldObstacleKind.cutTree
                    ? 'Supprimer cet arbre'
                    : 'Supprimer ce rocher'
              : healingDisplay != null
              ? 'Supprimer cet affichage de soin'
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
