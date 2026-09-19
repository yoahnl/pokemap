import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import 'resource_catalog.dart';
import 'resource_detail_panel.dart';
import 'resource_preview.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_resource_grid.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';

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
  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  late final search = TextEditingController(text: widget.state.query);
  late final scroll = ScrollController(
    initialScrollOffset: widget.state.offset,
  );
  List<ResourceItem> items = [];
  List<ResourceItem> filtered = [];
  ResourceLibraryState get state => widget.state;
  @override
  void initState() {
    super.initState();
    refresh();
    scroll.addListener(remember);
  }

  void remember() => state.offset = scroll.offset;
  @override
  void didUpdateWidget(ResourceLibraryScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.project, widget.project)) refresh();
  }

  void refresh() {
    items = resourceCatalog(widget.project);
    filter();
  }

  void filter() {
    filtered = items
        .where(
          (e) =>
              e.kind == state.kind &&
              (state.category.isEmpty || e.category == state.category) &&
              ('${e.name} ${e.tags.join(' ')}').toLowerCase().contains(
                state.query.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    scroll.removeListener(remember);
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  Widget preview(ResourceItem item, {double size = 80}) =>
      resourcePreview(item, widget.project, widget.visuals, size: size);

  @override
  Widget build(BuildContext context) {
    final selected = items
        .where((e) => e.id == state.selectedId && e.kind == state.kind)
        .firstOrNull;
    final categories = state.kind == ResourceKind.decors
        ? {for (final e in widget.project.elementCategories) e.id: e.name}
        : state.kind == ResourceKind.images
        ? {for (final e in widget.project.tilesetFolders) e.id: e.name}
        : <String, String>{};
    return Column(
      children: [
        StudioPageHeader(
          title: 'Ressources',
          description:
              'Vos décors, terrains et images, prêts à donner vie à la carte.',
          actions: [
            StudioButton(
              label: 'Retour à la carte',
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioTabs<ResourceKind>(
                items: const {
                  ResourceKind.decors: 'Décors',
                  ResourceKind.terrains: 'Terrains',
                  ResourceKind.images: 'Images et tuiles',
                },
                selected: state.kind,
                onChanged: (kind) => setState(() {
                  state.kind = kind;
                  state.category = '';
                  state.offset = 0;
                  filter();
                  if (scroll.hasClients) scroll.jumpTo(0);
                }),
              ),
              StudioButton(
                label: state.grid ? 'Mode liste' : 'Mode grille',
                secondary: true,
                onPressed: () => setState(() => state.grid = !state.grid),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: StudioSearchField(
                  controller: search,
                  label: 'Rechercher une ressource',
                  onChanged: (v) => setState(() {
                    state.query = v;
                    filter();
                  }),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(state.kind),
                    initialValue: state.category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Toutes')),
                      for (final c in categories.entries)
                        DropdownMenuItem(
                          value: c.key,
                          child: Text(c.value, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      state.category = v ?? '';
                      filter();
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final details = ResourceDetailPanel(
                item: selected,
                openUsage: selected == null
                    ? 0
                    : resourceOpenMapUsage(selected, widget.openMaps),
                project: widget.project,
                preview: selected == null
                    ? const SizedBox()
                    : preview(selected, size: 150),
                onUse: widget.onUse,
                onEdit: widget.onEdit,
                onTerrain: widget.onTerrain,
              );
              final grid = filtered.isEmpty
                  ? const StudioEmptyState(
                      title: 'Aucune ressource correspondante.',
                      description: 'Changez les filtres ou importez une image.',
                    )
                  : state.grid
                  ? StudioResourceGrid(
                      controller: scroll,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return StudioResourceCard(
                          name: item.name,
                          preview: preview(item, size: 132),
                          category: switch (item.kind) {
                            ResourceKind.decors => 'Décor',
                            ResourceKind.terrains => 'Terrain automatique',
                            ResourceKind.images => 'Image et tuiles',
                          },
                          metadata: item.tags.isEmpty
                              ? null
                              : item.tags.join(' · '),
                          selected: selected == item,
                          onTap: () =>
                              setState(() => state.selectedId = item.id),
                        );
                      },
                    )
                  : ListView.builder(
                      controller: scroll,
                      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return StudioChoice(
                          label: item.name,
                          leading: preview(item, size: 48),
                          selected: selected == item,
                          onTap: () =>
                              setState(() => state.selectedId = item.id),
                        );
                      },
                    );
              if (c.maxWidth < 720 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21) {
                return Column(
                  children: [
                    Expanded(child: grid),
                    SizedBox(height: 190, child: details),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: grid),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 290, child: details),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
