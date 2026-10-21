import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('Studio authors and reloads Full Restore in both contexts', (
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
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    await tester.tap(find.text('Effets').last);
    await pumpIo(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Soigner les PV').first);
      await tester.pumpAndSettle();
      expect(find.text('Soin Total'), findsWidgets);
      await tester.tap(find.text('Soin Total').last);
      await pumpIo(tester);
    }
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    for (final context in [
      ProjectItemUseContext.overworld,
      ProjectItemUseContext.battle,
    ]) {
      final use = commerce.item!.uses.singleWhere(
        (u) => u.contexts.contains(context),
      );
      expect(use.effect, const ProjectItemEffectDefinition.fullRestore());
      expect(use.target, ProjectItemTargetKind.partyMember);
      expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
    }
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(commerce.error, isNull);
    expect(commerce.dirty, isFalse);
    final reopened = (await tester.runAsync(() async {
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(host.source.session);
      return LocalPokemonCommerceAdapter(
        session: host.source.session,
        mapAdapter: maps,
      ).load();
    }))!;
    final item = reopened.catalog!.entries.singleWhere((i) => i.id == 'potion');
    expect(item.uses, hasLength(2));
    expect(
      item.uses.every(
        (u) => u.effect == const ProjectItemEffectDefinition.fullRestore(),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
