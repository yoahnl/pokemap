import 'package:map_core/map_core_domain.dart';

import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';

final class StorySavedRecords implements StoryDraftSaved {
  final _facts = <String, NarrativeFactDefinition>{};
  final _rules = <String, WorldRuleDefinition>{};

  void rememberFact(NarrativeFactDefinition fact) => _facts[fact.id] = fact;

  void rememberRule(WorldRuleDefinition rule) => _rules[rule.id] = rule;

  @override
  Object? read(StoryDraftKind<Object> kind, String id) => switch (kind) {
    StoryDraftKind.fact => _facts[id],
    StoryDraftKind.worldRule => _rules[id],
    _ => null,
  };
}
