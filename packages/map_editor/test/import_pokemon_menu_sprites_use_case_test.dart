import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_menu_sprites_use_case.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test(
    'editor previews, imports multiple canonical batches and preserves portraits on rerun',
    () async {
      final root = await Directory.systemTemp.createTemp('editor-menu-import-');
      final source = await Directory.systemTemp.createTemp(
        'editor-menu-source-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => source.delete(recursive: true));
      Future<void> json(String path, Object value) async {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(value));
      }

      await json(
        '${root.path}/project.json',
        const ProjectManifest(
          name: 'Generic creatures',
          maps: [],
          tilesets: [],
        ).toJson(),
      );
      for (var index = 0; index < 51; index++) {
        final id = 'creature_$index';
        await json('${root.path}/data/pokemon/species/$id.json', {
          'schemaVersion': currentPokemonDataSchemaVersion,
          'id': id,
          'nationalDex': index == 50 ? 2 : 1,
          'forms': {'formId': 'base'},
          'refs': {'media': '$id-media'},
        });
        await json(
          '${root.path}/data/pokemon/media/$id-media.json',
          PokemonMediaFile(
            speciesId: '$id-media',
            defaultFormId: 'base',
            variants: const {
              'base': PokemonMediaVariant(portrait: 'assets/my-drawing.png'),
            },
          ).toJson(),
        );
      }
      await json('${source.path}/data/species.json', {
        's32': {'sid': 's32', 'num': 1, 'formeNum': 0, 'forme': ''},
        's64': {'sid': 's64', 'num': 2, 'formeNum': 0, 'forme': ''},
      });
      final png = File('${source.path}/src/minisprites/pokemon/home/s32.png');
      await png.parent.create(recursive: true);
      await png.writeAsBytes(image.encodePng(image.Image(width: 8, height: 8)));
      await png.copy('${source.path}/src/minisprites/pokemon/home/s64.png');
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final service = ImportPokemonMenuSpritesUseCase(
        repository: FilePokemonReadRepository(),
        mutations: mutations,
      );
      final workspace = ProjectFileSystem(root.path);
      final preview = await service.preview(
        workspace,
        sourceDirectory: source.path,
      );
      expect(preview.additions, 102);
      expect(preview.batches.length, 2);
      expect(preview.handles.length, 1);
      final before = jsonDecode(
        await File(
          '${root.path}/data/pokemon/media/creature_0-media.json',
        ).readAsString(),
      );
      expect(before['variants']['base']['icon'], isNull);
      expect(await service.execute(preview), 102);
      await service.release(preview);
      await expectLater(
        mutations.readArtifact(root.path, handle: preview.handles.single),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (error) => error.code,
            'code',
            'artifact.unknown',
          ),
        ),
      );
      final after = jsonDecode(
        await File(
          '${root.path}/data/pokemon/media/creature_0-media.json',
        ).readAsString(),
      );
      expect(after['variants']['base']['portrait'], 'assets/my-drawing.png');
      expect(
        after['variants']['base']['icon'],
        after['variants']['base']['party'],
      );
      final rerun = await service.preview(
        workspace,
        sourceDirectory: source.path,
      );
      expect(rerun.additions, 0);
      expect(rerun.preserved, 102);
      await service.release(rerun);
      after['variants']['base'].remove('icon');
      after['variants']['base'].remove('party');
      await json(
        '${root.path}/data/pokemon/media/creature_0-media.json',
        after,
      );
      var changed = false;
      await expectLater(
        service.preview(
          workspace,
          sourceDirectory: source.path,
          resolveSourceFile: (relative) async {
            if (!changed) {
              changed = true;
              final speciesPath =
                  '${root.path}/data/pokemon/species/creature_0.json';
              final species = jsonDecode(
                await File(speciesPath).readAsString(),
              );
              species['nationalDex'] = 2;
              await json(speciesPath, species);
            }
            return '${source.path}/$relative';
          },
        ),
        throwsA(isA<EditorAuthoringMutationFailure>()),
      );
      final unchanged = jsonDecode(
        await File(
          '${root.path}/data/pokemon/media/creature_0-media.json',
        ).readAsString(),
      );
      expect(unchanged['variants']['base']['icon'], isNull);
    },
  );
}
