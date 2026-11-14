import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

late Directory root;
late LocalPokemonWorkspaceAdapter adapter;
late Gen5Transport transport;

Future<void> setUpGen5Import() async {
  final parent = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ??
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
  );
  await parent.create(recursive: true);
  final temporary = await parent.createTemp('studio-gen5-import-');
  root = Directory(await temporary.resolveSymbolicLinks());
  final files = spatialFeaturePayload('companion');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(utf8.decode(files['project/project.json']!))
        as Map<String, dynamic>,
  );
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  final working = await WorkingProjectCatalog.create(
    store: store,
    projectId: 'studio-gen5-import',
    project: manifest,
  );
  await working.close();
  for (final entry in files.entries) {
    if (entry.key == 'project/project.json') continue;
    final file = File('${root.path}/${entry.key.substring('project/'.length)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  final session = ProjectSession(
    sessionId: 'studio-gen5-import',
    name: 'Studio Gen5 import',
    directoryPath: root.path,
    storage: ProjectSessionStorage.workingCatalog,
  );
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadCatalog(session);
  transport = Gen5Transport();
  adapter = LocalPokemonWorkspaceAdapter(
    session: session,
    mapAdapter: maps,
    externalSource: const PokemonExternalSourceFixture(),
    gen5Source: AveluneGen5BattleSource(client: transport, release: 'test'),
  );
}

final class Gen5Transport implements PokemonBoundedExternalHttpTransport {
  int statusCode = 200;
  int calls = 0;
  bool invalid = false;
  int assetOffset = 0;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    calls++;
    final assets = <String, Object?>{};
    for (var index = 0; index < gen5BattleBundleAssetNames.length; index++) {
      final bytes = Uint8List.fromList([index + 1 + assetOffset]);
      assets[gen5BattleBundleAssetNames[index]] = {
        'encoding': 'base64',
        'size': bytes.length,
        'sha256': invalid ? '0' * 64 : sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      };
    }
    final data = utf8.encode(
      jsonEncode({
        'format': 'gen5-battle-source-v1',
        'game': 'black2-white2',
        'scope': 'default-form',
        'species': 'bulbasaur',
        'nationalDex': 1,
        'reconstruction': 'test',
        'source': {
          'repository': 'fuddlesworth/pokebw2',
          'revision': 'a' * 40,
          'directory': 'res/pokemon/bulbasaur',
          'redistributionStatus': 'test',
        },
        'assets': assets,
      }),
    );
    return PokemonExternalHttpResponse(
      statusCode: statusCode,
      headers: {'x-source-revision': 'a' * 40},
      body: '',
      bodyBytes: Uint8List.fromList(data),
    );
  }
}
