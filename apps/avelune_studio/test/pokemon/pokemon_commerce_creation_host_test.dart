import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('commerce actions remain reachable in a compact window', (
    tester,
  ) async {
    await MapHostFixture.open(
      tester,
      size: const Size(1280, 900),
      textScale: 1.5,
      prepareSource: (source) async {
        final target = File(
          '${source.directory.path}/data/pokemon/catalogs/items.json',
        );
        await target.parent.create(recursive: true);
        await File(
          '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
        ).copy(target.path);
      },
    ).then((host) => host.go('Pokémon'));
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    expect(find.text('Enregistrer'), findsWidgets);
    expect(find.text('Annuler les modifications'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates an item with a battle effect and a shop through Studio', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (source) async {
        final target = File(
          '${source.directory.path}/data/pokemon/catalogs/items.json',
        );
        await target.parent.create(recursive: true);
        await File(
          '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
        ).copy(target.path);
      },
    );
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.text('Créer un objet').last);
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'billet');
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-billet')),
      'Billet du train',
    );
    await tester.tap(find.text('Effets').last);
    await pumpIo(tester);
    await tester.tap(find.text('Ajouter un effet').last);
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    expect(commerce.error, isNull);
    expect(commerce.dirty, false);
    expect(
      commerce.snapshot!.catalog!.entries.any((item) => item.id == 'billet'),
      true,
    );

    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await tester.tap(find.text('Créer une boutique').last);
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'quai');
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Catalogue'));
    await pumpIo(tester);
    await tester.tap(find.text('Ajouter un objet'));
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'Billet du train');
    await pumpIo(tester);
    await tester.tap(find.text('Billet du train').last);
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);

    final reopened = (await tester.runAsync(() async {
      final session = ProjectSession(
        sessionId: 'commerce-create-reopen',
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
    final item = reopened.catalog!.entries.singleWhere(
      (value) => value.id == 'billet',
    );
    expect(item.displayName, 'Billet du train');
    expect(item.uses, isNotEmpty);
    expect(
      reopened.shops
          .singleWhere((shop) => shop.id == 'quai')
          .entries
          .single
          .itemId,
      'billet',
    );
    expect(tester.takeException(), isNull);
  });
}
