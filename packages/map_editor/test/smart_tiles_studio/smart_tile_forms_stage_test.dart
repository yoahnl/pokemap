import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_form_projection.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/stages/smart_tile_forms_stage.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

void main() {
  testWidgets(
      'an ambiguous form blocks the bench and opens its correction context',
      (tester) async {
    int? selectedMask;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: SmartTileFormsStage(
                usage: SmartTileUsage.terrain,
                topology: SmartTileTopology.uniform,
                forms: <SmartTileFormReadModel>[
                  SmartTileFormReadModel(
                    mask: 0,
                    label: 'Surface continue',
                    description: 'La même matière occupe toute la cellule.',
                    status: SmartTileVisibleFormStatus.ambiguous,
                    candidates: const <SmartTileCandidate>[
                      SmartTileCandidate(id: 'first'),
                      SmartTileCandidate(id: 'second'),
                    ],
                  ),
                ],
                selectedMask: selectedMask,
                pendingAtlasFrame: null,
                selectedChannel: SmartTileRenderChannel.ground,
                animations: const <ProjectSmartTileAnimation>[],
                atlasWorkbench: const SizedBox(
                  key: Key('smart-tiles-contextual-atlas'),
                  height: 120,
                ),
                onFormSelected: (mask) => setState(() => selectedMask = mask),
                onClearPendingFrame: () {},
                onChannelSelected: (_) {},
                onAnimationSelected: (_, __) {},
                onWeightChanged: (_, __, ___) {},
                onMoveVariant: (_, __, ___) {},
                onRemoveVariant: (_, __) {},
                onContinue: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 ambiguës'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const Key('smart-tiles-mapping-next-step')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('smart-tiles-form-0')));
    await tester.pump();

    expect(selectedMask, 0);
    expect(find.text('Source pour « Surface continue »'), findsOneWidget);
    expect(
      find.byKey(const Key('smart-tiles-contextual-atlas')),
      findsOneWidget,
    );
  });
}
