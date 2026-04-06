import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../lib/src/application/step_studio_completion_runtime.dart';

void main() {
  group('buildStepCompletionCutsceneIndex', () {
    test('indexes whenCutsceneEnds from global scenario metadata', () {
      const doc = '''
{"schemaVersion":1,"globalStoryScenarioId":"g","steps":[
  {"id":"s1","completion":{"mode":"whenCutsceneEnds","cutsceneId":"cut_a"}},
  {"id":"s2","completion":{"mode":"manual"}}
]}''';
      final scenarios = [
        ScenarioAsset(
          id: 'global_1',
          name: 'global',
          entryNodeId: 'start',
          scope: ScenarioScope.globalStory,
          nodes: const [],
          edges: const [],
          metadata: {kStepStudioDocumentMetadataKey: doc},
        ),
        ScenarioAsset(
          id: 'cut_a',
          name: 'cut',
          entryNodeId: 'start',
          scope: ScenarioScope.localEventFlow,
          nodes: const [],
          edges: const [],
          metadata: const {},
        ),
      ];
      final index = buildStepCompletionCutsceneIndex(scenarios);
      expect(index.stepIdToCompleteWhenCutsceneEnds('cut_a'), 's1');
      expect(index.stepIdToCompleteWhenCutsceneEnds('missing'), isNull);
    });

    test('appendCompletedStepIdIfAbsent is idempotent', () {
      const existing = ['a', 'b'];
      final once = appendCompletedStepIdIfAbsent(existing, 'c');
      expect(once, ['a', 'b', 'c']);
      final twice = appendCompletedStepIdIfAbsent(once, 'c');
      expect(identical(twice, once), isTrue);
    });
  });
}
