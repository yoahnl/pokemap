import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';
import 'parse_yarn_dialogue.dart';
import 'resolve_dialogue.dart';

final Map<String, _CachedDialogueDocument> _dialogueDocumentsByPath =
    <String, _CachedDialogueDocument>{};
const int _dialogueDocumentCacheCapacity = 64;

final class _CachedDialogueDocument {
  const _CachedDialogueDocument({
    required this.modified,
    required this.size,
    required this.document,
  });

  final DateTime modified;
  final int size;
  final RuntimeDialogueDocument document;
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
    final cached = _dialogueDocumentsByPath.remove(path);
    final RuntimeDialogueDocument document;
    if (cached != null &&
        cached.modified == stat.modified &&
        cached.size == stat.size) {
      _dialogueDocumentsByPath[path] = cached;
      document = cached.document;
    } else {
      if (path.toLowerCase().endsWith('.json')) {
        document = const RuntimeDialogueDocumentCodec().decodeUtf8(
          await file.readAsBytes(),
        );
      } else {
        document = const YarnDialogueCompiler().compile(
          await file.readAsString(),
        );
      }
      _dialogueDocumentsByPath[path] = _CachedDialogueDocument(
        modified: stat.modified,
        size: stat.size,
        document: document,
      );
      while (_dialogueDocumentsByPath.length > _dialogueDocumentCacheCapacity) {
        _dialogueDocumentsByPath.remove(_dialogueDocumentsByPath.keys.first);
      }
    }
    nodes = runtimeDialogueNodesFromDocument(
      document,
      localization: path.toLowerCase().endsWith('.json')
          ? resolved.localization
          : null,
      preferredLocale: resolved.preferredLocale,
      locales: resolved.locales,
    );
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
        '[dialogue] requested node "$startTitle" not found — falling back to "${session.currentNodeTitle}"',
      );
    } else {
      debugPrint('[dialogue] starting at node "$startTitle"');
    }
  } else {
    debugPrint(
      '[dialogue] no startNode specified — using first node "${session.currentNodeTitle}"',
    );
  }

  return session;
}
