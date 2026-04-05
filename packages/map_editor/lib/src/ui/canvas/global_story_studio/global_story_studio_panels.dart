// ---------------------------------------------------------------------------
// Panneaux UI du Global Story Studio (top bar, nav, flux, détail)
// ---------------------------------------------------------------------------
//
// Tous les widgets publics de ce fichier sont des **composants de présentation** :
// ils ne mutent pas le projet directement — ils appellent des callbacks fournis
// par [GlobalStoryStudioShell] / le workspace.
//
// Style : chrome éditorial sobre (nuances de gris, typographie hiérarchisée),
// aligné sur [EditorChrome] pour rester cohérent avec le reste de l’éditeur PokeMap.
//
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider, Tooltip;

import '../../../features/narrative/application/global_story_studio_authoring.dart';
import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../features/narrative/application/step_studio_authoring.dart';
import '../../shared/cupertino_editor_widgets.dart';
import 'global_story_flow_layout.dart';

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

/// Barre supérieure : fil d’Ariane produit, sélecteur de filière, actions principales.
///
/// UX : les actions les plus fréquentes sont à droite, zone standard macOS / desktop.
/// « Valider » = persister le brouillon (même hook que l’ancien « Sauvegarder »).
/// « Tester » est volontairement désactivé : la boucle playtest globale sera branchée plus tard.
class GlobalStoryStudioTopBar extends StatelessWidget {
  const GlobalStoryStudioTopBar({
    super.key,
    required this.storylineChoices,
    required this.selectedStorylineId,
    required this.onSelectStoryline,
    required this.hasUnsavedChanges,
    required this.canEdit,
    required this.onSave,
    required this.onReset,
    required this.onCreateStep,
  });

  final List<({String id, String label})> storylineChoices;
  final String? selectedStorylineId;
  final ValueChanged<String?> onSelectStoryline;
  final bool hasUnsavedChanges;
  final bool canEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onCreateStep;

  @override
  Widget build(BuildContext context) {
    final border = EditorChrome.subtleLabel(context).withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // Partie gauche : fil d’Ariane + filière — scroll horizontal si fenêtre étroite.
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Studio narratif',
                    style: TextStyle(
                      color: EditorChrome.subtleLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '›',
                      style: TextStyle(color: EditorChrome.subtleLabel(context)),
                    ),
                  ),
                  Text(
                    'Histoire globale',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                      color: EditorChrome.subtleLabel(context)
                          .withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.book,
                          size: 16,
                          color: EditorChrome.subtleLabel(context),
                        ),
                        const SizedBox(width: 8),
                        CupertinoPickerScaffold(
                          choices: storylineChoices,
                          selectedId: selectedStorylineId,
                          onChanged: onSelectStoryline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Actions : zone bornée + scroll — sans [Expanded] le second enfant du [Row]
          // demande une largeur infinie et provoque un overflow.
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                if (hasUnsavedChanges)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Modifications non enregistrées',
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _TopBarTextButton(
                  label: 'Réinitialiser',
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onReset,
                ),
                const SizedBox(width: 8),
                _TopBarTextButton(
                  label: 'Tester',
                  enabled: false,
                  onPressed: () {},
                  hint: 'Lecture test globale — bientôt disponible.',
                ),
                const SizedBox(width: 8),
                _TopBarPrimaryButton(
                  label: 'Valider',
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onSave,
                ),
                const SizedBox(width: 10),
                _TopBarPrimaryButton(
                  label: '+ Nouvelle étape',
                  enabled: canEdit,
                  onPressed: onCreateStep,
                  filled: true,
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picker compact sans dépendre de `DropdownButton` Material (cohérence Cupertino/macOS).
class CupertinoPickerScaffold extends StatelessWidget {
  const CupertinoPickerScaffold({
    super.key,
    required this.choices,
    required this.selectedId,
    required this.onChanged,
  });

  final List<({String id, String label})> choices;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = choices.cast<({String id, String label})?>().firstWhere(
          (e) => e!.id == selectedId,
          orElse: () => choices.isEmpty ? null : choices.first,
        );
    final label = current?.label ?? '—';
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minSize: 0,
      onPressed: choices.length <= 1
          ? null
          : () async {
              final chosen = await showMenuPicker(
                context: context,
                title: 'Filière narrative',
                choices: choices,
                selectedId: selectedId,
              );
              if (chosen != null) {
                onChanged(chosen);
              }
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (choices.length > 1) ...[
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: EditorChrome.subtleLabel(context),
            ),
          ],
        ],
      ),
    );
  }
}

