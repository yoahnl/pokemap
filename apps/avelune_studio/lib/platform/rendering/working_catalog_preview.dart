import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/project_session/domain/project_session.dart';
import '../../features/resources/domain/working_catalog_port.dart';
import '../../presentation/features/resources/resource_catalog.dart';
import '../../presentation/features/resources/resource_preview.dart';
import '../../presentation/shared/widgets/feedback/studio_notice.dart';
import 'studio_map_resources.dart';

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
  StudioMapResources? resources;
  String? error;
  int generation = 0;

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
    final current = ++generation;
    final previous = resources;
    resources = null;
    error = null;
    if (previous != null) await previous.dispose();
    if (!mounted || current != generation) return;
    try {
      final next = await StudioMapResources.load(
        widget.session,
        widget.detail.definitions,
      );
      if (!mounted || current != generation) {
        await next.dispose();
        return;
      }
      setState(() => resources = next);
    } catch (failure) {
      if (mounted && current == generation) setState(() => error = '$failure');
    }
  }

  @override
  void dispose() {
    generation++;
    final previous = resources;
    if (previous != null) unawaited(previous.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const StudioNotice(
        'Aperçu indisponible. Les informations restent modifiables.',
      );
    }
    final current = resources;
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
