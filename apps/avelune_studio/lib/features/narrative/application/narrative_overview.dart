import 'package:map_core/map_core_domain.dart';

import 'interaction_edit_session.dart';
import 'narrative_interaction.dart';

enum NarrativeOverviewReferenceKind {
  step,
  fact,
  dialogue,
  scene,
  event,
  cinematic,
}

class NarrativeOverviewReference {
  const NarrativeOverviewReference(
    this.kind,
    this.id,
    this.label,
    this.missing,
  );
  final NarrativeOverviewReferenceKind kind;
  final String id, label;
  final bool missing;
  String get identity => '${kind.name}:$id';
}

class NarrativeOverviewInteraction {
  const NarrativeOverviewInteraction({
    required this.id,
    required this.name,
    required this.mapId,
    required this.mapLabel,
    required this.sourceLabel,
    required this.whenText,
    required this.dirty,
    required this.advanced,
    required this.conditions,
    required this.consequences,
    required this.references,
    required this.missingReferences,
    this.source,
    this.record,
    this.session,
    this.draft,
  });
  final String id, name, mapLabel, sourceLabel, whenText;
  final String? mapId;
  final bool dirty, advanced;
  final NarrativeEventSourceRef? source;
  final NarrativeEventRecord? record;
  final InteractionEditSession? session;
  final NarrativeInteractionDraft? draft;
  final List<String> conditions, consequences, missingReferences;
  final List<NarrativeOverviewReference> references;
  String get identity => 'interaction:$id';
  bool get canEdit =>
      session?.editable == true ||
      (draft != null && !advanced && missingReferences.isEmpty);
  String get searchText => '$name $mapLabel $sourceLabel'.toLowerCase();
}

class NarrativeOverview {
  NarrativeOverview({
    required this.stories,
    required this.facts,
    required this.interactions,
    required this.stepsById,
    required this.stepLinks,
    required this.factLinks,
    required this.dirtyCount,
    this.stepReferences = const {},
  }) : interactionsById = {for (final item in interactions) item.id: item};
  final List<StorylineAsset> stories;
  final List<NarrativeFactDefinition> facts;
  final List<NarrativeOverviewInteraction> interactions;
  final Map<String, NarrativeOverviewInteraction> interactionsById;
  final Map<String, StorylineStep> stepsById;
  final Map<String, List<NarrativeOverviewInteraction>> stepLinks, factLinks;
  final Map<String, List<NarrativeOverviewReference>> stepReferences;
  final int dirtyCount;
}
