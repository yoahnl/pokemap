import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' show PokeMapPlayerTheme;
import 'package:map_player_ui/player_surfaces.dart';

void main() {
  test('exports the five reusable player surface types', () {
    expect(
      <Type>[
        PlayerTitleSurface,
        PlayerIntroVideoSurface,
        PlayerPauseSurface,
        PlayerDialogueSurface,
        PlayerBattleSurface,
      ],
      hasLength(5),
    );
  });

  test('shared surface files do not import runtime snapshots', () {
    for (final fileName in <String>[
      'player_title_surface.dart',
      'player_pause_surface.dart',
      'player_dialogue_surface.dart',
      'player_battle_surface.dart',
      'player_intro_video_surface.dart',
    ]) {
      final source = File('lib/src/player/$fileName').readAsStringSync();
      expect(source, isNot(contains('package:map_runtime')));
    }
  });

  testWidgets('dialogue surface exposes portrait and name independently', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: PlayerDialogueSurface(
          data: _dialogue,
          showSpeakerName: false,
          portraitBuilder: (_) => const SizedBox(
            key: ValueKey<String>('shared-dialogue-portrait'),
          ),
          onAction: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('shared-dialogue-portrait')),
      findsOneWidget,
    );
    expect(find.text('Léo'), findsNothing);
    expect(find.text('Bienvenue à Bourg-Lumière.'), findsOneWidget);
  });

  testWidgets('dialogue surface resolves a vertically centered layout', (
    tester,
  ) async {
    final base = suggestedProjectPresentationLayouts('standard');
    final layouts = base.copyWith(
      dialogue: base.dialogue.copyWith(
        regular: base.dialogue.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.center,
        ),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.withLayoutProfile(
          PokeMapPlayerTheme.dark(),
          layouts,
        ),
        home: PlayerDialogueSurface(data: _dialogue, onAction: (_) {}),
      ),
    );

    final align = tester.widget<Align>(
      find.byKey(
        const ValueKey<String>('player-dialogue-responsive-regular'),
      ),
    );
    expect(align.alignment, Alignment.center);
  });
}

const _dialogue = PlayerDialogueViewData(
  revision: 1,
  mode: PlayerDialogueMode.line,
  speaker: 'Léo',
  text: 'Bienvenue à Bourg-Lumière.',
  fullText: 'Bienvenue à Bourg-Lumière.',
  isCurrentLineFullyRevealed: true,
  isLastContent: false,
  choices: <PlayerDialogueChoiceViewData>[],
);
