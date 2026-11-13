import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_cases.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_triggers.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_deletion_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_behaviours.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/application/project_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_plan.dart';
import 'package:avelune_studio/features/story_draft/application/story_saved_dialogues.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';

part 'map_builder_story_cases_binding.dart';
part 'map_builder_story_conditions_binding.dart';
part 'map_builder_story_line_binding.dart';

enum MapStoryTab { behaviour, properties }

enum MapStoryAddition { character, sign, zone }

enum _StorySide { map, behaviours }

final class _StoryRefused implements Exception {
  const _StoryRefused(this.problem);

  final String problem;
}

class MapBuilderStoryBinding implements ProjectDraftPart {
  MapBuilderStoryBinding({
    required this.maps,
    required this.changed,
    required this.view,
    String Function()? zoneName,
    String Function(int index)? behaviourName,
    String Function(List<String> names)? conflictMessage,
    String Function(String name, List<String> behaviours)? deletionRefusal,
    this.loadMedia,
    this.gateway,
    this.loadDialogue,
  }) : _zoneName = zoneName ?? (() => 'Zone'),
       _behaviourName = behaviourName ?? ((index) => 'Comportement $index'),
       _conflictMessage =
           conflictMessage ?? ((names) => '$conflict${names.join(', ')}'),
       _deletionRefusal =
           deletionRefusal ??
           ((name, behaviours) => '$carrier$name:${behaviours.join(', ')}');

  final MapWorkspaceController maps;
  final void Function() changed;
  final MapEditingViewportSession? Function() view;
  final String Function() _zoneName;
  final String Function(int index) _behaviourName;
  final String Function(List<String> names) _conflictMessage;
  final String Function(String name, List<String> behaviours) _deletionRefusal;
  final Future<ProjectMediaCatalog?> Function(ProjectManifest project)?
  loadMedia;
  final StoryPublicationGatewayFactory? gateway;
  final StoryDialogueLoader? loadDialogue;
  final behaviours = MapStoryBehaviours();
  final _lines = _StoryLines();
  final _triggers = _StoryTriggers();
  BehaviourAfter? pendingAfter;
  bool _mediaLoaded = false;
  final _done = <(_StorySide, Object?)>[];
  final _undone = <(_StorySide, Object?)>[];
  bool publishing = false;
  int attempts = 0;
  bool preparing = false;

  bool get ready =>
      maps.hasWorkshop(MapWorkspaceWorkshop.events) &&
      (loadMedia == null || _mediaLoaded);

  Future<void> prepare() async {
    if (ready || preparing) return;
    preparing = true;
    changed();
    try {
      await maps.ensureWorkshop(MapWorkspaceWorkshop.events);
      await _prepareMedia();
      final project = maps.project;
      final map = this.map;
      if (project != null && map != null) behaviours.prepare(project, map);
    } on Object catch (failure) {
      error = '$failure';
    } finally {
      preparing = false;
      changed();
    }
  }

  Future<void> _prepareMedia() async {
    final load = loadMedia;
    final project = maps.project;
    if (load == null || project == null || _mediaLoaded) return;
    try {
      behaviours.media = await load(project);
    } finally {
      _mediaLoaded = true;
    }
  }

  NarrativeEventRegistry? _registry;
  bool choosing = false;
  MapStoryAddition? adding;
  bool charactersLoading = false;
  String? charactersError;
  int _armedEntities = 0;
  String query = '';
  MapStoryElementKind? filter;
  MapStoryTab tab = MapStoryTab.behaviour;
  int behaviour = 0;
  String? error;
  String? repairError;
  String? _mapSelection;
  MapStoryBehaviourIndex? _index;
  MapStoryElements? _elements;
  MapData? _source;
  ProjectManifest? _project;

  MapData? get map => maps.active?.current;

