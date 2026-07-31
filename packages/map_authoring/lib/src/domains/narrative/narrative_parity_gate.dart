import 'package:map_core/map_core.dart';

enum NarrativeParityStatus { supported, partial, unsupported }

final class NarrativeParityEntry {
  const NarrativeParityEntry({
    required this.domain,
    required this.featureId,
    required this.editorSurface,
    required this.apiActionOrRead,
    required this.runtimeAuthority,
    required this.status,
    this.limitations = const [],
  });

  final String domain;
  final String featureId;
  final String editorSurface;
  final String apiActionOrRead;
  final String runtimeAuthority;
  final NarrativeParityStatus status;
  final List<String> limitations;

  Map<String, Object?> toJson() => {
        'domain': domain,
        'featureId': featureId,
        'editorSurface': editorSurface,
        'apiActionOrRead': apiActionOrRead,
        'runtimeAuthority': runtimeAuthority,
        'status': status.name,
        'limitations': limitations,
      };
}

final class NarrativeParityReport {
  NarrativeParityReport({
    required Iterable<NarrativeParityEntry> entries,
    required this.projectCinematicCount,
  }) : entries = List.unmodifiable(entries);

  final List<NarrativeParityEntry> entries;
  final int projectCinematicCount;

  bool get hasUnsupportedFeatures =>
      entries.any((entry) => entry.status == NarrativeParityStatus.unsupported);

  Map<String, Object?> toJson() => {
        'projectCinematicCount': projectCinematicCount,
        'hasUnsupportedFeatures': hasUnsupportedFeatures,
        'entries': [for (final entry in entries) entry.toJson()],
      };
}

/// Explicit editor/API/runtime truth table. Entries marked partial expose their
/// limits instead of treating authorability as proof of runtime support.
final class NarrativeParityGate {
  const NarrativeParityGate();

  NarrativeParityReport inspect(ProjectManifest project) {
    final entries = <NarrativeParityEntry>[
      const NarrativeParityEntry(
        domain: 'dialogue',
        featureId: 'yarn_subset',
        editorSurface: 'Dialogue authoring',
        apiActionOrRead: 'dialogue.* / dialogue',
        runtimeAuthority: 'RuntimeDialogueDocument + YarnDialogueCompiler',
        status: NarrativeParityStatus.partial,
        limitations: ['Only the documented deterministic Yarn subset runs.'],
      ),
      const NarrativeParityEntry(
        domain: 'script',
        featureId: 'deterministic_commands',
        editorSurface: 'Script authoring and simulation',
        apiActionOrRead: 'script.* / script',
        runtimeAuthority: 'NarrativeCommandRuntimeExecutor',
        status: NarrativeParityStatus.partial,
        limitations: [
          'Simulation is side-effect free and host ports stay runtime-owned.'
        ],
      ),
      const NarrativeParityEntry(
        domain: 'scene',
        featureId: 'graph_execution',
        editorSurface: 'Scene graph authoring',
        apiActionOrRead: 'scene.* / scene',
        runtimeAuthority: 'buildSceneRuntimePlan',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'event_v2',
        featureId: 'dispatch',
        editorSurface: 'Event V2 lifecycle',
        apiActionOrRead: 'event_v2.* / eventV2',
        runtimeAuthority: 'NarrativeEventDispatchAuthority',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'fact',
        featureId: 'typed_resolution',
        editorSurface: 'Fact authoring',
        apiActionOrRead: 'fact.* / fact',
        runtimeAuthority: 'NarrativeFactRuntimeResolver',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'world_rule',
        featureId: 'effect_projection',
        editorSurface: 'World Rule authoring',
        apiActionOrRead: 'world_rule.* / worldRule',
        runtimeAuthority: 'projectWorldRuleEffects',
        status: NarrativeParityStatus.supported,
      ),
      const NarrativeParityEntry(
        domain: 'storyline',
        featureId: 'progression_projection',
        editorSurface: 'Storyline graph authoring',
        apiActionOrRead: 'storyline.* / storyline',
        runtimeAuthority: 'StorylineRuntimeProjection',
        status: NarrativeParityStatus.partial,
        limitations: [
          'The projection is canonical; orchestration remains host-owned.'
        ],
      ),
      const NarrativeParityEntry(
        domain: 'scenario',
        featureId: 'legacy_execution',
        editorSurface: 'Scenario compatibility authoring',
        apiActionOrRead: 'scenario.* / scenario',
        runtimeAuthority: 'ScenarioRuntimeExecutor',
        status: NarrativeParityStatus.supported,
      ),
      for (final kind in CinematicTimelineStepKind.values)
        NarrativeParityEntry(
          domain: 'cinematic.timeline',
          featureId: kind.name,
          editorSurface: 'Cinematic timeline',
          apiActionOrRead: 'cinematic.* / cinematic',
          runtimeAuthority:
              'CinematicRuntimePlaybackController + FlameCinematicRuntimePlaybackSink',
          status: NarrativeParityStatus.supported,
          limitations: const [
            'Concrete actor, active-map, and media availability is checked by runtime preflight.',
          ],
        ),
    ];
    return NarrativeParityReport(
      entries: entries,
      projectCinematicCount: project.cinematics.length,
    );
  }
}
