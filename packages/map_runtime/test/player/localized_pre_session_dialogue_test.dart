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
        final root = await Directory.systemTemp.createTemp(
          'localized-pre-session-',
        );
        addTearDown(() => root.delete(recursive: true));
        final document = const YarnDialogueCompiler().compile(
          'title: Start\n---\nBonjour\n===\n',
        );
        await File('${root.path}/intro.json').writeAsBytes(
          const RuntimeDialogueDocumentCodec().encodeUtf8(document),
        );
        final localization = DialogueLocalization(
          sourceLocale: 'fr',
          units: [
            DialogueTextUnit(
              id: 'greeting',
              binding: '/Start/0',
              kind: DialogueTextKind.line,
              source: 'Bonjour',
            ),
          ],
        ).translate('greeting', 'en', 'Hello');
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
                  SceneNode(
                    id: 'talk',
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
                    toNodeId: 'talk',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  SceneEdge(
                    id: 'done',
                    fromNodeId: 'talk',
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
            ).run(
              runId: 'run',
              draft: draft,
              interactions: interactions,
              preferredLocale: locale,
              locales: ProjectLocalePolicy(
                supportedLocales: ['fr', 'en', 'es'],
                fallbackLocale: 'fr',
              ),
            );
        expect(result, same(draft));
        expect(prompts, [locale == 'en' ? 'Hello' : 'Bonjour']);
      },
    );
  }
}
