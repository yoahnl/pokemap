import 'package:avelune_studio/features/game_memory/application/game_memory_staging.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:map_core/map_core_domain.dart';

NarrativeFactDefinition memoryFact(
  String id,
  String label, {
  NarrativeValue value = const NarrativeValue.boolean(false),
}) => NarrativeFactDefinition(id: id, label: label, initialValue: value);

final class FakeNarrativeIndex implements NarrativeIndexPort {
  final titlesByKind = <NarrativeTitleKind, List<NarrativeTitle>>{};
  final definitions = <String, NarrativeFactDefinition>{};
  final users = <String, NarrativeUsages>{};
  final owners = <String, NarrativeUsages>{};
  var rules = <WorldRuleDefinition>[];
  Object? titleFailure;
  Object? usageFailure;
  final titleRequests = <NarrativeTitleKind>[];
  final factRequests = <List<String>>[];
  final userRequests = <List<String>>[];
  var ruleRequests = 0;

  void addFacts(Iterable<NarrativeFactDefinition> facts) {
    for (final fact in facts) {
      definitions[fact.id] = fact;
    }
    titlesByKind[NarrativeTitleKind.facts] = [
      for (final fact in definitions.values)
        NarrativeTitle(id: fact.id, title: fact.label),
    ];
  }

  @override
  Future<List<NarrativeTitle>> titles(NarrativeTitleKind kind) async {
    titleRequests.add(kind);
    if (titleFailure case final failure?) throw failure;
    return titlesByKind[kind] ?? const [];
  }

  @override
  Future<List<NarrativeFactDefinition>> facts(List<String> ids) async {
    factRequests.add(ids);
    return [for (final id in ids) ?definitions[id]];
  }

  @override
  Future<Map<String, NarrativeUsages>> factUsers(List<String> factIds) async {
    userRequests.add(factIds);
    if (usageFailure case final failure?) throw failure;
    return {
      for (final id in factIds)
        id:
            users[id] ??
            NarrativeUsages(owners: const [], notCovered: const []),
    };
  }

  @override
  Future<NarrativeUsages> elementOwners(String mapId, String elementId) async {
    if (usageFailure case final failure?) throw failure;
    return owners['$mapId/$elementId'] ??
        NarrativeUsages(owners: const [], notCovered: const []);
  }

  @override
  Future<List<WorldRuleDefinition>> worldRules() async {
    ruleRequests++;
    return rules;
  }
}

final class FakeMemoryStaging implements GameMemoryStaging {
  @override
  final draft = StoryDraft();
  @override
  var editable = true;
  @override
  Object? revision;
  final facts = <String, NarrativeFactDefinition>{};
  final rules = <String, WorldRuleDefinition>{};
  var stages = 0;

  @override
  void rememberFact(NarrativeFactDefinition fact) => facts[fact.id] = fact;

  @override
  void rememberRule(WorldRuleDefinition rule) => rules[rule.id] = rule;

  @override
  void stage(void Function(StoryDraft draft) body) {
    stages++;
    draft.group(() => body(draft));
  }
}
