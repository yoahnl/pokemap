import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_ui_parts.dart';

class PokemonCommerceReferences extends StatelessWidget {
  const PokemonCommerceReferences({
    super.key,
    required this.commerce,
    required this.items,
    required this.onOpenShop,
    this.onOpenReference,
  });

  final PokemonCommerceController commerce;
  final bool items;
  final void Function(ShopDefinition) onOpenShop;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  Widget build(BuildContext context) {
    final snapshot = commerce.snapshot!;
    if (items) {
      final references = snapshot.references.referencesFor(commerce.item!.id);
      return PokemonSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PokemonSectionHeading(
              title: 'Usages et références · ${references.length}',
              description:
                  'Les liens ci-dessous proviennent de l’index canonique du projet enregistré.',
            ),
            if (references.isEmpty)
              const Text(
                'Aucune référence trouvée dans les données enregistrées.',
              ),
            for (final reference in references)
              ListTile(
                leading: Icon(_icon(reference.kind)),
                title: Text(
                  '${_label(reference.kind)} · ${reference.sourceId}',
                ),
                subtitle: Text(
                  reference.editablePath,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: reference.sourceKind == 'shop'
                    ? StudioButton(
                        label: 'Ouvrir',
                        secondary: true,
                        onPressed: () {
                          final shop = snapshot.shops
                              .where((value) => value.id == reference.sourceId)
                              .firstOrNull;
                          if (shop != null) onOpenShop(shop);
                        },
                      )
                    : (reference.sourceKind == 'scene' ||
                              reference.sourceKind == 'map') &&
                          onOpenReference != null
                    ? StudioButton(
                        label: 'Ouvrir',
                        secondary: true,
                        onPressed: () => onOpenReference!(
                          reference.sourceKind,
                          reference.sourceId,
                        ),
                      )
                    : null,
              ),
            const SizedBox(height: 8),
            const Text(
              'Carte, Histoire et nouvelle partie restent les propriétaires de leurs références.',
            ),
          ],
        ),
      );
    }
    final shop = commerce.shop!;
    final references = snapshot.narrativeReferences.usagesFor(
      NarrativeDependencyKey.synthetic(sourceKind: 'shop', sourceId: shop.id),
    );
    final unresolved = shop.entries
        .where(
          (entry) =>
              snapshot.catalog?.entries.any(
                (item) => item.id == entry.itemId,
              ) !=
              true,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokemonSectionHeading(
                title: 'Raccordements · ${references.length}',
                description:
                    'Scènes et commandes enregistrées qui ouvrent cette boutique.',
              ),
              if (references.isEmpty)
                const Text(
                  'Aucune scène liée trouvée dans les données enregistrées.',
                ),
              for (final reference in references)
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(
                    '${reference.owner.sourceKind ?? reference.owner.kind.name} · ${reference.owner.id}',
                  ),
                  subtitle: Text(reference.path),
                  trailing:
                      reference.owner.kind ==
                              NarrativeDependencyTargetKind.scene &&
                          onOpenReference != null
                      ? StudioButton(
                          label: 'Ouvrir la scène',
                          secondary: true,
                          onPressed: () =>
                              onOpenReference!('scene', reference.owner.id),
                        )
                      : null,
                ),
              const SizedBox(height: 8),
              const Text(
                'La commande d’ouverture se modifie dans Histoire. Les interactions de carte se règlent dans Carte.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokemonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokemonSectionHeading(
                title:
                    'Références d’objets · ${unresolved.length} manquante(s)',
              ),
              if (unresolved.isEmpty)
                const Text(
                  'Toutes les lignes du catalogue de base pointent vers un objet du projet.',
                ),
              for (final entry in unresolved)
                ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(entry.itemId),
                  subtitle: const Text(
                    'Objet non résolu ; référence conservée.',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _label(ProjectItemReferenceKind kind) => switch (kind) {
    ProjectItemReferenceKind.shopEntry => 'Boutique',
    ProjectItemReferenceKind.mapPickup => 'Objet de carte',
    ProjectItemReferenceKind.sceneGive ||
    ProjectItemReferenceKind.sceneTake => 'Scène',
    ProjectItemReferenceKind.trainerReward => 'Récompense',
    _ => kind.name,
  };

  IconData _icon(ProjectItemReferenceKind kind) => switch (kind) {
    ProjectItemReferenceKind.shopEntry => Icons.storefront_outlined,
    ProjectItemReferenceKind.mapPickup => Icons.map_outlined,
    ProjectItemReferenceKind.sceneGive ||
    ProjectItemReferenceKind.sceneTake => Icons.account_tree_outlined,
    _ => Icons.link,
  };
}
