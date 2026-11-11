import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

ValueChanged<String> mapLibraryOpenAction(
  ProjectManifest project,
  ValueChanged<ProjectMapEntry> activate,
  VoidCallback? close,
) => (id) {
  final entry = project.maps.where((entry) => entry.id == id).firstOrNull;
  if (entry == null) return;
  close?.call();
  activate(entry);
};
