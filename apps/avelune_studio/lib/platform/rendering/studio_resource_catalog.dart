import 'dart:convert';

import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, assetCatalogStorageKey;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

Future<Map<String, String>> resolveStudioResourcePaths(
  String projectRoot,
  ProjectManifest manifest,
  Set<String> supported,
) async {
  const reader = LocalProjectFileReader();
  AssetCatalog? catalog;
  final probe = await reader.probeResource(
    projectRoot: projectRoot,
    relativePath: assetCatalogStorageKey,
  );
  if (probe.status == ProjectResourceProbeStatus.exists) {
    catalog = AssetCatalog.fromJson(
      jsonDecode(
            utf8.decode(
              await reader.readBytes(
                projectRoot: projectRoot,
                relativePath: assetCatalogStorageKey,
              ),
            ),
          )
          as Map<String, dynamic>,
    );
  } else if (probe.status != ProjectResourceProbeStatus.missing) {
    throw StateError('Catalogue: ${probe.status.name}');
  }
  return resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: supported,
    assetCatalog: catalog,
  );
}
