// -----------------------------------------------------------------------------
// Codec Yarn ↔ [DialogueEditorDocument]
// -----------------------------------------------------------------------------
//
// Base algorithmique : alignée sur `packages/map_runtime/.../parse_yarn_dialogue.dart`
// (structure des choix, indentation, `<<jump …>>`).
//
// Extensions volontaires par rapport au parseur runtime :
// - Les lignes `<<…>>` qui ne sont pas `<<jump …>>` sont **conservées** ([DeCommandStep]
//   ou [DeConditionStep]) au lieu d’être ignorées — nécessaire pour un aller-retour honnête.
// - Les nœuds **sans** lignes de corps sont acceptés (brouillon vide dans l’éditeur).
//
// Limites (documentées aussi dans le rapport) :
// - Pas de support Yarn Spinner « node headers » avancés au-delà de `title:` + `---`.
// - Les tags/metadata hors corps ne sont pas modélisés séparément.
// -----------------------------------------------------------------------------

import 'dialogue_editor_model.dart';

// --- Représentation intermédiaire (parse) -----------------------------------

sealed class _PStep {}

class _PLine extends _PStep {
  _PLine(this.text);
  final String text;
}

class _PJump extends _PStep {
  _PJump(this.target);
  final String target;
}

class _PChoice extends _PStep {
  _PChoice(this.branches);
  final List<_PBranch> branches;
}

class _PBranch {
  _PBranch({required this.label, required this.steps});
  final String label;
  final List<_PStep> steps;
}

class _PRaw extends _PStep {
  _PRaw(this.line);
  final String line;
}

class _ParsedNode {
  _ParsedNode({required this.title, required this.steps});
  final String title;
  final List<_PStep> steps;
}

/// Parse le fichier `.yarn` complet en arbre intermédiaire.
List<_ParsedNode> _parseYarnToParsedNodes(String content) {
  final nodes = <_ParsedNode>[];
  String? currentTitle;
  var inBody = false;
  final rootSteps = <_PStep>[];
  var inChoiceBlock = false;
  final currentChoices = <_PBranch>[];
  String? currentChoiceText;
  final currentChoiceSteps = <_PStep>[];

  void closeChoiceOption() {
    if (currentChoiceText != null) {
      currentChoices.add(
        _PBranch(
          label: currentChoiceText!,
          steps: List<_PStep>.from(currentChoiceSteps),
        ),
      );
      currentChoiceText = null;
      currentChoiceSteps.clear();
    }
  }

  void closeChoiceBlock() {
    closeChoiceOption();
    if (currentChoices.isNotEmpty) {
      rootSteps.add(_PChoice(List<_PBranch>.from(currentChoices)));
      currentChoices.clear();
    }
    inChoiceBlock = false;
  }

  void flushNode() {
    if (currentTitle == null) return;
    // Contrairement au runtime : on accepte les nœuds vides (brouillon).
    nodes.add(
      _ParsedNode(
        title: currentTitle!,
        steps: List<_PStep>.from(rootSteps),
      ),
    );
    currentTitle = null;
    rootSteps.clear();
    inChoiceBlock = false;
    currentChoices.clear();
    currentChoiceText = null;
    currentChoiceSteps.clear();
  }

  for (final raw in content.split('\n')) {
    final line = raw.trimRight();

    if (!inBody) {
      final trimmed = line.trim();
      if (trimmed.startsWith('title:')) {
        currentTitle = trimmed.substring('title:'.length).trim();
      } else if (trimmed == '---') {
        inBody = true;
        rootSteps.clear();
        inChoiceBlock = false;
        currentChoices.clear();
        currentChoiceText = null;
        currentChoiceSteps.clear();
      }
    } else {
      final trimmed = line.trim();
      if (trimmed == '===') {
        if (inChoiceBlock) closeChoiceBlock();
        flushNode();
        inBody = false;
      } else if (trimmed.isEmpty) {
        // Ligne vide ignorée (comme le runtime).
      } else if (line.startsWith(' ') || line.startsWith('\t')) {
        // Branche de choix : lignes indentées.
        if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
          final target =
              trimmed.substring('<<jump '.length, trimmed.length - 2).trim();
          currentChoiceSteps.add(_PJump(target));
        } else if (trimmed.startsWith('<<') && trimmed.endsWith('>>')) {
          // Extension : conserver toute commande (dont `<<if …>>`).
          currentChoiceSteps.add(_PRaw(trimmed));
        } else {
          currentChoiceSteps.add(_PLine(trimmed));
        }
      } else if (trimmed.startsWith('->')) {
        if (!inChoiceBlock) {
          inChoiceBlock = true;
        } else {
          closeChoiceOption();
        }
        currentChoiceText = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
        if (inChoiceBlock) closeChoiceBlock();
        final target =
            trimmed.substring('<<jump '.length, trimmed.length - 2).trim();
        rootSteps.add(_PJump(target));
      } else if (trimmed.startsWith('<<') && trimmed.endsWith('>>')) {
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(_PRaw(trimmed));
      } else {
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(_PLine(trimmed));
      }
    }
  }

  return nodes;
}

