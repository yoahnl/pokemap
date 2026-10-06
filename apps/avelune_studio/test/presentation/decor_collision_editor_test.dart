import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/resources/decor_collision_mask.dart';
import 'package:avelune_studio/presentation/features/resources/decor_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/decor_draft_test.dart' as fixtures;
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('changing source dimensions cannot silently crop a fine mask', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = DecorDraft(tileset: fixtures.atlas())
      ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2);
    draft.paintCollisionPixel(const GridPos(x: 20, y: 4), solid: true);
    final before = draft.build();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecorEditorScreen(
            draft: draft,
            visuals: _AtlasVisuals(),
            project: fixtures.manifest,
            onSave: (_) async {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final atlas = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('atlas-selection')),
    );
    await tester.tapAt(atlas.localToGlobal(const Offset(3, 3)));
    await tester.pump();
    expect(draft.selection, before.frames.first.source);
    expect(draft.build().collisionProfile, before.collisionProfile);
    expect(find.textContaining('Conservez les dimensions'), findsOneWidget);
  });
  testWidgets('collision modes paint on the image instead of a detached grid', (
    tester,
  ) async {
    final draft = DecorDraft(tileset: fixtures.atlas())
      ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecorEditorScreen(
            draft: draft,
            visuals: WorkspaceTestVisuals(),
            project: fixtures.manifest,
            onSave: (_) async {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
    await tester.pump();
    expect(find.widgetWithText(StudioButton, 'Par case'), findsOneWidget);
    expect(find.widgetWithText(StudioButton, 'Au pixel'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('decor-collision-canvas')),
      findsOneWidget,
    );
  });

  testWidgets(
    'brush and eraser target pixels and one undo restores a whole stroke',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = DecorDraft(tileset: fixtures.atlas())
        ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DecorEditorScreen(
              draft: draft,
              visuals: WorkspaceTestVisuals(),
              project: fixtures.manifest,
              onSave: (_) async {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
      await tester.pumpAndSettle();
      var canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('decor-collision-canvas')),
      );
      final stroke = await tester.startGesture(
        canvas.localToGlobal(const Offset(4, 10)),
      );
      await stroke.moveTo(canvas.localToGlobal(const Offset(20, 10)));
      await stroke.up();
      await tester.pump();
      expect(draft.build().collisionProfile!.cells, hasLength(2));
      await tester.tap(find.widgetWithText(StudioButton, 'Annuler le trait'));
      await tester.pump();
      expect(draft.build().collisionProfile, isNull);
      await tester.tap(find.widgetWithText(StudioButton, 'Rétablir le trait'));
      await tester.pump();
      expect(draft.build().collisionProfile!.cells, hasLength(2));
      await tester.tap(find.widgetWithText(StudioButton, 'Au pixel'));
      await tester.tap(find.widgetWithText(StudioButton, 'Gomme'));
      await tester.pumpAndSettle();
      canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('decor-collision-canvas')),
      );
      await tester.tapAt(canvas.localToGlobal(const Offset(3.5, 4.5)));
      await tester.pump();
      final mask = draft.build().collisionProfile!.collisionMask!;
      final pixels = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
      expect(pixels[4 * 32 + 3], isFalse);
      expect(pixels.where((value) => value).length, 32 * 24 - 1);
      final actual = tester.widget<DecorCollisionMask>(
        find.byType(DecorCollisionMask),
      );
      expect(actual.image, isNotNull);
      expect(actual.pixels![4 * 32 + 3], isFalse);
      await tester.tap(find.widgetWithText(StudioButton, 'Annuler le trait'));
      await tester.pump();
      expect(draft.build().collisionProfile!.collisionMask, isNull);
    },
  );

  testWidgets('failed saving retains focused text and collisions for retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = DecorDraft(tileset: fixtures.atlas());
    var fail = true;
    final snapshots = <ProjectElementEntry>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecorEditorScreen(
            draft: draft,
            visuals: WorkspaceTestVisuals(),
            project: fixtures.manifest,
            onSave: (value) async {
              snapshots.add(value);
              if (fail) throw StateError('Publication refusée');
            },
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Arbre à l’orée');
    await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
    await tester.pumpAndSettle();
    final canvas = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('decor-collision-canvas')),
    );
    await tester.tapAt(canvas.localToGlobal(const Offset(4, 8)));
    await tester.pump();
    await tester.tap(find.widgetWithText(StudioButton, 'Enregistrer le décor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Publication refusée'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Arbre à l’orée',
    );
    expect(draft.blocked, {const GridPos(x: 0, y: 0)});
    fail = false;
    await tester.tap(find.widgetWithText(StudioButton, 'Enregistrer le décor'));
    await tester.pumpAndSettle();
    expect(snapshots, hasLength(2));
    expect(snapshots.last, snapshots.first);
    expect(find.textContaining('Publication refusée'), findsNothing);
  });

  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'collision actions remain accessible at $size and enlarged text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final draft = DecorDraft(tileset: fixtures.atlas());
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: DecorEditorScreen(
                  draft: draft,
                  visuals: WorkspaceTestVisuals(),
                  project: fixtures.manifest,
                  onSave: (_) async {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.widgetWithText(StudioButton, 'Collisions'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(StudioButton, 'Au pixel'),
        );
        await tester.tap(find.widgetWithText(StudioButton, 'Au pixel'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('decor-collision-canvas')),
        );
        expect(find.byType(DecorCollisionMask), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          tester
              .getRect(
                find.widgetWithText(StudioButton, 'Enregistrer le décor'),
              )
              .bottom,
          lessThan(size.height),
        );
      },
    );
  }
}

class _AtlasVisuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
  @override
  Widget atlasPreview(String tilesetId) => const SizedBox.expand();
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {}
}
