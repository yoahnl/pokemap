import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import 'library/resource_library_view.dart';
import 'project_library_catalog_view.dart';
import 'project_library_preview.dart';

class ProjectLibraryPage extends StatefulWidget {
  const ProjectLibraryPage({
    super.key,
    required this.active,
    required this.maps,
    required this.visuals,
  });

  final bool active;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals? visuals;

  @override
  State<ProjectLibraryPage> createState() => _ProjectLibraryPageState();
}

class _ProjectLibraryPageState extends State<ProjectLibraryPage> {
  Future<ProjectLibraryCatalogView>? _reading;

  @override
  void initState() {
    super.initState();
    if (widget.active) _read();
  }

  @override
  void didUpdateWidget(ProjectLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maps != widget.maps) _reading = null;
    if (widget.active && _reading == null) _read();
  }

  void _read() {
    final maps = widget.maps;
    final manifest = maps.project;
    if (manifest == null) return;
    final port = maps.port;
    final result = switch (port) {
      final ProjectResourceLibraryPort reader => reader.readResourceLibrary(
        maps.session,
      ),
      _ when maps.hasCompleteProject => Future.value(
        ProjectResourceLibrary.fromManifest(manifest),
      ),
      _ => Future<ProjectResourceLibrary>.error(
        StateError('Lecteur de bibliothèque indisponible.'),
      ),
    };
    _reading = result.then(ProjectLibraryCatalogView.new);
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    if (reading == null) {
      return widget.active
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    final maps = widget.maps;
    return ExcludeFocus(
      excluding: !widget.active,
      child: FutureBuilder<ProjectLibraryCatalogView>(
        future: reading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StudioEmptyState(
                    title: 'Bibliothèque indisponible',
                    description:
                        'Le catalogue des ressources n’a pas pu être lu.',
                  ),
                  const SizedBox(height: StudioSpacing.l),
                  StudioButton(
                    label: 'Réessayer',
                    onPressed: () => setState(_read),
                  ),
                ],
              ),
            );
          }
          final catalog = snapshot.data;
          if (catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final visuals = widget.active ? widget.visuals : null;
          final visualProject = visuals == null ? null : maps.visualProject;
          return ResourceLibraryView(
            key: ValueKey(maps.session.sessionId),
            items: catalog.items,
            familyLabels: catalog.familyLabels,
            maps: {
              for (final entry in maps.project?.maps ?? const [])
                entry.id: entry.name,
            },
            showRoles: true,
            showMapScopes: false,
            onRefresh: snapshot.connectionState == ConnectionState.done
                ? () => setState(_read)
                : null,
            tilePreview: visuals == null
                ? null
                : (item) =>
                      projectLibraryThumbnail(item.id, visualProject, visuals),
            detailPreview: visuals == null
                ? null
                : (item) {
                    final entry = catalog.entries[item.id];
                    return entry == null
                        ? null
                        : ProjectLibraryPreview(
                            entry: entry,
                            maps: maps,
                            visuals: visuals,
                          );
                  },
          );
        },
      ),
    );
  }
}
