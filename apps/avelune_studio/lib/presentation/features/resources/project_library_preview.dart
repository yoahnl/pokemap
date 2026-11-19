import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/resource_catalog.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../map_builder/map_builder_resource_preview.dart';

final _resources = Expando<Map<String, ResourceItem>>();

ResourceItem? _resource(ProjectManifest project, String identity) =>
    (_resources[project] ??= {
      for (final item in resourceCatalog(project)) item.identity: item,
    })[identity];

Widget? projectLibraryThumbnail(
  String identity,
  ProjectManifest? project,
  MapWorkspaceVisuals visuals,
) {
  if (project == null) return null;
  final item = _resource(project, identity);
  if (item == null) return null;
  return switch (resourcePreviewSource(item, project)) {
    ElementPreviewSource(:final element) => visuals.thumbnail(
      element,
      size: 112,
    ),
    TileFramePreviewSource(:final entry) => visuals.tileThumbnail(
      entry,
      size: 112,
    ),
    AtlasPreviewSource(:final tilesetId)
        when visuals is ResourceWorkspaceVisuals =>
      (visuals as ResourceWorkspaceVisuals).atlasPreview(tilesetId),
    _ => null,
  };
}

class ProjectLibraryPreview extends StatefulWidget {
  const ProjectLibraryPreview({
    super.key,
    required this.entry,
    required this.maps,
    required this.visuals,
  });

  final ProjectLibraryItem entry;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals visuals;

  @override
  State<ProjectLibraryPreview> createState() => _ProjectLibraryPreviewState();
}

class _ProjectLibraryPreviewState extends State<ProjectLibraryPreview> {
  late var _reading = _read();

  @override
  void didUpdateWidget(ProjectLibraryPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry || oldWidget.maps != widget.maps) {
      _reading = _read();
    }
  }

  Future<({ResourceItem item, ProjectManifest project})?> _read() async {
    final entry = widget.entry;
    final maps = widget.maps;
    await maps.ensureResourceClosure(entry.kind, entry.id);
    final project = maps.visualProject ?? maps.project;
    if (project == null) return null;
    final item = _resource(project, entry.identity);
    return item == null ? null : (item: item, project: project);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _reading,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final result = snapshot.data;
      if (result == null) {
        return const Tooltip(
          message: 'Aperçu indisponible',
          child: Icon(Icons.image_not_supported_outlined),
        );
      }
      return MapBuilderResourcePreview(
        item: result.item,
        project: result.project,
        visuals: widget.visuals,
        size: 200,
      );
    },
  );
}
