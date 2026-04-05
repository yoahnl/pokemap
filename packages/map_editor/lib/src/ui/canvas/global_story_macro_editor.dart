import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/global_story_studio_authoring.dart';
import '../../features/narrative/application/step_studio_authoring.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Éditeur **macro** du Global Story : lisible, centré sur les données réelles.
///
/// - Les steps affichées sont exactement celles du [StepStudioDocument] du scénario global
///   (même source que l’onglet Step).
/// - Les chapitres sont des **conteneurs** : on y **ajoute** des steps existantes depuis
///   la liste projet (déplacement implicite si la step était dans un autre chapitre).
///
/// L’édition fine des branches / suites globales reste dans l’inspecteur quand une step
/// est sélectionnée (évite de mélanger macro et graphe dans la même carte).
class GlobalStoryMacroEditor extends StatelessWidget {
  const GlobalStoryMacroEditor({
    super.key,
    required this.globalStoryName,
    required this.orderedSteps,
    required this.chapters,
    required this.globalDocument,
    required this.projectionStepCount,
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

  final String globalStoryName;
  final List<StepStudioStep> orderedSteps;
  final List<GlobalStoryChapter> chapters;
  final GlobalStoryStudioDocument globalDocument;
  final int projectionStepCount;
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

  String? _chapterNameContainingStep(String stepId) {
    for (final c in chapters) {
      if (c.stepIds.contains(stepId)) {
        return c.name.trim().isEmpty ? c.id : c.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final orderedChapters = chapters.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));

    var branchCount = 0;
    var convergeCount = 0;
    for (final node in globalDocument.nodes) {
      if (node.exitMode == GlobalStoryStepExitMode.branchExclusive ||
          node.exitMode == GlobalStoryStepExitMode.branchConditional) {
        branchCount++;
      }
      if (node.exitMode == GlobalStoryStepExitMode.converge) {
        convergeCount++;
      }
    }

    final stepCountMismatch =
        projectionStepCount > 0 && projectionStepCount != orderedSteps.length;

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MacroHeader(
            globalStoryName: globalStoryName,
            chapterCount: orderedChapters.length,
            stepCount: orderedSteps.length,
            branchCount: branchCount,
            convergeCount: convergeCount,
            hasUnsavedChanges: hasUnsavedChanges,
            canEdit: canEdit,
            onSave: onSave,
            onReset: onReset,
            onCreateStep: onCreateStep,
          ),
          const SizedBox(height: 12),
          if (showLegacyBanner) ...[
            const _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyAmber,
              text:
                  'Données historiques converties en compatibilité. Sauvegardez pour stabiliser le document Global Story.',
            ),
            const SizedBox(height: 8),
          ],
          if (stepCountMismatch) ...[
            _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text:
                  'Écart entre la liste des steps du scénario global (${orderedSteps.length}) '
                  'et le registre narratif du projet ($projectionStepCount). '
                  'Les steps affichées ici = métadonnées du scénario Global Story (comme l’onglet Step).',
            ),
            const SizedBox(height: 8),
          ],
          for (final w in warnings) ...[
            _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text: w,
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: ListView(
              children: [
                _ProjectStepsSection(
                  orderedSteps: orderedSteps,
                  selectedStepId: selectedStepId,
                  entryStepId: globalDocument.entryStepId,
                  canEdit: canEdit,
                  chapterLabelForStep: _chapterNameContainingStep,
                  onSelectStep: onSelectStep,
                  onOpenStepStudio: onOpenStepStudio,
                  onSetEntryStep: onSetEntryStep,
                ),
                const SizedBox(height: 16),
                _BranchTypesLegend(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Chapitres',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minSize: 0,
                      onPressed: canEdit ? onAddChapter : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.add_circled,
                            size: 18,
                            color: canEdit
                                ? EditorChrome.inspectorJoyMint
                                : EditorChrome.subtleLabel(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nouveau chapitre',
                            style: TextStyle(
                              color: canEdit
                                  ? EditorChrome.inspectorJoyMint
                                  : EditorChrome.subtleLabel(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (orderedChapters.isEmpty && orderedSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InlineInfoBanner(
                      accent: EditorChrome.inspectorJoyAmber,
                      text:
                          'Aucun chapitre : ajoutez-en un, puis placez des steps du bloc du haut dans ce chapitre.',
                    ),
                  ),
                for (var i = 0; i < orderedChapters.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ChapterMacroCard(
                    chapter: orderedChapters[i],
                    chapterIndex: i,
                    totalChapters: orderedChapters.length,
                    allChapters: orderedChapters,
                    stepsInChapter: _stepsForChapter(
                      orderedChapters[i],
                      orderedSteps,
                    ),
                    allSteps: orderedSteps,
                    globalDocument: globalDocument,
                    selectedStepId: selectedStepId,
                    canEdit: canEdit,
                    onRenameChapter: onRenameChapter,
                    onDeleteChapter: onDeleteChapter,
                    onMoveChapter: onMoveChapter,
                    onAddStepToChapter: onAddStepToChapter,
                    onRemoveStepFromChapter: onRemoveStepFromChapter,
                    onMoveStepInChapter: onMoveStepInChapter,
                    onSelectStep: onSelectStep,
                    onOpenStepStudio: onOpenStepStudio,
                    onSetEntryStep: onSetEntryStep,
                  ),
                ],
                const SizedBox(height: 14),
                const InspectorEmbeddedFootnote(
                  text:
                      'Macro : ordre des steps = onglet Step. Chapitres = regroupement pour le plan. '
                      'Branches exclusives / parallèles / conditionnelles / convergentes se configurent par step (inspecteur + suites globales).',
                  accent: EditorChrome.inspectorJoyCyan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<StepStudioStep> _stepsForChapter(
    GlobalStoryChapter chapter,
    List<StepStudioStep> orderedSteps,
  ) {
    final byId = {for (final s in orderedSteps) s.id: s};
    return chapter.stepIds
        .map((id) => byId[id])
        .whereType<StepStudioStep>()
        .toList(growable: false);
  }
}

class _MacroHeader extends StatelessWidget {
  const _MacroHeader({
    required this.globalStoryName,
    required this.chapterCount,
    required this.stepCount,
    required this.branchCount,
    required this.convergeCount,
    required this.hasUnsavedChanges,
    required this.canEdit,
    required this.onSave,
    required this.onReset,
    required this.onCreateStep,
  });

  final String globalStoryName;
  final int chapterCount;
  final int stepCount;
  final int branchCount;
  final int convergeCount;
  final bool hasUnsavedChanges;
  final bool canEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onCreateStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Story',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      globalStoryName,
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnsavedChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Modifié',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$chapterCount chapitre(s) · $stepCount step(s) dans ce scénario · '
            '$branchCount branche(s) · $convergeCount convergence(s)',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyAmber,
                  icon: CupertinoIcons.floppy_disk,
                  label: 'Sauvegarder',
                  prominent: true,
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.arrow_counterclockwise,
                  label: 'Réinitialiser',
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onReset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InspectorEmbeddedSecondaryCapsule(
            accent: EditorChrome.inspectorJoyMint,
            icon: CupertinoIcons.plus_circle,
            label: 'Nouvelle step (scénario global)',
            enabled: canEdit,
            onPressed: onCreateStep,
          ),
        ],
      ),
    );
  }
}

class _ProjectStepsSection extends StatelessWidget {
  const _ProjectStepsSection({
    required this.orderedSteps,
    required this.selectedStepId,
    required this.entryStepId,
    required this.canEdit,
    required this.chapterLabelForStep,
    required this.onSelectStep,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
  });

  final List<StepStudioStep> orderedSteps;
  final String? selectedStepId;
  final String entryStepId;
  final bool canEdit;
  final String? Function(String stepId) chapterLabelForStep;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String> onOpenStepStudio;
  final ValueChanged<String> onSetEntryStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.subtleLabel(context).withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.subtleLabel(context).withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Steps du projet (scénario global)',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            orderedSteps.isEmpty
                ? 'Aucune step : créez-en une ci-dessus ou depuis l’onglet Step.'
                : '${orderedSteps.length} step(s) — même liste que l’onglet Step.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (orderedSteps.isEmpty)
            Text(
              'Sans step, vous ne pouvez pas remplir les chapitres.',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...orderedSteps.map((step) {
              final placement = chapterLabelForStep(step.id);
              final placementLabel = placement != null
                  ? 'Chapitre : $placement'
                  : 'Non placée dans un chapitre';
              final isEntry = entryStepId == step.id;
              final selected = selectedStepId == step.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onSelectStep(step.id),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: selected
                            ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1)
                            : EditorChrome.subtleLabel(context)
                                .withValues(alpha: 0.03),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.45)
                            : EditorChrome.subtleLabel(context)
                                .withValues(alpha: 0.1),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEntry
                                  ? CupertinoIcons.location_solid
                                  : CupertinoIcons.circle,
                              size: 16,
                              color: isEntry
                                  ? EditorChrome.inspectorJoyMint
                                  : EditorChrome.subtleLabel(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#${step.order + 1} · ${step.name}',
                                style: TextStyle(
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          placementLabel,
                          style: TextStyle(
                            color: EditorChrome.subtleLabel(context),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InspectorEmbeddedSecondaryCapsule(
                                accent: EditorChrome.inspectorJoyPlum,
                                icon: CupertinoIcons.square_stack_3d_up,
                                label: 'Ouvrir Step',
                                enabled: canEdit,
                                onPressed: () => onOpenStepStudio(step.id),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: InspectorEmbeddedSecondaryCapsule(
                                accent: EditorChrome.inspectorJoyMint,
                                icon: CupertinoIcons.location,
                                label: isEntry ? 'Départ' : 'Définir départ',
                                enabled: canEdit && !isEntry,
                                onPressed: () => onSetEntryStep(step.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _BranchTypesLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.subtleLabel(context).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Types de branches (rappel)',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A. Exclusive — une route parmi plusieurs.\n'
            'B. Parallèle — plusieurs arcs actifs.\n'
            'C. Conditionnelle — ouverture si condition vraie.\n'
            'D. Convergente — chemins distincts qui rejoignent un point.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _macroChapterDisplayName(GlobalStoryChapter c) {
  final n = c.name.trim();
  if (n.isNotEmpty) return n;
  final id = c.id.trim();
  if (id.isNotEmpty) return id;
  return 'Chapitre';
}

String? _macroOtherChapterNameForStep(
  String stepId,
  List<GlobalStoryChapter> chapters,
  String excludeChapterId,
) {
  for (final c in chapters) {
    if (c.id == excludeChapterId) continue;
    if (c.stepIds.contains(stepId)) {
      return _macroChapterDisplayName(c);
    }
  }
  return null;
}

class _ChapterMacroCard extends StatelessWidget {
  const _ChapterMacroCard({
    required this.chapter,
    required this.chapterIndex,
    required this.totalChapters,
    required this.allChapters,
    required this.stepsInChapter,
    required this.allSteps,
    required this.globalDocument,
    required this.selectedStepId,
    required this.canEdit,
    required this.onRenameChapter,
    required this.onDeleteChapter,
    required this.onMoveChapter,
    required this.onAddStepToChapter,
    required this.onRemoveStepFromChapter,
    required this.onMoveStepInChapter,
    required this.onSelectStep,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
  });

  final GlobalStoryChapter chapter;
  final int chapterIndex;
  final int totalChapters;
  final List<GlobalStoryChapter> allChapters;
  final List<StepStudioStep> stepsInChapter;
  final List<StepStudioStep> allSteps;
  final GlobalStoryStudioDocument globalDocument;
  final String? selectedStepId;
  final bool canEdit;
  final void Function(String chapterId, String name) onRenameChapter;
  final void Function(String chapterId) onDeleteChapter;
  final void Function(String chapterId, int delta) onMoveChapter;
  final void Function(String chapterId, String stepId) onAddStepToChapter;
  final void Function(String chapterId, String stepId) onRemoveStepFromChapter;
  final void Function(String chapterId, int fromIndex, int toIndex)
      onMoveStepInChapter;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String> onOpenStepStudio;
  final ValueChanged<String> onSetEntryStep;

  Future<void> _pickStepToAdd(BuildContext context) async {
    final addable = allSteps
        .where((s) => !chapter.stepIds.contains(s.id))
        .toList(growable: false);
    if (addable.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucune step à ajouter',
        message:
            'Toutes les steps du scénario sont déjà dans ce chapitre. '
            'Créez une nouvelle step via « Nouvelle step (scénario global) » ou l’onglet Step.',
        okLabel: 'OK',
      );
      return;
    }
    final selected = await showMacosListPicker<StepStudioStep>(
      context: context,
      title:
          'Ajouter au chapitre « ${_macroChapterDisplayName(chapter)} »',
      items: addable,
      labelOf: (step) {
        final other = _macroOtherChapterNameForStep(
          step.id,
          allChapters,
          chapter.id,
        );
        final base = '#${step.order + 1}. ${step.name}';
        if (other != null) {
          return '$base — actuellement : $other';
        }
        return base;
      },
    );
    if (selected != null) {
      onAddStepToChapter(chapter.id, selected.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canMoveUp = chapterIndex > 0;
    final canMoveDown = chapterIndex < totalChapters - 1;

    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                  color:
                      EditorChrome.inspectorJoyPlum.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CH.${chapterIndex + 1}',
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyPlum,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChapterTitleField(
                  key: ValueKey('macro_chapter_title_${chapter.id}'),
                  chapterId: chapter.id,
                  name: chapter.name,
                  enabled: canEdit,
                  onCommit: onRenameChapter,
                ),
              ),
              if (canEdit) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed:
                      canMoveUp ? () => onMoveChapter(chapter.id, -1) : null,
                  child: Icon(
                    CupertinoIcons.chevron_up,
                    size: 18,
                    color: EditorChrome.inspectorJoyPlum,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed:
                      canMoveDown ? () => onMoveChapter(chapter.id, 1) : null,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: EditorChrome.inspectorJoyPlum,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: () => onDeleteChapter(chapter.id),
                  child: Icon(
                    CupertinoIcons.delete,
                    size: 18,
                    color: EditorChrome.inspectorJoyCoral,
                  ),
                ),
              ],
            ],
          ),
          if (chapter.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              chapter.description,
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${stepsInChapter.length} step(s) dans ce chapitre',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          if (stepsInChapter.isEmpty)
            Text(
              'Ajoutez des steps depuis le bouton ci-dessous (liste complète du projet).',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (var i = 0; i < stepsInChapter.length; i++) ...[
              _ChapterStepRow(
                step: stepsInChapter[i],
                node: _nodeFor(stepsInChapter[i].id),
                isEntry: globalDocument.entryStepId == stepsInChapter[i].id,
                isSelected: selectedStepId == stepsInChapter[i].id,
                canEdit: canEdit,
                canMoveUp: i > 0,
                canMoveDown: i < stepsInChapter.length - 1,
                onSelect: () => onSelectStep(stepsInChapter[i].id),
                onOpenStepStudio: () => onOpenStepStudio(stepsInChapter[i].id),
                onSetEntry: () => onSetEntryStep(stepsInChapter[i].id),
                onRemove: () =>
                    onRemoveStepFromChapter(chapter.id, stepsInChapter[i].id),
                onMoveUp: () =>
                    onMoveStepInChapter(chapter.id, i, i - 1),
                onMoveDown: () =>
                    onMoveStepInChapter(chapter.id, i, i + 1),
              ),
              if (i < stepsInChapter.length - 1) const SizedBox(height: 4),
            ],
          const SizedBox(height: 8),
          InspectorEmbeddedSecondaryCapsule(
            key: ValueKey<String>('macro_add_step_to_chapter_${chapter.id}'),
            accent: EditorChrome.inspectorJoyMint,
            icon: CupertinoIcons.plus_circled,
            label: 'Ajouter une step au chapitre…',
            enabled: canEdit && allSteps.isNotEmpty,
            onPressed: () => _pickStepToAdd(context),
          ),
        ],
      ),
    );
  }

  GlobalStoryStepNode _nodeFor(String stepId) {
    for (final n in globalDocument.nodes) {
      if (n.stepId == stepId) {
        return n;
      }
    }
    return GlobalStoryStepNode(stepId: stepId);
  }
}

class _ChapterTitleField extends StatefulWidget {
  const _ChapterTitleField({
    super.key,
    required this.chapterId,
    required this.name,
    required this.enabled,
    required this.onCommit,
  });

  final String chapterId;
  final String name;
  final bool enabled;
  final void Function(String chapterId, String name) onCommit;

  @override
  State<_ChapterTitleField> createState() => _ChapterTitleFieldState();
}

class _ChapterTitleFieldState extends State<_ChapterTitleField> {
  late TextEditingController _controller;
  late String _lastCommitted;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
    _lastCommitted = widget.name;
  }

  @override
  void didUpdateWidget(covariant _ChapterTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && widget.name != _lastCommitted) {
      _controller.text = widget.name;
      _lastCommitted = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isEmpty || t == _lastCommitted) {
      return;
    }
    _lastCommitted = t;
    widget.onCommit(widget.chapterId, t);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Text(
        widget.name,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return CupertinoTextField(
      key: ValueKey('macro_chapter_name_${widget.chapterId}'),
      controller: _controller,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.05),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      placeholder: 'Nom du chapitre',
      onSubmitted: (_) => _submit(),
      onEditingComplete: _submit,
    );
  }
}

class _ChapterStepRow extends StatelessWidget {
  const _ChapterStepRow({
    required this.step,
    required this.node,
    required this.isEntry,
    required this.isSelected,
    required this.canEdit,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onSelect,
    required this.onOpenStepStudio,
    required this.onSetEntry,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final StepStudioStep step;
  final GlobalStoryStepNode node;
  final bool isEntry;
  final bool isSelected;
  final bool canEdit;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onSelect;
  final VoidCallback onOpenStepStudio;
  final VoidCallback onSetEntry;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final exitLabel = globalStoryStepExitModeLabel(node.exitMode);
    return GestureDetector(
      onTap: onSelect,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: isSelected
                ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.08)
                : EditorChrome.subtleLabel(context).withValues(alpha: 0.03),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.4)
                : EditorChrome.subtleLabel(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isEntry
                      ? CupertinoIcons.location_solid
                      : CupertinoIcons.square_list,
                  size: 15,
                  color: isEntry
                      ? EditorChrome.inspectorJoyMint
                      : EditorChrome.subtleLabel(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '#${step.order + 1} · ${step.name}',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canEdit) ...[
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 26,
                    onPressed: canMoveUp ? onMoveUp : null,
                    child: Icon(
                      CupertinoIcons.arrow_up,
                      size: 16,
                      color: EditorChrome.inspectorJoyPlum,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 26,
                    onPressed: canMoveDown ? onMoveDown : null,
                    child: Icon(
                      CupertinoIcons.arrow_down,
                      size: 16,
                      color: EditorChrome.inspectorJoyPlum,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 26,
                    onPressed: onRemove,
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 16,
                      color: EditorChrome.inspectorJoyCoral,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$exitLabel · ${node.links.length} suite(s)',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyPlum,
                    icon: CupertinoIcons.square_stack_3d_up,
                    label: 'Ouvrir Step',
                    enabled: canEdit,
                    onPressed: onOpenStepStudio,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyMint,
                    icon: CupertinoIcons.location,
                    label: isEntry ? 'Step de départ' : 'Définir départ',
                    enabled: canEdit && !isEntry,
                    onPressed: onSetEntry,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfoBanner extends StatelessWidget {
  const _InlineInfoBanner({
    required this.accent,
    required this.text,
  });

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.info, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
