import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('animation references and custom local PNG reopen from disk', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        for (final (folder, file) in [
          ('species', '0001-bulbasaur.json'),
          ('media', 'bulbasaur.json'),
        ]) {
          final destination = File(
            '${fixture.directory.path}/data/pokemon/$folder/$file',
          );
          final json =
              jsonDecode(await File('$sourcePath/$folder/$file').readAsString())
                  as Map<String, dynamic>;
          json['schemaVersion'] = 1;
          if (folder == 'media') {
            final variant = (json['variants'] as Map)['base'] as Map;
            ((variant['animations'] as Map)['idle'] as Map)['sheet'] =
                'assets/custom/battle.png';
          }
          await destination.parent.create(recursive: true);
          await destination.writeAsString(jsonEncode(json));
        }
        final image = File(
          '${fixture.directory.path}/assets/custom/battle.png',
        );
        await image.parent.create(recursive: true);
        await File(sourcePng).copy(image.path);
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.tap(find.text('Médias').last);
    await pumpIo(tester);
    final animation = find.text('Animation idle');
    await tester.ensureVisible(animation);
    expect(animation, findsOneWidget);
    final animationId = find.byKey(
      const ValueKey('media-variants.base.animations.idle.animationId'),
    );
    await tester.ensureVisible(animationId);
    await tester.enterText(animationId, 'idle-train');
    await tester.pump();
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final bundle = (await tester.runAsync(() async {
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      final entry = (await adapter.loadIndex()).entries.single;
      final image = await adapter.loadImage('assets/custom/battle.png');
      return (await adapter.loadSpecies(entry), image);
    }))!;
    final media = bundle.$1.media!.document!;
    final variant = (media['variants'] as Map)['base'] as Map;
    final idle = (variant['animations'] as Map)['idle'] as Map;
    expect(idle['sheet'], 'assets/custom/battle.png');
    expect(idle['animationId'], 'idle-train');
    expect(bundle.$2, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
const sourcePng =
    '../../examples/playable_runtime_host/golden_item_system/assets/pokemon/sprites/sproutle/front.png';
