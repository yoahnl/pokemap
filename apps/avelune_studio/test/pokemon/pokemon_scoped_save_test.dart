import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'pokemon_scoped_save_fixture.dart';

void main() {
  test(
    'scoped Pokemon edits preserve the execution profile of a 3D project',
    () async {
      final fixture = await ScopedSaveFixture.open(0, spatial: true);
      addTearDown(fixture.close);
      final before = await fixture.combat.load();
      final commerce = await fixture.commerce.load();
      await fixture.combat.saveTable(
        before.project.encounterTables.single,
        before.project.encounterTables.single.copyWith(name: 'Spatial table'),
      );
      await fixture.combat.saveTrainer(
        before.project.trainers.single,
        before.project.trainers.single.copyWith(name: 'Spatial trainer'),
      );
      await fixture.commerce.saveShop(
        commerce.shops.single,
        commerce.shops.single.copyWith(label: 'Spatial shop'),
      );
      await fixture.commerce.saveBagCapacity(
        commerce.project.bagCapacity,
        const ProjectBagCapacity(
          pockets: {'items': BagPocketCapacity(maxDistinctItems: 5)},
        ),
      );
      await fixture.combat.setRuleset(
        before.project.pokemon.ruleset,
        PokemonRulesetProfile.pokeMapBetaV1,
      );
      final after = await fixture.maps.resourceBaseline(fixture.session);
      expect(after.manifest.version, ProjectVersion.v9);
      expect(after.manifest.settings.dimension, ProjectDimension.threeD);
      expect(after.manifest.settings.spatialCamera, isNotNull);
      expect(
        (await fixture.combat.load()).project.trainers.single.name,
        'Spatial trainer',
      );
    },
  );

  test('first save works without a preloaded map workspace', () async {
    final fixture = await ScopedSaveFixture.open(0);
    addTearDown(fixture.close);
    final adapter = LocalPokemonCommerceAdapter(
      session: fixture.session,
      mapAdapter: LocalMapWorkspaceAdapter(reader: fixture.reader),
      reader: fixture.reader,
    );
    final before = (await adapter.load()).catalog!.entries.single;
    await adapter.saveItem(before, before.copyWith(displayName: 'Autonomous'));
    expect(
      (await adapter.load()).catalog!.entries.single.displayName,
      'Autonomous',
    );
  });

  for (final nativeJson in [false, true]) {
    test(
      'recovered ${nativeJson ? 'native JSON' : 'catalog'} publication is verified before Studio acknowledges success',
      () async {
        final fixture = await ScopedSaveFixture.open(
          0,
          nativeJson: nativeJson,
          configuredNewGame: nativeJson,
        );
        addTearDown(fixture.close);
        var injected = false;
        final adapter = LocalPokemonCommerceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          reader: fixture.reader,
          faultInjector: (checkpoint) {
            if (!injected &&
                checkpoint.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted) {
              injected = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        final before = (await adapter.load()).shops.single;
        await adapter.saveShop(before, before.copyWith(label: 'Recovered'));
        expect(injected, isTrue);
        expect((await adapter.load()).shops.single.label, 'Recovered');
      },
    );
  }

  test('concurrent HEAD publication after verification does not merge across catalog generations', () async {
    final fixture = await ScopedSaveFixture.open(0);
    addTearDown(fixture.close);
    final transaction = LocalPokemonTransaction(
      session: fixture.session,
      mapAdapter: fixture.maps,
      reader: fixture.reader,
    );
    const after = ProjectBagCapacity(
      pockets: {'items': BagPocketCapacity(maxDistinctItems: 3)},
    );
    final head = File(
      '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
    );
    final initialHead = await head.readAsBytes();
    final before = await fixture.maps.resourceBaseline(fixture.session);
    late List<int> savedHead;
    final warning = await transaction.run(
      actionId: 'bag.capacity.set',
      parameters: after.toJson(),
      allowedStorageKeys: (_) => {'project.json'},
      validateBefore: (_) {},
      validateAfter: (snapshot) {
        expect(snapshot.manifest.bagCapacity, after);
        savedHead = head.readAsBytesSync();
        head.writeAsBytesSync(initialHead);
      },
    );
    expect(warning, contains('Enregistrement confirmé'));
    expect(warning, contains('le projet a changé'));
    expect(
      (await fixture.maps.resourceBaseline(fixture.session))
          .manifest
          .bagCapacity,
      before.manifest.bagCapacity,
    );
    await head.writeAsBytes(savedHead);
    expect((await fixture.commerce.load()).project.bagCapacity, after);
  });
}
