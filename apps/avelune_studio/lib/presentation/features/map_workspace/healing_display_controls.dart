import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_healing_display_draft.dart';

import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class HealingDisplayControls extends StatefulWidget {
  const HealingDisplayControls({
    super.key,
    required this.entity,
    required this.project,
    required this.map,
    required this.onChanged,
    this.elementPreview,
  });
  final MapEntity entity;
  final ProjectManifest project;
  final MapData map;
  final ValueChanged<MapEntityHealingDisplayData?> onChanged;
  final Widget Function(ProjectElementEntry)? elementPreview;
  @override
  State<HealingDisplayControls> createState() => _HealingDisplayControlsState();
}

class _HealingDisplayControlsState extends State<HealingDisplayControls> {
  late MapHealingDisplayDraft draft;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(HealingDisplayControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id ||
        widget.entity.healingDisplay != oldWidget.entity.healingDisplay) {
      _reset();
    } else {
      draft.updateContext(widget.map, widget.project);
    }
  }

  void _reset() {
    draft = MapHealingDisplayDraft(widget.map, widget.project, widget.entity);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = draft.candidates;
    final size = draft.selectedSize;
    final valid = draft.valid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Affichage des boules de soin'),
        const SizedBox(height: 6),
        const Text(
          'Choisissez une variante pour chaque taille d’équipe. Le soin natif affiche uniquement le nombre de Pokémon présents.',
        ),
        if (candidates.length < 6)
          const Text(
            'Ajoutez six éléments visuels sans collision et de dimensions identiques à la bibliothèque.',
          ),
        for (var i = 0; i < 6; i++) ...[
          const SizedBox(height: 10),
          StudioSelect(
            key: ValueKey('healing-display-variant-$i'),
            label: '${i + 1} Pokémon',
            value: draft.variants[i],
            options: {
              for (final entry in candidates.entries)
                if (size == null || draft.geometry(entry.value) == size)
                  entry.key: entry.value.name,
            },
            onChanged: (id) => setState(() => draft.variants[i] = id),
          ),
          if (candidates[draft.variants[i]] case final element?
              when widget.elementPreview != null)
            SizedBox(
              height: 64,
              child: Center(child: widget.elementPreview!(element)),
            ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('healing-display-apply'),
          label: widget.entity.healingDisplay == null
              ? 'Utiliser cet affichage de soin'
              : 'Appliquer les variantes',
          onPressed: valid ? () => widget.onChanged(draft.value) : null,
        ),
        if (widget.entity.healingDisplay != null) ...[
          const SizedBox(height: 8),
          StudioButton(
            key: const ValueKey('healing-display-clear'),
            label: 'Retirer l’affichage de soin',
            secondary: true,
            onPressed: () => widget.onChanged(null),
          ),
        ],
      ],
    );
  }
}
