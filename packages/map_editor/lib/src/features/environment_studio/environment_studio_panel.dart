import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Browser read-only des presets Environment (Lot Environment-10).
///
/// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
/// [ProjectManifest], aucun provider, aucune persistance.
class EnvironmentStudioPanel extends StatefulWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
}

class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _selectedPresetId = _defaultSelectedId(widget.manifest.environmentPresets);
  }

  @override
  void didUpdateWidget(covariant EnvironmentStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _coerceSelectedId(
      widget.manifest.environmentPresets,
      _selectedPresetId,
    );
    if (next != _selectedPresetId) {
      setState(() => _selectedPresetId = next);
    }
  }

  static String? _defaultSelectedId(List<EnvironmentPreset> presets) {
    return _coerceSelectedId(presets, null);
  }

  /// Garde une sélection valide : premier preset (tri sortOrder, id) si besoin.
  static String? _coerceSelectedId(
    List<EnvironmentPreset> presets,
    String? current,
  ) {
    if (presets.isEmpty) {
      return null;
    }
    if (current != null && presets.any((p) => p.id == current)) {
      return current;
    }
    final sorted = [...presets]..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        if (c != 0) {
          return c;
        }
        return a.id.compareTo(b.id);
      });
    return sorted.first.id;
  }

  EnvironmentPreset? _selectedPreset(List<EnvironmentPreset> presets) {
    final id = _selectedPresetId;
    if (id == null) {
      return null;
    }
    for (final p in presets) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final presets = widget.manifest.environmentPresets;
    final n = presets.length;
    final report = diagnoseProjectEnvironmentAuthoring(
      widget.manifest,
      maps: const [],
    );
    final s = report.summary;

    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(
        context,
        tint: EditorChrome.accentJade.withValues(alpha: 0.06),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, label, subtle, n),
                  const SizedBox(height: 20),
                  if (n == 0)
                    Expanded(
                      child: _buildEmptyPresets(context, subtle),
                    )
                  else
                    Expanded(
                      child: _buildBrowser(
                        context,
                        label,
                        subtle,
                        presets,
                        report,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildGlobalDiagnostics(context, label, subtle, s),
                  const SizedBox(height: 16),
                  _buildSoon(context, label, subtle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color label,
    Color subtle,
    int presetCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Environment Studio',
          key: const Key('environment-studio-title'),
          style: TextStyle(
            color: label,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Presets d’environnements organiques',
          style: TextStyle(
            color: subtle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: EditorChrome.chipFill(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EditorChrome.accentJade.withValues(alpha: 0.35),
            ),
          ),
          child: const Text(
            'Lecture seule — édition et génération arrivent dans les prochains lots.',
            key: Key('environment-studio-read-only-banner'),
            style: TextStyle(
              color: EditorChrome.accentJade,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          presetCount == 1 ? '1 preset' : '$presetCount presets',
          key: const Key('environment-studio-preset-count'),
          style: TextStyle(
            color: subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPresets(BuildContext context, Color subtle) {
    return Align(
      alignment: Alignment.topCenter,
      child: Text(
        'Aucun preset d’environnement pour le moment.\n'
        'Les presets seront créés ici dans un prochain lot.',
        key: const Key('environment-studio-empty-presets'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: subtle,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBrowser(
    BuildContext context,
    Color label,
    Color subtle,
    List<EnvironmentPreset> presets,
    EnvironmentAuthoringDiagnosticsReport report,
  ) {
    final selected = _selectedPreset(presets);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: DecoratedBox(
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
                final isSelected = p.id == _selectedPresetId;
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
                  onTap: () => setState(() => _selectedPresetId = p.id),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EditorChrome.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: selected == null
                ? Center(
                    child: Text(
                      'Preset sélectionné introuvable.',
                      key: const Key('environment-studio-preset-missing'),
                      style: TextStyle(
                        color: subtle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    key: const Key('environment-studio-detail-scroll'),
                    padding: const EdgeInsets.all(20),
                    child: _PresetDetail(
                      preset: selected,
                      report: report,
                      labelColor: label,
                      subtleColor: subtle,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalDiagnostics(
    BuildContext context,
    Color label,
    Color subtle,
    EnvironmentAuthoringDiagnosticsSummary s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Diagnostics Environment (projet)',
          key: const Key('environment-studio-diagnostics-title'),
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
          key: const Key('environment-studio-diagnostics-counts'),
          style: TextStyle(
            color: subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Les diagnostics d’usage dans les maps seront activés quand les cartes '
          'chargées seront connectées au workspace.',
          key: const Key('environment-studio-diagnostics-map-note'),
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSoon(BuildContext context, Color label, Color subtle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bientôt :',
          key: const Key('environment-studio-soon-title'),
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '• création de presets ;\n'
          '• édition de palettes ;\n'
          '• utilisation dans les Environment Layers ;\n'
          '• génération organique sur les maps.',
          key: const Key('environment-studio-soon-bullets'),
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
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
                '${preset.id} · $nPalette items · ${preset.templateId}',
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

class _PresetDetail extends StatelessWidget {
  const _PresetDetail({
    required this.preset,
    required this.report,
    required this.labelColor,
    required this.subtleColor,
  });

  final EnvironmentPreset preset;
  final EnvironmentAuthoringDiagnosticsReport report;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final p = preset;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-detail-root'),
      children: [
        Text(
          'Détail du preset',
          style: TextStyle(
            color: labelColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _detailLine('Nom', p.name, const Key('environment-studio-detail-name')),
        _detailLine('Id', p.id, const Key('environment-studio-detail-id')),
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
        const SizedBox(height: 16),
        Text(
          'Paramètres par défaut',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _detailLine(
          'Densité',
          _formatDouble(p.defaultParams.density),
          const Key('environment-studio-detail-param-density'),
        ),
        _detailLine(
          'Variation',
          _formatDouble(p.defaultParams.variation),
          const Key('environment-studio-detail-param-variation'),
        ),
        _detailLine(
          'Densité des bords',
          _formatDouble(p.defaultParams.edgeDensity),
          const Key('environment-studio-detail-param-edge'),
        ),
        _detailLine(
          'Espacement minimal (cases)',
          '${p.defaultParams.minSpacingCells}',
          const Key('environment-studio-detail-param-spacing'),
        ),
        const SizedBox(height: 16),
        Text(
          'Palette',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (p.palette.isEmpty)
          Text(
            'Palette vide.',
            key: const Key('environment-studio-palette-empty'),
            style: TextStyle(color: subtleColor, fontSize: 13),
          )
        else
          ...p.palette.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaletteItemBlock(item: item, subtle: subtleColor),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Diagnostics (preset)',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (diag.isEmpty)
          Text(
            'Aucun diagnostic pour ce preset.',
            key: const Key('environment-studio-preset-diagnostics-empty'),
            style: TextStyle(
              color: subtleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else ...[
          Text(
            '$err erreur${err == 1 ? '' : 's'} · '
            '$warn avertissement${warn == 1 ? '' : 's'}',
            key: const Key('environment-studio-preset-diagnostics-summary'),
            style: TextStyle(
              color: subtleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...diag.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    e.value.message,
                    key: Key('environment-studio-preset-diag-line-${e.key}'),
                    style: TextStyle(
                      color: e.value.severity ==
                              EnvironmentAuthoringDiagnosticSeverity.error
                          ? CupertinoColors.systemRed.resolveFrom(context)
                          : CupertinoColors.systemOrange.resolveFrom(context),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  static String _formatDouble(double v) => v.toStringAsFixed(2);

  Widget _detailLine(String title, String value, Key valueKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
}

class _PaletteItemBlock extends StatelessWidget {
  const _PaletteItemBlock({
    required this.item,
    required this.subtle,
  });

  final EnvironmentPaletteItem item;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final tagStr =
        item.tags.isEmpty ? '—' : (item.tags.toList()..sort()).join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.elementId,
              key: Key('environment-studio-palette-item-${item.elementId}'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Poids ${item.weight} · ${_collisionLabel(item.collisionMode)} · tags: $tagStr',
              key:
                  Key('environment-studio-palette-item-meta-${item.elementId}'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _collisionLabel(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
    };
  }
}
