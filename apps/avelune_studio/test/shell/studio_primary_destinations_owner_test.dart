import 'package:avelune_studio/features/shell/application/studio_primary_destinations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eight destinations are named buttons with selection', () {
    expect(
      [for (final destination in studioPrimaryDestinations) destination.id],
      [
        'home',
        'map',
        'regionalMap',
        'resources',
        'story',
        'pokemon',
        'projectSettings',
        'test',
      ],
    );
    expect(
      [for (final destination in studioPrimaryDestinations) destination.label],
      [
        'Accueil',
        'Carte',
        'Carte régionale',
        'Ressources',
        'Histoire',
        'Pokémon',
        'Réglages du projet',
        'Test du jeu',
      ],
    );
    expect({
      for (final destination in studioPrimaryDestinations) destination.id,
    }, hasLength(8));
  });

  test('every destination is highlighted for its own page', () {
    for (final destination in studioPrimaryDestinations) {
      expect(studioSelectedDestination(destination.id), destination.id);
    }
  });

  test('story pages and game export highlight their parent destination', () {
    for (final page in [
      'scene',
      'progression',
      'events',
      'dialogue',
      'cinematic',
    ]) {
      expect(studioSelectedDestination(page), 'story', reason: page);
    }
    expect(studioSelectedDestination('gameExport'), 'home');
  });

  test('a page with no destination of its own is highlighted as itself', () {
    expect(studioSelectedDestination('unknown'), 'unknown');
    for (final destination in studioPrimaryDestinations) {
      expect(
        studioPrimaryDestinations.map((entry) => entry.id),
        contains(studioSelectedDestination(destination.id)),
      );
    }
  });

  test('unavailable destination explains why it is unavailable', () {
    expect(
      studioDestinationUnavailableReason('test', busy: false, canTest: false),
      'ouvrez une carte du projet pour lancer un test',
    );
    expect(
      studioDestinationUnavailableReason('test', busy: false, canTest: true),
      isNull,
    );
    for (final destination in studioPrimaryDestinations) {
      if (destination.id == 'test') continue;
      expect(
        studioDestinationUnavailableReason(
          destination.id,
          busy: false,
          canTest: false,
        ),
        isNull,
        reason: destination.id,
      );
    }
  });

  test('every destination is unavailable while an operation is running', () {
    for (final destination in studioPrimaryDestinations) {
      for (final canTest in [false, true]) {
        expect(
          studioDestinationUnavailableReason(
            destination.id,
            busy: true,
            canTest: canTest,
          ),
          'indisponible pendant l’opération en cours',
          reason: '${destination.id} canTest=$canTest',
        );
      }
    }
  });
}
