import 'package:map_core/map_core.dart';

typedef MapStoryBehaviourOperation = NarrativeEventAuthoringResult Function(
  NarrativeEventAuthoringContext c,
);

typedef MapStoryBehaviourChange = ({
  String id,
  NarrativeEventRecord? base,
  NarrativeEventRecord? current,
});

const _workingRevision = 'map-story-working-copy';

typedef _Edit = ({NarrativeEventRecord? base, NarrativeEventRecord? current});

typedef _Step = Map<String, ({_Edit before, _Edit after})>;

final class MapStoryBehaviours {
  ProjectMediaCatalog? media;
  final _edits = <String, _Edit>{};
  final _undo = <_Step>[];
  final _redo = <_Step>[];
  NarrativeEventRegistry? _shell;
  var _version = 0;
  (NarrativeEventRegistry?, int, NarrativeEventRegistry?)? _overlay;
  (NarrativeEventRegistry?, Map<String, NarrativeEventRecord>)? _index;
  (
    ProjectManifest,
    MapData,
    ProjectMediaCatalog?,
    NarrativeEventProjectCatalogBasis,
  )?
  _basis;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  NarrativeEventRegistry? registry(ProjectManifest project) {
    final saved = project.eventRegistry;
    if (_edits.isEmpty) return saved;
    final cached = _overlay;
    if (cached != null &&
        identical(cached.$1, saved) &&
        cached.$2 == _version) {
      return cached.$3;
    }
    final shell = saved ?? _shell;
    final savedIds = <String>{};
    final records = <NarrativeEventRecord>[];
    for (final record in saved?.records ?? const <NarrativeEventRecord>[]) {
      savedIds.add(record.id);
      final edit = _edits[record.id];
      if (edit == null) {
        records.add(record);
      } else if (edit.current case final current?) {
        records.add(current);
      }
    }
    for (final MapEntry(:key, :value) in _edits.entries) {
      if (!savedIds.contains(key) && value.current != null) {
        records.add(value.current!);
      }
    }
    final registry = shell == null
        ? null
        : NarrativeEventRegistry(
            schemaVersion: shell.schemaVersion,
            mode: shell.mode,
            records: records,
            legacyClaims: shell.legacyClaims,
          );
    _overlay = (saved, _version, registry);
    return registry;
  }

  ProjectManifest project(ProjectManifest project) => _edits.isEmpty
      ? project
      : project.copyWith(eventRegistry: registry(project));

  bool dirty(ProjectManifest project) {
    final saved = _savedRecords(project);
    return _edits.entries.any((edit) => saved[edit.key] != edit.value.current);
  }

  List<MapStoryBehaviourChange> changes(ProjectManifest project) {
    final saved = _savedRecords(project);
    return [
      for (final MapEntry(:key, :value) in _edits.entries)
        if (saved[key] != value.current && saved[key] == value.base)
          (id: key, base: value.base, current: value.current),
    ];
  }

  List<String> conflicts(ProjectManifest project) {
    final saved = _savedRecords(project);
    return [
      for (final MapEntry(:key, :value) in _edits.entries)
        if (saved[key] != value.current && saved[key] != value.base) key,
    ];
  }

  NarrativeEventRecord? draftOf(String id) => _edits[id]?.current;

