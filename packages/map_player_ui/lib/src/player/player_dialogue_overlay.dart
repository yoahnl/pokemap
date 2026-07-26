import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

/// Boîte de dialogue joueur rendue en Flutter à partir du snapshot runtime.
class PlayerDialogueOverlay extends StatelessWidget {
  const PlayerDialogueOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.portraitBuilder,
  });

  final DialoguePresentationSnapshot snapshot;
  final ValueChanged<DialoguePresentationCommand> onCommand;
  final Widget Function(String speaker)? portraitBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PlayerSpacing.sm),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 760,
                maxHeight: constraints.maxHeight * 0.58,
              ),
              child: PlayerPanel(
                elevated: true,
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: AnimatedSwitcher(
                  duration: context.playerMotion.fast,
                  child: Semantics(
                    key: ValueKey<int>(snapshot.revision),
                    container: true,
                    liveRegion: true,
                    label: _semanticLabel(snapshot),
                    child: switch (snapshot.mode) {
                      DialoguePresentationMode.line => GestureDetector(
                          key: const ValueKey<String>('dialogue-tap-zone'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onCommand(
                            DialogueAdvanceCommand(
                              snapshotRevision: snapshot.revision,
                            ),
                          ),
                          child: _DialogueLineContent(
                            snapshot: snapshot,
                            portraitBuilder: portraitBuilder,
                          ),
                        ),
                      DialoguePresentationMode.choices =>
                        _DialogueChoiceContent(
                          snapshot: snapshot,
                          onCommand: onCommand,
                        ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogueLineContent extends StatelessWidget {
  const _DialogueLineContent({
    required this.snapshot,
    required this.portraitBuilder,
  });

  final DialoguePresentationSnapshot snapshot;
  final Widget Function(String speaker)? portraitBuilder;

  @override
  Widget build(BuildContext context) {
    final speaker = snapshot.speaker;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (speaker != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (portraitBuilder != null) ...<Widget>[
                  SizedBox.square(
                    dimension: 64,
                    child: portraitBuilder!(speaker),
                  ),
                  const SizedBox(width: PlayerSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    speaker,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: context.playerColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PlayerSpacing.sm),
          ],
          Text(
            snapshot.text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: PlayerSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                snapshot.isCurrentLineFullyRevealed
                    ? Icons.navigate_next_rounded
                    : Icons.fast_forward_rounded,
              ),
              const SizedBox(width: PlayerSpacing.xxs),
              Text(
                !snapshot.isCurrentLineFullyRevealed
                    ? context.playerL10n.showFullText
                    : snapshot.isLastContent
                        ? context.playerL10n.close
                        : context.playerL10n.next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogueChoiceContent extends StatelessWidget {
  const _DialogueChoiceContent({
    required this.snapshot,
    required this.onCommand,
  });

  final DialoguePresentationSnapshot snapshot;
  final ValueChanged<DialoguePresentationCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.playerL10n.yourChoice,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PlayerSpacing.sm),
          for (final choice in snapshot.choices) ...<Widget>[
            PlayerActionButton(
              key: ValueKey<String>('dialogue-choice-${choice.index}'),
              label: choice.label,
              icon: choice.selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              autofocus: choice.selected,
              secondary: !choice.selected,
              onPressed: () => onCommand(
                DialogueSelectChoiceCommand(
                  snapshotRevision: snapshot.revision,
                  choiceIndex: choice.index,
                ),
              ),
            ),
            if (choice != snapshot.choices.last)
              const SizedBox(height: PlayerSpacing.xs),
          ],
        ],
      ),
    );
  }
}

String _semanticLabel(DialoguePresentationSnapshot snapshot) {
  return switch (snapshot.mode) {
    DialoguePresentationMode.line =>
      '${snapshot.speaker == null ? '' : '${snapshot.speaker}, '}${snapshot.fullText}',
    DialoguePresentationMode.choices =>
      'Choix de dialogue, ${snapshot.choices.length} options',
  };
}
