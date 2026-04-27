// Surface Studio — vue diagnostics catalogue (Lot 55).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.diagnostics]
// (déjà calculé dans [map_core] — Lot 51). Aucun appel à
// diagnoseProjectSurfaceCatalog*, aucun JSON, aucun I/O, aucune mutation du
// manifest.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Chaînes visibles (aucun nom de type Dart de la couche diagnostics).
class SurfaceStudioDiagnosticsViewLabels {
  const SurfaceStudioDiagnosticsViewLabels._();

  static const String title = 'Diagnostics Surface';
  static const String cleanTitle = 'Aucun diagnostic Surface';
  static const String cleanSubtitle =
      'Le catalogue Surface ne signale ni erreur ni avertissement.';
  static const String sectionErrors = 'Erreurs';
  static const String sectionWarnings = 'Avertissements';
  static const String noErrors = 'Aucune erreur Surface';
  static const String noWarnings = 'Aucun avertissement Surface';

  static const String summaryErrors = 'Erreurs';
  static const String summaryWarnings = 'Avertissements';
  static const String summaryTotal = 'Total';

  /// Libellés métier pour les [SurfaceCatalogDiagnosticKind] (affichage principal).
  static String kindLabel(SurfaceCatalogDiagnosticKind kind) {
    switch (kind) {
      case SurfaceCatalogDiagnosticKind.missingPresetAnimation:
        return 'Animation manquante dans un preset';
      case SurfaceCatalogDiagnosticKind.missingAnimationAtlas:
        return 'Atlas manquant dans une animation';
      case SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry:
        return 'Frame hors géométrie d’atlas';
      case SurfaceCatalogDiagnosticKind.unusedAtlas:
        return 'Atlas inutilisé';
      case SurfaceCatalogDiagnosticKind.unusedAnimation:
        return 'Animation inutilisée';
    }
  }
}

/// Affichage structuré des diagnostics auteur — **read-only**, sans recalcul.
class SurfaceStudioDiagnosticsView extends StatelessWidget {
  const SurfaceStudioDiagnosticsView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final p = readModel.diagnostics;
    final sum = p.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioDiagnosticsViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _SummaryCounts(
          errorCount: sum.errorCount,
          warningCount: sum.warningCount,
          totalCount: sum.totalCount,
          labelColor: label,
        ),
        const SizedBox(height: 12),
        if (p.isClean) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MacosIcon(
                CupertinoIcons.check_mark_circled_solid,
                color: EditorChrome.inspectorJoyCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      SurfaceStudioDiagnosticsViewLabels.cleanTitle,
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SurfaceStudioDiagnosticsViewLabels.cleanSubtitle,
                      style: TextStyle(
                        color: subtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          _SectionTitle(
            text: SurfaceStudioDiagnosticsViewLabels.sectionErrors,
            subtle: subtle,
          ),
          const SizedBox(height: 8),
          if (p.errors.isEmpty)
            Text(
              SurfaceStudioDiagnosticsViewLabels.noErrors,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...p.errors.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  diagnostic: d,
                  isError: true,
                  labelColor: label,
                  subtle: subtle,
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SectionTitle(
            text: SurfaceStudioDiagnosticsViewLabels.sectionWarnings,
            subtle: subtle,
          ),
          const SizedBox(height: 8),
          if (p.warnings.isEmpty)
            Text(
              SurfaceStudioDiagnosticsViewLabels.noWarnings,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...p.warnings.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  diagnostic: d,
                  isError: false,
                  labelColor: label,
                  subtle: subtle,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryCounts extends StatelessWidget {
  const _SummaryCounts({
    required this.errorCount,
    required this.warningCount,
    required this.totalCount,
    required this.labelColor,
  });

  final int errorCount;
  final int warningCount;
  final int totalCount;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryErrors,
          '$errorCount',
          labelColor,
        ),
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryWarnings,
          '$warningCount',
          labelColor,
        ),
        _kv(
          SurfaceStudioDiagnosticsViewLabels.summaryTotal,
          '$totalCount',
          labelColor,
        ),
      ],
    );
  }

  Widget _kv(String k, String v, Color c) {
    return Text(
      '$k : $v',
      style: TextStyle(
        color: c,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
    required this.subtle,
  });

  final String text;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: subtle,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.diagnostic,
    required this.isError,
    required this.labelColor,
    required this.subtle,
  });

  final SurfaceCatalogDiagnostic diagnostic;
  final bool isError;
  final Color labelColor;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SurfaceStudioDiagnosticsViewLabels.kindLabel(diagnostic.kind),
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            diagnostic.message,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (_contextLines(diagnostic).isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._contextLines(diagnostic).map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Type : ${diagnostic.kind.name}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _contextLines(SurfaceCatalogDiagnostic d) {
    final out = <String>[];
    if (d.presetId != null) {
      out.add('Preset : ${d.presetId}');
    }
    if (d.animationId != null) {
      out.add('Animation : ${d.animationId}');
    }
    if (d.atlasId != null) {
      out.add('Atlas : ${d.atlasId}');
    }
    if (d.role != null) {
      out.add('Rôle : ${d.role!.name}');
    }
    if (d.frameIndex != null) {
      out.add('Frame : ${d.frameIndex}');
    }
    return out;
  }
}
