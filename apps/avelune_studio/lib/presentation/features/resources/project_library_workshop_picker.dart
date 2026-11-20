part of 'project_library_page.dart';

enum _ProjectWorkshopKind {
  models(
    'model3d',
    'Modèles 3D',
    'Atelier 3D',
    'Chercher un modèle 3D',
    Icons.view_in_ar_outlined,
  ),
  tilesets(
    'tileset',
    'Images et tuiles',
    'Atelier Images et tuiles',
    'Chercher une image ou une planche',
    Icons.image_outlined,
  ),
  borders(
    'borderBlueprint',
    'Bordures et parois',
    'Atelier Bordures',
    'Chercher une bordure',
    Icons.fence_outlined,
  ),
  characters(
    'character',
    'Personnages',
    'Atelier Personnages',
    'Chercher un personnage',
    Icons.person_outline,
  ),
  terrains(
    'smartTilePreset',
    'Terrains',
    'Atelier Terrains',
    'Chercher un terrain ou un chemin',
    Icons.terrain_outlined,
  );

  const _ProjectWorkshopKind(
    this.resourceKind,
    this.title,
    this.actionLabel,
    this.searchLabel,
    this.icon,
  );

  final String resourceKind, title, actionLabel, searchLabel;
  final IconData icon;
}

class _ProjectWorkshopPicker extends StatefulWidget {
  const _ProjectWorkshopPicker({
    super.key,
    required this.catalog,
    required this.workshop,
    required this.onWorkshop,
    required this.onSelected,
  });

  final ProjectLibraryCatalogView catalog;
  final _ProjectWorkshopKind workshop;
  final ValueChanged<_ProjectWorkshopKind> onWorkshop;
  final ValueChanged<String> onSelected;

  @override
  State<_ProjectWorkshopPicker> createState() => _ProjectWorkshopPickerState();
}

class _ProjectWorkshopPickerState extends State<_ProjectWorkshopPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = studioSearchText(_search.text).trim();
    final workshop = widget.workshop;
    final resources = [
      for (final item in widget.catalog.entries.values)
        if (item.kind == workshop.resourceKind &&
            item.searchText.contains(query))
          item,
    ];
    return Padding(
      padding: const EdgeInsets.all(StudioSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ateliers', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: StudioSpacing.xl),
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              for (final option in _ProjectWorkshopKind.values)
                Semantics(
                  selected: option == workshop,
                  child: StudioButton(
                    label: option.title,
                    icon: option.icon,
                    variant: option == workshop
                        ? StudioButtonVariant.secondary
                        : StudioButtonVariant.quiet,
                    onPressed: () => widget.onWorkshop(option),
                  ),
                ),
            ],
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSearchField(
            key: ValueKey('library-workshop-search-${workshop.resourceKind}'),
            label: workshop.searchLabel,
            controller: _search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: StudioSpacing.l),
          Expanded(
            child: resources.isEmpty
                ? StudioEmptyState(
                    title: query.isEmpty
                        ? 'Aucune ressource dans cet atelier'
                        : 'Aucune ressource trouvée',
                    description: query.isEmpty
                        ? 'Les ressources de ce type apparaissent ici.'
                        : 'Essayez une autre recherche.',
                  )
                : ListView.builder(
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      final entry = resources[index];
                      return StudioChoice(
                        key: ValueKey('library-workshop-${entry.identity}'),
                        label: entry.name,
                        dense: true,
                        leading: Icon(workshop.icon),
                        onTap: () => widget.onSelected(entry.identity),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
