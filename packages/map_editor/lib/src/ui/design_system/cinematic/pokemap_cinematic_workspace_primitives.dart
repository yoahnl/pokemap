import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_icon_button.dart';
import '../pokemap_toolbar_surface.dart';

enum PokeMapCinematicDocumentState {
  clean,
  dirty,
  saving,
  saved,
  conflict,
  error,
}

enum PokeMapCinematicPanelTab { layers, properties }

class PokeMapCinematicDocumentStatus extends StatelessWidget {
  const PokeMapCinematicDocumentStatus({
    super.key,
    required this.state,
    required this.label,
    this.detail,
  });

  final PokeMapCinematicDocumentState state;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final variant = switch (state) {
      PokeMapCinematicDocumentState.clean => PokeMapBadgeVariant.neutral,
      PokeMapCinematicDocumentState.dirty => PokeMapBadgeVariant.warning,
      PokeMapCinematicDocumentState.saving => PokeMapBadgeVariant.info,
      PokeMapCinematicDocumentState.saved => PokeMapBadgeVariant.success,
      PokeMapCinematicDocumentState.conflict => PokeMapBadgeVariant.warning,
      PokeMapCinematicDocumentState.error => PokeMapBadgeVariant.error,
    };
    final icon = switch (state) {
      PokeMapCinematicDocumentState.clean => Icons.circle_outlined,
      PokeMapCinematicDocumentState.dirty => Icons.edit_outlined,
      PokeMapCinematicDocumentState.saving => Icons.sync_rounded,
      PokeMapCinematicDocumentState.saved => Icons.check_circle_outline,
      PokeMapCinematicDocumentState.conflict => Icons.warning_amber_rounded,
      PokeMapCinematicDocumentState.error => Icons.error_outline_rounded,
    };
    final detailText = detail?.trim();
    return Semantics(
      container: true,
      liveRegion:
          state == PokeMapCinematicDocumentState.saving ||
          state == PokeMapCinematicDocumentState.conflict ||
          state == PokeMapCinematicDocumentState.error,
      label: detailText == null || detailText.isEmpty
          ? label
          : '$label. $detailText',
      child: ExcludeSemantics(
        child: Tooltip(
          message: detailText == null || detailText.isEmpty
              ? label
              : detailText,
          child: PokeMapBadge(label: label, variant: variant, icon: Icon(icon)),
        ),
      ),
    );
  }
}

class PokeMapCinematicWorkspaceToolbar extends StatelessWidget {
  const PokeMapCinematicWorkspaceToolbar({
    super.key,
    required this.backLabel,
    required this.title,
    required this.contextLabel,
    required this.onBack,
    required this.status,
    this.actions = const [],
  });

  final String backLabel;
  final String title;
  final String contextLabel;
  final VoidCallback? onBack;
  final Widget status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showContext = constraints.maxWidth >= 900;
        return PokeMapToolbarSurface(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              PokeMapIconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: backLabel,
                semanticLabel: backLabel,
                variant: PokeMapIconButtonVariant.soft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showContext) ...[
                      const SizedBox(height: 2),
                      Text(
                        contextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              status,
              for (final action in actions) ...[
                const SizedBox(width: 8),
                action,
              ],
            ],
          ),
        );
      },
    );
  }
}

class PokeMapCinematicPanelTabs extends StatelessWidget {
  const PokeMapCinematicPanelTabs({
    super.key,
    required this.selected,
    required this.layersLabel,
    required this.propertiesLabel,
    required this.onChanged,
  });

  final PokeMapCinematicPanelTab selected;
  final String layersLabel;
  final String propertiesLabel;
  final ValueChanged<PokeMapCinematicPanelTab>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: PokeMapButton(
                semanticLabel: layersLabel,
                onPressed: onChanged == null
                    ? null
                    : () => onChanged!(PokeMapCinematicPanelTab.layers),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: selected == PokeMapCinematicPanelTab.layers,
                child: Text(layersLabel),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PokeMapButton(
                semanticLabel: propertiesLabel,
                onPressed: onChanged == null
                    ? null
                    : () => onChanged!(PokeMapCinematicPanelTab.properties),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: selected == PokeMapCinematicPanelTab.properties,
                child: Text(propertiesLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokeMapCinematicExitGuardActions extends StatelessWidget {
  const PokeMapCinematicExitGuardActions({
    super.key,
    required this.cancelLabel,
    required this.discardLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onDiscard,
    required this.onSave,
    this.isSaving = false,
  });

  final String cancelLabel;
  final String discardLabel;
  final String saveLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onDiscard;
  final VoidCallback? onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        PokeMapButton(
          onPressed: isSaving ? null : onCancel,
          variant: PokeMapButtonVariant.ghost,
          child: Text(cancelLabel),
        ),
        PokeMapButton(
          onPressed: isSaving ? null : onDiscard,
          variant: PokeMapButtonVariant.danger,
          child: Text(discardLabel),
        ),
        PokeMapButton(
          onPressed: isSaving ? null : onSave,
          isLoading: isSaving,
          child: Text(saveLabel),
        ),
      ],
    );
  }
}
