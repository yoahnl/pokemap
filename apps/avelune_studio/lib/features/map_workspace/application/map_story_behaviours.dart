import 'package:map_core/map_core_domain.dart';

import '../../story_draft/application/story_draft.dart';
import '../../story_draft/application/story_draft_manifest_reader.dart';
import '../../story_draft/application/story_saved_dialogues.dart';
import '../../story_draft/application/story_saved_records.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../../story_draft/domain/story_draft_saved.dart';

typedef MapStoryBehaviourOperation = NarrativeEventAuthoringResult Function(
  NarrativeEventAuthoringContext c,
);

typedef MapStoryBehaviourChange = ({
  String id,
  NarrativeEventRecord? base,
  NarrativeEventRecord? current,
});

const _workingRevision = 'map-story-working-copy';

const _event = StoryDraftKind.event;

const _catalogKinds = <StoryDraftKind<Object>>[
  StoryDraftKind.scene,
  StoryDraftKind.dialogue,
  StoryDraftKind.fact,
];

final class MapStoryBehaviours {
  MapStoryBehaviours({StoryDraft? draft}) : draft = draft ?? StoryDraft();

  final StoryDraft draft;
  final dialogues = StorySavedDialogues();
  final records = StorySavedRecords();
  late final StoryDraftSaved _beyond = _SavedBeyond(dialogues, records);
  ProjectMediaCatalog? media;
  final _reader = StoryDraftManifestReader();
  (
    ProjectManifest,
    List<int>,
    MapData,
    ProjectMediaCatalog?,
    NarrativeEventProjectCatalogBasis,
  )?
  _basis;

  bool get canUndo => draft.canUndo;
  bool get canRedo => draft.canRedo;

  StoryDraftSaved saved(ProjectManifest project) =>
      _reader.of(project, beyond: _beyond);

  NarrativeEventRegistry? registry(ProjectManifest project) =>
      draft.eventRegistry(project.eventRegistry);

  ProjectManifest project(ProjectManifest project) => draft.project(project);

  bool dirty(ProjectManifest project) =>
      draft.dirty(saved(project), kind: _event);

  List<MapStoryBehaviourChange> changes(ProjectManifest project) => [
    for (final change in draft.changesOf(_event, saved(project)))
      (id: change.id, base: change.base, current: change.current),
  ];

  List<String> conflicts(ProjectManifest project) => [
    for (final ref in draft.conflicts(saved(project))) ref.id,
  ];

  NarrativeEventRecord? draftOf(String id) =>
      draft.entryOf(_event, id)?.current;

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
    final sections = [for (final kind in _catalogKinds) draft.versionOf(kind)];
    final cached = _basis;
    if (cached != null &&
        identical(cached.$1, project) &&
        _same(cached.$2, sections) &&
        identical(cached.$3, map) &&
        identical(cached.$4, media) &&
        cached.$5.fits(registry)) {
      return cached.$5;
    }
    final staged = _catalogKinds.any((kind) => draft.touched(kind).isNotEmpty)
        ? draft.project(project)
        : project;
    final current =
        identical(staged, project) && identical(registry, project.eventRegistry)
        ? project
        : staged.copyWith(eventRegistry: registry);
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
    _basis = (project, sections, map, media, basis);
    return basis;
  }

  bool _same(List<int> left, List<int> right) {
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
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
    final saved = this.saved(project);
    final before = {
      for (final record in start?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    final after = {
      for (final record in registry?.records ?? const <NarrativeEventRecord>[])
        record.id: record,
    };
    draft.eventRegistryShell = registry;
    draft.group(() {
      for (final id in {...before.keys, ...after.keys}) {
        if (identical(before[id], after[id]) || before[id] == after[id]) {
          continue;
        }
        draft.load(_event, id, saved.read(_event, id) as NarrativeEventRecord?);
        switch (after[id]) {
          case final record?:
            draft.put(_event, record);
          case null:
            draft.remove(_event, id);
        }
      }
    });
    return (eventId: eventId, problem: null);
  }

  void undo() => draft.undo();

  void redo() => draft.redo();

  void settle(ProjectManifest saved) => draft.rebase(this.saved(saved));

  void rememberPublished(Iterable<StoryDraftEntry<Object>> published) {
    for (final entry in published) {
      switch (entry.current) {
        case final NarrativeFactDefinition fact:
          records.rememberFact(fact);
        case final WorldRuleDefinition rule:
          records.rememberRule(rule);
      }
    }
  }
}

final class _SavedBeyond implements StoryDraftSaved {
  const _SavedBeyond(this._dialogues, this._records);

  final StorySavedDialogues _dialogues;
  final StorySavedRecords _records;

  @override
  Object? read(StoryDraftKind<Object> kind, String id) =>
      kind == StoryDraftKind.dialogue
      ? _dialogues.read(kind, id)
      : _records.read(kind, id);
}
