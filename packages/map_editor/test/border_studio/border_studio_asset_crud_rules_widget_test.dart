import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/border_studio_workspace.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_assets_step.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'connected-line imports are publishable through candidate readiness',
    (tester) async {
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap_connected_line_import_',
      );
      addTearDown(() {
        if (projectRoot.existsSync()) {
          projectRoot.deleteSync(recursive: true);
        }
      });
      final atlas = File(
        p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
      );
      atlas.parent.createSync(recursive: true);
      atlas.writeAsBytesSync(_atlasBytes(), flush: true);
      final manifest = _manifestWithAsset();
      final container = await _pumpWorkspace(
        tester,
        manifest,
        projectRoot.path,
      );
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier)
            ..createBlueprint(
              id: 'connected-cliff',
              name: 'Falaise connectée',
              template: BorderBlueprintTemplate.connectedLine,
            );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-step-Assets')),
      );
      await tester.pump();

      for (var index = 0; index < 3; index += 1) {
        await tester.runAsync(
          () => tester
              .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
              .onAnalyzeSelected(),
        );
        await tester.pump();
      }

      final imported =
          controller.state.workingDraft!.blueprint.definition.primitives;
      expect(imported, hasLength(3));
      expect(
        imported.map((primitive) => primitive.transforms.allowFlipX),
        everyElement(isTrue),
      );
      const roles = <BorderPrimitiveRole>[
        BorderPrimitiveRole.lineCap,
        BorderPrimitiveRole.lineStraight,
        BorderPrimitiveRole.lineCorner,
      ];
      controller.replacePrimitives(<BorderPrimitiveDraft>[
        for (final (index, primitive) in imported.indexed)
          _primitiveWithRole(primitive, roles[index]),
      ]);
      final candidateManifest = controller.saveDraft();
      final candidateRecord =
          candidateManifest.borderCatalog.recordById('connected-cliff')!;
      const service = BorderProjectElementAssetService();
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: service.prepare,
        buildCandidate: const BorderPublicationCandidateBuilder().build,
        resolveCanonicalGallery: ({
          required blueprintId,
          required blueprintRevision,
          required visualSnapshots,
          required tileSizePx,
          required resolverVersion,
        }) =>
            BorderStudioCanonicalGalleryResolution.fromCore(
          resolveBorderCanonicalGallery(
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: visualSnapshots,
            tileSizePx: tileSizePx,
            resolverVersion: resolverVersion,
          ),
        ),
        publishRequest: (_) async => throw StateError('not used'),
      );
      BorderStudioPublicationPreview? preview;
      await tester.runAsync(() async {
        preview = await coordinator.prepare(
          manifest: candidateManifest,
          projectRootPath: projectRoot.path,
          draftRecord: candidateRecord,
        );
      });

      expect(preview, isNotNull);
      expect(preview!.candidate.nextManifest.borderCatalog.formatVersion,
          ProjectBorderCatalog.formatVersionV2);
      expect(preview!.diagnostics.hasErrors, isFalse);
      expect(preview!.canPublish, isTrue);
    },
  );

  testWidgets('masonry imports authorize the mirrored line side',
      (tester) async {
    final projectRoot = Directory.systemTemp.createTempSync(
      'pokemap_masonry_line_import_',
    );
    addTearDown(() {
      if (projectRoot.existsSync()) {
        projectRoot.deleteSync(recursive: true);
      }
    });
    final atlas = File(
      p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
    );
    atlas.parent.createSync(recursive: true);
    atlas.writeAsBytesSync(_atlasBytes(), flush: true);
    final container = await _pumpWorkspace(
      tester,
      _manifestWithAsset(),
      projectRoot.path,
    );
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier)
          ..createBlueprint(
            id: 'masonry-cliff',
            name: 'Pierres unitaires',
            template: BorderBlueprintTemplate.masonryLine,
          );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Assets')),
    );
    await tester.pump();

    await tester.runAsync(
      () => tester
          .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
          .onAnalyzeSelected(),
    );
    await tester.pump();

    final imported =
        controller.state.workingDraft!.blueprint.definition.primitives.single;
    expect(imported.transforms.allowFlipX, isTrue);
  });

  testWidgets(
    'selects a named project element, analyzes it, previews it, and removes it',
    (tester) async {
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap_border_studio_asset_ui_',
      );
      addTearDown(() {
        if (projectRoot.existsSync()) {
          projectRoot.deleteSync(recursive: true);
        }
      });
      final atlas = File(
        p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
      );
      atlas.parent.createSync(recursive: true);
      atlas.writeAsBytesSync(_atlasBytes(), flush: true);

      final container = await _pumpWorkspace(
        tester,
        _manifestWithAsset(),
        projectRoot.path,
      );
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier);
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-new-blueprint')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-step-Assets')),
      );
      await tester.pump();

      final picker = find.byKey(
        const ValueKey<String>('border-studio-project-element-picker'),
      );
      expect(picker, findsOneWidget);
      expect(find.text('Rocher côtier'), findsOneWidget);
      expect(find.text('coast-rock'), findsNothing);

      tester.widget<PokeMapDropdownField<String>>(picker).onChanged(
            'coast-rock',
          );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('border-studio-analyze-asset')),
        findsOneWidget,
      );
      await tester.runAsync(
        () => tester
            .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
            .onAnalyzeSelected(),
      );
      await tester.pump();

      final primitives =
          controller.state.workingDraft!.blueprint.definition.primitives;
      expect(primitives, hasLength(1));
      expect(primitives.single.sourceElementId, 'coast-rock');
      expect(primitives.single.currentMetrics.pixelSize,
          const GridSize(width: 2, height: 1));
      expect(
        find.byKey(const ValueKey<String>('border-studio-asset-thumbnail')),
        findsOneWidget,
      );
      expect(find.text('Asset analysé'), findsWidgets);
      expect(find.text('Rocher côtier'), findsWidgets);
      expect(find.text('coast-rock'), findsNothing);

      final initialFingerprint =
          primitives.single.currentMetrics.assetFingerprint;
      atlas.writeAsBytesSync(_changedAtlasBytes(), flush: true);
      expect(
        find.byKey(
          ValueKey<String>(
            'border-studio-reanalyze-asset-${primitives.single.id}',
          ),
        ),
        findsOneWidget,
      );
      await tester.runAsync(
        () => tester
            .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
            .onReanalyzePrimitive(primitives.single.id),
      );
      await tester.pump();
      expect(
        controller.state.workingDraft!.blueprint.definition.primitives.single
            .currentMetrics.assetFingerprint,
        isNot(initialFingerprint),
      );
      expect(find.textContaining('a été relue explicitement'), findsOneWidget);

      await tester.tap(
        find.byKey(
          ValueKey<String>(
            'border-studio-remove-asset-${primitives.single.id}',
          ),
        ),
      );
      await tester.pump();

      expect(
        controller.state.workingDraft!.blueprint.definition.primitives,
        isEmpty,
      );
      expect(find.text('Asset retiré du brouillon.'), findsOneWidget);
    },
  );

  testWidgets('stone assets expose and persist their authored orientation',
      (tester) async {
    final projectRoot = Directory.systemTemp.createTempSync(
      'pokemap_border_studio_orientation_ui_',
    );
    addTearDown(() {
      if (projectRoot.existsSync()) {
        projectRoot.deleteSync(recursive: true);
      }
    });
    final atlas = File(
      p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
    );
    atlas.parent.createSync(recursive: true);
    atlas.writeAsBytesSync(_atlasBytes(), flush: true);
    final container = await _pumpWorkspace(
      tester,
      _manifestWithAsset(),
      projectRoot.path,
    );
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier)
          ..createBlueprint(
            id: 'oriented-cliff',
            name: 'Falaise orientée',
            template: BorderBlueprintTemplate.stoneChainLine,
          );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Assets')),
    );
    await tester.pump();
    await tester.runAsync(
      () => tester
          .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
          .onAnalyzeSelected(),
    );
    await tester.pump();

    final primitive =
        controller.state.workingDraft!.blueprint.definition.primitives.single;
    final picker = find.byKey(
      ValueKey<String>(
        'border-studio-authored-orientation-picker-${primitive.id}',
      ),
    );
    expect(picker, findsOneWidget);
    expect(find.text('Orientation dessinée dans l\'asset'), findsOneWidget);
    final orientationField =
        tester.widget<PokeMapDropdownField<BorderPrimitiveOrientation>>(picker);
    expect(
      orientationField.items.map((item) => item.label),
      <String>['Historique', 'Nord', 'Est', 'Sud', 'Ouest'],
    );
    orientationField.onChanged(BorderPrimitiveOrientation.west);
    await tester.pump();

    expect(
      controller.state.workingDraft!.blueprint.definition.primitives.single
          .authoredOrientation,
      BorderPrimitiveOrientation.west,
    );
    expect(controller.state.diagnosticsAreCurrent, isFalse);
  });

  testWidgets('edits the three guided rules and preserves advanced values',
      (tester) async {
    final container = await _pumpWorkspace(
      tester,
      _emptyManifest(),
      Directory.systemTemp.path,
    );
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-new-blueprint')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();

    _changeSlider(tester, 'border-studio-regularity-control', 60);
    await tester.pump();
    _changeSlider(tester, 'border-studio-details-control', 35);
    await tester.pump();
    _changeSlider(tester, 'border-studio-variety-control', 80);
    await tester.pump();

    final rules = controller.state.workingDraft!.blueprint.definition.defaults;
    expect(rules.irregularityPermille, 400);
    expect(rules.detailDensityPermille, 350);
    expect(rules.variationPermille, 800);
    expect(rules.maxOverlapPx, 4);
    expect(rules.gapTolerancePx, 1);
    expect(rules.depthRows, 1);
    expect(find.text('Régularité'), findsWidgets);
    expect(find.text('Quantité de détails'), findsWidgets);
    expect(find.text('Variété'), findsWidgets);
  });

  testWidgets(
    'connected-line rules hide ineffective controls and retain useful ones',
    (tester) async {
      final container = await _pumpWorkspace(
        tester,
        _emptyManifest(),
        Directory.systemTemp.path,
      );
      container
          .read(borderStudioDraftControllerProvider.notifier)
          .createBlueprint(
            id: 'connected-rules',
            name: 'Ligne connectée',
            template: BorderBlueprintTemplate.connectedLine,
          );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-step-Règles')),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('border-studio-regularity-control'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('border-studio-details-control')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('border-studio-variety-control')),
        findsOneWidget,
      );
      expect(find.text('Variété'), findsWidgets);
      expect(find.text('Réglages avancés'), findsOneWidget);
      expect(find.textContaining('Chevauchement'), findsOneWidget);
      final rotationToggle = find.byKey(
        const ValueKey<String>('border-studio-auto-rotation-toggle'),
      );
      expect(rotationToggle, findsOneWidget);
      expect(find.text('Rotation automatique'), findsOneWidget);

      tester.widget<PokeMapToggleTile>(rotationToggle).onChanged(false);
      await tester.pump();
      expect(find.text('Conserve l\'asset sans rotation.'), findsOneWidget);
      expect(
        container
            .read(borderStudioDraftControllerProvider)
            .workingDraft!
            .blueprint
            .definition
            .defaults
            .allowAutoRotation,
        isFalse,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-profile-wild')),
      );
      await tester.pump();

      final naturalRules = container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .defaults;
      expect(naturalRules.variationPermille, 700);
      expect(naturalRules.maxOverlapPx, 32);
      expect(naturalRules.gapTolerancePx, 6);
      expect(naturalRules.allowAutoRotation, isFalse);
      expect(find.text('Profil varié appliqué'), findsOneWidget);
      expect(
        find.text('Chevauchement 32 px · vide toléré 6 px'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-profile-strict')),
      );
      await tester.pump();

      final strictRules = container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .defaults;
      expect(strictRules.variationPermille, 100);
      expect(strictRules.maxOverlapPx, 4);
      expect(strictRules.gapTolerancePx, 1);
    },
  );

  testWidgets('stone-chain rules expose guided stone controls and profiles',
      (tester) async {
    final container = await _pumpWorkspace(
      tester,
      _emptyManifest(),
      Directory.systemTemp.path,
    );
    container
        .read(borderStudioDraftControllerProvider.notifier)
        .createBlueprint(
          id: 'stone-chain-rules',
          name: 'Chaîne de pierres',
          template: BorderBlueprintTemplate.stoneChainLine,
        );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('border-studio-stone-spacing-control'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-stone-irregularity-control'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'border-studio-stone-secondary-density-control',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('border-studio-variety-control')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-auto-rotation-toggle'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-two-tier-toggle'),
      ),
      findsOneWidget,
    );
    expect(find.text('Deux étages continus'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-stone-interlock-control'),
      ),
      findsOneWidget,
    );
    expect(find.text('Imbrication des pierres'), findsWidgets);
    expect(
      find.text(
        'Conserve l\'éclairage et l\'orientation d\'origine des pierres.',
      ),
      findsOneWidget,
    );

    final twoTierToggle = find.byKey(
      const ValueKey<String>('border-studio-two-tier-toggle'),
    );
    tester.widget<PokeMapToggleTile>(twoTierToggle).onChanged(false);
    await tester.pump();
    expect(
      container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .defaults
          .depthRows,
      1,
    );
    tester.widget<PokeMapToggleTile>(twoTierToggle).onChanged(true);
    await tester.pump();

    _changeSlider(tester, 'border-studio-stone-interlock-control', 50);
    await tester.pump();
    expect(
      container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .defaults
          .maxOverlapPx,
      6,
    );

    _changeSlider(tester, 'border-studio-stone-spacing-control', 75);
    await tester.pump();
    expect(find.text('Espacement visible entre les pierres'), findsOneWidget);
    _changeSlider(tester, 'border-studio-stone-irregularity-control', 41);
    await tester.pump();
    _changeSlider(
      tester,
      'border-studio-stone-secondary-density-control',
      32,
    );
    await tester.pump();

    var rules = container
        .read(borderStudioDraftControllerProvider)
        .workingDraft!
        .blueprint
        .definition
        .defaults;
    expect(rules.gapTolerancePx, 6);
    expect(rules.irregularityPermille, 410);
    expect(rules.detailDensityPermille, 320);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-profile-wild')),
    );
    await tester.pump();
    rules = container
        .read(borderStudioDraftControllerProvider)
        .workingDraft!
        .blueprint
        .definition
        .defaults;
    expect(find.text('Naturel et irrégulier'), findsOneWidget);
    expect(rules.irregularityPermille, 420);
    expect(rules.detailDensityPermille, 330);
    expect(rules.variationPermille, 1000);
    expect(rules.maxOverlapPx, 2);
    expect(rules.gapTolerancePx, 3);
    expect(rules.depthRows, 2);
    expect(rules.allowAutoRotation, isFalse);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-profile-strict')),
    );
    await tester.pump();
    rules = container
        .read(borderStudioDraftControllerProvider)
        .workingDraft!
        .blueprint
        .definition
        .defaults;
    expect(find.text('Fin et côtier'), findsOneWidget);
    expect(rules.irregularityPermille, 180);
    expect(rules.detailDensityPermille, 0);
    expect(rules.variationPermille, 1000);
    expect(rules.maxOverlapPx, 8);
    expect(rules.gapTolerancePx, 0);
    expect(rules.depthRows, 2);
    expect(rules.allowAutoRotation, isFalse);
  });

  testWidgets('masonry rules expose the automatic rotation toggle',
      (tester) async {
    final container = await _pumpWorkspace(
      tester,
      _emptyManifest(),
      Directory.systemTemp.path,
    );
    container
        .read(borderStudioDraftControllerProvider.notifier)
        .createBlueprint(
          id: 'masonry-rules',
          name: 'Pierres unitaires',
          template: BorderBlueprintTemplate.masonryLine,
        );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();

    final rotationToggle = find.byKey(
      const ValueKey<String>('border-studio-auto-rotation-toggle'),
    );
    expect(rotationToggle, findsOneWidget);

    tester.widget<PokeMapToggleTile>(rotationToggle).onChanged(false);
    await tester.pump();

    expect(find.text('Conserve l\'asset sans rotation.'), findsOneWidget);
    expect(
      container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .defaults
          .allowAutoRotation,
      isFalse,
    );
  });

  testWidgets('duplicates, deletes, and renames drafts from guided actions',
      (tester) async {
    final container = await _pumpWorkspace(
      tester,
      _manifestWithDraft(),
      Directory.systemTemp.path,
    );
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-duplicate-blueprint')),
    );
    await tester.pump();
    expect(controller.state.workingDraft!.blueprint.definition.name,
        'Côte rocheuse — copie');
    expect(controller.state.isDirty, isTrue);
    expect(find.text('coast-blueprint'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-delete-blueprint')),
    );
    await tester.pump();
    expect(controller.state.selectedBlueprintId, 'coast-blueprint');
    expect(controller.state.workingDraft!.blueprint.definition.name,
        'Côte rocheuse');

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-rename-blueprint')),
    );
    await tester.pump();
    final renameField = find.byKey(
      const ValueKey<String>('border-studio-rename-field'),
    );
    expect(renameField, findsOneWidget);
    await tester.enterText(renameField, 'Falaise du port');
    await tester.tap(
      find.byKey(
        const ValueKey<String>('border-studio-confirm-rename'),
      ),
    );
    await tester.pump();

    expect(controller.state.workingDraft!.blueprint.definition.name,
        'Falaise du port');
    expect(find.text('Falaise du port'), findsWidgets);
    expect(find.text('coast-blueprint'), findsNothing);
  });

  testWidgets(
    'discards reanalysis that completes after another blueprint is selected',
    (tester) async {
      final projectRoot = _projectRootWithAtlas('stale_asset_result');
      addTearDown(() => projectRoot.deleteSync(recursive: true));
      final container = await _pumpWorkspace(
        tester,
        _manifestWithSharedPrimitiveIds(),
        projectRoot.path,
      );
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier);
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-step-Assets')),
      );
      await tester.pump();

      final reanalyze = tester
          .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
          .onReanalyzePrimitive;
      await tester.runAsync(() async {
        final pending = reanalyze('shared-primitive');
        controller.selectBlueprint('coast-b');
        await pending;
      });
      await tester.pump();

      final selectedPrimitive =
          controller.state.workingDraft!.blueprint.definition.primitives.single;
      expect(controller.state.selectedBlueprintId, 'coast-b');
      expect(
        selectedPrimitive.currentMetrics.assetFingerprint,
        'fingerprint-b',
      );
      expect(
        find.textContaining('résultat a été ignoré'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'does not reuse a cached thumbnail for the same primitive id in another blueprint',
    (tester) async {
      final projectRoot = _projectRootWithAtlas('isolated_asset_preview');
      addTearDown(() => projectRoot.deleteSync(recursive: true));
      final container = await _pumpWorkspace(
        tester,
        _manifestWithSharedPrimitiveIds(),
        projectRoot.path,
      );
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier);
      await tester.tap(
        find.byKey(const ValueKey<String>('border-studio-step-Assets')),
      );
      await tester.pump();
      await tester.runAsync(
        () => tester
            .widget<BorderAssetsStep>(find.byType(BorderAssetsStep))
            .onReanalyzePrimitive('shared-primitive'),
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapAssetThumbnail>(
              find.byType(PokeMapAssetThumbnail),
            )
            .imageBytes,
        isNotNull,
      );

      controller.selectBlueprint('coast-b');
      await tester.pump();

      expect(
        tester
            .widget<PokeMapAssetThumbnail>(
              find.byType(PokeMapAssetThumbnail),
            )
            .imageBytes,
        isNull,
      );
    },
  );
}

