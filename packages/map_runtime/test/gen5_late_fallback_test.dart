import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

Uint8List _bank(String magic, String section, int length) {
  final bytes = Uint8List(16 + length);
  bytes.setRange(0, 4, magic.codeUnits);
  bytes.setRange(16, 20, section.codeUnits);
  ByteData.sublistView(bytes).setUint32(20, length, Endian.little);
  return bytes;
}

Gen5BattleSourceBundle _bundleWithLaterInvalidCell({int firstCellSize = 8}) {
  final palette = image.PaletteUint8(16, 4)
    ..setRgba(0, 0, 0, 0, 0)
    ..setRgba(1, 255, 255, 255, 255);
  final atlas = image.Image(
    width: 256,
    height: 128,
    withPalette: true,
    palette: palette,
  );
  for (var y = 0; y < firstCellSize; y++) {
    for (var x = 0; x < firstCellSize; x++) {
      atlas.setPixelIndex(x, y, 1);
    }
  }
  final cells = _bank('RECN', 'KBEC', 60);
  ByteData.sublistView(cells)
    ..setUint16(24, 2, Endian.little)
    ..setUint32(28, 24, Endian.little)
    ..setUint16(48, 1, Endian.little)
    ..setUint16(56, 1, Endian.little)
    ..setUint32(60, 6, Endian.little);
  final maps = _bank('RCMN', 'KBCM', 40);
  ByteData.sublistView(maps)
    ..setUint16(24, 1, Endian.little)
    ..setUint32(28, 16, Endian.little)
    ..setUint16(40, 1, Endian.little);
  Uint8List animation(String magic, {required bool switchCell}) {
    final bytes = _bank(magic, 'KNBA', switchCell ? 60 : 50);
    ByteData.sublistView(bytes)
      ..setUint16(24, 1, Endian.little)
      ..setUint32(28, 16, Endian.little)
      ..setUint32(32, 32, Endian.little)
      ..setUint32(36, switchCell ? 48 : 40, Endian.little)
      ..setUint16(40, switchCell ? 2 : 1, Endian.little)
      ..setUint16(60, 1, Endian.little);
    if (switchCell) {
      ByteData.sublistView(bytes)
        ..setUint32(64, 2, Endian.little)
        ..setUint16(68, 1, Endian.little)
        ..setUint16(74, 1, Endian.little);
    }
    return bytes;
  }

  final nanr = animation('RNAN', switchCell: true);
  final compressed = BytesBuilder()
    ..add([0x11, nanr.length & 255, nanr.length >> 8, 0]);
  for (var i = 0; i < nanr.length; i += 8) {
    compressed.addByte(0);
    compressed.add(nanr.sublist(i, (i + 8).clamp(0, nanr.length)));
  }
  final info = Uint8List(110);
  ByteData.sublistView(info)
    ..setInt32(0, 2, Endian.little)
    ..setInt32(20, firstCellSize * 4096, Endian.little)
    ..setInt32(24, firstCellSize * 4096, Endian.little)
    ..setInt32(68, 17 * 4096, Endian.little)
    ..setInt32(72, 8 * 4096, Endian.little)
    ..setInt32(76, 240 * 4096, Endian.little);
  final png = image.encodePng(atlas);
  final pal = Uint8List.fromList(
    ascii.encode(
      'JASC-PAL\n0100\n16\n0 0 0\n255 255 255\n${List.filled(14, '0 0 0').join('\n')}\n',
    ),
  );
  return Gen5BattleSourceBundle(
    species: 'testmon',
    nationalDex: 1,
    release: 'test-release',
    sourceRepository: 'fuddlesworth/pokebw2',
    sourceRevision: 'a' * 40,
    sourceDirectory: 'res/pokemon/testmon',
    reconstruction: 'test',
    redistributionStatus: 'test',
    assets: {
      for (final side in ['front', 'back']) ...{
        '$side.png': png,
        '${side}_cells.ncer': cells,
        '${side}_animations.nanr.lz11': compressed.toBytes(),
        '${side}_multi_cells.nmcr': maps,
        '${side}_multi_animations.nmar': animation('RAMN', switchCell: false),
        '${side}_info.bin': info,
      },
      'normal.pal': pal,
      'shiny.pal': pal,
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps native pixel proportions and a shared origin across sizes', () async {
    Future<BattleSceneCombatantComponent> actor(int side) async {
      final bundle = _bundleWithLaterInvalidCell(firstCellSize: side);
      final spec = BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.back,
        gen5Source: BattleGen5SpriteSource(
          speciesId: 'testmon', shiny: false, loader: (_) async => bundle,
        ),
      );
      final actor = BattleSceneCombatantComponent(
        sceneSpriteRect: const ui.Rect.fromLTWH(40, 30, 120, 120),
        scenePlatformRect: const ui.Rect.fromLTWH(52, 136, 110, 18),
        sceneFootAnchor: const ui.Offset(102, 140),
        spriteFootXRatio: .68, isPlayerSide: true,
        speciesLabel: 'testmon', initialSpriteSpec: spec,
      );
      await actor.onLoad();
      actor.onMount();
      await actor.sync(speciesLabel: 'testmon', spriteSpec: spec);
      expect(actor.currentSpriteSourcePath, 'gen5:testmon');
      return actor;
    }

    final small = await actor(8);
    final large = await actor(16);
    addTearDown(small.onRemove);
    addTearDown(large.onRemove);
    final smallRect = small.currentRenderedSpriteRect;
    final largeRect = large.currentRenderedSpriteRect;
    expect(largeRect.width / smallRect.width, closeTo(2, .01));
    expect(largeRect.height / smallRect.height, closeTo(2, .01));
    expect(largeRect.left, closeTo(smallRect.left, .01));
    expect(largeRect.top, closeTo(smallRect.top, .01));
    expect(large.stableCameraGeometry.bounds, largeRect);
    large.applyBattleCameraTransform(offset: Vector2(17, -9), scale: 1.2);
    final projected = large.currentRenderedSpriteRect;
    expect(projected.left, closeTo(largeRect.left * 1.2 + 17, .01));
    expect(projected.top, closeTo(largeRect.top * 1.2 - 9, .01));
    expect(projected.width, closeTo(largeRect.width * 1.2, .01));
  });

  test('falls back to GIF when a later skeleton frame is invalid', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gen5-late-fallback-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final gif = File('${directory.path}/front.gif');
    final encoder = image.GifEncoder();
    encoder.addFrame(image.Image(width: 2, height: 2), duration: 10);
    encoder.addFrame(image.Image(width: 2, height: 2), duration: 10);
    await gif.writeAsBytes(encoder.finish()!);
    final spec = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif.path,
      gen5Source: BattleGen5SpriteSource(
        speciesId: 'testmon',
        shiny: false,
        loader: (_) async => _bundleWithLaterInvalidCell(),
      ),
    );
    final component = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 100, 100),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 90, 100, 10),
      sceneFootAnchor: const ui.Offset(50, 100),
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: 'Testmon',
      initialSpriteSpec: spec,
    );
    addTearDown(component.onRemove);
    await component.onLoad();
    component.onMount();
    await component.sync(speciesLabel: 'Testmon', spriteSpec: spec);
    expect(component.currentSpriteSourcePath, 'gen5:testmon');
    component.update(1 / 60 + 0.001);
    for (
      var i = 0;
      i < 100 && component.currentSpriteSourcePath != gif.path;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(component.currentSpriteSourcePath, gif.path);
  });
}
