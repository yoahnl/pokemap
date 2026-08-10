import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../fixtures/personalization_studio_v2_fixture.dart';

enum _PlayerSurface { title, intro, pause, dialogue, battle }

void main() {
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
        final profile = await tester.runAsync(_readGoldenPresentation);
        final presentation = RuntimePlayerPresentation.fromProfile(
          profile!,
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
              child: _surface(surface, presentation),
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
) =>
    switch (surface) {
      _PlayerSurface.title => PlayerTitleSurface(
          data: PersonalizationStudioV2Fixture.title(presentation),
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
          gameTitle: PersonalizationStudioV2Fixture.projectName,
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

Future<ProjectPresentationProfile> _readGoldenPresentation() async {
  final file = File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_slice/presentation.json',
  );
  final decoded = jsonDecode(await file.readAsString());
  return ProjectPresentationProfile.fromJson(
    Map<String, dynamic>.from(decoded as Map),
  );
}
