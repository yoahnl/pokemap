import 'dart:math';

// -----------------------------------------------------------------------------
// Dialogue Studio — modèle d’édition structuré (vérité UX, pas le Yarn brut).
// -----------------------------------------------------------------------------
//
// Rôle produit:
// - Le créateur raisonne en blocs (réplique, choix, saut, fin…), pas en syntaxe.
// - Le fichier `.yarn` reste un format de persistance / échange, produit par le
//   codec [dialogue_yarn_codec.dart], pas tapé comme source unique dans l’UI.
//
// Identifiants stables:
// - Chaque nœud Yarn devient un [DialogueEditorNode] avec un `id` unique.
// - Chaque bloc visuel est un [DialogueEditorStep] avec son propre `id` pour la
//   sélection inspecteur / mutations sans réindex fragile.
// -----------------------------------------------------------------------------

/// Génère un identifiant unique simple (pas de dépendance `uuid` ajoutée au package).
String newDialogueEditorId() {
  return 'de_${DateTime.now().microsecondsSinceEpoch}_'
      '${Random().nextInt(1 << 30)}';
}

/// Builds a stable public outcome id from a readable author label.
///
/// `completed` is reserved by the Scene runtime for the no-outcome fallback,
/// so the generated id always skips it even when no dialogue outcome currently
/// uses that value.
String availableDialogueOutcomeId(
  String label,
  Iterable<String> usedIds,
) {
  var base = label.toLowerCase();
  const replacements = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'œ': 'oe',
  };
  for (final replacement in replacements.entries) {
    base = base.replaceAll(replacement.key, replacement.value);
  }
  base = base
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty) base = 'outcome';

  final unavailableIds = <String>{
    'completed',
    for (final id in usedIds) id.trim(),
  };
  if (!unavailableIds.contains(base)) return base;
  var suffix = 2;
  while (unavailableIds.contains('${base}_$suffix')) {
    suffix += 1;
  }
  return '${base}_$suffix';
}

/// Document édité dans Dialogue Studio : liste ordonnée de nœuds (= blocs `title:` Yarn).
class DialogueSourcePreservation {
  const DialogueSourcePreservation({
    required this.originalText,
    required this.canonicalAtParse,
    required this.hasNonCanonicalFormatting,
  });

  /// Exact bytes decoded as text when the document was loaded.
  ///
  /// The codec may return this value while the semantic document is unchanged.
  /// This protects comments, blank lines and whitespace that do not have a
  /// dedicated no-code representation yet.
  final String originalText;
  final String canonicalAtParse;
  final bool hasNonCanonicalFormatting;
}

/// Header Yarn other than `title`.
///
/// Keeping the ordered name/value pairs is the minimum contract required to
/// prevent Selbrume `tags:` and third-party extensions from disappearing when
/// a document is edited and canonically emitted.
class DialogueEditorNodeHeader {
  const DialogueEditorNodeHeader({required this.name, required this.value});

  final String name;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is DialogueEditorNodeHeader &&
      other.name == name &&
      other.value == value;

  @override
  int get hashCode => Object.hash(name, value);
}

class DialogueEditorDocumentOutcome {
  const DialogueEditorDocumentOutcome({
    required this.id,
    required this.label,
    required this.nodeId,
    required this.branchId,
  });

  final String id;
  final String label;
  final String nodeId;
  final String branchId;
}

class DialogueEditorDocument {
  const DialogueEditorDocument({
    required this.nodes,
    this.entryNodeId,
    this.sourcePreservation,
  });

  final List<DialogueEditorNode> nodes;

  /// Stable editor id of the node used to start the conversation.
  ///
  /// Legacy in-memory documents can omit it and still use the first node. The
  /// codec always makes it explicit, and persists the choice by emitting the
  /// entry node first because the simplified Yarn wire has no separate entry
  /// header.
  final String? entryNodeId;

  final DialogueSourcePreservation? sourcePreservation;

  String? get effectiveEntryNodeId =>
      entryNodeId ?? (nodes.isEmpty ? null : nodes.first.id);

  DialogueEditorDocument copyWith({
    List<DialogueEditorNode>? nodes,
    String? entryNodeId,
    DialogueSourcePreservation? sourcePreservation,
  }) {
    return DialogueEditorDocument(
      nodes: nodes ?? this.nodes,
      entryNodeId: entryNodeId ?? this.entryNodeId,
      sourcePreservation: sourcePreservation ?? this.sourcePreservation,
    );
  }

