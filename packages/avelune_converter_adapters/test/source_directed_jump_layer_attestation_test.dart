import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'source_directed_jump_study_composer_test.dart' as fixture;
import 'support/literal_tile_fixture.dart';

void main() {
  test(
      'repeated ledges preserve exact traces and distinct source layer hashes per map',
      () async {
    final f = await fixture.jumpFixture(connectedMaps: [
      LiteralFixtureMap(id: 99, width: 4, height: 5, layers: [
        List.filled(20, 384),
        List.generate(20, (index) => index == 9 || index == 10 ? 392 : 0),
        List.filled(20, 0),
      ]),
    ]);
    final source = f.base.draft!.source;
    final resolver = SourceSemanticResolver.forProject(source);
    expect(
        f.base.layerProvenance
            .where((layer) => layer.sourceZ == 1)
            .map((layer) => layer.sourceLayerHash)
            .toSet(),
        hasLength(2));
    final first = await fixture.composeJump(f);
    expect(first.evidence['importedJumpCount'], 5);
    for (final row in (first.evidence['rows'] as List).cast<Map>()) {
      final id = row['sourceMapId'] as int;
      final from = (row['from'] as List).cast<int>();
      final via = (row['via'] as List).cast<int>();
      final landing = (row['landing'] as List).cast<int>();
      final passage = resolver.resolveDirectedJump(
          resolver.cellAt(id, from[0], from[1]),
          resolver.cellAt(id, via[0], via[1]),
          resolver.cellAt(id, landing[0], landing[1]),
          SourceCardinalDirection.values.byName(row['direction'] as String));
      expect(row['sourceTraceHash'], canonicalHashOf(passage.toJson()).value);
    }
    final second = await fixture.composeJump(f);
    expect(canonicalJsonOf(second.evidence), canonicalJsonOf(first.evidence));
    expect(canonicalJsonOf(second.project.toJson()),
        canonicalJsonOf(first.project.toJson()));
    expect(
        canonicalJsonOf({
          for (final map in second.nativeMaps.entries)
            '${map.key}': map.value.toJson()
        }),
        canonicalJsonOf({
          for (final map in first.nativeMaps.entries)
            '${map.key}': map.value.toJson()
        }));
    expect(
        canonicalJsonOf([
          for (final (index, mutation) in second.resourceMutations.indexed)
            mutation.toJson(index)
        ]),
        canonicalJsonOf([
          for (final (index, mutation) in first.resourceMutations.indexed)
            mutation.toJson(index)
        ]));
  });

  test('a bad second ledge remains rejected after the first layer attestation',
      () async {
    final f = await fixture.jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final layer = map.layers
        .whereType<TileLayer>()
        .singleWhere((layer) => layer.name == 'Source Z 1');
    final changed = layer.copyWith(cells: layer.cells.toList()..[12] = 0);
    await expectLater(
        fixture.composeJump(f, maps: {
          98: map.copyWith(layers: [
            for (final original in map.layers)
              if (original.id == layer.id) changed else original,
          ])
        }),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'jumps.native_glyph')));
  });

  test('a later composition still rechecks the sealed source bytes', () async {
    final f = await fixture.jumpFixture();
    expect((await fixture.composeJump(f)).evidence['importedJumpCount'], 3);
    const path = 'Data/Map098.rxdata';
    f.fixture.files.overrides[path] = [...f.fixture.sourceBytes[path]!, 0];
    await expectLater(
        fixture.composeJump(f),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'jumps.source_changed')));
  });
}
