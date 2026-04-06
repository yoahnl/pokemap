import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../lib/src/application/global_story_chapter_runtime.dart';

void main() {
  test('buildGlobalStoryChapterStepIndex lit authoring.globalStoryStudioDocument',
      () {
    const doc = '''
{"chapters":[
  {"id":"ch1","name":"A","description":"","stepIds":["s1","s2"],"order":0}
]}''';
    final scenarios = [
      ScenarioAsset(
        id: 'global_1',
        name: 'global',
        entryNodeId: 'start',
        scope: ScenarioScope.globalStory,
        nodes: const [],
        edges: const [],
        metadata: {kGlobalStoryStudioDocumentMetadataKey: doc},
      ),
    ];
    final idx = buildGlobalStoryChapterStepIndex(scenarios);
    expect(idx.isChapterCompleted('ch1', {'s1'}), isFalse);
    expect(idx.isChapterCompleted('ch1', {'s1', 's2'}), isTrue);
    expect(idx.isChapterNotCompleted('ch1', {'s1', 's2'}), isFalse);
  });
}
