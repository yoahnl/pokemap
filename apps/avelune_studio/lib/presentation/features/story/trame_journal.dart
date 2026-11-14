import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameMilestoneJournal extends StatefulWidget {
  const TrameMilestoneJournal({
    super.key,
    required this.trame,
    required this.storylineId,
    required this.chapterId,
    required this.milestoneId,
    required this.milestoneTitle,
  });

  final StorylineTrameController trame;
  final String storylineId;
  final String chapterId;
  final String milestoneId;
  final String milestoneTitle;

  @override
  State<TrameMilestoneJournal> createState() => _TrameMilestoneJournalState();
}

class _TrameMilestoneJournalState extends State<TrameMilestoneJournal> {
  String? _title;
  String? _text;

  StorylineTrameController get _trame => widget.trame;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_trame.ensureStorylines);
  }

  StorylineMilestoneJournal? get _journal => _trame
      .fullMilestone(widget.storylineId, widget.chapterId, widget.milestoneId)
      ?.journal;

  String get _currentTitle =>
      _title ?? _journal?.title.fallback ?? widget.milestoneTitle;

  String get _currentText => _text ?? _journal?.text.fallback ?? '';

  Future<void> _save(({String title, String text})? journal) async {
    final saved = await _trame.setMilestoneJournal(
      widget.storylineId,
      widget.chapterId,
      widget.milestoneId,
      journal: journal,
    );
    if (saved && mounted) {
      setState(() {
        _title = null;
        _text = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = gameMemoryResourceState(
      context,
      _trame.saved,
      loading: l10n.trameJournalLoading,
      onRetry: _trame.ensureStorylines,
    );
    final journal = _journal;
    final title = _currentTitle.trim();
    final text = _currentText.trim();
    final editable = _trame.staging.editable;
    final changed =
        journal == null ||
        title != journal.title.fallback ||
        text != journal.text.fallback;
    final translated =
        journal != null &&
        (journal.title.translations.isNotEmpty ||
            journal.text.translations.isNotEmpty);
    return StudioSection(
      title: l10n.trameJournal,
      children: [
        Text(l10n.trameJournalHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.m),
        if (state != null)
          SizedBox(height: 120, child: state)
        else ...[
          StudioDraftField(
            key: const ValueKey('trame-journal-title'),
            value: _currentTitle,
            label: l10n.trameJournalTitle,
            helperText: l10n.trameJournalLimit(storylineJournalTitleMaxLength),
            enabled: editable,
            onChanged: (value) => setState(() => _title = value),
          ),
          const SizedBox(height: StudioSpacing.m),
          StudioDraftField(
            key: const ValueKey('trame-journal-text'),
            value: _currentText,
            label: l10n.trameJournalText,
            lines: 4,
            helperText: l10n.trameJournalLimit(storylineJournalTextMaxLength),
            enabled: editable,
            onChanged: (value) => setState(() => _text = value),
          ),
          if (translated) ...[
            const SizedBox(height: StudioSpacing.s),
            Text(
              l10n.trameJournalTranslations,
              key: const ValueKey('trame-journal-translations'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: StudioSpacing.m),
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              StudioButton(
                key: const ValueKey('trame-journal-apply'),
                label: journal == null
                    ? l10n.trameJournalAdd
                    : l10n.trameJournalApply,
                icon: Icons.menu_book_outlined,
                onPressed:
                    editable && changed && title.isNotEmpty && text.isNotEmpty
                    ? () => unawaited(_save((title: title, text: text)))
                    : null,
              ),
              if (journal != null)
                StudioButton(
                  key: const ValueKey('trame-journal-remove'),
                  label: l10n.trameJournalRemove,
                  icon: Icons.remove_circle_outline,
                  variant: StudioButtonVariant.secondary,
                  onPressed: editable ? () => unawaited(_save(null)) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
