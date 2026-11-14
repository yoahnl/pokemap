import 'package:map_core/map_core_domain.dart';

import '../../story_draft/application/story_draft.dart';

abstract interface class GameMemoryStaging {
  StoryDraft get draft;

  bool get editable;

  Object? get revision;

  void rememberFact(NarrativeFactDefinition fact);

  void rememberRule(WorldRuleDefinition rule);

  void stage(void Function(StoryDraft draft) body);
}
