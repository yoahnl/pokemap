import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/presentation/design_system/avelune_design_system.dart';

/// A game session must present the GAME's palette, never the launcher's brand.
///
/// The first recette on a real device showed every structured interaction —
/// the text field, its Submit, the confirmation's Yes/No — painted in Avelune
/// violet instead of the player theme's cyan. The panel background was correct,
/// which is what made it look half-themed and sent the diagnosis down the wrong
/// path: `PlayerPanel` reads `context.playerColors`, a ThemeExtension that
/// survives, while every widget leaving `style: null` resolves its colour from
/// `colorScheme.primary`.
void main() {
  test('the launcher brand really does override the player primary', () {
    // Without this, everything below is vacuous: it establishes that the two
    // themes genuinely disagree about `primary`, so a test that pins which one
    // the session uses is testing something.
    final player = PokeMapPlayerTheme.dark();
    final branded = applyAveluneTheme(PokeMapPlayerTheme.dark());

    expect(
      branded.colorScheme.primary,
      isNot(player.colorScheme.primary),
      reason: 'applyAveluneTheme replaces primary with the launcher accent',
    );
  });

  test('personalization never restores the palette a branded base lost', () {
    // `applyTo` layers typography, semantic colours, surface palettes and the
    // window/layout/dialogue/battle profiles. It never touches `colorScheme`,
    // so whatever primary the base carried is the primary the session gets.
    // That is the whole reason the BASE has to be right.
    const presentation = RuntimePlayerPresentation(
      title: RuntimePlayerTitlePresentation(author: ''),
    );
    final player = PokeMapPlayerTheme.dark();
    final branded = applyAveluneTheme(PokeMapPlayerTheme.dark());

    expect(
      presentation.applyTo(player).colorScheme.primary,
      player.colorScheme.primary,
    );
    expect(
      presentation.applyTo(branded).colorScheme.primary,
      branded.colorScheme.primary,
      reason: 'personalizing a branded theme keeps the brand — this is the '
          'exact leak the recette surfaced',
    );
  });

  test('the session page personalizes a pristine player theme', () async {
    // Asserted on the source because the branch that builds `personalizedTheme`
    // only runs once a launch has resolved, which needs a full bootstrap —
    // coordinator, presentation runtime, save repository. This file's sibling
    // `hub_runtime_presentation_test.dart` already pins page invariants the
    // same way. A behavioural test would be better; this one at least fails on
    // the exact regression instead of not existing.
    final page = await File(
      'lib/presentation/features/player/pages/hub_installed_game_player.dart',
    ).readAsString();

    expect(
      page,
      isNot(contains('applyTo(Theme.of(context))')),
      reason: 'that is the leak: at this level Theme.of(context) is the '
          'Avelune-branded theme',
    );
    expect(page, contains('PokeMapPlayerTheme.dark(reducedMotion:'));
    expect(page, contains('PokeMapPlayerTheme.light(reducedMotion:'));
    expect(
      page,
      contains('playerPresentation.applyTo(playerBaseTheme)'),
      reason: 'the personalization base is the pristine player theme',
    );
  });
}
