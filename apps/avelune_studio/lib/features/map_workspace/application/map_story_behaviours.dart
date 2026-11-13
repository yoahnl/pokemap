import 'package:map_core/map_core.dart';

typedef MapStoryBehaviourOperation = NarrativeEventAuthoringResult Function(
  NarrativeEventAuthoringContext c,
);

typedef MapStoryBehaviourChange = ({
  String id,
  NarrativeEventRecord? base,
  NarrativeEventRecord? current,
});

final class MapStoryBehaviours {
  ProjectMediaCatalog? media;
  NarrativeEventRegistry? _working;
  bool _touched = false;
  final _undo = <(bool, NarrativeEventRegistry?)>[];
  final _redo = <(bool, NarrativeEventRegistry?)>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  NarrativeEventRegistry? registry(ProjectManifest project) =>
      _touched ? _working : project.eventRegistry;

  ProjectManifest project(ProjectManifest project) =>
      _touched ? project.copyWith(eventRegistry: _working) : project;

  bool dirty(ProjectManifest project) => changes(project).isNotEmpty;

  List<MapStoryBehaviourChange> changes(ProjectManifest project) {
    if (!_touched) return const [];
    final saved = {
      for (final record in project.eventRegistry?.records ?? const [])
        record.id: record,
    };
    final working = {
      for (final record in _working?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    return [
      for (final id in {...saved.keys, ...working.keys})
        if (saved[id] != working[id])
          (id: id, base: saved[id], current: working[id]),
    ];
  }

  NarrativeEventAuthoringContext context(
    ProjectManifest project,
    MapData map,
  ) => _context(this.project(project), map);

  NarrativeEventAuthoringContext _context(
    ProjectManifest current,
    MapData map,
  ) {
    final registry = current.eventRegistry;
    final scenes = <String, List<SceneAsset>>{};
    for (final scene in current.scenes) {
      scenes.putIfAbsent(scene.id, () => []).add(scene);
    }
    final catalog = buildNarrativeEventProjectCatalog(
      project: current,
      maps: [map],
      mapInventoryComplete: false,
      presentationMediaCatalog: media,
      lookupRewardScenes: (id) => scenes[id] ?? const [],
    );
    return NarrativeEventAuthoringContext(
      registryState: registry == null
          ? EventRegistryDecodeResult.absent()
          : EventRegistryDecodeResult.decoded(registry),
      revision: catalog.manifestHash,
      catalog: catalog,
      sourceIndex: buildNarrativeEventSourceIndex(
        registry?.records ?? const [],
      ),
      manifestHash: catalog.manifestHash,
      mapHashes: catalog.mapHashes,
    );
  }

  ({String? eventId, String? problem}) apply(
    ProjectManifest project,
    MapData map,
    List<MapStoryBehaviourOperation> operations,
  ) {
    final before = (_touched, _working);
    var registry = this.registry(project);
    String? eventId;
    for (final operation in operations) {
      final context = _context(project.copyWith(eventRegistry: registry), map);
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
    if (registry == this.registry(project)) {
      return (eventId: eventId, problem: null);
    }
    _undo.add(before);
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    _touched = true;
    _working = registry;
    return (eventId: eventId, problem: null);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add((_touched, _working));
    final (touched, working) = _undo.removeLast();
    _touched = touched;
    _working = working;
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add((_touched, _working));
    final (touched, working) = _redo.removeLast();
    _touched = touched;
    _working = working;
  }

  void settle(ProjectManifest saved) {
    if (_touched && changes(saved).isEmpty) {
      _touched = false;
      _working = null;
    }
  }
}
