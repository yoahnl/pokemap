import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

class DialoguePreviewState {
  DialoguePreviewState(DialogueAuthoringCompileResult compiled) {
    if (!compiled.canPublish) {
      error = compiled.diagnostics.map((d) => d.message).join('\n');
      return;
    }
    _nodes = {for (final n in compiled.document!.nodes) n.title: n};
    final start = compiled.startNode ?? compiled.document!.nodes.first.title;
    _pending.addAll(_nodes[start]!.steps);
    _drain();
  }
  Map<String, RuntimeDialogueNode> _nodes = {};
  final _pending = <RuntimeDialogueStep>[];
  final _outcomes = <String>[];
  final _transcript = <String>[];
  RuntimeDialogueLine? line;
  List<RuntimeDialogueChoice> choices = const [];
  List<String> get outcomes => List.unmodifiable(_outcomes);
  List<String> get transcript => List.unmodifiable(_transcript);
  bool ended = false, truncated = false;
  String? error;
  int _operations = 0;
  void advance() {
    if (choices.isNotEmpty || ended || truncated || error != null) return;
    line = null;
    _drain();
  }

  void choose(int index) {
    if (index < 0 || index >= choices.length || truncated) return;
    final choice = choices[index];
    if (choice.outcomeId != null) _outcomes.add(choice.outcomeId!);
    _pending.insertAll(0, choice.steps);
    choices = const [];
    line = null;
    _drain();
  }

  void _drain() {
    while (_pending.isNotEmpty) {
      if (_operations++ >= 512) {
        truncated = true;
        error = 'Boucle interrompue après 512 étapes.';
        return;
      }
      switch (_pending.removeAt(0)) {
        case RuntimeDialogueLine next:
          line = next;
          _transcript.add(next.text);
          return;
        case RuntimeDialogueChoiceBlock block:
          choices = block.choices;
          return;
        case RuntimeDialogueJump jump:
          final target = _nodes[jump.targetNode];
          if (target == null) {
            error = 'Suite absente : ${jump.targetNode}';
            return;
          }
          _pending
            ..clear()
            ..addAll(target.steps);
      }
    }
    ended = true;
  }
}
