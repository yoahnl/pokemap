import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/resource_catalog.dart';
import '../../shared/localization/studio_labels.dart';
import '../../shared/localization/studio_locale.dart';
import '../map_builder/map_builder_resource_preview.dart';

class ProjectLibraryDetail extends StatefulWidget {
  const ProjectLibraryDetail({
    super.key,
    required this.item,
    required this.library,
    required this.maps,
    required this.visuals,
  });
  final ProjectLibraryItem item;
  final ProjectResourceLibrary library;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals? visuals;
  @override
  State<ProjectLibraryDetail> createState() => _ProjectLibraryDetailState();
}

class _ProjectLibraryDetailState extends State<ProjectLibraryDetail> {
  late var _preview = _readPreview();

  @override
  void didUpdateWidget(ProjectLibraryDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item || oldWidget.maps != widget.maps) {
      _preview = _readPreview();
    }
  }

  Future<({ResourceItem item, ProjectManifest project})?> _readPreview() async {
    final item = widget.item;
    final maps = widget.maps;
    await maps.ensureResourceClosure(item.kind, item.id);
    final project = maps.visualProject ?? maps.project;
    if (project == null) return null;
    final definition = resourceCatalog(project)
        .where((entry) => entry.identity == item.identity)
        .firstOrNull;
    return definition == null ? null : (item: definition, project: project);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = context.l10n;
    final owner = widget.maps.project?.maps
        .where((map) => map.id == item.mapId)
        .firstOrNull;
    return ListView(
      children: [
        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: StudioSpacing.s),
        Text(l10n.resourceKindLabel(item.kind)),
        if (item.familyId case final id?) Text(widget.library.familyPath(id)),
        Text(owner?.name ?? item.mapId ?? l10n.resourceScopeProject),
        if (item.description case final description?) ...[
          const SizedBox(height: StudioSpacing.l),
          Text(description),
        ],
        if (widget.visuals case final visuals?) ...[
          const SizedBox(height: StudioSpacing.l),
          FutureBuilder(
            future: _preview,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(l10n.resourcesUnavailable('${snapshot.error}'));
              }
              final result = snapshot.data;
              if (result == null) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink();
              }
              return MapBuilderResourcePreview(
                item: result.item,
                project: result.project,
                visuals: visuals,
                size: 200,
              );
            },
          ),
        ],
      ],
    );
  }
}
