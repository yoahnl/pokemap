import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';
import '../../map_workspace/application/map_story_elements.dart';
import '../domain/verification_port.dart';

enum VerificationProblemSeverity { error, warning, info }

enum VerificationObjectState { draft, disabled }

final class VerificationProblem {
  const VerificationProblem({
    required this.code,
    required this.severity,
    required this.message,
    required this.destination,
    this.mapId,
    this.eventId,
    this.sceneId,
    this.sceneNodeId,
    this.dialogueId,
    this.storylineId,
    this.chapterId,
    this.stepId,
    this.factId,
    this.worldRuleId,
    this.objectName,
    this.location,
    this.objectState,
  });

  final String code;
  final VerificationProblemSeverity severity;
  final String message;
  final NarrativeProjectDiagnosticDestination destination;
  final String? mapId;
  final String? eventId;
  final String? sceneId;
  final String? sceneNodeId;
  final String? dialogueId;
  final String? storylineId;
  final String? chapterId;
  final String? stepId;
  final String? factId;
  final String? worldRuleId;
  final String? objectName;
  final String? location;
  final VerificationObjectState? objectState;
}

List<VerificationProblem> verificationProblems(
  NarrativeProjectValidationReport report,
  NarrativeValidationDimensionResult? physical,
  ProjectManifest project,
) {
  final context = _VerificationLabels(project);
  final unreadableMaps = {
    for (final item in report.diagnostics)
      if (item.code == verificationUnreadableMap) item.mapId,
  };
  final problems = <VerificationProblem>[
    for (final item in report.diagnostics)
      if (item.code != verificationRuntimeMissingMap ||
          !unreadableMaps.contains(item.mapId))
        context.narrative(item),
    for (final item in physical?.diagnostics ?? const [])
      VerificationProblem(
        code: item.code,
        severity: switch (item.severity) {
          'error' => VerificationProblemSeverity.error,
          'info' => VerificationProblemSeverity.info,
          _ => VerificationProblemSeverity.warning,
        },
        message: item.message,
        destination: item.path.startsWith('maps.')
            ? NarrativeProjectDiagnosticDestination.map
            : NarrativeProjectDiagnosticDestination.overview,
        mapId: item.path.startsWith('maps.') ? item.path.substring(5) : null,
        objectName: item.path.startsWith('maps.')
            ? context.maps[item.path.substring(5)]
            : null,
      ),
  ];
  return [
    for (final severity in VerificationProblemSeverity.values)
      ...problems.where((problem) => problem.severity == severity),
  ];
}

final class _VerificationLabels {
  _VerificationLabels(ProjectManifest project)
    : maps = {for (final map in project.maps) map.id: map.name},
      events = {
        for (final event
            in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
          event.id: event,
      },
      scenes = {for (final scene in project.scenes) scene.id: scene},
      dialogues = {
        for (final dialogue in project.dialogues) dialogue.id: dialogue.name,
      },
      facts = {for (final fact in project.facts) fact.id: fact.label},
      rules = {for (final rule in project.worldRules) rule.id: rule},
      stories = {for (final story in project.storylines) story.id: story.title},
      steps = {
        for (final story in project.storylines)
          for (final chapter in story.chapters)
            for (final step in chapter.steps) (story.id, step.id): step.title,
      };

  final Map<String, String> maps, dialogues, facts, stories;
  final Map<String, NarrativeEventRecord> events;
  final Map<String, SceneAsset> scenes;
  final Map<String, WorldRuleDefinition> rules;
  final Map<(String, String), String> steps;

  VerificationProblem narrative(NarrativeProjectDiagnostic item) {
    final event = events[item.eventId];
    final rule = rules[item.worldRuleId];
    final scene = scenes[item.sceneId];
    final mapId =
        item.mapId ??
        (event == null ? null : mapStoryLocation(event)?.$1) ??
        rule?.target.mapId;
    final destination = item.destination;
    final objectName = switch (destination) {
      NarrativeProjectDiagnosticDestination.map => maps[mapId],
      NarrativeProjectDiagnosticDestination.event => event?.name,
      NarrativeProjectDiagnosticDestination.scene => scene?.name,
      NarrativeProjectDiagnosticDestination.storyline =>
        steps[(item.storylineId ?? '', item.stepId ?? '')] ??
            stories[item.storylineId],
      NarrativeProjectDiagnosticDestination.dialogue =>
        dialogues[item.dialogueId],
      NarrativeProjectDiagnosticDestination.fact => facts[item.factId],
      NarrativeProjectDiagnosticDestination.worldRule => rule?.label,
      _ => null,
    };
    final state = switch ((destination, event, rule)) {
      (NarrativeProjectDiagnosticDestination.event, final event?, _)
          when event.enabledOrNull == null =>
        VerificationObjectState.draft,
      (NarrativeProjectDiagnosticDestination.event, final event?, _)
          when event.enabledOrNull == false =>
        VerificationObjectState.disabled,
      (
        NarrativeProjectDiagnosticDestination.worldRule,
        _,
        WorldRuleDefinition(enabled: false),
      ) =>
        VerificationObjectState.disabled,
      _ => null,
    };
    return VerificationProblem(
      code: item.code,
      severity: switch (item.severity) {
        NarrativeProjectDiagnosticSeverity.error =>
          VerificationProblemSeverity.error,
        NarrativeProjectDiagnosticSeverity.warning =>
          VerificationProblemSeverity.warning,
        NarrativeProjectDiagnosticSeverity.info =>
          VerificationProblemSeverity.info,
      },
      message: item.message,
      destination: destination,
      mapId: mapId,
      eventId: item.eventId,
      sceneId: item.sceneId,
      sceneNodeId: item.sceneNodeId,
      dialogueId: item.dialogueId,
      storylineId: item.storylineId,
      chapterId: item.chapterId,
      stepId: item.stepId,
      factId: item.factId,
      worldRuleId: item.worldRuleId,
      objectName: objectName == null || objectName.trim().isEmpty
          ? null
          : objectName,
      location: destination == NarrativeProjectDiagnosticDestination.map
          ? null
          : maps[mapId],
      objectState: state,
    );
  }
}
