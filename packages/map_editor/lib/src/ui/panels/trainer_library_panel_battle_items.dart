part of 'trainer_library_panel.dart';

void _clearBattleItemControllers(
  Map<String, TextEditingController> controllers,
) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
  controllers.clear();
}

String? _battleItemDraftError(Map<String, TextEditingController> controllers) {
  if (controllers.length > 16)
    return 'Le stock accepte au plus 16 soins distincts.';
  for (final controller in controllers.values) {
    final raw = controller.text;
    final quantity = int.tryParse(raw);
    if (!RegExp(r'^[0-9]+$').hasMatch(raw) ||
        quantity == null ||
        quantity < 1 ||
        quantity > 99) {
      return 'Chaque quantité doit être un entier entre 1 et 99.';
    }
  }
  return null;
}

Map<String, int> _battleItemsFromDraft(
  Map<String, TextEditingController> controllers,
) => {
  for (final entry in controllers.entries)
    entry.key: int.parse(entry.value.text),
};

extension _TrainerBattleItemsRendering on _TrainerLibraryPanelState {
  Widget _buildBattleItemsEditor(
    _TrainerReferenceData references, {
    required bool createMode,
  }) {
    final controllers = createMode
        ? _newBattleItemControllers
        : _editBattleItemControllers;
    final prefix =
        'trainer-library-${createMode ? 'create' : 'edit'}-battle-item';
    final eligible = eligibleTrainerBattleItems(
      references.itemsCatalogView.canonicalCatalog,
    );
    final eligibleById = {for (final item in eligible) item.id: item};
    final draftError = _battleItemDraftError(controllers);
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Soins du dresseur en combat',
            description:
                'Stock consommable renouvelé à chaque combat, indépendant des récompenses de victoire. 16 soins distincts maximum.',
          ),
          PokeMapDropdownField<String>(
            key: Key('$prefix-picker'),
            label: 'Ajouter un soin',
            value: '',
            enabled:
                references.isItemCatalogAvailable && controllers.length < 16,
            items: [
              const PokeMapDropdownItem(
                value: '',
                label: 'Sélectionner un soin du catalogue',
              ),
              for (final item in eligible)
                if (!controllers.containsKey(item.id))
                  PokeMapDropdownItem(value: item.id, label: item.displayName),
            ],
            onChanged: (id) {
              if (id.isEmpty ||
                  controllers.containsKey(id) ||
                  controllers.length >= 16 ||
                  !eligibleById.containsKey(id))
                return;
              setState(() {
                controllers[id] = TextEditingController(text: '1');
              });
            },
          ),
          if (!references.isItemCatalogAvailable)
            const Text(
              'Catalogue des objets indisponible : aucun soin ne peut être ajouté. Un stock existant doit être validé avant enregistrement.',
            ),
          if (references.isItemCatalogAvailable && eligible.isEmpty)
            const Text(
              'Aucun soin consommable de PV ou de statut compatible dans ce catalogue.',
            ),
          for (final entry in controllers.entries) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: PokeMapTextField(
                    label:
                        '${eligibleById[entry.key]?.displayName ?? 'Soin indisponible : ${entry.key}'} — quantité',
                    fieldKey: Key('$prefix-${entry.key}-quantity'),
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                PokeMapButton(
                  key: Key('$prefix-${entry.key}-remove'),
                  variant: PokeMapButtonVariant.ghost,
                  onPressed: () => setState(() {
                    controllers.remove(entry.key)?.dispose();
                  }),
                  child: const Text('Retirer'),
                ),
              ],
            ),
          ],
          if (draftError != null) Text(draftError),
        ],
      ),
    );
  }
}
