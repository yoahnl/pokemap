import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/editor_unsaved_work_registry.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_providers.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';

void main() {
  test('readiness provider maps editor flags and registered drafts', () {
    final registry = EditorUnsavedWorkRegistry();
    registry.register(_DirtyDialogueParticipant());
    final container = ProviderContainer(
      overrides: [
        editorUnsavedWorkRegistryProvider.overrideWithValue(registry),
        editorExitReadinessInputsProvider.overrideWithValue(
          (
            editorState: const EditorState(isDirty: true),
            hasPendingBorderPreview: true,
            hasDirtyBorderStudio: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final readiness = container.read(editorExitReadinessProvider);

    expect(
      readiness.blockers.map((blocker) => blocker.kind),
      [
        EditorExitBlockerKind.map,
        EditorExitBlockerKind.borderPreview,
        EditorExitBlockerKind.borderStudio,
        EditorExitBlockerKind.dialogueStudio,
      ],
    );
  });
}

final class _DirtyDialogueParticipant implements EditorUnsavedWorkParticipant {
  @override
  String get id => 'dialogue-studio';

  @override
  bool get isDirty => true;

  @override
  EditorExitBlockerKind get kind => EditorExitBlockerKind.dialogueStudio;

  @override
  Future<EditorUnsavedWorkSaveOutcome> save() async {
    return EditorUnsavedWorkSaveOutcome.unsupported;
  }
}