void _changeSlider(WidgetTester tester, String key, double value) {
  final slider = find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(CupertinoSlider),
  );
  expect(slider, findsOneWidget);
  tester.widget<CupertinoSlider>(slider).onChanged!(value);
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester,
  ProjectManifest manifest,
  String projectRootPath,
) async {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: projectRootPath,
    project: manifest,
    workspaceMode: EditorWorkspaceMode.borderStudio,
    activeMap: null,
  );
  addTearDown(() async {
    subscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  await tester.binding.setSurfaceSize(const Size(1280, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const CupertinoPageScaffold(child: BorderStudioWorkspace()),
      ),
    ),
  );
  await tester.pump();
  return container;
}

ProjectManifest _emptyManifest() => const ProjectManifest(
      name: 'Border Studio UI',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

ProjectManifest _manifestWithAsset() => const ProjectManifest(
      name: 'Border Studio UI',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'coast',
          name: 'Rochers côtiers',
          relativePath: 'assets/tilesets/coast.png',
        ),
      ],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'coast-rock',
          name: 'Rocher côtier',
          tilesetId: 'coast',
          categoryId: 'coast',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
      settings: ProjectSettings(tileWidth: 2, tileHeight: 1),
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
    );

ProjectManifest _manifestWithDraft() => ProjectManifest(
      name: 'Border Studio UI',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      borderCatalog: ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          BorderBlueprintRecord(
            id: 'coast-blueprint',
            draft: BorderBlueprintDraft(
              baseRevision: 0,
              definition: BorderBlueprintDraftDefinition(
                name: 'Côte rocheuse',
                previewSeed: BorderSignedInt64.fromInt(42),
                template: BorderBlueprintTemplate.organicEdge,
                primitives: const <BorderPrimitiveDraft>[],
                defaults: BorderGenerationParams(
                  irregularityPermille: 250,
                  detailDensityPermille: 500,
                  variationPermille: 300,
                  maxOverlapPx: 4,
                  gapTolerancePx: 1,
                  depthRows: 1,
                ),
                sortOrder: 0,
              ),
            ),
          ),
        ],
      ),
    );

