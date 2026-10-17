import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_pack_transfer_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_filter_tag.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ResourcePackSelection extends StatefulWidget {
  const ResourcePackSelection({super.key, required this.controller});
  final ResourcePackTransferController controller;
  @override
  State<ResourcePackSelection> createState() => _ResourcePackSelectionState();
}

class _ResourcePackSelectionState extends State<ResourcePackSelection> {
  late final search = TextEditingController(text: widget.controller.search);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final enabled = !c.operationActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioSearchField(
          controller: search,
          onChanged: (value) => c.setFilter(search: value),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Contexte',
          value: c.context,
          options: resourcePackContextLabels,
          onChanged: enabled ? (value) => c.setFilter(context: value) : null,
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Type de ressource',
          value: c.kind ?? '',
          options: const {
            '': 'Tous les types',
            'tileset': 'Images',
            'element': 'Décors',
            'model3d': 'Modèles 3D',
            'character': 'Personnages',
            'environmentPreset': 'Environnements',
            'smartTilePreset': 'Terrains',
            'smartTilePattern': 'Motifs de terrain',
            'borderBlueprint': 'Bordures',
          },
          onChanged: enabled ? (value) => c.setFilter(kind: value) : null,
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Famille',
          value: c.familyId ?? '',
          options: {
            '': 'Toutes les familles',
            '__unclassified__': 'Sans famille',
            for (final row in c.families)
              row['id']! as String:
                  '${row['label']}${row['labelComplete'] == false ? '… (nom abrégé)' : ''}',
            if (c.familyId != null &&
                !c.families.any((row) => row['id'] == c.familyId))
              c.familyId!: c.selectedFamilyLabel ?? 'Famille choisie',
          },
          onChanged: enabled ? (value) => c.setFilter(familyId: value) : null,
        ),
        if (c.familyCount > c.families.length)
          Wrap(
            spacing: 8,
            children: [
              StudioButton(
                label: 'Premières familles',
                secondary: true,
                onPressed: enabled ? c.firstFamilyPage : null,
              ),
              if (c.familyCursor != null)
                StudioButton(
                  label: 'Autres familles',
                  secondary: true,
                  onPressed: enabled ? c.nextFamilyPage : null,
                ),
            ],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (c.context != 'all')
              StudioFilterTag(
                label: 'Contexte : ${resourcePackContextLabels[c.context]}',
                onRemove: () => c.setFilter(context: 'all'),
              ),
            StudioBadge('${c.selectedCount} sélectionnées au total'),
            StudioBadge('${c.visibleCount} résultats visibles'),
            StudioButton(
              key: const ValueKey('resource-pack-select-filtered'),
              label: 'Sélectionner tous les résultats',
              secondary: true,
              onPressed: enabled ? c.selectFiltered : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          compact: true,
          children: [
            SizedBox(
              height: 200,
              child: ListView.builder(
                key: const ValueKey('resource-pack-entry-list'),
                itemCount: c.entries.length,
                itemBuilder: (context, index) {
                  final entry = c.entries[index];
                  return StudioToggleRow(
                    key: ValueKey(
                      'resource-pack-entry-${entry['kind']}:${entry['id']}',
                    ),
                    label: '${entry['label'] ?? entry['id']}',
                    description: resourcePackKindLabel(entry['kind']),
                    value: entry['selected'] == true,
                    onChanged: enabled ? (_) => c.toggle(entry) : null,
                  );
                },
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            StudioButton(
              label: 'Première page',
              secondary: true,
              onPressed: enabled ? c.firstPage : null,
            ),
            StudioButton(
              key: const ValueKey('resource-pack-next-page'),
              label: 'Page suivante',
              secondary: true,
              onPressed: enabled && c.nextCursor != null ? c.nextPage : null,
            ),
          ],
        ),
        const Text(
          'Les dépendances nécessaires sont incluses automatiquement. Les ressources sélectionnées restent conservées lorsque les filtres les masquent.',
        ),
      ],
    );
  }
}

String resourcePackKindLabel(Object? kind) => switch (kind) {
  'tileset' => 'Image',
  'element' => 'Décor',
  'model3d' => 'Modèle 3D',
  'character' => 'Personnage',
  'environmentPreset' => 'Environnement',
  'smartTilePreset' => 'Terrain',
  'smartTilePattern' => 'Motif de terrain',
  'borderBlueprint' => 'Bordure',
  'resourceFamily' => 'Famille de ressources',
  'elementCategory' => 'Catégorie de décors',
  'tilesetFolder' => 'Dossier d’images',
  'tilesetElementGroup' => 'Groupe de planche',
  'smartTileMaterial' => 'Matériau de terrain',
  'smartTileAtlas' => 'Planche de terrain',
  'smartTileAnimation' => 'Animation de terrain',
  'smartTileCategory' => 'Catégorie de terrain',
  'smartTileConnectionGroup' => 'Groupe de raccordement',
  'characterPortraitState' => 'État de portrait',
  'characterAnimationDefinition' => 'Animation de personnage',
  'borderSnapshot' => 'Publication de bordure',
  'file' => 'Source graphique',
  _ => 'Ressource',
};

const resourcePackContextLabels = {
  'all': 'Tous',
  'interior': 'Intérieur',
  'exterior': 'Extérieur',
  'both': 'Les deux',
  'unspecified': 'Non renseigné',
};
