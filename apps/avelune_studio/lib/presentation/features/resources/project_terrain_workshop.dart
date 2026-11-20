import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import 'library/resource_library_map_usage_links.dart';
import 'project_library_resource_art.dart';

class ProjectTerrainWorkshop extends StatefulWidget {
  const ProjectTerrainWorkshop({
    super.key,
    required this.item,
    required this.previews,
    required this.visuals,
    required this.onBack,
    this.usages,
    this.loadingMapUsages = false,
    this.onOpenMap,
    this.onRename,
  });

  final ProjectLibraryItem item;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;
  final Map<String, String>? usages;
  final bool loadingMapUsages;
  final Future<bool> Function(String)? onOpenMap;
  final Future<void> Function()? onRename;

  @override
  State<ProjectTerrainWorkshop> createState() => _ProjectTerrainWorkshopState();
}

class _ProjectTerrainWorkshopState extends State<ProjectTerrainWorkshop> {
  late ProjectResourcePreviewLease _lease;

  @override
  void initState() {
    super.initState();
    _lease = widget.previews.acquire(widget.item);
  }

  @override
  void didUpdateWidget(ProjectTerrainWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.identity != widget.item.identity ||
        oldWidget.previews != widget.previews) {
      _read();
    }
  }

  void _read() {
    _lease.release();
    _lease = widget.previews.acquire(widget.item);
  }

  void _retry() {
    widget.previews.invalidate([widget.item.identity]);
    setState(_read);
  }

  @override
  void dispose() {
    _lease.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewPanel();
    final usages = widget.usages;
    final maps = StudioPanel(
      title: 'Utilisation dans les cartes',
      icon: Icons.map_outlined,
      children: [
        ResourceLibraryMapUsageLinks(
          key: ValueKey(widget.item.identity),
          mapIds: usages?.keys ?? const [],
          maps: usages ?? const {},
          emptyLabel: switch ((usages, widget.loadingMapUsages)) {
            (null, true) => 'Calcul des usages par carte…',
            (null, false) => 'Usages indisponibles.',
            _ => 'Aucune carte ne l’utilise.',
          },
          onOpenMap: widget.onOpenMap,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StudioSpacing.xl,
            vertical: StudioSpacing.l,
          ),
          child: Wrap(
            spacing: StudioSpacing.l,
            runSpacing: StudioSpacing.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StudioButton(
                label: 'Retour à la bibliothèque',
                icon: Icons.arrow_back,
                onPressed: widget.onBack,
                variant: StudioButtonVariant.quiet,
              ),
              Text('Terrains', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(StudioSpacing.xl),
            children: [
              Wrap(
                spacing: StudioSpacing.l,
                runSpacing: StudioSpacing.m,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.onRename != null)
                    StudioButton(
                      label: 'Renommer',
                      icon: Icons.edit_outlined,
                      variant: StudioButtonVariant.secondary,
                      onPressed: widget.onRename,
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.xl),
              LayoutBuilder(
                builder: (context, bounds) => bounds.maxWidth >= 680
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: preview),
                          const SizedBox(width: StudioSpacing.xl),
                          Expanded(flex: 2, child: maps),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          preview,
                          const SizedBox(height: StudioSpacing.xl),
                          maps,
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewPanel() => StudioPanel(
    title: 'Aperçu du terrain',
    icon: Icons.terrain_outlined,
    children: [
      FutureBuilder<ProjectResourcePreview?>(
        future: _lease.result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: StudioSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement du terrain',
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return StudioEmptyState(
              title: 'Impossible de lire le terrain',
              action: StudioButton(label: 'Réessayer', onPressed: _retry),
            );
          }
          final result = snapshot.data;
          final terrain = result?.item.terrain;
          if (result == null || terrain == null) {
            return const StudioEmptyState(title: 'Terrain introuvable');
          }
          final visuals = widget.visuals;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioBadge(terrainUsageLabel(terrain.usage)),
              const SizedBox(height: StudioSpacing.l),
              if (visuals == null)
                const StudioNotice('Aperçu indisponible.')
              else
                LayoutBuilder(
                  builder: (context, bounds) => Center(
                    child: ProjectLibraryResourceArt(
                      item: result.item,
                      project: result.project,
                      visuals: visuals,
                      size: bounds.constrainWidth(264),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
