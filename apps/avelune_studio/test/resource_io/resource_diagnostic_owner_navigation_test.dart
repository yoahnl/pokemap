import 'package:avelune_studio/platform/rendering/studio_resource_index.dart';
import 'package:avelune_studio/platform/rendering/contracts/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/features/map_workspace/application/workspace_resource_diagnostic_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectManifest _project() => workspaceProject.copyWith(
  characters: [
    ProjectCharacterEntry(
      id: 'ekans',
      name: 'Abo — compagnon d’équipe',
      tilesetId: 'hgss-compagnon-ekans',
      frameWidth: 2,
      frameHeight: 2,
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.south,
          sourceAssetId: 'asset-hgss-compagnon-ekans',
          frames: const [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    ),
  ],
);

WorkspaceResourceDiagnostic _diagnostic(
  StudioResourceIndex index,
  String id,
  WorkspaceResourceCause cause,
) {
  final owner = index.owners[id];
  return WorkspaceResourceDiagnostic(
    resourceId: id,
    name: index.names[id] ?? id,
    cause: cause,
    detail: 'Détail $id',
    ownerKind: owner?.kind,
    ownerId: owner?.id,
    ownerName: owner?.name,
    role: owner?.role,
  );
}

void main() {
  test(
    'the resource index names the owner of a character sheet and animations',
    () {
      final index = StudioResourceIndex(_project());
      final sheet = index.owners['hgss-compagnon-ekans']!;
      expect(
        (sheet.kind, sheet.id, sheet.name),
        ('character', 'ekans', 'Abo — compagnon d’équipe'),
      );
      expect(sheet.role, 'Planche du personnage');
      final animation =
          index.owners['character-animation:asset-hgss-compagnon-ekans']!;
      expect((animation.kind, animation.id), ('character', 'ekans'));
      expect(animation.role, 'Animations');
      final tileset = index.owners[workspaceProject.tilesets.first.id]!;
      expect(tileset.kind, 'tileset');
      expect(index.owners['unknown-reference'], isNull);
    },
  );

  test('owner projection retains identity, roles, causes and complete references', () {
    final index = StudioResourceIndex(_project());
    final projection = WorkspaceResourceDiagnosticProjection([
      _diagnostic(index, 'hgss-compagnon-ekans', WorkspaceResourceCause.unsupported),
      _diagnostic(index, 'character-animation:asset-hgss-compagnon-ekans', WorkspaceResourceCause.unsupported),
      _diagnostic(index, 'mystery', WorkspaceResourceCause.readFailure),
    ], const {});
    expect(projection.ownerCount, 2);
    expect(projection.groups, hasLength(2));
    expect(projection.diagnostics, hasLength(3));
    final owner = projection.groups.singleWhere((group) => group.key == 'character:ekans');
    expect(owner.title, 'Abo — compagnon d’équipe');
    expect(owner.roles, ['Planche du personnage', 'Animations']);
    expect(owner.verified, isTrue);
    expect(owner.owner, ('character', 'ekans'));
    expect(owner.retryableIds, ['hgss-compagnon-ekans', 'character-animation:asset-hgss-compagnon-ekans']);
    final details = owner.items.map(workspaceResourceDiagnosticDetail).join('\n');
    expect(details, contains('hgss-compagnon-ekans'));
    expect(details, contains('character-animation:asset-hgss-compagnon-ekans'));
    final unknown = projection.groups.singleWhere((group) => group.key == 'mystery');
    expect(unknown.verified, isFalse);
    expect(unknown.owner, isNull);
    expect(unknown.items.single.explanation, contains('sans cause identifiée'));
  });

  test('an incomplete owner identity never yields an actionable resource', () {
    final projection = WorkspaceResourceDiagnosticProjection([
      const WorkspaceResourceDiagnostic(
        resourceId: 'partial', name: 'Référence partielle',
        cause: WorkspaceResourceCause.missing, ownerKind: 'character',
      ),
    ], const {});
    expect(projection.groups.single.owner, isNull);
    expect(projection.groups.single.key, 'partial');
  });
}
