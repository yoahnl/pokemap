import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/project_session/domain/project_session.dart';
import '../../features/resources/domain/working_catalog_port.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import '../../presentation/features/resources/resource_preview.dart';
import '../../presentation/shared/widgets/feedback/studio_notice.dart';
import 'working_catalog_preview_session.dart';

class WorkingCatalogPreview extends StatefulWidget {
  const WorkingCatalogPreview({
    super.key,
    required this.session,
    required this.detail,
  });
  final ProjectSession session;
  final WorkingCatalogDetail detail;

  @override
  State<WorkingCatalogPreview> createState() => _WorkingCatalogPreviewState();
}

class _WorkingCatalogPreviewState extends State<WorkingCatalogPreview> {
  final preview = WorkingCatalogPreviewSession();

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void didUpdateWidget(WorkingCatalogPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
          oldWidget.detail.visualIdentity,
          widget.detail.visualIdentity,
        ) ||
        oldWidget.session != widget.session) {
      unawaited(load());
    }
  }

  Future<void> load() async {
    await preview.load(widget.session, widget.detail);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(preview.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (preview.error != null) {
      return const StudioNotice(
        'Aperçu indisponible. Les informations restent modifiables.',
      );
    }
    final current = preview.resources;
    if (current == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final item = resourceCatalog(widget.detail.definitions)
        .where((item) => item.identity == widget.detail.entry.identity)
        .firstOrNull;
    if (item == null) {
      return const StudioNotice(
        'Cette ressource ne possède pas d’aperçu visuel.',
      );
    }
    return resourcePreview(
      item,
      widget.detail.definitions,
      current,
      size: widget.detail.entry.kind == 'model3d' ? 300 : 170,
      terrainPattern: true,
    );
  }
}
