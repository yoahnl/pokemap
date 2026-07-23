import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

final class ShopStateSettingsDraft {
  const ShopStateSettingsDraft({
    required this.label,
    required this.priority,
    required this.isOpen,
    required this.storefrontLabel,
    required this.welcomeMessage,
    required this.closedMessage,
  });

  final String label;
  final int priority;
  final bool isOpen;
  final String storefrontLabel;
  final String welcomeMessage;
  final String closedMessage;
}

class ShopStateInspector extends StatefulWidget {
  const ShopStateInspector({
    super.key,
    required this.shop,
    required this.state,
    required this.onRenameShop,
    required this.onSaveState,
  });

  final ShopDefinition shop;
  final ShopStateDefinition? state;
  final ValueChanged<String> onRenameShop;
  final ValueChanged<ShopStateSettingsDraft>? onSaveState;

  @override
  State<ShopStateInspector> createState() => _ShopStateInspectorState();
}

class _ShopStateInspectorState extends State<ShopStateInspector> {
  final _shopLabelController = TextEditingController();
  final _stateLabelController = TextEditingController();
  final _priorityController = TextEditingController();
  final _storefrontController = TextEditingController();
  final _welcomeController = TextEditingController();
  final _closedController = TextEditingController();
  bool _isOpen = true;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ShopStateInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id ||
        oldWidget.shop.label != widget.shop.label ||
        oldWidget.state != widget.state) {
      _sync();
    }
  }

  @override
  void dispose() {
    _shopLabelController.dispose();
    _stateLabelController.dispose();
    _priorityController.dispose();
    _storefrontController.dispose();
    _welcomeController.dispose();
    _closedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return PokeMapPanel(
      key: const Key('shop-state-inspector'),
      expandChild: true,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: PokeMapSectionHeader(
          title: 'Inspecteur',
          description: 'Comportement et messages',
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          PokeMapTextField(
            label: 'Nom de la boutique',
            fieldKey: const Key('shop-rename-field'),
            controller: _shopLabelController,
            onSubmitted: widget.onRenameShop,
          ),
          const SizedBox(height: 12),
          if (state == null)
            const PokeMapEmptyState(
              title: 'État par défaut',
              description:
                  'Toujours disponible. Son catalogue sert de base aux nouveaux états.',
              icon: Icon(CupertinoIcons.checkmark_circle),
            )
          else ...[
            PokeMapSectionHeader(
              title: state.label,
              description: 'Configuration de l’état conditionnel',
              trailing: PokeMapBadge(
                label: 'Priorité ${state.priority}',
                variant: PokeMapBadgeVariant.narrative,
              ),
            ),
            const SizedBox(height: 10),
            PokeMapTextField(
              label: 'Nom de l’état',
              fieldKey: const Key('shop-state-label-field'),
              controller: _stateLabelController,
            ),
            const SizedBox(height: 8),
            PokeMapTextField(
              label: 'Priorité',
              fieldKey: const Key('shop-state-priority-field'),
              controller: _priorityController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            PokeMapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Condition d’activation',
                    style: TextStyle(
                      color: context.pokeMapColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  PokeMapBadge(
                    label: _conditionLabel(state.activation.type),
                    variant: PokeMapBadgeVariant.info,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'La condition est conservée sans exposer son identifiant '
                    'technique. Les pickers guidés arrivent avec la validation '
                    'et la simulation du prochain lot.',
                    style: TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            PokeMapToggleTile(
              label: 'Boutique ouverte',
              description: _isOpen
                  ? 'Le joueur peut acheter les objets de cet état.'
                  : 'Le message de fermeture est affiché.',
              value: _isOpen,
              onChanged: (value) => setState(() => _isOpen = value),
            ),
            const SizedBox(height: 8),
            PokeMapTextField(
              label: 'Nom de devanture (facultatif)',
              controller: _storefrontController,
            ),
            const SizedBox(height: 8),
            PokeMapTextField(
              label: 'Message d’accueil',
              controller: _welcomeController,
            ),
            const SizedBox(height: 8),
            PokeMapTextField(
              label: 'Message de fermeture',
              controller: _closedController,
            ),
            const SizedBox(height: 10),
            PokeMapButton(
              key: const Key('shop-state-settings-save'),
              onPressed: _save,
              leading: const Icon(CupertinoIcons.floppy_disk),
              child: const Text('Enregistrer l’état'),
            ),
          ],
        ],
      ),
    );
  }

  void _sync() {
    _shopLabelController.text = widget.shop.label;
    final state = widget.state;
    if (state == null) return;
    _stateLabelController.text = state.label;
    _priorityController.text = '${state.priority}';
    _storefrontController.text = state.storefrontLabel ?? '';
    _welcomeController.text = state.welcomeMessage;
    _closedController.text = state.closedMessage;
    _isOpen = state.isOpen;
  }

  void _save() {
    final callback = widget.onSaveState;
    if (callback == null) return;
    callback(
      ShopStateSettingsDraft(
        label: _stateLabelController.text,
        priority: int.tryParse(_priorityController.text.trim()) ?? 0,
        isOpen: _isOpen,
        storefrontLabel: _storefrontController.text,
        welcomeMessage: _welcomeController.text,
        closedMessage: _closedController.text,
      ),
    );
  }
}

String _conditionLabel(ScriptConditionType type) => switch (type) {
      ScriptConditionType.allOf => 'Toutes les conditions',
      ScriptConditionType.anyOf => 'Au moins une condition',
      ScriptConditionType.not => 'Condition inversée',
      ScriptConditionType.flagIsSet => 'Flag actif',
      ScriptConditionType.flagIsUnset => 'Flag inactif',
      ScriptConditionType.factEquals => 'Fact égal à une valeur',
      ScriptConditionType.stepCompleted => 'Étape terminée',
      ScriptConditionType.badgeOwned => 'Badge obtenu',
      ScriptConditionType.itemQuantityAtLeast => 'Quantité d’objet',
      ScriptConditionType.moneyAtLeast => 'Argent minimum',
      ScriptConditionType.variableEquals => 'Variable égale',
      ScriptConditionType.variableGreaterThan => 'Variable supérieure',
      ScriptConditionType.variableLessThan => 'Variable inférieure',
      ScriptConditionType.fieldAbilityUnlocked => 'Capacité de terrain',
      ScriptConditionType.partyHasMove => 'Capacité dans l’équipe',
      ScriptConditionType.partyHasUsableMove => 'Capacité utilisable',
      ScriptConditionType.eventIsConsumed => 'Événement consommé',
      ScriptConditionType.playerOnMap => 'Présence sur une map',
    };
