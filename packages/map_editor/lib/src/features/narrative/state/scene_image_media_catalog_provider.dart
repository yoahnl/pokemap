import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final sceneImageMediaCatalogProvider = FutureProvider.autoDispose
    .family<ProjectMediaCatalog, String?>((ref, root) async {
      if (root == null || root.isEmpty) return ProjectMediaCatalog();
      final file = File(p.join(root, projectMediaCatalogStorageKey));
      if (!await file.exists()) return ProjectMediaCatalog();
      return decodeProjectMediaCatalogBytes(await file.readAsBytes());
    });
