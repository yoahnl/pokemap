import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_item_effects.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'imports a capture sprite into the draft before saving its item',
    () async {
      final port = _CommercePort();
      final commerce = PokemonCommerceController(port, changed: () {});
      await commerce.load();
      commerce.selectItem(_ball);
      await commerce.importCaptureSprite(sourcePath: '/picked.png');

      expect(commerce.item!.capture!.animationSpritePath, _path);
      expect(commerce.dirty, isTrue);
      expect(port.saved, isNull);
      expect(port.imports, 1);
      expect(await commerce.save(), isTrue);
      expect(port.saved!.capture!.animationSpritePath, _path);
      expect(commerce.dirty, isFalse);
      commerce.dispose();
    },
  );

  test('failed capture sprite import preserves the draft', () async {
    final port = _CommercePort()..failure = StateError('PNG invalide');
    final commerce = PokemonCommerceController(port, changed: () {});
    await commerce.load();
    commerce.selectItem(_ball);
    commerce.editItem((item) => item.copyWith(displayName: 'Brouillon'));
    final before = commerce.item;
    await commerce.importCaptureSprite(sourcePath: '/picked.png');

    expect(commerce.item, before);
    expect(commerce.error, contains('PNG invalide'));
    expect(commerce.importing, isFalse);
    expect(port.saved, isNull);
    commerce.dispose();
  });

  test('capture import locks draft changes and stops when disposed', () async {
    final port = _CommercePort()..gate = Completer<void>();
    final commerce = PokemonCommerceController(port, changed: () {});
    await commerce.load();
    commerce.selectItem(_ball);
    final importing = commerce.importCaptureSprite(sourcePath: '/picked.png');
    expect(commerce.importing, isTrue);
    expect(commerce.selectItem(_ball.copyWith(id: 'other')), isFalse);
    commerce.editItem((item) => item.copyWith(displayName: 'Wrong'));
    commerce.discardSelected();
    expect(commerce.item, _ball);
    expect(await commerce.save(), isFalse);
    commerce.dispose();
    port.gate!.complete();
    await importing;
    expect(commerce.item, _ball);
    expect(port.saved, isNull);
  });

  testWidgets('picker updates the draft and can remove its animation', (
    tester,
  ) async {
    final port = _CommercePort();
    VoidCallback redraw = () {};
    final commerce = PokemonCommerceController(port, changed: () => redraw());
    await commerce.load();
    commerce.selectItem(_ball);
    addTearDown(commerce.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = () => setState(() {});
              return SingleChildScrollView(
                child: PokemonItemEffects(
                  commerce: commerce,
                  pickPng: () async => '/picked.png',
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Aucune animation choisie.'), findsOneWidget);
    await tester.ensureVisible(find.text('Choisir une planche PNG'));
    await tester.tap(find.text('Choisir une planche PNG'));
    await tester.pumpAndSettle();
    expect(port.imports, 1);
    expect(port.saved, isNull);
    expect(commerce.item!.capture!.animationSpritePath, _path);
    expect(commerce.item!.capture!.rateNumerator, 1);
    expect(commerce.item!.capture!.allowedEncounterKinds, {EncounterKind.walk});
    expect(find.byType(Image), findsOneWidget);
    await tester.ensureVisible(find.text('Retirer l’animation'));
    await tester.tap(find.text('Retirer l’animation'));
    await tester.pumpAndSettle();
    expect(commerce.item!.capture!.animationSpritePath, isNull);
    expect(find.text('Aucune animation choisie.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled PNG selection leaves the item untouched', (
    tester,
  ) async {
    final port = _CommercePort();
    final commerce = PokemonCommerceController(port, changed: () {});
    await commerce.load();
    commerce.selectItem(_ball);
    addTearDown(commerce.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PokemonItemEffects(
              commerce: commerce,
              pickPng: () async => null,
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Choisir une planche PNG'));
    await tester.tap(find.text('Choisir une planche PNG'));
    await tester.pumpAndSettle();
    expect(port.imports, 0);
    expect(commerce.item, _ball);
    expect(commerce.dirty, isFalse);
    commerce.selectItem(_ball.copyWith(capture: null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PokemonItemEffects(
              commerce: commerce,
              pickPng: () async => '/picked.png',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Animation de capture'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
              await File(
                '${fixture.directory.path}/$assetCatalogStorageKey',
              ).readAsString(),
            )
            as Map<String, dynamic>,
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
          await File(
            '${fixture.directory.path}/$assetCatalogStorageKey',
          ).exists(),
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

const _path = 'data/pokemon/assets/items/capture/custom.png';
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

final class _CommercePort implements PokemonCommercePort {
  ProjectItemDefinition? saved;
  Object? failure;
  int imports = 0;
  Completer<void>? gate;

  @override
  Future<String> importCaptureSprite({
    required String sourcePath,
    required String itemId,
    bool Function()? shouldContinue,
  }) async {
    imports++;
    await gate?.future;
    if (failure != null) throw failure!;
    if (shouldContinue?.call() == false) throw StateError('Cancelled');
    return _path;
  }

  @override
  Future<Uint8List?> loadCaptureSprite(String path) async => _png(64, 2048);

  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) async {
    saved = after;
  }

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Capture', maps: [], tilesets: []),
    catalog: ProjectItemCatalog(schemaVersion: 1, entries: [saved ?? _ball]),
    shops: const [],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [],
    catalogPath: 'data/pokemon/catalogs/items.json',
    problem: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
