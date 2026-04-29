import 'package:flutter/cupertino.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_step.dart';

class SurfaceStudioTopStepper extends StatelessWidget {
  const SurfaceStudioTopStepper({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepSelected,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      key: const ValueKey('surfaceStudio.stepper'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final step in SurfaceStudioWizardStep.values) ...[
            _TopStep(
              step: step,
              active: step == currentStep,
              completed: completedSteps.contains(step),
              onTap: () => onStepSelected(step),
            ),
            if (step != SurfaceStudioWizardStep.values.last)
              Container(
                width: 28,
                height: 1,
                color: step.index < currentStep.index
                    ? SurfaceStudioDesignTokens.accentTeal
                        .withValues(alpha: 0.45)
                    : SurfaceStudioDesignTokens.borderStrong,
              ),
          ],
        ],
      ),
    );
  }
}

class _TopStep extends StatelessWidget {
  const _TopStep({
    required this.step,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal
            : SurfaceStudioDesignTokens.textMuted;
    return GestureDetector(
      key: ValueKey('surfaceStudio.step.${step.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? SurfaceStudioDesignTokens.accentGoldSoft
                        .withValues(alpha: 0.55)
                    : SurfaceStudioDesignTokens.backgroundPanel,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: active ? 2 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: SurfaceStudioDesignTokens.accentGold
                              .withValues(alpha: 0.32),
                          blurRadius: 14,
                        ),
                      ]
                    : const [],
              ),
              child: completed
                  ? Icon(CupertinoIcons.checkmark, size: 15, color: color)
                  : Text(
                      '${step.number}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 7),
            Text(
              step.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontStyle: active ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            if (active)
              SizedBox(
                key: ValueKey('surfaceStudio.step.${step.id}.active'),
                width: 0,
                height: 0,
              ),
          ],
        ),
      ),
    );
  }
}
