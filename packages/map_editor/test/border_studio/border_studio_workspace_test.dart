import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoPageScaffold;
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/border_studio_workspace.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets('creates a blueprint and exposes template-dependent role lists',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-new-blueprint')),
    );
    await tester.pump();

    expect(controller.state.workingDraft, isNotNull);
    expect(find.text('Côte organique'), findsOneWidget);
    expect(find.text('Muret maçonné'), findsOneWidget);
    expect(find.text('Clôture poteaux-traverses'), findsOneWidget);
    expect(find.text('Ligne connectée'), findsOneWidget);
    expect(find.text('Chaîne de pierres'), findsOneWidget);
    expect(find.text('Publication disponible'), findsNWidgets(5));
    expect(find.text('Publication après BORD-06'), findsNothing);

    final fenceTemplate =
        find.byKey(const ValueKey<String>('border-studio-template-fence'));
    await tester.ensureVisible(fenceTemplate);
    await tester.tap(fenceTemplate);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Rôles')),
    );
    await tester.pump();

    expect(find.text('Poteau'), findsOneWidget);
    expect(find.text('Traverse'), findsOneWidget);
    expect(find.text('Finition intérieure'), findsOneWidget);
    expect(find.text('Structure principale'), findsNothing);
    expect(
      find.text(
          'Poteau et Traverse sont requis. Les autres rôles sont optionnels.'),
      findsOneWidget,
    );
    expect(find.text('Publication après BORD-06'), findsNothing);
  });

  testWidgets(
      'connected line exposes three no-code slots and counts their variants',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier)
          ..createBlueprint(
            id: 'cliff-line',
            name: 'Falaise libre',
            template: BorderBlueprintTemplate.connectedLine,
          )
          ..replacePrimitives(<BorderPrimitiveDraft>[
            _primitive(id: 'cap-a', role: BorderPrimitiveRole.lineCap),
            _primitive(id: 'cap-b', role: BorderPrimitiveRole.lineCap),
            _primitive(
              id: 'straight',
              role: BorderPrimitiveRole.lineStraight,
            ),
            _primitive(id: 'corner', role: BorderPrimitiveRole.lineCorner),
          ]);
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Rôles')),
    );
    await tester.pump();

    expect(find.text('Extrémité'), findsWidgets);
    expect(find.text('Segment droit'), findsWidgets);
    expect(find.text('Angle'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-role-status-lineCap'),
      ),
      findsOneWidget,
    );
    expect(find.text('2 variantes'), findsOneWidget);
    expect(find.text('1 variante'), findsNWidgets(2));
    expect(find.text('Prêt'), findsNWidgets(3));
    expect(find.text('Manquant'), findsNothing);

    controller.removePrimitive('corner');
    await tester.pump();

    expect(find.text('Manquant'), findsOneWidget);
    expect(find.text('Prêt'), findsNWidgets(2));
  });

  testWidgets('masonry roles require one structure and keep finishes optional',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    container
        .read(borderStudioDraftControllerProvider.notifier)
        .createBlueprint(
          id: 'wall',
          name: 'Muret',
          template: BorderBlueprintTemplate.masonryLine,
        );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Rôles')),
    );
    await tester.pump();

    expect(find.text('Structure principale'), findsOneWidget);
    expect(find.text('Structure secondaire'), findsOneWidget);
    expect(find.text('Remplissage'), findsOneWidget);
    expect(find.text('Poteau'), findsOneWidget);
    expect(find.text('Finition intérieure'), findsOneWidget);
    expect(
      find.text(
        'Au moins une Structure principale, Structure secondaire ou Remplissage est requise. Les autres rôles sont optionnels.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'two-tier stone-chain roles require a top and a face with optional fallbacks',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier)
          ..createBlueprint(
            id: 'stone-chain',
            name: 'Chaîne de pierres',
            template: BorderBlueprintTemplate.stoneChainLine,
          );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Rôles')),
    );
    await tester.pump();

    for (final label in const <String>[
      'Sommet plat',
      'Face de falaise',
      'Pierre libre facultative',
      'Pierre de sommet à un angle',
      'Pierre de sommet à une extrémité',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Requis'), findsNWidgets(2));
    expect(find.text('Facultatif'), findsNWidgets(3));
    expect(find.text('Repli automatique'), findsNWidgets(3));
    expect(find.text('Manquant'), findsNWidgets(2));
    expect(find.text('Poteau'), findsNothing);
    expect(find.text('Traverse'), findsNothing);
    expect(find.text('Finition intérieure'), findsNothing);

    controller.replacePrimitives(<BorderPrimitiveDraft>[
      _primitive(
        id: 'main-stone',
        role: BorderPrimitiveRole.structureLarge,
      ),
    ]);
    await tester.pump();

    expect(find.text('Manquant'), findsOneWidget);
    expect(find.text('Rôles non résolus'), findsOneWidget);

    controller.replacePrimitives(<BorderPrimitiveDraft>[
      _primitive(
        id: 'main-stone',
        role: BorderPrimitiveRole.structureLarge,
      ),
      _primitive(
        id: 'cliff-face',
        role: BorderPrimitiveRole.structureMedium,
      ),
    ]);
    await tester.pump();

    expect(find.text('Manquant'), findsNothing);
    expect(find.text('Rôles non résolus'), findsNothing);
  });

  testWidgets('reports asset validation without exposing internal identifiers',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'internal-blueprint-id',
      name: 'Côte du port',
      template: BorderBlueprintTemplate.organicEdge,
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Assets')),
    );
    await tester.pump();

    expect(find.text('Aucun asset analysé'), findsOneWidget);
    expect(
      find.text('Ajoutez au moins une structure pour préparer la bordure.'),
      findsOneWidget,
    );
    expect(find.text('internal-blueprint-id'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('border-studio-asset-error')),
      findsOneWidget,
    );
  });

  testWidgets('strict and wild profiles edit guided integer rules',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'coast',
      name: 'Côte',
      template: BorderBlueprintTemplate.organicEdge,
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-profile-strict')),
    );
    await tester.pump();

    var rules = controller.state.workingDraft!.blueprint.definition.defaults;
    expect(rules.irregularityPermille, 100);
    expect(rules.detailDensityPermille, 250);
    expect(rules.variationPermille, 100);
    expect(find.text('Profil strict appliqué'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-profile-wild')),
    );
    await tester.pump();
    rules = controller.state.workingDraft!.blueprint.definition.defaults;
    expect(rules.irregularityPermille, 750);
    expect(rules.detailDensityPermille, 700);
    expect(rules.variationPermille, 700);
    expect(find.text('Profil sauvage appliqué'), findsOneWidget);
  });

  testWidgets('masonry rules use aligned and aged labels without depth rows',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'wall',
      name: 'Muret',
      template: BorderBlueprintTemplate.masonryLine,
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();

    expect(find.text('Aligné'), findsOneWidget);
    expect(find.text('Vieilli'), findsOneWidget);
    expect(find.textContaining('profondeur'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-profile-strict')),
    );
    await tester.pump();
    expect(find.text('Profil aligné appliqué'), findsOneWidget);
  });

  testWidgets('fence rules use regular and rustic labels without depth rows',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    container
        .read(borderStudioDraftControllerProvider.notifier)
        .createBlueprint(
          id: 'fence',
          name: 'Clôture',
          template: BorderBlueprintTemplate.postAndRailLine,
        );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Règles')),
    );
    await tester.pump();

    expect(find.text('Régulier'), findsOneWidget);
    expect(find.text('Rustique'), findsOneWidget);
    expect(find.textContaining('profondeur'), findsNothing);
  });

  testWidgets('assigns functional roles with a guided picker', (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'coast',
      name: 'Côte',
      template: BorderBlueprintTemplate.organicEdge,
    );
    controller.replacePrimitives(<BorderPrimitiveDraft>[
      _primitive(
        id: 'rock',
        role: BorderPrimitiveRole.structureLarge,
        authoredOrientation: BorderPrimitiveOrientation.west,
      ),
    ]);
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-step-Rôles')),
    );
    await tester.pump();

    final rolePicker = find.byKey(
      const ValueKey<String>('border-studio-role-picker-rock'),
    );
    expect(rolePicker, findsOneWidget);
    tester
        .widget<PokeMapDropdownField<BorderPrimitiveRole>>(rolePicker)
        .onChanged(BorderPrimitiveRole.outerAccent);
    await tester.pump();

    expect(
      controller
          .state.workingDraft!.blueprint.definition.primitives.single.role,
      BorderPrimitiveRole.outerAccent,
    );
    expect(
      controller.state.workingDraft!.blueprint.definition.primitives.single
          .authoredOrientation,
      BorderPrimitiveOrientation.west,
    );
  });

  testWidgets(
      'preview is a neutral sandbox with deterministic variation and distinct final actions',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'coast',
      name: 'Côte',
      template: BorderBlueprintTemplate.organicEdge,
    );
    controller.replacePrimitives(<BorderPrimitiveDraft>[
      _primitive(
        id: 'rock',
        role: BorderPrimitiveRole.structureLarge,
      ),
    ]);
    controller.setDiagnostics(const BorderDiagnosticsReport.empty());
    final previousSeed = controller.state.previewSeed;
    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'border-studio-step-Aperçu et publication',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('border-studio-neutral-sandbox')),
      findsOneWidget,
    );
    expect(find.text('Longue portion'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-gallery-not-prepared'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('border-studio-prepare-preview'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('border-studio-save-draft')),
      findsOneWidget,
    );
    final publish = find.byKey(
      const ValueKey<String>('border-studio-publish'),
    );
    expect(publish, findsOneWidget);
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNull);
    expect(
      find.text('Générez l’aperçu canonique avant de publier.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-new-variation')),
    );
    await tester.pump();
    expect(controller.state.previewSeed, isNot(previousSeed));
  });

  testWidgets('line templates report missing roles instead of a lot gate',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.createBlueprint(
      id: 'wall',
      name: 'Muret',
      template: BorderBlueprintTemplate.masonryLine,
    );
    controller.setDiagnostics(const BorderDiagnosticsReport.empty());
    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'border-studio-step-Aperçu et publication',
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Attribuez les rôles requis'), findsOneWidget);
    expect(find.textContaining('BORD-06'), findsNothing);
    final publish = find.byKey(
      const ValueKey<String>('border-studio-publish'),
    );
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNull);
  });

  testWidgets('step controls expose button semantics and keyboard activation',
      (tester) async {
    final container = await _pumpWorkspace(tester, _manifest());
    container
        .read(borderStudioDraftControllerProvider.notifier)
        .createBlueprint(
          id: 'coast',
          name: 'Côte',
          template: BorderBlueprintTemplate.organicEdge,
        );
    await tester.pump();

    final assetsStep = find.byKey(
      const ValueKey<String>('border-studio-step-Assets'),
    );
    final semantics = tester.getSemantics(assetsStep);
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.getSemanticsData().flagsCollection.isButton, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('border-studio-assets-step')),
      findsOneWidget,
    );
  });

  testWidgets('publication disables every workspace mutation and navigation',
      (tester) async {
    final publishCompleter = Completer<BorderPublicationResult>();
    late BorderPublicationRequest request;
    final manifest = _publicationManifest();
    final container = await _pumpControlledPublicationWorkspace(
      tester,
      manifest: manifest,
      coordinator: _controlledCoordinator(
        publishCompleter: publishCompleter,
        onPublishRequest: (value) => request = value,
      ),
    );
    await _prepareAndStartPublication(tester, container);

    for (final key in const <String>[
      'border-studio-new-blueprint',
      'border-studio-step-Type',
      'border-studio-step-Assets',
      'border-studio-step-Rôles',
      'border-studio-step-Règles',
      'border-studio-step-Aperçu et publication',
      'border-studio-prepare-preview',
      'border-studio-new-variation',
      'border-studio-save-draft',
      'border-studio-publish',
    ]) {
      final button = tester.widget<PokeMapButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull, reason: '$key must be disabled');
    }
    for (final key in const <String>[
      'border-studio-rename-blueprint',
      'border-studio-duplicate-blueprint',
      'border-studio-delete-blueprint',
    ]) {
      final button = tester.widget<PokeMapIconButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull, reason: '$key must be disabled');
    }
    expect(
      tester
          .widgetList<PokeMapSidebarItem>(
            find.byType(PokeMapSidebarItem),
          )
          .every((item) => item.onTap == null),
      isTrue,
    );

    publishCompleter.complete(_publicationResult(request.nextManifest));
    await tester.pumpAndSettle();
    expect(
      container.read(editorNotifierProvider).project,
      request.nextManifest,
    );
  });

  testWidgets('publication completion never pollutes a newly opened project',
      (tester) async {
    final publishCompleter = Completer<BorderPublicationResult>();
    late BorderPublicationRequest request;
    final originalManifest = _publicationManifest();
    final container = await _pumpControlledPublicationWorkspace(
      tester,
      manifest: originalManifest,
      coordinator: _controlledCoordinator(
        publishCompleter: publishCompleter,
        onPublishRequest: (value) => request = value,
      ),
    );
    await _prepareAndStartPublication(tester, container);
    const replacementManifest = ProjectManifest(
      name: 'Replacement while publishing',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/projects/replacement',
      project: replacementManifest,
      workspaceMode: EditorWorkspaceMode.borderStudio,
    );
    await tester.pump();

    publishCompleter.complete(_publicationResult(request.nextManifest));
    await tester.pumpAndSettle();

    final editor = container.read(editorNotifierProvider);
    expect(editor.projectRootPath, '/projects/replacement');
    expect(editor.project, same(replacementManifest));
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('border-studio-new-blueprint'),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('publication completion never overwrites a changed target draft',
      (tester) async {
    final publishCompleter = Completer<BorderPublicationResult>();
    late BorderPublicationRequest request;
    final manifest = _publicationManifest();
    final container = await _pumpControlledPublicationWorkspace(
      tester,
      manifest: manifest,
      coordinator: _controlledCoordinator(
        publishCompleter: publishCompleter,
        onPublishRequest: (value) => request = value,
      ),
    );
    await _prepareAndStartPublication(tester, container);
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.renameBlueprint('Edited while publication was pending');
    await tester.pump();

    publishCompleter.complete(_publicationResult(request.nextManifest));
    await tester.pumpAndSettle();

    expect(
      controller.state.workingDraft!.blueprint.definition.name,
      'Edited while publication was pending',
    );
    expect(container.read(editorNotifierProvider).project, same(manifest));
    expect(
      find.text(
        'Le résultat a été ignoré car le projet ou le blueprint a changé.',
      ),
      findsOneWidget,
    );
  });
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester,
  ProjectManifest manifest, {
  String projectRootPath = '/tmp/border-studio-project',
}) {
  return pumpEditorCanvasHostHarness(
    tester,
    initialState: EditorState(
      projectRootPath: projectRootPath,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.borderStudio,
      activeMap: null,
    ),
    surfaceSize: const Size(1280, 800),
  );
}

ProjectManifest _manifest({
  List<BorderBlueprintRecord> records = const <BorderBlueprintRecord>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return ProjectManifest(
    name: 'Border Studio UI',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: tilesets,
    elements: elements,
    borderCatalog: ProjectBorderCatalog(records: records),
  );
}

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
  BorderPrimitiveOrientation authoredOrientation =
      BorderPrimitiveOrientation.legacyAxis,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: 'element-$id',
    role: role,
    authoredOrientation: authoredOrientation,
    weight: 100,
    anchorPx: const BorderPixelPos(x: 4, y: 8),
    transforms: BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: const <int>[0],
    ),
    currentMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'fingerprint-$id',
      pixelSize: const GridSize(width: 16, height: 16),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
      defaultAnchorPx: const BorderPixelPos(x: 4, y: 8),
      occupancyMaskRle: '1:256',
    ),
  );
}

