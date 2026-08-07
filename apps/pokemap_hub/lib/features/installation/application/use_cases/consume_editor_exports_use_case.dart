import 'package:pokemap_hub/features/installation/domain/entities/editor_export_install_result.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/editor_export_inbox_interface.dart';

/// Installs anything the editor dropped in the inbox since the last reload.
final class ConsumeEditorExportsUseCase {
  const ConsumeEditorExportsUseCase(this._inbox);

  final EditorExportInboxInterface _inbox;

  Future<List<EditorExportInstallResult>> call() => _inbox.consumePending();
}
