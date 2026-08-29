import 'package:meta/meta.dart' show immutable;

enum NarrativeCommandBackend {
  sceneConsequence,
  interactiveRuntimeCommand,
  dedicatedSceneNode,
}

enum NarrativeCommandCapabilityStatus { supported, unsupported }

enum NarrativeCommandParameterKind {
  text,
  integer,
  boolean,
  fact,
  event,
  storyStep,
  item,
  species,
  speciesForm,
  starter,
  map,
  npc,
  warp,
  shop,
  badge,
  fieldAbility,
  completionOutcome,
  postGamePolicy,
  trainer,
  staticEncounter,
  dialogue,
  cinematic,
  actor,
  customAnimationDefinition,
  characterDirection,
  customAnimationPlayback,
  pauseMenuAction,
  railJourney,
  railJourneyOperation,
  railJourneyDirection,
  railJourneyAdvanceEvent,
  railJourneyDoorSide,
}

@immutable
final class NarrativeCommandParameterDescriptor {
  const NarrativeCommandParameterDescriptor({
    required this.id,
    required this.label,
    required this.kind,
    this.required = true,
  });

  final String id;
  final String label;
  final NarrativeCommandParameterKind kind;
  final bool required;
}

@immutable
final class NarrativeCommandCapabilities {
  const NarrativeCommandCapabilities({
    required this.model,
    required this.editor,
    required this.runtime,
    this.reason,
  });

  const NarrativeCommandCapabilities.supported()
      : model = NarrativeCommandCapabilityStatus.supported,
        editor = NarrativeCommandCapabilityStatus.supported,
        runtime = NarrativeCommandCapabilityStatus.supported,
        reason = null;

  final NarrativeCommandCapabilityStatus model;
  final NarrativeCommandCapabilityStatus editor;
  final NarrativeCommandCapabilityStatus runtime;
  final String? reason;

  bool get isPublishable =>
      model == NarrativeCommandCapabilityStatus.supported &&
      editor == NarrativeCommandCapabilityStatus.supported &&
      runtime == NarrativeCommandCapabilityStatus.supported;
}

@immutable
final class NarrativeCommandDescriptor {
  NarrativeCommandDescriptor({
    required String id,
    required String label,
    required String description,
    required this.backend,
    required this.capabilities,
    required String fgLotId,
    required String wireId,
    List<NarrativeCommandParameterDescriptor> parameters = const [],
    this.isPersistent = false,
    this.isAwaitable = false,
  })  : id = _required(id, 'id'),
        label = _required(label, 'label'),
        description = _required(description, 'description'),
        fgLotId = _required(fgLotId, 'fgLotId'),
        wireId = _required(wireId, 'wireId'),
        parameters = List<NarrativeCommandParameterDescriptor>.unmodifiable(
          parameters,
        );

  final String id;
  final String label;
  final String description;
  final NarrativeCommandBackend backend;
  final NarrativeCommandCapabilities capabilities;
  final String fgLotId;

  /// Unique canonical persisted/executable representation for this effect.
  final String wireId;
  final List<NarrativeCommandParameterDescriptor> parameters;
  final bool isPersistent;
  final bool isAwaitable;

  bool get isPublishable => capabilities.isPublishable;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
