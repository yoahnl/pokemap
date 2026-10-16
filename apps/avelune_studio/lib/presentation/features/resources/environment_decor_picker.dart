part of 'environment_editor_screen.dart';

class _EnvironmentDecorPicker extends StatefulWidget {
  const _EnvironmentDecorPicker({
    required this.project,
    required this.visuals,
    required this.excluded,
    this.activeMapId,
  });
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final Set<String> excluded;
  final String? activeMapId;
  @override
  State<_EnvironmentDecorPicker> createState() =>
      _EnvironmentDecorPickerState();
}

class _EnvironmentDecorPickerState extends State<_EnvironmentDecorPicker> {
  final search = TextEditingController();
  final filters = ResourceCatalogFilterState(showComponents: true);
  List<ResourceItem> get candidates => resourceCatalog(widget.project)
      .where(
        (item) =>
            !widget.excluded.contains(item.identity) &&
            (item.element != null || item.model3d != null),
      )
      .toList();
  List<ResourceItem> visible(ResourceCatalogFilterState state) =>
      filterResourceCatalog(
        widget.project,
        candidates,
        state,
        activeMapId: widget.activeMapId,
        forMapPicker: true,
      );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resources = visible(filters);
    final tree = ResourceFamilyTree(
      widget.project,
      candidates,
      activeMapId: widget.activeMapId,
      forMapPicker: true,
      filters: filters,
    );
    final familyLabel =
        tree.nodes
            .where((node) => node.id == filters.familyId)
            .firstOrNull
            ?.name ??
        (filters.familyId == unclassifiedResourceFamily
            ? 'Sans famille'
            : null);
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      child: SizedBox(
        width: (size.width - 48).clamp(0, 650),
        height: (size.height - 80).clamp(0, 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisir un décor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StudioSearchField(
                controller: search,
                onChanged: (value) => setState(() => filters.query = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    key: const ValueKey('environment-decor-families'),
                    label: familyLabel ?? 'Familles',
                    icon: Icons.folder_outlined,
                    secondary: true,
                    onPressed: () => showWorkspaceCompactPanel(
                      context,
                      title: 'Familles',
                      builder: (context, refresh, close) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: ResourceFamilyTreeView(
                          tree: tree,
                          selectedFamilyId: filters.familyId,
                          compact: true,
                          onChanged: (value) {
                            close();
                            setState(() => filters.familyId = value);
                          },
                        ),
                      ),
                    ),
                  ),
                  ResourceFilterButton(
                    filters: filters,
                    forMapPicker: true,
                    onChanged: () => setState(() {}),
                    countResults: (draft, _) => visible(draft).length,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ResourceFilterTags(
                filters: filters,
                familyLabel: familyLabel,
                forMapPicker: true,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: resources.isEmpty
                    ? const Center(child: Text('Aucun autre décor disponible.'))
                    : ListView.builder(
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          final resource = resources[index];
                          return StudioChoice(
                            key: ValueKey('environment-decor-${resource.id}'),
                            label: resource.name,
                            subtitle: resourceCatalogScopeLabel(
                              widget.project,
                              resource,
                            ),
                            leading: resourcePreview(
                              resource,
                              widget.project,
                              widget.visuals,
                              size: 64,
                            ),
                            onTap: () => Navigator.pop(context, resource),
                          );
                        },
                      ),
              ),
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
