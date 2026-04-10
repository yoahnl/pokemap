import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/editor/application/editor_workspace_controller.dart';

/// Wiring minimal des transitions de workspace.
///
/// L'objectif n'est pas de sur-provideriser l'éditeur, mais d'éviter que
/// `EditorNotifier` garde lui-même toutes les bascules triviales de mode.
final editorWorkspaceControllerProvider = Provider<EditorWorkspaceController>(
  (ref) => const EditorWorkspaceController(),
);
