part of 'dialogue_yarn_codec.dart';

final class _TextLocation {
  const _TextLocation(this.start, this.token);
  final int start;
  final String token;
  int get end => start + token.length;

  String replace(String previous, String value,
      {bool narration = false, bool choice = false}) {
    if (YarnDialogueLineLiteral.matches(token)) {
      final line = YarnDialogueLineLiteral.parse(token);
      return _encodeLineText(value, line.speaker);
    }
    final decoded = _decodeText(token);
    final prefix = choice
        ? ''
        : narration
            ? '('
            : decoded.substring(0, decoded.length - previous.length);
    final suffix = narration ? decoded.substring(1 + previous.length) : '';
    final text = '$prefix$value$suffix';
    if (!narration && !choice) {
      final line = _lineStepFromPlainText(token) as DeLineStep;
      if (!_lineTextMatches(text, value, line.speaker)) {
        return YarnDialogueLineLiteral(text: value, speaker: line.speaker)
            .toSource();
      }
    }
    return token.startsWith(r'\"')
        ? '\\${jsonEncode(text)}'
        : _encodeText(text);
  }
}

String? _emitPatchedDialogueTexts(
    DialogueEditorDocument document, String source) {
  final locations = <String, _TextLocation>{};
  final original = _parseYarnDocument(source, locations: locations);
  if (original.nodes.length != document.nodes.length) return null;
  final restored = cloneDialogueDocument(document);
  final patches = <(_TextLocation, String)>[];
  bool replace(String id, String before, String after,
      {bool narration = false, bool choice = false}) {
    if (before == after) return true;
    final location = locations[id];
    if (location == null) return false;
    patches.add((
      location,
      location.replace(before, after, narration: narration, choice: choice)
    ));
    return true;
  }

  bool walk(List<DialogueEditorStep> before, List<DialogueEditorStep> after) {
    final old = before.where((s) => !_emitSkip(s)).toList();
    final next = after.where((s) => !_emitSkip(s)).toList();
    if (old.length != next.length) return false;
    for (var i = 0; i < old.length; i++) {
      final a = old[i];
      final b = next[i];
      switch ((a, b)) {
        case (final DeLineStep x, final DeLineStep y):
          if (!replace(x.id, x.body, y.body)) return false;
          y.body = x.body;
        case (final DeNarrationStep x, final DeNarrationStep y):
          if (!replace(x.id, x.text, y.text, narration: true)) return false;
          y.text = x.text;
        case (final DeChoiceStep x, final DeChoiceStep y):
          if (x.branches.length != y.branches.length) return false;
          for (var j = 0; j < x.branches.length; j++) {
            final oldBranch = x.branches[j];
            final newBranch = y.branches[j];
            if (!replace(oldBranch.id, oldBranch.label, newBranch.label,
                    choice: true) ||
                !walk(oldBranch.steps, newBranch.steps)) {
              return false;
            }
            newBranch.label = oldBranch.label;
          }
        default:
          break;
      }
    }
    return true;
  }

  for (var i = 0; i < original.nodes.length; i++) {
    if (!walk(original.nodes[i].steps, restored.nodes[i].steps)) return null;
  }
  if (_emitCanonicalDocument(original) != _emitCanonicalDocument(restored)) {
    return null;
  }
  patches.sort((a, b) => a.$1.start.compareTo(b.$1.start));
  final result = StringBuffer();
  var cursor = 0;
  for (final (location, text) in patches) {
    if (location.start < cursor) return null;
    result.write(source.substring(cursor, location.start));
    result.write(text);
    cursor = location.end;
  }
  result.write(source.substring(cursor));
  return result.toString();
}
