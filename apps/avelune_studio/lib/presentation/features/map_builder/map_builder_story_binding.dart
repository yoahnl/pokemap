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
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
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

part 'map_builder_input_session.dart';
part 'map_builder_story_additions.dart';
part 'map_builder_story_behaviour_editing.dart';
part 'map_builder_story_cases_binding.dart';
part 'map_builder_story_conditions_binding.dart';
part 'map_builder_story_element_editing.dart';
part 'map_builder_story_history.dart';
part 'map_builder_story_line_binding.dart';
part 'map_builder_story_publication.dart';
part 'map_builder_story_selection.dart';

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
  NarrativeIndexPort? narrative;
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

  static const outOfMap = 'out-of-map';
  static const deactivated = 'deactivated:';
  static const conflict = 'conflict:';
  static const carrier = 'carrier:';
  static const afterRefused = 'after-refused:';
  static const unsupported = 'publish-unsupported:';
  static const lineRefused = 'line-refused:';
}
