import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/story_port.dart';
import 'story_edit_history.dart';

part 'story_workspace_publication.dart';
part 'story_workspace_reload.dart';

class StoryWorkspaceController {
  StoryWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.sceneDrafts,
  }) {
    narrative.saveStoryDrafts = saveAll;
    narrative.storyDraftsBusy = _isBusy;
    workspace.addListener(reconcile);
    reconcile();
  }
  final NarrativeWorkspaceController narrative;
  final StoryPort port;
  final void Function() changed;
  final List<SceneAsset> Function()? sceneDrafts;
  final _bases = <String, StorylineAsset?>{};
  final _factBases = <String, NarrativeFactDefinition?>{};
  final _history = StoryEditHistory();
  String? activeId;
  String? error;
  bool busy = false;
  bool _disposed = false;
  MapWorkspaceController get workspace => narrative.workspace;
  bool get _closed => _disposed || workspace.isDisposed;
  bool get dirty =>
      narrative.pendingStories.isNotEmpty ||
      narrative.pendingStoryDeletions.isNotEmpty ||
      narrative.pendingFacts.isNotEmpty;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  List<StorylineAsset> get stories => narrative.stories;
  StorylineAsset? get active =>
      stories.where((story) => story.id == activeId).firstOrNull;
  ProjectManifest? _cached;
  List<Object?> _signature = [];
  ProjectManifest get project {
    final scenes = sceneDrafts?.call() ?? narrative.project.scenes;
    final signature = <Object?>[
      narrative.project,
      ...narrative.pendingStories.values,
      ...narrative.pendingStoryDeletions,
      ...narrative.pendingFacts.values,
      ...scenes,
    ];
    if (_cached != null &&
        signature.length == _signature.length &&
        List.generate(
          signature.length,
          (i) => i,
        ).every((i) => signature[i] == _signature[i])) {
      return _cached!;
    }
    _signature = signature;
    return _cached = narrative.project.copyWith(
      storylines: stories,
      facts: narrative.facts,
      scenes: scenes,
    );
  }

  bool open(String id) {
    if (_closed) return false;
    reconcile();
    if (!stories.any((story) => story.id == id)) {
      error = 'Cette histoire ne figure plus dans le projet.';
      changed();
      return false;
    }
    activeId = id;
    changed();
    return true;
  }

  StorylineAsset? create(
    String name, {
    StorylineType type = StorylineType.main,
  }) {
    if (_closed || name.trim().isEmpty) return null;
    final story = StorylineAsset(
      id: narrative.identity('histoire'),
      title: name.trim(),
      type: type,
    );
    if (!apply(createStoryline(project, storyline: story))) return null;
    activeId = story.id;
    changed();
    return story;
  }

  bool apply(StorylineMutationResult result) {
    if (!result.isApplied) {
      error = result.disposition == StorylineMutationDisposition.noChange
          ? null
          : result.message;
      changed();
      return false;
    }
    return applyProject(result.before, result.after);
  }

  bool mutate(ProjectManifest Function(ProjectManifest) operation) {
    if (_closed) return false;
    try {
      final before = project;
      return applyProject(before, operation(before));
    } catch (failure) {
      error = failure.toString();
      changed();
      return false;
    }
  }

  bool connect(StorylineProgressionConnectRequest request) =>
      _progression(connectStorylineProgressionEdge(project, request));
  bool disconnect(String edgeId, {String? storylineId}) => _progression(
    disconnectStorylineProgressionEdge(
      project,
      storylineId: storylineId ?? activeId!,
      edgeId: edgeId,
    ),
  );
  bool _progression(StorylineProgressionMutationResult result) {
    if (result.disposition != StorylineProgressionMutationDisposition.applied) {
      error = result.message;
      changed();
      return false;
    }
    return applyProject(result.before, result.after);
  }

  bool applyProject(ProjectManifest before, ProjectManifest after) {
    if (_closed) return false;
    final previous = {for (final s in before.storylines) s.id: s};
    final next = {for (final s in after.storylines) s.id: s};
    final ids = {
      ...previous.keys,
      ...next.keys,
    }.where((id) => previous[id] != next[id]).toSet();
    if (ids.isEmpty) return false;
    final current = {for (final s in stories) s.id: s};
    if (ids.any((id) => current[id] != previous[id])) {
      error = 'L’histoire a changé depuis le début de cette édition.';
      changed();
      return false;
    }
    for (final id in ids) {
      _bases.putIfAbsent(
        id,
        () => narrative.project.storylines
            .where((story) => story.id == id)
            .firstOrNull,
      );
    }
    final delta = StoryEditDelta(
      {for (final id in ids) id: previous[id]},
      {for (final id in ids) id: next[id]},
    );
    _history.add(delta);
    _write(delta.after);
    return true;
  }

  void restore({required bool redo}) {
    if (_closed) return;
    reconcile();
    final delta = _history.take(redo: redo);
    if (delta != null) _write(redo ? delta.after : delta.before);
  }

  void _write(Map<String, StorylineAsset?> values) {
    for (final entry in values.entries) {
      final canonical = narrative.project.storylines
          .where((s) => s.id == entry.key)
          .firstOrNull;
      if (entry.value == canonical) {
        narrative.pendingStories.remove(entry.key);
        narrative.pendingStoryDeletions.remove(entry.key);
      } else if (entry.value == null) {
        narrative.pendingStories.remove(entry.key);
        narrative.pendingStoryDeletions.add(entry.key);
      } else {
        narrative.pendingStories[entry.key] = entry.value!;
        narrative.pendingStoryDeletions.remove(entry.key);
      }
    }
    error = null;
    changed();
  }

  void reconcile() {
    if (_closed || workspace.project == null || busy) return;
    final changedBases = <String>{};
    final canonical = {for (final s in narrative.project.storylines) s.id: s};
    for (final entry in _bases.entries.toList()) {
      if (canonical[entry.key] == entry.value) continue;
      final pending = narrative.pendingStories[entry.key];
      final deleted = narrative.pendingStoryDeletions.contains(entry.key);
      if (pending != null || deleted) {
        error =
            'Une histoire ouverte a changé. Son brouillon est conservé ; rechargez-la pour résoudre le conflit.';
        continue;
      }
      _bases[entry.key] = canonical[entry.key];
      changedBases.add(entry.key);
    }
    _history.invalidate(changedBases);
    for (final story in stories) {
      _bases.putIfAbsent(story.id, () => canonical[story.id]);
    }
    for (final fact in narrative.pendingFacts.values) {
      _factBases.putIfAbsent(
        fact.id,
        () => narrative.project.facts.where((f) => f.id == fact.id).firstOrNull,
      );
    }
  }

  bool discard(String id) {
    if (_closed || busy) return false;
    _discardStory(id);
    return true;
  }

  void _discardStory(String id) {
    narrative.pendingStories.remove(id);
    narrative.pendingStoryDeletions.remove(id);
    _bases[id] = narrative.project.storylines
        .where((s) => s.id == id)
        .firstOrNull;
    _history.invalidate({id});
    error = null;
    changed();
  }

  Future<bool> reload(String id, {StorylineAsset? expectedStory}) =>
      _reloadStory(id, expectedStory: expectedStory);

  bool _isBusy() => busy;
  Future<bool> save() => saveAll();
  Future<bool> saveAll() => _publishAll();
  void dispose() {
    _disposed = true;
    workspace.removeListener(reconcile);
    if (narrative.saveStoryDrafts == saveAll) narrative.saveStoryDrafts = null;
    if (narrative.storyDraftsBusy == _isBusy) narrative.storyDraftsBusy = null;
  }
}
