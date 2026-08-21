import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

/// Visual reference for the shared Pokémon summary sheet — BETA-PTY-001.
///
/// The sheet had no golden at all, so no reviewer — human or agent — could see
/// what it renders; the only proof available was someone opening the Hub. These
/// goldens pin the rendering in both surface roles the ticket names, party and
/// PC, and in the narrow portrait the widget tests already exercise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFonts);

  const cases = <String, ({ProjectPresentationSurfaceRole role, Size size})>{
    'party_960x540': (
      role: ProjectPresentationSurfaceRole.party,
      size: Size(960, 540),
    ),
    'pc_960x540': (
      role: ProjectPresentationSurfaceRole.pokedex,
      size: Size(960, 540),
    ),
    'party_360x640': (
      role: ProjectPresentationSurfaceRole.party,
      size: Size(360, 640),
    ),
    // Tall enough for the WHOLE sheet: a viewport-sized golden would hide the
    // provenance block, which is exactly the part nobody had ever seen.
    'party_full_480x1200': (
      role: ProjectPresentationSurfaceRole.party,
      size: Size(480, 1200),
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('certifies the summary sheet ${entry.key}', (tester) async {
      await tester.binding.setSurfaceSize(entry.value.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(reducedMotion: true),
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('pokemon-summary-golden'),
              child: SingleChildScrollView(
                child: PlayerPokemonSummarySheet(
                  summary: _summary(),
                  surfaceRole: entry.value.role,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('pokemon-summary-golden')),
        matchesGoldenFile('goldens/pokemon_summary/${entry.key}.png'),
      );
    });
  }
}

Future<void> _loadFixtureFonts() async {
  final bytes = await File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/assets/presentation/fonts/display.ttf',
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final iconBytes = await File(
    '${_flutterCacheDirectory().path}/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  ).readAsBytes();
  await _loadFont('MaterialIcons', iconBytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    final cache = Directory('${current.path}/cache');
    if (Directory('${cache.path}/artifacts/material_fonts').existsSync()) {
      return cache;
    }
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}

RuntimePokemonSummarySnapshot _summary() => RuntimePokemonSummarySnapshot(
      targetId: 'pokemon.indiv-1',
      individualId: 'indiv-1',
      speciesLabel: 'Bulbizarre',
      nickname: 'Bulbi',
      level: 12,
      experience: 120,
      currentHp: 20,
      maxHp: 48,
      stats: const RuntimePokemonStatsSummarySnapshot(
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      ),
      natureLabel: 'Hardy',
      abilityLabel: 'Engrais',
      genderLabel: 'Mâle',
      heldItemLabel: 'Baie Oran',
      friendship: 70,
      moves: const <RuntimePokemonMoveSummarySnapshot>[
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'tackle',
          label: 'Charge',
          typeLabel: 'Normal',
          currentPp: 30,
          maxPp: 35,
        ),
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'vine_whip',
          label: 'Fouet Lianes',
          typeLabel: 'Plante',
          currentPp: 24,
          maxPp: 25,
        ),
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'growl',
          label: 'Rugissement',
          typeLabel: 'Normal',
          currentPp: 40,
          maxPp: 40,
        ),
      ],
      provenance: const RuntimePokemonProvenanceSummarySnapshot(
        originLabel: 'Capturé',
        metMapLabel: 'Route Hanazuki',
        metSourceLabel: 'Hautes herbes',
        metLevel: 5,
        ballLabel: 'Poké Ball',
      ),
    );
