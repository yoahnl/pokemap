import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderCreationPanel extends StatelessWidget {
  const EventBuilderCreationPanel({
    super.key,
    required this.isExpanded,
    required this.controls,
    required this.onToggle,
    this.compactMessage,
  });

  final bool isExpanded;
  final List<Widget> controls;
  final VoidCallback? onToggle;
  final String? compactMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final controlsContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: controls,
    );
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      expandChild: isExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.plus_square,
                color: colors.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer un événement',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez une position, puis créez un brouillon.',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey('event-builder-creation-panel-toggle'),
                onPressed: controls.isEmpty ? null : onToggle,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                ),
                child: Text(isExpanded ? 'Replier' : 'Préparer'),
              ),
            ],
          ),
          if (isExpanded && controls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('event-builder-creation-panel-scroll'),
                child: controlsContent,
              ),
            ),
          ] else if (compactMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              compactMessage!,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
