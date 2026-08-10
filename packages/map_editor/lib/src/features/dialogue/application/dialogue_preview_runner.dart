// -----------------------------------------------------------------------------
// Prévisualisation « joueur » sans dépendre de `map_runtime`
// -----------------------------------------------------------------------------
// Rejoue une partie du graphe [DialogueEditorDocument] : lignes, choix, sauts.
// - Les conditions et commandes connues sont exécutées dans un état isolé.
// - Une commande inconnue arrête la simulation au lieu de produire un faux succès.
// - [DeStartStep] / [DeEndStep] sont ignorés.
// -----------------------------------------------------------------------------

import 'dialogue_editor_model.dart';

sealed class DialoguePreviewEvent {
  const DialoguePreviewEvent();
}

class DialoguePreviewLine extends DialoguePreviewEvent {
  DialoguePreviewLine(
    this.displayText, {
    this.characterId,
    this.portraitStateId,
  });
  final String displayText;
  final String? characterId;
  final String? portraitStateId;
}

class DialoguePreviewChoicePrompt extends DialoguePreviewEvent {
  DialoguePreviewChoicePrompt(this.options);
  final List<String> options;
}

class DialoguePreviewEnded extends DialoguePreviewEvent {
  const DialoguePreviewEnded({this.reason, this.outcomeId});
  final String? reason;
  final String? outcomeId;
}

enum DialoguePreviewTraceKind { condition, command, outcome, unsupported }

/// Explication structurée d'une décision ou mutation du dry-run.
class DialoguePreviewTrace extends DialoguePreviewEvent {
  DialoguePreviewTrace({
    required this.kind,
    required this.source,
    required this.message,
    required Map<String, Object?> state,
  }) : state = Map<String, Object?>.unmodifiable(state);

  final DialoguePreviewTraceKind kind;
  final String source;
  final String message;
  final Map<String, Object?> state;
}

/// État mutable du mode preview (machine simple).
class DialoguePreviewSession {
  DialoguePreviewSession(
    this.document, {
    this.startNodeTitle,
    Map<String, Object?> initialState = const {},
  }) : _initialState = Map<String, Object?>.from(initialState) {
    _reset();
  }

  final DialogueEditorDocument document;

  /// Si null : premier nœud du document.
  final String? startNodeTitle;

  final Map<String, Object?> _initialState;
  final Map<String, Object?> _state = {};

  Map<String, Object?> get state => Map<String, Object?>.unmodifiable(_state);

  final List<DialoguePreviewEvent> transcript = [];

  List<DialogueEditorStep> _activeSteps = [];
  var _index = 0;
  List<DeChoiceBranch>? _pendingChoices;
  String? _selectedOutcomeId;
  final List<_DialogueConditionFrame> _conditions = [];

