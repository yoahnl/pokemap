import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../map_workspace/workspace_compact_panel.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'resource_catalog.dart';
import 'resource_catalog_toolbar.dart';
import 'resource_catalog_view.dart';
import 'resource_category_filter.dart';
import 'resource_detail_panel.dart';
import 'resource_preview.dart';

class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({
    super.key,
    required this.project,
    required this.visuals,
    required this.state,
    required this.onUse,
    required this.onEdit,
    required this.onTerrain,
    required this.onImport,
    required this.onBack,
    this.openMaps = const [],
    this.targetMapName,
    this.canUse = true,
  });
  final ProjectManifest project;
  final List<MapData> openMaps;
  final MapWorkspaceVisuals visuals;
  final ResourceLibraryState state;
  final ValueChanged<ResourceItem> onUse;
  final ValueChanged<ResourceItem> onEdit;
  final ValueChanged<ResourceItem> onTerrain;
  final VoidCallback onImport;
  final VoidCallback onBack;
  final String? targetMapName;
  final bool canUse;
  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  late final search = TextEditingController(text: widget.state.query);
  late final scroll = ScrollController(
    initialScrollOffset: widget.state.offset,
  );
  List<ResourceItem> items = [];
  ResourceLibraryState get state => widget.state;

  @override
  void initState() {
    super.initState();
    items = resourceCatalog(widget.project);
    scroll.addListener(remember);
  }

  void remember() => state.offset = scroll.offset;

  @override
  void didUpdateWidget(ResourceLibraryScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.project, widget.project)) {
      items = resourceCatalog(widget.project);
    }
    if (search.text != state.query) search.text = state.query;
  }

  void change(VoidCallback update) {
    setState(update);
    state.offset = 0;
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  void dispose() {
    scroll.removeListener(remember);
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  Widget detail(ResourceItem? item, {VoidCallback? close}) =>
      ResourceDetailPanel(
        item: item,
        project: widget.project,
        openUsage: item == null
            ? 0
            : resourceOpenMapUsage(item, widget.openMaps),
        preview: item == null
            ? const SizedBox()
            : resourcePreview(
                item,
                widget.project,
                widget.visuals,
                size: 280,
                terrainPattern: true,
              ),
        targetMapName: widget.targetMapName,
        canUse: widget.canUse && widget.project.maps.isNotEmpty,
        onUse: (item) {
          close?.call();
          widget.onUse(item);
        },
        onEdit: (item) {
          close?.call();
          widget.onEdit(item);
        },
        onTerrain: (item) {
          close?.call();
          widget.onTerrain(item);
        },
      );

  Widget categories(Map<String, String> values, {VoidCallback? close}) =>
      ResourceCategoryFilter(
        categories: values,
        items: items,
        kind: state.kind,
        selected: state.category,
        onChanged: (value) {
          change(() => state.category = value);
          close?.call();
        },
      );

  void showDetail(ResourceItem item) => showWorkspaceCompactPanel(
    context,
    title: 'Détail de la ressource',
    closeLabel: 'Retour aux ressources',
    builder: (context, refresh, close) => detail(item, close: close),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = state.visibleItems(items);
    final selected = state.reconcileSelection(filtered);
    final values = resourceCategories(widget.project, state.kind, items: items);
    final hasCategories = values.keys.any((value) => value.isNotEmpty);
    return LayoutBuilder(
      builder: (context, bounds) {
        final inlineDetail =
            bounds.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final inlineCategories = bounds.maxWidth >= 1200 && hasCategories;
        if (state.revealPending) {
          state.revealPending = false;
          if (!inlineDetail && selected != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showDetail(selected);
            });
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioPageHeader(
              title: 'Ressources',
              alignActionsToEnd: true,
              description: bounds.maxHeight < 650
                  ? null
                  : 'Vos décors, terrains et images, prêts à donner vie à la carte.',
              actions: [
                StudioButton(
                  label: widget.targetMapName == null
                      ? 'Retour à la carte'
                      : 'Carte : ${widget.targetMapName}',
                  icon: Icons.arrow_back,
                  secondary: true,
                  onPressed: widget.onBack,
                ),
                StudioButton(
                  label: 'Importer une image',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: widget.onImport,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StudioTabs<ResourceKind>(
                items: const {
                  ResourceKind.decors: 'Décors',
                  ResourceKind.terrains: 'Terrains',
                  ResourceKind.images: 'Images et tuiles',
                },
                selected: state.kind,
                onChanged: (kind) => change(() {
                  state.kind = kind;
                  state.category = '';
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: ResourceCatalogToolbar(
                search: search,
                state: state,
                count: filtered.length,
                onSearch: (value) => change(() => state.query = value),
                onSort: (value) => change(() => state.sort = value),
                onGrid: (value) => change(() => state.grid = value),
                onFilters: hasCategories && !inlineCategories
                    ? () => showWorkspaceCompactPanel(
                        context,
                        title: 'Catégories',
                        closeLabel: 'Retour aux ressources',
                        builder: (context, refresh, close) =>
                            categories(values, close: close),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (inlineCategories) ...[
                      SizedBox(width: 180, child: categories(values)),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: ResourceCatalogView(
                        items: filtered,
                        selected: selected,
                        project: widget.project,
                        visuals: widget.visuals,
                        scroll: scroll,
                        grid: state.grid,
                        catalogEmpty: !items.any(
                          (item) => item.kind == state.kind,
                        ),
                        onSelect: (item) {
                          setState(() => state.selectedId = item.id);
                          if (!inlineDetail) {
                            showDetail(item);
                          }
                        },
                      ),
                    ),
                    if (inlineDetail) ...[
                      const SizedBox(width: 14),
                      SizedBox(
                        width: bounds.maxWidth >= 1250 ? 340 : 320,
                        child: detail(selected),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