ProjectManifest _manifestWithSharedPrimitiveIds() => ProjectManifest(
      name: 'Border Studio guarded assets',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'coast',
          name: 'Rochers côtiers',
          relativePath: 'assets/tilesets/coast.png',
        ),
      ],
      elements: const <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'coast-rock',
          name: 'Rocher côtier',
          tilesetId: 'coast',
          categoryId: 'coast',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
      settings: const ProjectSettings(tileWidth: 2, tileHeight: 1),
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      borderCatalog: ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _recordWithSharedPrimitive(
            id: 'coast-a',
            name: 'Côte A',
            fingerprint: 'fingerprint-a',
            sortOrder: 0,
          ),
          _recordWithSharedPrimitive(
            id: 'coast-b',
            name: 'Côte B',
            fingerprint: 'fingerprint-b',
            sortOrder: 1,
          ),
        ],
      ),
    );

BorderBlueprintRecord _recordWithSharedPrimitive({
  required String id,
  required String name,
  required String fingerprint,
  required int sortOrder,
}) {
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: name,
        previewSeed: BorderSignedInt64.fromInt(sortOrder + 1),
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPrimitiveDraft>[
          BorderPrimitiveDraft(
            id: 'shared-primitive',
            sourceElementId: 'coast-rock',
            role: BorderPrimitiveRole.structureLarge,
            weight: 1000,
            anchorPx: const BorderPixelPos(x: 1, y: 0),
            transforms: BorderTransformPolicy(
              allowFlipX: false,
              allowedQuarterTurns: const <int>[0, 1, 2, 3],
            ),
            currentMetrics: BorderPrimitiveAssetMetrics(
              assetFingerprint: fingerprint,
              pixelSize: const GridSize(width: 2, height: 1),
              opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
              defaultAnchorPx: const BorderPixelPos(x: 1, y: 0),
              occupancyMaskRle: '1:2',
            ),
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 250,
          detailDensityPermille: 500,
          variationPermille: 300,
          maxOverlapPx: 4,
          gapTolerancePx: 1,
          depthRows: 1,
        ),
        sortOrder: sortOrder,
      ),
    ),
  );
}

