import 'package:avelune_studio/platform/rendering/studio_resource_index.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/contracts/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostics.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

  testWidgets(
    'incidents are grouped by owner, name their cause status and open the right resource',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final index = StudioResourceIndex(_project());
      final visuals = _Visuals([
        _diagnostic(
          index,
          'hgss-compagnon-ekans',
          WorkspaceResourceCause.unsupported,
        ),
        _diagnostic(
          index,
          'character-animation:asset-hgss-compagnon-ekans',
          WorkspaceResourceCause.unsupported,
        ),
        _diagnostic(index, 'mystery', WorkspaceResourceCause.readFailure),
      ]);
      final opened = <(String, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                WorkspaceResourceDiagnostics(
                  visuals: visuals,
                  onOpenOwner: (kind, id) async {
                    opened.add((kind, id));
                    return true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text('2 ressources en incident · ressources demandées'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('resource-details')));
      await tester.pumpAndSettle();
      expect(
        find.text('2 ressources concernées · 3 références'),
        findsOneWidget,
      );
      final owner = find.byKey(const ValueKey('resource-row-character:ekans'));
      expect(owner, findsOneWidget);
      expect(
        find.descendant(
          of: owner,
          matching: find.text('Abo — compagnon d’équipe'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: owner,
          matching: find.textContaining('Planche du personnage · Animations'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: owner, matching: find.text('Cause vérifiée')),
        findsOneWidget,
      );
      final unknown = find.byKey(const ValueKey('resource-row-mystery'));
      expect(
        find.descendant(of: unknown, matching: find.text('Cause non vérifiée')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: unknown,
          matching: find.byKey(const ValueKey('resource-open-owner')),
        ),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: owner,
          matching: find.byKey(const ValueKey('Voir le diagnostic complet')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('hgss-compagnon-ekans'), findsWidgets);
      expect(
        find.textContaining('character-animation:asset-hgss-compagnon-ekans'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('Fermer le diagnostic complet')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: owner,
          matching: find.byKey(const ValueKey('resource-open-owner')),
        ),
      );
      await tester.pumpAndSettle();
      expect(opened, [('character', 'ekans')]);
      expect(
        find.byKey(const ValueKey('resource-diagnostics-panel')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await visuals.dispose();
    },
  );
}

class _Visuals implements MapWorkspaceVisuals {
  _Visuals(this.diagnostics);
  final _changes = ChangeNotifier();
  @override
  List<WorkspaceResourceDiagnostic> diagnostics;
  @override
  Set<String> get activeResourceIds => {};
  @override
  List<String> get warnings => [];
  @override
  void addListener(VoidCallback listener) => _changes.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {}
  @override
  Future<void> dispose() async => _changes.dispose();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
