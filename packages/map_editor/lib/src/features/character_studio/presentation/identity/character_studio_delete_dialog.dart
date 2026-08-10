import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../application/use_cases/character_use_cases.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

final class CharacterDeleteDecision {
  const CharacterDeleteDecision({required this.resolution, this.replacementId});

  final CharacterDeleteResolution resolution;
  final String? replacementId;
}

Future<CharacterDeleteDecision?> showCharacterDeleteDialog({
  required BuildContext context,
  required String characterName,
  required CharacterDeletePlan plan,
}) {
  var resolution = CharacterDeleteResolution.clear;
  var replacementId = plan.replacementCandidates.firstOrNull?.id;
  return showDialog<CharacterDeleteDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => PokeMapDialog(
        key: const ValueKey<String>('character-delete-dialog'),
        title: 'Supprimer $characterName',
        icon: CupertinoIcons.trash,
        maxWidth: 560,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              key: const ValueKey<String>('character-delete-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const ValueKey<String>('character-delete-confirm'),
              onPressed:
                  resolution == CharacterDeleteResolution.replace &&
                      replacementId == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                      CharacterDeleteDecision(
                        resolution: resolution,
                        replacementId:
                            resolution == CharacterDeleteResolution.replace
                            ? replacementId
                            : null,
                      ),
                    ),
              variant: PokeMapButtonVariant.danger,
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.dependencies.isEmpty
                      ? 'Ce personnage n’est utilisé nulle part ailleurs dans le projet.'
                      : '${plan.dependencies.length} références utilisent encore ce personnage. Choisissez comment les traiter avant la suppression.',
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (plan.dependencies.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _CharacterDeleteDependencies(dependencies: plan.dependencies),
                ],
                if (plan.requiresResolution) ...[
                  const SizedBox(height: 18),
                  const PokeMapSectionHeader(
                    title: 'Traitement des références',
                    description:
                        'Effacez les liens existants ou remplacez-les par un autre personnage.',
                  ),
                  const SizedBox(height: 8),
                  PokeMapSegmentedTabs(
                    tabs: [
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'character-delete-resolution-clear',
                        ),
                        label: 'Effacer les références',
                        selected: resolution == CharacterDeleteResolution.clear,
                        icon: CupertinoIcons.clear_circled,
                        onTap: () => setDialogState(
                          () => resolution = CharacterDeleteResolution.clear,
                        ),
                      ),
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'character-delete-resolution-replace',
                        ),
                        label: 'Remplacer',
                        selected:
                            resolution == CharacterDeleteResolution.replace,
                        icon: CupertinoIcons.arrow_2_circlepath,
                        onTap: plan.replacementCandidates.isEmpty
                            ? null
                            : () => setDialogState(
                                () => resolution =
                                    CharacterDeleteResolution.replace,
                              ),
                      ),
                    ],
                  ),
                  if (resolution == CharacterDeleteResolution.replace) ...[
                    const SizedBox(height: 12),
                    PokeMapDropdownField<String>(
                      key: const ValueKey<String>(
                        'character-delete-replacement',
                      ),
                      label: 'Personnage de remplacement',
                      value: replacementId ?? '',
                      items: [
                        for (final candidate in plan.replacementCandidates)
                          PokeMapDropdownItem<String>(
                            value: candidate.id,
                            label: candidate.name,
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => replacementId = value),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CharacterDeleteDependencies extends StatelessWidget {
  const _CharacterDeleteDependencies({required this.dependencies});

  final List<CharacterDeleteDependency> dependencies;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey<String>('character-delete-dependencies'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < dependencies.length; index++) ...[
            _CharacterDeleteDependencyRow(dependency: dependencies[index]),
            if (index != dependencies.length - 1)
              Divider(color: context.pokeMapColors.divider, height: 18),
          ],
        ],
      ),
    );
  }
}

class _CharacterDeleteDependencyRow extends StatelessWidget {
  const _CharacterDeleteDependencyRow({required this.dependency});

  final CharacterDeleteDependency dependency;

  @override
  Widget build(BuildContext context) {
    final label = _dependencyLabel(dependency.sourceKind);
    final showSource = dependency.sourceKind != 'defaultPlayer';
    return Row(
      children: [
        Icon(
          _dependencyIcon(dependency.sourceKind),
          size: 16,
          color: context.pokeMapColors.warning,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            showSource && dependency.sourceId.isNotEmpty
                ? '$label · ${dependency.sourceId}'
                : label,
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _dependencyLabel(String sourceKind) => switch (sourceKind) {
  'defaultPlayer' => 'Personnage joueur par défaut',
  'newGameAvatar' => 'Avatar de nouvelle partie',
  'trainer' => 'Dresseur',
  'cinematicAppearance' => 'Apparition cinématique',
  'mapNpc' => 'PNJ de carte',
  _ => 'Référence de projet',
};

IconData _dependencyIcon(String sourceKind) => switch (sourceKind) {
  'defaultPlayer' => CupertinoIcons.game_controller_solid,
  'newGameAvatar' => CupertinoIcons.person_crop_circle_badge_plus,
  'trainer' => CupertinoIcons.person_2_fill,
  'cinematicAppearance' => CupertinoIcons.film_fill,
  'mapNpc' => CupertinoIcons.map_pin_ellipse,
  _ => CupertinoIcons.link,
};
