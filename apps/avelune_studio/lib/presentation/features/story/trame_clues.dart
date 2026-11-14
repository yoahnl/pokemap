import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameJournalClues extends StatefulWidget {
  const TrameJournalClues({
    super.key,
    required this.trame,
    required this.storylineId,
  });

  final StorylineTrameController trame;
  final String storylineId;

  @override
  State<TrameJournalClues> createState() => _TrameJournalCluesState();
}

class _TrameJournalCluesState extends State<TrameJournalClues> {
  var _text = '';
  String? _factId;
  var _composer = 0;

  StorylineTrameController get _trame => widget.trame;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      _trame.ensureStorylines();
      _trame.ensureFactNames();
    });
  }

  Future<void> _add(String text, String factId) async {
    if (await _trame.addJournalClue(
          widget.storylineId,
          text: text,
          factId: factId,
        ) &&
        mounted) {
      setState(() {
        _text = '';
        _factId = null;
        _composer++;
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
    final clues =
        _trame.fullStoryline(widget.storylineId)?.journalClues ?? const [];
    final facts = {
      for (final fact in _trame.booleanFacts)
        fact.id: fact.title.trim().isEmpty ? fact.id : fact.title,
    };
    final editable = _trame.staging.editable;
    final text = _text.trim();
    final factId = _factId;
    return StudioSection(
      title: l10n.trameClues,
      children: [
        Text(l10n.trameCluesHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.m),
        if (state != null)
          SizedBox(height: 120, child: state)
        else ...[
          for (final clue in clues)
            _TrameClueRow(
              key: ValueKey('trame-clue-${clue.id}'),
              trame: _trame,
              storylineId: widget.storylineId,
              clue: clue,
              facts: facts,
              editable: editable,
            ),
          if (facts.isEmpty)
            Text(l10n.trameCluesNoFact, style: theme.textTheme.bodySmall)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StudioDraftField(
                    key: ValueKey('trame-clue-new-text-$_composer'),
                    value: _text,
                    label: l10n.trameClueText,
                    helperText: l10n.trameJournalLimit(
                      storylineJournalClueTextMaxLength,
                    ),
                    enabled: editable,
                    onChanged: (value) => setState(() => _text = value),
                  ),
                ),
                const SizedBox(width: StudioSpacing.m),
                SizedBox(
                  width: 220,
                  child: KeyedSubtree(
                    key: ValueKey('trame-clue-new-fact-$_composer'),
                    child: StudioSelect(
                      label: l10n.trameClueFact,
                      value: factId,
                      options: facts,
                      onChanged: editable
                          ? (id) => setState(() => _factId = id)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: StudioSpacing.m),
                StudioButton(
                  key: const ValueKey('trame-clue-add'),
                  label: l10n.trameClueAdd,
                  icon: Icons.add,
                  onPressed: editable && text.isNotEmpty && factId != null
                      ? () => unawaited(_add(text, factId))
                      : null,
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class _TrameClueRow extends StatefulWidget {
  const _TrameClueRow({
    super.key,
    required this.trame,
    required this.storylineId,
    required this.clue,
    required this.facts,
    required this.editable,
  });

  final StorylineTrameController trame;
  final String storylineId;
  final StorylineJournalClue clue;
  final Map<String, String> facts;
  final bool editable;

  @override
  State<_TrameClueRow> createState() => _TrameClueRowState();
}

class _TrameClueRowState extends State<_TrameClueRow> {
  String? _text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final clue = widget.clue;
    final text = (_text ?? clue.text.fallback).trim();
    final editable = widget.editable;
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StudioDraftField(
              key: ValueKey('trame-clue-${clue.id}-text'),
              value: _text ?? clue.text.fallback,
              label: l10n.trameClueText,
              enabled: editable,
              onChanged: (value) => setState(() => _text = value),
            ),
          ),
          const SizedBox(width: StudioSpacing.m),
          SizedBox(
            width: 220,
            child: KeyedSubtree(
              key: ValueKey('trame-clue-${clue.id}-fact'),
              child: StudioSelect(
                label: l10n.trameClueFact,
                value: clue.factId,
                options: widget.facts,
                onChanged: editable
                    ? (id) => unawaited(
                        widget.trame.updateJournalClue(
                          widget.storylineId,
                          clue.id,
                          factId: id,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          IconButton(
            key: ValueKey('trame-clue-${clue.id}-apply'),
            tooltip: l10n.trameClueApply,
            onPressed: editable && text.isNotEmpty && text != clue.text.fallback
                ? () async {
                    if (await widget.trame.updateJournalClue(
                          widget.storylineId,
                          clue.id,
                          text: text,
                        ) &&
                        mounted) {
                      setState(() => _text = null);
                    }
                  }
                : null,
            icon: const Icon(Icons.check),
          ),
          IconButton(
            key: ValueKey('trame-clue-${clue.id}-remove'),
            tooltip: l10n.trameClueRemove,
            onPressed: editable
                ? () => unawaited(
                    widget.trame.removeJournalClue(widget.storylineId, clue.id),
                  )
                : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
