import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_combat_list.dart';
import 'pokemon_combat_table_detail.dart';
import 'pokemon_combat_trainer_detail.dart';
import 'pokemon_combat_references.dart';
import 'pokemon_combat_context_panel.dart';
import 'pokemon_ui_parts.dart';

class PokemonCombatPage extends StatefulWidget {
  const PokemonCombatPage({
    super.key,
    required this.combat,
    required this.index,
    this.onOpenReference,
  });

  final PokemonCombatController combat;
  final PokemonWorkspaceIndex index;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  State<PokemonCombatPage> createState() => _PokemonCombatPageState();
}

class _PokemonCombatPageState extends State<PokemonCombatPage> {
  late final search = TextEditingController(text: widget.combat.search);
  bool compactDetail = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _blocked() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Enregistrez ou annulez la fiche en cours.')),
  );

  Future<void> _create() async {
    var name = '';
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(switch (widget.combat.view) {
          PokemonCombatView.wild => 'Nouvelle table de rencontres',
          PokemonCombatView.trainers => 'Nouveau dresseur',
          PokemonCombatView.unique => 'Nouvelle rencontre unique',
        }),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
          onChanged: (value) => name = value,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          StudioButton(
            label: 'Créer',
            onPressed: () => Navigator.pop(context, name),
          ),
        ],
      ),
    );
    if (!mounted || title == null) return;
    final combat = widget.combat;
    final created = combat.view == PokemonCombatView.trainers
        ? combat.createTrainer(title)
        : combat.createTable(
            title,
            unique: combat.view == PokemonCombatView.unique,
          );
    if (created) setState(() => compactDetail = true);
  }

  Future<void> _delete() async {
    final combat = widget.combat;
    final table = combat.table;
    final trainer = combat.trainer;
    if (combat.dirty || (table == null && trainer == null)) return;
    final owner = table?.current.id ?? trainer!.current.id;
    final references = table != null
        ? combatTableReferences(combat.snapshot!, table.current)
        : combatTrainerReferences(combat.snapshot!, trainer!.current);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer $owner ?'),
        content: Text(
          references.isEmpty
              ? 'Cette fiche sera supprimée du projet.'
              : 'Références à corriger avant suppression : ${references.join(', ')}',
        ),
        actions: [
          StudioButton(
            label: 'Conserver',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer',
            variant: StudioButtonVariant.destructive,
            onPressed: references.isNotEmpty
                ? null
                : () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await combat.deleteSelected();
    if (mounted && deleted) setState(() => compactDetail = false);
  }

  @override
  Widget build(BuildContext context) {
    final combat = widget.combat;
    final snapshot = combat.snapshot;
    if (snapshot == null) {
      return PokemonEmptyState(
        title: combat.loading
            ? 'Chargement des combats…'
            : 'Combats indisponibles',
        description: combat.error ?? 'Réessayez la lecture du projet.',
        action: StudioButton(
          label: 'Réessayer',
          onPressed: combat.loading ? null : () => combat.load(refresh: true),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final detail = combat.view == PokemonCombatView.trainers
            ? PokemonCombatTrainerDetail(
                combat: combat,
                index: widget.index,
                references: combat.trainer == null
                    ? const []
                    : combatTrainerReferences(
                        snapshot,
                        combat.trainer!.current,
                      ),
                onOpenReference: widget.onOpenReference,
                onDelete: _delete,
                onBack: compact
                    ? () => setState(() => compactDetail = false)
                    : null,
              )
            : PokemonCombatTableDetail(
                combat: combat,
                index: widget.index,
                onOpenReference: widget.onOpenReference,
                onDelete: _delete,
                onBack: compact
                    ? () => setState(() => compactDetail = false)
                    : null,
              );
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (view, label) in const [
                    (PokemonCombatView.wild, 'Rencontres sauvages'),
                    (PokemonCombatView.trainers, 'Dresseurs'),
                    (PokemonCombatView.unique, 'Rencontres uniques'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: combat.view == view,
                        onSelected: (_) {
                          if (!combat.setView(view)) {
                            _blocked();
                            return;
                          }
                          search.clear();
                          setState(() => compactDetail = false);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: compact && compactDetail
                  ? detail
                  : Row(
                      children: [
                        SizedBox(
                          width: compact
                              ? constraints.maxWidth
                              : (constraints.maxWidth * .32).clamp(280, 380),
                          child: PokemonCombatList(
                            combat: combat,
                            search: search,
                            onCreate: _create,
                            onSearch: (value) {
                              combat.search = value;
                              setState(() {});
                            },
                            onSelected: () =>
                                setState(() => compactDetail = true),
                            onBlocked: _blocked,
                          ),
                        ),
                        if (!compact) ...[
                          const VerticalDivider(width: 1),
                          Expanded(child: detail),
                          if (constraints.maxWidth >= 1150) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 320,
                              child: PokemonCombatContextPanel(
                                combat: combat,
                                onOpenReference: widget.onOpenReference,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
