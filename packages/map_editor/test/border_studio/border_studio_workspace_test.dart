import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
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
    expect(find.text('Structure principale'), findsNothing);
    expect(find.text('Publication après BORD-06'), findsOneWidget);
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
    expect(find.text('Longue portion'), findsOneWidget);
    expect(find.text('Petite boucle ou îlot'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('border-studio-save-draft')),
      findsOneWidget,
    );
    final publish = find.byKey(
      const ValueKey<String>('border-studio-publish'),
    );
    expect(publish, findsOneWidget);
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('border-studio-new-variation')),
    );
    await tester.pump();
    expect(controller.state.previewSeed, isNot(previousSeed));
  });

  testWidgets('line templates keep publication visibly disabled until BORD-06',
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

    expect(
      find.text(
        'La publication des murets et clôtures reste désactivée jusqu’au lot BORD-06.',
      ),
      findsOneWidget,
    );
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
    version: ProjectVersion.v2,
    maps: const <ProjectMapEntry>[],
    tilesets: tilesets,
    elements: elements,
    borderCatalog: ProjectBorderCatalog(records: records),
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: 'element-$id',
    role: role,
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