bool _isConditionToken(String line) {
  final t = line.trim();
  return t.startsWith('<<if') && t.endsWith('>>');
}

/// Transforme une ligne « dialogue » en [DeLineStep] ou [DeNarrationStep].
DialogueEditorStep _lineStepFromPlainText(String trimmed) {
  // Narration : convention éditeur `(didascalie)` sur une seule ligne.
  final nar = RegExp(r'^\((.*)\)\s*$').firstMatch(trimmed);
  if (nar != null) {
    return DeNarrationStep(
      id: newDialogueEditorId(),
      text: nar.group(1) ?? '',
    );
  }
  final colon = RegExp(r'^([^:]+):\s*(.*)$').firstMatch(trimmed);
  if (colon != null) {
    return DeLineStep(
      id: newDialogueEditorId(),
      speaker: colon.group(1)!.trim(),
      body: colon.group(2)!.trim(),
    );
  }
  return DeLineStep(
    id: newDialogueEditorId(),
    speaker: null,
    body: trimmed,
  );
}

DialogueEditorStep _convertParsedStep(_PStep step) {
  switch (step) {
    case _PLine(:final text):
      return _lineStepFromPlainText(text);
    case _PJump(:final target):
      return DeJumpStep(
        id: newDialogueEditorId(),
        targetTitle: target,
      );
    case _PChoice(:final branches):
      return DeChoiceStep(
        id: newDialogueEditorId(),
        branches: branches
            .map(
              (b) => DeChoiceBranch(
                id: newDialogueEditorId(),
                label: b.label,
                steps: b.steps.map(_convertParsedStep).toList(),
              ),
            )
            .toList(),
      );
    case _PRaw(:final line):
      if (_isConditionToken(line)) {
        return DeConditionStep(id: newDialogueEditorId(), raw: line.trim());
      }
      return DeCommandStep(id: newDialogueEditorId(), raw: line.trim());
  }
}

/// Insertion du bloc « Début » sur le premier nœud pour coller au wireframe produit.
void _ensureStartMarker(DialogueEditorDocument doc) {
  if (doc.nodes.isEmpty) return;
  final first = doc.nodes.first;
  if (first.steps.isEmpty || first.steps.first is! DeStartStep) {
    first.steps.insert(0, DeStartStep(id: newDialogueEditorId()));
  }
}

/// Point d’entrée : chaîne `.yarn` → document éditable.
DialogueEditorDocument parseYarnToDocument(String content) {
  final parsed = _parseYarnToParsedNodes(content);
  final nodes = <DialogueEditorNode>[];
  for (final p in parsed) {
    nodes.add(
      DialogueEditorNode(
        id: newDialogueEditorId(),
        title: p.title,
        steps: p.steps.map(_convertParsedStep).toList(),
      ),
    );
  }
  final doc = DialogueEditorDocument(nodes: nodes);
  _ensureStartMarker(doc);
  return doc;
}

/// Document minimal si le parse n’a rien produit (fichier vide ou invalide).
DialogueEditorDocument emptyDialogueDocument({String startTitle = 'Start'}) {
  final doc = DialogueEditorDocument(
    nodes: [
      DialogueEditorNode(
        id: newDialogueEditorId(),
        title: startTitle,
        steps: [
          DeStartStep(id: newDialogueEditorId()),
          DeLineStep(
            id: newDialogueEditorId(),
            speaker: null,
            body: '',
          ),
        ],
      ),
    ],
  );
  return doc;
}

bool _emitSkip(DialogueEditorStep s) => s is DeStartStep || s is DeEndStep;

void _emitStep(StringBuffer sb, DialogueEditorStep step, String indent) {
  if (_emitSkip(step)) return;
  switch (step) {
    case DeLineStep(:final speaker, :final body):
      final sp = speaker;
      final line = (sp != null && sp.trim().isNotEmpty) ? '${sp.trim()}: $body' : body;
      sb.writeln('$indent$line');
    case DeNarrationStep(:final text):
      sb.writeln('$indent($text)');
    case DeJumpStep(:final targetTitle):
      sb.writeln('$indent<<jump ${targetTitle.trim()}>>');
    case DeConditionStep(:final raw):
    case DeCommandStep(:final raw):
      sb.writeln('$indent$raw');
    case DeChoiceStep(:final branches):
      for (final b in branches) {
        sb.writeln('$indent-> ${b.label}');
        final innerIndent = '$indent  ';
        for (final st in b.steps) {
          _emitStep(sb, st, innerIndent);
        }
      }
    case DeStartStep():
    case DeEndStep():
      break;
  }
}

/// Sérialise le document vers le texte `.yarn` (un bloc `title` / `---` / `===` par nœud).
String emitDocumentToYarn(DialogueEditorDocument doc) {
  final sb = StringBuffer();
  for (final node in doc.nodes) {
    sb.writeln('title: ${node.title.trim()}');
    sb.writeln('---');
    for (final step in node.steps) {
      _emitStep(sb, step, '');
    }
    sb.writeln('===');
  }
  return sb.toString();
}
