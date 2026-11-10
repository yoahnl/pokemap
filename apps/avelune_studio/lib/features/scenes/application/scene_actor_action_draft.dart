import 'package:map_core/map_core.dart';

class SceneActorActionDraft {
  SceneActorActionDraft({
    required this.project,
    required this.commandId,
    required this.current,
    required this.changed,
    this.loadMap,
  }) {
    readCurrent();
  }
  ProjectManifest project;
  String commandId;
  SceneActionPayload? current;
  Future<MapData> Function(String)? loadMap;
  final void Function() changed;
  bool _disposed = false;
  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required ProjectManifest project,
    required String commandId,
    required SceneActionPayload? current,
    required Future<MapData> Function(String)? loadMap,
  }) {
    final reread = this.current != current || this.commandId != commandId;
    final reload = this.project != project || this.loadMap != loadMap;
    this.project = project;
    this.commandId = commandId;
    this.current = current;
    this.loadMap = loadMap;
    if (reread) {
      readCurrent();
    } else if (reload) {
      reloadMap();
    }
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  String? selectedMapId, selectedEntityId;
  SceneActorTargetKind targetKind = SceneActorTargetKind.player;
  ActorRouteTransientScope transientScope = ActorRouteTransientScope.route;
  bool skippable = false, visible = true, loading = false;
  MapData? stageMap;
  String? mapError;
  int _request = 0, nextStepId = 0;
  final steps = <SceneActorStepDraft>[];

  bool get isRoute => commandId == NarrativeCommandIds.actorRoute;

  SceneActorStepDraft addStep() {
    final step = SceneActorStepDraft(nextStepId++);
    steps.add(step);
    return step;
  }

  void moveStep(SceneActorStepDraft step, int delta) {
    final index = steps.indexOf(step);
    final destination = index + delta;
    if (index < 0 || destination < 0 || destination >= steps.length) return;
    steps.removeAt(index);
    steps.insert(destination, step);
  }

  void removeStep(SceneActorStepDraft step) => steps.remove(step);

  void readCurrent() {
    selectedMapId = null;
    selectedEntityId = null;
    targetKind = SceneActorTargetKind.player;
    skippable = false;
    transientScope = ActorRouteTransientScope.route;
    visible = true;
    steps.clear();
    nextStepId = 0;
    final command = current?.interactiveCommand;
    final target = switch (command) {
      SceneActorRouteInteractiveCommand() when isRoute => command.target,
      SceneActorVisibilityInteractiveCommand() when !isRoute => command.target,
      _ => null,
    };
    if (target != null) {
      selectedMapId = target.mapId;
      selectedEntityId = target.entityId;
      targetKind = target.kind;
    }
    if (command is SceneActorRouteInteractiveCommand && isRoute) {
      skippable = command.skippable;
      transientScope = command.transientScope;
      for (final step in command.steps) {
        steps.add(
          SceneActorStepDraft.fromStep(
            nextStepId++,
            step,
            mapId: target!.mapId,
          ),
        );
      }
    } else if (command is SceneActorVisibilityInteractiveCommand && !isRoute) {
      visible = command.visible;
    }
    reloadMap();
  }

  Map<String, String> get mapOptions {
    if (project.settings.dimension != ProjectDimension.twoD) {
      return const {};
    }
    final counts = <String, int>{};
    for (final map in project.maps) {
      counts[map.id] = (counts[map.id] ?? 0) + 1;
    }
    return {
      for (final map in project.maps)
        if (counts[map.id] == 1 && map.id.isNotEmpty && map.id.trim() == map.id)
          map.id: map.name,
    };
  }

  Map<String, String> get actorOptions {
    final map = stageMap;
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
            isSceneActorEntityReferenceAvailable(project, entity))
          entity.id: entity.name.trim().isNotEmpty
              ? entity.name
              : 'PNJ (${entity.id})',
    };
  }

  Map<String, String> get initialCollisionOwners {
    final map = stageMap;
    if (map == null) return const {};
    final actors = actorOptions;
    return {
      for (final entity in map.entities)
        if (actors.containsKey(entity.id) &&
            isSceneActorInitialCollisionOwnerReferenceAvailable(
              project,
              entity,
            ))
          entity.id: actors[entity.id]!,
    };
  }

  bool throughBefore(int index) {
    var through = false;
    for (final step in steps.take(index)) {
      if (step.kind == SceneActorRouteStepKind.through) {
        through = step.enabled;
      }
    }
    return through;
  }

  bool canSelectInitialOwner(SceneActorStepDraft step, int index) =>
      step.kind == SceneActorRouteStepKind.move &&
      targetKind == SceneActorTargetKind.player &&
      !throughBefore(index);

  String? initialOwnerError(SceneActorStepDraft step, int index) {
    if (step.initialCollisionOwnerEntityId == null) return null;
    if (step.kind != SceneActorRouteStepKind.move) {
      return 'Ce personnage est réservé à un déplacement. Choisir Aucun pour retirer la sélection.';
    }
    if (targetKind != SceneActorTargetKind.player) {
      return 'Seul le joueur peut quitter la case d’un personnage. Choisir Aucun pour retirer la sélection.';
    }
    if (throughBefore(index)) {
      return 'Désactiver la traversée avant ce déplacement ou choisir Aucun.';
    }
    if (step.initialCollisionOwnerMapId != selectedMapId) {
      return 'La carte a changé. Choisir à nouveau le personnage dans cette carte ou choisir Aucun.';
    }
    if (!initialCollisionOwners.containsKey(
      step.initialCollisionOwnerEntityId,
    )) {
      return 'Choisir un PNJ unique avec un personnage connu et un contact d’une case à la position du PNJ, ou choisir Aucun.';
    }
    return null;
  }

  Map<String, String> initialOwnerOptions(
    SceneActorStepDraft step,
    int index,
  ) => {
    '': 'Aucun',
    if (initialOwnerError(step, index) != null)
      'unavailable': 'Sélection conservée — à vérifier',
    if (canSelectInitialOwner(step, index))
      for (final entry in initialCollisionOwners.entries)
        initialOwnerOptionKey(entry.key): entry.value,
  };

  String initialOwnerValue(SceneActorStepDraft step, int index) =>
      step.initialCollisionOwnerEntityId == null
      ? ''
      : initialOwnerError(step, index) != null
      ? 'unavailable'
      : initialOwnerOptionKey(step.initialCollisionOwnerEntityId!);

  String initialOwnerOptionKey(String entityId) =>
      'entity:${selectedMapId!.length}:$selectedMapId:$entityId';

  void selectInitialOwner(SceneActorStepDraft step, String value) {
    if (value.isEmpty) {
      step.initialCollisionOwnerEntityId = null;
      step.initialCollisionOwnerMapId = null;
    } else {
      for (final entityId in initialCollisionOwners.keys) {
        if (initialOwnerOptionKey(entityId) != value) continue;
        step.initialCollisionOwnerEntityId = entityId;
        step.initialCollisionOwnerMapId = selectedMapId;
        return;
      }
    }
  }

  bool get routeStepsValid {
    for (var index = 0; index < steps.length; index++) {
      if (!stepValid(steps[index]) ||
          initialOwnerError(steps[index], index) != null) {
        return false;
      }
    }
    return true;
  }

  Map<String, String> get characterOptions => {
    for (final character in project.characters)
      if (isSceneActorAppearanceReferenceAvailable(project, character.id))
        character.id: character.name,
  };

  Map<String, String> get soundOptions {
    final counts = <String, int>{};
    for (final media in project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.id.isNotEmpty &&
            media.id.trim() == media.id &&
            media.kind == CinematicMediaAssetKind.sound &&
            !media.loopByDefault)
          media.id: media.label,
    };
  }

  void reloadMap() {
    final request = ++_request;
    stageMap = null;
    mapError = null;
    loading = false;
    final mapId = selectedMapId, load = loadMap;
    if (mapId == null) return;
    if (!mapOptions.containsKey(mapId)) {
      mapError =
          'Cette carte est absente, ambiguë ou incompatible avec le Player 2D.';
      return;
    }
    if (load == null) {
      mapError = 'La carte doit être chargée pour vérifier l’acteur.';
      return;
    }
    loading = true;
    Future<MapData>.sync(() => load(mapId)).then(
      (map) {
        if (_disposed || request != _request) return;
        _update(() {
          loading = false;
          if (map.id != mapId || map.spatialScene != null) {
            mapError =
                'La carte chargée ne correspond pas à une carte 2D valide.';
          } else {
            stageMap = map;
          }
        });
      },
      onError: (Object error) {
        if (_disposed || request != _request) return;
        _update(() {
          loading = false;
          mapError = 'Impossible de lire la carte de l’acteur.';
        });
      },
    );
  }

  SceneActorTarget get target => targetKind == SceneActorTargetKind.player
      ? SceneActorTarget.player(mapId: selectedMapId!)
      : SceneActorTarget.entity(
          mapId: selectedMapId!,
          entityId: selectedEntityId!,
        );

  SceneActorRouteStep typedStep(SceneActorStepDraft step) =>
      switch (step.kind) {
        SceneActorRouteStepKind.appearance => SceneActorRouteStep.appearance(
          characterId: step.characterId!,
        ),
        SceneActorRouteStepKind.face => SceneActorRouteStep.face(
          direction: step.direction,
          durationMs: step.duration!,
          yieldAfter: step.yieldAfter,
        ),
        SceneActorRouteStepKind.move => SceneActorRouteStep.move(
          direction: step.direction,
          durationMs: step.duration!,
          initialCollisionOwnerEntityId: step.initialCollisionOwnerEntityId,
        ),
        SceneActorRouteStepKind.moveDiagonal =>
          SceneActorRouteStep.moveDiagonal(
            horizontal: step.horizontal,
            vertical: step.vertical,
            durationMs: step.duration!,
          ),
        SceneActorRouteStepKind.wait => SceneActorRouteStep.wait(
          durationMs: step.duration!,
        ),
        SceneActorRouteStepKind.through => SceneActorRouteStep.through(
          enabled: step.enabled,
        ),
        SceneActorRouteStepKind.renderAboveMap =>
          SceneActorRouteStep.renderAboveMap(enabled: step.enabled),
        SceneActorRouteStepKind.visibility => SceneActorRouteStep.visibility(
          visible: step.enabled,
        ),
        SceneActorRouteStepKind.sound => SceneActorRouteStep.sound(
          mediaAssetId: step.soundId!,
          gain: double.parse(step.gainText.trim()),
        ),
      };

  bool stepValid(SceneActorStepDraft step) {
    if (step.kind == SceneActorRouteStepKind.appearance &&
        !characterOptions.containsKey(step.characterId)) {
      return false;
    }
    if (step.kind == SceneActorRouteStepKind.sound &&
        !soundOptions.containsKey(step.soundId)) {
      return false;
    }
    try {
      typedStep(step);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get valid =>
      !loading &&
      mapError == null &&
      stageMap != null &&
      mapOptions.containsKey(selectedMapId) &&
      (targetKind == SceneActorTargetKind.player ||
          actorOptions.containsKey(selectedEntityId)) &&
      (!isRoute || routeStepsValid);

  SceneActionPayload? get payload {
    if (!valid) return null;
    final command = isRoute
        ? SceneInteractiveCommand.actorRoute(
            target: target,
            steps: [for (final step in steps) typedStep(step)],
            skippable: skippable,
            transientScope: transientScope,
          )
        : SceneInteractiveCommand.actorVisibility(
            target: target,
            visible: visible,
          );
    final current = this.current;
    return SceneActionPayload.interactive(
      command,
      actionKind: current?.actionKind,
      parameters: current?.parameters ?? const {},
    );
  }
}

class SceneActorStepDraft {
  SceneActorStepDraft(this.id);
  final int id;
  SceneActorRouteStepKind kind = SceneActorRouteStepKind.face;
  EntityFacing direction = EntityFacing.south;
  EntityFacing horizontal = EntityFacing.west, vertical = EntityFacing.north;
  String durationText = '0', gainText = '1';
  String? soundId, characterId;
  String? initialCollisionOwnerEntityId, initialCollisionOwnerMapId;
  bool enabled = false, yieldAfter = false;

  factory SceneActorStepDraft.fromStep(
    int id,
    SceneActorRouteStep step, {
    required String mapId,
  }) {
    final draft = SceneActorStepDraft(id)..kind = step.kind;
    switch (step) {
      case SceneActorFaceStep():
        draft.yieldAfter = step.yieldAfter;
        draft.direction = step.direction;
        draft.durationText = '${step.durationMs}';
      case SceneActorMoveStep():
        draft.direction = step.direction;
        draft.durationText = '${step.durationMs}';
        draft.initialCollisionOwnerEntityId =
            step.initialCollisionOwnerEntityId;
        if (step.initialCollisionOwnerEntityId != null) {
          draft.initialCollisionOwnerMapId = mapId;
        }
      case SceneActorDiagonalMoveStep():
        draft.horizontal = step.horizontal;
        draft.vertical = step.vertical;
        draft.durationText = '${step.durationMs}';
      case SceneActorWaitStep():
        draft.durationText = '${step.durationMs}';
      case SceneActorThroughStep():
        draft.enabled = step.enabled;
      case SceneActorRenderAboveMapStep():
        draft.enabled = step.enabled;
      case SceneActorAppearanceStep():
        draft.characterId = step.characterId;
      case SceneActorVisibilityStep():
        draft.enabled = step.visible;
      case SceneActorSoundStep():
        draft.soundId = step.mediaAssetId;
        draft.gainText = '${step.gain}';
    }
    return draft;
  }

  bool get isMovement =>
      kind == SceneActorRouteStepKind.move ||
      kind == SceneActorRouteStepKind.moveDiagonal;
  bool get hasDuration =>
      kind == SceneActorRouteStepKind.face ||
      isMovement ||
      kind == SceneActorRouteStepKind.wait;
  int? get duration => RegExp(r'^\d+$').hasMatch(durationText.trim())
      ? int.tryParse(durationText.trim())
      : null;
  bool get durationValid =>
      duration != null &&
      duration! >= (isMovement ? 1 : 0) &&
      duration! <= 0x7fffffff;
  bool get gainValid {
    final value = double.tryParse(gainText.trim());
    return value != null && value.isFinite && value >= 0 && value <= 1;
  }

  void changeKind(SceneActorRouteStepKind next) {
    if (next == kind) return;
    kind = next;
    durationText = isMovement ? '200' : '0';
    gainText = '1';
    soundId = null;
    enabled = false;
    yieldAfter = false;
  }
}
