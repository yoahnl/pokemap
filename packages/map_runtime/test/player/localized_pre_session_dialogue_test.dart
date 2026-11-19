import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_story/map_story.dart';

void main() {
  for (final locale in ['fr', 'en', 'fr-CA', 'es', 'de']) {
    test(
      'pre-session dialogue uses the host language policy for $locale',
      () async {
        final prompts = await _playIntro(preferredLocale: locale);
        expect(
          prompts,
          locale == 'en'
              ? ['Hello', 'Goodbye', 'Hello', 'Goodbye']
              : ['Bonjour', 'Au revoir', 'Bonjour', 'Au revoir'],
        );
      },
    );
  }

  test('only a new pre-session dialogue adopts the latest locale', () async {
    var locale = 'fr';
    final prompts = await _playIntro(
      preferredLocale: 'en',
      readPreferredLocale: () async => locale,
      onPrompt: (number) {
        if (number == 1) locale = 'en';
      },
    );

    expect(prompts, ['Bonjour', 'Au revoir', 'Hello', 'Goodbye']);
  });

  test('a missing or failed locale read preserves the run locale', () async {
    var reads = 0;
    final prompts = await _playIntro(
      preferredLocale: 'en',
      readPreferredLocale: () async {
        if (++reads == 1) return null;
        throw StateError('Preferences unavailable');
      },
    );

    expect(reads, 2);
    expect(prompts, ['Hello', 'Goodbye', 'Hello', 'Goodbye']);
  });
}

Future<List<String?>> _playIntro({
  required String preferredLocale,
  Future<String?> Function()? readPreferredLocale,
  void Function(int number)? onPrompt,
}) async {
  final root = await Directory.systemTemp.createTemp('localized-pre-session-');
  addTearDown(() => root.delete(recursive: true));
  final document = const YarnDialogueCompiler().compile(
    'title: Start\n---\nBonjour\nAu revoir\n===\n',
  );
  await File('${root.path}/intro.json')
      .writeAsBytes(const RuntimeDialogueDocumentCodec().encodeUtf8(document));
  final localization = DialogueLocalization(
    sourceLocale: 'fr',
    units: [
      DialogueTextUnit(
        id: 'greeting',
        binding: '/Start/0',
        kind: DialogueTextKind.line,
        source: 'Bonjour',
      ),
      DialogueTextUnit(
        id: 'farewell',
        binding: '/Start/1',
        kind: DialogueTextKind.line,
        source: 'Au revoir',
      ),
    ],
  ).translate('greeting', 'en', 'Hello').translate('farewell', 'en', 'Goodbye');
  final project = ProjectManifest(
    name: 'Localized pre-session',
    maps: [],
    tilesets: [],
    dialogues: [
      ProjectDialogueEntry(
        id: 'intro',
        name: 'Intro',
        relativePath: 'intro.json',
        localization: localization,
      ),
    ],
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'map',
      preSessionSceneId: 'intro-scene',
    ),
    scenes: [
      SceneAsset(
        id: 'intro-scene',
        name: 'Intro',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            for (final id in ['first-dialogue', 'second-dialogue'])
              SceneNode(
                id: id,
                kind: SceneNodeKind.yarnDialogue,
                payload: SceneYarnDialoguePayload(dialogueId: 'intro'),
              ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'open',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'first-dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'continue',
              fromNodeId: 'first-dialogue',
              fromPortId: 'completed',
              toNodeId: 'second-dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'done',
              fromNodeId: 'second-dialogue',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
    ],
  );
  final interactions = HeadlessSceneInteractionPort();
  addTearDown(interactions.close);
  final prompts = <String?>[];
  final subscription = interactions.requests.listen((request) {
    prompts.add(request.prompt.fallbackText);
    onPrompt?.call(prompts.length);
    interactions.resolve(
      SceneInteractionResult.acknowledged(
        requestId: request.requestId,
        revision: request.revision,
      ),
    );
  });
  addTearDown(subscription.cancel);
  final draft = NewGameDraft.start(
    draftId: 'draft',
    projectRevision: 'sha256:test',
    slotId: 'slot',
    config: project.newGame,
  );
  final result =
      await RuntimeTextPreSessionSceneRunner(
        project: project,
        projectRootDirectory: root.path,
        sceneId: 'intro-scene',
        readPreferredLocale: readPreferredLocale,
      ).run(
        runId: 'run',
        draft: draft,
        interactions: interactions,
        preferredLocale: preferredLocale,
        locales: ProjectLocalePolicy(
          supportedLocales: ['fr', 'en', 'es'],
          fallbackLocale: 'fr',
        ),
      );
  expect(result, same(draft));
  return prompts;
}
