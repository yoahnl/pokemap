import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'environment_diagnostic_presentation.dart';

/// Drilldown read-only des diagnostics filtrés sur un preset.
class EnvironmentPresetDiagnosticsView extends StatelessWidget {
  const EnvironmentPresetDiagnosticsView({
    super.key,
    required this.diagnostics,
    required this.labelColor,
    required this.subtleColor,
  });

  final List<EnvironmentAuthoringDiagnostic> diagnostics;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return Text(
        'Aucun diagnostic pour ce preset.',
        key: const Key('environment-studio-preset-diagnostics-empty'),
        style: TextStyle(
          color: subtleColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    var err = 0;
    var warn = 0;
    for (final d in diagnostics) {
      switch (d.severity) {
        case EnvironmentAuthoringDiagnosticSeverity.error:
          err++;
        case EnvironmentAuthoringDiagnosticSeverity.warning:
          warn++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-preset-diagnostics-root'),
      children: [
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
        const SizedBox(height: 10),
        ...diagnostics.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  index: e.key,
                  diagnostic: e.value,
                  labelColor: labelColor,
                  subtleColor: subtleColor,
                ),
              ),
            ),
      ],
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.index,
    required this.diagnostic,
    required this.labelColor,
    required this.subtleColor,
  });

  final int index;
  final EnvironmentAuthoringDiagnostic diagnostic;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final d = diagnostic;
    final isError = d.severity == EnvironmentAuthoringDiagnosticSeverity.error;
    final badgeColor = isError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemOrange.resolveFrom(context);
    final fill = EditorChrome.chipFill(context);

    return DecoratedBox(
      key: Key('environment-studio-diag-card-$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    environmentDiagnosticSeverityLabel(d.severity),
                    key: Key('environment-studio-diag-severity-$index'),
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    environmentDiagnosticKindLabel(d.kind),
                    key: Key('environment-studio-diag-kind-$index'),
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.message,
              key: Key('environment-studio-diag-message-$index'),
              style: TextStyle(
                color: labelColor,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasOptionalFields(d)) ...[
              const SizedBox(height: 10),
              ..._buildOptionalRows(d, index, subtleColor),
            ],
          ],
        ),
      ),
    );
  }

  static bool _hasOptionalFields(EnvironmentAuthoringDiagnostic d) {
    return d.elementId != null ||
        d.templateId != null ||
        d.mapId != null ||
        d.layerId != null ||
        d.areaId != null ||
        d.targetTileLayerId != null ||
        d.generatedPlacementId != null;
  }

  static List<Widget> _buildOptionalRows(
    EnvironmentAuthoringDiagnostic d,
    int index,
    Color subtle,
  ) {
    final out = <Widget>[];
    void add(String title, String? value, String field) {
      if (value == null || value.isEmpty) {
        return;
      }
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  title,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  key: Key('environment-studio-diag-field-$field-$index'),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    add('elementId', d.elementId, 'elementId');
    add('templateId', d.templateId, 'templateId');
    add('mapId', d.mapId, 'mapId');
    add('layerId', d.layerId, 'layerId');
    add('areaId', d.areaId, 'areaId');
    add('targetTileLayerId', d.targetTileLayerId, 'targetTileLayerId');
    add('generatedPlacementId', d.generatedPlacementId, 'generatedPlacementId');
    return out;
  }
}