  MapStoryElements? get elements {
    final map = this.map;
    if (map == null) return null;
    final project = maps.project;
    final registry = project == null ? null : behaviours.registry(project);
    var index = _index;
    if (index == null ||
        index.mapId != map.id ||
        !identical(registry, _registry)) {
      _registry = registry;
      _elements = null;
      index = _index = MapStoryBehaviourIndex(
        map.id,
        registry?.records ?? const [],
      );
    }
    if (_elements == null ||
        !identical(map, _source) ||
        !identical(project, _project)) {
      _source = map;
      _project = project;
      _elements = MapStoryElements(map, project, behaviours: index);
    }
    return _elements;
  }

  List<MapStoryOrphan> get orphans => elements?.orphans ?? const [];

  List<MapStoryElement> get repairTargets => [
    for (final element in elements?.elements ?? const <MapStoryElement>[])
      if (element.target != MapStoryElementTarget.map) element,
  ];

  String? deletionProblem(MapStoryElementTarget target, String id) {
    final carrier = elements?.carrier(target, id);
    return carrier == null
        ? null
        : _deletionRefusal(carrier.name, [
            for (final record in carrier.behaviours) record.name,
          ]);
  }

  String? modelDeletionProblem(String mapId, String modelId) => mapId == map?.id
      ? deletionProblem(MapStoryElementTarget.model, modelId)
      : null;

  String? contextDeletionProblem(MapContextTarget target) =>
      target.mapId != map?.id
      ? null
      : switch (target.family) {
          MapContextFamily.character || MapContextFamily.marker =>
            deletionProblem(MapStoryElementTarget.entity, target.id),
          MapContextFamily.trigger => deletionProblem(
            MapStoryElementTarget.trigger,
            target.id,
          ),
          MapContextFamily.decor => deletionProblem(
            MapStoryElementTarget.model,
            target.id,
          ),
          MapContextFamily.warp ||
          MapContextFamily.zone ||
          MapContextFamily.cell => null,
        };

  List<MapStoryElement> get visible {
    final needle = query.trim().toLowerCase();
    return [
      for (final element in elements?.elements ?? const <MapStoryElement>[])
        if ((filter == null || element.kind == filter) &&
            (needle.isEmpty || element.name.toLowerCase().contains(needle)))
          element,
    ];
  }

  MapStoryElement? get selected {
    final map = this.map;
    final session = view();
    if (map == null || session == null) return null;
    final elements = this.elements!;
    for (final (family, target) in const [
      (MapSelectionFamily.character, MapStoryElementTarget.entity),
      (MapSelectionFamily.marker, MapStoryElementTarget.entity),
      (MapSelectionFamily.trigger, MapStoryElementTarget.trigger),
      (MapSelectionFamily.decor, MapStoryElementTarget.model),
    ]) {
      final id = session.selectedFor(map.id, family);
      if (id != null) return elements.byKey('${target.name}:$id');
    }
    if (session.hasSelectionIn(map.id)) return null;
    return elements.byKey(_mapSelection);
  }

  NarrativeEventRecord? get selectedBehaviour {
    final behaviours = selected?.behaviours ?? const [];
    return behaviours.isEmpty
        ? null
        : behaviours[behaviour.clamp(0, behaviours.length - 1)];
  }

  void select(MapStoryElement element) {
    final document = maps.active;
    final session = view();
    if (document == null || session == null) return;
    behaviour = 0;
    _mapSelection = null;
    switch (element.target) {
      case MapStoryElementTarget.map:
        session.clearSelection(document);
        _mapSelection = element.key;
      case MapStoryElementTarget.entity:
        final entity = document.current.entities
            .where((item) => item.id == element.id)
            .firstOrNull;
        session.select(
          document,
          entity?.kind == MapEntityKind.npc
              ? MapSelectionFamily.character
              : MapSelectionFamily.marker,
          element.id,
        );
      case MapStoryElementTarget.trigger:
        session.select(document, MapSelectionFamily.trigger, element.id);
      case MapStoryElementTarget.model:
        session.select(document, MapSelectionFamily.decor, element.id);
    }
    changed();
  }

