// -----------------------------------------------------------------------------
// Prévisualisation « joueur » sans dépendre de `map_runtime`
// -----------------------------------------------------------------------------
// Rejoue une partie du graphe [DialogueEditorDocument] : lignes, choix, sauts.
// - Les [DeCommandStep] / [DeConditionStep] sont ignorés (comme le runtime actuel
//   pour la plupart des `<<>>` hors jump).
// - [DeStartStep] / [DeEndStep] sont ignorés.
// -----------------------------------------------------------------------------

import 'dialogue_editor_model.dart';

sealed class DialoguePreviewEvent {}

class DialoguePreviewLine extends DialoguePreviewEvent {
  DialoguePreviewLine(this.displayText);
  final String displayText;
}

class DialoguePreviewChoicePrompt extends DialoguePreviewEvent {
  DialoguePreviewChoicePrompt(this.options);
  final List<String> options;
}

class DialoguePreviewEnded extends DialoguePreviewEvent {
  DialoguePreviewEnded({this.reason});
  final String? reason;
}

/// État mutable du mode preview (machine simple).
class DialoguePreviewSession {
  DialoguePreviewSession(
    this.document, {
    this.startNodeTitle,
  }) {
    _reset();
  }

  final DialogueEditorDocument document;

  /// Si null : premier nœud du document.
  final String? startNodeTitle;

  final List<DialoguePreviewEvent> transcript = [];

  List<DialogueEditorStep> _activeSteps = [];
  var _index = 0;
  List<DeChoiceBranch>? _pendingChoices;

  DialogueEditorNode? get _startNode {
    if (document.nodes.isEmpty) return null;
    final want = startNodeTitle?.trim();
    if (want != null && want.isNotEmpty) {
      for (final n in document.nodes) {
        if (n.title.trim() == want) return n;
      }
    }
    return document.nodes.first;
  }

  void _reset() {
    transcript.clear();
    _pendingChoices = null;
    final start = _startNode;
    if (start == null) {
      _activeSteps = [];
      _index = 0;
      transcript.add(DialoguePreviewEnded(reason: 'Aucun nœud dans ce dialogue.'));
      return;
    }
    _activeSteps = List<DialogueEditorStep>.from(start.steps);
    _index = 0;
    _drain();
  }

  DialogueEditorNode? _nodeByTitle(String title) {
    final t = title.trim();
    for (final n in document.nodes) {
      if (n.title.trim() == t) return n;
    }
    return null;
  }

  /// Pousse les événements jusqu’au prochain arrêt (choix ou fin).
  void _drain() {
    while (true) {
      if (_pendingChoices != null) {
        return;
      }
      if (_index >= _activeSteps.length) {
        transcript.add(DialoguePreviewEnded(reason: 'Fin du nœud.'));
        return;
      }
      final step = _activeSteps[_index];
      _index++;
      switch (step) {
        case DeStartStep():
        case DeEndStep():
          break;
        case DeLineStep(:final speaker, :final body):
          final sp = speaker;
          final prefix = (sp != null && sp.trim().isNotEmpty) ? '${sp.trim()}: ' : '';
          transcript.add(DialoguePreviewLine('$prefix$body'));
        case DeNarrationStep(:final text):
          transcript.add(DialoguePreviewLine('($text)'));
        case DeJumpStep(:final targetTitle):
          final next = _nodeByTitle(targetTitle);
          if (next == null) {
            transcript.add(DialoguePreviewEnded(
              reason: 'Saut impossible : nœud « $targetTitle » introuvable.',
            ));
            return;
          }
          _activeSteps = List<DialogueEditorStep>.from(next.steps);
          _index = 0;
          break;
        case DeChoiceStep(:final branches):
          if (branches.isEmpty) {
            transcript.add(DialoguePreviewEnded(reason: 'Choix sans option.'));
            return;
          }
          _pendingChoices = branches;
          transcript.add(DialoguePreviewChoicePrompt(
            branches.map((b) => b.label).toList(),
          ));
          return;
        case DeConditionStep():
        case DeCommandStep():
          break;
      }
    }
  }

  /// L’utilisateur a choisi l’index [i] pour le dernier prompt de choix.
  void choose(int i) {
    final pending = _pendingChoices;
    if (pending == null || i < 0 || i >= pending.length) {
      return;
    }
    _pendingChoices = null;
    _activeSteps = List<DialogueEditorStep>.from(pending[i].steps);
    _index = 0;
    _drain();
  }

  void restart() {
    _reset();
  }
}