  /// Titres Yarn de tous les nœuds (utile pour validation des sauts).
  Set<String> nodeTitles() =>
      nodes.map((n) => n.title.trim()).where((t) => t.isNotEmpty).toSet();

  DialogueEditorNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Extracts the public outcomes actually emitted by structured Yarn choices.
  ///
  /// The manifest remains the stable public registry; this projection lets the
  /// editor compare the validated document with that registry before saving or
  /// changing Scene ports.
  List<DialogueEditorDocumentOutcome> documentOutcomes() {
    final outcomes = <DialogueEditorDocumentOutcome>[];
    void walk(String nodeId, List<DialogueEditorStep> steps) {
      for (final step in steps) {
        if (step is! DeChoiceStep) continue;
        for (final branch in step.branches) {
          final outcomeId = branch.outcomeId?.trim() ?? '';
          if (outcomeId.isNotEmpty) {
            outcomes.add(
              DialogueEditorDocumentOutcome(
                id: outcomeId,
                label: branch.label.trim(),
                nodeId: nodeId,
                branchId: branch.id,
              ),
            );
          }
          walk(nodeId, branch.steps);
        }
      }
    }

    for (final node in nodes) {
      walk(node.id, node.steps);
    }
    return List<DialogueEditorDocumentOutcome>.unmodifiable(outcomes);
  }

  /// Adds a new valid Yarn node without mutating the current document.
  DialogueEditorDocument createNode({
    required String title,
    int? index,
  }) {
    final normalizedTitle = _availableDialogueNodeTitle(title, nodes);
    final node = DialogueEditorNode(
      id: newDialogueEditorId(),
      title: normalizedTitle,
      steps: <DialogueEditorStep>[],
    );
    final next = nodes.map(_cloneDialogueNode).toList();
    final insertAt = index == null ? next.length : index.clamp(0, next.length);
    next.insert(insertAt, node);
    final nextEntry = effectiveEntryNodeId ?? node.id;
    return _normalizeDialogueEntryMarkers(
      DialogueEditorDocument(
        nodes: next,
        entryNodeId: nextEntry,
        sourcePreservation: sourcePreservation,
      ),
    );
  }

  /// Deletes a node and promotes the first remaining node when it was entry.
  DialogueEditorDocument deleteNode(String nodeId) {
    if (nodeById(nodeId) == null) {
      throw ArgumentError.value(nodeId, 'nodeId', 'Unknown dialogue node.');
    }
    final next = nodes
        .where((node) => node.id != nodeId)
        .map(_cloneDialogueNode)
        .toList();
    final previousEntry = effectiveEntryNodeId;
    final nextEntry = previousEntry == nodeId
        ? (next.isEmpty ? null : next.first.id)
        : previousEntry;
    return _normalizeDialogueEntryMarkers(
      DialogueEditorDocument(
        nodes: next,
        entryNodeId: nextEntry,
        sourcePreservation: sourcePreservation,
      ),
    );
  }

  /// Renames a node and every structured jump that targets its old title.
  DialogueEditorDocument renameNode(String nodeId, String title) {
    final target = nodeById(nodeId);
    if (target == null) {
      throw ArgumentError.value(nodeId, 'nodeId', 'Unknown dialogue node.');
    }
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title must not be empty.');
    }
    if (nodes.any(
      (node) => node.id != nodeId && node.title.trim() == normalized,
    )) {
      throw ArgumentError.value(title, 'title', 'Title must be unique.');
    }
    final previousTitle = target.title.trim();
    final next = nodes.map(_cloneDialogueNode).toList();
    for (final node in next) {
      if (node.id == nodeId) node.title = normalized;
      _rewriteDialogueJumps(node.steps, previousTitle, normalized);
    }
    return DialogueEditorDocument(
      nodes: next,
      entryNodeId: effectiveEntryNodeId,
      sourcePreservation: sourcePreservation,
    );
  }

  /// Duplicates one node with fresh editor ids and a collision-free title.
  DialogueEditorDocument duplicateNode(String nodeId) {
    final sourceIndex = nodes.indexWhere((node) => node.id == nodeId);
    if (sourceIndex < 0) {
      throw ArgumentError.value(nodeId, 'nodeId', 'Unknown dialogue node.');
    }
    final source = nodes[sourceIndex];
    final duplicateTitle = _availableDialogueNodeTitle(source.title, nodes);
    final duplicate = _cloneDialogueNode(source, freshIds: true)
      ..title = duplicateTitle;
    _rewriteDialogueJumps(
      duplicate.steps,
      source.title.trim(),
      duplicateTitle,
    );
    final next = nodes.map(_cloneDialogueNode).toList()
      ..insert(sourceIndex + 1, duplicate);
    return DialogueEditorDocument(
      nodes: next,
      entryNodeId: effectiveEntryNodeId,
      sourcePreservation: sourcePreservation,
    );
  }

  DialogueEditorDocument moveNode(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= nodes.length) {
      throw RangeError.index(fromIndex, nodes, 'fromIndex');
    }
    if (toIndex < 0 || toIndex >= nodes.length) {
      throw RangeError.index(toIndex, nodes, 'toIndex');
    }
    final next = nodes.map(_cloneDialogueNode).toList();
    final moved = next.removeAt(fromIndex);
    next.insert(toIndex, moved);
    return DialogueEditorDocument(
      nodes: next,
      entryNodeId: effectiveEntryNodeId,
      sourcePreservation: sourcePreservation,
    );
  }

  /// Selects the entry while preserving the author's visual node order.
  ///
  /// Persistence belongs to `ProjectDialogueEntry.defaultStartNode`; the Yarn
  /// body itself therefore does not need to be reordered for this metadata.
  DialogueEditorDocument selectEntryNode(String nodeId) {
    final sourceIndex = nodes.indexWhere((node) => node.id == nodeId);
    if (sourceIndex < 0) {
      throw ArgumentError.value(nodeId, 'nodeId', 'Unknown dialogue node.');
    }
    final next = nodes.map(_cloneDialogueNode).toList();
    return _normalizeDialogueEntryMarkers(
      DialogueEditorDocument(
        nodes: next,
        entryNodeId: nodeId,
        sourcePreservation: sourcePreservation,
      ),
    );
  }
}

