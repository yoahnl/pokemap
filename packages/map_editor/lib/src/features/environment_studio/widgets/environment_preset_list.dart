import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Liste read-only des presets Environment avec sélection visuelle.
class EnvironmentPresetList extends StatelessWidget {
  const EnvironmentPresetList({
    super.key,
    required this.presets,
    required this.selectedPresetId,
    required this.report,
    required this.onSelect,
  });

  final List<EnvironmentPreset> presets;
  final String? selectedPresetId;
  final EnvironmentAuthoringDiagnosticsReport report;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: ListView.builder(
        key: const Key('environment-studio-preset-list'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final p = presets[index];
          final isSelected = p.id == selectedPresetId;
          final diag = report.diagnosticsForPreset(p.id);
          var err = 0;
          var warn = 0;
          for (final d in diag) {
            switch (d.severity) {
              case EnvironmentAuthoringDiagnosticSeverity.error:
                err++;
              case EnvironmentAuthoringDiagnosticSeverity.warning:
                warn++;
            }
          }
          return _PresetListTile(
            preset: p,
            selected: isSelected,
            errorCount: err,
            warningCount: warn,
            onTap: () => onSelect(p.id),
          );
        },
      ),
    );
  }
}

class _PresetListTile extends StatelessWidget {
  const _PresetListTile({
    required this.preset,
    required this.selected,
    required this.errorCount,
    required this.warningCount,
    required this.onTap,
  });

  final EnvironmentPreset preset;
  final bool selected;
  final int errorCount;
  final int warningCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = EditorChrome.accentJade;
    final nPalette = preset.palette.length;
    final paletteLabel = nPalette == 1 ? '1 élément' : '$nPalette éléments';
    final category = preset.categoryId ?? 'sans catégorie';
    final badge = StringBuffer();
    if (errorCount > 0) {
      badge.write('$errorCount erreur${errorCount > 1 ? 's' : ''}');
    }
    if (warningCount > 0) {
      if (badge.isNotEmpty) {
        badge.write(' · ');
      }
      badge.write(
        '$warningCount avertissement${warningCount > 1 ? 's' : ''}',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: GestureDetector(
        key: Key('environment-studio-preset-row-${preset.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.65)
                  : CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: label,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      size: 16,
                      color: accent,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Catégorie : $category • $paletteLabel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  badge.toString(),
                  key: Key('environment-studio-preset-row-diag-${preset.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: errorCount > 0
                        ? CupertinoColors.systemRed.resolveFrom(context)
                        : CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
