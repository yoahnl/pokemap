import 'package:pokemap_hub/features/installation/domain/entities/editor_export_install_result.dart';

/// Drains whatever the editor dropped for installation since the last pass.
abstract interface class EditorExportInboxInterface {
  Future<List<EditorExportInstallResult>> consumePending();
}
