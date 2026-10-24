import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

class CharacterAutonomyLimitsInspector extends StatefulWidget {
  const CharacterAutonomyLimitsInspector({
    super.key,
    required this.entity,
    required this.map,
    required this.movement,
    required this.onChanged,
  });
  final MapEntity entity;
  final MapData map;
  final MapEntityNpcMovementConfig movement;
  final ValueChanged<MapEntityNpcMovementConfig> onChanged;

  @override
  State<CharacterAutonomyLimitsInspector> createState() =>
      _CharacterAutonomyLimitsInspectorState();
}

class _CharacterAutonomyLimitsInspectorState
    extends State<CharacterAutonomyLimitsInspector> {
  String? _problem;

  bool _pause(int index, String raw) {
    final value = int.tryParse(raw);
    if (value == null || value < 0 || value > 3600000) {
      setState(
        () => _problem =
            'Chaque attente doit être comprise entre 0 et 3 600 000 ms.',
      );
      return false;
    }
    final values = widget.movement.pauseDurationsMs.toList()..[index] = value;
    setState(() => _problem = null);
    widget.onChanged(widget.movement.copyWith(pauseDurationsMs: values));
    return true;
  }

  bool _area(String field, String raw) {
    final value = int.tryParse(raw);
    final area = widget.movement.movementArea!;
    if (value == null) return false;
    final next = MapRect(
      pos: GridPos(
        x: field == 'x' ? value : area.pos.x,
        y: field == 'y' ? value : area.pos.y,
      ),
      size: GridSize(
        width: field == 'width' ? value : area.size.width,
        height: field == 'height' ? value : area.size.height,
      ),
    );
    if (next.pos.x < 0 ||
        next.pos.y < 0 ||
        next.size.width < 1 ||
        next.size.height < 1 ||
        next.pos.x + next.size.width > widget.map.size.width ||
        next.pos.y + next.size.height > widget.map.size.height) {
      setState(
        () => _problem = 'La zone doit rester dans les limites de la carte.',
      );
      return false;
    }
    setState(() => _problem = null);
    widget.onChanged(widget.movement.copyWith(movementArea: next));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final movement = widget.movement, area = widget.movement.movementArea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioChoice(
          key: const ValueKey('npc-random-pauses'),
          label: 'Choisir une attente au hasard',
          selected: movement.pauseDurationsMs.isNotEmpty,
          onTap: () => widget.onChanged(
            movement.copyWith(
              pauseDurationsMs: movement.pauseDurationsMs.isEmpty
                  ? const [500, 1000]
                  : const [],
            ),
          ),
        ),
        for (var index = 0; index < movement.pauseDurationsMs.length; index++)
          Row(
            children: [
              Expanded(
                child: StudioCommitField(
                  key: ValueKey('npc-pause-choice-$index'),
                  label: 'Attente possible ${index + 1} (ms)',
                  value: '${movement.pauseDurationsMs[index]}',
                  tryCommit: (raw) => _pause(index, raw),
                ),
              ),
              StudioTool(
                label: 'Retirer l’attente ${index + 1}',
                icon: Icons.remove_circle_outline,
                onPressed: () => widget.onChanged(
                  movement.copyWith(
                    pauseDurationsMs: movement.pauseDurationsMs.toList()
                      ..removeAt(index),
                  ),
                ),
              ),
            ],
          ),
        if (movement.pauseDurationsMs.isNotEmpty)
          StudioButton(
            label: 'Ajouter une attente possible',
            onPressed: movement.pauseDurationsMs.length >= 256
                ? null
                : () => widget.onChanged(
                    movement.copyWith(
                      pauseDurationsMs: [...movement.pauseDurationsMs, 1000],
                    ),
                  ),
          ),
        StudioChoice(
          key: const ValueKey('npc-limit-movement-area'),
          label: 'Limiter les déplacements à une zone fixe',
          selected: area != null,
          onTap: () {
            final width = math.min(3, widget.map.size.width),
                height = math.min(3, widget.map.size.height);
            widget.onChanged(
              movement.copyWith(
                movementArea: area == null
                    ? MapRect(
                        pos: GridPos(
                          x: (widget.entity.pos.x - 1).clamp(
                            0,
                            widget.map.size.width - width,
                          ),
                          y: (widget.entity.pos.y - 1).clamp(
                            0,
                            widget.map.size.height - height,
                          ),
                        ),
                        size: GridSize(width: width, height: height),
                      )
                    : null,
              ),
            );
          },
        ),
        if (area != null) ...[
          const Text(
            'Cette zone garde ses coordonnées lorsque le personnage se déplace ou reprend une partie.',
          ),
          for (final field in <String, (String, int)>{
            'x': ('Colonne de départ', area.pos.x),
            'y': ('Ligne de départ', area.pos.y),
            'width': ('Largeur (cases)', area.size.width),
            'height': ('Hauteur (cases)', area.size.height),
          }.entries)
            StudioCommitField(
              key: ValueKey('npc-movement-area-${field.key}'),
              label: field.value.$1,
              value: '${field.value.$2}',
              tryCommit: (raw) => _area(field.key, raw),
            ),
        ],
        if (_problem != null) Text(_problem!),
      ],
    );
  }
}
