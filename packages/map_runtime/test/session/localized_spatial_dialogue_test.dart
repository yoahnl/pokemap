import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the real spatial session follows preferences and preserves choice outcomes', () async {
    final root = await Directory.systemTemp.createTemp('localized-spatial-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key.substring(8)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final source = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)),
    );
    final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!)),
    );
    final document = RuntimeDialogueDocument(
      nodes: [
        RuntimeDialogueNode(
          title: 'Start',
          steps: [
            RuntimeDialogueLine('Bonjour {{ name }}'),
            RuntimeDialogueChoiceBlock([
              RuntimeDialogueChoice(
                text: 'Partir',
                outcomeId: 'leave',
                steps: [],
              ),
              RuntimeDialogueChoice(
                text: 'Rester',
                outcomeId: 'stay',
                steps: [],
              ),
            ]),
          ],
        ),
      ],
    );
    final localization =
        DialogueLocalization(
              sourceLocale: 'fr',
              units: [
                for (final (index, scope) in runtimeDialogueTextScopes(
                  document,
                ).indexed)
                  DialogueTextUnit(
                    id: 'text-$index',
                    binding: scope.binding,
                    kind: scope.kind,
                    source: scope.text,
                  ),
              ],
            )
            .translate('text-0', 'en', 'Hello {{ name }}')
            .translate('text-1', 'en', 'Leave')
            .translate('text-2', 'en', 'Stay');
    await File(
      '${root.path}/talk.json',
    ).writeAsBytes(const RuntimeDialogueDocumentCodec().encodeUtf8(document));
    final bundle = RuntimeMapBundle(
      manifest: source.copyWith(
        newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'map'),
        dialogues: [
          ProjectDialogueEntry(
            id: 'talk',
            name: 'Accueil',
            relativePath: 'talk.json',
            localization: localization,
          ),
        ],
      ),
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: {'hero-atlas': '${root.path}/assets/hero.png'},
      characterAnimationAbsolutePathsByAssetId: {
        'hero-source': '${root.path}/assets/hero.png',
      },
    );
    final runtime = SpatialExplorationGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: 'localized',
        sessionToken: 'token',
        identity: GameIdentity(
          gameId: 'games.example.localized',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v9,
          saveFormat: SaveEnvelopeCodec.currentSaveFormat,
          compatibilityId: 'localized',
        ),
        profileId: 'profile',
        slotId: 'slot',
        launchMode: GameSessionLaunchMode.newGame,
        initialGameState: GameState(
          saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
          currentMapId: 'map',
          playerPosition: const GridPos(x: 6, y: 6),
          playerSpatialPosition: PlayerSpatialPosition(x: 6, z: 6),
          trainerProfile: const TrainerProfile(
            name: 'Yoahn',
            avatarCharacterId: 'hero',
          ),
          scriptVariables: ScriptVariables(
            values: {'name': const ScriptVariableValue.string('Yoahn')},
          ),
        ),
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: {'map3d@1', dialogueLocalizationCapability},
        locale: 'fr',
        locales: ProjectLocalePolicy(
          supportedLocales: ['fr', 'en', 'es'],
          fallbackLocale: 'fr',
        ),
        accessibility: const GameSessionAccessibilityOptions(),
      ),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {},
      unmountSession: (_) async {},
    );
    addTearDown(runtime.dispose);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    for (final locale in ['fr', 'en', 'fr-CA', 'es', 'de', 'en']) {
      runtime.applyPlayerPreferences(
        PlayerPreferencesSnapshot(
          locale: locale,
          dialogueTextSpeed: RuntimeDialogueTextSpeed.instant,
          accessibility: const GameSessionAccessibilityOptions(),
        ),
      );
      final completed = runtime.session!.showDialogue(
        const DialogueRef(dialogueId: 'talk'),
      );
      final ready = Completer<void>();
      void changed() {
        if (runtime.dialoguePresentationListenable.value != null &&
            !ready.isCompleted) {
          ready.complete();
        }
      }

      runtime.dialoguePresentationListenable.addListener(changed);
      try {
        changed();
        await ready.future.timeout(const Duration(seconds: 3));
      } finally {
        runtime.dialoguePresentationListenable.removeListener(changed);
      }
      expect(
        runtime.dialoguePresentationListenable.value!.fullText,
        locale == 'en' ? 'Hello Yoahn' : 'Bonjour Yoahn',
      );
      runtime.session!.confirmDialogue();
      final choices = runtime.dialoguePresentationListenable.value!;
      expect(
        choices.choices.map((choice) => choice.label),
        locale == 'en' ? ['Leave', 'Stay'] : ['Partir', 'Rester'],
      );
      runtime.session!.confirmDialogue();
      final result = await completed;
      expect(result.success, isTrue);
      expect(result.scenePortId, 'leave');
      expect(
        runtime.gameStateSnapshot.scriptVariables.values['name'],
        const ScriptVariableValue.string('Yoahn'),
      );
    }
  });
}
