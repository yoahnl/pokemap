import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/project/evaluation_project_projection.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';

void main() {
  test(
    'captures, freezes, attests, and disposes one project snapshot',
    () async {
      final repository = await Directory.systemTemp.createTemp(
        'pokemap-eval-projection-',
      );
      addTearDown(() async {
        if (await repository.exists()) await repository.delete(recursive: true);
      });
      final source = Directory(p.join(repository.path, 'project'));
      await source.create();
      await _writeProject(source, pokemonEnabled: false);
      final marker = File(p.join(source.path, 'marker.txt'));
      await marker.writeAsString('captured');

      final projection = await const LocalEvaluationProjectProjectionFactory()
          .create(
            repositoryRoot: repository,
            projectId: 'project',
            runId: 'run-1',
          );
      await marker.writeAsString('mutated');

      expect(
        await File(
          p.join(projection.projectRoot.path, 'marker.txt'),
        ).readAsString(),
        'captured',
      );
      expect(
        projection.projectTreeHash,
        await const ProjectTreeDigest().compute(projection.projectRoot),
      );
      expect(projection.relativeProjectRoot, startsWith('examples/'));

      final projectedRoot = projection.projectRoot;
      await projection.dispose();
      expect(await projectedRoot.exists(), isFalse);
    },
  );

  test(
    'rejects an invalid Pokemon catalog before returning a projection',
    () async {
      final repository = await Directory.systemTemp.createTemp(
        'pokemap-eval-invalid-',
      );
      addTearDown(() async {
        if (await repository.exists()) await repository.delete(recursive: true);
      });
      final source = Directory(p.join(repository.path, 'project'));
      await source.create();
      await _writeProject(source, pokemonEnabled: true);

      await expectLater(
        const LocalEvaluationProjectProjectionFactory().create(
          repositoryRoot: repository,
          projectId: 'project',
          runId: 'run-invalid',
        ),
        throwsA(
          isA<EvaluationProjectProjectionException>().having(
            (error) => error.code,
            'code',
            'pokemon.catalog_not_ready',
          ),
        ),
      );
      final input = Directory(
        p.join(
          repository.path,
          'examples',
          'playable_runtime_host',
          'build',
          'pokemap-eval',
          'input',
        ),
      );
      expect(
        await input.exists() ? await input.list().toList() : const <Object>[],
        isEmpty,
      );
    },
  );
}

Future<void> _writeProject(
  Directory root, {
  required bool pokemonEnabled,
}) async {
  final manifest = ProjectManifest(
    name: 'Projection',
    version: ProjectVersion.v7,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    pokemon: ProjectPokemonConfig(
      enabled: pokemonEnabled,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
  );
  await File(
    p.join(root.path, 'project.json'),
  ).writeAsString(jsonEncode(manifest.toJson()));
}
