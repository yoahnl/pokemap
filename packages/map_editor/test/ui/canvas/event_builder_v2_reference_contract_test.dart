import 'dart:io';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../support/event_builder_v2_visual_harness.dart';

const _referencePath = 'test/goldens/event_builder_v2/reference/'
    'event_builder_v2_reference_1672x941.png';
const _contractPath = '../../reports/narrativeStudio/events/'
    'ns_event_v2_v0_visual_contract.md';
const _referenceFingerprint =
    'sha256:2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885';

void main() {
  group('NS-EVENT-V2 V0 visual reference contract', () {
    test('pins the supplied north-star bytes and dimensions', () {
      final reference = File(_referencePath);

      expect(
        reference.existsSync(),
        isTrue,
        reason: 'The supplied product reference must be versioned in-repo.',
      );
      final bytes = reference.readAsBytesSync();
      expect(narrativeEventBytesFingerprint(bytes), _referenceFingerprint);

      final decoded = image.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1672);
      expect(decoded.height, 941);
    });

    test('pins the reproducible fixture state used for comparisons', () {
      expect(
        eventBuilderV2PhaseKReferenceViewport,
        const Size(1672, 941),
      );

      final fixture = buildEventBuilderV2PhaseKReadModel();
      final selected = fixture.eventByStableKey(
        eventBuilderV2PhaseKSelectedStableKey,
      );

      expect(selected, isNotNull);
      expect(selected!.title, 'Rencontre rival au port');
      expect(selected.source.mapLabel, 'Port Selbrume');
      expect(selected.scene.humanLabel, 'Rencontre rival');
      expect(selected.enabled, isTrue);
    });

    test('documents all eight zones and numeric severity tolerances', () {
      final contract = File(_contractPath);

      expect(contract.existsSync(), isTrue);
      final markdown = contract.readAsStringSync();
      // Keep every measured rectangle executable: a prose-only marker test
      // would stay green if a coordinate drifted while H/K still trusted it.
      for (final requiredMarker in const <String>[
        '| 1 | Enveloppe fenêtre | `0, 0, 1672, 941` |',
        '| 2 | Header marque | `0, 0, 1672, 50` |',
        '| 3 | Barre contexte/actions | `207, 50, 1465, 52` |',
        '| 4 | Navigation produit | `8, 102, 191, 817` |',
        '| 5 | Colonne Événements | `207, 102, 266, 817` |',
        '| 6 | Bibliothèque | `481, 102, 213, 817` |',
        '| 7 | Éditeur central | `702, 102, 565, 817` |',
        '| 8 | Inspecteur | `1275, 102, 388, 817` |',
        'bord de panneau : `±4 px` maximum',
        'gouttière : `±2 px` maximum',
        'hauteur de chrome : `±3 px` maximum',
        'largeur de colonne : `±1,5 %` maximum',
        'géométrie interne et padding : `±2 px`',
        'taille ou hauteur de texte : `±1 px`',
        'text scale 1.0',
        'reste en attente d\'une approbation explicite',
      ]) {
        expect(markdown, contains(requiredMarker));
      }
    });
  });
}