Future<String?> showMenuPicker({
  required BuildContext context,
  required String title,
  required List<({String id, String label})> choices,
  required String? selectedId,
}) async {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) {
      return CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final c in choices)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, c.id),
              child: Text(c.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
      );
    },
  );
}

class _TopBarTextButton extends StatelessWidget {
  const _TopBarTextButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.hint,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final child = CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      minSize: 0,
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          color: enabled
              ? EditorChrome.primaryLabel(context)
              : EditorChrome.subtleLabel(context),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
    if (hint != null && !enabled) {
      return Tooltip(message: hint!, child: child);
    }
    return child;
  }
}

class _TopBarPrimaryButton extends StatelessWidget {
  const _TopBarPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled
        ? CupertinoColors.white
        : (enabled
            ? EditorChrome.inspectorJoyMint
            : EditorChrome.subtleLabel(context));
    final bg = filled
        ? (enabled
            ? EditorChrome.inspectorJoyMint
            : EditorChrome.subtleLabel(context).withValues(alpha: 0.25))
        : Colors.transparent;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      minSize: 0,
      color: bg,
      borderRadius: BorderRadius.circular(8),
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation gauche
// ---------------------------------------------------------------------------

/// Colonne de navigation : chapitres / regroupements + étapes imbriquées.
///
/// Rôle produit : permettre de **se repérer** et de sauter rapidement à une étape
/// sans dépendre du scroll du flux central.
String _navChapterDisplayName(GlobalStoryChapter c) {
  final n = c.name.trim();
  if (n.isNotEmpty) {
    return n;
  }
  final id = c.id.trim();
  return id.isNotEmpty ? id : 'Sans titre';
}

String? _navOtherChapterForStep(
  String stepId,
  List<GlobalStoryChapter> chapters,
  String excludeChapterId,
) {
  for (final c in chapters) {
    if (c.id == excludeChapterId) {
      continue;
    }
    if (c.stepIds.contains(stepId)) {
      return _navChapterDisplayName(c);
    }
  }
  return null;
}

class GlobalStoryNavPanel extends StatelessWidget {
  const GlobalStoryNavPanel({
    super.key,
    required this.chapters,
    required this.orderedSteps,
    required this.globalDocument,
    required this.selectedStepId,
    required this.entryStepId,
    required this.canEdit,
    required this.statsLine,
    required this.onSelectStep,
    required this.onAddChapter,
    required this.onRenameChapter,
    required this.onDeleteChapter,
    required this.onMoveChapter,
    required this.onAddStepToChapter,
    required this.onRemoveStepFromChapter,
    required this.onMoveStepInChapter,
  });

  final List<GlobalStoryChapter> chapters;
  final List<StepStudioStep> orderedSteps;
  final GlobalStoryStudioDocument globalDocument;
  final String? selectedStepId;
  final String entryStepId;
  final bool canEdit;
  final String statsLine;

  final ValueChanged<String?> onSelectStep;
  final VoidCallback onAddChapter;
  final void Function(String chapterId, String name) onRenameChapter;
  final void Function(String chapterId) onDeleteChapter;
  final void Function(String chapterId, int delta) onMoveChapter;
  final void Function(String chapterId, String stepId) onAddStepToChapter;
  final void Function(String chapterId, String stepId) onRemoveStepFromChapter;
  final void Function(String chapterId, int fromIndex, int toIndex)
      onMoveStepInChapter;

