import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../../../features/resources/domain/project_tileset_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'library/resource_library_map_usage_links.dart';
import 'project_tileset_grid_dialog.dart';

part 'project_tileset_workshop_details.dart';

class ProjectTilesetWorkshop extends StatefulWidget {
  const ProjectTilesetWorkshop({
    super.key,
    required this.item,
    required this.previews,
    required this.visuals,
    required this.onBack,
    this.usages,
    this.onOpenMap,
    this.gridEditor,
  });

  final ProjectLibraryItem item;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;
  final Map<String, String>? usages;
  final Future<bool> Function(String)? onOpenMap;
  final ProjectTilesetGridEditor? gridEditor;

  @override
  State<ProjectTilesetWorkshop> createState() => _ProjectTilesetWorkshopState();
}

class _ProjectTilesetWorkshopState extends State<ProjectTilesetWorkshop> {
  late ProjectResourcePreviewLease _lease;
  bool _showGrid = true;
  String? _pageId;

  @override
  void initState() {
    super.initState();
    _lease = widget.previews.acquire(widget.item);
  }

  @override
  void didUpdateWidget(ProjectTilesetWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.identity != widget.item.identity) {
      _showGrid = true;
      _pageId = null;
    }
    if (oldWidget.item.identity != widget.item.identity ||
        oldWidget.previews != widget.previews) {
      _read();
    }
  }

  void _read() {
    _lease.release();
    _lease = widget.previews.acquire(widget.item);
  }

  @override
  void dispose() {
    _lease.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.xl,
          StudioSpacing.l,
          StudioSpacing.xl,
          StudioSpacing.l,
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
            Text(
              'Images et tuiles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: FutureBuilder<ProjectResourcePreview?>(
          future: _lease.result,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement de la planche',
                ),
              );
            }
            if (snapshot.hasError) {
              return StudioEmptyState(
                title: 'Impossible de lire la planche',
                action: StudioButton(
                  label: 'Réessayer',
                  onPressed: () => setState(_read),
                ),
              );
            }
            final result = snapshot.data;
            final tileset = result?.item.tileset;
            if (result == null || tileset == null) {
              return const StudioEmptyState(title: 'Planche introuvable');
            }
            return _planche(context, tileset, result.project);
          },
        ),
      ),
    ],
  );

  Widget _planche(
    BuildContext context,
    ProjectTilesetEntry tileset,
    ProjectManifest project,
  ) {
    final source = tileset.source;
    final regular = source is ProjectRegularAtlasTilesetSource ? source : null;
    final collection = source is ProjectImageCollectionTilesetSource
        ? source
        : null;
    final pages = collection?.pages ?? const <ProjectImageCollectionPage>[];
    final page =
        pages.where((page) => page.id == _pageId).firstOrNull ??
        pages.firstOrNull;
    final fullImage =
        regular != null &&
        regular.pixelWidth == regular.tileWidth &&
        regular.pixelHeight == regular.tileHeight &&
        regular.marginX == 0 &&
        regular.marginY == 0 &&
        regular.pixelWidth > 0 &&
        regular.pixelHeight > 0;
    final hasGrid = !fullImage && regular != null && regular.tileCount > 0;
    final visual = _previewPanel(
      tileset,
      project,
      pages: pages,
      page: page,
      gridAvailable: hasGrid && widget.visuals is ScopedResourcePreviewVisuals,
    );
    final usages = widget.usages;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sourcePanel(
          context,
          source,
          page,
          fullImage,
          onEdit: regular == null || widget.gridEditor == null
              ? null
              : () => _editGrid(tileset, regular, project),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioPanel(
          title: 'Utilisation dans les cartes',
          icon: Icons.map_outlined,
          children: [
            ResourceLibraryMapUsageLinks(
              mapIds: usages?.keys ?? const [],
              maps: usages ?? const {},
              emptyLabel: usages == null
                  ? 'Usages indisponibles.'
                  : 'Aucune carte ne l’utilise.',
              onOpenMap: widget.onOpenMap,
            ),
          ],
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: StudioSpacing.xl),
        LayoutBuilder(
          builder: (context, bounds) => bounds.maxWidth >= 680
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: visual),
                    const SizedBox(width: StudioSpacing.xl),
                    Expanded(flex: 2, child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    visual,
                    const SizedBox(height: StudioSpacing.xl),
                    details,
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _editGrid(
    ProjectTilesetEntry tileset,
    ProjectRegularAtlasTilesetSource source,
    ProjectManifest project,
  ) async {
    final editor = widget.gridEditor!;
    final item = widget.item;
    final previews = widget.previews;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectTilesetGridDialog(
        name: item.name,
        tileset: tileset,
        source: source,
        editor: (
          revision: editor.revision,
          save: editor.save,
          reconcile: editor.reconcile,
          pendingReceipt: editor.pendingReceipt,
          onPendingReceiptChanged: editor.onPendingReceiptChanged,
          prepareCatalog: () async {
            final revision = await editor.prepareCatalog();
            previews.invalidate([item.identity]);
            final lease = previews.acquire(item);
            try {
              final current = await lease.result;
              if (current?.item.tileset?.source != source) {
                throw const ResourceFailure(
                  'La planche a changé. Rouvrez-la avant de reprendre ce découpage.',
                );
              }
              return revision;
            } finally {
              lease.release();
            }
          },
        ),
        buildPreview: (candidate) => _preview(
          AtlasPreviewSource(
            tileset.id,
            showGrid: true,
            gridOverride: candidate,
          ),
          project,
        ),
      ),
    );
    if (!mounted || saved != true || widget.item.identity != item.identity) {
      return;
    }
    setState(() {
      widget.previews.invalidate([item.identity]);
      _read();
    });
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Découpage enregistré.')));
  }

  Widget _previewPanel(
    ProjectTilesetEntry tileset,
    ProjectManifest project, {
    required List<ProjectImageCollectionPage> pages,
    required ProjectImageCollectionPage? page,
    required bool gridAvailable,
  }) => StudioPanel(
    title: 'Aperçu de la planche',
    icon: Icons.image_outlined,
    children: [
      if (pages.length > 1) ...[
        StudioSelect(
          label: 'Page de la collection',
          value: page?.id,
          options: {
            for (var index = 0; index < pages.length; index++)
              pages[index].id: 'Page ${index + 1}',
          },
          onChanged: (id) => setState(() => _pageId = id),
        ),
        const SizedBox(height: StudioSpacing.l),
      ],
      SizedBox(
        width: double.infinity,
        height: 264,
        child: Semantics(
          label: 'Image de la planche',
          child: _preview(
            AtlasPreviewSource(
              tileset.id,
              pageId: page?.id,
              showGrid: gridAvailable && _showGrid,
            ),
            project,
          ),
        ),
      ),
      if (gridAvailable)
        StudioToggleRow(
          label: 'Afficher la grille',
          value: _showGrid,
          onChanged: (enabled) => setState(() => _showGrid = enabled),
        ),
    ],
  );

  Widget _preview(AtlasPreviewSource source, ProjectManifest project) {
    final visuals = widget.visuals;
    if (visuals is ScopedResourcePreviewVisuals) {
      return (visuals as ScopedResourcePreviewVisuals).scopedResourcePreview(
        source,
        project,
        size: 264,
      );
    }
    if (visuals is ResourceWorkspaceVisuals && source.pageId == null) {
      return (visuals as ResourceWorkspaceVisuals).atlasPreview(
        source.tilesetId,
      );
    }
    return const StudioEmptyState(
      title: 'Aperçu indisponible',
      icon: Icons.image_not_supported_outlined,
    );
  }
}
