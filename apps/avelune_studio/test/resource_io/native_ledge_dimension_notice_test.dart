import 'package:avelune_studio/features/map_workspace/application/traversal_labels.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'ledge_border_metadata_test.dart' show NativeLedgeResourceFixture;

void main() {
  for (final dimension in ProjectDimension.values) {
    test('a ledge jump says where the game applies it ($dimension)', () async {
      final fixture = await NativeLedgeResourceFixture.create();
      addTearDown(fixture.dispose);
      final before = fixture.record.draft.definition;
      expect(
        ledgeJumpSummary(before.jumpBehavior!),
        contains('le côté choisi'),
      );
      final notice = nativeLedgeJumpDimensionNotice(dimension);
      if (dimension == ProjectDimension.threeD) {
        expect(notice, contains('Ce saut s’applique aux cartes 2D'));
        expect(notice, contains('Talus à sens unique'));
      } else {
        expect(notice, isNull);
      }
      expect(fixture.record.draft.definition, before);
    });
  }
}
