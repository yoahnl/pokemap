import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';
import 'parse_yarn_dialogue.dart';
import 'resolve_dialogue.dart';

/// Nœuds parsés par chemin absolu, revalidés par (mtime, taille) à chaque
/// accès : chaque interaction PNJ relisait et re-parsait le fichier entier.
/// Les sessions ne mutent jamais les nœuds (les transformations passent par
/// `mapText`, qui clone), le partage est donc sûr.
final Map<String, _CachedDialogueNodes> _dialogueNodesByPath =
    <String, _CachedDialogueNodes>{};
const int _dialogueNodesCacheCapacity = 64;

final class _CachedDialogueNodes {
  const _CachedDialogueNodes({
    required this.modified,
    required this.size,
    required this.nodes,
  });

  final DateTime modified;
  final int size;
  final List<YarnNode> nodes;
}

/// Read the `.yarn` file referenced by [resolved], parse it, and start a
/// [DialogueSession] at the requested node.
///
/// Returns null if the file cannot be read, has no nodes, or the requested
/// node is not found.
Future<DialogueSession?> loadDialogueContent(ResolvedDialogue resolved) async {
  final List<YarnNode> nodes;
  try {
    final path = resolved.absoluteFilePath;
    final file = File(path);
    final stat = await file.stat();
    final cached = _dialogueNodesByPath.remove(path);
    if (cached != null &&
        cached.modified == stat.modified &&
        cached.size == stat.size) {
      _dialogueNodesByPath[path] = cached;
      nodes = cached.nodes;
    } else {
      if (path.toLowerCase().endsWith('.json')) {
        final document = const RuntimeDialogueDocumentCodec().decodeUtf8(
          await file.readAsBytes(),
        );
        nodes = runtimeDialogueNodesFromDocument(document);
      } else {
        nodes = parseYarnFile(await file.readAsString());
      }
      _dialogueNodesByPath[path] = _CachedDialogueNodes(
        modified: stat.modified,
        size: stat.size,
        nodes: nodes,
      );
      while (_dialogueNodesByPath.length > _dialogueNodesCacheCapacity) {
        _dialogueNodesByPath.remove(_dialogueNodesByPath.keys.first);
      }
    }
  } catch (e) {
    debugPrint(
      '[dialogue] failed to load file ${resolved.absoluteFilePath}: $e',
    );
    return null;
  }

  if (kDebugMode) {
    debugPrint(
      '[dialogue] parsed ${nodes.length} node(s) from '
      '${resolved.absoluteFilePath}',
    );
  }

  if (nodes.isEmpty) {
    debugPrint('[dialogue] no nodes found in file');
    return null;
  }

  final session = DialogueSession.start(nodes, resolved.startNode);
  if (session == null) {
    debugPrint('[dialogue] session could not start (empty body?)');
    return null;
  }

  final startTitle = resolved.startNode;
  if (startTitle != null && startTitle.isNotEmpty) {
    if (session.currentNodeTitle != startTitle) {
      debugPrint(
          '[dialogue] requested node "$startTitle" not found — falling back to "${session.currentNodeTitle}"');
    } else {
      debugPrint('[dialogue] starting at node "$startTitle"');
    }
  } else {
    debugPrint(
        '[dialogue] no startNode specified — using first node "${session.currentNodeTitle}"');
  }

  return session;
}
