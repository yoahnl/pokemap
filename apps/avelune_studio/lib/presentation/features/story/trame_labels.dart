import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/l10n/app_localizations.dart';

bool trameArchived(StorylineStatus? status) =>
    status == StorylineStatus.archived;

extension TrameLabels on AppLocalizations {
  String trameIssue(StorylineMilestoneIssue issue) =>
      trameIssueText(issue.name);

  String trameType(StorylineType type) => trameStorylineType(type.name);

  String trameName(String title, String fallback) =>
      title.trim().isEmpty ? fallback : title;
}