Future<ProviderContainer> _pumpControlledPublicationWorkspace(
  WidgetTester tester, {
  required ProjectManifest manifest,
  required BorderStudioPublicationCoordinator coordinator,
}) async {
  final container = ProviderContainer(
    overrides: <Override>[
      borderStudioPublicationCoordinatorProvider.overrideWithValue(
        coordinator,
      ),
    ],
  );
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    subscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  await tester.binding.setSurfaceSize(const Size(1280, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/projects/original',
    project: manifest,
    workspaceMode: EditorWorkspaceMode.borderStudio,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const CupertinoPageScaffold(
          child: BorderStudioWorkspace(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _prepareAndStartPublication(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.tap(
    find.byKey(
      const ValueKey<String>(
        'border-studio-step-Aperçu et publication',
      ),
    ),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('border-studio-prepare-preview')),
  );
  await tester.pumpAndSettle();
  final controller =
      container.read(borderStudioDraftControllerProvider.notifier);
  for (final warningCode in controller.state.warningCodes) {
    controller.acknowledgeWarningCode(warningCode);
  }
  await tester.pump();
  final publish = find.byKey(
    const ValueKey<String>('border-studio-publish'),
  );
  expect(
    tester.widget<PokeMapButton>(publish).onPressed,
    isNotNull,
    reason:
        'availability=${controller.state.publicationAvailability.disabledReason}; '
        'diagnostics=${controller.state.diagnostics.diagnostics.map((item) => item.code).toList()}; '
        'galleryNotPrepared=${find.byKey(const ValueKey<String>('border-studio-gallery-not-prepared')).evaluate().isNotEmpty}',
  );
  await tester.tap(publish);
  await tester.pump();
}

BorderStudioPublicationCoordinator _controlledCoordinator({
  required Completer<BorderPublicationResult> publishCompleter,
  required ValueChanged<BorderPublicationRequest> onPublishRequest,
}) {
  return BorderStudioPublicationCoordinator(
    prepareProjectElementAsset: ({
      required manifest,
      required projectRootPath,
      required sourceElementId,
      required primitiveId,
      required role,
      required weight,
      required transforms,
      anchorPx,
    }) async {
      final record = manifest.borderCatalog.recordById('coast')!;
      final primitive = record.draft.definition.primitives.singleWhere(
        (candidate) => candidate.id == primitiveId,
      );
      final preparation = _snapshotPreparation(primitive);
      return BorderPreparedProjectElementAsset(
        sourceElement: manifest.elements.singleWhere(
          (element) => element.id == sourceElementId,
        ),
        primitive: primitive,
        preparation: preparation,
      );
    },
    buildCandidate: const BorderPublicationCandidateBuilder().build,
    resolveCanonicalGallery: _passingGallery,
    publishRequest: (request) {
      onPublishRequest(request);
      return publishCompleter.future;
    },
  );
}

BorderStudioCanonicalGalleryResolution _passingGallery({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  required int resolverVersion,
}) {
  final definition = blueprintRevision.definition;
  final samples = <BorderPublicationGallerySample>[
    for (final galleryCase
        in borderCanonicalGalleryCasesForTemplate(definition.template))
      BorderPublicationGallerySample(
        galleryCase: galleryCase,
        coverageChecks: <BorderPublicationCoverageCheck>[
          for (final component in borderCanonicalCoverageComponentsForCase(
            template: definition.template,
            galleryCase: galleryCase,
          ))
            BorderPublicationCoverageCheck(
              component: component,
              longestContiguousGapPx: 0,
              maximumPairwiseOverlapPx: 0,
              gapTolerancePx: definition.defaults.gapTolerancePx,
              maxOverlapPx: definition.defaults.maxOverlapPx,
            ),
        ],
        structuralRuns: const <BorderPublicationStructuralRun>[],
      ),
  ];
  final report = BorderPublicationGalleryReport(
    resolverVersion: resolverVersion,
    canonicalGalleryVersion: borderCanonicalGalleryVersion,
    candidateFingerprint: computeBorderPublicationCandidateFingerprint(
      blueprintId: blueprintId,
      definition: definition,
      resolverVersion: resolverVersion,
    ),
    samples: samples,
  );
  final primitive = definition.primitives.single;
  return BorderStudioCanonicalGalleryResolution(
    report: report,
    cases: <BorderStudioCanonicalGalleryCasePreview>[
      for (var index = 0; index < samples.length; index += 1)
        BorderStudioCanonicalGalleryCasePreview(
          galleryCase: samples[index].galleryCase,
          mapSize: const GridSize(width: 1, height: 1),
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[true],
          ),
          resolution: _successfulResolution(
            primitiveId: primitive.id,
            snapshotId: primitive.visualSnapshotId,
            revision: blueprintRevision.revision,
          ),
          publicationSample: samples[index],
        ),
    ],
    resolutionDiagnostics: const BorderDiagnosticsReport.empty(),
  );
}

BorderResolutionResult _successfulResolution({
  required String primitiveId,
  required String snapshotId,
  required int revision,
}) {
  const fingerprint =
      'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
  final components = BorderInputFingerprints(
    blueprint: fingerprint,
    geometryAndSeed: fingerprint,
    parameters: fingerprint,
    overrides: fingerprint,
    keepOutRegions: fingerprint,
    mapContext: fingerprint,
    visualSnapshots: fingerprint,
  );
  return BorderResolutionResult(
    materialization: BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: borderResolverVersion,
        blueprintRevision: revision,
        components: components,
        inputFingerprint: fingerprint,
        outputFingerprint: fingerprint,
      ),
      ground: const <BorderResolvedGroundCell>[],
      placements: <BorderResolvedPlacement>[
        BorderResolvedPlacement(
          id: 'placement',
          slotKey: 'slot',
          primitiveId: primitiveId,
          visualSnapshotId: snapshotId,
          anchorCell: const GridPos(x: 0, y: 0),
          topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
          opaqueWorldBoundsPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: 1,
            height: 1,
          ),
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
          drawBand: BorderDrawBand.structure,
          stableOrderKey: BorderStableOrderKey(
            drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
            anchorRowMajor: 0,
            passIndex: 0,
            rank: 0,
            ordinalLocal: 0,
            slotKey: 'slot',
          ),
        ),
      ],
    ),
    diagnosticReport: const BorderDiagnosticsReport.empty(),
  );
}