  MapEntity? entityOf(MapStoryElement element) =>
      element.target == MapStoryElementTarget.entity
      ? map?.entities.where((item) => item.id == element.id).firstOrNull
      : null;

  bool rename(MapStoryElement element, String name) => _edit((
    document,
    project,
  ) {
    final entity = entityOf(element);
    switch (element.target) {
      case MapStoryElementTarget.trigger:
        TriggerEditingCommands(document, project).rename(element.id, name);
      case MapStoryElementTarget.entity when entity?.npc != null:
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, name: name);
      case MapStoryElementTarget.entity when entity?.sign != null:
        MapEntityEditingCommands(
          document,
          project,
        ).updateSign(element.id, title: name);
      case MapStoryElementTarget.entity:
        MapEntityEditingCommands(document, project).rename(element.id, name);
      case MapStoryElementTarget.model || MapStoryElementTarget.map:
        return false;
    }
    return true;
  });

  bool moveTo(MapStoryElement element, GridPos position) => _edit((
    document,
    project,
  ) {
    final size = element.area?.size ?? const GridSize(width: 1, height: 1);
    if (!_fits(document.current, position, size)) return false;
    switch (element.target) {
      case MapStoryElementTarget.trigger:
        TriggerEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.entity when entityOf(element)?.npc != null:
        CharacterEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.entity:
        MapEntityEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.model || MapStoryElementTarget.map:
        return false;
    }
    return true;
  });

  bool resize(MapStoryElement element, GridSize size) =>
      _edit((document, project) {
        final area = element.area;
        if (element.target != MapStoryElementTarget.trigger ||
            area == null ||
            size.width < 1 ||
            size.height < 1 ||
            !_fits(document.current, area.pos, size)) {
          return false;
        }
        TriggerEditingCommands(document, project).resize(element.id, size);
        return true;
      });

  bool setFacing(MapStoryElement element, EntityFacing facing) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, facing: facing);
        return true;
      });

  bool setBlocks(MapStoryElement element, bool blocks) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, blocks: blocks);
        return true;
      });

  bool setMovement(MapStoryElement element, MapEntityNpcMovementMode mode) =>
      _edit((document, project) {
        final npc = entityOf(element)?.npc;
        if (npc == null) return false;
        CharacterEditingCommands(document, project).setMovementConfiguration(
          element.id,
          npc.movement.copyWith(mode: mode),
        );
        return true;
      });

  bool setTrainer(MapStoryElement element, String? trainerId) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).assignTrainer(element.id, trainerId);
        return true;
      });

  bool setSignText(MapStoryElement element, String text) =>
      _edit((document, project) {
        MapEntityEditingCommands(
          document,
          project,
        ).updateSign(element.id, plainText: text);
        return true;
      });

  bool _edit(
    bool Function(EditableMapDocument document, ProjectManifest project) change,
  ) {
    final document = maps.active;
    final project = maps.project;
    if (document == null || project == null || document.saving) return false;
    attempts++;
    final before = document.current;
    bool applied;
    try {
      applied = change(document, project);
      error = applied ? null : outOfMap;
    } on Object catch (failure) {
      applied = false;
      error = failure is StateError ? failure.message : '$failure';
    }
    if (!identical(document.current, before)) {
      _record(_StorySide.map, document.undoToken);
      maps.notify();
    }
    changed();
    return applied;
  }

  bool get dirty {
    final project = maps.project;
    return project != null && behaviours.draft.dirty(behaviours.saved(project));
  }

  @override
  bool get unsaved => dirty;

  @override
  bool get saving => publishing;

  @override
  Future<bool> save() =>
      publish(gateway?.call(behaviours.draft, behaviours.dialogues));

  bool get canUndo =>
      _done.any((step) => _matches(step, undo: true)) ||
      (maps.active?.canUndo ?? false);

  bool get canRedo => _undone.any((step) => _matches(step, undo: false));

  void undo() {
    while (_done.isNotEmpty) {
      final step = _done.removeLast();
      if (!_matches(step, undo: true)) continue;
      _undone.add(_step(step.$1, undo: true));
      return;
    }
    if (maps.active?.canUndo ?? false) {
      maps.restore(redo: false);
      _undone.add((_StorySide.map, maps.active?.redoToken));
      changed();
    }
  }

  void redo() {
    while (_undone.isNotEmpty) {
      final step = _undone.removeLast();
      if (!_matches(step, undo: false)) continue;
      _done.add(_step(step.$1, undo: false));
      return;
    }
  }

  bool _matches((_StorySide, Object?) step, {required bool undo}) =>
      switch (step.$1) {
        _StorySide.behaviours => undo ? behaviours.canUndo : behaviours.canRedo,
        _StorySide.map => identical(
          undo ? maps.active?.undoToken : maps.active?.redoToken,
          step.$2,
        ),
      };

  (_StorySide, Object?) _step(_StorySide side, {required bool undo}) {
    switch (side) {
      case _StorySide.behaviours:
        undo ? behaviours.undo() : behaviours.redo();
        changed();
        return (side, null);
      case _StorySide.map:
        maps.restore(redo: !undo);
        changed();
        return (side, undo ? maps.active?.redoToken : maps.active?.undoToken);
    }
  }

  void _record(_StorySide side, Object? token) {
    _done.add((side, token));
    _undone.clear();
  }

  NarrativeEventSourceRef? defaultSource(MapStoryElement element) {
    final map = this.map;
    if (map == null) return null;
    return switch (element.target) {
      MapStoryElementTarget.entity => NarrativeEventSourceRef.entityInteract(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.model => NarrativeEventSourceRef.modelInteract(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.trigger => NarrativeEventSourceRef.triggerEnter(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.map => NarrativeEventSourceRef.mapEnter(map.id),
    };
  }

  List<NarrativeEventSourceKind> triggerKinds(MapStoryElement element) {
    final project = maps.project;
    final map = this.map;
    return project == null || map == null
        ? const []
        : _triggers.kinds(behaviours.project(project), map, element);
  }

  bool addBehaviour(MapStoryElement element) {
    final source = defaultSource(element);
    final order = element.behaviours.fold<int>(
      -1,
      (highest, record) => record.order > highest ? record.order : highest,
    );
    String? created;
    final applied = _operate(const [], [
      (c) {
        final result = createNarrativeEventDraft(
          context: c,
          expectedRevision: c.revision,
          name: _behaviourName(element.behaviours.length + 1),
          initialSource: source,
          idGenerator: NarrativeEventIdGenerator(),
        );
        created = result.eventId;
        return result;
      },
      (c) => setNarrativeEventReusePolicy(
        context: c,
        expectedRevision: c.revision,
        eventId: created!,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      ),
      (c) => setNarrativeEventOrder(
        context: c,
        expectedRevision: c.revision,
        eventId: created!,
        order: order + 1,
      ),
    ]);
    if (applied) {
      behaviour = element.behaviours.length;
      tab = MapStoryTab.behaviour;
      changed();
    }
    return applied;
  }

  bool renameBehaviour(NarrativeEventRecord record, String name) =>
      _operate(const [], [
        (c) => renameNarrativeEvent(
          context: c,
          expectedRevision: c.revision,
          eventId: record.id,
          name: name,
        ),
      ]);

  bool setTrigger(
    MapStoryElement element,
    NarrativeEventRecord record,
    NarrativeEventSourceKind kind,
  ) {
    final map = this.map;
    if (map == null) return false;
    final source = switch (kind) {
      NarrativeEventSourceKind.entityInteract =>
        NarrativeEventSourceRef.entityInteract(map.id, element.id),
      NarrativeEventSourceKind.entityBump => NarrativeEventSourceRef.entityBump(
        map.id,
        element.id,
      ),
      NarrativeEventSourceKind.entityAutorun =>
        NarrativeEventSourceRef.entityAutorun(map.id, element.id),
      NarrativeEventSourceKind.modelInteract =>
        NarrativeEventSourceRef.modelInteract(map.id, element.id),
      NarrativeEventSourceKind.triggerEnter =>
        NarrativeEventSourceRef.triggerEnter(map.id, element.id),
      NarrativeEventSourceKind.triggerBump =>
        NarrativeEventSourceRef.triggerBump(map.id, element.id),
      NarrativeEventSourceKind.mapEnter => NarrativeEventSourceRef.mapEnter(
        map.id,
      ),
      NarrativeEventSourceKind.outcomeReceived => null,
    };
    if (source == null) return false;
    return _operate(
      [record],
      [
        (c) => record.source == null
            ? selectNarrativeEventSource(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
                source: source,
              )
            : replaceNarrativeEventSource(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
                source: source,
              ),
      ],
    );
  }

  bool setScene(NarrativeEventRecord record, String? sceneId) => _operate(
    [record],
    [
      (c) => sceneId == null
          ? removeNarrativeEventScene(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
            )
          : setNarrativeEventScene(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
              sceneId: sceneId,
            ),
    ],
  );

  bool setActive(NarrativeEventRecord record, bool active) =>
      _operate(const [], [
        if (active && record.draftOrNull != null)
          (c) => publishNarrativeEvent(
            context: c,
            expectedRevision: c.revision,
            eventId: record.id,
          ),
        (c) => active
            ? activateNarrativeEvent(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
              )
            : deactivateNarrativeEvent(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
              ),
      ]);

  bool reassign(NarrativeEventRecord record, MapStoryElement element) {
    final kinds = triggerKinds(element);
    final current = record.source?.kind;
    if (kinds.isEmpty) return false;
    return _repair(
      () => setTrigger(
        element,
        record,
        kinds.contains(current) ? current! : kinds.first,
      ),
    );
  }

  bool deleteOrphan(NarrativeEventRecord record) =>
      _repair(() => deleteBehaviour(record));

  bool _repair(bool Function() repair) {
    final before = attempts;
    final repaired = repair();
    if (attempts == before) return repaired;
    repairError = error;
    error = null;
    changed();
    return repaired;
  }

  bool deleteBehaviour(NarrativeEventRecord record) {
    final project = maps.project;
    final map = this.map;
    if (project == null || map == null) return false;
    final applied = _operate(const [], [
      (c) => deleteNarrativeEvent(
        context: c,
        expectedRevision: c.revision,
        eventId: record.id,
        dependencyIndex: buildNarrativeDependencyIndex(
          project: behaviours.project(project),
          maps: [map],
        ),
      ),
    ]);
    if (applied) behaviour = 0;
    return applied;
  }

  bool _operate(
    List<NarrativeEventRecord> active,
    List<MapStoryBehaviourOperation> operations, {
    void Function(StoryDraft draft)? stage,
  }) {
    final project = maps.project;
    final map = this.map;
    if (project == null || map == null || publishing || !ready) return false;
    attempts++;
    repairError = null;
    final enabled = [
      for (final record in active)
        if (record.enabledOrNull == true) record.id,
    ];
    final wrapped = [
      for (final id in enabled)
        (NarrativeEventAuthoringContext c) => deactivateNarrativeEvent(
          context: c,
          expectedRevision: c.revision,
          eventId: id,
        ),
      ...operations,
    ];
    final draft = behaviours.draft;
    final recorded = draft.recorded;
    String? problem;
    String? notice;
    try {
      draft.group(() {
        stage?.call(draft);
        var result = behaviours.apply(project, map, [
          ...wrapped,
          for (final id in enabled)
            (NarrativeEventAuthoringContext c) => activateNarrativeEvent(
              context: c,
              expectedRevision: c.revision,
              eventId: id,
            ),
        ]);
        if (result.problem != null && enabled.isNotEmpty) {
          notice = result.problem;
          result = behaviours.apply(project, map, wrapped);
        }
        if (result.problem case final refused?) throw _StoryRefused(refused);
      });
    } on _StoryRefused catch (refused) {
      problem = refused.problem;
    } on Object catch (failure) {
      problem = failure is StateError ? failure.message : '$failure';
    }
    final records = {
      for (final record
          in behaviours.registry(project)?.records ??
              const <NarrativeEventRecord>[])
        record.id: record,
    };
    final dropped = enabled.any(
      (id) => records[id] != null && records[id]!.enabledOrNull != true,
    );
    error =
        problem ??
        (dropped
            ? '$deactivated${notice?.trim().isNotEmpty == true ? ' $notice' : ''}'
            : null);
    if (draft.recorded != recorded) _record(_StorySide.behaviours, null);
    changed();
    return problem == null;
  }

  Future<bool> publish(StoryPublicationGateway? gateway) async {
    final project = maps.project;
    if (project == null || !dirty) return true;
    if (gateway == null) {
      error = 'publish-unavailable';
      changed();
      return false;
    }
    publishing = true;
    changed();
    try {
      await gateway.publish(
        planStoryPublication(
          behaviours.draft.changes(behaviours.saved(project)),
        ),
        land: (write) async {
          final before = maps.project!;
          final receipt = await write();
          maps.acceptResources(
            maps.project == receipt.before ? receipt.before : before,
            receipt.manifest,
          );
          return behaviours.saved(receipt.manifest);
        },
      );
      final saved = maps.project!;
      behaviours.settle(saved);
      final conflicts = behaviours.conflicts(saved);
      if (conflicts.isNotEmpty) {
        final records = saved.eventRegistry?.records ?? const [];
        error = _conflictMessage([
          for (final id in conflicts)
            (behaviours.draftOf(id) ??
                        records.where((record) => record.id == id).firstOrNull)
                    ?.name ??
                id,
        ]);
        return false;
      }
      error = null;
      return true;
    } on StoryPublicationUnsupported catch (failure) {
      error =
          '$unsupported${[for (final kind in failure.kinds) kind.name].join(',')}';
      return false;
    } on Object catch (failure) {
      final cause = failure is StoryPublicationFailed ? failure.cause : failure;
      error = cause is EventFailure ? cause.message : '$cause';
      return false;
    } finally {
      publishing = false;
      changed();
    }
  }

  static const outOfMap = 'out-of-map';
  static const deactivated = 'deactivated:';
  static const conflict = 'conflict:';
  static const carrier = 'carrier:';
  static const afterRefused = 'after-refused:';
  static const unsupported = 'publish-unsupported:';
  static const lineRefused = 'line-refused:';

  bool _fits(MapData map, GridPos position, GridSize size) =>
      position.x >= 0 &&
      position.y >= 0 &&
      position.x + size.width <= map.size.width &&
      position.y + size.height <= map.size.height;

  List<ProjectCharacterEntry> get characters =>
      [...?maps.project?.characters]..sort((a, b) => a.name.compareTo(b.name));

  void toggleChoices() {
    choosing = !choosing;
    if (!choosing) cancelAdding();
    changed();
  }

  Future<void> startAdding(MapStoryAddition kind) async {
    final session = view();
    if (session == null || maps.active == null) return;
    adding = kind;
    error = null;
    switch (kind) {
      case MapStoryAddition.sign:
        _arm(session, StudioMapTool.sign);
      case MapStoryAddition.zone:
        _arm(session, StudioMapTool.zone);
      case MapStoryAddition.character:
        session.tool = StudioMapTool.select;
        await loadCharacters();
    }
    changed();
  }

  Future<void> loadCharacters() async {
    if (charactersLoading) return;
    charactersLoading = true;
    charactersError = null;
    changed();
    try {
      await maps.ensureResourceKind('character');
    } on Object catch (failure) {
      charactersError = failure is StateError ? failure.message : '$failure';
    } finally {
      charactersLoading = false;
      changed();
    }
  }

  void chooseCharacter(ProjectCharacterEntry character) {
    final session = view();
    if (session == null || adding != MapStoryAddition.character) return;
    session.character = character;
    _arm(session, StudioMapTool.character);
    changed();
  }

  void cancelAdding() {
    final session = view();
    if (adding != null &&
        session != null &&
        const {
          StudioMapTool.character,
          StudioMapTool.sign,
          StudioMapTool.zone,
        }.contains(session.tool)) {
      session.tool = StudioMapTool.select;
    }
    adding = null;
  }

  bool get armed {
    final tool = view()?.tool;
    return switch (adding) {
      MapStoryAddition.character => tool == StudioMapTool.character,
      MapStoryAddition.sign => tool == StudioMapTool.sign,
      MapStoryAddition.zone => tool == StudioMapTool.zone,
      null => false,
    };
  }

  void reconcile() {
    final map = this.map;
    if (adding == null || map == null || !armed) return;
    if (adding != MapStoryAddition.zone &&
        map.entities.length > _armedEntities) {
      _record(_StorySide.map, maps.active?.undoToken);
      _finish();
    }
  }

  bool addZone(MapRect area) {
    if (adding != MapStoryAddition.zone) return false;
    final applied = _edit((document, project) {
      final ids = document.current.triggers.map((item) => item.id).toSet();
      var index = document.current.triggers.length + 1;
      while (ids.contains('story-zone-$index')) {
        index++;
      }
      final trigger = TriggerEditingCommands(document, project).add(
        MapTrigger(
          id: 'story-zone-$index',
          name: _zoneName(),
          type: TriggerType.event,
          area: area,
        ),
      );
      view()?.select(document, MapSelectionFamily.trigger, trigger.id);
      return true;
    });
    if (applied) _finish();
    return applied;
  }

  bool setCharacter(MapStoryElement element, ProjectCharacterEntry character) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).setCharacter(element.id, character);
        return true;
      });

  void _arm(MapEditingViewportSession session, StudioMapTool tool) {
    _armedEntities = map?.entities.length ?? 0;
    session
      ..brush = null
      ..model3d = null
      ..tile = null
      ..terrain = null
      ..tool = tool;
  }

  void _finish() {
    cancelAdding();
    choosing = false;
    tab = MapStoryTab.properties;
    changed();
  }

  void search(String value) {
    query = value;
    changed();
  }

  void showKind(MapStoryElementKind? value) {
    filter = value;
    changed();
  }

  void openTab(MapStoryTab value) {
    tab = value;
    changed();
  }

  void openBehaviour(int index) {
    behaviour = index;
    changed();
  }
}

class MapBuilderInputSession extends MapEditingInputSession {
  MapBuilderInputSession({
    required super.controller,
    required super.view,
    required this.story,
  });

  final MapBuilderStoryBinding story;

  @override
  MapContextActionContext? contextAt(GridPos position) {
    final context = super.contextAt(position);
    return context == null
        ? null
        : MapGuardedContextActionContext(
            document: context.document,
            project: story.behaviours.project(context.project),
            position: position,
            referenceGuard: context.referenceGuard,
            deletionGuard: story.contextDeletionProblem,
          );
  }

  @override
  void run(MapContextCommand command) {
    final selected = target;
    final document = controller.active;
    final problem = command != MapContextCommand.delete || selected == null
        ? null
        : story.contextDeletionProblem(selected);
    if (problem == null || document == null) return super.run(command);
    dismiss();
    document.error = problem;
    notifyListeners();
  }
}
