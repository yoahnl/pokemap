import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/application/map_story_behaviours.dart';
import '../../map_workspace/application/map_story_elements.dart';
import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import 'game_behaviour_dependencies.dart';

typedef GameBehaviourEditResult = ({
  bool applied,
  bool recorded,
  String? problem,
  String? deactivated,
});

final class GameBehaviourEditing {
  GameBehaviourEditing({
    required this.project,
    required this.map,
    required this.behaviours,
    this.eventId,
    this.isCurrent,
  });

  final ProjectManifest project;
  final MapData map;
  final MapStoryBehaviours behaviours;
  final String? eventId;
  final bool Function()? isCurrent;
  (int, int, int, GameBehaviourDependencies)? _dependencies;

  StoryDraft get draft => behaviours.draft;

  String? get problem {
    if (isCurrent?.call() == false) {
      return 'Ce contexte a changé. Rouvrez le comportement avant de le modifier.';
    }
    final id = eventId;
    if (id == null) return null;
    final record = behaviours
        .registry(project)
        ?.records
        .where((record) => record.id == id)
        .firstOrNull;
    final at = record == null ? null : mapStoryLocation(record);
    if (at == null || at.$1 != map.id) {
      return 'Ce comportement ne dispose plus de porteur sur cette carte.';
    }
    final elements = MapStoryElements(map, project);
    if (elements.byKey('${at.$2.name}:${at.$3}') == null) {
      return 'Le porteur de ce comportement est absent. Utilisez la réparation dans Carte · Scénario.';
    }
    final events = draft.versionOf(StoryDraftKind.event);
    final scenes = draft.versionOf(StoryDraftKind.scene);
    final facts = draft.versionOf(StoryDraftKind.fact);
    final cached = _dependencies;
    if (cached == null ||
        cached.$1 != events ||
        cached.$2 != scenes ||
        cached.$3 != facts) {
      _dependencies = (
        events,
        scenes,
        facts,
        GameBehaviourDependencies(behaviours.project(project), record!),
      );
    }
    return _dependencies!.$4.problem;
  }

  GameBehaviourEditResult apply({
    List<NarrativeEventRecord> active = const [],
    List<NarrativeEventRecord> expected = const [],
    List<MapStoryBehaviourOperation> operations = const [],
    void Function(StoryDraft draft)? stage,
  }) {
    final invalid = problem ?? _obsolete({...active, ...expected});
    if (invalid != null) {
      return (
        applied: false,
        recorded: false,
        problem: invalid,
        deactivated: null,
      );
    }
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
    final recorded = draft.recorded;
    final shell = draft.eventRegistryShell;
    String? failure;
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
        if (result.problem case final refused?) throw _Refused(refused);
      });
    } on Object catch (error) {
      draft.eventRegistryShell = shell;
      failure = switch (error) {
        _Refused(:final message) => message,
        StateError(:final message) => message,
        _ => '$error',
      };
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
    return (
      applied: failure == null,
      recorded: draft.recorded != recorded,
      problem: failure,
      deactivated: dropped ? notice ?? '' : null,
    );
  }

  String? _obsolete(Iterable<NarrativeEventRecord> expected) {
    if (expected.isEmpty) return null;
    final current = {
      for (final record
          in behaviours.registry(project)?.records ??
              const <NarrativeEventRecord>[])
        record.id: record,
    };
    return expected.any((record) => current[record.id] != record)
        ? 'Ce comportement a changé. Rouvrez sa fiche avant de le modifier.'
        : null;
  }

  NarrativeEventSimulationReport? simulate(
    NarrativeEventSimulationInput input,
  ) => problem == null ? behaviours.simulate(project, map, input) : null;
}

final class _Refused implements Exception {
  const _Refused(this.message);

  final String message;
}
