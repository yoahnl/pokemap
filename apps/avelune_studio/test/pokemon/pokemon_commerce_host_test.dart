import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_commerce_integer_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('objects and shops persist through the real workspace', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final captureKey = GlobalKey();
    final host = await MapHostFixture.open(
      tester,
      prepareSource: _seed,
      captureKey: captureKey,
    );
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    expect(find.textContaining('Objets ·'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'lot-b-01-objets');

    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-02-objet-fiche');
    await tester.enterText(
      find.byKey(const ValueKey('item-name-potion')),
      'Potion du quai',
    );
    await tester.tap(find.text('Effets').last);
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-03-objet-effets');
    await tester.tap(find.text('Usages et références').last);
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-04-objet-references');
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    expect(commerce.error, isNull);
    expect(commerce.dirty, false);

    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-05-boutiques');
    await tester.tap(find.byKey(const ValueKey('shop-gare')));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-06-boutique-fiche');
    await tester.tap(find.widgetWithText(TextButton, 'Catalogue'));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-07-boutique-catalogue');
    if (find.text('Ajouter un objet').evaluate().isEmpty) {
      fail(
        'view=${tester.widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage)).controller!.view} section=${commerce.section} texts=${tester.widgetList<Text>(find.byType(Text)).map((value) => value.data).whereType<String>().join(' | ')}',
      );
    }
    await tester.tap(find.text('Ajouter un objet'));
    await pumpIo(tester);
    await tester.tap(find.text('Potion du quai').last);
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(commerce.error, isNull);
    expect(commerce.dirty, false);
    await tester.tap(find.widgetWithText(TextButton, 'Références'));
    await pumpIo(tester);
    await captureM3Widget(tester, captureKey, 'lot-b-08-boutique-references');

    final reopened = (await tester.runAsync(() async {
      final session = ProjectSession(
        sessionId: 'commerce-reopen',
        name: host.source.session.name,
        directoryPath: host.source.directory.path,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(session);
      return LocalPokemonCommerceAdapter(
        session: session,
        mapAdapter: maps,
      ).load();
    }))!;
    expect(
      reopened.catalog!.entries
          .firstWhere((item) => item.id == 'potion')
          .displayName,
      'Potion du quai',
    );
    expect(
      reopened.shops
          .singleWhere((shop) => shop.id == 'gare')
          .entries
          .single
          .itemId,
      'potion',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog revision conflict preserves focused draft', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-potion')),
      'Brouillon local',
    );
    await tester.pump();
    final before = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    expect(before.dirty, true, reason: '${before.item?.displayName}');
    await tester.runAsync(() async {
      final file = File(
        '${host.source.directory.path}/data/pokemon/catalogs/items.json',
      );
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (json['entries'] as List).first['displayName'] = 'Modification externe';
      await file.writeAsString(jsonEncode(json));
    });
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    expect(
      commerce.error,
      contains('changé sur le disque'),
      reason:
          'dirty=${commerce.dirty} saving=${commerce.saving} item=${commerce.item?.displayName}',
    );
    expect(find.textContaining('changé sur le disque'), findsWidgets);
    expect(find.text('Brouillon local'), findsWidgets);
    final text = (await tester.runAsync(
      () async => File(
        '${host.source.directory.path}/data/pokemon/catalogs/items.json',
      ).readAsString(),
    ))!;
    expect(text, contains('Modification externe'));
    expect(text, isNot(contains('Brouillon local')));
  });

  testWidgets(
    'JSON import previews without writing and requires replacement consent',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      late String importPath;
      final host = await MapHostFixture.open(
        tester,
        prepareSource: (source) async {
          await _seed(source);
          importPath = '${source.directory.path}/import-item.json';
          await File(importPath).writeAsString(
            jsonEncode(
              const ProjectItemDefinition(
                id: 'potion',
                displayName: 'Potion importée',
                pocketId: 'medicine',
              ).toJson(),
            ),
          );
        },
        pokemonJsonPicker: () async => importPath,
        captureKey: captureKey,
      );
      await host.go('Pokémon');
      await tester.tap(find.text('Objets').first);
      await pumpIo(tester);
      final catalogFile = File(
        '${host.source.directory.path}/data/pokemon/catalogs/items.json',
      );
      final original = (await tester.runAsync(catalogFile.readAsBytes))!;
      await tester.tap(find.text('Importer un JSON'));
      await pumpIo(tester);
      expect(find.text('Remplacer Potion importée ?'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'lot-b-09-import-preview');
      expect((await tester.runAsync(catalogFile.readAsBytes))!, original);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester);
      expect((await tester.runAsync(catalogFile.readAsBytes))!, original);

      await tester.tap(find.text('Importer un JSON'));
      await pumpIo(tester);
      await tester.tap(find.text('Remplacer').last);
      await pumpIo(tester);
      final reopened = (await tester.runAsync(() async {
        final session = ProjectSession(
          sessionId: 'commerce-import-reopen',
          name: host.source.session.name,
          directoryPath: host.source.directory.path,
        );
        final maps = LocalMapWorkspaceAdapter();
        await maps.loadProject(session);
        return LocalPokemonCommerceAdapter(
          session: session,
          mapAdapter: maps,
        ).load();
      }))!;
      expect(
        reopened.catalog!.entries
            .singleWhere((item) => item.id == 'potion')
            .displayName,
        'Potion importée',
      );
    },
  );

  testWidgets('invalid focused price blocks save and leaving keeps the draft', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('shop-gare')));
    await pumpIo(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Catalogue'));
    await pumpIo(tester);
    await tester.tap(find.text('Ajouter un objet'));
    await pumpIo(tester);
    await tester.tap(find.text('Potion').last);
    await pumpIo(tester);
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    final field = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is PokemonCommerceIntegerField &&
            widget.fieldId == 'shop-gare-0-price',
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '');
    await pumpIo(tester);
    expect(commerce.fieldErrors, isNotEmpty);
    expect(commerce.dirty, true);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(commerce.error, contains('Corrigez les nombres'));
    await host.go('Carte');
    expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
    await tester.tap(find.text('Rester'));
    await pumpIo(tester);
    expect(commerce.shop!.entries, hasLength(1));
    await tester.tap(find.text('Annuler les modifications').last);
    await pumpIo(tester);
    expect(commerce.dirty, false);
    expect(commerce.shop!.entries, isEmpty);
  });
}

Future<void> _seed(M3StoryFixture fixture) async {
  final root = fixture.directory.path;
  final target = File('$root/data/pokemon/catalogs/items.json');
  await target.parent.create(recursive: true);
  final source = File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
  );
  await source.copy(target.path);
  final manifestFile = File('$root/project.json');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
  );
  final updated = manifest.copyWith(
    shops: [const ShopDefinition(id: 'gare', label: 'Boutique de la gare')],
  );
  await manifestFile.writeAsString(jsonEncode(updated.toJson()));
}
