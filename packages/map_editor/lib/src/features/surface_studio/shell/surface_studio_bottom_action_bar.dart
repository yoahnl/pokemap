import 'package:flutter/cupertino.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioBottomActionBar extends StatelessWidget {
  const SurfaceStudioBottomActionBar({
    super.key,
    required this.canGoBack,
    required this.canAutoSuggest,
    required this.canApplyMapping,
    required this.canGoNext,
    required this.onBack,
    required this.onAutoSuggest,
    required this.onApplyMapping,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canAutoSuggest;
  final bool canApplyMapping;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onAutoSuggest;
  final VoidCallback onApplyMapping;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.bottomBar'),
      decoration: const BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        border: Border(
          top: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _BarButton(
            keyName: 'surfaceStudio.action.back',
            label: 'Retour',
            icon: CupertinoIcons.arrow_left,
            enabled: canGoBack,
            onPressed: onBack,
          ),
          const Spacer(),
          _BarButton(
            keyName: 'surfaceStudio.action.autoSuggest',
            label: 'Suggestion auto',
            icon: CupertinoIcons.sparkles,
            enabled: canAutoSuggest,
            onPressed: onAutoSuggest,
            accent: SurfaceStudioDesignTokens.accentTeal,
          ),
          const SizedBox(width: 20),
          _BarButton(
            keyName: 'surfaceStudio.action.applyMapping',
            label: 'Appliquer le mapping',
            icon: CupertinoIcons.checkmark_circle,
            enabled: canApplyMapping,
            onPressed: onApplyMapping,
          ),
          const SizedBox(width: 20),
          _BarButton(
            keyName: 'surfaceStudio.action.next',
            label: 'Suivant',
            icon: CupertinoIcons.arrow_right,
            enabled: canGoNext,
            onPressed: onNext,
            accent: SurfaceStudioDesignTokens.accentGold,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.accent,
    this.primary = false,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final Color? accent;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? SurfaceStudioDesignTokens.borderStrong;
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: CupertinoButton(
        key: ValueKey(keyName),
        minimumSize: const Size(46, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        color: primary
            ? effectiveAccent.withValues(alpha: 0.42)
            : SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(9),
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary
                  ? SurfaceStudioDesignTokens.textPrimary
                  : effectiveAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? SurfaceStudioDesignTokens.textPrimary
                    : SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
