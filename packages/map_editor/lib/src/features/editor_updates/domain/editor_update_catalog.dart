import 'package:pub_semver/pub_semver.dart';

import 'editor_update_models.dart';

abstract interface class EditorUpdateCatalog {
  Future<EditorUpdateRelease?> latestStable(Version currentVersion);
}

abstract interface class EditorInstalledVersionReader {
  Future<Version> read();
}

enum EditorUpdateCatalogFailureCode {
  network,
  timeout,
  httpStatus,
  responseTooLarge,
  invalidJson,
  invalidSchema,
  invalidChannel,
  invalidVersion,
  invalidTag,
  invalidDate,
  untrustedUrl,
}

final class EditorUpdateCatalogException implements Exception {
  const EditorUpdateCatalogException(this.code, this.message);

  final EditorUpdateCatalogFailureCode code;
  final String message;

  @override
  String toString() => 'EditorUpdateCatalogException($code, $message)';
}
