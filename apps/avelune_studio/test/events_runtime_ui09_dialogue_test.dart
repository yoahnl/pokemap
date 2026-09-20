import 'dart:io';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final choice in [0, 1]) {
    test(
      'UI09 published conversation choice $choice drives its real Scene branch',
      () async {
        final fixture = await createUi09RuntimeFixture();
        addTearDown(fixture.dispose);
        final root = fixture.directory.path;
        final projectPath = '$root/project.json';
        final before = {
          for (final path in [
            'project.json',
            'dialogues/ui09_guichet.yarn',
            fixture.manifest.maps.first.relativePath,
          ])
            path: await File('$root/$path').readAsBytes(),
        };
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectPath,
          mapId: fixture.manifest.maps.first.id,
        );
        expect(
          bundle.manifest.dialogues
              .singleWhere((e) => e.id == ui09DialogueId)
              .declaredOutcomes
              .map((e) => e.id),
          ['depart', 'attente'],
        );
        final game = _LoadedGame(bundle: bundle, projectFilePath: projectPath);
        game.onGameResize(Vector2(640, 480));
        await game.onLoad();
        await _until(
          game,
          () => game.dialoguePresentationListenable.value != null,
        );
        final opening = game.dialoguePresentationListenable.value!;
        expect(opening.nodeTitle, 'Accueil');
        expect(
          opening.fullText,
          contains('Souhaitez-vous préparer votre départ'),
        );
        await _until(game, () {
          final snapshot = game.dialoguePresentationListenable.value;
          if (snapshot?.mode == DialoguePresentationMode.choices) return true;
          if (snapshot != null) {
            game.dispatchDialoguePresentationCommand(
              DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
            );
          }
          return false;
        });
        final choices = game.dialoguePresentationListenable.value!;
        expect(choices.choices.map((e) => e.label), [
          'Je pars maintenant',
          'Je préfère attendre',
        ]);
        expect(
          game.dispatchDialoguePresentationCommand(
            DialogueSelectChoiceCommand(
              snapshotRevision: choices.revision,
              choiceIndex: choice,
            ),
          ),
          isTrue,
        );
        await _until(
          game,
          () =>
              game.dialoguePresentationListenable.value?.mode ==
              DialoguePresentationMode.line,
        );
        expect(
          game.dialoguePresentationListenable.value!.fullText,
          contains(
            choice == 0
                ? 'Votre train vous attend sur le quai.'
                : 'Prenez votre temps dans la salle d’attente.',
          ),
        );
        await _until(game, () {
          final snapshot = game.dialoguePresentationListenable.value;
          if (snapshot != null) {
            game.dispatchDialoguePresentationCommand(
              DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
            );
          }
          return !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              game
                  .gameStateSnapshot
                  .narrativeEventProgress
                  .consumedNarrativeEventIds
                  .contains(Ui06SceneFixture.eventId);
        });
        final facts =
            game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId;
        expect(
          facts[Ui06SceneFixture.departureFactId],
          choice == 0 ? true : isNot(true),
        );
        expect(facts[ui09WaitingFact], choice == 1 ? true : isNot(true));
        expect(game.debugFlowPhaseName, 'overworld');
        for (final file in before.entries) {
          expect(await File('$root/${file.key}').readAsBytes(), file.value);
        }
      },
    );
  }
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 1500; tick++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'UI09 runtime timeout: ${game.debugFlowPhaseName}, '
    'dialogue=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

final class _LoadedGame extends PlayableMapGame {
  _LoadedGame({required super.bundle, required super.projectFilePath});
  @override
  bool get isLoaded => true;
}
