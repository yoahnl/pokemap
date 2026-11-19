import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLocaleResolver', () {
    const supported = <String>['fr-FR', 'en-US', 'es'];

    test('prefers an exact supported locale', () {
      expect(
        ProjectLocaleResolver.resolve(
          preferredLocale: 'en-US',
          supportedLocales: supported,
          fallbackLocale: 'fr-FR',
        ),
        'en-US',
      );
    });

    test('matches the preferred language before falling back', () {
      expect(
        ProjectLocaleResolver.resolve(
          preferredLocale: 'en-GB',
          supportedLocales: supported,
          fallbackLocale: 'fr-FR',
        ),
        'en-US',
      );
    });

    test('uses the declared project fallback for an unsupported language', () {
      expect(
        ProjectLocaleResolver.resolve(
          preferredLocale: 'de-DE',
          supportedLocales: supported,
          fallbackLocale: 'fr-FR',
        ),
        'fr-FR',
      );
    });
  });

  group('ProjectLocalePolicy.resolvePreferred', () {
    final policy = ProjectLocalePolicy(
      supportedLocales: ['fr-FR', 'en-US', 'es'],
      fallbackLocale: 'fr-FR',
    );

    test('tries later content preferences before the declared fallback', () {
      expect(policy.resolvePreferred(['it-IT', 'EN_us']), 'en-US');
      expect(policy.resolvePreferred(['it-IT', 'es-MX', 'en-US']), 'es');
    });

    test('keeps project language matching within each candidate', () {
      expect(policy.resolvePreferred(['en-GB', 'es']), 'en-US');
    });

    test('uses the project fallback after exhausting the candidates', () {
      expect(policy.resolvePreferred(['it-IT', 'de-DE']), 'fr-FR');
      expect(policy.resolvePreferred([]), 'fr-FR');
    });
  });
}