  String? get selectedOutcomeId => _selectedOutcomeId;

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
    _selectedOutcomeId = null;
    _state
      ..clear()
      ..addAll(_initialState);
    _conditions.clear();
    final start = _startNode;
    if (start == null) {
      _activeSteps = [];
      _index = 0;
      transcript.add(
        const DialoguePreviewEnded(reason: 'Aucun nœud dans ce dialogue.'),
      );
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
        transcript.add(
          DialoguePreviewEnded(
            reason: 'Fin du nœud.',
            outcomeId: _selectedOutcomeId,
          ),
        );
        return;
      }
      final step = _activeSteps[_index];
      _index++;
      if (_handleConditionControl(step)) continue;
      if (!_isActive) continue;
      switch (step) {
        case DeStartStep():
        case DeEndStep():
          break;
        case DeLineStep(
          :final speaker,
          :final body,
          :final characterId,
          :final portraitStateId,
        ):
          final sp = speaker;
          final prefix = (sp != null && sp.trim().isNotEmpty)
              ? '${sp.trim()}: '
              : '';
          transcript.add(
            DialoguePreviewLine(
              '$prefix$body',
              characterId: characterId,
              portraitStateId: portraitStateId,
            ),
          );
        case DeNarrationStep(:final text):
          transcript.add(DialoguePreviewLine('($text)'));
        case DeJumpStep(:final targetTitle):
          final next = _nodeByTitle(targetTitle);
          if (next == null) {
            transcript.add(
              DialoguePreviewEnded(
                reason: 'Saut impossible : nœud « $targetTitle » introuvable.',
              ),
            );
            return;
          }
          _activeSteps = List<DialogueEditorStep>.from(next.steps);
          _index = 0;
          break;
        case DeChoiceStep(:final branches):
          if (branches.isEmpty) {
            transcript.add(
              const DialoguePreviewEnded(reason: 'Choix sans option.'),
            );
            return;
          }
          _pendingChoices = branches;
          transcript.add(
            DialoguePreviewChoicePrompt(branches.map((b) => b.label).toList()),
          );
          return;
        case DeConditionStep():
          // Already handled by [_handleConditionControl].
          break;
        case DeCommandStep(:final raw):
          if (!_executeCommand(raw)) return;
      }
    }
  }

  bool get _isActive =>
      _conditions.isEmpty || _conditions.every((frame) => frame.isActive);

  bool _handleConditionControl(DialogueEditorStep step) {
    final raw = switch (step) {
      DeConditionStep(:final raw) => raw.trim(),
      DeCommandStep(:final raw) => raw.trim(),
      _ => '',
    };
    final ifMatch = RegExp(r'^<<if\s+(.+)>>$').firstMatch(raw);
    if (ifMatch != null) {
      final parentActive = _isActive;
      final result = parentActive && _evaluate(ifMatch.group(1)!.trim());
      _conditions.add(
        _DialogueConditionFrame(
          parentActive: parentActive,
          conditionMatched: result,
          isActive: result,
        ),
      );
      transcript.add(
        DialoguePreviewTrace(
          kind: DialoguePreviewTraceKind.condition,
          source: raw,
          message: result ? 'Condition vraie.' : 'Condition fausse.',
          state: _state,
        ),
      );
      return true;
    }
    if (raw == '<<else>>') {
      if (_conditions.isEmpty) return false;
      final frame = _conditions.last;
      frame.isActive = frame.parentActive && !frame.conditionMatched;
      frame.conditionMatched = true;
      return true;
    }
    if (raw == '<<endif>>') {
      if (_conditions.isNotEmpty) _conditions.removeLast();
      return true;
    }
    return step is DeConditionStep;
  }

  bool _evaluate(String expression) {
    var source = expression.trim();
    if (source.startsWith('not ')) return !_evaluate(source.substring(4));
    final comparison = RegExp(
      r'^\$([A-Za-z_][\w]*)\s*(==|!=)\s*(.+)$',
    ).firstMatch(source);
    if (comparison != null) {
      final current = _state[comparison.group(1)!];
      final expected = _parseValue(comparison.group(3)!);
      final equal = current == expected;
      return comparison.group(2) == '==' ? equal : !equal;
    }
    final variable = RegExp(r'^\$([A-Za-z_][\w]*)$').firstMatch(source);
    if (variable != null) return _truthy(_state[variable.group(1)!]);
    return _truthy(_parseValue(source));
  }

  bool _executeCommand(String raw) {
    final set = RegExp(
      r'^<<set\s+\$([A-Za-z_][\w]*)\s+to\s+(.+)>>$',
    ).firstMatch(raw.trim());
    if (set != null) {
      final name = set.group(1)!;
      _state[name] = _parseValue(set.group(2)!);
      transcript.add(
        DialoguePreviewTrace(
          kind: DialoguePreviewTraceKind.command,
          source: raw,
          message: 'Variable \$$name mise à jour.',
          state: _state,
        ),
      );
      return true;
    }
    transcript.add(
      DialoguePreviewTrace(
        kind: DialoguePreviewTraceKind.unsupported,
        source: raw,
        message: 'Commande non supportée par le dry-run.',
        state: _state,
      ),
    );
    transcript.add(
      DialoguePreviewEnded(
        reason: 'Commande non supportée : $raw',
        outcomeId: _selectedOutcomeId,
      ),
    );
    return false;
  }

  Object? _parseValue(String raw) {
    final value = raw.trim();
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null') return null;
    final number = num.tryParse(value);
    if (number != null) return number;
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  bool _truthy(Object? value) => switch (value) {
    null => false,
    false => false,
    num value => value != 0,
    String value => value.isNotEmpty,
    _ => true,
  };

  /// L’utilisateur a choisi l’index [i] pour le dernier prompt de choix.
  void choose(int i) {
    final pending = _pendingChoices;
    if (pending == null || i < 0 || i >= pending.length) {
      return;
    }
    _pendingChoices = null;
    final outcomeId = pending[i].outcomeId?.trim() ?? '';
    if (outcomeId.isNotEmpty) {
      _selectedOutcomeId = outcomeId;
      transcript.add(
        DialoguePreviewTrace(
          kind: DialoguePreviewTraceKind.outcome,
          source: outcomeId,
          message: 'Résultat « $outcomeId » sélectionné.',
          state: _state,
        ),
      );
    }
    _activeSteps = List<DialogueEditorStep>.from(pending[i].steps);
    _index = 0;
    _drain();
  }

  void restart() {
    _reset();
  }
}

class _DialogueConditionFrame {
  _DialogueConditionFrame({
    required this.parentActive,
    required this.conditionMatched,
    required this.isActive,
  });

  final bool parentActive;
  bool conditionMatched;
  bool isActive;
}
