import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical adapter imports exact PNG bytes before item update',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final bytes = _png(64, 2048);
      final source = File('${fixture.directory.path}/chosen.png');
      await source.writeAsBytes(bytes);
      final before = await fixture.catalogFile.readAsBytes();
      final path = await fixture.adapter.importCaptureSprite(
        sourcePath: source.path,
        itemId: _ball.id,
      );

      expect(path, startsWith('data/pokemon/assets/items/capture/'));
      expect(
        await File('${fixture.directory.path}/$path').readAsBytes(),
        bytes,
      );
      expect(await fixture.catalogFile.readAsBytes(), before);
      final assets = AssetCatalog.fromJson(
        jsonDecode(
          await File('${fixture.directory.path}/$assetCatalogStorageKey')
              .readAsString(),
        ) as Map<String, dynamic>,
      );
      expect(assets.records.single.logicalPath, path);
      expect(assets.records.single.usages, contains('item:${_ball.id}'));
      final updated = _ball.copyWith(
        capture: _ball.capture!.copyWith(animationSpritePath: path),
      );
      await fixture.adapter.saveItem(_ball, updated);
      expect((await fixture.adapter.load()).catalog!.entries.single, updated);
      expect(await fixture.adapter.loadCaptureSprite(path), bytes);
      expect(
        await fixture.adapter.importCaptureSprite(
          sourcePath: source.path,
          itemId: _ball.id,
        ),
        path,
      );
    },
  );

  test(
    'adapter rejects wrong dimensions and corrupt PNG before mutation',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.catalogFile.readAsBytes();
      final source = File('${fixture.directory.path}/chosen.png');
      for (final bytes in [
        _png(64, 64),
        _png(32, 2048),
        _png(64, 2048).sublist(0, 33),
      ]) {
        await source.writeAsBytes(bytes);
        await expectLater(
          fixture.adapter.importCaptureSprite(
            sourcePath: source.path,
            itemId: _ball.id,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(await fixture.catalogFile.readAsBytes(), before);
        expect(
          await File('${fixture.directory.path}/$assetCatalogStorageKey')
              .exists(),
          isFalse,
        );
        expect(
          await Directory(
            '${fixture.directory.path}/data/pokemon/assets/items/capture',
          ).exists(),
          isFalse,
        );
      }
    },
  );
}

const _ball = ProjectItemDefinition(
  id: 'custom-ball',
  displayName: 'Custom Ball',
  pocketId: 'balls',
  capture: ProjectCaptureItemDefinition(
    rateNumerator: 1,
    rateDenominator: 1,
    allowedEncounterKinds: {EncounterKind.walk},
  ),
);

Uint8List _png(int width, int height) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: height)));

final class _Fixture {
  _Fixture(this.directory, this.adapter, this.catalogFile);
  final Directory directory;
  final LocalPokemonCommerceAdapter adapter;
  final File catalogFile;

  static Future<_Fixture> create() async {
    final temp = await Directory.systemTemp.createTemp(
      'studio_capture_sprite_',
    );
    final directory = Directory(await temp.resolveSymbolicLinks());
    final catalogFile = File(
      '${directory.path}/data/pokemon/catalogs/items.json',
    );
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          ProjectItemCatalog(schemaVersion: 1, entries: const [_ball]),
        ),
      ),
    );
    await File('${directory.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Capture',
          maps: const [],
          tilesets: const [],
          pokemon: const ProjectPokemonConfig(
            enabled: true,
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'data/pokemon/catalogs/items.json'},
          ),
        ).toJson(),
      ),
    );
    return _Fixture(
      directory,
      LocalPokemonCommerceAdapter(
        session: ProjectSession(
          sessionId: directory.path,
          name: 'Capture',
          directoryPath: directory.path,
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
      ),
      catalogFile,
    );
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
