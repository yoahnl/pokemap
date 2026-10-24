import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/new_game/party_companion_configuration_sheet.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('companion visual uses catalog labels and saves typed mapping', (
    tester,
  ) async {
    ProjectPartyCompanionConfig? saved;
    final actor = ProjectCharacterEntry(
      id: 'guide',
      name: 'Petit compagnon',
      tilesetId: 'sheet',
      animations: [
        for (final facing in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: facing,
            frames: const [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PartyCompanionConfigurationForm(
            project: ProjectManifest(
              name: 'Test',
              maps: [],
              tilesets: [],
              characters: [actor],
            ),
            species: const [
              SceneConsequenceCatalogOption(
                id: 'clockbird',
                label: 'Oiseau horloge',
                primaryFormId: 'bronze',
                formIds: ['bronze'],
              ),
            ],
            onSave: (config) async {
              saved = config;
              return true;
            },
          ),
        ),
      ),
    );
    tester
        .widget<PokeMapToggleTile>(
          find.byKey(const Key('party-companion-enabled')),
        )
        .onChanged(true);
    await tester.pump();
    tester
        .widget<PokeMapDropdownField<String>>(
          find.byKey(const Key('party-companion-clockbird-bronze')),
        )
        .onChanged('guide');
    await tester.pump();
    await tester.tap(find.byKey(const Key('party-companion-save')));
    await tester.pumpAndSettle();
    expect(saved!.enabled, isTrue);
    expect(saved!.mappings.single.characterId, 'guide');
    expect(saved!.mappings.single.speciesId, 'clockbird');
    expect(saved!.mappings.single.formId, 'bronze');
    expect(find.text('Oiseau horloge'), findsOneWidget);
  });
}
