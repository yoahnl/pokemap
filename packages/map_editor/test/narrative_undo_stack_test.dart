import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';

void main() {
  group('NarrativeUndoStack', () {
    test('records one complete intention and restores it through undo and redo',
        () {
      const stack = NarrativeUndoStack<String>(capacity: 3);

      final recorded = stack.record(
        operationId: 'rename-1',
        label: 'Renommer la cinématique',
        before: 'A',
        after: 'B',
      );
      final undo = recorded.undo('B');
      final redo = undo!.stack.redo('A');

      expect(recorded.canUndo, isTrue);
      expect(recorded.canRedo, isFalse);
      expect(undo.document, 'A');
      expect(undo.entry.operationId, 'rename-1');
      expect(undo.stack.canUndo, isFalse);
      expect(undo.stack.canRedo, isTrue);
      expect(redo!.document, 'B');
      expect(redo.stack.canUndo, isTrue);
      expect(redo.stack.canRedo, isFalse);
    });

    test('a new intention after undo clears the redo branch', () {
      const stack = NarrativeUndoStack<String>();
      final recorded = stack
          .record(
            operationId: 'edit-1',
            label: 'Première édition',
            before: 'A',
            after: 'B',
          )
          .record(
            operationId: 'edit-2',
            label: 'Deuxième édition',
            before: 'B',
            after: 'C',
          );
      final undone = recorded.undo('C')!;

      final branched = undone.stack.record(
        operationId: 'edit-3',
        label: 'Branche locale',
        before: undone.document,
        after: 'D',
      );

      expect(branched.canUndo, isTrue);
      expect(branched.canRedo, isFalse);
      expect(branched.undoEntries.map((entry) => entry.operationId), [
        'edit-1',
        'edit-3',
      ]);
    });

    test('capacity evicts the oldest intention and collections are immutable',
        () {
      var stack = const NarrativeUndoStack<String>(capacity: 2);
      for (var index = 0; index < 3; index++) {
        stack = stack.record(
          operationId: 'edit-$index',
          label: 'Édition $index',
          before: '$index',
          after: '${index + 1}',
        );
      }

      expect(
        stack.undoEntries.map((entry) => entry.operationId),
        ['edit-1', 'edit-2'],
      );
      expect(
        () => stack.undoEntries.add(
          const NarrativeUndoEntry(
            operationId: 'forbidden',
            label: 'Interdit',
            before: 'x',
            after: 'y',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('a no-op preserves identity and blank intent metadata is rejected',
        () {
      const stack = NarrativeUndoStack<String>();

      expect(
        stack.record(
          operationId: 'same',
          label: 'Aucun changement',
          before: 'A',
          after: 'A',
        ),
        same(stack),
      );
      expect(
        () => stack.record(
          operationId: ' ',
          label: 'Libellé',
          before: 'A',
          after: 'B',
        ),
        throwsArgumentError,
      );
      expect(
        () => stack.record(
          operationId: 'edit',
          label: ' ',
          before: 'A',
          after: 'B',
        ),
        throwsArgumentError,
      );
    });

    test('undo and redo fail closed when the visible document drifted', () {
      final recorded = const NarrativeUndoStack<String>().record(
        operationId: 'edit',
        label: 'Édition',
        before: 'A',
        after: 'B',
      );
      final undone = recorded.undo('B')!;

      expect(() => recorded.undo('external'), throwsStateError);
      expect(() => undone.stack.redo('external'), throwsStateError);
    });

    test('a reconstructed stack preserves both recovery branches', () {
      const first = NarrativeUndoEntry<String>(
        operationId: 'first',
        label: 'Première',
        before: 'A',
        after: 'B',
      );
      const second = NarrativeUndoEntry<String>(
        operationId: 'second',
        label: 'Deuxième',
        before: 'B',
        after: 'C',
      );
      const restored = NarrativeUndoStack<String>(
        undoEntries: [first],
        redoEntries: [second],
        capacity: 5,
      );

      expect(restored.canUndo, isTrue);
      expect(restored.canRedo, isTrue);
      expect(restored.undoEntries.single, same(first));
      expect(restored.redoEntries.single, same(second));
    });
  });
}
