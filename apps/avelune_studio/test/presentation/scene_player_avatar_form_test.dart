import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'avatar action reopens by label and preserves exact payload metadata',
    (tester) async {
      final current = SceneActionPayload.consequence(
        SceneConsequence.setPlayerAvatar(
          characterId: 'costume',
          label: 'Costume de scène',
          notes: 'Restaurer après la cérémonie',
        ),
        actionKind: 'custom-label',
        parameters: const {'annotation': 'keep'},
      );
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: current, applied: applied);

      final picker = tester.widget<StudioSelect>(_avatarPicker);
      expect(picker.value, 'costume');
      expect(picker.options, {
        'hero': 'Tenue de voyage',
        'costume': 'Tenue de soirée',
      });
      expect(find.text('Tenue de soirée'), findsOneWidget);
      expect(picker.onChanged, isNotNull);
      expect(_apply(tester).onPressed, isNotNull);
      expect(applied, isEmpty);

      await tester.tap(find.text('Appliquer l’action'));
      expect(applied.single, current);
      await _pickAvatar(tester, 'Tenue de voyage');
      await tester.tap(find.text('Appliquer l’action'));
      final changed = applied.last as SceneActionPayload;
      expect(changed.actionKind, current.actionKind);
      expect(changed.parameters, current.parameters);
      expect(
        changed.consequence,
        SceneConsequence.setPlayerAvatar(
          characterId: 'hero',
          label: 'Costume de scène',
          notes: 'Restaurer après la cérémonie',
        ),
      );
    },
  );

  testWidgets('new avatar action guides selection from character labels', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await _pump(tester, applied: applied);
    final commands = tester.widget<StudioSelect>(_picker('Commande'));
    expect(
      commands.options[NarrativeCommandIds.setPlayerAvatar],
      'Changer l’avatar du joueur',
    );
    commands.onChanged!(NarrativeCommandIds.setPlayerAvatar);
    await tester.pump();

    expect(_apply(tester).onPressed, isNull);
    expect(find.byType(TextField), findsNothing);
    await _pickAvatar(tester, 'Tenue de soirée');
    expect(applied, isEmpty);
    expect(_apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Ajouter l’action'));
    final payload = applied.single as SceneActionPayload;
    expect(
      payload.consequence,
      SceneConsequence.setPlayerAvatar(characterId: 'costume'),
    );
  });

  testWidgets(
    'avatar options exclude ambiguous characters and invalid animation definitions',
    (tester) async {
      final project = _project();
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _payload('hero'),
        applied: applied,
        project: project.copyWith(
          characters: [
            ...project.characters,
            _character('duplicate', 'Doublon A'),
            _character('duplicate', 'Doublon B'),
            const ProjectCharacterEntry(
              id: 'missing_walk',
              name: 'Sans marche',
              tilesetId: 'unused',
            ),
            _character(
              'invalid_frame',
              'Cadre invalide',
            ).copyWith(frameWidth: 0),
          ],
        ),
      );

      final picker = tester.widget<StudioSelect>(_avatarPicker);
      expect(picker.options, {
        'hero': 'Tenue de voyage',
        'costume': 'Tenue de soirée',
      });
      expect(picker.options.keys, isNot(contains('missing')));
      expect(_apply(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'missing avatar stays recorded until the author explicitly repairs it',
    (tester) async {
      final applied = <SceneNodePayload>[];
      final current = _payload('missing');
      await _pump(tester, current: current, applied: applied);

      expect(tester.widget<StudioSelect>(_avatarPicker).value, 'missing');
      expect(find.text('Référence introuvable : missing'), findsOneWidget);
      expect(_apply(tester).onPressed, isNull);
      expect(applied, isEmpty);
      await _pump(
        tester,
        current: current,
        applied: applied,
        project: _project().copyWith(name: 'Renamed project'),
      );
      expect(tester.widget<StudioSelect>(_avatarPicker).value, 'missing');
      expect(_apply(tester).onPressed, isNull);

      await _pickAvatar(tester, 'Tenue de voyage');
      expect(applied, isEmpty);
      expect(_apply(tester).onPressed, isNotNull);
      await tester.tap(find.text('Appliquer l’action'));
      expect(
        (applied.single as SceneActionPayload).consequence,
        SceneConsequence.setPlayerAvatar(characterId: 'hero'),
      );
      expect(
        current.consequence,
        SceneConsequence.setPlayerAvatar(characterId: 'missing'),
      );
    },
  );

  testWidgets('catalog changes never reset an existing avatar selection', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    final current = _payload('costume');
    final project = _project();
    await _pump(tester, current: current, applied: applied, project: project);
    expect(_apply(tester).onPressed, isNotNull);

    await _pump(
      tester,
      current: current,
      applied: applied,
      project: project.copyWith(characters: [project.characters.first]),
    );
    expect(tester.widget<StudioSelect>(_avatarPicker).value, 'costume');
    expect(_apply(tester).onPressed, isNull);
    expect(applied, isEmpty);

    await _pump(tester, current: current, applied: applied, project: project);
    expect(tester.widget<StudioSelect>(_avatarPicker).value, 'costume');
    expect(_apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, current);
  });
}

Finder _picker(String label) => find.byWidgetPredicate(
  (widget) => widget is StudioSelect && widget.label == label,
);

Finder get _avatarPicker => _picker('Avatar / costume');

StudioButton _apply(WidgetTester tester) => tester.widget<StudioButton>(
  find.byWidgetPredicate(
    (widget) =>
        widget is StudioButton &&
        (widget.label == 'Appliquer l’action' ||
            widget.label == 'Ajouter l’action'),
  ),
);

Future<void> _pickAvatar(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: _avatarPicker,
      matching: find.byType(DropdownButtonFormField<String>),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required List<SceneNodePayload> applied,
  SceneNodePayload? current,
  ProjectManifest? project,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 500,
          child: SceneActionForm(
            project: project ?? _project(),
            current: current,
            onApply: applied.add,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _project() => ProjectManifest(
  name: 'Avatar authoring',
  maps: const [],
  tilesets: const [],
  characters: [
    _character('hero', 'Tenue de voyage'),
    _character('costume', 'Tenue de soirée'),
  ],
);

SceneActionPayload _payload(String id) => SceneActionPayload.consequence(
  SceneConsequence.setPlayerAvatar(characterId: id),
);

ProjectCharacterEntry _character(String id, String name) =>
    ProjectCharacterEntry(
      id: id,
      name: name,
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            sourceAssetId: id,
            frames: [
              CharacterAnimationFrame(
                source: const TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 32,
                  height: 32,
                ),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
