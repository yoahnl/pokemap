import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';

final class _FixtureMedia implements PokemonBoundedExternalHttpTransport {
  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    final listing = uri.path.contains('/owners/move/');
    final move = listing
        ? uri.pathSegments.last
        : uri.pathSegments.last.replaceFirst('-recipe', '');
    final recipe = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'recipeId': '$move-recipe',
      'revision': '1',
      'moveSourceId': move,
      'variant': 'default',
      'requiredCapabilities': ['wait'],
      'provenance': {
        'source': 'synthetic',
        'sourceRevision': '1',
        'sourcePaths': <String>[],
        'converter': 'test'
      },
      'resources': <Object>[],
      'program': {'kind': 'wait', 'durationMs': 1},
    }));
    final bytes = listing
        ? utf8.encode(jsonEncode([
            {
              'id': '$move-recipe',
              'sha256': sha256.convert(recipe).toString(),
              'contentType': 'application/vnd.avelune.battle-recipe+json',
              'usage': 'battle',
              'representation': 'recipe',
              'style': 'gen5-bw2',
              'metadata': {
                'recipeId': '$move-recipe',
                'moveSourceId': move,
                'revision': '1',
                'variant': 'default',
                'bindings': <String, String>{}
              },
            }
          ]))
        : recipe;
    return PokemonExternalHttpResponse(
        statusCode: 200,
        headers: const {},
        body: listing ? utf8.decode(bytes) : '',
        bodyBytes: Uint8List.fromList(bytes));
  }
}

Future<void> main(List<String> arguments) async {
  final rootIndex = arguments.indexOf('--root');
  if (rootIndex < 0) throw ArgumentError('The test worker requires --root.');
  final root = arguments[rootIndex + 1];
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
      initializeSceneOwners: false);
  final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      enablePokemonRecipeNetwork: true);
  final worker = JsonlWorker(
      api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
      mutations: mutations,
      moveRecipeBatch: BattleMoveRecipeBatchService(
          openService: opener, authoring: mutations, client: _FixtureMedia()));
  try {
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      stdout.writeln(await worker.processLine(line));
      await stdout.flush();
    }
  } finally {
    await worker.close();
  }
}
