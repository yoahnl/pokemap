import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class CharacterFixedRouteInspector extends StatefulWidget {
  const CharacterFixedRouteInspector({
    super.key,
    required this.entity,
    required this.map,
    required this.project,
    required this.onChanged,
  });

  final MapEntity entity;
  final MapData map;
  final ProjectManifest project;
  final ValueChanged<MapEntityNpcMovementConfig> onChanged;

  @override
  State<CharacterFixedRouteInspector> createState() =>
      _CharacterFixedRouteInspectorState();
}

class _CharacterFixedRouteInspectorState
    extends State<CharacterFixedRouteInspector> {
  String? _problem;
  MapEntityNpcMovementConfig get _movement => widget.entity.npc!.movement;
  bool get _twoD =>
      widget.map.spatialScene == null &&
      widget.map.version != ProjectVersion.v9 &&
      widget.project.settings.dimension == ProjectDimension.twoD;

  void _change(MapEntityNpcMovementConfig movement) {
    widget.onChanged(
      movement.copyWith(
        routeSteps: List.unmodifiable(movement.routeSteps),
        waypoints: List.unmodifiable(movement.waypoints),
      ),
    );
  }

  void _steps(List<MapEntityNpcRouteStep> steps) =>
      _change(_movement.copyWith(routeSteps: steps));

  EntityFacing _direction(MapEntityNpcRouteStep step) => switch (step) {
    MapEntityNpcMoveStep(:final direction) => direction,
    MapEntityNpcFaceStep(:final direction) => direction,
    MapEntityNpcRandomFacingStep() ||
    MapEntityNpcRandomMoveStep() => widget.entity.npc!.facing,
  };

  MapEntityNpcRouteStep _step(
    MapEntityNpcRouteStepKind kind,
    EntityFacing direction,
  ) => switch (kind) {
    MapEntityNpcRouteStepKind.move => MapEntityNpcRouteStep.move(
      direction: direction,
    ),
    MapEntityNpcRouteStepKind.face => MapEntityNpcRouteStep.face(
      direction: direction,
    ),
    MapEntityNpcRouteStepKind.randomFacing =>
      const MapEntityNpcRouteStep.randomFacing(),
    MapEntityNpcRouteStepKind.randomMove =>
      const MapEntityNpcRouteStep.randomMove(),
  };

  bool _time(String raw, {required bool pause}) {
    final value = int.tryParse(raw);
    if (value == null ||
        value < (pause ? 0 : 1) ||
        value > (pause ? 3600000 : 60000)) {
      setState(
        () => _problem = pause
            ? 'L’attente doit être comprise entre 0 et 3 600 000 ms.'
            : 'La durée du pas doit être comprise entre 1 et 60 000 ms.',
      );
      return false;
    }
    setState(() => _problem = null);
    _change(
      pause
          ? _movement.copyWith(pauseDurationMs: value)
          : _movement.copyWith(stepDurationMs: value),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final movement = _movement;
    final choices = <String, (MapEntityNpcRouteInstanceBoolean?, String)>{
      'none': (null, 'Ne pas suspendre'),
    };
    for (final scene in widget.project.scenes) {
      for (final node in scene.graph.nodes) {
        final payload = node.payload;
        if (payload is! SceneActionPayload ||
            payload.consequence
                is! SceneSetMapEventInstanceBooleanConsequence) {
          continue;
        }
        final consequence =
            payload.consequence as SceneSetMapEventInstanceBooleanConsequence;
        if (consequence.mapId != widget.map.id ||
            consequence.eventId != widget.entity.id) {
          continue;
        }
        final binding = MapEntityNpcRouteInstanceBoolean(
          key: consequence.key,
          value: consequence.value,
        );
        choices['${binding.key}:${binding.value}'] = (
          binding,
          '${consequence.label ?? scene.name}${binding.value ? '' : ' (désactivée)'}',
        );
      }
    }
    final current = movement.suspendWhenInstanceBoolean;
    final selected = current == null
        ? 'none'
        : '${current.key}:${current.value}';
    if (current != null && !choices.containsKey(selected)) {
      choices[selected] = (current, 'Condition existante de ce personnage');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('npc-movement-mode'),
          label: 'Déplacement autonome',
          value: movement.mode.name,
          options: {
            'idle': 'Immobile',
            'scriptedOnly': 'Seulement pendant une interaction',
            if (movement.mode == MapEntityNpcMovementMode.patrol)
              'patrol': 'Patrouille existante',
            if (_twoD || movement.mode == MapEntityNpcMovementMode.fixedRoute)
              'fixedRoute': 'Suite de pas',
          },
          onChanged: (name) {
            if (name == movement.mode.name) return;
            final mode = MapEntityNpcMovementMode.values.byName(name);
            _change(
              movement.copyWith(
                mode: mode,
                waypoints: mode == MapEntityNpcMovementMode.fixedRoute
                    ? const []
                    : movement.waypoints,
                routeSteps: mode == MapEntityNpcMovementMode.fixedRoute
                    ? [
                        MapEntityNpcRouteStep.move(
                          direction: widget.entity.npc!.facing,
                        ),
                      ]
                    : const [],
                suspendWhenInstanceBoolean: null,
              ),
            );
          },
        ),
        if (movement.mode == MapEntityNpcMovementMode.fixedRoute && !_twoD)
          const Text('Les suites de pas sont disponibles sur les cartes 2D.'),
        if (movement.mode == MapEntityNpcMovementMode.fixedRoute && _twoD) ...[
          const SizedBox(height: 8),
          StudioChoice(
            label: 'Répéter la suite',
            selected: movement.loop,
            onTap: () => _change(movement.copyWith(loop: !movement.loop)),
          ),
          StudioCommitField(
            key: const ValueKey('npc-fixed-route-pause'),
            label: 'Attente initiale et entre les actions (ms)',
            value: '${movement.pauseDurationMs}',
            tryCommit: (raw) => _time(raw, pause: true),
          ),
          StudioCommitField(
            key: const ValueKey('npc-fixed-route-duration'),
            label: 'Durée d’un pas (ms)',
            value: '${movement.stepDurationMs}',
            tryCommit: (raw) => _time(raw, pause: false),
          ),
          if (_problem != null) Text(_problem!),
          const SizedBox(height: 8),
          const Text(
            'Un pas bloqué est réessayé, sans détour. Les dialogues et menus mettent la suite en pause.',
          ),
          const SizedBox(height: 8),
          StudioSelect(
            key: const ValueKey('npc-fixed-route-suspension'),
            label: 'Suspendre avec une condition de ce personnage',
            value: selected,
            options: {
              for (final choice in choices.entries) choice.key: choice.value.$2,
            },
            onChanged: (id) => _change(
              movement.copyWith(suspendWhenInstanceBoolean: choices[id]!.$1),
            ),
          ),
          for (var index = 0; index < movement.routeSteps.length; index++) ...[
            const SizedBox(height: 8),
            StudioSelect(
              key: ValueKey('npc-fixed-route-kind-$index'),
              label: 'Action ${index + 1}',
              value: movement.routeSteps[index].kind.name,
              options: const {
                'move': 'Avancer',
                'face': 'Se tourner',
                'randomFacing': 'Direction aléatoire',
                'randomMove': 'Pas aléatoire',
              },
              onChanged: (name) {
                final steps = movement.routeSteps.toList();
                steps[index] = _step(
                  MapEntityNpcRouteStepKind.values.byName(name),
                  _direction(steps[index]),
                );
                _steps(steps);
              },
            ),
            if (!const {
              MapEntityNpcRouteStepKind.randomFacing,
              MapEntityNpcRouteStepKind.randomMove,
            }.contains(movement.routeSteps[index].kind))
              StudioSelect(
                key: ValueKey('npc-fixed-route-direction-$index'),
                label: 'Direction ${index + 1}',
                value: _direction(movement.routeSteps[index]).name,
                options: const {
                  'north': 'Nord',
                  'south': 'Sud',
                  'east': 'Est',
                  'west': 'Ouest',
                },
                onChanged: (name) {
                  final steps = movement.routeSteps.toList();
                  steps[index] = _step(
                    steps[index].kind,
                    EntityFacing.values.byName(name),
                  );
                  _steps(steps);
                },
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StudioTool(
                  label: 'Monter l’action ${index + 1}',
                  icon: Icons.arrow_upward,
                  onPressed: index == 0
                      ? null
                      : () {
                          final steps = movement.routeSteps.toList();
                          final step = steps.removeAt(index);
                          steps.insert(index - 1, step);
                          _steps(steps);
                        },
                ),
                StudioTool(
                  label: 'Descendre l’action ${index + 1}',
                  icon: Icons.arrow_downward,
                  onPressed: index == movement.routeSteps.length - 1
                      ? null
                      : () {
                          final steps = movement.routeSteps.toList();
                          final step = steps.removeAt(index);
                          steps.insert(index + 1, step);
                          _steps(steps);
                        },
                ),
                StudioTool(
                  label: 'Supprimer l’action ${index + 1}',
                  icon: Icons.remove_circle_outline,
                  onPressed: movement.routeSteps.length <= 1
                      ? null
                      : () {
                          final steps = movement.routeSteps.toList()
                            ..removeAt(index);
                          _steps(steps);
                        },
                ),
              ],
            ),
          ],
          StudioButton(
            label: 'Ajouter une action',
            onPressed: movement.routeSteps.length >= 256
                ? null
                : () => _steps([
                    ...movement.routeSteps,
                    MapEntityNpcRouteStep.move(
                      direction: widget.entity.npc!.facing,
                    ),
                  ]),
          ),
        ],
      ],
    );
  }
}
