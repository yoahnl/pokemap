import 'package:avelune_studio/presentation/features/scenes/scene_battle_demonstration_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('demonstration authoring uses named team and item pickers', (tester) async {
    SceneBattleDemonstration? value;
    final project = ProjectManifest(name: 'Demo', maps: [], tilesets: [],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      trainers: const [ProjectTrainerEntry(id: 'guide', name: 'Guide de capture', trainerClass: 'Guide',
        team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)])]);
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: SingleChildScrollView(
      child: StatefulBuilder(builder: (context, setState) => SceneBattleDemonstrationForm(
        project: project, value: value,
        loadItems: () async => {'poke-ball': 'Poké Ball'},
        onChanged: (next) => setState(() => value = next),
      )),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Démonstration automatique'), findsOneWidget);
    await tester.tap(find.byType(StudioToggleRow).first);
    await tester.pumpAndSettle();
    expect(value?.playerTrainerId, 'guide');
    expect(value?.bagItems.single.itemId, 'poke-ball');
    expect(find.text('Guide de capture'), findsOneWidget);
    expect(find.text('Poké Ball'), findsWidgets);
    expect(find.textContaining('JSON'), findsNothing);
    await tester.tap(find.byType(StudioToggleRow).first);
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing project teams and items cannot create broken demonstrations', (tester) async {
    var changed = false;
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: SceneBattleDemonstrationForm(
      project: ProjectManifest(name: 'Empty', maps: [], tilesets: []), value: null,
      loadItems: () async => {}, onChanged: (_) => changed = true,
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudioToggleRow));
    await tester.pumpAndSettle();
    expect(changed, false);
    expect(find.textContaining('équipe solo'), findsOneWidget);
  });
}
