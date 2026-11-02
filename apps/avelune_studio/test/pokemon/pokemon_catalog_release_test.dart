import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class RecordingHttpClient implements HttpClient {
  RecordingHttpClient(this.requests);

  final List<Uri> requests;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add(url);
    throw const SocketException('offline test');
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final release in [null, 'public-2026-11-02', '../invalid']) {
    test('Studio uses the project release $release for search', () async {
      final parent = Directory(Platform.environment['AVELUNE_QA_ROOT']!);
      final root = await parent.createTemp('release-search-');
      addTearDown(() => root.delete(recursive: true));
      final manifest = ProjectManifest(
        name: 'Release test',
        maps: const [],
        tilesets: const [],
        pokemon: ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogRelease: release,
        ),
      );
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'release-search',
        project: manifest,
      );
      await working.close();
      final session = ProjectSession(
        sessionId: 'release-search',
        name: 'Release test',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final requests = <Uri>[];
      await HttpOverrides.runZoned(() async {
        final adapter = LocalPokemonWorkspaceAdapter(
          session: session,
          mapAdapter: maps,
        );
        if (release == '../invalid') {
          await expectLater(
            adapter.searchExternal('pidgey'),
            throwsA(isA<PokemonWorkspaceFailure>()),
          );
        } else {
          await adapter.searchExternal('pidgey');
        }
        await adapter.close();
      }, createHttpClient: (_) => RecordingHttpClient(requests));
      if (release == '../invalid') {
        expect(requests, isEmpty);
        return;
      }
      expect(requests, hasLength(1));
      expect(
        requests.single.path,
        '/v1/compat/${release ?? 'public-2026-11'}/showdown/pokedex.json',
      );
    });
  }
}
