import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

class BorderAssetsStep extends StatelessWidget {
  const BorderAssetsStep({
    super.key,
    required this.state,
  });

  final BorderStudioDraftState state;

  @override
  Widget build(BuildContext context) {
    final primitives = state.workingDraft?.blueprint.definition.primitives ??
        const <BorderPrimitiveDraft>[];
    return BorderStudioStepScaffold(
      key: const ValueKey<String>('border-studio-assets-step'),
      title: '2. Assets',
      description:
          'Préparez les éléments visuels, puis vérifiez leur analyse avant publication.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (primitives.isEmpty)
            const BorderStudioNotice(
              key: ValueKey<String>('border-studio-asset-error'),
              title: 'Aucun asset analysé',
              description:
                  'Ajoutez au moins une structure pour préparer la bordure.',
              tone: PokeMapTone.danger,
              icon: CupertinoIcons.exclamationmark_triangle,
            )
          else
            for (final primitive in primitives) ...[
              PokeMapCard(
                child: Row(
                  children: [
                    const PokeMapIconTile(
                      icon: CupertinoIcons.photo,
                      tone: PokeMapTone.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Asset analysé'),
                          const SizedBox(height: 3),
                          Text(borderRoleLabel(primitive.role)),
                        ],
                      ),
                    ),
                    PokeMapBadge(
                      label:
                          '${primitive.currentMetrics.pixelSize.width} × ${primitive.currentMetrics.pixelSize.height} px',
                      variant: PokeMapBadgeVariant.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (state.requiresSourceReanalysis) ...[
            const SizedBox(height: 10),
            const BorderStudioNotice(
              title: 'Source modifiée',
              description:
                  'Réanalysez les assets signalés avant toute republication.',
              tone: PokeMapTone.warning,
              icon: CupertinoIcons.refresh_circled,
            ),
          ],
        ],
      ),
    );
  }
}
