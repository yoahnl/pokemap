import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderFlowBlock extends StatelessWidget {
  const EventBuilderFlowBlock({
    super.key,
    required this.phaseLabel,
    required this.title,
    required this.icon,
    required this.tone,
    required this.children,
    this.summary,
    this.diagnosticCount,
    this.hasBlockingDiagnostic = false,
  });

  final String phaseLabel;
  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final String? summary;
  final int? diagnosticCount;
  final bool hasBlockingDiagnostic;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 8,
      padding: const EdgeInsets.all(0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: toneColors.border,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PokeMapIconTile(
                          icon: icon,
                          tone: tone,
                          size: 34,
                          iconSize: 17,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phaseLabel,
                                style: TextStyle(
                                  color: toneColors.icon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (diagnosticCount != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PokeMapBadge(
                            label: diagnosticCount == 0
                                ? '0 diagnostic'
                                : '$diagnosticCount diagnostic${diagnosticCount! > 1 ? 's' : ''}',
                            variant: diagnosticCount == 0
                                ? PokeMapBadgeVariant.success
                                : hasBlockingDiagnostic
                                    ? PokeMapBadgeVariant.error
                                    : PokeMapBadgeVariant.warning,
                          ),
                          if (hasBlockingDiagnostic)
                            const PokeMapBadge(
                              label: 'Bloquant',
                              variant: PokeMapBadgeVariant.error,
                            ),
                        ],
                      ),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        summary!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
