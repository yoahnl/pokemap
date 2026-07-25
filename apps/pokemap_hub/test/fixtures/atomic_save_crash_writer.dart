import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/pokemap_hub.dart';

Future<void> main(List<String> arguments) async {
  final stage = SaveWriteStage.values.byName(arguments[1]);
  final identity = GameIdentity(
    gameId: 'games.example.atomic',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'campaign-v1',
  );
  final store = HubSaveStore(
    supportRoot: Directory(arguments[0]),
    identity: identity,
    faultHook: (seen) async {
      if (seen == stage) exit(86);
    },
  );
  await store.write(
    const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 11),
      status: SaveStatus.active,
      playTimeSeconds: 1,
      state: <String, Object?>{'marker': 'new'},
    ),
  );
}
