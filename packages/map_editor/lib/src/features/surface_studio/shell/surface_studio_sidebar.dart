import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../surface_studio_design_tokens.dart';
import '../surface_studio_motion.dart';
import '../surface_studio_step.dart';

class SurfaceStudioSidebar extends StatelessWidget {
  const SurfaceStudioSidebar({
    super.key,
    required this.collapsed,
    required this.currentStep,
    required this.completedSteps,
    required this.onToggleCollapsed,
    required this.onStepSelected,
  });

  final bool collapsed;
  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('surfaceStudio.sidebar'),
      duration: SurfaceStudioMotion.panelSlide,
      curve: SurfaceStudioMotion.easeInOut,
      width: collapsed
          ? SurfaceStudioDesignTokens.sidebarWidthCollapsed
          : SurfaceStudioDesignTokens.sidebarWidthExpanded,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: ValueKey(
                collapsed
                    ? 'surfaceStudio.sidebar.collapsed'
                    : 'surfaceStudio.sidebar.expanded',
              ),
              height: 0,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: collapsed ? 52 : 254,
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!collapsed)
                      const Text(
                        'Étapes',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Tooltip(
                      message: collapsed
                          ? 'Déployer les étapes'
                          : 'Réduire les étapes',
                      child: CupertinoButton(
                        key: const ValueKey(
                            'surfaceStudio.sidebar.collapseButton'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(36),
                        onPressed: onToggleCollapsed,
                        child: Icon(
                          collapsed
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          color: SurfaceStudioDesignTokens.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final step in SurfaceStudioWizardStep.values) ...[
              _SidebarStepCard(
                collapsed: collapsed,
                step: step,
                active: step == currentStep,
                completed: completedSteps.contains(step),
                onTap: () => onStepSelected(step),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 8),
            _TipsCard(collapsed: collapsed),
          ],
        ),
      ),
    );
  }
}

class _SidebarStepCard extends StatelessWidget {
  const _SidebarStepCard({
    required this.collapsed,
    required this.step,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  final bool collapsed;
  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.75)
            : SurfaceStudioDesignTokens.borderSubtle;
    final fill = active
        ? SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.22)
        : completed
            ? SurfaceStudioDesignTokens.accentTealSoft.withValues(alpha: 0.36)
            : SurfaceStudioDesignTokens.backgroundPanelAlt;
    final content = AnimatedContainer(
      duration: SurfaceStudioMotion.normal,
      height: collapsed ? 56 : 90,
      padding: EdgeInsets.all(collapsed ? 8 : 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
        border: Border.all(color: border, width: active ? 2 : 1),
      ),
      child: collapsed
          ? Center(
              child: Text(
                '${step.number}',
                style: TextStyle(
                  color: active
                      ? SurfaceStudioDesignTokens.accentGold
                      : completed
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 226,
                child: Row(
                  children: [
                    _StepNumber(
                        step: step, active: active, completed: completed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              color: active
                                  ? SurfaceStudioDesignTokens.accentGold
                                  : completed
                                      ? SurfaceStudioDesignTokens.accentTeal
                                      : SurfaceStudioDesignTokens.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            step.sidebarDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active || completed
                                  ? SurfaceStudioDesignTokens.textSecondary
                                  : SurfaceStudioDesignTokens.textMuted,
                              fontSize: 11.5,
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (completed)
                      const Icon(
                        CupertinoIcons.checkmark_circle,
                        color: SurfaceStudioDesignTokens.accentTeal,
                        size: 22,
                      )
                    else if (active)
                      const Icon(
                        CupertinoIcons.arrow_right,
                        color: SurfaceStudioDesignTokens.accentGold,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
    );

    return Tooltip(
      message: step.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber({
    required this.step,
    required this.active,
    required this.completed,
  });

  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal
            : SurfaceStudioDesignTokens.textMuted;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '${step.number}',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Astuces',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.18),
          borderRadius:
              BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
          border: Border.all(
            color: SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.45),
          ),
        ),
        child: collapsed
            ? const Icon(
                CupertinoIcons.lightbulb,
                color: SurfaceStudioDesignTokens.accentGold,
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Icon(
                        CupertinoIcons.lightbulb,
                        color: SurfaceStudioDesignTokens.accentGold,
                        size: 17,
                      ),
                      Text(
                        'Astuces',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.accentGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _TipLine(
                      'Glissez une colonne de l’atlas vers une case du schéma.'),
                  _TipLine(
                      'Les rôles sont illustrés pour éviter les ambiguïtés.'),
                  _TipLine('Le rôle “Plein” peut contenir plusieurs colonnes.'),
                ],
              ),
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• $text',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textSecondary,
          fontSize: 11,
          height: 1.25,
        ),
        softWrap: true,
      ),
    );
  }
}
