import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../../packages/map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('an older Player refuses localized content without altering its game or save', () async {
    final root = await Directory.systemTemp.createTemp(
      'localized-package-rejection-',
    );
    addTearDown(() => root.delete(recursive: true));
    final support = Directory('${root.path}/support');
    final current = AveluneRuntimeCompatibility.host();
    final older = GamePackageHostCompatibility(
      hubVersion: current.hubVersion,
      runtimeApiVersion: current.runtimeApiVersion,
      supportedRuntimeApiVersions: current.supportedRuntimeApiVersions,
      capabilities: current.capabilities.difference({
        dialogueLocalizationCapability,
      }),
      supportedProjectFormats: current.supportedProjectFormats,
      currentProjectFormat: current.currentProjectFormat,
      currentProjectFormats: current.currentProjectFormats,
      supportedSaveFormats: current.supportedSaveFormats,
    );
    GamePackageManifest manifest(bool localized) {
      final json = spatialManifest(
        capabilities: [
          'map3d@1',
          if (localized) dialogueLocalizationCapability,
        ],
      ).toJson();
      json['gameVersion'] = localized ? '0.2.0' : '0.1.0';
      (json['compatibility'] as Map).addAll(<String, Object?>{
        'minHubVersion': '0.1.0',
        'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
      });
      json['locales'] = {
        'default': 'fr',
        'supported': ['fr', 'en'],
      };
      return const GamePackageManifestCodec().decodeJson(json);
    }

    final service = GamePackageInstaller(
      supportRoot: support,
      inspector: GamePackageInspector(hostCompatibility: older),
      availableDiskBytes: (_) async => 1 << 30,
      loadSmoke: (staged, _) async {
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: '${staged.path}/project/project.json',
          mapId: 'map',
        );
        expect(bundle.map.id, 'map');
      },
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    );
    final base = const GamePackageBuilder().build(
      manifest: manifest(false),
      payloadFiles: spatialPayload(),
    );
    final baseFile = await File('${root.path}/base.avelunegame')
        .writeAsBytes(base.packageBytes);
    final installed = await service.install(
      baseFile,
      source: GamePackageInstallSource.localFile,
    );
    final launch = await InstalledGameLaunchResolver(
      supportRoot: support,
      hostCompatibility: older,
    ).resolve(installed.game);
    final state = GameState(
      saveId: 'f1a66236-3c7c-49e5-91e4-a77bac5d0021',
      currentMapId: 'map',
      playerPosition: const GridPos(x: 6, y: 6),
      playerSpatialPosition: PlayerSpatialPosition(x: 6, z: 6),
    );
    final envelope = const GameStateSaveEnvelopeMapper().create(
      identity: launch.identity,
      profileId: 'local',
      slotId: 'slot-1',
      saveId: state.saveId,
      createdAt: DateTime.utc(2026, 11, 17),
      updatedAt: DateTime.utc(2026, 11, 17),
      status: SaveStatus.active,
      playTimeSeconds: 7,
      gameState: state,
    );
    final store = HubSaveStore(supportRoot: support, identity: launch.identity);
    await store.writeVerified(envelope);
    final before = await _files(support);
    final payload = spatialPayload();
    final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(payload['project/project.json']!)),
    );
    final document = const YarnDialogueCompiler().compile(
      'title: Start\n---\nBonjour\n===\n',
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
    payload['project/project.json'] = utf8.encode(
      jsonEncode(
        project
            .copyWith(
              dialogues: [
                ProjectDialogueEntry(
                  id: 'talk',
                  name: 'Talk',
                  relativePath: 'dialogues/talk.json',
                  localization: localization,
                ),
              ],
            )
            .toJson(),
      ),
    );
    payload['project/dialogues/talk.json'] =
        const RuntimeDialogueDocumentCodec().encodeUtf8(document);
    final localized = const GamePackageBuilder().build(
      manifest: manifest(true),
      payloadFiles: payload,
    );
    final candidate = await File('${root.path}/localized.avelunegame')
        .writeAsBytes(localized.packageBytes);
    await expectLater(
      service.install(candidate, source: GamePackageInstallSource.localFile),
      throwsA(
        isA<GameInstallationException>().having(
          (error) => error.cause,
          'cause',
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'capabilityUnsupported',
          ),
        ),
      ),
    );
    expect(await _files(support), before);
    expect(await baseFile.readAsBytes(), base.packageBytes);
    expect(await candidate.readAsBytes(), localized.packageBytes);
    final restored =
        await HubPlayerSaveGateway(
          store: HubSaveStore(supportRoot: support, identity: launch.identity),
        ).readLaunchableEnvelope(
          SaveSlotAddress(
            gameId: launch.identity.gameId,
            profileId: 'local',
            slotId: 'slot-1',
          ),
        );
    expect(const GameStateSaveEnvelopeMapper().restore(restored!), state);
  });
}

Future<Map<String, List<int>>> _files(Directory root) async => {
  await for (final entity in root.list(recursive: true, followLinks: false))
    if (entity is File)
      p.relative(entity.path, from: root.path): await entity.readAsBytes(),
};
