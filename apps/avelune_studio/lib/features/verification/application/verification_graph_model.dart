part of 'verification_workspace_controller.dart';

enum VerificationEdgeSense { reference, condition, progression, location }

enum VerificationNodeRole { focus, owner, target, context }

class VerificationGraphNode {
  const VerificationGraphNode({
    required this.id,
    required this.label,
    required this.kind,
    required this.role,
    this.missing = false,
  });

  final String id;
  final String label;
  final NarrativeDependencyTargetKind kind;
  final VerificationNodeRole role;
  final bool missing;
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
