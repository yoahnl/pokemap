import 'dialogue_runtime_models.dart';

/// Parse the full content of a `.yarn` file and return all nodes found.
///
/// Each node starts with a `title:` header followed by `---` and ends with
/// `===`. Body lines are trimmed; empty lines and Yarn command lines (`<<...>>`)
/// are excluded.
List<YarnNode> parseYarnFile(String content) {
  final nodes = <YarnNode>[];
  String? currentTitle;
  final currentBody = <String>[];
  bool inBody = false;

  for (final raw in content.split('\n')) {
    final line = raw.trimRight();

    if (!inBody) {
      final trimmed = line.trim();
      if (trimmed.startsWith('title:')) {
        currentTitle = trimmed.substring('title:'.length).trim();
      } else if (trimmed == '---') {
        inBody = true;
        currentBody.clear();
      }
    } else {
      final trimmed = line.trim();
      if (trimmed == '===') {
        if (currentTitle != null && currentBody.isNotEmpty) {
          nodes.add(YarnNode(title: currentTitle, bodyLines: List.unmodifiable(currentBody)));
        }
        currentTitle = null;
        currentBody.clear();
        inBody = false;
      } else if (trimmed.isNotEmpty && !(trimmed.startsWith('<<') && trimmed.endsWith('>>'))) {
        currentBody.add(trimmed);
      }
    }
  }

  return nodes;
}

/// Find a node by title. Returns null if not found.
YarnNode? findYarnNode(List<YarnNode> nodes, String title) {
  for (final node in nodes) {
    if (node.title == title) return node;
  }
  return null;
}
