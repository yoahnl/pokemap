/// What consuming the editor's export inbox produced, per request.
///
/// A contract type: the application layer reports these to the dashboard, so
/// it must not have to import the data layer to name them.
enum EditorExportInstallStatus { installed, failed }

final class EditorExportInstallResult {
  const EditorExportInstallResult({
    required this.requestId,
    required this.status,
    required this.code,
  });

  final String requestId;
  final EditorExportInstallStatus status;
  final String code;
}

/// Consumes the editor-to-Hub inbox without trusting either filename or bytes.
