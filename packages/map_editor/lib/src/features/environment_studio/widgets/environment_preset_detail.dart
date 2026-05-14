import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_tileset_compatibility.dart';
import 'environment_element_thumbnail.dart';
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
    required this.manifest,
    this.resolveTilesetPathById,
    this.onEditAsDraft,
    this.onEditPalette,
  });

  final EnvironmentPreset preset;
  final ProjectManifest manifest;
  final List<ProjectElementEntry> projectElements;
  final EnvironmentAuthoringDiagnosticsReport report;
  final Color labelColor;
  final Color subtleColor;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;

  /// Lot 18 : ouvre le brouillon d’édition (null = action masquée).
  final VoidCallback? onEditAsDraft;
  final VoidCallback? onEditPalette;

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
        _editorTopBar(context, tilesetCompatibility, fill, border),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-identity'),
          number: 1,
          title: 'Identité',
          child: Wrap(
            key: const Key('environment-studio-identity-grid'),
            spacing: 10,
            runSpacing: 10,
            children: [
              _formField(context, 'Nom', p.name,
                  const Key('environment-studio-detail-name')),
              _formField(context, 'ID', p.id,
                  const Key('environment-studio-detail-id')),
              _formField(
                context,
                'Template',
                p.templateId,
                const Key('environment-studio-detail-template'),
              ),
              _formField(
                context,
                'Catégorie',
                p.categoryId ?? '—',
                const Key('environment-studio-detail-category'),
              ),
              _formField(
                context,
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
          number: 2,
          title: 'Paramètres par défaut',
          child: Wrap(
            key: const Key('environment-studio-default-param-grid'),
            spacing: 8,
            runSpacing: 8,
            children: [
              _paramControl(
                context,
                label: 'Densité',
                value: _formatDouble(p.defaultParams.density),
                sliderValue: p.defaultParams.density,
                valueKey: const Key('environment-studio-detail-param-density'),
              ),
              _paramControl(
                context,
                label: 'Variation',
                value: _formatDouble(p.defaultParams.variation),
                sliderValue: p.defaultParams.variation,
                valueKey:
                    const Key('environment-studio-detail-param-variation'),
              ),
              _paramControl(
                context,
                label: 'Densité des bords',
                value: _formatDouble(p.defaultParams.edgeDensity),
                sliderValue: p.defaultParams.edgeDensity,
                valueKey: const Key('environment-studio-detail-param-edge'),
              ),
              _paramControl(
                context,
                label: 'Espacement min. (cases)',
                value: '${p.defaultParams.minSpacingCells}',
                sliderValue: null,
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
          key: const Key('environment-studio-section-palette'),
          number: 3,
          title: 'Palette du preset',
          child: _paletteTableSection(
            context,
            palette: p.palette,
            incompatibleElementIds: incompatibleElementIds,
          ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-diagnostics'),
          title: 'Diagnostics projet',
          child: _projectDiagnostics(context, diag, report.summary),
          fill: fill,
          border: border,
        ),
      ],
    );
  }

  static String _formatDouble(double v) => v.toStringAsFixed(2);

  Widget _editorTopBar(
    BuildContext context,
    EnvironmentPresetTilesetCompatibility compatibility,
    Color fill,
    Color border,
  ) {
    return DecoratedBox(
      key: const Key('environment-studio-editor-top-bar'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Éditer le preset',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _editorActions(),
              ],
            );
            final tileset =
                _tilesetSourceCard(context, compatibility, fill, border);
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  tileset,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                SizedBox(width: 360, child: tileset),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _editorActions() {
    if (onEditAsDraft == null && onEditPalette == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onEditAsDraft != null)
          CupertinoButton(
            key: const Key('environment-studio-edit-as-draft'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            minimumSize: Size.zero,
            onPressed: onEditAsDraft,
            child: const Text('Modifier en brouillon'),
          ),
        if (onEditPalette != null)
          CupertinoButton(
            key: const Key('environment-studio-edit-palette'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            minimumSize: Size.zero,
            onPressed: onEditPalette,
            child: const Text('Modifier la palette'),
          ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required Key key,
    int? number,
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
            Row(
              children: [
                if (number != null) ...[
                  Container(
                    key: Key('environment-studio-section-number-$number'),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EditorChrome.accentJade.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: EditorChrome.accentJade,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _tilesetSourceCard(
    BuildContext context,
    EnvironmentPresetTilesetCompatibility compatibility,
    Color fill,
    Color border,
  ) {
    return DecoratedBox(
      key: const Key('environment-studio-tileset-source-card'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          key: const Key('environment-studio-section-tileset-source'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tileset source',
              style: TextStyle(
                color: subtleColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _tilesetSourceBlock(context, compatibility),
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
        const SizedBox(height: 5),
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
        const SizedBox(height: 7),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

  Widget _formField(
    BuildContext context,
    String title,
    String value,
    Key valueKey,
  ) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subtleColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: EditorChrome.badgeFill(context),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Text(
              value,
              key: valueKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramControl(
    BuildContext context, {
    required String label,
    required String value,
    required double? sliderValue,
    required Key valueKey,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    final clamped = sliderValue?.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.badgeFill(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: subtle,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  value,
                  key: valueKey,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (clamped == null)
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: EditorChrome.accentJade.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              )
            else
              SizedBox(
                height: 18,
                child: CupertinoSlider(
                  value: clamped,
                  onChanged: null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paletteTableSection(
    BuildContext context, {
    required List<EnvironmentPaletteItem> palette,
    required Set<String> incompatibleElementIds,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final edit = onEditPalette == null
                ? const SizedBox.shrink()
                : CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    onPressed: onEditPalette,
                    child: const Text('Modifier la palette'),
                  );
            final filter = _compatibleFilterBox(context);
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: edit),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: filter),
                ],
              );
            }
            return Row(
              children: [
                edit,
                const Spacer(),
                filter,
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        if (palette.isEmpty)
          Text(
            'Palette vide.',
            key: const Key('environment-studio-palette-empty'),
            style: TextStyle(color: subtleColor, fontSize: 13),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              key: const Key('environment-studio-palette-table'),
              width: 842,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _paletteHeader(context),
                  const SizedBox(height: 6),
                  for (final item in palette)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: EnvironmentPaletteItemView(
                        item: item,
                        subtleColor: subtleColor,
                        manifest: manifest,
                        element: _projectElement(item.elementId),
                        resolveTilesetPathById: resolveTilesetPathById,
                        isIncompatibleTileset:
                            incompatibleElementIds.contains(item.elementId),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  ProjectElementEntry? _projectElement(String id) {
    for (final element in projectElements) {
      if (element.id == id) {
        return element;
      }
    }
    return null;
  }

  Widget _compatibleFilterBox(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EditorChrome.badgeFill(context),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: CupertinoColors.separator.resolveFrom(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filtrer éléments compatibles...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtleColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.search,
            color: subtleColor,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _paletteHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EditorChrome.badgeFill(context),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Row(
        children: [
          _tableHeader('Élément',
              const Key('environment-studio-palette-header-element'), 270),
          _tableHeader('Poids',
              const Key('environment-studio-palette-header-weight'), 92),
          _tableHeader('Collision',
              const Key('environment-studio-palette-header-collision'), 150),
          _tableHeader(
              'Tags', const Key('environment-studio-palette-header-tags'), 230),
          _tableHeader('Actions',
              const Key('environment-studio-palette-header-actions'), 78),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, Key key, double width) {
    return SizedBox(
      key: key,
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: subtleColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _projectDiagnostics(
    BuildContext context,
    List<EnvironmentAuthoringDiagnostic> diagnostics,
    EnvironmentAuthoringDiagnosticsSummary summary,
  ) {
    return KeyedSubtree(
      key: const Key('environment-studio-project-diagnostics-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${summary.errorCount} erreur · ${summary.warningCount} avertissement',
            key: const Key('environment-studio-diagnostics-counts'),
            style: TextStyle(
              color: subtleColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          EnvironmentPresetDiagnosticsView(
            diagnostics: diagnostics,
            labelColor: labelColor,
            subtleColor: subtleColor,
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Voir le rapport complet',
              style: TextStyle(
                color: EditorChrome.accentJade,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
