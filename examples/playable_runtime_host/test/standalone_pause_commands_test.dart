import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_launch_save.dart';
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'standalone pause transport commits real party and held-item commands',
    () async {
      final root = await Directory.systemTemp.createTemp('standalone-pause-');
      addTearDown(() => root.delete(recursive: true));
      final source = Directory('${Directory.current.path}/golden_battle_slice');
      await for (final entry in source.list(
        recursive: true,
        followLinks: false,
      )) {
        final relative = entry.path.substring(source.path.length + 1);
        if (entry is File) {
          final file = File('${root.path}/$relative');
          await file.parent.create(recursive: true);
          await entry.copy(file.path);
        }
      }
      final projectFile = '${root.path}/project.json';
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await File(projectFile).readAsString())
            as Map<String, dynamic>,
      );
      final initialSave = (await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFile,
      ))!;
      var state = gameStateFromSaveData(initialSave);
      state = state.copyWith(
        party: PlayerParty(
          members: [
            for (var i = 0; i < state.party.members.length; i++)
              state.party.members[i].copyWith(individualId: 'member-$i'),
          ],
        ),
        bag: const Bag(
          entries: [BagEntry(itemId: 'miracle_seed', quantity: 2)],
        ),
      );
      final itemCatalog = ItemCatalogSnapshot.fromCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ...mvpItemCatalog.entries,
            const ProjectItemDefinition(
              id: 'miracle_seed',
              displayName: 'Grain Miracle',
              pocketId: 'items',
              heldEffectId: 'miracle_seed',
            ),
          ],
        ),
      );
      var commits = 0;
      final services = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (next) async {
          state = next;
          commits++;
          await File(
            '${root.path}/$kRuntimeHostLaunchSaveFileName',
          ).writeAsString(jsonEncode(saveDataFromGameState(next).toJson()));
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
        itemCatalog: itemCatalog,
      );
      addTearDown(services.dispose);
      final gameLoaded = Completer<void>();
      final launchEntered = Completer<void>();
      final port = CallbackStandaloneRuntimeSessionPort(
        onLaunch: (_, report, preloaded) async {
          preloaded?.dispose();
          launchEntered.complete();
          await gameLoaded.future;
          report(
            const GameSessionLoadingProgress(
              stage: 'ready',
              current: 1,
              total: 1,
            ),
          );
        },
        onCaptureCheckpoint: () async => GameSessionCheckpoint(
          saveId: state.saveId,
          createdAt: DateTime.utc(2026, 9, 6),
          updatedAt: DateTime.utc(2026, 9, 6),
          playTimeSeconds: 0,
          state: strictGameStateSaveJson(state),
        ),
        onPauseCommand: (command) => switch (command.kind) {
          RuntimePlayerPauseCommandKind.reorderPartyMember ||
          RuntimePlayerPauseCommandKind.setPartyLead =>
            services.reorderPartyOutsideBattle(command),
          _ => services.useBagItemOutsideBattle(command),
        },
      );
      final host = StandaloneRuntimeStartupHost(
        projectFilePath: projectFile,
        manifest: manifest,
        sessionPort: port,
      );
      addTearDown(host.dispose);
      await host.sessionController.prepare(
        GameSessionDescriptor(
          sessionId: 'pause-test',
          sessionToken: 'pause-test-token',
          identity: host.identity,
          profileId: standaloneRuntimeProfileId,
          slotId: standaloneRuntimeSlotId,
          launchMode: GameSessionLaunchMode.newGame,
          installedVersionHandle: 'standalone-version',
          runtimeApiVersion: 'runtime.v1',
          grantedCapabilities: const {},
          locale: 'fr',
          accessibility: const GameSessionAccessibilityOptions(),
          initialGameState: state,
        ),
      );
      final running = host.sessionController.snapshots.firstWhere(
        (snapshot) => snapshot.state == GameSessionState.running,
      );
      final loading = host.sessionController.snapshots.firstWhere(
        (snapshot) => snapshot.state == GameSessionState.loading,
      );
      final started = host.sessionController.start();
      await loading.timeout(const Duration(seconds: 10));
      await launchEntered.future.timeout(const Duration(seconds: 10));
      expect(host.sessionController.snapshot.state, GameSessionState.loading);
      gameLoaded.complete();
      await started;
      await running.timeout(const Duration(seconds: 10));
      await host.sessionController.pause();

      final reorder = await host.sessionController.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.reorderPartyMember(
          partyTargetId: 'pokemon.member-0',
          secondPartyTargetId: 'pokemon.member-1',
        ),
      );
      expect(reorder.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(state.party.members.first.individualId, 'member-1');
      final held = await host.sessionController.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.equipHeldItem(
          itemTargetId: 'miracle_seed',
          partyTargetId: 'pokemon.member-0',
        ),
      );
      expect(held.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(state.party.members.last.heldItemId, 'miracle_seed');
      expect(state.bag.entries.single.quantity, 1);
      final lead = await host.sessionController.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.member-0',
        ),
      );
      expect(lead.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(state.party.members.first.individualId, 'member-0');
      final take = await host.sessionController.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.unequipHeldItem(
          partyTargetId: 'pokemon.member-0',
        ),
      );
      expect(take.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(state.party.members.first.heldItemId, isEmpty);
      expect(state.bag.entries.single.quantity, 2);
      expect(commits, 4);
      final persisted = (await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFile,
      ))!;
      expect(persisted.party.members.first.individualId, 'member-0');
      expect(persisted.bag.entries.single.quantity, 2);
      final details = await host.sessionController.loadPauseDetails();
      expect(
        details[RuntimePlayerPauseSection.party]!.entries.first.id,
        'pokemon.member-0',
      );
      await host.sessionController.resume();
      final refused = await host.sessionController.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.member-1',
        ),
      );
      expect(refused.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(commits, 4);
    },
  );

  test('missing standalone command callback fails closed', () async {
    final port = CallbackStandaloneRuntimeSessionPort(
      onLaunch: (_, _, _) async {},
    );
    final result = await port.dispatchPauseCommand(
      const RuntimePlayerPauseCommand.setPartyLead(
        partyTargetId: 'pokemon.absent',
      ),
    );
    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
  });
}
