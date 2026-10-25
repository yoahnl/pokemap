import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'contact shadow project default is disabled and persists explicitly',
    () {
      final settings = ProjectSettings.fromJson({});
      expect(settings.toJson()['actorContactShadowsByDefault'], false);
      final enabled = ProjectSettings.fromJson({
        'actorContactShadowsByDefault': true,
      });
      expect(enabled.toJson()['actorContactShadowsByDefault'], true);
    },
  );

  test(
    'character contact shadow omission inherits and explicit values persist',
    () {
      final base = {'id': 'hero', 'name': 'Hero', 'tilesetId': 'actors'};
      expect(
        ProjectCharacterEntry.fromJson(base).toJson(),
        isNot(contains('contactShadow')),
      );
      for (final enabled in [true, false]) {
        final entry = ProjectCharacterEntry.fromJson({
          ...base,
          'contactShadow': enabled,
        });
        expect(entry.toJson()['contactShadow'], enabled);
      }
    },
  );
}
