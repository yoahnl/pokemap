import '../../editor/application/editor_unsaved_work_registry.dart';
import '../../editor/state/editor_state.dart';
import '../domain/editor_exit_readiness.dart';

EditorExitReadiness resolveEditorExitReadiness({
  required EditorState editorState,
  required bool hasPendingBorderPreview,
  required bool hasDirtyBorderStudio,
  required EditorUnsavedWorkRegistry registry,
}) {
  return registry.resolveReadiness(
    globalBlockers: [
      if (editorState.isDirty)
        const EditorExitBlocker(
          id: 'active-map',
          kind: EditorExitBlockerKind.map,
        ),
      if (editorState.isProjectDirty)
        const EditorExitBlocker(
          id: 'project-manifest',
          kind: EditorExitBlockerKind.projectManifest,
        ),
      if (hasPendingBorderPreview)
        const EditorExitBlocker(
          id: 'border-preview',
          kind: EditorExitBlockerKind.borderPreview,
        ),
      if (hasDirtyBorderStudio)
        const EditorExitBlocker(
          id: 'border-studio',
          kind: EditorExitBlockerKind.borderStudio,
        ),
      if (editorState.isSaving)
        const EditorExitBlocker(
          id: 'save-in-progress',
          kind: EditorExitBlockerKind.saveInProgress,
        ),
    ],
  );
}