ProjectManifest _publicationManifest() {
  final primitive = BorderPrimitiveDraft(
    id: 'rock',
    sourceElementId: 'element-rock',
    role: BorderPrimitiveRole.structureLarge,
    weight: 100,
    anchorPx: const BorderPixelPos(x: 1, y: 1),
    transforms: BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    ),
    currentMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'fingerprint-rock',
      pixelSize: const GridSize(width: 2, height: 2),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
      defaultAnchorPx: const BorderPixelPos(x: 1, y: 1),
      occupancyMaskRle: encodeBorderRleMask(
        const <bool>[true, true, true, true],
      ),
    ),
  );
  final record = BorderBlueprintRecord(
    id: 'coast',
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: 'Coast',
        previewSeed: BorderSignedInt64.fromInt(7),
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPrimitiveDraft>[primitive],
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
  );
  return _manifest(
    records: <BorderBlueprintRecord>[record],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tilesets/border.png',
      ),
    ],
    elements: const <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'element-rock',
        name: 'Rock',
        tilesetId: 'tileset',
        categoryId: 'border',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

BorderAssetSnapshotPreparation _snapshotPreparation(
  BorderPrimitiveDraft primitive,
) {
  const digit = 'a';
  final fingerprint = digit * 64;
  final relativePath = 'assets/borders/snapshots/$fingerprint/frame_0000.png';
  return BorderAssetSnapshotPreparation(
    sourceElementId: primitive.sourceElementId,
    snapshot: BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 100,
        ),
      ],
    ),
    metrics: primitive.currentMetrics,
    files: <BorderSnapshotFilePayload>[
      BorderSnapshotFilePayload(
        relativePath: relativePath,
        bytes: Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAEklEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
          ),
        ),
      ),
    ],
  );
}

BorderPublicationResult _publicationResult(ProjectManifest manifest) {
  return BorderPublicationResult(
    manifest: manifest,
    diagnostics: const BorderDiagnosticsReport.empty(),
    snapshotFinalize: BorderAssetSnapshotFinalizeResult(
      createdRelativePaths: const <String>[],
      deduplicatedRelativePaths: const <String>[],
    ),
  );
}
