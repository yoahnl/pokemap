import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

SceneActionPayload _payload(String mapId) => SceneActionPayload.interactive(
  SceneInteractiveCommand.fromJson({'kind': 'waitForActorRoutes', 'mapId': mapId}),
  actionKind: 'author-label', parameters: const {'annotation': 'keep'});
const _maps = [ProjectMapEntry(id: 'port', name: 'Port', relativePath: 'maps/port.json'),
  ProjectMapEntry(id: 'forest', name: 'Bois', relativePath: 'maps/forest.json')];
ProjectManifest _project() => const ProjectManifest(name: 'Barrier', maps: _maps, tilesets: []);
void main() {
  Future<void> pump(WidgetTester tester, ProjectManifest project, SceneActionPayload current,
    ValueChanged<SceneNodePayload> onApply) async {
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: SizedBox(width: 420,
      child: SceneActionForm(project: project, current: current, onApply: onApply)))));
    await tester.pumpAndSettle();
  }
  StudioButton apply(WidgetTester tester) => tester.widget<StudioButton>(find.byWidgetPredicate((w) => w is StudioButton && w.label == 'Appliquer l’action'));
  testWidgets('guided route wait chooses an exact native map and preserves authored metadata', (tester) async {
    final original = _payload('port');
    final applied = <SceneNodePayload>[];
    await pump(tester, _project(), original, applied.add);
    expect(find.text('Attendre les déplacements'), findsOneWidget);
    expect(apply(tester).onPressed, isNotNull);
    final picker = find.descendant(of: find.byWidgetPredicate((w) => w is StudioSelect && w.label == 'Carte'), matching: find.byType(DropdownButtonFormField<String>));
    await tester.tap(picker); await tester.pumpAndSettle();
    await tester.tap(find.text('Bois').last); await tester.pumpAndSettle();
    expect(applied, isEmpty);
    await tester.tap(find.text('Appliquer l’action'));
    final result = applied.single as SceneActionPayload;
    expect(result.interactiveCommand!.toJson(), {'kind': 'waitForActorRoutes', 'mapId': 'forest'});
    expect(result.parameters, original.parameters); expect(result.actionKind, original.actionKind);
    expect(original.interactiveCommand!.toJson()['mapId'], 'port');
  });
  testWidgets('route wait rejects deleted or ambiguous map references in the guide', (tester) async {
    for (final project in [_project().copyWith(maps: []), _project().copyWith(maps: [..._maps, _maps.first])]) {
      await pump(tester, project, _payload('port'), (_) => fail('Invalid barrier must not apply'));
      expect(apply(tester).onPressed, isNull);
    }
  });
  testWidgets('route wait has no 3D guided consumer and keeps its unsupported draft', (tester) async {
    final original = _payload('port');
    await pump(tester, _project().copyWith(settings: const ProjectSettings(dimension: ProjectDimension.threeD)), original,
      (_) => fail('3D barrier must not apply'));
    expect(find.text('Attendre les déplacements'), findsNothing);
    expect(apply(tester).onPressed, isNull);
    expect(original.interactiveCommand!.toJson(), {'kind': 'waitForActorRoutes', 'mapId': 'port'});
  });
}
