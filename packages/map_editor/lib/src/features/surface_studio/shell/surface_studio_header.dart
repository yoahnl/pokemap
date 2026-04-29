import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../surface_studio_design_tokens.dart';
import '../surface_studio_step.dart';
import 'surface_studio_top_stepper.dart';

class SurfaceStudioHeader extends StatelessWidget {
  const SurfaceStudioHeader({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepSelected,
    this.onOpenAdvanced,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
  final VoidCallback? onOpenAdvanced;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Container(
          key: const ValueKey('surfaceStudio.header'),
          decoration: const BoxDecoration(
            color: SurfaceStudioDesignTokens.backgroundDeep,
            border: Border(
              bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          child: Row(
            children: [
              const _StudioMark(),
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 180 : 380),
                  child: const Text(
                    'Surface Studio — Assistant de mapping d’atlas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SurfaceStudioDesignTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 24),
              Expanded(
                child: SurfaceStudioTopStepper(
                  currentStep: currentStep,
                  completedSteps: completedSteps,
                  onStepSelected: onStepSelected,
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Aide',
                icon: CupertinoIcons.question_circle,
                onPressed: () {},
              ),
              _HeaderIconButton(
                tooltip: 'Catalogue & diagnostics',
                icon: CupertinoIcons.gear_alt,
                onPressed: onOpenAdvanced ?? () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentTealSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.7),
        ),
      ),
      child: const Icon(
        CupertinoIcons.drop,
        color: SurfaceStudioDesignTokens.accentTeal,
        size: 22,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(36),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 18,
          color: SurfaceStudioDesignTokens.textSecondary,
        ),
      ),
    );
  }
}