  Map<String, NarrativeEventRecord> _savedRecords(ProjectManifest project) {
    final registry = project.eventRegistry;
    final cached = _index;
    if (cached != null && identical(cached.$1, registry)) return cached.$2;
    final index = {
      for (final record in registry?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    _index = (registry, index);
    return index;
  }

  void prepare(ProjectManifest project, MapData map) =>
      _basisFor(project, map, registry(project));

  NarrativeEventAuthoringContext context(
    ProjectManifest project,
    MapData map,
  ) => _context(project, registry(project), map);

  NarrativeEventAuthoringContext _context(
    ProjectManifest project,
    NarrativeEventRegistry? registry,
    MapData map,
  ) => NarrativeEventAuthoringContext.ofCatalog(
    registryState: registry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry),
    revision: _workingRevision,
    catalog: _basisFor(
      project,
      map,
      registry,
    ).catalog(registry, deferFingerprints: true),
    sourceIndex: buildNarrativeEventSourceIndex(registry?.records ?? const []),
  );

  NarrativeEventProjectCatalogBasis _basisFor(
    ProjectManifest project,
    MapData map,
    NarrativeEventRegistry? registry,
  ) {
    final cached = _basis;
    if (cached != null &&
        identical(cached.$1, project) &&
        identical(cached.$2, map) &&
        identical(cached.$3, media) &&
        cached.$4.fits(registry)) {
      return cached.$4;
    }
    final current = identical(registry, project.eventRegistry)
        ? project
        : project.copyWith(eventRegistry: registry);
    final scenes = <String, List<SceneAsset>>{};
    for (final scene in current.scenes) {
      scenes.putIfAbsent(scene.id, () => []).add(scene);
    }
    final basis = prepareNarrativeEventProjectCatalog(
      project: current,
      maps: [map],
      mapInventoryComplete: false,
      presentationMediaCatalog: media,
      lookupRewardScenes: (id) => scenes[id] ?? const [],
    );
    _basis = (project, map, media, basis);
    return basis;
  }

  ({String? eventId, String? problem}) apply(
    ProjectManifest project,
    MapData map,
    List<MapStoryBehaviourOperation> operations,
  ) {
    final start = this.registry(project);
    var registry = start;
    String? eventId;
    for (final operation in operations) {
      final context = _context(project, registry, map);
      final result = operation(context);
      if (result.status == NarrativeEventAuthoringStatus.noOp) continue;
      if (result.status != NarrativeEventAuthoringStatus.applied) {
        final blocking = context.catalog.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity ==
                  NarrativeEventProjectDiagnosticSeverity.error,
            )
            .firstOrNull;
        return (
          eventId: null,
          problem: [
            result.humanReason ?? 'Cette modification est refusée.',
            ?blocking?.message,
          ].join(' '),
        );
      }
      registry = result.nextRegistry;
      eventId = result.eventId ?? eventId;
    }
    if (identical(registry, start) || registry == start) {
      return (eventId: eventId, problem: null);
    }
    final saved = _savedRecords(project);
    final before = {
      for (final record in start?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    final after = {
      for (final record in registry?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    final step = <String, ({_Edit before, _Edit after})>{};
    for (final id in {...before.keys, ...after.keys}) {
      if (identical(before[id], after[id]) || before[id] == after[id]) continue;
      final previous = _edits[id] ?? (base: saved[id], current: saved[id]);
      step[id] = (
        before: previous,
        after: (base: previous.base, current: after[id]),
      );
    }
    _shell = registry;
    if (step.isEmpty) return (eventId: eventId, problem: null);
    _play(step, forward: true);
    _undo.add(step);
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    return (eventId: eventId, problem: null);
  }

  void undo() {
    if (_undo.isEmpty) return;
    final step = _undo.removeLast();
    _play(step, forward: false);
    _redo.add(step);
  }

  void redo() {
    if (_redo.isEmpty) return;
    final step = _redo.removeLast();
    _play(step, forward: true);
    _undo.add(step);
  }

  void _play(_Step step, {required bool forward}) {
    for (final MapEntry(:key, :value) in step.entries) {
      final edit = forward ? value.after : value.before;
      if (edit.base == edit.current) {
        _edits.remove(key);
      } else {
        _edits[key] = edit;
      }
    }
    _version++;
  }

  void settle(ProjectManifest saved, {Set<String>? only}) {
    final records = _savedRecords(saved);
    final settled = [
      for (final MapEntry(:key, :value) in _edits.entries)
        if ((only == null || only.contains(key)) &&
            records[key] == value.current)
          (key, value),
    ];
    if (settled.isEmpty) return;
    for (final (id, edit) in settled) {
      _edits.remove(id);
      for (final step in [..._undo, ..._redo]) {
        final entry = step[id];
        if (entry == null) continue;
        step[id] = (
          before: _rebased(entry.before, edit.base, edit.current),
          after: _rebased(entry.after, edit.base, edit.current),
        );
      }
    }
    _version++;
  }

  _Edit _rebased(
    _Edit edit,
    NarrativeEventRecord? from,
    NarrativeEventRecord? to,
  ) => edit.base == from ? (base: to, current: edit.current) : edit;
}
