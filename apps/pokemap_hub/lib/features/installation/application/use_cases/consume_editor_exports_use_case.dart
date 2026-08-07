import 'package:pokemap_hub/features/installation/data/repositories/editor_export_install_inbox.dart';

/// Installs anything the editor dropped in the inbox since the last reload.
final class ConsumeEditorExportsUseCase {
  const ConsumeEditorExportsUseCase(this._inbox);

  final EditorExportInstallInbox _inbox;

  Future<List<EditorExportInstallResult>> call() => _inbox.consumePending();
}
