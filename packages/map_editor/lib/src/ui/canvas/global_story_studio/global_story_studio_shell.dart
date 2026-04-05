// ---------------------------------------------------------------------------
// Global Story Studio — coque écran (produit PokeMap)
// ---------------------------------------------------------------------------
//
// Ce widget remplace l’ancienne « macro carte » fourre-tout par une composition
// stable inspirée des studios narratifs modernes :
//
//   [ Top bar : fil d’Ariane + filière + actions ]
//   [ Nav gauche | Story flow central | Détail step droite ]
//
// Règles respectées :
// - vocabulaire **métier** (étape, chapitre, embranchement, débloque…)
// - **pas** de mini-éditeur de cutscene ici : on renvoie vers Step / Cutscene Studio
// - hiérarchie visuelle forte, beaucoup d’air, pas de graphe libre
//
// Les callbacks mutateurs sont les **mêmes** que l’ancien [GlobalStoryMacroEditor] :
// le workspace conserve toute la logique de brouillon / sauvegarde / réconciliation.
//
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import '../../../features/narrative/application/global_story_studio_authoring.dart';
import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../features/narrative/application/step_studio_authoring.dart';
import '../../shared/cupertino_editor_widgets.dart';
import 'global_story_flow_layout.dart';
import 'global_story_studio_panels.dart';

/// Shell principal : assemblage des 4 zones (top + 3 colonnes).
class GlobalStoryStudioShell extends StatefulWidget {
  const GlobalStoryStudioShell({
    super.key,
    required this.globalStoryName,
    required this.storylineChoices,
    required this.selectedStorylineId,
    required this.onSelectStoryline,
    required this.orderedSteps,
    required this.chapters,
    required this.globalDocument,
    required this.projection,
    required this.selectedStepId,
    required this.hasUnsavedChanges,
    required this.canEdit,
    required this.warnings,
    required this.showLegacyBanner,
    required this.onSave,
    required this.onReset,
    required this.onAddChapter,
    required this.onDeleteChapter,
    required this.onRenameChapter,
    required this.onMoveChapter,
    required this.onAddStepToChapter,
    required this.onRemoveStepFromChapter,
    required this.onMoveStepInChapter,
    required this.onSelectStep,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
    required this.onCreateStep,
  });

  /// Nom affiché du scénario global courant.
  final String globalStoryName;

  /// Entrées du sélecteur « filière / storyline » (souvent un seul item aujourd’hui).
  final List<({String id, String label})> storylineChoices;
  final String? selectedStorylineId;
  final ValueChanged<String?> onSelectStoryline;

  final List<StepStudioStep> orderedSteps;
  final List<GlobalStoryChapter> chapters;
  final GlobalStoryStudioDocument globalDocument;
  final NarrativeWorkspaceProjection projection;

  final String? selectedStepId;
  final bool hasUnsavedChanges;
  final bool canEdit;
  final List<String> warnings;
  final bool showLegacyBanner;

  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onAddChapter;
  final void Function(String chapterId) onDeleteChapter;
  final void Function(String chapterId, String name) onRenameChapter;
  final void Function(String chapterId, int delta) onMoveChapter;
  final void Function(String chapterId, String stepId) onAddStepToChapter;
  final void Function(String chapterId, String stepId) onRemoveStepFromChapter;
  final void Function(String chapterId, int fromIndex, int toIndex)
      onMoveStepInChapter;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String> onOpenStepStudio;
  final ValueChanged<String> onSetEntryStep;
  final VoidCallback onCreateStep;

  @override
  State<GlobalStoryStudioShell> createState() => _GlobalStoryStudioShellState();
}

class _GlobalStoryStudioShellState extends State<GlobalStoryStudioShell> {
  double _navColumnWidth = 228;
  double _detailColumnWidth = 276;

  @override
  Widget build(BuildContext context) {
    final bg = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: EditorChrome.islandWarmTint.withValues(alpha: 0.04),
    );
    final flowBlocks = buildGlobalStoryFlowBlocks(
      document: widget.globalDocument,
      orderedSteps: widget.orderedSteps,
    );

    final stepById = {for (final s in widget.orderedSteps) s.id: s};
    final nodeById = {for (final n in widget.globalDocument.nodes) n.stepId: n};
    final selectedStep = widget.selectedStepId != null
        ? stepById[widget.selectedStepId!]
        : null;
    final selectedNode = widget.selectedStepId != null
        ? nodeById[widget.selectedStepId!]
        : null;

    NarrativeStepSummary? projectionForSelected;
    if (widget.selectedStepId != null) {
      for (final s in widget.projection.steps) {
        if (s.id == widget.selectedStepId) {
          projectionForSelected = s;
          break;
        }
      }
    }