/// Un nœud Yarn (`title: …` … `===`).
class DialogueEditorNode {
  DialogueEditorNode({
    required this.id,
    required this.title,
    required this.steps,
    this.headers = const <DialogueEditorNodeHeader>[],
  });

  /// Identifiant éditeur (pas le titre Yarn).
  final String id;

  /// Titre du nœud côté Yarn (doit rester unique dans le fichier pour les sauts).
  String title;

  /// Séquence verticale principale du nœud (hors branches indentées des choix).
  List<DialogueEditorStep> steps;

  /// Ordered Yarn headers other than `title`.
  List<DialogueEditorNodeHeader> headers;

  DialogueEditorNode copyWith({
    String? id,
    String? title,
    List<DialogueEditorStep>? steps,
    List<DialogueEditorNodeHeader>? headers,
  }) {
    return DialogueEditorNode(
      id: id ?? this.id,
      title: title ?? this.title,
      steps: steps ?? List<DialogueEditorStep>.from(this.steps),
      headers: headers ?? List<DialogueEditorNodeHeader>.from(this.headers),
    );
  }
}

String _availableDialogueNodeTitle(
  String requested,
  Iterable<DialogueEditorNode> nodes,
) {
  final base = requested.trim().isEmpty ? 'Nouveau noeud' : requested.trim();
  final used = nodes.map((node) => node.title.trim()).toSet();
  if (!used.contains(base)) return base;
  var suffix = 2;
  while (used.contains('$base $suffix')) {
    suffix += 1;
  }
  return '$base $suffix';
}

DialogueEditorDocument _normalizeDialogueEntryMarkers(
  DialogueEditorDocument document,
) {
  final entryId = document.effectiveEntryNodeId;
  final next = document.nodes.map(_cloneDialogueNode).toList();
  for (final node in next) {
    node.steps.removeWhere((step) => step is DeStartStep);
    if (node.id == entryId) {
      node.steps.insert(0, DeStartStep(id: newDialogueEditorId()));
    }
  }
  return DialogueEditorDocument(
    nodes: next,
    entryNodeId: entryId,
    sourcePreservation: document.sourcePreservation,
  );
}

DialogueEditorNode _cloneDialogueNode(
  DialogueEditorNode node, {
  bool freshIds = false,
}) {
  return DialogueEditorNode(
    id: freshIds ? newDialogueEditorId() : node.id,
    title: node.title,
    headers: List<DialogueEditorNodeHeader>.from(node.headers),
    steps: node.steps
        .map((step) => _cloneDialogueStep(step, freshIds: freshIds))
        .toList(),
  );
}

