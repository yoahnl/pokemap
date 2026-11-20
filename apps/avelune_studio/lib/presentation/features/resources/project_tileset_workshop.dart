import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import 'library/resource_library_map_usage_links.dart';

class ProjectTilesetWorkshop extends StatefulWidget {
  const ProjectTilesetWorkshop({
    super.key,
    required this.item,
    required this.previews,
    required this.visuals,
    required this.onBack,
    this.usages,
    this.onOpenMap,
  });

  final ProjectLibraryItem item;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;
  final Map<String, String>? usages;
  final Future<bool> Function(String)? onOpenMap;

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
        _sourcePanel(context, source, page, fullImage),
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
        Text(tileset.name, style: Theme.of(context).textTheme.titleLarge),
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

Widget _sourcePanel(
  BuildContext context,
  ProjectTilesetSource? source,
  ProjectImageCollectionPage? page,
  bool fullImage,
) {
  final facts = switch (source) {
    final ProjectRegularAtlasTilesetSource atlas => <(String, String)>[
      if (atlas.pixelWidth > 0 && atlas.pixelHeight > 0)
        ('Dimensions de l’image', _size(atlas.pixelWidth, atlas.pixelHeight)),
      if (!fullImage && atlas.tileCount > 0) ...[
        ('Taille d’une tuile', _size(atlas.tileWidth, atlas.tileHeight)),
        ('Grille', '${atlas.columns} colonnes × ${atlas.rows} lignes'),
        if (atlas.marginX != 0 || atlas.marginY != 0)
          (
            'Marges horizontale et verticale',
            _size(atlas.marginX, atlas.marginY),
          ),
        if (atlas.spacingX != 0 || atlas.spacingY != 0)
          (
            'Espacements horizontal et vertical',
            _size(atlas.spacingX, atlas.spacingY),
          ),
      ],
    ],
    ProjectImageCollectionTilesetSource(:final pages, :final tileDefinitions) =>
      [
        ('Pages', '${pages.length}'),
        if (page != null && page.pixelWidth > 0 && page.pixelHeight > 0)
          ('Dimensions de la page', _size(page.pixelWidth, page.pixelHeight)),
        ('Tuiles de la collection', '${tileDefinitions.length}'),
      ],
    null => const <(String, String)>[],
  };
  final title = switch (source) {
    ProjectRegularAtlasTilesetSource() when fullImage => 'Image entière',
    ProjectRegularAtlasTilesetSource() => 'Planche de tuiles',
    ProjectImageCollectionTilesetSource() => 'Collection d’images',
    null => 'Découpe',
  };
  final texts = Theme.of(context).textTheme;
  return StudioPanel(
    title: title,
    icon: Icons.grid_on_outlined,
    children: [
      if (source == null)
        const Text('Aucune grille enregistrée pour cette image.')
      else if (source is ProjectRegularAtlasTilesetSource &&
          source.tileCount == 0)
        const StudioNotice('La grille enregistrée est inexploitable.'),
      for (final (label, value) in facts)
        Padding(
          padding: const EdgeInsets.only(bottom: StudioSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: texts.bodySmall),
              Text(value, style: texts.titleSmall),
            ],
          ),
        ),
    ],
  );
}

String _size(int width, int height) => '$width × $height px';
