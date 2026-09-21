part of 'verification_workspace_controller.dart';

enum VerificationEdgeSense { reference, condition, progression, location }

enum VerificationNodeRole { focus, owner, target, context }

/// The full canonical identity, not the bare text identifier: two steps named
/// `s1` in two stories, or a scene and a dialogue sharing an id, stay distinct
/// everywhere — lookups, labels, nodes, edges and selection.
String verificationKeyId(NarrativeDependencyKey key) => [
  key.kind.name,
  key.id,
  key.scope ?? '',
  key.parentId ?? '',
  key.sourceKind ?? '',
].join('');

/// What a diagnostic can point at, most precise identity first.
List<(NarrativeDependencyTargetKind, String)> verificationCandidates(
  NarrativeProjectDiagnostic diagnostic,
) => [
  for (final candidate in <(NarrativeDependencyTargetKind, String?)>[
    (NarrativeDependencyTargetKind.worldRule, diagnostic.worldRuleId),
    (NarrativeDependencyTargetKind.fact, diagnostic.factId),
    (NarrativeDependencyTargetKind.dialogue, diagnostic.dialogueId),
    (NarrativeDependencyTargetKind.cinematic, diagnostic.cinematicId),
    (NarrativeDependencyTargetKind.step, diagnostic.stepId),
    (NarrativeDependencyTargetKind.chapter, diagnostic.chapterId),
    (NarrativeDependencyTargetKind.storyline, diagnostic.storylineId),
    (NarrativeDependencyTargetKind.scene, diagnostic.sceneId),
    (NarrativeDependencyTargetKind.eventV2, diagnostic.eventId),
    (NarrativeDependencyTargetKind.sourceMap, diagnostic.mapId),
  ])
    if (candidate.$2 case final id? when id.isNotEmpty) (candidate.$1, id),
];

/// The identity a diagnostic designates, or nothing when several documents
/// answer to it. An ambiguous target is never replaced by the first match.
({NarrativeDependencyKey? key, bool ambiguous}) verificationResolve(
  NarrativeDependencyIndex index,
  NarrativeProjectDiagnostic diagnostic,
) {
  final parents = <String>{
    for (final id in [
      diagnostic.chapterId,
      diagnostic.storylineId,
      diagnostic.sceneId,
      diagnostic.mapId,
    ])
      if (id != null && id.isNotEmpty) id,
  };
  for (final candidate in verificationCandidates(diagnostic)) {
    final matches = [
      for (final definition in index.definitions)
        if (definition.key.kind == candidate.$1 &&
            definition.key.id == candidate.$2)
          definition.key,
    ];
    if (matches.isEmpty) continue;
    if (matches.length == 1) return (key: matches.single, ambiguous: false);
    final narrowed = [
      for (final key in matches)
        if (key.parentId != null && parents.contains(key.parentId)) key,
    ];
    if (narrowed.length == 1) return (key: narrowed.single, ambiguous: false);
    return (key: null, ambiguous: true);
  }
  return (key: null, ambiguous: false);
}

class VerificationGraphNode {
  const VerificationGraphNode({
    required this.key,
    required this.label,
    required this.role,
    this.missing = false,
  });

  final NarrativeDependencyKey key;
  final String label;
  final VerificationNodeRole role;
  final bool missing;

  String get id => verificationKeyId(key);
  NarrativeDependencyTargetKind get kind => key.kind;
}

class VerificationGraphEdge {
  const VerificationGraphEdge({
    required this.from,
    required this.to,
    required this.sense,
    this.unresolved = false,
  });

  final String from;
  final String to;
  final VerificationEdgeSense sense;
  final bool unresolved;
}

/// A read-only projection of the canonical dependencies. It never creates a
/// scene, a link or a consequence, and never writes to the project.
class VerificationGraph {
  const VerificationGraph({
    required this.nodes,
    required this.edges,
    required this.title,
    this.focusId,
    this.hiddenCount = 0,
  });

  final List<VerificationGraphNode> nodes;
  final List<VerificationGraphEdge> edges;
  final String title;
  final String? focusId;
  final int hiddenCount;

  bool get isEmpty => nodes.isEmpty;
}

String verificationEdgeLabel(VerificationEdgeSense sense) => switch (sense) {
  VerificationEdgeSense.reference => 'référence',
  VerificationEdgeSense.condition => 'condition',
  VerificationEdgeSense.progression => 'progression',
  VerificationEdgeSense.location => 'localisation',
};

String verificationKindLabel(NarrativeDependencyTargetKind kind) =>
    switch (kind) {
      NarrativeDependencyTargetKind.fact => 'État',
      NarrativeDependencyTargetKind.badge => 'Badge',
      NarrativeDependencyTargetKind.item => 'Objet',
      NarrativeDependencyTargetKind.eventV2 => 'Événement',
      NarrativeDependencyTargetKind.scene => 'Scène',
      NarrativeDependencyTargetKind.dialogue => 'Dialogue',
      NarrativeDependencyTargetKind.cinematic => 'Cinématique',
      NarrativeDependencyTargetKind.media => 'Média',
      NarrativeDependencyTargetKind.storyline => 'Histoire',
      NarrativeDependencyTargetKind.chapter => 'Chapitre',
      NarrativeDependencyTargetKind.step => 'Étape',
      NarrativeDependencyTargetKind.worldRule => 'Règle',
      NarrativeDependencyTargetKind.railJourney => 'Trajet',
      NarrativeDependencyTargetKind.sourceMap => 'Carte',
    };