    final chapterCount = widget.chapters.length;
    final stepCount = widget.orderedSteps.length;

    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlobalStoryStudioTopBar(
            storylineChoices: widget.storylineChoices,
            selectedStorylineId: widget.selectedStorylineId,
            onSelectStoryline: widget.onSelectStoryline,
            hasUnsavedChanges: widget.hasUnsavedChanges,
            canEdit: widget.canEdit,
            onSave: widget.onSave,
            onReset: widget.onReset,
            onCreateStep: widget.onCreateStep,
          ),
          if (widget.showLegacyBanner)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _LegacyBanner(),
            ),
          if (widget.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _WarningsStrip(warnings: widget.warnings),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final total = constraints.maxWidth;
                  final layout = _resolveGlobalStoryShellColumns(
                    totalWidth: total,
                    navW: _navColumnWidth,
                    detailW: _detailColumnWidth,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: layout.nav,
                        child: GlobalStoryNavPanel(
                          chapters: widget.chapters,
                          orderedSteps: widget.orderedSteps,
                          globalDocument: widget.globalDocument,
                          selectedStepId: widget.selectedStepId,
                          entryStepId: widget.globalDocument.entryStepId,
                          canEdit: widget.canEdit,
                          statsLine:
                              '$chapterCount chapitres · $stepCount étapes',
                          onSelectStep: widget.onSelectStep,
                          onAddChapter: widget.onAddChapter,
                          onRenameChapter: widget.onRenameChapter,
                          onDeleteChapter: widget.onDeleteChapter,
                          onMoveChapter: widget.onMoveChapter,
                          onAddStepToChapter: widget.onAddStepToChapter,
                          onRemoveStepFromChapter:
                              widget.onRemoveStepFromChapter,
                          onMoveStepInChapter: widget.onMoveStepInChapter,
                        ),
                      ),
                      _GlobalStoryShellColumnSplitter(
                        tooltip: 'Redimensionner la structure',
                        onDrag: (dx) {
                          setState(() {
                            final next = _resolveGlobalStoryShellColumns(
                              totalWidth: total,
                              navW: _navColumnWidth + dx,
                              detailW: _detailColumnWidth,
                            );
                            _navColumnWidth = next.nav;
                            _detailColumnWidth = next.detail;
                          });
                        },
                      ),
                      SizedBox(
                        width: layout.flow,
                        child: GlobalStoryFlowPanel(
                          flowBlocks: flowBlocks,
                          orderedSteps: widget.orderedSteps,
                          globalDocument: widget.globalDocument,
                          selectedStepId: widget.selectedStepId,
                          entryStepId: widget.globalDocument.entryStepId,
                          onSelectStep: widget.onSelectStep,
                        ),
                      ),
                      _GlobalStoryShellColumnSplitter(
                        tooltip: 'Redimensionner le détail',
                        onDrag: (dx) {
                          setState(() {
                            final next = _resolveGlobalStoryShellColumns(
                              totalWidth: total,
                              navW: _navColumnWidth,
                              detailW: _detailColumnWidth - dx,
                            );
                            _navColumnWidth = next.nav;
                            _detailColumnWidth = next.detail;
                          });
                        },
                      ),
                      SizedBox(
                        width: layout.detail,
                        child: GlobalStoryStepDetailPanel(
                          step: selectedStep,
                          node: selectedNode,
                          projection: projectionForSelected,
                          allSteps: widget.orderedSteps,
                          entryStepId: widget.globalDocument.entryStepId,
                          canEdit: widget.canEdit,
                          onOpenStepStudio: widget.onOpenStepStudio,
                          onSetEntryStep: widget.onSetEntryStep,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _kGlobalStoryShellSplitterWidth = 6;

({double nav, double flow, double detail}) _resolveGlobalStoryShellColumns({
  required double totalWidth,
  required double navW,
  required double detailW,
  double minNav = 176,
  double maxNav = 400,
  double minDetail = 200,
  double maxDetail = 520,
  double minFlow = 200,
}) {
  const overhead = 2 * _kGlobalStoryShellSplitterWidth + 2 * 10;
  var n = navW.clamp(minNav, maxNav);
  var d = detailW.clamp(minDetail, maxDetail);
  var f = totalWidth - n - d - overhead;
  while (f < minFlow && (n > minNav || d > minDetail)) {
    final deficit = minFlow - f;
    if (d > minDetail) {
      final sub = math.min(deficit, d - minDetail);
      d -= sub;
      f += sub;
    } else {
      final sub = math.min(deficit, n - minNav);
      n -= sub;
      f += sub;
    }
  }
  f = math.max(0, f);
  return (nav: n, flow: f, detail: d);
}

class _GlobalStoryShellColumnSplitter extends StatelessWidget {
  const _GlobalStoryShellColumnSplitter({
    required this.onDrag,
    required this.tooltip,
  });

  final ValueChanged<double> onDrag;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final line = EditorChrome.subtleLabel(context).withValues(alpha: 0.38);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          child: SizedBox(
            width: _kGlobalStoryShellSplitterWidth,
            child: Center(
              child: Container(
                width: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bannière discrète quand des métadonnées legacy ont été dérivées automatiquement.
class _LegacyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Certaines données ont été complétées automatiquement (ancien format). '
        'Enregistrez pour figer la structure actuelle.',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Bandeau des avertissements de parsing / cohérence (lisible, non bloquant).
class _WarningsStrip extends StatelessWidget {
  const _WarningsStrip({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        warnings.take(4).join('\n'),
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11,
          height: 1.35,
        ),
      ),
    );
  }
}
