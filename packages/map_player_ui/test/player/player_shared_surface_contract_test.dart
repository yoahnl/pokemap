import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
