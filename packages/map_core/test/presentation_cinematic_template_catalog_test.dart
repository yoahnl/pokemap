import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationCinematicTemplateCatalog', () {
    test('publishes the six approved templates in deterministic order', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();

      expect(catalog.schemaVersion, 1);
      expect(catalog.templates.map((template) => template.id), <String>[
        'blank',
        'titleIdentity',
        'immersiveOpening',
        'stagedStory',
        'interactivePath',
        'adaptiveVideo',
      ]);
      expect(catalog.templates.map((template) => template.order), <int>[
        0,
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(
        catalog.templates.every((template) => template.version == 1),
        isTrue,
      );
      expect(
        catalog.templates.every(
          (template) =>
              template.nameKey.startsWith('cinematic.template.') &&
              template.descriptionKey.endsWith('.description'),
        ),
        isTrue,
      );
    });

    test('declares native landscape and portrait compositions', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();

      for (final template in catalog.templates) {
        expect(
          template.compositions.map((composition) => composition.orientation),
          <PresentationTemplateOrientation>[
            PresentationTemplateOrientation.landscape,
            PresentationTemplateOrientation.portrait,
          ],
          reason: template.id,
        );
        expect(template.compositions.first.aspectWidth, 16);
        expect(template.compositions.first.aspectHeight, 9);
        expect(template.compositions.last.aspectWidth, 9);
        expect(template.compositions.last.aspectHeight, 16);
      }
    });

    test('keeps media optional with responsive fallback except music', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();
      final slots = catalog.templates.expand((template) => template.mediaSlots);

      expect(slots, isNotEmpty);
      expect(slots.every((slot) => !slot.required), isTrue);
      expect(
        slots
            .where((slot) => slot.kind == PresentationTemplateMediaKind.music)
            .every(
              (slot) =>
                  slot.variantPolicy ==
                  PresentationTemplateMediaVariantPolicy.shared,
            ),
        isTrue,
      );
      expect(
        slots
            .where((slot) => slot.kind != PresentationTemplateMediaKind.music)
            .every(
              (slot) =>
                  slot.variantPolicy ==
                  PresentationTemplateMediaVariantPolicy.responsiveFallback,
            ),
        isTrue,
      );
    });

    test('roundtrips every template through the strict catalog codec', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();

      final decoded = PresentationCinematicTemplateCatalog.fromJson(
        catalog.toJson(),
      );

      expect(decoded, catalog);
      for (final template in catalog.templates) {
        expect(
          decoded.require(template.id, version: template.version),
          template,
        );
      }
    });

    test('rejects unknown identity or version', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();

      expect(
        () => catalog.require('unknown', version: 1),
        throwsA(isA<PresentationCinematicTemplateException>()),
      );
      expect(
        () => catalog.require('blank', version: 2),
        throwsA(isA<PresentationCinematicTemplateException>()),
      );
    });
  });
}
