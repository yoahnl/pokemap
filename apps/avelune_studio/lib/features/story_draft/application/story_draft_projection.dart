import 'package:map_core/map_core_domain.dart';

import '../domain/story_dialogue_source.dart';
import '../domain/story_draft_entry.dart';

final class StoryDraftProjection {
  StoryDraftProjection(this._edits, this._version);

  final Map<String, StoryDraftEntry<Object>> Function(StoryDraftKind<Object>)
  _edits;
  final int Function(StoryDraftKind<Object>) _version;
  final _overlays = <StoryDraftKind<Object>, (Object?, int, Object?)>{};
  (ProjectManifest, List<int>, ProjectManifest)? _projected;

  NarrativeEventRegistry? eventRegistry(
    NarrativeEventRegistry? saved,
    NarrativeEventRegistry? shell,
  ) {
    if (_edits(StoryDraftKind.event).isEmpty) return saved;
    final frame = saved ?? shell;
    return _overlay(
      StoryDraftKind.event,
      saved,
      () => frame == null
          ? null
          : NarrativeEventRegistry(
              schemaVersion: frame.schemaVersion,
              mode: frame.mode,
              records: _merged(
                StoryDraftKind.event,
                saved?.records ?? const [],
                (record) => record,
              ),
              legacyClaims: frame.legacyClaims,
            ),
    );
  }

  ProjectManifest project(
    ProjectManifest project,
    NarrativeEventRegistry? shell,
  ) {
    if (StoryDraftKind.values.every((kind) => _edits(kind).isEmpty)) {
      return project;
    }
    final versions = [for (final kind in StoryDraftKind.values) _version(kind)];
    final cached = _projected;
    if (cached != null &&
        identical(cached.$1, project) &&
        _same(cached.$2, versions)) {
      return cached.$3;
    }
    List<V> list<T extends Object, V extends Object>(
      StoryDraftKind<T> kind,
      List<V> saved,
      V Function(T value) stored,
    ) => _edits(kind).isEmpty
        ? saved
        : _overlay(kind, project, () => _merged(kind, saved, stored));
    final projected = project.copyWith(
      eventRegistry: eventRegistry(project.eventRegistry, shell),
      scenes: list(StoryDraftKind.scene, project.scenes, (scene) => scene),
      dialogues: list(
        StoryDraftKind.dialogue,
        project.dialogues,
        (StoryDialogueSource dialogue) => dialogue.entry,
      ),
      facts: list(StoryDraftKind.fact, project.facts, (fact) => fact),
      storylines: list(
        StoryDraftKind.story,
        project.storylines,
        (story) => story,
      ),
      worldRules: list(
        StoryDraftKind.worldRule,
        project.worldRules,
        (rule) => rule,
      ),
    );
    _projected = (project, versions, projected);
    return projected;
  }

  bool _same(List<int> left, List<int> right) {
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  V _overlay<V>(
    StoryDraftKind<Object> kind,
    Object? source,
    V Function() build,
  ) {
    final version = _version(kind);
    final cached = _overlays[kind];
    if (cached != null &&
        identical(cached.$1, source) &&
        cached.$2 == version) {
      return cached.$3 as V;
    }
    final value = build();
    _overlays[kind] = (source, version, value);
    return value;
  }

  List<V> _merged<T extends Object, V extends Object>(
    StoryDraftKind<T> kind,
    Iterable<V> saved,
    V Function(T value) stored,
  ) {
    final positions = <String, int>{};
    final merged = <V?>[];
    for (final value in saved) {
      positions[value is ProjectDialogueEntry ? value.id : kind.idOf(value)] =
          merged.length;
      merged.add(value);
    }
    final created = <V>[];
    for (final edit in _edits(kind).values) {
      final current = edit.current as T?;
      final position = positions[edit.id];
      if (position != null) {
        merged[position] = current == null ? null : stored(current);
      } else if (current != null) {
        created.add(stored(current));
      }
    }
    return [...merged.nonNulls, ...created];
  }
}
