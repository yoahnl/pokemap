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
    this.description,
    this.summary,
    this.diagnosticCount,
    this.hasBlockingDiagnostic = false,
    this.trailing,
  });

  final String phaseLabel;
  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final String? description;
  final String? summary;
  final int? diagnosticCount;
  final bool hasBlockingDiagnostic;
  final Widget? trailing;
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PokeMapIconTile(
                          icon: icon,
                          tone: tone,
                          size: 26,
                          iconSize: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phaseLabel,
                                style: TextStyle(
                                  color: toneColors.icon,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  description!,
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                    if (diagnosticCount != null) ...[
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 4),
                      Text(
                        summary!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
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
