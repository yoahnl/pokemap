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
}
