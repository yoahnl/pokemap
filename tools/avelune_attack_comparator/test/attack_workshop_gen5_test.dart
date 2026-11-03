import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_attack_compare/main.dart' show PreviewPanel, extractPreviewResources;
import 'package:avelune_attack_compare/preview_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_background.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_component.dart';

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
  setUp(rootBundle.clear);
  testWidgets('clips battle visuals to the simulated phone screen', (tester) async {
    const boundaryKey = ValueKey('preview-boundary');
    const screenKey = ValueKey('phone-screen');
    await tester.pumpWidget(MaterialApp(
      home: Center(child: SizedBox(width: 400, height: 300,
        child: RepaintBoundary(key: boundaryKey, child: PreviewPanel(
          eyebrow: 'TEST', title: 'Combat', aspectRatio: 0.4,
          child: CustomPaint(key: screenKey, painter: _OverflowPainter()),
        )),
      )),
    ));
    final screen = tester.getRect(find.byKey(screenKey));
    final origin = tester.getTopLeft(find.byKey(boundaryKey));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
    final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    final x = (screen.left - origin.dx - 10).floor();
    final y = (screen.center.dy - origin.dy).floor();
    expect(bytes!.getUint8((y * image!.width + x) * 4), lessThan(100));
    image.dispose();
  });

  test('Quick Attack bundles its source program and both impact emitters', () async {
    expect(PreviewMove.quickAttack.unavailableReason, isNull);
    final program = jsonDecode(
      await rootBundle.loadString('assets/bw2/quick_attack.json'),
    ) as Map<String, dynamic>;
    expect(program['conversion'], 'supported');
    final instructions = (program['instructions'] as List).cast<Map>();
    expect(instructions.where((item) => item['op'] == 'circleCombatant'), hasLength(1));
    expect(instructions.where((item) => item['op'] == 'startOrthoEmitter'), hasLength(2));
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/bw2/particle270/manifest.json'),
    ) as Map<String, dynamic>;
    expect(manifest['sourceEmitterIndices'], [0, 1]);
    expect(await rootBundle.loadString('assets/bw2/particle270/texture00.b64'), isNotEmpty);
  });

  test('Hydro Pump bundles its source program and decoded background', () async {
    expect(PreviewMove.hydroPump.unavailableReason, isNull);
    final bundle = jsonDecode(
      await rootBundle.loadString(PreviewMove.hydroPump.bundleAsset!),
    ) as Map<String, dynamic>;
    expect(bundle['particle'], 221);
    expect((bundle['program'] as Map)['conversion'], 'supported');
    final bytes = base64Decode((bundle['backgrounds'] as Map)['18'] as String);
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      expect((frame.image.width, frame.image.height), (512, 512));
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  });

  test('Fire Blast bundles its source background palette cycle', () async {
    expect(PreviewMove.fireBlast.unavailableReason, isNull);
    final bundle = jsonDecode(
      await rootBundle.loadString(PreviewMove.fireBlast.bundleAsset!),
    ) as Map<String, dynamic>;
    final animation = (bundle['backgroundAnimations'] as Map)['6'] as Map;
    expect(animation['background'], 60);
    expect(animation['durations'], [6, 6, 6, 6, 6, 6]);
    expect(animation['frames'], hasLength(6));
    for (final frame in animation['frames'] as List) {
      final codec = await ui.instantiateImageCodec(base64Decode(frame as String));
      try {
        final image = (await codec.getNextFrame()).image;
        expect((image.width, image.height), (512, 512));
        image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });

  test('selected source variants are available once in the workshop', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final ids = [
      for (final move in PreviewMove.values)
        if (move.unavailableReason == null) move.id,
      for (final row in index.cast<Map>()) row['id'] as String,
    ];
    expect(ids.toSet(), hasLength(ids.length));
    for (final move in [PreviewMove.fly, PreviewMove.thief]) {
      expect(move.unavailableReason, isNull);
      expect(move.approximations, contains('source-variant:first-only'));
      final bundle = jsonDecode(await rootBundle.loadString(move.bundleAsset!)) as Map;
      expect(bundle['id'], move.id);
      expect((bundle['program'] as Map)['conversion'], 'supported');
    }
  });

  test('all batch textures decode from the bundled workshop catalog', () async {
    final index = jsonDecode(
      await rootBundle.loadString('assets/bw2/batch/index.json'),
    ) as List;
    final failures = <String>[];
    var decoded = 0;
    for (final row in index.cast<Map<String, dynamic>>()) {
      try {
        final bundle = jsonDecode(
          await rootBundle.loadString(row['bundleAsset'] as String),
        ) as Map<String, dynamic>;
        if (bundle['id'] != row['id']) {
          throw const FormatException('Wrong bundle');
        }
        final groups = bundle['particleGroups'] as Map?;
        for (final group in groups?.values ?? [bundle]) {
          final textures = ((group as Map)['textures'] as Map).cast<String, String>();
          for (final texture in textures.entries) {
            final codec = await ui.instantiateImageCodec(
              base64Decode(texture.value),
            );
            try {
              final frame = await codec.getNextFrame();
              frame.image.dispose();
              decoded++;
            } finally {
              codec.dispose();
            }
          }
        }
        for (final data in (bundle['backgrounds'] as Map? ?? const {}).values) {
          final codec = await ui.instantiateImageCodec(base64Decode(data as String));
          try {
            final frame = await codec.getNextFrame();
            if (frame.image.width != 512 || frame.image.height != 512) {
              frame.image.dispose();
              throw const FormatException('Invalid source background dimensions');
            }
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        }
      } on Object catch (error) {
        failures.add('${row['id']}: $error');
      }
    }
    expect(index, isNotEmpty);
    expect(decoded, greaterThanOrEqualTo(index.length));
    expect(failures, isEmpty);
    debugPrint('Decoded $decoded batch textures for ${index.length} attacks');
  });

  final rootPath = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
  for (final scenario in [
    (size: const Size(393, 852), id: 'surf', label: 'Surf',
        particle: 222, requireMovement: false),
    (size: const Size(852, 393), id: 'surf', label: 'Surf',
        particle: 222, requireMovement: false),
    for (final move in <({String id, String label, int particle})>[
      (id: 'flash-cannon', label: 'Luminocanon', particle: 609),
      (id: 'thunderbolt', label: 'Tonnerre', particle: 253),
      (id: 'thunder', label: 'Fatal-Foudre', particle: 256),
      (id: 'light-screen', label: 'Mur Lumière', particle: 282),
      (id: 'tri-attack', label: 'Triplattaque', particle: 329),
      (id: 'metal-claw', label: 'Griffe Acier', particle: 402),
      (id: 'taunt', label: 'Provoc', particle: 438),
      (id: 'ingrain', label: 'Racines', particle: 444),
      (id: 'crush-claw', label: 'Éclate Griffe', particle: 476),
      (id: 'gravity', label: 'Gravité', particle: 533),
      (id: 'echoed-voice', label: 'Écho', particle: 212),
      (id: 'struggle-bug', label: 'Survinsecte', particle: 425),
      (id: 'mist-ball', label: 'Ball’Brume', particle: 466),
      (id: 'aqua-jet', label: 'Aqua-Jet', particle: 632),
      (id: 'eruption', label: 'Éruption', particle: 455),
      (id: 'guard-split', label: 'Partage Garde', particle: 564),
      (id: 'dragon-claw', label: 'Draco-Griffe', particle: 511),
      (id: 'sky-drop', label: 'Chute Libre', particle: 460),
      (id: 'fissure', label: 'Abîme', particle: 261),
      (id: 'power-split', label: 'Partage Force', particle: 563),
      (id: 'shadow_ball', label: 'Ball’Ombre', particle: 418),
      (id: 'fusion-flare', label: 'Flamme Croix', particle: 735),
      (id: 'fusion-bolt', label: 'Éclair Croix', particle: 737),
      (id: 'sweet-scent', label: 'Doux Parfum', particle: 400),
      (id: 'crush-grip', label: 'Presse', particle: 641),
    ])
      for (final size in [const Size(393, 852), const Size(852, 393)])
        (size: size, id: move.id, label: move.label,
            particle: move.particle, requireMovement: false),
    (size: const Size(393, 852), id: 'defog', label: 'Anti-Brume',
        particle: 612, requireMovement: false),
    (size: const Size(852, 393), id: 'defog', label: 'Anti-Brume',
        particle: 612, requireMovement: false),
    (size: const Size(393, 852), id: 'growl', label: 'Rugissement',
        particle: 210, requireMovement: false),
    (size: const Size(852, 393), id: 'growl', label: 'Rugissement',
        particle: 210, requireMovement: false),
    (size: const Size(393, 852), id: 'hyper-voice', label: 'Mégaphone',
        particle: 474, requireMovement: false),
    (size: const Size(852, 393), id: 'hyper-voice', label: 'Mégaphone',
        particle: 474, requireMovement: false),
    (size: const Size(393, 852), id: 'howl', label: 'Grondement',
        particle: 510, requireMovement: false),
    (size: const Size(852, 393), id: 'howl', label: 'Grondement',
        particle: 510, requireMovement: false),
    (size: const Size(393, 852), id: 'chatter', label: 'Babil',
        particle: 627, requireMovement: true),
    (size: const Size(852, 393), id: 'chatter', label: 'Babil',
        particle: 627, requireMovement: true),
    (size: const Size(393, 852), id: 'haze', label: 'Buée Noire',
        particle: 284, requireMovement: false),
    (size: const Size(852, 393), id: 'haze', label: 'Buée Noire',
        particle: 284, requireMovement: false),
    (size: const Size(393, 852), id: 'rock-tomb', label: 'Tomberoche',
        particle: 491, requireMovement: false),
    (size: const Size(852, 393), id: 'rock-tomb', label: 'Tomberoche',
        particle: 491, requireMovement: false),
    (size: const Size(393, 852), id: 'smack-down', label: 'Anti-Air',
        particle: 654, requireMovement: false),
    (size: const Size(852, 393), id: 'smack-down', label: 'Anti-Air',
        particle: 654, requireMovement: false),
    (size: const Size(393, 852), id: 'flame-charge', label: 'Nitrocharge',
        particle: 663, requireMovement: true),
    (size: const Size(852, 393), id: 'flame-charge', label: 'Nitrocharge',
        particle: 663, requireMovement: true),
    (size: const Size(393, 852), id: 'round', label: 'Chant Canon',
        particle: 668, requireMovement: false),
    (size: const Size(852, 393), id: 'round', label: 'Chant Canon',
        particle: 668, requireMovement: false),
    (size: const Size(393, 852), id: 'night-daze', label: 'Explonuit',
        particle: 708, requireMovement: true),
    (size: const Size(852, 393), id: 'night-daze', label: 'Explonuit',
        particle: 708, requireMovement: true),
    (size: const Size(393, 852), id: 'teleport', label: 'Téléport',
        particle: 272, requireMovement: true),
    (size: const Size(852, 393), id: 'teleport', label: 'Téléport',
        particle: 272, requireMovement: true),
    (size: const Size(393, 852), id: 'rapid-spin', label: 'Tour Rapide',
        particle: 399, requireMovement: false),
    (size: const Size(852, 393), id: 'rapid-spin', label: 'Tour Rapide',
        particle: 399, requireMovement: false),
    (size: const Size(393, 852), id: 'metal-sound', label: 'Strido-Son',
        particle: 493, requireMovement: false),
    (size: const Size(852, 393), id: 'metal-sound', label: 'Strido-Son',
        particle: 493, requireMovement: false),
    (size: const Size(393, 852), id: 'focus-blast', label: 'Exploforce',
        particle: 590, requireMovement: false),
    (size: const Size(852, 393), id: 'focus-blast', label: 'Exploforce',
        particle: 590, requireMovement: false),
    (size: const Size(393, 852), id: 'acrobatics', label: 'Acrobatie',
        particle: 682, requireMovement: true),
    (size: const Size(852, 393), id: 'acrobatics', label: 'Acrobatie',
        particle: 682, requireMovement: true),
    (size: const Size(393, 852), id: 'skull-bash', label: 'Coud’Krâne',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'skull-bash', label: 'Coud’Krâne',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'entrainment', label: 'Ten-Danse',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'entrainment', label: 'Ten-Danse',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'after-you', label: 'Après Vous',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'after-you', label: 'Après Vous',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'dig', label: 'Tunnel',
        particle: 263, requireMovement: true),
    (size: const Size(852, 393), id: 'dig', label: 'Tunnel',
        particle: 263, requireMovement: true),
    (size: const Size(393, 852), id: 'extreme-speed', label: 'Vitesse Extrême',
        particle: 416, requireMovement: true),
    (size: const Size(852, 393), id: 'extreme-speed', label: 'Vitesse Extrême',
        particle: 416, requireMovement: true),
    (size: const Size(393, 852), id: 'dive', label: 'Plongée',
        particle: 461, requireMovement: true),
    (size: const Size(852, 393), id: 'dive', label: 'Plongée',
        particle: 461, requireMovement: true),
    (size: const Size(393, 852), id: 'bide', label: 'Patience',
        particle: 287, requireMovement: false),
    (size: const Size(852, 393), id: 'bide', label: 'Patience',
        particle: 287, requireMovement: false),
    (size: const Size(393, 852), id: 'sky-attack', label: 'Piqué',
        particle: 312, requireMovement: false),
    (size: const Size(852, 393), id: 'sky-attack', label: 'Piqué',
        particle: 312, requireMovement: false),
    (size: const Size(393, 852), id: 'thief', label: 'Larcin',
        particle: 338, requireMovement: false),
    (size: const Size(852, 393), id: 'thief', label: 'Larcin',
        particle: 338, requireMovement: false),
    (size: const Size(393, 852), id: 'snatch', label: 'Saisie',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'snatch', label: 'Saisie',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'doom-desire', label: 'Vœu Destructeur',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'doom-desire', label: 'Vœu Destructeur',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'dragon-rush', label: 'Draco-Charge',
        particle: 586, requireMovement: false),
    (size: const Size(852, 393), id: 'dragon-rush', label: 'Draco-Charge',
        particle: 586, requireMovement: false),
    (size: const Size(393, 852), id: 'fly', label: 'Vol',
        particle: 184, requireMovement: false),
    (size: const Size(852, 393), id: 'fly', label: 'Vol',
        particle: 184, requireMovement: false),
    (size: const Size(393, 852), id: 'acid-armor', label: 'Acidarmure',
        particle: 319, requireMovement: false),
    (size: const Size(852, 393), id: 'acid-armor', label: 'Acidarmure',
        particle: 319, requireMovement: false),
    (size: const Size(393, 852), id: 'sketch', label: 'Gribouille',
        particle: 336, requireMovement: false),
    (size: const Size(852, 393), id: 'sketch', label: 'Gribouille',
        particle: 336, requireMovement: false),
    (size: const Size(393, 852), id: 'nightmare', label: 'Cauchemar',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'nightmare', label: 'Cauchemar',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'camouflage', label: 'Camouflage',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'camouflage', label: 'Camouflage',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'feint-attack', label: 'Feinte',
        particle: 355, requireMovement: false),
    (size: const Size(852, 393), id: 'feint-attack', label: 'Feinte',
        particle: 355, requireMovement: false),
    (size: const Size(393, 852), id: 'bounce', label: 'Rebond',
        particle: 515, requireMovement: false),
    (size: const Size(852, 393), id: 'bounce', label: 'Rebond',
        particle: 515, requireMovement: false),
    (size: const Size(393, 852), id: 'u-turn', label: 'Demi-Tour',
        particle: 547, requireMovement: false),
    (size: const Size(852, 393), id: 'u-turn', label: 'Demi-Tour',
        particle: 547, requireMovement: false),
    (size: const Size(393, 852), id: 'brave-bird', label: 'Rapace',
        particle: 592, requireMovement: false),
    (size: const Size(852, 393), id: 'brave-bird', label: 'Rapace',
        particle: 592, requireMovement: false),
    (size: const Size(393, 852), id: 'shadow-force', label: 'Revenant',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'shadow-force', label: 'Revenant',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'perish-song', label: 'Requiem',
        particle: 365, requireMovement: false),
    (size: const Size(852, 393), id: 'perish-song', label: 'Requiem',
        particle: 365, requireMovement: false),
    (size: const Size(393, 852), id: 'rain-dance', label: 'Danse Pluie',
        particle: 411, requireMovement: false),
    (size: const Size(852, 393), id: 'rain-dance', label: 'Danse Pluie',
        particle: 411, requireMovement: false),
    (size: const Size(393, 852), id: 'sunny-day', label: 'Zénith',
        particle: 412, requireMovement: false),
    (size: const Size(852, 393), id: 'sunny-day', label: 'Zénith',
        particle: 412, requireMovement: false),
    (size: const Size(393, 852), id: 'hail', label: 'Grêle',
        particle: 428, requireMovement: false),
    (size: const Size(852, 393), id: 'hail', label: 'Grêle',
        particle: 428, requireMovement: false),
    (size: const Size(393, 852), id: 'trick', label: 'Tour de Magie',
        particle: 441, requireMovement: false),
    (size: const Size(852, 393), id: 'trick', label: 'Tour de Magie',
        particle: 441, requireMovement: false),
    (size: const Size(393, 852), id: 'aromatherapy', label: 'Aromathérapie',
        particle: 487, requireMovement: false),
    (size: const Size(852, 393), id: 'aromatherapy', label: 'Aromathérapie',
        particle: 487, requireMovement: false),
    (size: const Size(393, 852), id: 'volt-tackle', label: 'Électacle',
        particle: 521, requireMovement: false),
    (size: const Size(852, 393), id: 'volt-tackle', label: 'Électacle',
        particle: 521, requireMovement: false),
    (size: const Size(393, 852), id: 'water-pulse', label: 'Vibraqua',
        particle: 529, requireMovement: false),
    (size: const Size(852, 393), id: 'water-pulse', label: 'Vibraqua',
        particle: 529, requireMovement: false),
    (size: const Size(393, 852), id: 'switcheroo', label: 'Passe-Passe',
        particle: 594, requireMovement: false),
    (size: const Size(852, 393), id: 'switcheroo', label: 'Passe-Passe',
        particle: 594, requireMovement: false),
    (size: const Size(393, 852), id: 'water-spout', label: 'Giclédo',
        particle: 497, requireMovement: false),
    (size: const Size(852, 393), id: 'water-spout', label: 'Giclédo',
        particle: 497, requireMovement: false),
    (size: const Size(393, 852), id: 'draco-meteor', label: 'Draco-Météore',
        particle: 613, requireMovement: false),
    (size: const Size(852, 393), id: 'draco-meteor', label: 'Draco-Météore',
        particle: 613, requireMovement: false),
    (size: const Size(393, 852), id: 'poison-gas', label: 'Gaz Toxik',
        particle: 308, requireMovement: false),
    (size: const Size(852, 393), id: 'poison-gas', label: 'Gaz Toxik',
        particle: 308, requireMovement: false),
    (size: const Size(393, 852), id: 'psywave', label: 'Vague Psy',
        particle: 317, requireMovement: false),
    (size: const Size(852, 393), id: 'psywave', label: 'Vague Psy',
        particle: 317, requireMovement: false),
    (size: const Size(393, 852), id: 'blizzard', label: 'Blizzard',
        particle: 224, requireMovement: false),
    (size: const Size(852, 393), id: 'blizzard', label: 'Blizzard',
        particle: 224, requireMovement: false),
    (size: const Size(393, 852), id: 'rollout', label: 'Roulade',
        particle: 375, requireMovement: false),
    (size: const Size(852, 393), id: 'rollout', label: 'Roulade',
        particle: 375, requireMovement: false),
    (size: const Size(393, 852), id: 'double-team', label: 'Reflet',
        particle: null, requireMovement: true),
    (size: const Size(852, 393), id: 'double-team', label: 'Reflet',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'strength', label: 'Force',
        particle: 235, requireMovement: true),
    (size: const Size(852, 393), id: 'strength', label: 'Force',
        particle: 235, requireMovement: true),
    (size: const Size(393, 852), id: 'earthquake', label: 'Séisme',
        particle: 260, requireMovement: false),
    (size: const Size(852, 393), id: 'earthquake', label: 'Séisme',
        particle: 260, requireMovement: false),
    (size: const Size(393, 852), id: 'magnitude', label: 'Ampleur',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'magnitude', label: 'Ampleur',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'reversal', label: 'Contre',
        particle: 350, requireMovement: false),
    (size: const Size(852, 393), id: 'reversal', label: 'Contre',
        particle: 350, requireMovement: false),
    (size: const Size(393, 852), id: 'fury-cutter', label: 'Taillade',
        particle: 380, requireMovement: false),
    (size: const Size(852, 393), id: 'fury-cutter', label: 'Taillade',
        particle: 380, requireMovement: false),
    (size: const Size(393, 852), id: 'absorb', label: 'Vole-Vie',
        particle: 236, requireMovement: false),
    (size: const Size(852, 393), id: 'absorb', label: 'Vole-Vie',
        particle: 236, requireMovement: false),
    (size: const Size(393, 852), id: 'jump-kick', label: 'Pied Sauté',
        particle: 192, requireMovement: false),
    (size: const Size(852, 393), id: 'jump-kick', label: 'Pied Sauté',
        particle: 192, requireMovement: false),
    (size: const Size(393, 852), id: 'mud-bomb', label: 'Boue-Bombe',
        particle: 605, requireMovement: false),
    (size: const Size(852, 393), id: 'mud-bomb', label: 'Boue-Bombe',
        particle: 605, requireMovement: false),
    (size: const Size(393, 852), id: 'drain-punch', label: 'Vampi-Poing',
        particle: 588, requireMovement: false),
    (size: const Size(852, 393), id: 'drain-punch', label: 'Vampi-Poing',
        particle: 588, requireMovement: false),
    (size: const Size(393, 852), id: 'heat-wave', label: 'Canicule',
        particle: 427, requireMovement: false),
    (size: const Size(852, 393), id: 'heat-wave', label: 'Canicule',
        particle: 427, requireMovement: false),
    (size: const Size(393, 852), id: 'cotton-spore', label: 'Spore Coton',
        particle: 349, requireMovement: false),
    (size: const Size(852, 393), id: 'cotton-spore', label: 'Spore Coton',
        particle: 349, requireMovement: false),
    (size: const Size(393, 852), id: 'flare-blitz', label: 'Boutefeu',
        particle: 573, requireMovement: true),
    (size: const Size(852, 393), id: 'flare-blitz', label: 'Boutefeu',
        particle: 573, requireMovement: true),
    (size: const Size(393, 852), id: 'aerial-ace', label: 'Aéropique',
        particle: 506, requireMovement: true),
    (size: const Size(852, 393), id: 'aerial-ace', label: 'Aéropique',
        particle: 506, requireMovement: true),
    (size: const Size(393, 852), id: 'meditate', label: 'Yoga',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'mud-sport', label: 'Lance-Boue',
        particle: 470, requireMovement: false),
    (size: const Size(393, 852), id: 'night-shade', label: 'Ombre Nocturne',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'shell-smash', label: 'Exuviation',
        particle: 675, requireMovement: false),
    (size: const Size(393, 852), id: 'spit-up', label: 'Relâche',
        particle: 425, requireMovement: true),
    (size: const Size(393, 852), id: 'bulk-up', label: 'Gonflette',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'bulldoze', label: 'Piétisol',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'flash', label: 'Flash',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'future-sight', label: 'Prescience',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'minimize', label: 'Lilliput',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'role-play', label: 'Imitation',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'spite', label: 'Dépit',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'tail-whip', label: 'Mimi-Queue',
        particle: null, requireMovement: true),
    (size: const Size(393, 852), id: 'growth', label: 'Croissance',
        particle: 241, requireMovement: false),
    (size: const Size(852, 393), id: 'confusion', label: 'Choc Mental',
        particle: 266, requireMovement: false),
    (size: const Size(393, 852), id: 'frenzy-plant', label: 'Végé-Attaque',
        particle: 514, requireMovement: false),
    (size: const Size(852, 393), id: 'aqua-tail', label: 'Hydro-Queue',
        particle: 580, requireMovement: false),
    (size: const Size(393, 852), id: 'freeze-shock', label: 'Éclair Gelé',
        particle: 726, requireMovement: false),
    (size: const Size(393, 852), id: 'quick_attack', label: 'Vive-Attaque',
        particle: 270, requireMovement: true),
    (size: const Size(852, 393), id: 'quick_attack', label: 'Vive-Attaque',
        particle: 270, requireMovement: true),
    (size: const Size(393, 852), id: 'astonish', label: 'Étonnement',
        particle: 481, requireMovement: true),
    (size: const Size(852, 393), id: 'facade', label: 'Façade',
        particle: 433, requireMovement: false),
    (size: const Size(393, 852), id: 'grass-pledge', label: 'Aire d’Herbe',
        particle: 690, requireMovement: false),
    (size: const Size(852, 393), id: 'charm', label: 'Charme',
        particle: 374, requireMovement: false),
    (size: const Size(393, 852), id: 'thunder-fang', label: 'Crocs Éclair',
        particle: 601, requireMovement: false),
    (size: const Size(852, 393), id: 'sharpen', label: 'Affûtage',
        particle: 327, requireMovement: false),
    (size: const Size(393, 852), id: 'protect', label: 'Abri',
        particle: 352, requireMovement: false),
    (size: const Size(852, 393), id: 'acid-spray', label: 'Bombe Acide',
        particle: 665, requireMovement: false),
    (size: const Size(393, 852), id: 'hydro_pump', label: 'Hydrocanon',
        particle: 221, requireMovement: false),
    (size: const Size(852, 393), id: 'hydro_pump', label: 'Hydrocanon',
        particle: 221, requireMovement: false),
    (size: const Size(393, 852), id: 'solar-beam', label: 'Lance-Soleil',
        particle: 243, requireMovement: false),
    (size: const Size(852, 393), id: 'thunder-wave', label: 'Cage Éclair',
        particle: 255, requireMovement: false),
    (size: const Size(393, 852), id: 'focus-punch', label: 'Mitra-Poing',
        particle: 434, requireMovement: false),
    (size: const Size(852, 393), id: 'close-combat', label: 'Close Combat',
        particle: 549, requireMovement: false),
    (size: const Size(393, 852), id: 'calm-mind', label: 'Plénitude',
        particle: 524, requireMovement: false),
    (size: const Size(852, 393), id: 'leaf-storm', label: 'Tempête Verte',
        particle: 616, requireMovement: false),
    (size: const Size(393, 852), id: 'lunar-dance', label: 'Danse Lune',
        particle: 640, requireMovement: false),
    (size: const Size(393, 852), id: 'psychic', label: 'Psyko',
        particle: null, requireMovement: false),
    (size: const Size(852, 393), id: 'psychic', label: 'Psyko',
        particle: null, requireMovement: false),
    (size: const Size(393, 852), id: 'waterfall', label: 'Cascade',
        particle: 296, requireMovement: false),
    (size: const Size(852, 393), id: 'waterfall', label: 'Cascade',
        particle: 296, requireMovement: false),
    (size: const Size(393, 852), id: 'sacred-fire', label: 'Feu Sacré',
        particle: 392, requireMovement: false),
    (size: const Size(852, 393), id: 'whirlpool', label: 'Siphon',
        particle: 420, requireMovement: false),
    (size: const Size(393, 852), id: 'inferno', label: 'Feu d’Enfer',
        particle: 687, requireMovement: false),
    (size: const Size(852, 393), id: 'blue-flare', label: 'Flamme Bleue',
        particle: 724, requireMovement: false),
    (size: const Size(393, 852), id: 'sing', label: 'Berceuse',
        particle: 212, requireMovement: false),
    (size: const Size(852, 393), id: 'powder-snow', label: 'Poudreuse',
        particle: 351, requireMovement: false),
    (size: const Size(393, 852), id: 'frost-breath', label: 'Souffle Glacé',
        particle: 694, requireMovement: false),
    (size: const Size(393, 852), id: 'megahorn', label: 'Mégacorne',
        particle: 394, requireMovement: false),
    (size: const Size(852, 393), id: 'megahorn', label: 'Mégacorne',
        particle: 394, requireMovement: false),
    (size: const Size(393, 852), id: 'mist', label: 'Brume',
        particle: 219, requireMovement: false),
    (size: const Size(852, 393), id: 'thrash', label: 'Mania',
        particle: 203, requireMovement: false),
    (size: const Size(393, 852), id: 'lava-plume', label: 'Ébullilave',
        particle: 615, requireMovement: false),
    (size: const Size(852, 393), id: 'overheat', label: 'Surchauffe',
        particle: 490, requireMovement: false),
    (size: const Size(852, 393), id: 'rage', label: 'Frénésie',
        particle: 271, requireMovement: false),
    (size: const Size(393, 852), id: 'synchronoise', label: 'Synchropeine',
        particle: 660, requireMovement: false),
    (size: const Size(393, 852), id: 'fire_blast', label: 'Déflagration',
        particle: 295, requireMovement: false),
    (size: const Size(852, 393), id: 'fire_blast', label: 'Déflagration',
        particle: 295, requireMovement: false),
  ]) {
    testWidgets('${scenario.label} runs in the workshop at ${scenario.size}', (tester) async {
      final size = scenario.size;
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
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: scenario.id == 'surf' ? PreviewMove.surf :
            scenario.id == 'shadow_ball' ? PreviewMove.shadowBall :
            scenario.id == 'quick_attack' ? PreviewMove.quickAttack :
            scenario.id == 'hydro_pump' ? PreviewMove.hydroPump :
            scenario.id == 'fire_blast' ? PreviewMove.fireBlast :
            scenario.id == 'psychic' ? PreviewMove.psychic :
            scenario.id == 'fly' ? PreviewMove.fly :
            scenario.id == 'thief' ? PreviewMove.thief : PreviewMove(
          scenario.id, scenario.label, null, 'normal', PsdkBattleMoveCategory.physical,
          particle: scenario.particle,
          bundleAsset: 'assets/bw2/batch/${scenario.id}.json',
        ),
        status: status,
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: size.width, height: size.height,
            child: GameWidget(game: game)),
      ));
      BattleOverlayComponent? overlay() {
        final values = game.children.whereType<BattleOverlayComponent>();
        return values.isEmpty ? null : values.first;
      }
      for (var tick = 0; tick < 360 && status.value != 'Combat prêt · appuie sur Lancer'; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      }
      expect(status.value, 'Combat prêt · appuie sur Lancer');
      final initial = overlay()!.debugPlayerCombatant!.currentVisualOffset;
      final initialEnemy = overlay()!.debugEnemyCombatant!.currentVisualOffset;
      final initialRotation = overlay()!.debugPlayerCombatant!.currentVisualRotation;
      final initialEnemyRotation = overlay()!.debugEnemyCombatant!.currentVisualRotation;
      final initialCameraEye = overlay()!.battleCameraPose!.eye;
      final initialSize = overlay()!.debugPlayerCombatant!
          .currentCameraNeutralRenderedSpriteRect.size;
      final initialPlayerAlpha = overlay()!.debugPlayerCombatant!.stageTint.a;
      final initialEnemyAlpha = overlay()!.debugEnemyCombatant!.stageTint.a;
      var started = false;
      var sawParticles = false;
      var sawMovement = false;
      var sawScale = false;
      var sawBackground = false;
      var sawWave = false;
      var sawPaletteAnimation = false;
      var sawCameraMovement = false;
      var sawAlpha = false;
      var sawHidden = false;
      var sawRotation = false;
      var sawBothPalettes = false;
      unawaited(game.play(onStart: () => started = true));
      for (var tick = 0; tick < 600; tick++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
        final scene = overlay();
        if (scene != null) {
          final camera = scene.battleCameraPose;
          if (camera != null) {
            sawCameraMovement |= camera.eye.distanceTo(initialCameraEye) > .0001;
          }
          sawParticles |= scene.children.whereType<BattleSplStaticComponent>()
              .any((effect) => effect.playback.activeParticles > 0);
          sawMovement |= scene.debugPlayerCombatant!.currentVisualOffset != initial;
          sawAlpha |= scene.debugPlayerCombatant!.stageTint.a < initialPlayerAlpha - 0.05 ||
              scene.debugEnemyCombatant!.stageTint.a < initialEnemyAlpha - 0.05;
          sawHidden |= scene.debugPlayerCombatant!.isHiddenForBattleScript;
          sawBothPalettes |= scene.debugPlayerCombatant!.hasBattleScriptPalette &&
              scene.debugEnemyCombatant!.hasBattleScriptPalette;
          sawRotation |= (scene.debugPlayerCombatant!.currentVisualRotation - initialRotation).abs() > .001 ||
              (scene.debugEnemyCombatant!.currentVisualRotation - initialEnemyRotation).abs() > .001;
          sawScale |= scene.debugPlayerCombatant!
              .currentCameraNeutralRenderedSpriteRect.size != initialSize;
          sawBackground |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.visible || background.hideField);
          sawWave |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.isWaving);
          sawPaletteAnimation |= scene.children.whereType<BattleGen5SourceBackground>()
              .any((background) => background.isPaletteAnimating);
        }
        if (status.value.contains('terminée') ||
            status.value.contains('Impossible') ||
            status.value.contains('interrompue')) {
          break;
        }
      }
      expect(started, isTrue, reason: status.value);
      if ({'acid-armor', 'sketch', 'nightmare', 'camouflage'}.contains(scenario.id)) {
        expect(sawAlpha, isTrue, reason: status.value);
      }
      if (scenario.id == 'fly') {
        expect(sawHidden, isTrue, reason: status.value);
      }
      if ({'skull-bash', 'entrainment', 'after-you'}.contains(scenario.id)) {
        expect(sawRotation, isTrue, reason: status.value);
      }
      if (scenario.id == 'defog') {
        expect(sawBothPalettes, isTrue, reason: status.value);
      }
      if (scenario.particle != null) {
        expect(sawParticles, isTrue, reason: status.value);
      }
      if (scenario.requireMovement) {
        expect(sawMovement, isTrue, reason: status.value);
      }
      if ({'magnitude', 'water-spout', 'draco-meteor', 'fusion-flare', 'fusion-bolt'}.contains(scenario.id)) {
        expect(sawCameraMovement, isTrue, reason: status.value);
      }
      if ({'bulk-up', 'minimize', 'meditate', 'night-shade', 'doom-desire',
        'shell-smash', 'spit-up'}.contains(scenario.id)) {
        expect(sawScale, isTrue, reason: status.value);
      }
      if ({'hydro_pump', 'focus-punch', 'close-combat', 'leaf-storm', 'lunar-dance', 'fire_blast', 'psychic',
        'waterfall', 'sacred-fire', 'whirlpool', 'inferno', 'blue-flare', 'megahorn', 'overheat',
        'flare-blitz', 'aerial-ace', 'fissure'}
          .contains(scenario.id)) {
        expect(sawBackground, isTrue, reason: status.value);
      }
      if ({'fire_blast', 'megahorn', 'flare-blitz', 'aerial-ace'}.contains(scenario.id)) {
        expect(sawPaletteAnimation, isTrue, reason: status.value);
      }
      if ({'psychic', 'waterfall', 'sacred-fire', 'whirlpool', 'inferno', 'blue-flare', 'flare-blitz'}
          .contains(scenario.id)) {
        expect(sawWave, isTrue, reason: status.value);
      }
      expect(status.value, contains('terminée'));
      expect(overlay()!.debugPlayerCombatant!.currentVisualOffset, initial);
      if ({'dig', 'extreme-speed', 'dive'}.contains(scenario.id)) {
        expect(overlay()!.debugEnemyCombatant!.currentVisualOffset, initialEnemy);
      }
      if ({'skull-bash', 'entrainment', 'after-you'}.contains(scenario.id)) {
        expect(overlay()!.debugPlayerCombatant!.currentVisualRotation, closeTo(initialRotation, .001));
        expect(overlay()!.debugEnemyCombatant!.currentVisualRotation, closeTo(initialEnemyRotation, .001));
      }
      if ({'acid-armor', 'sketch', 'nightmare', 'camouflage'}.contains(scenario.id)) {
        expect(overlay()!.debugPlayerCombatant!.stageTint.a, closeTo(initialPlayerAlpha, .001));
        expect(overlay()!.debugEnemyCombatant!.stageTint.a, closeTo(initialEnemyAlpha, .001));
      }
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null ||
        (scenario.id == 'heat-wave' && scenario.size.width > scenario.size.height));
  }

  for (final scenario in [
    (move: PreviewMove.tackle, player: 'gen5:totodile', enemy: 'gen5:pidgey'),
    (
      move: PreviewMove.surf,
      player: 'herdier-back.gif',
      enemy: 'trubbish-front.gif',
    ),
  ]) {
    testWidgets('attack workshop loads sprites for ${scenario.move.label}', (
      tester,
    ) async {
      final root = (await tester.runAsync(
        () => extractPreviewResources(parent: Directory(rootPath!)),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final status = ValueNotifier<String>('Preparing');
      final game = BattlePreviewGame(
        projectRoot: root.path,
        move: scenario.move,
        status: status,
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 393,
            height: 852,
            child: GameWidget(game: game),
          ),
        ),
      );
      BattleOverlayComponent? overlay() {
        final values = game.children.whereType<BattleOverlayComponent>();
        return values.isEmpty ? null : values.first;
      }

      for (var i = 0; i < 360; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3)),
        );
        if ((overlay()?.debugPlayerCombatant?.currentSpriteSourcePath ?? '')
                .endsWith(scenario.player) &&
            (overlay()?.debugEnemyCombatant?.currentSpriteSourcePath ?? '')
                .endsWith(scenario.enemy)) {
          break;
        }
      }
      expect(
        overlay()?.debugPlayerCombatant?.currentSpriteSourcePath,
        endsWith(scenario.player),
      );
      expect(
        overlay()?.debugEnemyCombatant?.currentSpriteSourcePath,
        endsWith(scenario.enemy),
      );
      await tester.pumpWidget(const SizedBox());
      status.dispose();
    }, skip: rootPath == null);
  }
}

class _OverflowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(-24, 0, 24, size.height),
        Paint()..color = const Color(0xffff0000));
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff00ff00));
  }

  @override
  bool shouldRepaint(covariant _OverflowPainter oldDelegate) => false;
}
