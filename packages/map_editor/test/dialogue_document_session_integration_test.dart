import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_document_session.dart';

void main() {
  group('DialogueDocumentSession', () {
    test('create save reload and undo/redo preserve identical Yarn', () async {
      var disk = 'title: Start\n---\nGuide: Bonjour.\n===\n';
      final recovery = InMemoryDialogueRecoveryStore();
      final session = DialogueDocumentSession(
        dialogueId: 'dlg_selbrume',
        initialYarn: disk,
        load: () async => disk,
        persist: (source) async => disk = source,
        recoveryStore: recovery,
      );
      await session.initialize();

      final created = session.document.createNode(title: 'Suite');
      expect(
        await session.apply(
          operationId: 'create-suite',
          label: 'Créer le nœud Suite',
          document: created,
        ),
        isTrue,
      );
      expect(session.state.status, NarrativeDocumentSessionStatus.dirty);
      expect(await session.undo(), isTrue);
      expect(session.document.nodes, hasLength(1));
      expect(await session.redo(), isTrue);
      expect(session.document.nodes, hasLength(2));
      expect(await session.save(operationId: 'save-dialogue'), isTrue);

      final durable = disk;
      final reloaded = DialogueDocumentSession(
        dialogueId: 'dlg_selbrume',
        initialYarn: '',
        load: () async => disk,
        persist: (source) async => disk = source,
      );
      await reloaded.initialize();

      expect(reloaded.state.document, durable);
      expect(reloaded.document.nodes.map((node) => node.title), [
        'Start',
        'Suite',
      ]);
      expect(reloaded.state.status, NarrativeDocumentSessionStatus.saved);
    });

    test('refused write stays dirty and exposes a product error', () async {
      var disk = 'title: Start\n---\n===\n';
      final session = DialogueDocumentSession(
        dialogueId: 'dlg_refused',
        initialYarn: disk,
        load: () async => disk,
        persist: (_) async => throw const FileSystemException('read only'),
      );
      await session.initialize();
      await session.apply(
        operationId: 'add-node',
        label: 'Ajouter un nœud',
        document: session.document.createNode(title: 'Blocked'),
      );

      expect(await session.save(operationId: 'save-refused'), isFalse);
      expect(session.state.status, NarrativeDocumentSessionStatus.failed);
      expect(session.state.code, 'dialogueWriteFailed');
      expect(session.state.blocksNavigation, isTrue);
      expect(disk, 'title: Start\n---\n===\n');
    });

    test('external edit blocks overwrite and keeps comparison', () async {
      var disk = 'title: Start\n---\n===\n';
      final session = DialogueDocumentSession(
        dialogueId: 'dlg_conflict',
        initialYarn: disk,
        load: () async => disk,
        persist: (source) async => disk = source,
      );
      await session.initialize();
      await session.apply(
        operationId: 'local-edit',
        label: 'Édition locale',
        document: session.document.createNode(title: 'Local'),
      );
      disk = 'title: Start\n---\nGuide: Externe.\n===\n';

      expect(await session.save(operationId: 'conflicted-save'), isFalse);
      expect(session.state.status, NarrativeDocumentSessionStatus.conflicted);
      expect(session.state.externalVersion?.document, disk);
    });
  });
}
