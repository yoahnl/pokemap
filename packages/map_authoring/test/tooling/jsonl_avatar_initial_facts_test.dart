import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_source_fixture.dart' show sourcePng;

void main() {
  test('direct and JSONL avatar facts validate atomically, persist and reopen',
      () async {
    final root = await Directory.systemTemp.createTemp('avatar-facts-jsonl-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/maps').create();
    await Directory('${root.path}/assets').create();
    final manifest = ProjectManifest(name: 'Avatar facts', maps: const [
      ProjectMapEntry(id: 'home', name: 'Home', relativePath: 'maps/home.json'),
    ], tilesets: const [
      ProjectTilesetEntry(
          id: 'actors', name: 'Actors', relativePath: 'assets/actors.png'),
    ], characters: const [
      ProjectCharacterEntry(id: 'a', name: 'A', tilesetId: 'actors'),
      ProjectCharacterEntry(id: 'b', name: 'B', tilesetId: 'actors'),
    ], facts: [
      NarrativeFactDefinition(
          id: 'identity',
          label: 'Identity',
          initialValue: NarrativeValue.integer(-1)),
      NarrativeFactDefinition(
          id: 'label',
          label: 'Label',
          initialValue: const NarrativeValue.string('')),
      NarrativeFactDefinition(id: 'party', label: 'Party'),
    ]);
    final projectFile = File('${root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(manifest.toJson()));
    final mapFile = File('${root.path}/maps/home.json');
    await mapFile.writeAsBytes(encodeMapAuthoringDocument(MapData(
        id: 'home', name: 'Home', size: const GridSize(width: 4, height: 4))));
    await File('${root.path}/assets/actors.png').writeAsBytes(sourcePng());
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy, fileReader: reader, handles: handles),
            snapshotLoader: snapshots),
        mutations: LocalMapAuthoringMutationApi(
            policy: policy, snapshotLoader: snapshots));
    var sequence = 0;
    Future<AuthoringResult> wire(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': 'avatar-${sequence++}',
          'command': command,
          'args': args,
        }))) as Map<String, dynamic>);
    final opened = await wire('open', {'projectRoot': root.path});
    final handle = ProjectHandle(opened.data['projectHandle']! as String);
    final workspace = opened.data['workspaceHandle']! as String;
    final before = await snapshots.load(handle);
    final original = await projectFile.readAsBytes();
    final originalMap = await mapFile.readAsBytes();
    final mapping = <String, Object?>{
      'a': {'identity': 0, 'label': 'first'},
      'b': {'identity': 1, 'label': 'second'},
    };
    final config = ProjectNewGameConfig.fromJson({
      'enabled': true,
      'startMapId': 'home',
      'playerAvatarCharacterIds': ['a', 'b'],
      'initialFactValuesByAvatarCharacterId': mapping,
      'existingPartyFactId': 'party',
    });
    expect(
        const CampaignContentActions().updateNewGame(manifest, config).newGame,
        config);
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((action) => action.id == 'campaign.new_game.update');
    expect(
        (descriptor.extensions['initialFactValuesByAvatarCharacterId']
            as Map)['omitWhenEmpty'],
        isTrue);
    Future<AuthoringResult> plan(Object? values) => wire('plan', {
          'projectHandle': handle.value,
          'request': AuthoringRequest(
              requestId: 'avatar-request-$sequence',
              actionId: 'campaign.new_game.update',
              actionVersion: 1,
              workspaceHandle: workspace,
              expectedRevision: before.revision,
              idempotencyKey: 'avatar-idem-$sequence',
              parameters: {
                'newGame': {
                  ...config.toJson(),
                  'initialFactValuesByAvatarCharacterId': values
                },
              }).toJson(),
        });
    for (final invalid in [
      {
        'unknown': {'identity': 0}
      },
      {
        'a': {'unknown': 0}
      },
      {
        'a': {'identity': true}
      },
      {
        'a': {'label': 0}
      },
      {
        'a': {'party': true}
      },
      {'a': []},
      [],
      null,
    ]) {
      final result = await plan(invalid);
      expect(result.status, isNot(AuthoringResultStatus.success));
      expect(jsonEncode(result.toJson()), isNot(contains('worker.internal')));
      expect(await projectFile.readAsBytes(), original);
      expect((await snapshots.load(handle)).revision, before.revision);
    }
    final prepared = await plan(mapping);
    expect(prepared.status, AuthoringResultStatus.success,
        reason: prepared.toJson().toString());
    final apply = {
      'projectHandle': handle.value,
      'planId': prepared.data['planId'],
      'operationId': 'avatar-apply'
    };
    expect((await wire('apply', apply)).status, AuthoringResultStatus.success);
    final saved = await projectFile.readAsBytes();
    expect((await wire('apply', apply)).status, AuthoringResultStatus.success);
    expect(await projectFile.readAsBytes(), saved);
    final reopened = await wire('open', {'projectRoot': root.path});
    final cold = await snapshots
        .load(ProjectHandle(reopened.data['projectHandle']! as String));
    expect(cold.manifest.newGame, config);
    expect(
        cold.manifest.newGame.toJson()['initialFactValuesByAvatarCharacterId'],
        mapping);
    expect(await mapFile.readAsBytes(), originalMap);
  });
}
