import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft_controller.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_assets_step.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_rules_step.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_studio_presentation.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_type_step.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  test('an empty ledge draft starts with fixed whole-cell rules', () {
    final controller = _controller();
    controller.createBlueprint(id: 'ledge', name: 'Rebord', template: BorderBlueprintTemplate.ledgeLine);
    _expectFixedRules(controller.state.workingDraft!.blueprint.definition.defaults);
    expect(controller.state.allowedPrimitiveRoles, {BorderPrimitiveRole.structureLarge});
  });

  test('switching an existing native module to ledge clears incompatible rules', () {
    final controller = _controller();
    controller.createBlueprint(id: 'ledge', name: 'Rebord', template: BorderBlueprintTemplate.organicEdge);
    controller.replacePrimitives(_state().workingDraft!.blueprint.definition.primitives);
    controller.setGenerationParams(BorderGenerationParams(irregularityPermille: 250,
        detailDensityPermille: 500, variationPermille: 300, maxOverlapPx: 4,
        gapTolerancePx: 1, depthRows: 2, allowAutoRotation: true));
    controller.setTemplate(BorderBlueprintTemplate.ledgeLine);
    _expectFixedRules(controller.state.workingDraft!.blueprint.definition.defaults);
  });

  test('ledge presentation requires only the whole native module role', () {
    expect(borderTemplateLabel(BorderBlueprintTemplate.ledgeLine), 'Rebord');
    expect(
      isRequiredBorderRole(
        BorderBlueprintTemplate.ledgeLine,
        BorderPrimitiveRole.structureLarge,
      ),
      isTrue,
    );
    expect(
      isRequiredBorderRole(
        BorderBlueprintTemplate.ledgeLine,
        BorderPrimitiveRole.lineCap,
      ),
      isFalse,
    );
    expect(
      unresolvedBorderRoleLabels(_state().workingDraft!.blueprint.definition),
      isEmpty,
    );
  });

  testWidgets('the template picker exposes an explicit Rebord selection', (
    tester,
  ) async {
    final selected = <BorderBlueprintTemplate>[];
    await _pump(
      tester,
      BorderTypeStep(state: _state(), onTemplateSelected: selected.add),
    );
    final button = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey<String>('border-studio-template-ledge-line')),
    );
    expect(find.text('Rebord'), findsOneWidget);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(selected, [BorderBlueprintTemplate.ledgeLine]);
  });

  testWidgets(
    'ledge rules keep the carrier fixed and expose only compatible variety',
    (tester) async {
      final outputs = <BorderGenerationParams>[];
      await _pump(
        tester,
        BorderRulesStep(state: _state(), onRulesChanged: outputs.add),
      );
      expect(
        find.byKey(
          const ValueKey<String>('border-studio-auto-rotation-toggle'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('border-studio-regularity-control')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('border-studio-details-control')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'border-studio-connected-line-overlap-control',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('border-studio-connected-line-gap-control'),
        ),
        findsNothing,
      );
      for (final key in [
        'border-studio-profile-strict',
        'border-studio-profile-wild',
      ]) {
        tester
            .widget<PokeMapButton>(find.byKey(ValueKey<String>(key)))
            .onPressed!();
      }
      tester
          .widget<PokeMapGuidedSlider>(
            find.byKey(const ValueKey<String>('border-studio-variety-control')),
          )
          .onChanged(70);
      expect(outputs, hasLength(3));
      expect(outputs.map((rules) => rules.variationPermille), [0, 1000, 700]);
      for (final rules in outputs) {
        expect(rules.irregularityPermille, 0);
        expect(rules.detailDensityPermille, 0);
        expect(rules.maxOverlapPx, 0);
        expect(rules.gapTolerancePx, 0);
        expect(rules.depthRows, 1);
        expect(rules.allowAutoRotation, isFalse);
      }
    },
  );

  testWidgets('ledge visual spacing is explicit and survives variety changes', (
    tester,
  ) async {
    final outputs = <BorderGenerationParams>[];
    await _pump(
      tester,
      BorderRulesStep(state: _state(), onRulesChanged: outputs.add),
    );
    final slider = tester.widget<PokeMapGuidedSlider>(
      find.byKey(const ValueKey<String>('border-studio-ledge-gap-control')),
    );
    expect(slider.max, 31);
    slider.onChanged(8);
    expect(outputs.single.gapTolerancePx, 8);
    expect(outputs.single.maxOverlapPx, 0);
    expect(outputs.single.depthRows, 1);
    expect(outputs.single.allowAutoRotation, isFalse);
    final source = _state();
    final definition = source.workingDraft!.blueprint.definition;
    final updated = _state(gap: outputs.single.gapTolerancePx);
    await _pump(
      tester,
      BorderRulesStep(state: updated, onRulesChanged: outputs.add),
    );
    tester
        .widget<PokeMapButton>(
          find.byKey(const ValueKey<String>('border-studio-profile-wild')),
        )
        .onPressed!();
    expect(outputs.last.gapTolerancePx, 8);
    expect(outputs.last.variationPermille, 1000);
    expect(definition.defaults.gapTolerancePx, 0);
  });

  testWidgets(
    'ledge assets expose native cardinal orientations without rotation or historical mode',
    (tester) async {
      final changes = <(String, BorderPrimitiveOrientation)>[];
      await _pump(
        tester,
        BorderAssetsStep(
          state: _state(),
          manifest: const ProjectManifest(
            name: 'Rebord',
            maps: [],
            tilesets: [],
          ),
          selectedSourceElementId: null,
          onSourceElementSelected: (_) {},
          onAnalyzeSelected: () async {},
          onReanalyzePrimitive: (_) async {},
          onRemovePrimitive: (_) {},
          onRealignConnectedLineAnchors: () {},
          onAuthoredOrientationChanged: (id, orientation) =>
              changes.add((id, orientation)),
          previewBytesByPrimitiveId: const <String, Uint8List>{},
        ),
      );
      final picker = tester
          .widget<PokeMapDropdownField<BorderPrimitiveOrientation>>(
            find.byKey(
              const ValueKey<String>(
                'border-studio-authored-orientation-picker-module',
              ),
            ),
          );
      expect(picker.items.map((item) => item.value), [
        BorderPrimitiveOrientation.north,
        BorderPrimitiveOrientation.east,
        BorderPrimitiveOrientation.south,
        BorderPrimitiveOrientation.west,
      ]);
      picker.onChanged(BorderPrimitiveOrientation.east);
      expect(changes, [('module', BorderPrimitiveOrientation.east)]);
      expect(find.text('Point de raccord'), findsNothing);
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: PokeMapTheme.dark(),
    home: Scaffold(body: child),
  ),
);

BorderStudioDraftState _state({int gap = 0}) => BorderStudioDraftState(
  selectedBlueprintId: 'ledge',
  workingDraft: BorderStudioDraft(
    id: 'ledge',
    blueprint: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: 'Rebord',
        previewSeed: BorderSignedInt64.fromInt(1),
        template: BorderBlueprintTemplate.ledgeLine,
        primitives: [
          BorderPrimitiveDraft(
            id: 'module',
            sourceElementId: 'module-source',
            role: BorderPrimitiveRole.structureLarge,
            authoredOrientation: BorderPrimitiveOrientation.south,
            weight: 1000,
            anchorPx: const BorderPixelPos(x: 16, y: 31),
            transforms: BorderTransformPolicy(
              allowFlipX: false,
              allowedQuarterTurns: const [0],
            ),
            currentMetrics: BorderPrimitiveAssetMetrics(
              assetFingerprint: 'module',
              pixelSize: const GridSize(width: 32, height: 32),
              opaqueBounds: BorderPixelRect(x: 0, y: 16, width: 32, height: 16),
              defaultAnchorPx: const BorderPixelPos(x: 16, y: 31),
              occupancyMaskRle: '0:512,1:512',
            ),
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: gap,
          depthRows: 1,
          allowAutoRotation: false,
        ),
        sortOrder: 0,
      ),
    ),
  ),
);

BorderStudioDraftController _controller() {
  final provider = NotifierProvider<BorderStudioDraftController, BorderStudioDraftState>(BorderStudioDraftController.new);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(provider.notifier)
    ..loadFromManifest(const ProjectManifest(name: 'Rebord', maps: [], tilesets: []));
}

void _expectFixedRules(BorderGenerationParams rules) {
  expect(rules.irregularityPermille, 0);
  expect(rules.detailDensityPermille, 0);
  expect(rules.maxOverlapPx, 0);
  expect(rules.gapTolerancePx, 0);
  expect(rules.depthRows, 1);
  expect(rules.allowAutoRotation, isFalse);
}
