import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../../resources/application/resource_preview_source.dart';

abstract interface class ScopedResourcePreviewVisuals {
  void refreshResourcePreviews();

  void invalidateResourcePreviews(Set<String> changedRelativePaths);

  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  });
}
