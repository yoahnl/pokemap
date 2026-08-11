import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../fixtures/personalization_studio_v2_fixture.dart';

enum _PlayerSurface { title, intro, pause, dialogue, battle }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFont);

  for (final orientation in <String>['landscape', 'portrait']) {
    for (final surface in _PlayerSurface.values) {
      testWidgets('certifies player ${surface.name} in $orientation', (
        tester,
      ) async {
        final size = orientation == 'landscape'
            ? const Size(960, 540)
            : const Size(540, 960);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = await tester.runAsync(_readGoldenFixture);
        final presentation = RuntimePlayerPresentation.fromProfile(
          fixture!.profile,
          author: 'POKÉMAP',
          description: 'Une aventure ferroviaire à travers Hanazuki.',
        );

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: presentation.applyTo(
              PokeMapPlayerTheme.dark(reducedMotion: true),
            ),
            home: RepaintBoundary(
              key: const ValueKey<String>('player-personalization-golden'),
              child: _surface(surface, presentation, fixture.projectName),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey<String>('player-personalization-golden')),
          matchesGoldenFile(
            'goldens/player_personalization/${orientation}_${surface.name}.png',
          ),
        );
      });
    }
  }
}

Widget _surface(
  _PlayerSurface surface,
  RuntimePlayerPresentation presentation,
  String projectName,
) =>
    switch (surface) {
      _PlayerSurface.title => PlayerTitleSurface(
          data: PersonalizationStudioV2Fixture.title(
            presentation,
            projectName: projectName,
          ),
          onSelected: (_) {},
        ),
      _PlayerSurface.intro => PlayerIntroVideoSurface(
          media: PersonalizationStudioV2Fixture.introMedia,
          isPoster: true,
          caption: 'Le train entre en gare de Hanazuki.',
          onSkip: () {},
          onReplay: () {},
          onContinue: () {},
        ),
      _PlayerSurface.pause => RuntimePlayerPauseShell.root(
          gameTitle: projectName,
          labels: presentation.pauseMenuLabels,
          actions: PersonalizationStudioV2Fixture.pauseActions,
          onSelected: (_) {},
          detail: const Center(child: Text('Sélectionnez une section')),
        ),
      _PlayerSurface.dialogue => PlayerDialogueSurface(
          data: PersonalizationStudioV2Fixture.dialogue,
          onAction: (_) {},
        ),
      _PlayerSurface.battle => PlayerBattleSurface(
          data: PersonalizationStudioV2Fixture.battle,
          onAction: (_) {},
        ),
    };

Future<({ProjectPresentationProfile profile, String projectName})>
    _readGoldenFixture() async {
  final file = File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/project.json',
  );
  final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return (
    profile: ProjectPresentationProfile.fromJson(
      Map<String, dynamic>.from(decoded['presentation'] as Map),
    ),
    projectName: decoded['name']! as String,
  );
}

Future<void> _loadFixtureFont() async {
  final bytes = await File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/assets/presentation/fonts/display.ttf',
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final flutterCache = _flutterCacheDirectory();
  final iconBytes = await File(
    '${flutterCache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
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
    if (current.path.endsWith('${Platform.pathSeparator}cache')) return current;
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}
