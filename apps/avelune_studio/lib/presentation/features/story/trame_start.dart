import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class TrameStart extends StatefulWidget {
  const TrameStart({super.key, required this.trame});

  final StorylineTrameController trame;

  @override
  State<TrameStart> createState() => _TrameStartState();
}

class _TrameStartState extends State<TrameStart> {
  final _title = TextEditingController();
  StorylineAsset? _shown;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trame = widget.trame;
    final editable = trame.staging.editable;
    final proposal = trame.proposal;
    final empty = StudioButton(
      key: const ValueKey('trame-start-empty'),
      label: l10n.trameStartEmpty,
      icon: Icons.add,
      variant: StudioButtonVariant.secondary,
      onPressed: editable
          ? () => unawaited(
              trame.startStoryline(
                StorylineType.main,
                l10n.trameMainTitle,
                l10n.trameNewChapter,
              ),
            )
          : null,
    );
    if (proposal.value == null &&
        !proposal.loading &&
        proposal.problem == null) {
      return StudioEmptyState(
        key: const ValueKey('trame-empty'),
        icon: Icons.account_tree_outlined,
        title: l10n.trameEmpty,
        description: l10n.trameEmptyHint,
        action: Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          alignment: WrapAlignment.center,
          children: [
            StudioButton(
              key: const ValueKey('trame-propose'),
              label: l10n.tramePropose,
              icon: Icons.auto_awesome_outlined,
              onPressed: () => unawaited(trame.loadProposal()),
            ),
            empty,
          ],
        ),
      );
    }
    final state = gameMemoryResourceState(
      context,
      proposal,
      loading: l10n.trameProposing,
      onRetry: () => unawaited(trame.loadProposal()),
    );
    if (state != null) return state;
    final proposed = proposal.value!.storyline;
    if (proposed == null) {
      return StudioEmptyState(
        key: const ValueKey('trame-proposal-none'),
        icon: Icons.info_outline,
        title: l10n.trameProposalNone,
        action: empty,
      );
    }
    if (!identical(_shown, proposed)) {
      _shown = proposed;
      _title.text = proposed.title;
    }
    return ListView(
      key: const ValueKey('trame-proposal'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        StudioNotice(l10n.trameProposalDraft),
        const SizedBox(height: StudioSpacing.l),
        TextField(
          key: const ValueKey('trame-proposal-title'),
          controller: _title,
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.trameStorylineName,
          ),
        ),
        for (final chapter in proposed.chapters)
          StudioSection(
            title: chapter.title,
            children: [
              for (final step in chapter.steps)
                Text(step.title, key: ValueKey('trame-proposed-${step.id}')),
            ],
          ),
        Wrap(
          spacing: StudioSpacing.s,
          children: [
            StudioButton(
              key: const ValueKey('trame-proposal-keep'),
              label: l10n.trameProposalKeep,
              icon: Icons.check,
              onPressed: editable
                  ? () => unawaited(trame.keepProposal(_title.text))
                  : null,
            ),
            StudioButton(
              key: const ValueKey('trame-proposal-discard'),
              label: l10n.trameProposalDiscard,
              variant: StudioButtonVariant.quiet,
              onPressed: trame.discardProposal,
            ),
          ],
        ),
      ],
    );
  }
}
