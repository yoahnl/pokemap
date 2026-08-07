import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

/// Loads a freshly staged release once before it is published, so a package
/// that passes checksum verification but cannot actually boot is rejected
/// while the transaction can still roll back.
Future<void> loadInstalledProjectSmoke(
  Directory stagedVersionRoot,
  GamePackageManifest manifest,
) async {
  final projectFile = File(
    p.join(stagedVersionRoot.path, 'project', 'project.json'),
  );
  final decoded = jsonDecode(await projectFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Installed project manifest is invalid.');
  }
  final project = ProjectManifest.fromJson(decoded);
  final mapId = project.newGame.enabled
      ? project.newGame.startMapId
      : project.maps.firstOrNull?.id;
  if (mapId == null || mapId.trim().isEmpty) {
    throw const FormatException('Installed game has no launchable map.');
  }
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: mapId,
  );
  if (bundle.manifest.version.name != manifest.compatibility.projectFormat) {
    throw const FormatException('Installed project format changed on load.');
  }
}
