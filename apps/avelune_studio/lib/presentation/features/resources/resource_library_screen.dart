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
import 'resource_category_tree.dart';
import 'resource_detail_panel.dart';
import 'resource_preview.dart';
import 'resource_terrain_draft_list.dart';
import 'resource_terrain_actions.dart';
import 'resource_border_draft_bar.dart';
import 'resource_creation_buttons.dart';
part 'resource_library_layout.dart';
part 'resource_library_header.dart';

class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({
    super.key,
    required this.project,
    required this.visuals,
    required this.state,
    required this.onUse,
    required this.onEdit,
    required this.onTerrain,
    required this.onCreateBorder,
    required this.onResumeBorder,
    this.onManageBorder,
    required this.onImport,
    this.onCharacters,
    required this.onBack,
    this.openMaps = const [],
    this.targetMapName,
    this.canUse = true,
    this.terrainDrafts = const [],
    this.onResumeTerrain,
    this.onManageTerrainDraft,
    this.terrainDraftStatus,
    this.canResumeTerrain,
    this.canEditTerrain,
    this.onInformation,
    this.onMove,
    this.onUsages,
    this.onReplace,
    this.onRemove,
    this.onDuplicate,
    this.onManageContainers,
  });
  final ProjectManifest project;
  final List<MapData> openMaps;
  final MapWorkspaceVisuals visuals;
  final ResourceLibraryState state;
  final ValueChanged<ResourceItem> onUse;
  final ValueChanged<ResourceItem> onEdit;
  final ValueChanged<ResourceItem> onTerrain;
  final VoidCallback onCreateBorder;
  final ValueChanged<BorderBlueprintRecord> onResumeBorder;
  final void Function(BorderBlueprintRecord, BorderResourceAction)?
  onManageBorder;
  final VoidCallback onImport;
  final VoidCallback? onCharacters;
  final VoidCallback onBack;
  final String? targetMapName;
  final bool canUse;
  final List<ProjectSmartTileAuthoringDraft> terrainDrafts;
  final ValueChanged<ProjectSmartTileAuthoringDraft>? onResumeTerrain;
  final void Function(ProjectSmartTileAuthoringDraft, TerrainResourceAction)?
  onManageTerrainDraft;
  final String Function(ProjectSmartTileAuthoringDraft)? terrainDraftStatus;
  final bool Function(ProjectSmartTileAuthoringDraft)? canResumeTerrain;
  final bool Function(ResourceItem)? canEditTerrain;
  final ValueChanged<ResourceItem>? onInformation, onMove, onUsages;
  final ValueChanged<ResourceItem>? onReplace, onRemove, onDuplicate;
  final ValueChanged<ResourceKind>? onManageContainers;
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
  void select(ResourceItem item) => setState(() => state.selectedId = item.id);
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
        onInformation: widget.onInformation == null
            ? null
            : (item) {
                close?.call();
                widget.onInformation?.call(item);
              },
        onMove: widget.onMove == null
            ? null
            : (item) {
                close?.call();
                widget.onMove?.call(item);
              },
        onUsages: widget.onUsages == null
            ? null
            : (item) {
                close?.call();
                widget.onUsages?.call(item);
              },
        onReplace: widget.onReplace == null
            ? null
            : (item) {
                close?.call();
                widget.onReplace?.call(item);
              },
        onRemove: widget.onRemove == null
            ? null
            : (item) {
                close?.call();
                widget.onRemove?.call(item);
              },
        onDuplicate: widget.onDuplicate == null
            ? null
            : (item) {
                close?.call();
                widget.onDuplicate?.call(item);
              },
        canEditTerrain:
            item != null && (widget.canEditTerrain?.call(item) ?? false),
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

  Widget categories(ResourceCategoryTree tree, {VoidCallback? close}) =>
      ResourceCategoryFilter(
        tree: tree,
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
  Widget build(BuildContext context) => buildLibrary(context);
}
