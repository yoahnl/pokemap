import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  test(
    'a completed team survives the standalone file gateway and cold reload',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'completion-party-save-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final projectFilePath = '${directory.path}/project.json';
      final identity = buildStandaloneRuntimeGameIdentity(
        projectFilePath: projectFilePath,
        projectFormat: ProjectVersion.v8.name,
      );
      expect(identity.saveFormat, SaveEnvelopeCodec.currentSaveFormat);
      final descriptor = GameSessionDescriptor(
        sessionId: 'completion-party',
        sessionToken: 'completion-party-token',
        identity: identity,
        profileId: standaloneRuntimeProfileId,
        slotId: standaloneRuntimeSlotId,
        launchMode: GameSessionLaunchMode.newGame,
        initialGameState: const GameState(
          saveId: 'completion-file-save',
          currentMapId: 'victory-hall',
        ),
        installedVersionHandle: 'completion-fixture',
        runtimeApiVersion: '1.0.0',
        grantedCapabilities: const {
          GameCompletionPartyCapabilities.capabilityId,
        },
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
      );
      final consequence = SceneConsequence.finishGame(
        endingId: 'victory',
        outcome: SceneGameCompletionOutcome.victory,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'Victoire'),
          summary: SceneLocalizedText(fallback: 'Bravo !'),
        ),
        postGamePolicy: ScenePostGamePolicy.returnToTitle,
        recordParty: true,
      );
      const writer = SceneConsequenceRuntimeWriter(
        project: ProjectManifest(name: 'Victory', maps: [], tilesets: []),
      );
      final applied = writer.applyOne(
        const GameState(
          saveId: 'completion-file-save',
          currentMapId: 'victory-hall',
          trainerProfile: TrainerProfile(name: 'Alice'),
          party: PlayerParty(
            members: [
              PlayerPokemon(
                individualId: 'winner',
                speciesId: 'pikachu',
                natureId: 'hardy',
                abilityId: 'static',
                level: 50,
                knownMoveIds: ['thunderbolt'],
                currentPpByMoveId: {'thunderbolt': 5},
              ),
            ],
          ),
        ),
        consequence,
        completionRecordedAtEpochMs: 1792814400000,
      );
      expect(applied.success, isTrue);
      final gateway = StandalonePlayerSaveGateway(
        projectFilePath: projectFilePath,
        identity: identity,
      );
      final date = DateTime.fromMillisecondsSinceEpoch(
        1792814400000,
        isUtc: true,
      );
      await gateway.commit(
        GameSessionCheckpointCommit(
          descriptor: descriptor.publicContext,
          checkpoint: GameSessionCheckpoint(
            saveId: applied.gameState.saveId,
            createdAt: date,
            updatedAt: date,
            playTimeSeconds: 100,
            state: strictGameStateSaveJson(applied.gameState),
          ),
          status: SaveStatus.completed,
          completedAt: date,
          trigger: GameSessionCheckpointTrigger.completion,
        ),
      );
      final coldGateway = StandalonePlayerSaveGateway(
        projectFilePath: projectFilePath,
        identity: identity,
      );
      final envelope = await coldGateway.readEnvelope();
      expect(envelope, isNotNull);
      expect(const SaveEnvelopeCodec().verifyChecksum(envelope!), isTrue);
      final restored = const GameStateSaveEnvelopeMapper().restore(envelope);
      expect(
        restored.completionPartyJournal,
        applied.gameState.completionPartyJournal,
      );
      final replayed = writer.applyOne(
        restored.copyWith(party: const PlayerParty()),
        consequence,
      );
      expect(replayed.success, isTrue);
      expect(replayed.gameCompletion, isNull);
      expect(replayed.gameState.completionPartyJournal.records, hasLength(1));
      expect(
        replayed
            .gameState
            .completionPartyJournal
            .records
            .single
            .party
            .members
            .single
            .knownMoveIds,
        ['thunderbolt'],
      );
      expect(await directory.list().length, 1);
      final saveFile = (await directory.list().single) as File;
      final validBytes = await saveFile.readAsBytes();
      final validJson =
          jsonDecode(utf8.decode(validBytes)) as Map<String, dynamic>;
      for (final invalid in [
        {...validJson}..remove('completionPartyJournal'),
        {...validJson, 'completionPartyJournal': null},
        {
          ...validJson,
          'completionPartyJournal': {'schemaVersion': 999, 'records': []},
        },
      ]) {
        await saveFile.writeAsString(jsonEncode(invalid));
        final rejectedBytes = await saveFile.readAsBytes();
        await expectLater(coldGateway.readEnvelope(), throwsStateError);
        expect(await saveFile.readAsBytes(), rejectedBytes);
      }
      await saveFile.writeAsBytes(validBytes);
      final reopened = const GameStateSaveEnvelopeMapper().restore(
        (await coldGateway.readEnvelope())!,
      );
      expect(
        reopened.completionPartyJournal,
        applied.gameState.completionPartyJournal,
      );
    },
  );
}
