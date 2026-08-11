part of 'trainer_library_panel.dart';

class _TrainerRewardEditor extends StatelessWidget {
  const _TrainerRewardEditor({
    required this.createMode,
    required this.moneyController,
    required this.flagsController,
    required this.itemQuantityController,
    required this.references,
    required this.badges,
    required this.selectedItemId,
    required this.itemGrants,
    required this.badgeId,
    required this.fieldAbilityUnlock,
    required this.onSelectItem,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onSelectBadge,
    required this.onSelectFieldAbility,
  });

  final bool createMode;
  final TextEditingController moneyController;
  final TextEditingController flagsController;
  final TextEditingController itemQuantityController;
  final _TrainerReferenceData references;
  final List<BadgeDefinition> badges;
  final String? selectedItemId;
  final List<ProjectTrainerItemGrant> itemGrants;
  final String? badgeId;
  final FieldAbility? fieldAbilityUnlock;
  final ValueChanged<String?> onSelectItem;
  final VoidCallback onAddItem;
  final ValueChanged<String> onRemoveItem;
  final ValueChanged<String?> onSelectBadge;
  final ValueChanged<FieldAbility?> onSelectFieldAbility;

  String get _keyPrefix => createMode
      ? 'trainer-library-create-reward'
      : 'trainer-library-edit-reward';

  @override
  Widget build(BuildContext context) {
    final itemDefinitions = references.itemDefinitions;
    final sortedBadges = badges.toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    return PokeMapCard(
      key: Key('$_keyPrefix-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Récompenses de victoire',
            description:
                'Ces gains sont appliqués une seule fois après une victoire validée.',
          ),
          PokeMapTextField(
            label: 'Argent',
            fieldKey: Key('$_keyPrefix-money-field'),
            controller: moneyController,
            hintText: '0',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          ItemCapabilityPicker(
            fieldKey: Key('$_keyPrefix-item-dropdown'),
            label: 'Objet à ajouter',
            definitions: itemDefinitions,
            requirement: ItemCapabilityRequirement.any,
            value: selectedItemId ?? '',
            enabled: references.isItemCatalogAvailable,
            allowEmpty: true,
            emptyLabel: 'Sélectionner un objet du catalogue',
            onChanged: onSelectItem,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PokeMapTextField(
                  label: 'Quantité',
                  fieldKey: Key('$_keyPrefix-item-quantity-field'),
                  controller: itemQuantityController,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: Key('$_keyPrefix-item-add-button'),
                onPressed:
                    references.isItemCatalogAvailable ? onAddItem : null,
                size: PokeMapButtonSize.medium,
                leading: const Icon(CupertinoIcons.plus, size: 14),
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (!references.isItemCatalogAvailable) ...[
            const SizedBox(height: 6),
            const Text(
              'Le catalogue local des objets est indisponible : aucun ID brut '
              'n’est enregistré silencieusement.',
            ),
          ],
          if (itemGrants.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final grant in itemGrants) ...[
              _TrainerRewardItemGrantRow(
                key: Key('$_keyPrefix-item-${grant.itemId}'),
                grant: grant,
                displayName: _itemDisplayName(
                  itemDefinitions,
                  grant.itemId,
                ),
                onRemove: () => onRemoveItem(grant.itemId),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 4),
          PokeMapTextField(
            label: 'Flags activés après victoire',
            fieldKey: Key('$_keyPrefix-flags-field'),
            controller: flagsController,
            hintText: 'story:trainer_won, chapter:badge_received',
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-badge-dropdown'),
            label: 'Badge optionnel',
            value: badgeId ?? '',
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Aucun badge',
              ),
              for (final badge in sortedBadges)
                PokeMapDropdownItem<String>(
                  value: badge.id,
                  label: badge.label,
                ),
            ],
            onChanged: (value) => onSelectBadge(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-field-ability-dropdown'),
            label: 'Capacité de terrain optionnelle',
            value: fieldAbilityUnlock?.moveId ?? '',
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Aucune capacité',
              ),
              for (final ability in FieldAbility.values)
                PokeMapDropdownItem<String>(
                  value: ability.moveId,
                  label: _fieldAbilityRewardLabel(ability),
                ),
            ],
            onChanged: (value) => onSelectFieldAbility(
              FieldAbility.values
                  .where((ability) => ability.moveId == value)
                  .firstOrNull,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerRewardItemGrantRow extends StatelessWidget {
  const _TrainerRewardItemGrantRow({
    super.key,
    required this.grant,
    required this.displayName,
    required this.onRemove,
  });

  final ProjectTrainerItemGrant grant;
  final String displayName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('$displayName × ${grant.quantity}'),
          ),
          PokeMapButton(
            key: Key('trainer-library-reward-item-remove-${grant.itemId}'),
            onPressed: onRemove,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

String _itemDisplayName(
  List<ProjectItemDefinition> definitions,
  String itemId,
) {
  return definitions
          .where((definition) => definition.id == itemId)
          .map((definition) => definition.displayName)
          .firstOrNull ??
      'Référence indisponible';
}

String _fieldAbilityRewardLabel(FieldAbility ability) => switch (ability) {
      FieldAbility.surf => 'Surf',
      FieldAbility.cut => 'Coupe',
      FieldAbility.strength => 'Force',
      FieldAbility.flash => 'Flash',
      FieldAbility.rockSmash => 'Éclate-Roc',
      FieldAbility.waterfall => 'Cascade',
      FieldAbility.dive => 'Plongée',
    };
