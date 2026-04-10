part of '../cutscene_studio_workspace.dart';

class _CutsceneSourceKindPicker extends StatelessWidget {
  const _CutsceneSourceKindPicker({
    required this.groupValue,
    required this.enabled,
    required this.onValueChanged,
  });

  final CutsceneStudioSourceKind groupValue;
  final bool enabled;
  final ValueChanged<CutsceneStudioSourceKind> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final track = EditorChrome.chipFill(context);
    final thumb = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.separator(context);
    const kinds = CutsceneStudioSourceKind.values;

    return SizedBox(
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < kinds.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i > 0 ? 1.5 : 0,
                      right: i < kinds.length - 1 ? 1.5 : 0,
                    ),
                    child: _CutsceneSourceKindSegment(
                      label: cutsceneStudioSourceKindLabel(kinds[i]),
                      selected: groupValue == kinds[i],
                      enabled: enabled,
                      onTap: () => onValueChanged(kinds[i]),
                      selectedFill: thumb,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CutsceneSourceKindSegment extends StatelessWidget {
  const _CutsceneSourceKindSegment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.selectedFill,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color selectedFill;

  @override
  Widget build(BuildContext context) {
    final labelColor = enabled
        ? EditorChrome.primaryLabel(context)
        : CupertinoColors.placeholderText.resolveFrom(context);

    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? selectedFill : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                height: 1.2,
                color: labelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioSectionCard extends StatelessWidget {
  const _StudioSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.06),
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled
                ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.45)
                : CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled
                  ? EditorChrome.inspectorJoyCyan
                  : CupertinoColors.placeholderText.resolveFrom(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EditorChrome.primaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 13,
              color: enabled
                  ? EditorChrome.inspectorJoyCyan
                  : CupertinoColors.placeholderText.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOptionRow extends StatelessWidget {
  const _ToggleOptionRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: enabled
              ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.45)
              : CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EditorChrome.primaryLabel(context),
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(24, 24),
      onPressed: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 14,
        color: enabled
            ? EditorChrome.inspectorJoyPlum
            : CupertinoColors.placeholderText.resolveFrom(context),
      ),
    );
  }
}

class _CompatibilityWarningCard extends StatelessWidget {
  const _CompatibilityWarningCard({
    required this.warnings,
  });

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scénario hors format guidé v1',
            style: TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Le studio affiche ce scénario, mais ne peut pas l’éditer sans risque de perte de structure (branches/graphes avancés).',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in warnings)
              Text(
                '• $warning',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CutsceneRuntimeHonestyCard extends StatelessWidget {
  const _CutsceneRuntimeHonestyCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final amber = CupertinoColors.systemOrange.resolveFrom(context);
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: amber.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lecture runtime MVP (honnêteté)',
            style: TextStyle(
              color: amber,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ces points décrivent le comportement actuel de l’exécuteur scénario '
            'MVP, pas une erreur de sauvegarde. Le graphe reste explicite '
            '(fusion, placeholders, etc.).',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Text(
              '• $line',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> deleteCutsceneWithUserConfirmation({
  required BuildContext context,
  required EditorNotifier editorNotifier,
  required NarrativeWorkspaceProjection projection,
  required String scenarioId,
  required String? selectedScenarioId,
  required ValueChanged<String> onSelectReplacement,
}) async {
  final confirmed = await showMacosEditorTwoChoiceAlert(
    context,
    title: 'Supprimer cette cutscene ?',
    message:
        'Cette action retire définitivement la cutscene du projet. Les links qui la référencent devront être mis à jour.',
    primaryLabel: 'Supprimer',
    secondaryLabel: 'Annuler',
    primaryIsDestructive: true,
  );
  if (!confirmed || !context.mounted) return;

  await editorNotifier.deleteProjectScenario(scenarioId);
  if (!context.mounted) return;

  if (selectedScenarioId == scenarioId) {
    final fallback = projection.localEventFlows
        .where((entry) => entry.id != scenarioId)
        .cast<NarrativeScenarioSummary?>()
        .firstWhere((entry) => entry != null, orElse: () => null);
    if (fallback != null) {
      onSelectReplacement(fallback.id);
    }
  }
}

String? _trimOrNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String _trimmedOrFallback(
  String? value, {
  required String fallback,
}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }
  return normalized;
}

String _menuValueOrFirst(String? selected, List<String> options) {
  if (options.isEmpty) {
    return '';
  }
  if (selected != null && options.contains(selected)) {
    return selected;
  }
  return options.first;
}

T? _firstOrNull<T>(List<T> list) {
  if (list.isEmpty) {
    return null;
  }
  return list.first;
}

const String kCutsceneActorNarratorId = 'narrator';
