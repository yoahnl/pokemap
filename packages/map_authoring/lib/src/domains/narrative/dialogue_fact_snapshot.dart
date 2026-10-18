import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';
import 'dialogue_source_store.dart';

Map<String, RuntimeDialogueDocument> snapshotDialogueDocuments(
    ProjectSnapshot snapshot) {
  final result = <String, RuntimeDialogueDocument>{};
  for (final entry in snapshot.manifest.dialogues) {
    final bytes =
        snapshot.resourceBytes(dialogueSourceResourceIdentity(entry.id));
    final text = utf8.decode(bytes);
    if (entry.relativePath.toLowerCase().endsWith('.json')) {
      final document = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);
      if (dialogueDocumentFactIds(document).isNotEmpty) {
        result[entry.id] = document;
      }
    } else {
      result[entry.id] = const YarnDialogueCompiler().compile(text);
    }
  }
  return result;
}