  @override
  Widget build(BuildContext context) {
    final border = EditorChrome.subtleLabel(context).withValues(alpha: 0.14);
    final orderedChapters = chapters.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final stepById = {for (final s in orderedSteps) s.id: s};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STRUCTURE',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre récit',
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statsLine,
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              itemCount: orderedChapters.length + 1,
              itemBuilder: (context, index) {
                if (index == orderedChapters.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: canEdit ? onAddChapter : null,
                      child: const Text(
                        'Nouveau chapitre',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                final ch = orderedChapters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NavChapterCard(
                    key: ValueKey<String>(ch.id),
                    chapter: ch,
                    allChapters: orderedChapters,
                    chapterIndex: index,
                    totalChapters: orderedChapters.length,
                    stepById: stepById,
                    selectedStepId: selectedStepId,
                    entryStepId: entryStepId,
                    canEdit: canEdit,
                    onSelectStep: onSelectStep,
                    onRenameChapter: onRenameChapter,
                    onDeleteChapter: onDeleteChapter,
                    onMoveChapter: onMoveChapter,
                    onAddStepToChapter: onAddStepToChapter,
                    onRemoveStepFromChapter: onRemoveStepFromChapter,
                    onMoveStepInChapter: onMoveStepInChapter,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavChapterCard extends StatefulWidget {
  const _NavChapterCard({
    super.key,
    required this.chapter,
    required this.allChapters,
    required this.chapterIndex,
    required this.totalChapters,
    required this.stepById,
    required this.selectedStepId,
    required this.entryStepId,
    required this.canEdit,
    required this.onSelectStep,
    required this.onRenameChapter,
    required this.onDeleteChapter,
    required this.onMoveChapter,
    required this.onAddStepToChapter,
    required this.onRemoveStepFromChapter,
    required this.onMoveStepInChapter,
  });

  final GlobalStoryChapter chapter;
  final List<GlobalStoryChapter> allChapters;
  final int chapterIndex;
  final int totalChapters;
  final Map<String, StepStudioStep> stepById;
  final String? selectedStepId;
  final String entryStepId;
  final bool canEdit;

  final ValueChanged<String?> onSelectStep;
  final void Function(String chapterId, String name) onRenameChapter;
  final void Function(String chapterId) onDeleteChapter;
  final void Function(String chapterId, int delta) onMoveChapter;
  final void Function(String chapterId, String stepId) onAddStepToChapter;
  final void Function(String chapterId, String stepId) onRemoveStepFromChapter;
  final void Function(String chapterId, int fromIndex, int toIndex)
      onMoveStepInChapter;

  @override
  State<_NavChapterCard> createState() => _NavChapterCardState();
}

class _NavChapterCardState extends State<_NavChapterCard> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter.name);
  }

  @override
  void didUpdateWidget(covariant _NavChapterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le nom a changé côté document (ex. undo) et que le champ n’a pas été
    // édité localement différemment, on resynchronise le contrôleur.
    if (oldWidget.chapter.name != widget.chapter.name &&
        _titleController.text.trim() == oldWidget.chapter.name.trim()) {
      _titleController.text = widget.chapter.name;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = EditorChrome.inspectorJoyPlum;
    final chapter = widget.chapter;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        color: accent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'CH.${widget.chapterIndex + 1}',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  key: ValueKey<String>('macro_chapter_name_${chapter.id}'),
                  controller: _titleController,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: EditorChrome.subtleLabel(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onSubmitted: (v) => widget.onRenameChapter(chapter.id, v.trim()),
                ),
              ),
              if (widget.canEdit) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 26,
                  onPressed: widget.chapterIndex > 0
                      ? () => widget.onMoveChapter(chapter.id, -1)
                      : null,
                  child: Icon(CupertinoIcons.chevron_up, size: 16, color: accent),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 26,
                  onPressed: widget.chapterIndex < widget.totalChapters - 1
                      ? () => widget.onMoveChapter(chapter.id, 1)
                      : null,
                  child: Icon(CupertinoIcons.chevron_down, size: 16, color: accent),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 26,
                  onPressed: () => widget.onDeleteChapter(chapter.id),
                  child: Icon(CupertinoIcons.trash, size: 16, color: accent),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < chapter.stepIds.length; i++) ...[
            _NavStepRow(
              stepId: chapter.stepIds[i],
              step: widget.stepById[chapter.stepIds[i]],
              selected: widget.selectedStepId == chapter.stepIds[i],
              isEntry: widget.entryStepId == chapter.stepIds[i],
              canEdit: widget.canEdit,
              onTap: () => widget.onSelectStep(chapter.stepIds[i]),
              onMoveUp: i > 0
                  ? () => widget.onMoveStepInChapter(chapter.id, i, i - 1)
                  : null,
              onMoveDown: i < chapter.stepIds.length - 1
                  ? () => widget.onMoveStepInChapter(chapter.id, i, i + 1)
                  : null,
              onRemove: () =>
                  widget.onRemoveStepFromChapter(chapter.id, chapter.stepIds[i]),
            ),
            if (i < chapter.stepIds.length - 1) const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
          CupertinoButton(
            key: ValueKey<String>('macro_add_step_to_chapter_${chapter.id}'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            onPressed: widget.canEdit
                ? () => _pickStepToAddToChapter(context, chapter)
                : null,
            child: Text(
              '+ Ajouter une étape à ce chapitre…',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStepToAddToChapter(
    BuildContext context,
    GlobalStoryChapter chapter,
  ) async {
    final addable = widget.stepById.values
        .where((s) => !chapter.stepIds.contains(s.id))
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    if (addable.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucune étape à ajouter',
        message:
            'Toutes les étapes du scénario sont déjà dans ce chapitre. '
            'Créez une nouvelle étape avec « + Nouvelle étape » en haut à droite.',
        okLabel: 'OK',
      );
      return;
    }
    final selected = await showMacosListPicker<StepStudioStep>(
      context: context,
      title: 'Ajouter au chapitre « ${chapter.name.trim().isEmpty ? 'Sans titre' : chapter.name.trim()} »',
      items: addable,
      labelOf: (s) {
        final other = _navOtherChapterForStep(
          s.id,
          widget.allChapters,
          chapter.id,
        );
        final base = '#${s.order + 1}. ${s.name}';
        if (other != null) {
          return '$base — actuellement : $other';
        }
        return base;
      },
    );
    if (selected != null) {
      widget.onAddStepToChapter(chapter.id, selected.id);
    }
  }
}

class _NavStepRow extends StatelessWidget {
  const _NavStepRow({
    required this.stepId,
    required this.step,
    required this.selected,
    required this.isEntry,
    required this.canEdit,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final String stepId;
  final StepStudioStep? step;
  final bool selected;
  final bool isEntry;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = step?.name.trim().isNotEmpty == true ? step!.name : stepId;
    final bg = selected
        ? EditorChrome.inspectorJoyMint.withValues(alpha: 0.18)
        : EditorChrome.subtleLabel(context).withValues(alpha: 0.06);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? EditorChrome.inspectorJoyMint.withValues(alpha: 0.45)
                : EditorChrome.subtleLabel(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            if (isEntry)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  CupertinoIcons.location_solid,
                  size: 14,
                  color: EditorChrome.inspectorJoyMint,
                ),
              ),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (canEdit) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 24,
                onPressed: onMoveUp,
                child: Icon(
                  CupertinoIcons.chevron_up,
                  size: 14,
                  color: EditorChrome.subtleLabel(context),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 24,
                onPressed: onMoveDown,
                child: Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: EditorChrome.subtleLabel(context),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 24,
                onPressed: onRemove,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: EditorChrome.subtleLabel(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Story flow central
// ---------------------------------------------------------------------------

/// Panneau central : rend les blocs calculés par [buildGlobalStoryFlowBlocks].
class GlobalStoryFlowPanel extends StatelessWidget {
  const GlobalStoryFlowPanel({
    super.key,
    required this.flowBlocks,
    required this.orderedSteps,
    required this.globalDocument,
    required this.selectedStepId,
    required this.entryStepId,
    required this.onSelectStep,
  });

  final List<GlobalStoryFlowBlock> flowBlocks;
  final List<StepStudioStep> orderedSteps;
  final GlobalStoryStudioDocument globalDocument;
  final String? selectedStepId;
  final String entryStepId;
  final ValueChanged<String?> onSelectStep;

  @override
  Widget build(BuildContext context) {
    final border = EditorChrome.subtleLabel(context).withValues(alpha: 0.14);
    final nodeById = {for (final n in globalDocument.nodes) n.stepId: n};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIL NARRATIF',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progression globale',
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lecture de haut en bas. Les embranchements s’ouvrent sur le côté, puis le récit se referme sur une étape commune lorsque c’est possible.',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      for (var i = 0; i < flowBlocks.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _FlowBlockWidget(
                          block: flowBlocks[i],
                          orderedSteps: orderedSteps,
                          nodeById: nodeById,
                          selectedStepId: selectedStepId,
                          entryStepId: entryStepId,
                          onSelectStep: onSelectStep,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowBlockWidget extends StatelessWidget {
  const _FlowBlockWidget({
    required this.block,
    required this.orderedSteps,
    required this.nodeById,
    required this.selectedStepId,
    required this.entryStepId,
    required this.onSelectStep,
  });

  final GlobalStoryFlowBlock block;
  final List<StepStudioStep> orderedSteps;
  final Map<String, GlobalStoryStepNode> nodeById;
  final String? selectedStepId;
  final String entryStepId;
  final ValueChanged<String?> onSelectStep;

  @override
  Widget build(BuildContext context) {
    if (block is GlobalStoryFlowNoticeBlock) {
      final n = block as GlobalStoryFlowNoticeBlock;
      return _NoticeCard(message: n.message);
    }
    if (block is GlobalStoryFlowLinearBlock) {
      final b = block as GlobalStoryFlowLinearBlock;
      return Column(
        children: [
          for (var j = 0; j < b.steps.length; j++) ...[
            if (j > 0) _FlowConnector(),
            _FlowStepCard(
              key: ValueKey<String>('gss_flow_linear_${b.steps[j].stepId}'),
              stepId: b.steps[j].stepId,
              step: _findStep(b.steps[j].stepId),
              node: nodeById[b.steps[j].stepId],
              outgoingHints: b.steps[j].outgoingLabels,
              selected: selectedStepId == b.steps[j].stepId,
              isEntry: entryStepId == b.steps[j].stepId,
              onTap: () => onSelectStep(b.steps[j].stepId),
            ),
          ],
        ],
      );
    }
    if (block is GlobalStoryFlowBranchBlock) {
      final b = block as GlobalStoryFlowBranchBlock;
      return Column(
        children: [
          _FlowStepCard(
            key: ValueKey<String>('gss_flow_branch_${b.branchPointStepId}'),
            stepId: b.branchPointStepId,
            step: _findStep(b.branchPointStepId),
            node: nodeById[b.branchPointStepId],
            outgoingHints: const [],
            selected: selectedStepId == b.branchPointStepId,
            isEntry: entryStepId == b.branchPointStepId,
            onTap: () => onSelectStep(b.branchPointStepId),
            subtitle: 'Plusieurs chemins possibles',
          ),
          _FlowConnector(label: 'embranchement'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var a = 0; a < b.arms.length; a++) ...[
                  if (a > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          b.arms[a].linkLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: EditorChrome.subtleLabel(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (var k = 0; k < b.arms[a].stepIds.length; k++) ...[
                          if (k > 0) _FlowConnector(height: 18),
                          _FlowStepCard(
                            key: ValueKey<String>(
                              'gss_flow_arm_${b.arms[a].stepIds[k]}_$a',
                            ),
                            stepId: b.arms[a].stepIds[k],
                            step: _findStep(b.arms[a].stepIds[k]),
                            node: nodeById[b.arms[a].stepIds[k]],
                            outgoingHints: const [],
                            compact: true,
                            selected: selectedStepId == b.arms[a].stepIds[k],
                            isEntry: entryStepId == b.arms[a].stepIds[k],
                            onTap: () => onSelectStep(b.arms[a].stepIds[k]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (b.mergeStepId != null) ...[
            _FlowConnector(label: 'convergence'),
            _FlowStepCard(
              key: ValueKey<String>('gss_flow_merge_${b.mergeStepId}'),
              stepId: b.mergeStepId!,
              step: _findStep(b.mergeStepId!),
              node: nodeById[b.mergeStepId!],
              outgoingHints: const [],
              selected: selectedStepId == b.mergeStepId!,
              isEntry: entryStepId == b.mergeStepId!,
              onTap: () => onSelectStep(b.mergeStepId!),
              subtitle: 'Les chemins se rejoignent ici',
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  StepStudioStep? _findStep(String id) {
    for (final s in orderedSteps) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.12),
        border: Border.all(
          color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({this.label, this.height = 22});

  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final line = EditorChrome.subtleLabel(context).withValues(alpha: 0.35);
    return SizedBox(
      height: height + (label != null ? 18 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 2, height: height * 0.45, color: line),
          if (label != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: EditorChrome.subtleLabel(context),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Container(width: 2, height: height * 0.45, color: line),
        ],
      ),
    );
  }
}

class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({
    super.key,
    required this.stepId,
    required this.step,
    required this.node,
    required this.outgoingHints,
    required this.selected,
    required this.isEntry,
    required this.onTap,
    this.subtitle,
    this.compact = false,
  });

  final String stepId;
  final StepStudioStep? step;
  final GlobalStoryStepNode? node;
  final List<String> outgoingHints;
  final bool selected;
  final bool isEntry;
  final VoidCallback onTap;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = step?.name.trim().isNotEmpty == true ? step!.name : stepId;
    final desc = step?.description.trim() ?? '';
    final badge = _productBadgeLabel(node, isEntry);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          color: selected
              ? CupertinoColors.white.withValues(alpha: 0.08)
              : CupertinoColors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? EditorChrome.inspectorJoyMint.withValues(alpha: 0.55)
                : EditorChrome.subtleLabel(context).withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: compact ? 6 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Colonnes d’embranchement très étroites : pas de [Row] titre+badge.
            final narrow = compact || constraints.maxWidth < 168;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (narrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEntry)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(
                            CupertinoIcons.location_solid,
                            size: 14,
                            color: EditorChrome.inspectorJoyMint,
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: EditorChrome.subtleLabel(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (isEntry) ...[
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 16,
                          color: EditorChrome.inspectorJoyMint,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: EditorChrome.primaryLabel(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: EditorChrome.subtleLabel(context)
                              .withValues(alpha: 0.12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: EditorChrome.subtleLabel(context),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (desc.isNotEmpty && !compact) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
            if (outgoingHints.isNotEmpty && !compact) ...[
              const SizedBox(height: 10),
              Text(
                'En sortie',
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              for (final h in outgoingHints.take(4))
                Text(
                  '· $h',
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context).withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
            ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _productBadgeLabel(GlobalStoryStepNode? node, bool isEntry) {
  if (isEntry) {
    return 'Départ';
  }
  if (node == null) {
    return 'À compléter';
  }
  return switch (node.exitMode) {
    GlobalStoryStepExitMode.linear => 'Étape principale',
    GlobalStoryStepExitMode.branchExclusive => 'Embranchement',
    GlobalStoryStepExitMode.branchConditional => 'Conditionnelle',
    GlobalStoryStepExitMode.converge => 'Convergence',
  };
}

// ---------------------------------------------------------------------------
// Détail droite
// ---------------------------------------------------------------------------

/// Inspecteur « métier » de l’étape sélectionnée (pas d’édition de cutscene ici).
class GlobalStoryStepDetailPanel extends StatelessWidget {
  const GlobalStoryStepDetailPanel({
    super.key,
    required this.step,
    required this.node,
    required this.projection,
    required this.allSteps,
    required this.entryStepId,
    required this.canEdit,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
  });

  final StepStudioStep? step;
  final GlobalStoryStepNode? node;
  final NarrativeStepSummary? projection;
  final List<StepStudioStep> allSteps;
  final String entryStepId;
  final bool canEdit;
  final ValueChanged<String> onOpenStepStudio;
  final ValueChanged<String> onSetEntryStep;

  @override
  Widget build(BuildContext context) {
    final border = EditorChrome.subtleLabel(context).withValues(alpha: 0.14);
    if (step == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Sélectionnez une étape dans la structure ou dans le fil narratif '
              'pour voir ce qu’elle débloque et comment elle s’insère dans l’histoire.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    final s = step!;
    final n = node;
    final proj = projection;
    final activationLine = _activationHumanLine(s, allSteps);
    final outcomes = s.outcomes;
    final nextSteps = <String>[];
    if (n != null) {
      for (final link in n.links) {
        final name = _nameForStepId(link.toStepId, allSteps);
        nextSteps.add(name);
      }
    }

    final cutsceneCount = s.cutscenes.length;
    final isEntry = s.id == entryStepId;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DÉTAIL DE L’ÉTAPE',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.name.trim().isEmpty ? s.id : s.name,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _productBadgeLabel(n, isEntry),
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyMint,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                _DetailSection(
                  title: 'Entrée',
                  lines: [activationLine],
                ),
                if (outcomes.isNotEmpty)
                  _DetailSection(
                    title: 'Résultats narratifs possibles',
                    lines: [
                      for (final o in outcomes)
                        o.label.trim().isNotEmpty ? o.label : o.outcomeId,
                    ],
                  ),
                if (proj != null && proj.worldChangeCount > 0)
                  _DetailSection(
                    title: 'Changements dans le monde',
                    lines: [
                      '${proj.worldChangeCount} effet(s) lié(s) à cette étape (vue projection).',
                    ],
                  ),
                if (nextSteps.isNotEmpty)
                  _DetailSection(
                    title: 'Débloque / mène à',
                    lines: nextSteps,
                  )
                else
                  _DetailSection(
                    title: 'Débloque / mène à',
                    lines: const ['Fin de ce fil pour l’instant'],
                  ),
                _DetailSection(
                  title: 'Scènes liées',
                  lines: [
                    cutsceneCount == 0
                        ? 'Aucune cutscene listée sur cette étape pour le moment.'
                        : '$cutsceneCount scène(s) liée(s) — ouvrez l’étape pour les parcourir.',
                  ],
                ),
                if (proj != null && proj.activationSummary.isNotEmpty)
                  _DetailSection(
                    title: 'Rappel automatique',
                    lines: [proj.activationSummary],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: EditorChrome.subtleLabel(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => onOpenStepStudio(s.id),
                        child: const Text(
                          'Ouvrir Step',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: EditorChrome.subtleLabel(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: cutsceneCount == 0
                            ? null
                            : () => onOpenStepStudio(s.id),
                        child: Text(
                          'Voir cutscenes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cutsceneCount == 0
                                ? EditorChrome.subtleLabel(context)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isEntry && canEdit) ...[
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => onSetEntryStep(s.id),
                    child: Text(
                      'Définir comme point de départ du jeu',
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyPlum,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $line',
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _activationHumanLine(StepStudioStep s, List<StepStudioStep> allSteps) {
  final rule = s.activation;
  switch (rule.mode) {
    case StepStudioActivationMode.atGameStart:
      return 'Dès le début du jeu';
    case StepStudioActivationMode.afterPreviousStep:
      return 'Après l’étape précédente dans l’ordre du scénario';
    case StepStudioActivationMode.afterStep:
      final name = rule.stepId != null ? _nameForStepId(rule.stepId!, allSteps) : 'une étape précise';
      return 'Après : $name';
    case StepStudioActivationMode.afterOutcome:
      return 'Après un résultat de progression';
    case StepStudioActivationMode.afterCutscene:
      return 'Après une scène jouée';
    case StepStudioActivationMode.whenFlagTrue:
      return 'Quand un état du monde est atteint';
  }
}

String _nameForStepId(String id, List<StepStudioStep> allSteps) {
  for (final s in allSteps) {
    if (s.id == id) {
      return s.name.trim().isEmpty ? id : s.name;
    }
  }
  return id;
}
