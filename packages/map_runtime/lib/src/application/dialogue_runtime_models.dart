/// A single Yarn node extracted from a `.yarn` file.
class YarnNode {
  const YarnNode({required this.title, required this.bodyLines});

  /// The node title as declared with `title: ...`.
  final String title;

  /// The body lines of the node (between `---` and `===`), with empty lines
  /// and Yarn command lines (`<<...>>`) filtered out.
  final List<String> bodyLines;
}

/// Immutable snapshot of an in-progress dialogue session.
class DialogueSession {
  const DialogueSession({
    required this.nodes,
    required this.currentNodeIndex,
    required this.currentLineIndex,
  });

  final List<YarnNode> nodes;
  final int currentNodeIndex;
  final int currentLineIndex;

  YarnNode get currentNode => nodes[currentNodeIndex];

  String get currentLine => currentNode.bodyLines[currentLineIndex];

  bool get isLastLine =>
      currentLineIndex >= currentNode.bodyLines.length - 1;

  /// Advance to the next line. Returns null if the session is finished.
  DialogueSession? advance() {
    if (!isLastLine) {
      return DialogueSession(
        nodes: nodes,
        currentNodeIndex: currentNodeIndex,
        currentLineIndex: currentLineIndex + 1,
      );
    }
    return null;
  }

  static DialogueSession? start(List<YarnNode> nodes, String? startNodeTitle) {
    if (nodes.isEmpty) return null;
    int index = 0;
    if (startNodeTitle != null && startNodeTitle.isNotEmpty) {
      final found = nodes.indexWhere((n) => n.title == startNodeTitle);
      if (found != -1) index = found;
    }
    final node = nodes[index];
    if (node.bodyLines.isEmpty) return null;
    return DialogueSession(
      nodes: nodes,
      currentNodeIndex: index,
      currentLineIndex: 0,
    );
  }
}
