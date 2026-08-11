import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import 'item_studio_gateway.dart';

enum ItemCatalogCapabilityFilter {
  all,
  overworld,
  battle,
  capture,
  machine,
  held,
}

final class ItemCatalogList extends StatefulWidget {
  const ItemCatalogList({
    super.key,
    required this.definitions,
    required this.readinessByItemId,
    required this.selectedItemId,
    required this.onSelected,
  });

  final List<ProjectItemDefinition> definitions;
  final Map<String, ItemStudioReadiness> readinessByItemId;
  final String? selectedItemId;
  final ValueChanged<String> onSelected;

  @override
  State<ItemCatalogList> createState() => _ItemCatalogListState();
}

final class _ItemCatalogListState extends State<ItemCatalogList> {
  String _search = '';
  ItemCatalogCapabilityFilter _filter = ItemCatalogCapabilityFilter.all;

  @override
  Widget build(BuildContext context) {
    final definitions = widget.definitions.where(_matches).toList();
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: PokeMapSectionHeader(
          title: 'Catalogue',
          description: '${definitions.length} objet(s) affiché(s)',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSearchField(
            key: const Key('item-studio-search-field'),
            hintText: 'Rechercher un objet…',
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<ItemCatalogCapabilityFilter>(
            key: const Key('item-studio-capability-filter'),
            label: 'Capacité',
            value: _filter,
            compact: true,
            items: const <PokeMapDropdownItem<ItemCatalogCapabilityFilter>>[
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.all,
                label: 'Toutes',
              ),
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.overworld,
                label: 'Utilisable dans le monde',
              ),
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.battle,
                label: 'Utilisable en combat',
              ),
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.capture,
                label: 'Capture',
              ),
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.machine,
                label: 'Capsule technique',
              ),
              PokeMapDropdownItem(
                value: ItemCatalogCapabilityFilter.held,
                label: 'Effet tenu',
              ),
            ],
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: definitions.isEmpty
                ? const Center(child: Text('Aucun objet ne correspond.'))
                : ListView.separated(
                    key: const Key('item-studio-catalog-list'),
                    itemCount: definitions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final definition = definitions[index];
                      return _ItemCatalogEntry(
                        definition: definition,
                        readiness: widget.readinessByItemId[definition.id],
                        selected: definition.id == widget.selectedItemId,
                        onTap: () => widget.onSelected(definition.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _matches(ProjectItemDefinition definition) {
    final search = _search.trim().toLowerCase();
    if (search.isNotEmpty) {
      final haystack = <String>[
        definition.displayName,
        definition.pocketId,
        definition.description ?? '',
        ...definition.aliases,
      ].join(' ').toLowerCase();
      if (!haystack.contains(search)) return false;
    }
    return switch (_filter) {
      ItemCatalogCapabilityFilter.all => true,
      ItemCatalogCapabilityFilter.overworld => definition.uses.any(
        (use) => use.contexts.contains(ProjectItemUseContext.overworld),
      ),
      ItemCatalogCapabilityFilter.battle => definition.uses.any(
        (use) => use.contexts.contains(ProjectItemUseContext.battle),
      ),
      ItemCatalogCapabilityFilter.capture => definition.capture != null,
      ItemCatalogCapabilityFilter.machine => definition.machine != null,
      ItemCatalogCapabilityFilter.held => definition.heldEffectId != null,
    };
  }
}

final class _ItemCatalogEntry extends StatelessWidget {
  const _ItemCatalogEntry({
    required this.definition,
    required this.readiness,
    required this.selected,
    required this.onTap,
  });

  final ProjectItemDefinition definition;
  final ItemStudioReadiness? readiness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: Key('item-studio-entry-${definition.id}'),
      selected: selected,
      onTap: onTap,
      semanticLabel: definition.displayName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  definition.displayName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PokeMapBadge(
                label: readiness?.ready == false ? 'À corriger' : 'Prêt',
                variant: readiness?.ready == false
                    ? PokeMapBadgeVariant.warning
                    : PokeMapBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _pocketLabel(definition.pocketId),
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          if (_capabilityLabels(definition) case final labels
              when labels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final label in labels)
                  PokeMapBadge(label: label, variant: PokeMapBadgeVariant.info),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

List<String> _capabilityLabels(ProjectItemDefinition definition) {
  return <String>[
    if (definition.uses.any(
      (use) => use.contexts.contains(ProjectItemUseContext.overworld),
    ))
      'Monde',
    if (definition.uses.any(
      (use) => use.contexts.contains(ProjectItemUseContext.battle),
    ))
      'Combat',
    if (definition.capture != null) 'Capture',
    if (definition.machine != null) 'Capsule',
    if (definition.heldEffectId != null) 'Tenu',
  ];
}

String _pocketLabel(String pocketId) => switch (pocketId) {
  'medicine' => 'Soins',
  'poke-balls' => 'Objets de capture',
  'battle-items' => 'Objets de combat',
  'machines' => 'Capsules techniques',
  'key-items' => 'Objets rares',
  _ => 'Objets',
};
