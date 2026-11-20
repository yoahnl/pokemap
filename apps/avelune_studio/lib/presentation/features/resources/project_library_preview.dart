import 'package:flutter/material.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import 'project_library_resource_art.dart';

class ProjectLibraryPreview extends StatefulWidget {
  const ProjectLibraryPreview({
    super.key,
    required this.entry,
    required this.previews,
    required this.visuals,
    required this.compact,
  });

  final ProjectLibraryItem entry;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals visuals;
  final bool compact;

  @override
  State<ProjectLibraryPreview> createState() => _ProjectLibraryPreviewState();
}

class _ProjectLibraryPreviewState extends State<ProjectLibraryPreview> {
  late var _lease = widget.previews.acquire(widget.entry);

  @override
  void didUpdateWidget(ProjectLibraryPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.identity != widget.entry.identity ||
        oldWidget.previews != widget.previews) {
      _lease.release();
      _lease = widget.previews.acquire(widget.entry);
    }
  }

  @override
  void dispose() {
    _lease.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _lease.result,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: SizedBox.square(
            dimension: 16,
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
      return ProjectLibraryResourceArt(
        item: result.item,
        project: result.project,
        visuals: widget.visuals,
        size: widget.compact ? 112 : 200,
        compact: widget.compact,
      );
    },
  );
}