DialogueEditorStep _cloneDialogueStep(
  DialogueEditorStep step, {
  required bool freshIds,
}) {
  String nextId(String current) => freshIds ? newDialogueEditorId() : current;
  return switch (step) {
    DeStartStep(:final id) => DeStartStep(id: nextId(id)),
    DeLineStep(:final id, :final speaker, :final body) => DeLineStep(
        id: nextId(id),
        speaker: speaker,
        body: body,
      ),
    DeNarrationStep(:final id, :final text) =>
      DeNarrationStep(id: nextId(id), text: text),
    DeChoiceStep(:final id, :final branches) => DeChoiceStep(
        id: nextId(id),
        branches: branches
            .map(
              (branch) => DeChoiceBranch(
                id: nextId(branch.id),
                label: branch.label,
                outcomeId: branch.outcomeId,
                steps: branch.steps
                    .map(
                      (inner) => _cloneDialogueStep(inner, freshIds: freshIds),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    DeJumpStep(:final id, :final targetTitle) =>
      DeJumpStep(id: nextId(id), targetTitle: targetTitle),
    DeConditionStep(:final id, :final raw) =>
      DeConditionStep(id: nextId(id), raw: raw),
    DeCommandStep(:final id, :final raw) =>
      DeCommandStep(id: nextId(id), raw: raw),
    DeEndStep(:final id) => DeEndStep(id: nextId(id)),
  };
}

void _rewriteDialogueJumps(
  List<DialogueEditorStep> steps,
  String previousTitle,
  String nextTitle,
) {
  for (final step in steps) {
    switch (step) {
      case DeJumpStep(:final targetTitle):
        if (targetTitle.trim() == previousTitle) {
          step.targetTitle = nextTitle;
        }
      case DeChoiceStep(:final branches):
        for (final branch in branches) {
          _rewriteDialogueJumps(branch.steps, previousTitle, nextTitle);
        }
      default:
        break;
    }
  }
}

/// Bloc unique dans le canvas (réplique, choix, etc.).
sealed class DialogueEditorStep {
  String get id;
}

/// Marqueur visuel « début de conversation » (le premier nœud Yarn).
///
/// N’est pas émis dans le fichier : il sert uniquement au layout créateur.
class DeStartStep implements DialogueEditorStep {
  DeStartStep({required this.id});

  @override
  final String id;
}

/// Réplique parlée (`speaker: texte` ou ligne libre).
class DeLineStep implements DialogueEditorStep {
  DeLineStep({
    required this.id,
    this.speaker,
    required this.body,
  });

  @override
  final String id;

  /// Interlocuteur affiché (optionnel si la ligne est sans préfixe `:`).
  String? speaker;

  /// Texte sans le préfixe locuteur.
  String body;
}

/// Narration / didascalie : sérialisée comme `(texte)` pour rester une seule ligne Yarn.
class DeNarrationStep implements DialogueEditorStep {
  DeNarrationStep({required this.id, required this.text});

  @override
  final String id;
  String text;
}

/// Bloc choix joueur : branches horizontales / indentées côté Yarn (`->`).
class DeChoiceStep implements DialogueEditorStep {
  DeChoiceStep({required this.id, required this.branches});

  @override
  final String id;
  List<DeChoiceBranch> branches;
}

/// Une option de choix et sa mini-séquence (lignes indentées sous `->`).
class DeChoiceBranch {
  DeChoiceBranch({
    required this.id,
    required this.label,
    this.outcomeId,
    required this.steps,
  });

  final String id;
  String label;

  /// Stable public result returned by this branch to its owning Scene.
  ///
  /// This identity is intentionally independent from [label], which remains
  /// editable and localizable. Legacy choices can keep it `null`.
  String? outcomeId;

  /// Étapes exécutées si l’option est choisie (souvent un `<<jump …>>`).
  List<DialogueEditorStep> steps;
}

/// Saut explicite vers un autre nœud (`<<jump NodeTitle>>`).
class DeJumpStep implements DialogueEditorStep {
  DeJumpStep({required this.id, required this.targetTitle});

  @override
  final String id;
  String targetTitle;
}

/// Condition Yarn (`<<if …>>`) — préservée telle quelle pour ne pas perdre la donnée
/// (le runtime actuel ignore ces lignes, mais l’éditeur ne doit pas les effacer).
class DeConditionStep implements DialogueEditorStep {
  DeConditionStep({required this.id, required this.raw});

  @override
  final String id;
  String raw;
}

/// Autre commande `<<…>>` (hors `jump` / `if` détecté).
class DeCommandStep implements DialogueEditorStep {
  DeCommandStep({required this.id, required this.raw});

  @override
  final String id;
  String raw;
}

/// Fin de conversation (marqueur créateur ; rien n’est obligatoire côté Yarn).
class DeEndStep implements DialogueEditorStep {
  DeEndStep({required this.id});

  @override
  final String id;
}
