import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/load_dialogue_content.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';

void main() {
  test('loads a compiled data-only dialogue with legacy session semantics',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap_compiled_dialogue_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final document = const YarnDialogueCompiler().compile('''
title: Start
---
Guide: Bienvenue.
-> Oui
  <<outcome accepted>>
  Continuons.
-> Non
  <<outcome declined>>
  Au revoir.
===
''');
    final file = File('${directory.path}/intro.json');
    await file.writeAsBytes(
      const RuntimeDialogueDocumentCodec().encodeUtf8(document),
      flush: true,
    );

    final session = await loadDialogueContent(
      ResolvedDialogue(
        absoluteFilePath: file.path,
        dialogueId: 'intro',
        startNode: 'Start',
      ),
    );

    expect(
      (session!.state as DialogueShowingLine).text,
      'Guide: Bienvenue.',
    );
    final waiting = session.advance()!;
    expect(waiting.state, isA<DialogueWaitingForChoice>());
    final chosen = waiting.confirmChoice()!;
    expect(chosen.selectedOutcomeId, 'accepted');
    expect((chosen.state as DialogueShowingLine).text, 'Continuons.');
  });
}
