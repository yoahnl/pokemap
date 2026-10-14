import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';

class SceneActorActionForm extends StatefulWidget {
  const SceneActorActionForm({
    super.key,
    required this.project,
    required this.commandId,
    required this.current,
    required this.onApply,
    this.loadMap,
  });

  final ProjectManifest project;
  final String commandId;
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;

  @override
  State<SceneActorActionForm> createState() => _SceneActorActionFormState();
}

class _SceneActorActionFormState extends State<SceneActorActionForm> {
  String? _mapId, _entityId;
  SceneActorTargetKind _targetKind = SceneActorTargetKind.player;
  bool _skippable = false, _visible = true, _loading = false;
  MapData? _map;
  String? _mapError;
  int _request = 0, _nextStepId = 0;
  final _steps = <_ActorStepDraft>[];

  bool get _route => widget.commandId == NarrativeCommandIds.actorRoute;

  @override
  void initState() {
    super.initState();
    _readCurrent();
  }

  @override
  void didUpdateWidget(SceneActorActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.commandId != widget.commandId) {
      _readCurrent();
    } else if (oldWidget.project != widget.project ||
        oldWidget.loadMap != widget.loadMap) {
      _loadMap();
    }
  }

  void _readCurrent() {
    _mapId = null;
    _entityId = null;
    _targetKind = SceneActorTargetKind.player;
    _skippable = false;
    _visible = true;
    _steps.clear();
    _nextStepId = 0;
    final command = widget.current?.interactiveCommand;
    final target = switch (command) {
      SceneActorRouteInteractiveCommand() when _route => command.target,
      SceneActorVisibilityInteractiveCommand() when !_route => command.target,
      _ => null,
    };
    if (target != null) {
      _mapId = target.mapId;
      _entityId = target.entityId;
      _targetKind = target.kind;
    }
    if (command is SceneActorRouteInteractiveCommand && _route) {
      _skippable = command.skippable;
      for (final step in command.steps) {
        _steps.add(_ActorStepDraft.fromStep(_nextStepId++, step));
      }
    } else if (command is SceneActorVisibilityInteractiveCommand && !_route) {
      _visible = command.visible;
    }
    _loadMap();
  }

  Map<String, String> get _maps {
    if (widget.project.settings.dimension != ProjectDimension.twoD) {
      return const {};
    }
    final counts = <String, int>{};
    for (final map in widget.project.maps) {
      counts[map.id] = (counts[map.id] ?? 0) + 1;
    }
    return {
      for (final map in widget.project.maps)
        if (counts[map.id] == 1 && map.id.isNotEmpty && map.id.trim() == map.id)
          map.id: map.name,
    };
  }

  Map<String, String> get _actors {
    final map = _map;
    if (map == null) return const {};
    final counts = <String, int>{};
    for (final entity in map.entities) {
      counts[entity.id] = (counts[entity.id] ?? 0) + 1;
    }
    return {
      for (final entity in map.entities)
        if (counts[entity.id] == 1 &&
            entity.id.isNotEmpty &&
            entity.id.trim() == entity.id &&
            isSceneActorEntityReferenceAvailable(widget.project, entity))
          entity.id: entity.name.trim().isNotEmpty
              ? entity.name
              : 'PNJ (${entity.id})',
    };
  }

  Map<String, String> get _sounds {
    final counts = <String, int>{};
    for (final media in widget.project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in widget.project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.id.isNotEmpty &&
            media.id.trim() == media.id &&
            media.kind == CinematicMediaAssetKind.sound &&
            !media.loopByDefault)
          media.id: media.label,
    };
  }

  void _loadMap() {
    final request = ++_request;
    _map = null;
    _mapError = null;
    _loading = false;
    final mapId = _mapId, load = widget.loadMap;
    if (mapId == null) return;
    if (!_maps.containsKey(mapId)) {
      _mapError =
          'Cette carte est absente, ambiguë ou incompatible avec le Player 2D.';
      return;
    }
    if (load == null) {
      _mapError = 'La carte doit être chargée pour vérifier l’acteur.';
      return;
    }
    _loading = true;
    Future<MapData>.sync(() => load(mapId)).then(
      (map) {
        if (!mounted || request != _request) return;
        setState(() {
          _loading = false;
          if (map.id != mapId || map.spatialScene != null) {
            _mapError =
                'La carte chargée ne correspond pas à une carte 2D valide.';
          } else {
            _map = map;
          }
        });
      },
      onError: (Object error) {
        if (!mounted || request != _request) return;
        setState(() {
          _loading = false;
          _mapError = 'Impossible de lire la carte de l’acteur.';
        });
      },
    );
  }

  SceneActorTarget get _target => _targetKind == SceneActorTargetKind.player
      ? SceneActorTarget.player(mapId: _mapId!)
      : SceneActorTarget.entity(mapId: _mapId!, entityId: _entityId!);

  SceneActorRouteStep _typedStep(_ActorStepDraft step) => switch (step.kind) {
    SceneActorRouteStepKind.face => SceneActorRouteStep.face(
      direction: step.direction,
      durationMs: step.duration!,
    ),
    SceneActorRouteStepKind.move => SceneActorRouteStep.move(
      direction: step.direction,
      durationMs: step.duration!,
    ),
    SceneActorRouteStepKind.wait => SceneActorRouteStep.wait(
      durationMs: step.duration!,
    ),
    SceneActorRouteStepKind.through => SceneActorRouteStep.through(
      enabled: step.enabled,
    ),
    SceneActorRouteStepKind.sound => SceneActorRouteStep.sound(
      mediaAssetId: step.soundId!,
      gain: double.parse(step.gainText.trim()),
    ),
  };

  bool _stepValid(_ActorStepDraft step) {
    if (step.kind == SceneActorRouteStepKind.sound &&
        !_sounds.containsKey(step.soundId)) {
      return false;
    }
    try {
      _typedStep(step);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get _valid =>
      !_loading &&
      _mapError == null &&
      _map != null &&
      _maps.containsKey(_mapId) &&
      (_targetKind == SceneActorTargetKind.player ||
          _actors.containsKey(_entityId)) &&
      (!_route || _steps.every(_stepValid));

  void _submit() {
    if (!_valid) return;
    final command = _route
        ? SceneInteractiveCommand.actorRoute(
            target: _target,
            steps: [for (final step in _steps) _typedStep(step)],
            skippable: _skippable,
          )
        : SceneInteractiveCommand.actorVisibility(
            target: _target,
            visible: _visible,
          );
    final current = widget.current;
    widget.onApply(
      SceneActionPayload.interactive(
        command,
        actionKind: current?.actionKind,
        parameters: current?.parameters ?? const {},
      ),
    );
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Carte de l’acteur',
        value: _mapId,
        options: _maps,
        onChanged: (value) => setState(() {
          _mapId = value;
          _entityId = null;
          _loadMap();
        }),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Acteur',
        value: _targetKind.name,
        options: const {'player': 'Joueur', 'entity': 'PNJ de la carte'},
        onChanged: (value) => setState(() {
          _targetKind = SceneActorTargetKind.values.byName(value);
          _entityId = null;
        }),
      ),
      if (_loading) const StudioNotice('Chargement des acteurs de la carte…'),
      if (_mapError != null) ...[
        StudioNotice(_mapError!, isError: true),
        StudioButton(
          label: 'Recharger la carte',
          secondary: true,
          onPressed: () => setState(_loadMap),
        ),
      ],
      if (_targetKind == SceneActorTargetKind.entity) ...[
        const SizedBox(height: 12),
        StudioSelect(
          label: 'PNJ',
          value: _entityId,
          options: _actors,
          onChanged: _actors.isEmpty
              ? null
              : (value) => setState(() => _entityId = value),
        ),
        if (!_loading && _map != null && !_actors.containsKey(_entityId))
          const StudioNotice(
            'Choisir un PNJ unique avec un personnage connu dans cette carte.',
            isError: true,
          ),
      ],
      if (_route) ...[
        StudioToggleRow(
          label: 'Continuer si un déplacement est bloqué',
          value: _skippable,
          description: 'Les déplacements bloqués sont ignorés ; les autres étapes restent exécutées.',
          onChanged: (value) => setState(() => _skippable = value),
        ),
        for (var index = 0; index < _steps.length; index++)
          _step(_steps[index], index),
        if (_steps.isEmpty)
          const StudioNotice(
            'Aucune étape : la route se termine immédiatement.',
          ),
        StudioButton(
          key: const ValueKey('actor-add-step'),
          label: 'Ajouter une étape',
          secondary: true,
          onPressed: () =>
              setState(() => _steps.add(_ActorStepDraft(_nextStepId++))),
        ),
      ] else
        StudioToggleRow(
          label: 'Acteur visible',
          value: _visible,
          description: 'Modifie uniquement son affichage ; ses collisions restent inchangées.',
          onChanged: (value) => setState(() => _visible = value),
        ),
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: _valid ? _submit : null,
      ),
    ],
  );

  Widget _step(_ActorStepDraft step, int index) => Padding(
    key: ValueKey('actor-step-${step.id}'),
    padding: const EdgeInsets.only(bottom: 16),
    child: StudioPanel(
      compact: true,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Étape ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-up'),
              label: 'Monter l’étape ${index + 1}',
              icon: Icons.arrow_upward,
              onPressed: index == 0
                  ? null
                  : () => setState(() {
                      _steps.removeAt(index);
                      _steps.insert(index - 1, step);
                    }),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-down'),
              label: 'Descendre l’étape ${index + 1}',
              icon: Icons.arrow_downward,
              onPressed: index == _steps.length - 1
                  ? null
                  : () => setState(() {
                      _steps.removeAt(index);
                      _steps.insert(index + 1, step);
                    }),
            ),
            StudioTool(
              key: ValueKey('actor-step-${step.id}-delete'),
              label: 'Supprimer l’étape ${index + 1}',
              icon: Icons.delete_outline,
              onPressed: () => setState(() => _steps.removeAt(index)),
            ),
          ],
        ),
        StudioSelect(
          label: 'Action de l’étape ${index + 1}',
          value: step.kind.name,
          options: const {
            'face': 'Se tourner',
            'move': 'Avancer d’une case',
            'wait': 'Attendre',
            'through': 'Traverser les obstacles',
            'sound': 'Jouer un son',
          },
          onChanged: (value) => setState(
            () => step.changeKind(SceneActorRouteStepKind.values.byName(value)),
          ),
        ),
        if (step.kind == SceneActorRouteStepKind.face ||
            step.kind == SceneActorRouteStepKind.move) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Direction de l’étape ${index + 1}',
            value: step.direction.name,
            options: const {
              'north': 'Nord',
              'south': 'Sud',
              'east': 'Est',
              'west': 'Ouest',
            },
            onChanged: (value) => setState(
              () => step.direction = EntityFacing.values.byName(value),
            ),
          ),
        ],
        if (step.hasDuration) ...[
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('actor-step-${step.id}-duration'),
            value: step.durationText,
            label: step.kind == SceneActorRouteStepKind.face
                ? 'Maintien de la direction (ms)'
                : 'Durée (ms)',
            keyboardType: TextInputType.number,
            helperText: step.kind == SceneActorRouteStepKind.move
                ? 'De 1 à 2147483647 ms.'
                : 'De 0 à 2147483647 ms.',
            errorText: step.durationValid
                ? null
                : 'Saisir une durée entière dans les limites indiquées.',
            onChanged: (value) => setState(() => step.durationText = value),
          ),
        ],
        if (step.kind == SceneActorRouteStepKind.through)
          StudioToggleRow(
            label: 'Traversée autorisée',
            value: step.enabled,
            onChanged: (value) => setState(() => step.enabled = value),
          ),
        if (step.kind == SceneActorRouteStepKind.sound) ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Son de l’étape ${index + 1}',
            value: step.soundId,
            options: _sounds,
            onChanged: _sounds.isEmpty
                ? null
                : (value) => setState(() => step.soundId = value),
          ),
          if (!_sounds.containsKey(step.soundId))
            const StudioNotice(
              'Choisir un son unique sans lecture en boucle.',
              isError: true,
            ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('actor-step-${step.id}-gain'),
            label: 'Volume (0 à 1)',
            value: step.gainText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: step.gainValid
                ? null
                : 'Saisir un volume fini entre 0 et 1.',
            onChanged: (value) => setState(() => step.gainText = value),
          ),
        ],
      ],
    ),
  );
}