Directory _projectRootWithAtlas(String prefix) {
  final projectRoot = Directory.systemTemp.createTempSync('pokemap_$prefix');
  final atlas = File(
    p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
  );
  atlas.parent.createSync(recursive: true);
  atlas.writeAsBytesSync(_atlasBytes(), flush: true);
  return projectRoot;
}

Uint8List _atlasBytes() {
  final image = img.Image(width: 2, height: 1, numChannels: 4)
    ..setPixelRgba(0, 0, 80, 70, 60, 255)
    ..setPixelRgba(1, 0, 110, 100, 90, 255);
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _changedAtlasBytes() {
  final image = img.Image(width: 2, height: 1, numChannels: 4)
    ..setPixelRgba(0, 0, 20, 40, 60, 255)
    ..setPixelRgba(1, 0, 80, 100, 120, 255);
  return Uint8List.fromList(img.encodePng(image));
}

BorderPrimitiveDraft _primitiveWithRole(
  BorderPrimitiveDraft primitive,
  BorderPrimitiveRole role,
) =>
    BorderPrimitiveDraft(
      id: primitive.id,
      sourceElementId: primitive.sourceElementId,
      role: role,
      weight: primitive.weight,
      anchorPx: primitive.anchorPx,
      transforms: primitive.transforms,
      currentMetrics: primitive.currentMetrics,
    );
