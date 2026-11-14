import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'border_profile_loading_fixture.dart';

void main() {
  test('the map lists border profiles without their pieces and resolves only the chosen one', () async {
    final measures = <int, ({int profileReads, int choiceReads})>{};
    for (final unrelated in [0, 150, 450]) {
      final fixture = await BorderFixture.create(unrelated: unrelated);
      try {
        await fixture.openWorkspace();
        final workspace = fixture.workspace;
        expect(workspace.hasBorderProfiles, isFalse);
        expect(workspace.hasBorderBlueprint('cliff_target'), isFalse);
        final pieces = fixture.blockedPieceFiles();
        if (unrelated > 0) expect(pieces, isNotEmpty);

        final profileReads = await fixture.guarded(
          pieces,
          workspace.ensureBorderProfiles,
        );
        expect(workspace.hasBorderProfiles, isTrue);
        final listed = workspace.project!;
        expect(listed.borderCatalog.records.length, unrelated + 2);
        expect(
          listed.models3d.where((model) => model.id.startsWith('piece_')),
          isEmpty,
        );
        expect(
          listed.resourceLibraryCatalog
              .entryFor('borderBlueprint', 'cliff_target')
              ?.familyId,
          'family_cliffs',
        );
        expect(
          listed.resourceLibraryCatalog.families.map((family) => family.id),
          contains('family_cliffs'),
        );

        final choiceReads = await fixture.guarded(
          pieces,
          () => workspace.ensureBorderBlueprint('cliff_target'),
        );
        expect(workspace.hasBorderBlueprint('cliff_target'), isTrue);
        expect(workspace.hasBorderBlueprint('cliff_other'), isFalse);
        expect(
          workspace.project!.models3d
              .map((model) => model.id)
              .where((id) => id.startsWith('piece_'))
              .toSet(),
          {'piece_target_a', 'piece_target_b'},
        );
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.visualProject!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        measures[unrelated] = (
          profileReads: profileReads,
          choiceReads: choiceReads,
        );

        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'familyId': 'family_cliffs',
        });
        expect(
          workspace.project!.resourceLibraryCatalog
              .entryFor('borderBlueprint', 'cliff_other')
              ?.familyId,
          'family_cliffs',
        );

        expect(workspace.hasWorkshop(MapWorkspaceWorkshop.resources), isFalse);
        await workspace.activate(
          workspace.project!.maps.singleWhere((map) => map.id == 'clairiere'),
        );
        expect(workspace.error, isNull);
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.project!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'description': 'Après changement de carte',
        });

        await workspace.ensureResourceKind('element');
        expect(workspace.error, isNull);
        expect(workspace.hasBorderProfiles, isTrue);
        expect(workspace.hasBorderBlueprint('cliff_target'), isTrue);
        expect(workspace.project!.borderCatalog.records.length, unrelated + 2);
        expect(
          workspace.project!.models3d.map((model) => model.id),
          containsAll(['piece_target_a', 'piece_target_b']),
        );
        await fixture.mutate('resource.classify', {
          'resourceKind': 'borderBlueprint',
          'resourceId': 'cliff_other',
          'familyId': null,
          'description': null,
        });
        expect(
          workspace.project!.resourceLibraryCatalog.entryFor(
            'borderBlueprint',
            'cliff_other',
          ),
          isNull,
        );

        await fixture.reopen();
        expect(fixture.workspace.hasBorderProfiles, isFalse);
        await fixture.workspace.ensureBorderProfiles();
        expect(
          fixture.workspace.project!.resourceLibraryCatalog.entryFor(
            'borderBlueprint',
            'cliff_other',
          ),
          isNull,
        );
      } finally {
        await fixture.dispose();
      }
    }
    printOnFailure('$measures');
    expect(measures[150]!.choiceReads, measures[0]!.choiceReads);
    expect(measures[450]!.choiceReads, measures[0]!.choiceReads);
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('the old family loading resolves every border piece', () async {
    final fixture = await BorderFixture.create(unrelated: 12);
    try {
      await fixture.openWorkspace();
      await fixture.workspace.ensureResourceKind('borderBlueprint');
      expect(
        fixture.workspace.project!.models3d
            .where((model) => model.id.startsWith('piece_'))
            .length,
        2 * 14,
      );
      expect(fixture.workspace.hasBorderProfiles, isTrue);
      expect(fixture.workspace.hasBorderBlueprint('cliff_other'), isTrue);
    } finally {
      await fixture.dispose();
    }
  });
}