class _ActorStepDraft {
  _ActorStepDraft(this.id);
  final int id;
  SceneActorRouteStepKind kind = SceneActorRouteStepKind.face;
  EntityFacing direction = EntityFacing.south;
  String durationText = '0', gainText = '1';
  String? soundId;
  bool enabled = false;

  factory _ActorStepDraft.fromStep(int id, SceneActorRouteStep step) {
    final draft = _ActorStepDraft(id)..kind = step.kind;
    switch (step) {
      case SceneActorFaceStep():
        draft.direction = step.direction;
        draft.durationText = '${step.durationMs}';
      case SceneActorMoveStep():
        draft.direction = step.direction;
        draft.durationText = '${step.durationMs}';
      case SceneActorWaitStep():
        draft.durationText = '${step.durationMs}';
      case SceneActorThroughStep():
        draft.enabled = step.enabled;
      case SceneActorSoundStep():
        draft.soundId = step.mediaAssetId;
        draft.gainText = '${step.gain}';
    }
    return draft;
  }

  bool get hasDuration =>
      kind == SceneActorRouteStepKind.face ||
      kind == SceneActorRouteStepKind.move ||
      kind == SceneActorRouteStepKind.wait;
  int? get duration => RegExp(r'^\d+$').hasMatch(durationText.trim())
      ? int.tryParse(durationText.trim())
      : null;
  bool get durationValid =>
      duration != null &&
      duration! >= (kind == SceneActorRouteStepKind.move ? 1 : 0) &&
      duration! <= 0x7fffffff;
  bool get gainValid {
    final value = double.tryParse(gainText.trim());
    return value != null && value.isFinite && value >= 0 && value <= 1;
  }

  void changeKind(SceneActorRouteStepKind next) {
    if (next == kind) return;
    kind = next;
    durationText = next == SceneActorRouteStepKind.move ? '200' : '0';
    gainText = '1';
    soundId = null;
    enabled = false;
  }
}
