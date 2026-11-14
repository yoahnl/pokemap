import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

String mapBuilderStoryError(
  String error,
  AppLocalizations l10n,
) => switch (error) {
  MapBuilderStoryBinding.outOfMap => l10n.storyOutOfMap,
  'publish-unavailable' => l10n.storyPublishUnavailable,
  _ when error.startsWith(MapBuilderStoryBinding.afterRefused) =>
    l10n.storyCaseAfterRefused(
      error.substring(MapBuilderStoryBinding.afterRefused.length),
    ),
  _ when error.startsWith(MapBuilderStoryBinding.lineRefused) =>
    l10n.storyLineRefused(
      error.substring(MapBuilderStoryBinding.lineRefused.length),
    ),
  _ when error.startsWith(MapBuilderStoryBinding.unsupported) =>
    l10n.storyPublicationUnsupported(
      error
          .substring(MapBuilderStoryBinding.unsupported.length)
          .split(',')
          .map(l10n.storyPublicationKind)
          .join(', '),
    ),
  _ when error.startsWith(MapBuilderStoryBinding.deactivated) =>
    '${l10n.storyDeactivated} ${error.substring(MapBuilderStoryBinding.deactivated.length)}'
        .trim(),
  _ => switch (EventDeletionRefused.parse(error)) {
    final refusal? when refusal.coverageUnknown =>
      l10n.storyDeleteCoverageUnknown,
    final refusal? => l10n.storyDeleteInUse(
      refusal.users.map((user) => _storyDeleteUser(user, l10n)).join(', '),
    ),
    null => error,
  },
};

String _storyDeleteUser(EventDeletionUser user, AppLocalizations l10n) =>
    switch (user.kind) {
      'event' => l10n.storyDeleteUserEvent(user.label),
      'worldRule' => l10n.storyDeleteUserWorldRule(user.label),
      'map' => l10n.storyDeleteUserMap(user.label),
      _ => l10n.storyDeleteUserOther(user.label),
    };
