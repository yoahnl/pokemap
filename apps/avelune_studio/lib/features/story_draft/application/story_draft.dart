import 'package:map_core/map_core_domain.dart';

import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';
import 'story_draft_history.dart';
import 'story_draft_projection.dart';

final class StoryDraft {
  NarrativeEventRegistry? _eventRegistryShell;
  final _loaded = <StoryDraftRef, Object?>{};
  final _edits =
      <StoryDraftKind<Object>, Map<String, StoryDraftEntry<Object>>>{};
  final _versions = <StoryDraftKind<Object>, int>{};
  final _history = StoryDraftHistory();
  late final _projection = StoryDraftProjection(
    (kind) => _edits[kind] ?? const {},
    (kind) => _versions[kind] ?? 0,
  );
  StoryDraftStep? _open;
  int _recorded = 0;

  NarrativeEventRegistry? get eventRegistryShell => _eventRegistryShell;

  set eventRegistryShell(NarrativeEventRegistry? shell) {
    if (identical(shell, _eventRegistryShell)) return;
    _eventRegistryShell = shell;
    _bump(StoryDraftKind.event);
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  int get recorded => _recorded;

  int versionOf(StoryDraftKind<Object> kind) => _versions[kind] ?? 0;

  bool load<T extends Object>(StoryDraftKind<T> kind, String id, T? saved) {
    if (saved != null && kind.idOf(saved) != id) {
      throw ArgumentError.value(saved, 'saved', 'is not the ${kind.name} $id');
    }
    if (isTouched(kind, id)) return false;
    _loaded[(kind: kind, id: id)] = saved;
    return true;
  }

  bool isLoaded(StoryDraftKind<Object> kind, String id) =>
      _loaded.containsKey((kind: kind, id: id));

  bool isTouched(StoryDraftKind<Object> kind, String id) =>
      _edits[kind]?.containsKey(id) ?? false;

  Iterable<String> touched(StoryDraftKind<Object> kind) =>
      _edits[kind]?.keys ?? const [];

  Iterable<StoryDraftRef> get touchedRefs => _touched().map((e) => e.ref);

  StoryDraftEntry<T>? entryOf<T extends Object>(
    StoryDraftKind<T> kind,
    String id,
  ) => _edits[kind]?[id] as StoryDraftEntry<T>?;

  T? currentOf<T extends Object>(StoryDraftKind<T> kind, String id) {
    final edit = _edits[kind]?[id];
    return (edit == null ? _loaded[(kind: kind, id: id)] : edit.current) as T?;
  }

  T? baseOf<T extends Object>(StoryDraftKind<T> kind, String id) {
    final edit = _edits[kind]?[id];
    return (edit == null ? _loaded[(kind: kind, id: id)] : edit.base) as T?;
  }

  T? effective<T extends Object>(
    StoryDraftKind<T> kind,
    String id,
    StoryDraftSaved saved,
  ) {
    final edit = _edits[kind]?[id];
    return (edit == null ? saved.read(kind, id) : edit.current) as T?;
  }

  void put<T extends Object>(StoryDraftKind<T> kind, T value) =>
      group(() => _write(kind, kind.idOf(value), value));

  void remove(StoryDraftKind<Object> kind, String id) =>
      group(() => _write(kind, id, null));

  void group(void Function() body) {
    if (_open != null) {
      body();
      return;
    }
    final step = _open = {};
    try {
      body();
    } on Object {
      _play(step, forward: false);
      rethrow;
    } finally {
      _open = null;
    }
    step.removeWhere((_, change) => change.before == change.after);
    if (step.isEmpty) return;
    _history.record(step);
    _recorded++;
  }

  void undo() => _travel(redo: false);

  void redo() => _travel(redo: true);

  bool dirty(StoryDraftSaved saved, {StoryDraftKind<Object>? kind}) =>
      _touched(kind)
          .any((edit) => saved.read(edit.kind, edit.id) != edit.current);

  List<StoryDraftEntry<Object>> changes(
    StoryDraftSaved saved, {
    StoryDraftKind<Object>? kind,
  }) => [
    for (final edit in _touched(kind))
      if (saved.read(edit.kind, edit.id) case final stored
          when stored != edit.current && stored == edit.base)
        edit,
  ];

  List<StoryDraftEntry<T>> changesOf<T extends Object>(
    StoryDraftKind<T> kind,
    StoryDraftSaved saved,
  ) => [
    for (final change in changes(saved, kind: kind))
      change as StoryDraftEntry<T>,
  ];

  List<StoryDraftRef> conflicts(
    StoryDraftSaved saved, {
    StoryDraftKind<Object>? kind,
  }) => [
    for (final edit in _touched(kind))
      if (saved.read(edit.kind, edit.id) case final stored
          when stored != edit.current && stored != edit.base)
        edit.ref,
  ];

  void rebase(StoryDraftSaved saved, {Set<StoryDraftRef>? only}) {
    final settled = [
      for (final edit in _touched())
        if ((only == null || only.contains(edit.ref)) &&
            saved.read(edit.kind, edit.id) == edit.current)
          edit,
    ];
    for (final edit in settled) {
      _rebase(edit.ref, edit.base, edit.current);
    }
  }

  void acknowledge(
    Iterable<StoryDraftEntry<Object>> published,
    StoryDraftSaved saved,
  ) {
    final refs = <StoryDraftRef>{};
    for (final entry in published) {
      refs.add(entry.ref);
      final stored = saved.read(entry.kind, entry.id);
      if (stored != entry.current || !isLoaded(entry.kind, entry.id)) continue;
      if (baseOf(entry.kind, entry.id) == entry.base) {
        _rebase(entry.ref, entry.base, stored);
      }
    }
    rebase(saved, only: refs);
  }

  NarrativeEventRegistry? eventRegistry(NarrativeEventRegistry? saved) =>
      _projection.eventRegistry(saved, _eventRegistryShell);

  ProjectManifest project(ProjectManifest project) =>
      _projection.project(project, _eventRegistryShell);

  Iterable<StoryDraftEntry<Object>> _touched([StoryDraftKind<Object>? kind]) =>
      kind == null
      ? [for (final each in StoryDraftKind.values) ...?_edits[each]?.values]
      : [...?_edits[kind]?.values];

  void _write(StoryDraftKind<Object> kind, String id, Object? value) {
    final ref = (kind: kind, id: id);
    if (!_loaded.containsKey(ref)) {
      throw StateError('The ${kind.name} $id was not loaded into the draft.');
    }
    final before =
        _edits[kind]?[id] ??
        kind.entry(id, base: _loaded[ref], current: _loaded[ref]);
    if (before.current == value) return;
    final after = kind.entry(id, base: before.base, current: value);
    final step = _open!;
    step[ref] = (before: step[ref]?.before ?? before, after: after);
    _apply(after);
  }

  void _travel({required bool redo}) {
    if (_open != null) {
      throw StateError('The history cannot move while a step is written.');
    }
    final step = _history.take(redo: redo);
    if (step != null) _play(step, forward: redo);
  }

  void _play(StoryDraftStep step, {required bool forward}) {
    for (final change in step.values) {
      _apply(forward ? change.after : change.before);
    }
  }

  void _apply(StoryDraftEntry<Object> entry) {
    final edits = _edits.putIfAbsent(entry.kind, () => {});
    if (entry.touched) {
      edits[entry.id] = entry;
    } else {
      edits.remove(entry.id);
    }
    _loaded[entry.ref] = entry.base;
    _bump(entry.kind);
  }

  void _bump(StoryDraftKind<Object> kind) =>
      _versions[kind] = (_versions[kind] ?? 0) + 1;

  void _rebase(StoryDraftRef ref, Object? from, Object? to) {
    if (from == to) return;
    final kind = ref.kind;
    if (baseOf(kind, ref.id) == from) {
      _apply(kind.entry(ref.id, base: to, current: currentOf(kind, ref.id)));
    }
    _history.rebase(ref, from, to);
  }
}
