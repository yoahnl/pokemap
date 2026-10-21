import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';

Future<ProjectTemplateCatalog> loadCliProjectTemplateCatalog({
  String embeddedCatalogBase64 = const String.fromEnvironment(
    'POKEMAP_AUTHORING_TEMPLATE_CATALOG_BASE64',
  ),
  Future<Uri?> Function(Uri)? resolvePackageUri,
}) async {
  if (embeddedCatalogBase64.isNotEmpty) {
    return ProjectTemplateCatalog.fromJson(
      jsonDecode(utf8.decode(base64Decode(embeddedCatalogBase64))),
    );
  }
  final packageLibrary = await (resolvePackageUri ?? Isolate.resolvePackageUri)(
    Uri.parse('package:map_authoring/map_authoring.dart'),
  );
  if (packageLibrary == null) {
    throw StateError(
        'Unable to locate the configured project template catalogue.');
  }
  return ProjectTemplateCatalog.fromJson(
    jsonDecode(await File.fromUri(
      packageLibrary.resolve('../assets/project_templates.v1.json'),
    ).readAsString()),
  );
}
