import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('V1-126 cinematic emote catalog', () {
    test('exposes stable no-code entries', () {
      expect(cinematicEmoteCatalog, hasLength(greaterThanOrEqualTo(6)));
      expect(
          cinematicEmoteCatalog.map((entry) => entry.id),
          containsAll([
            cinematicDefaultActorEmoteId,
            'question',
            'heart',
            'anger',
            'music',
            'thought',
            'neutral',
          ]));

      final ids = cinematicEmoteCatalog.map((entry) => entry.id).toSet();
      expect(ids, hasLength(cinematicEmoteCatalog.length));
      expect(cinematicEmoteCatalog.every((entry) => entry.label.isNotEmpty),
          isTrue);
      expect(
        cinematicEmoteCatalog.any((entry) => entry.label == 'Surprise'),
        isTrue,
      );
      expect(
        cinematicEmoteCatalog.every(
          (entry) => !entry.id.contains(' ') && !entry.id.contains('é'),
        ),
        isTrue,
      );
    });

    test('keeps frame rects inside candidate atlases', () {
      for (final entry in cinematicEmoteCatalog) {
        final atlas = cinematicEmoteAtlasById(entry.atlasId);
        expect(atlas, isNotNull, reason: entry.id);
        expect(entry.frame.width, 16, reason: entry.id);
        expect(entry.frame.height, 16, reason: entry.id);
        expect(entry.frame.fitsInside(atlas!), isTrue, reason: entry.id);
        expect(atlas.assetKey, isNot(startsWith('/Users/')));
        expect(atlas.assetKey, startsWith('assets/cinematics/emotes/'));
      }
    });

    test('can find entries and fails safely for unknown ids', () {
      final entry = cinematicEmoteCatalogEntryById('question');
      expect(entry, isNotNull);
      expect(entry!.label, 'Question');

      expect(cinematicEmoteCatalogEntryById('missing_emote'), isNull);
      expect(cinematicEmoteCatalogEntryById('  '), isNull);
      expect(isCinematicEmoteIdKnown('heart'), isTrue);
      expect(isCinematicEmoteIdKnown('unknown'), isFalse);
    });
  });
}
