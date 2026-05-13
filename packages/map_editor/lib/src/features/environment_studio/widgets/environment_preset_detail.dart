import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_tileset_compatibility.dart';
import 'environment_palette_item_view.dart';
import 'environment_preset_diagnostics_view.dart';

/// Détail read-only d’un preset : identité, paramètres, palette, diagnostics.
class EnvironmentPresetDetail extends StatelessWidget {
  const EnvironmentPresetDetail({
    super.key,
    required this.preset,
    required this.projectElements,
    required this.report,
    required this.labelColor,
    required this.subtleColor,
    this.onEditAsDraft,
  });

  final EnvironmentPreset preset;
  final List<ProjectElementEntry> projectElements;
  final EnvironmentAuthoringDiagnosticsReport report;
  final Color labelColor;
  final Color subtleColor;

  /// Lot 18 : ouvre le brouillon d’édition (null = action masquée).
  final VoidCallback? onEditAsDraft;

  @override
  Widget build(BuildContext context) {
    final p = preset;
    final diag = report.diagnosticsForPreset(p.id);
    final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
      paletteElementIds: [
        for (final item in p.palette) item.elementId,
      ],
      projectElements: projectElements,
    );
    final incompatibleElementIds =
        tilesetCompatibility.incompatiblePaletteElementIds.toSet();
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-detail-root'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Éditer le preset',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onEditAsDraft != null) ...[
              const SizedBox(width: 10),
              CupertinoButton(
                key: const Key('environment-studio-edit-as-draft'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                onPressed: onEditAsDraft,
                child: const Text('Modifier en brouillon'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-identity'),
          title: 'Identité',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailLine(
                  'Nom', p.name, const Key('environment-studio-detail-name')),
              _detailLine(
                  'Id', p.id, const Key('environment-studio-detail-id')),
              _detailLine(
                'Template',
                p.templateId,
                const Key('environment-studio-detail-template'),
              ),
              _detailLine(
                'Catégorie',
                p.categoryId ?? '—',
                const Key('environment-studio-detail-category'),
              ),
              _detailLine(
                'Ordre d’affichage',
                '${p.sortOrder}',
                const Key('environment-studio-detail-sort'),
              ),
            ],
          ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-params'),
          title: 'Paramètres par défaut',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _paramChip(
                context,
                label: 'Densité',
                value: _formatDouble(p.defaultParams.density),
                valueKey: const Key('environment-studio-detail-param-density'),
              ),
              _paramChip(
                context,
                label: 'Variation',
                value: _formatDouble(p.defaultParams.variation),
                valueKey:
                    const Key('environment-studio-detail-param-variation'),
              ),
              _paramChip(
                context,
                label: 'Densité des bords',
                value: _formatDouble(p.defaultParams.edgeDensity),
                valueKey: const Key('environment-studio-detail-param-edge'),
              ),
              _paramChip(
                context,
                label: 'Espacement min. (cases)',
                value: '${p.defaultParams.minSpacingCells}',
                valueKey: const Key('environment-studio-detail-param-spacing'),
              ),
            ],
          ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-tileset-source'),
          title: 'Tileset source',
          child: _tilesetSourceBlock(context, tilesetCompatibility),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-palette'),
          title: 'Palette du preset',
          child: p.palette.isEmpty
              ? Text(
                  'Palette vide.',
                  key: const Key('environment-studio-palette-empty'),
                  style: TextStyle(color: subtleColor, fontSize: 13),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in p.palette)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EnvironmentPaletteItemView(
                          item: item,
                          subtleColor: subtleColor,
                          isIncompatibleTileset:
                              incompatibleElementIds.contains(item.elementId),
                        ),
                      ),
                  ],
                ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-diagnostics'),
          title: 'Diagnostics (preset)',
          child: EnvironmentPresetDiagnosticsView(
            diagnostics: diag,
            labelColor: labelColor,
            subtleColor: subtleColor,
          ),
          fill: fill,
          border: border,
        ),
      ],
    );
  }

  static String _formatDouble(double v) => v.toStringAsFixed(2);

  Widget _sectionCard(
    BuildContext context, {
    required Key key,
    required String title,
    required Widget child,
    required Color fill,
    required Color border,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _tilesetSourceBlock(
    BuildContext context,
    EnvironmentPresetTilesetCompatibility compatibility,
  ) {
    final source = compatibility.sourceTilesetId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          source ?? 'Tileset source non défini',
          key: const Key('environment-studio-tileset-source-value'),
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          source == null
              ? 'Ajoutez un premier élément ou choisissez un tileset source.'
              : 'Seuls les éléments compatibles avec ce tileset sont proposés.',
          key: const Key('environment-studio-tileset-source-help'),
          style: TextStyle(
            color: subtleColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        _protectionPill(),
        if (compatibility.hasMixedTilesets) ...[
          const SizedBox(height: 8),
          Text(
            'Ce preset contient des éléments provenant de plusieurs tilesets.',
            key: const Key('environment-studio-tileset-mixed-warning'),
            style: TextStyle(
              color: CupertinoColors.systemOrange.resolveFrom(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Nettoyez la palette avant de l’utiliser en génération.',
            style: TextStyle(
              color: subtleColor,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _protectionPill() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: EditorChrome.accentWarm.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: EditorChrome.accentWarm.withValues(alpha: 0.42),
          ),
        ),
        child: const Text(
          'Protection anti-mélange de tilesets activée',
          style: TextStyle(
            color: EditorChrome.accentWarm,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String title, String value, Key valueKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              title,
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramChip(
    BuildContext context, {
    required String label,
    required String value,
    required Key valueKey,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
