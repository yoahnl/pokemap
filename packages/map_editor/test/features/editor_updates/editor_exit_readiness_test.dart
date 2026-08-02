import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/editor_unsaved_work_registry.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_exit_readiness_resolver.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';

void main() {
  group('EditorExitReadiness', () {
    test('is ready only when no blocker exists', () {
      expect(EditorExitReadiness.clean.canExit, isTrue);

      final readiness = EditorExitReadiness.fromBlockers(
        const [
          EditorExitBlocker(
            id: 'project',
            kind: EditorExitBlockerKind.projectManifest,
          ),
        ],
      );

      expect(readiness.canExit, isFalse);
      expect(readiness.blockers.single.id, 'project');
    });

    test('deduplicates blockers and keeps a stable domain order', () {
      final readiness = EditorExitReadiness.fromBlockers(
        const [
          EditorExitBlocker(
            id: 'path-b',
            kind: EditorExitBlockerKind.pathStudio,
          ),
          EditorExitBlocker(
            id: 'map',
            kind: EditorExitBlockerKind.map,
          ),
          EditorExitBlocker(
            id: 'path-a',
            kind: EditorExitBlockerKind.pathStudio,
          ),
          EditorExitBlocker(
            id: 'path-a',
            kind: EditorExitBlockerKind.pathStudio,
          ),
        ],
      );

      expect(
        readiness.blockers.map((blocker) => blocker.id),
        ['map', 'path-a', 'path-b'],
      );
    });

    test('declares every known editor draft domain explicitly', () {
      expect(
        EditorExitBlockerKind.values,
        containsAll(
          const [
            EditorExitBlockerKind.map,
            EditorExitBlockerKind.projectManifest,
            EditorExitBlockerKind.narrative,
            EditorExitBlockerKind.personalization,
            EditorExitBlockerKind.borderPreview,
            EditorExitBlockerKind.borderStudio,
            EditorExitBlockerKind.pathStudio,
            EditorExitBlockerKind.stepStudio,
            EditorExitBlockerKind.environmentStudio,
            EditorExitBlockerKind.dialogueStudio,
            EditorExitBlockerKind.globalStoryStudio,
            EditorExitBlockerKind.eventBuilderV2,
            EditorExitBlockerKind.pendingTemplate,
            EditorExitBlockerKind.saveInProgress,
            EditorExitBlockerKind.unknown,
          ],
        ),
      );
    });
  });

  test('resolver combines editor state, border preview and registry', () {
    final registry = EditorUnsavedWorkRegistry();
    registry.register(
      _ReadinessParticipant(
        id: 'step-studio',
        kind: EditorExitBlockerKind.stepStudio,
      ),
    );

    final readiness = resolveEditorExitReadiness(
      editorState: const EditorState(
        isDirty: true,
        isProjectDirty: true,
        isSaving: true,
      ),
      hasPendingBorderPreview: true,
      hasDirtyBorderStudio: true,
      registry: registry,
    );

    expect(
      readiness.blockers.map((blocker) => blocker.kind),
      [
        EditorExitBlockerKind.map,
        EditorExitBlockerKind.projectManifest,
        EditorExitBlockerKind.borderPreview,
        EditorExitBlockerKind.borderStudio,
        EditorExitBlockerKind.stepStudio,
        EditorExitBlockerKind.saveInProgress,
      ],
    );
  });
}

final class _ReadinessParticipant implements EditorUnsavedWorkParticipant {
  _ReadinessParticipant({
    required this.id,
    required this.kind,
  });

  @override
  final String id;

  @override
  final EditorExitBlockerKind kind;

  @override
  bool get isDirty => true;

  @override
  Future<EditorUnsavedWorkSaveOutcome> save() async {
    return EditorUnsavedWorkSaveOutcome.unsupported;
  }
}
