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
class DialogueEditorDocument {
  const DialogueEditorDocument({required this.nodes});

  final List<DialogueEditorNode> nodes;

  DialogueEditorDocument copyWith({List<DialogueEditorNode>? nodes}) {
    return DialogueEditorDocument(nodes: nodes ?? this.nodes);
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
}

/// Un nœud Yarn (`title: …` … `===`).
class DialogueEditorNode {
  DialogueEditorNode({
    required this.id,
    required this.title,
    required this.steps,
  });

  /// Identifiant éditeur (pas le titre Yarn).
  final String id;

  /// Titre du nœud côté Yarn (doit rester unique dans le fichier pour les sauts).
  String title;

  /// Séquence verticale principale du nœud (hors branches indentées des choix).
  List<DialogueEditorStep> steps;

  DialogueEditorNode copyWith({
    String? id,
    String? title,
    List<DialogueEditorStep>? steps,
  }) {
    return DialogueEditorNode(
      id: id ?? this.id,
      title: title ?? this.title,
      steps: steps ?? List<DialogueEditorStep>.from(this.steps),
    );
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
