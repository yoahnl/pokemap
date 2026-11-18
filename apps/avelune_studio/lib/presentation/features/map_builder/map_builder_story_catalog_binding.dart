import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_dependencies.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';

import 'map_builder_story_binding.dart';

final class MapBuilderStoryCatalogBinding {
  MapBuilderStoryCatalogBinding({
    required this.story,
    required this.maps,
    required this.changed,
  });

  final MapBuilderStoryBinding story;
  final WorldMapSelectionPort maps;
  final void Function() changed;
  MapBuilderStoryBinding? editor;
  String? selectedId;
  String? error;
  bool loading = false;
  int _epoch = 0;
  bool _disposed = false;
  final _listeners = <void Function()>{};

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _changed() {
    changed();
    for (final listener in _listeners.toList()) {
      listener();
    }
  }

  Future<void> sync() async {
    final current = editor;
    final id = current?.selectedBehaviour?.id ?? selectedId;
    if (_disposed ||
        loading ||
        story.publishing ||
        current == null ||
        id == null ||
        (identical(current.project, story.project) &&
            current.editing?.isCurrent?.call() != false)) {
      return;
    }
    await open(id);
  }

  void clear() {
    _epoch++;
    selectedId = null;
    editor = null;
    error = null;
    loading = false;
    _changed();
  }

  Future<bool> open(
    String id, {
    bool checkSavedMap = false,
    bool Function()? isRequested,
  }) => _open(id: id, checkSavedMap: checkSavedMap, isRequested: isRequested);

  Future<bool> prepareCreation(String mapId) => _open(mapId: mapId);

  Future<bool> _open({
    String? id,
    String? mapId,
    bool checkSavedMap = false,
    bool Function()? isRequested,
  }) async {
    if (_disposed || isRequested?.call() == false) return false;
    final epoch = ++_epoch;
    bool requested() =>
        !_disposed && epoch == _epoch && isRequested?.call() != false;
    selectedId = id;
    editor = null;
    error = null;
    loading = true;
    _changed();
    try {
      await story.prepare();
      if (!requested()) return false;
      final project = story.project;
      if (project == null || !story.ready) {
        throw StateError(
          'Le contexte narratif est incomplet. Réessayez son chargement.',
        );
      }
      final record = story.behaviours
          .registry(project)
          ?.records
          .where((record) => record.id == id)
          .firstOrNull;
      final at = record == null ? null : mapStoryLocation(record);
      final entry = project.maps
          .where((entry) => entry.id == (mapId ?? at?.$1))
          .firstOrNull;
      if ((id != null && (record == null || at == null)) || entry == null) {
        throw StateError(
          'Ce comportement est hors carte. Utilisez la réparation dans Carte · Interactions.',
        );
      }
      final document = story.maps.documents[entry.id];
      final draft = story.behaviours.draft;
      final versions = [
        for (final kind in [
          StoryDraftKind.event,
          StoryDraftKind.scene,
          StoryDraftKind.dialogue,
          StoryDraftKind.fact,
        ])
          draft.versionOf(kind),
      ];
      bool unchanged() =>
          [
            StoryDraftKind.event,
            StoryDraftKind.scene,
            StoryDraftKind.dialogue,
            StoryDraftKind.fact,
          ].indexed.every(
            (entry) => draft.versionOf(entry.$2) == versions[entry.$1],
          );
      final savedMap = checkSavedMap || document == null
          ? await maps.loadMap(entry)
          : null;
      if (!requested()) return false;
      final map = document?.current ?? savedMap!;
      bool current() =>
          !_disposed &&
          epoch == _epoch &&
          identical(project, story.project) &&
          (document == null
              ? story.maps.documents[entry.id] == null ||
                    identical(story.maps.documents[entry.id]!.current, map)
              : identical(story.maps.documents[entry.id], document) &&
                    identical(document.current, map));
      if (!current() ||
          !unchanged() ||
          map.id != entry.id ||
          (savedMap != null && savedMap.id != entry.id) ||
          story.behaviours
                  .registry(project)
                  ?.records
                  .where((item) => item.id == id)
                  .firstOrNull !=
              record) {
        throw StateError(
          'Le contexte a changé pendant le chargement. Réessayez.',
        );
      }
      final editing = GameBehaviourEditing(
        project: project,
        map: map,
        behaviours: story.behaviours,
        eventId: id,
        isCurrent: current,
      );
      if (editing.problem case final problem? when !editing.canRepairScene) {
        throw StateError(problem);
      }
      final sceneId = record?.sceneId;
      final scene = sceneId == null
          ? null
          : story.behaviours.draft.effective(
              StoryDraftKind.scene,
              sceneId,
              story.behaviours.saved(project),
            );
      final dialogueIds = record == null
          ? const <String>[]
          : GameBehaviourDependencies(
              story.behaviours.project(project),
              record,
            ).dialogueIds;
      for (final dialogueId in dialogueIds) {
        if (draft.isTouched(StoryDraftKind.dialogue, dialogueId) ||
            story.behaviours.dialogues[dialogueId] != null) {
          continue;
        }
        final load = story.loadDialogue;
        if (load == null) {
          throw StateError('Le texte de ce comportement est indisponible.');
        }
        final dialogue = await load(dialogueId);
        if (!requested()) return false;
        if (!current() || !unchanged() || dialogue.entry.id != dialogueId) {
          throw StateError('Le contexte du texte a changé. Réessayez.');
        }
        story.behaviours.dialogues.remember(dialogue);
      }
      if (!current() ||
          !unchanged() ||
          (editing.problem != null && !editing.canRepairScene)) {
        throw StateError(
          'Le contexte a changé pendant le chargement. Réessayez.',
        );
      }
      if (record != null) draft.load(StoryDraftKind.event, record.id, record);
      if (scene != null) draft.load(StoryDraftKind.scene, scene.id, scene);
      final binding = MapBuilderStoryBinding(
        maps: story.maps,
        changed: _changed,
        view: () => null,
        editing: editing,
        onBehaviourRecorded: story.recordBehaviourStep,
        publicationBlocked: () => story.publishing,
        loadDialogue: story.loadDialogue,
        behaviourName: story.behaviourName,
      )..trame = story.trame;
      binding.openScene = story.openScene;
      if (at != null) {
        final element = binding.elements!.byKey('${at.$2.name}:${at.$3}')!;
        binding.select(element);
        binding.openBehaviour(
          element.behaviours.indexWhere((record) => record.id == id),
        );
      }
      editor = binding;
      return true;
    } on Object catch (failure) {
      if (requested()) {
        error = failure is StateError ? failure.message : '$failure';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        _changed();
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    editor = null;
    _listeners.clear();
  }
}
