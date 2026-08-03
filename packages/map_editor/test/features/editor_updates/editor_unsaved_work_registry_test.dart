import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/editor_unsaved_work_registry.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';

void main() {
  group('EditorUnsavedWorkRegistry', () {
    test('rejects duplicate participant identifiers', () {
      final registry = EditorUnsavedWorkRegistry();
      final participant = _FakeParticipant(
        id: 'dialogue-studio',
        kind: EditorExitBlockerKind.dialogueStudio,
      );

      registry.register(participant);

      expect(
        () => registry.register(participant),
        throwsA(isA<StateError>()),
      );
    });

    test('keeps a dirty participant registered outside widget lifetime', () {
      final registry = EditorUnsavedWorkRegistry();
      final participant = _FakeParticipant(
        id: 'dialogue-studio',
        kind: EditorExitBlockerKind.dialogueStudio,
        isDirty: true,
      );
      registry.register(participant);

      expect(
        () => registry.unregister('dialogue-studio'),
        throwsA(isA<StateError>()),
      );
      expect(registry.readiness.canExit, isFalse);
      expect(registry.readiness.blockers.single.id, 'dialogue-studio');
    });

    test('removes a participant after its draft is resolved', () {
      final registry = EditorUnsavedWorkRegistry();
      final participant = _FakeParticipant(
        id: 'dialogue-studio',
        kind: EditorExitBlockerKind.dialogueStudio,
        isDirty: true,
      );
      registry.register(participant);

      participant.isDirty = false;
      registry.notifyChanged();
      registry.unregister('dialogue-studio');

      expect(registry.readiness.canExit, isTrue);
      expect(registry.participants, isEmpty);
    });

    test('combines application participants with global blockers', () {
      final registry = EditorUnsavedWorkRegistry();
      registry.register(
        _FakeParticipant(
          id: 'environment-studio',
          kind: EditorExitBlockerKind.environmentStudio,
          isDirty: true,
        ),
      );

      final readiness = registry.resolveReadiness(
        globalBlockers: const [
          EditorExitBlocker(
            id: 'map',
            kind: EditorExitBlockerKind.map,
          ),
          EditorExitBlocker(
            id: 'saving',
            kind: EditorExitBlockerKind.saveInProgress,
          ),
        ],
      );

      expect(
        readiness.blockers.map((blocker) => blocker.id),
        ['map', 'environment-studio', 'saving'],
      );
    });
  });
}

final class _FakeParticipant implements EditorUnsavedWorkParticipant {
  _FakeParticipant({
    required this.id,
    required this.kind,
    this.isDirty = false,
  });

  @override
  final String id;

  @override
  final EditorExitBlockerKind kind;

  @override
  bool isDirty;

  @override
  Future<EditorUnsavedWorkSaveOutcome> save() async {
    isDirty = false;
    return EditorUnsavedWorkSaveOutcome.saved;
  }
}
