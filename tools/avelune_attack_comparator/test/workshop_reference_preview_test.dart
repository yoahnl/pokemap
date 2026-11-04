import 'dart:convert';
import 'dart:io';

import 'package:avelune_attack_compare/main.dart' show extractPreviewResources;
import 'package:avelune_attack_compare/preview_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobal = MethodChannel('xyz.luan/audioplayers.global');
  const audioEvents = MethodChannel('xyz.luan/audioplayers.global/events');
  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioGlobal, (_) async => null);
    messenger.setMockMethodCallHandler(audioEvents, (_) async => null);
  });
  tearDownAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioGlobal, null);
    messenger.setMockMethodCallHandler(audioEvents, null);
  });

  test('bundles the reference Pokemon manifest', () async {
    final data = jsonDecode(await rootBundle.loadString(
      'assets/bw2/reference_pokemon.json',
    )) as Map<String, dynamic>;
    expect((data['references'] as Map)['Dig_V.png'], ['dugtrio', 'jigglypuff']);
  });

  final rootPath = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
  for (final size in [const Size(393, 852), const Size(852, 393)]) {
    testWidgets('renders the requested reference Pokemon at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final gif = (await tester.runAsync(() async => base64Decode(
        (await rootBundle.loadString('assets/bw2/herdier-back.gif.b64')).trim(),
      )))!;
      await tester.runAsync(() async {
        for (final (id, view) in [('dugtrio', 'back'), ('jigglypuff', 'front')]) {
          final relative = 'assets/pokemon/comparator/$id-$view.gif';
          final sprite = File('${root.path}/$relative');
          await sprite.parent.create(recursive: true);
          await sprite.writeAsBytes(gif);
          final media = File('${root.path}/data/pokemon/media/$id.json');
          await media.parent.create(recursive: true);
          await media.writeAsString(jsonEncode({
            'schemaVersion': 2,
            'speciesId': id,
            'defaultFormId': 'base',
            'variants': {'base': {'${view}Animated': relative}},
          }));
        }
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: PreviewMove.tackle,
        status: status,
        referencePokemon: (
          attacker: (id: 'dugtrio', name: 'Triopikeur'),
          target: (id: 'jigglypuff', name: 'Rondoudou'),
        ),
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: size.width, height: size.height, child: GameWidget(game: game)),
      ));
      BattleOverlayComponent? overlay() =>
          game.children.whereType<BattleOverlayComponent>().firstOrNull;
      for (var i = 0; i < 360; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        if ((overlay()?.debugPlayerCombatant?.currentSpriteSourcePath ?? '')
                .endsWith('dugtrio-back.gif') &&
            (overlay()?.debugEnemyCombatant?.currentSpriteSourcePath ?? '')
                .endsWith('jigglypuff-front.gif')) {
          break;
        }
      }
      expect(overlay()?.debugPlayerCombatant?.currentSpriteSourcePath,
          endsWith('dugtrio-back.gif'));
      expect(overlay()?.debugEnemyCombatant?.currentSpriteSourcePath,
          endsWith('jigglypuff-front.gif'));
      expect(overlay()?.debugPlayerCombatant?.currentSpeciesLabel, 'Triopikeur');
      expect(overlay()?.debugEnemyCombatant?.currentSpeciesLabel, 'Rondoudou');
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null);
  }
}
