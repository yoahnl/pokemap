import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BadgeDefinition', () {
    test('round-trips optional icon and field ability through manifest', () {
      final manifest = ProjectManifest(
        name: 'Selbrume',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        badges: <BadgeDefinition>[
          const BadgeDefinition(
            id: ' brume ',
            label: ' Badge Brume ',
            iconRelativePath: 'ui/badges/brume.png',
            fieldAbilityUnlock: FieldAbility.surf,
          ).normalized(),
        ],
      );

      final restored = ProjectManifest.fromJson(manifest.toJson());

      expect(restored.badges.single.id, 'brume');
      expect(restored.badges.single.label, 'Badge Brume');
      expect(
        restored.badges.single.fieldAbilityUnlock,
        FieldAbility.surf,
      );
    });

    test('legacy manifest defaults badges to empty', () {
      final manifest = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'Legacy',
        'version': 'v6',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.badges, isEmpty);
    });

    test('rejects empty ids, labels and absolute icon paths', () {
      for (final badge in <BadgeDefinition>[
        const BadgeDefinition(id: ' ', label: 'Badge'),
        const BadgeDefinition(id: 'badge', label: ' '),
        const BadgeDefinition(
          id: 'badge',
          label: 'Badge',
          iconRelativePath: '/tmp/badge.png',
        ),
      ]) {
        expect(badge.normalized, throwsStateError);
      }
    });

    test('keeps acquisition in existing trainer and progression registries',
        () {
      const profile = TrainerProfile(name: 'Leaf', badgeIds: <String>['brume']);
      const progression = PlayerProgression(
        unlockedFieldAbilities: <FieldAbility>[FieldAbility.surf],
      );

      expect(profile.badgeIds, <String>['brume']);
      expect(progression.unlockedFieldAbilities,
          <FieldAbility>[FieldAbility.surf]);
    });
  });
}
