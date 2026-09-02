import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_form_projection.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_path_pattern.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/stages/smart_tile_path_fill_stage.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/stages/smart_tile_path_pattern_stage.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_selectable_tile.dart';

void main() {
  testWidgets('path pattern stage exposes two visual presets and custom mode', (
    tester,
  ) async {
    SmartTilePathPatternId? selected;
    var customRequested = false;

    await tester.pumpWidget(
      _app(
        SmartTilePathPatternStage(
          selectedPatternId: null,
          onPatternSelected: (value) => selected = value,
          onUseCustomPattern: () => customRequested = true,
          onContinue: null,
        ),
      ),
    );

    expect(
      find.byKey(const Key('smart-tiles-path-pattern-classic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('smart-tiles-path-pattern-closedContour')),
      findsOneWidget,
    );
    expect(find.text('2 patrons disponibles'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('smart-tiles-path-pattern-closedContour')),
    );
    await tester.pump();
    expect(selected, SmartTilePathPatternId.closedContour);

    await tester.tap(find.byKey(const Key('smart-tiles-path-pattern-custom')));
    expect(customRequested, isTrue);
  });

  testWidgets(
    'closed contour fill keeps a 3 by 3 body and separate 2 by 2 corners',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pattern = smartTilePathPatternById(
        SmartTilePathPatternId.closedContour,
      );
      int? selectedMask;

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SmartTilePathFillStage(
              pattern: pattern,
              forms: <SmartTileFormReadModel>[
                for (final slot in pattern.slots)
                  SmartTileFormReadModel(
                    mask: slot.mask,
                    label: slot.label,
                    description: slot.label,
                    status: SmartTileVisibleFormStatus.covered,
                    candidates: pattern.slots.indexOf(slot) < 7
                        ? <SmartTileCandidate>[
                            SmartTileCandidate(id: 'candidate-${slot.mask}'),
                          ]
                        : const <SmartTileCandidate>[],
                  ),
              ],
              selectedMask: selectedMask,
              atlasWorkbench: const SizedBox(
                key: Key('path-source-atlas'),
                height: 220,
              ),
              automaticPreview: const SizedBox(
                key: Key('path-automatic-preview'),
                height: 220,
              ),
              slotPreviewBuilder: (mask) => SizedBox(
                key: Key('path-slot-preview-$mask'),
                width: 44,
                height: 44,
              ),
              onSlotSelected: (mask) => selectedMask = mask,
              onChangeImage: () {},
              onReset: () {},
              onContinue: null,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('smart-tiles-path-primary-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-path-corner-grid')),
        findsOneWidget,
      );
      expect(find.text('Coins'), findsOneWidget);
      expect(find.text('7 / 13 morceaux associés'), findsOneWidget);
      expect(find.byKey(const Key('path-source-atlas')), findsOneWidget);
      expect(find.byKey(const Key('path-automatic-preview')), findsOneWidget);
      expect(find.byType(PokeMapSelectableTile), findsNWidgets(13));

      final targetMask = pattern.cornerSlots.first.mask;
      await tester.tap(find.byKey(Key('smart-tiles-path-slot-$targetMask')));
      expect(selectedMask, targetMask);
    },
  );

  testWidgets('automatic preview stays calm until the first piece is mapped', (
    tester,
  ) async {
    final pattern = smartTilePathPatternById(
      SmartTilePathPatternId.closedContour,
    );

    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox.square(
            dimension: 420,
            child: SmartTilePathAutomaticPreview(
              pattern: pattern,
              mappedMasks: const <int>{},
              slotPreviewBuilder: (_) => const ColoredBox(
                key: Key('mapped-preview-cell'),
                color: Colors.green,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Associez un premier morceau'), findsOneWidget);
    expect(find.byKey(const Key('mapped-preview-cell')), findsNothing);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.dark(),
  home: Scaffold(body: child),
);
