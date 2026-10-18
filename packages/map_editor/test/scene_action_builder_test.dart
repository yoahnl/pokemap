import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('interactive native gift keeps guided policies when reopened and rejects invalid bounds', (tester) async {
    final gift = SceneInteractiveCommand.receivePokemonFromCatalog(speciesId: 'bird', formId: 'bronze', level: 17,
      moveIds: ['exceptional', 'tackle'],
      nicknamePolicy: ScenePokemonGiftNicknamePolicy.disabled, nicknameMaxGraphemes: 10,
      pokedexPresentationPolicy: ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible);
    SceneNodePayload? submitted;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.receivePokemonFromCatalog,
      initialPayload: SceneActionPayload.interactive(gift), onSubmit: (p) => submitted = p,
      options: {
        NarrativeCommandParameterKind.species: const [SceneActionPickerOption(id: 'bird', label: 'Bird'), SceneActionPickerOption(id: 'invalid', label: 'Unresolved')],
        NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([
          const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: 'bronze', formIds: ['sunny', 'bronze']),
        ]),
      });
    expect(_picker(tester, 'Espèce').items.map((item) => item.value), ['bird']);
    expect(_picker(tester, 'Forme').items.map((item) => item.value), ['bronze']);
    expect(_picker(tester, 'Proposer un surnom').value, 'disabled');
    expect(_picker(tester, 'Présenter le Pokédex').value, 'whenNewAndPokedexVisible');
    expect(find.byKey(const ValueKey('scene-gift-move-mode')), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
    await tester.ensureVisible(find.byKey(const ValueKey('scene-action-submit')));
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    expect((submitted as SceneActionPayload).interactiveCommand, gift);
    for (final field in ['level', 'nicknameMaxGraphemes']) {
      final input = find.byKey(ValueKey('scene-action-parameter-$field'));
      for (final value in ['0', '101', '1.5']) {
        await tester.enterText(input, value);
        await tester.pump();
        expect(_submitButton(tester).onPressed, isNull, reason: '$field=$value');
      }
      await tester.enterText(input, field == 'level' ? '17' : '10');
      await tester.pump();
    }
    expect(_submitButton(tester).onPressed, isNotNull);
  });

  for (final command in [NarrativeCommandIds.givePokemonFromCatalog, NarrativeCommandIds.receivePokemonFromCatalog]) {
    testWidgets('$command guides ordered exceptional moves and automatic reset', (tester) async {
      SceneNodePayload? submitted;
      await _pumpBuilder(tester, initialCommandId: command,
        initialParameters: const {'speciesId': 'bird', 'formId': 'base', 'level': '8', 'moveIds': '["exceptional","tackle"]'},
        options: {NarrativeCommandParameterKind.species: const [SceneActionPickerOption(id: 'bird', label: 'Bird')],
          NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: 'base', formIds: ['base'])])},
        onSubmit: (value) => submitted = value);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scene-action-parameter-moveIds')), findsNothing);
      final first = tester.widget<PokeMapDropdownField<String>>(find.byKey(const ValueKey('scene-gift-move-0')));
      expect(first.value, 'exceptional');
      expect(first.items.map((item) => item.value), isNot(contains('tackle')));
      await tester.ensureVisible(find.byKey(const ValueKey('scene-gift-move-down-0')));
      await tester.tap(find.byKey(const ValueKey('scene-gift-move-down-0')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('scene-action-submit')));
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      var payload = submitted! as SceneActionPayload;
      expect((payload.consequence?.toJson() ?? payload.interactiveCommand!.toJson())['moveIds'], ['tackle', 'exceptional']);
      for (final move in ['surf', 'fly']) {
        tester.widget<PokeMapButton>(find.byKey(const ValueKey('scene-gift-move-add'))).onPressed!();
        await tester.pump();
        expect(_submitButton(tester).onPressed, isNull);
        final index = move == 'surf' ? 2 : 3;
        tester.widget<PokeMapDropdownField<String>>(find.byKey(ValueKey('scene-gift-move-$index'))).onChanged(move);
        await tester.pump();
      }
      expect(tester.widget<PokeMapButton>(find.byKey(const ValueKey('scene-gift-move-add'))).onPressed, isNull);
      tester.widget<PokeMapButton>(find.byKey(const ValueKey('scene-gift-move-remove-1'))).onPressed!();
      await tester.pump();
      tester.widget<PokeMapDropdownField<String>>(find.byKey(const ValueKey('scene-gift-move-mode'))).onChanged('automatic');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('scene-action-submit')));
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      payload = submitted! as SceneActionPayload;
      expect((payload.consequence?.toJson() ?? payload.interactiveCommand!.toJson()).containsKey('moveIds'), isFalse);
    });
  }

  testWidgets('lost gift moves stay visible until explicitly repaired', (tester) async {
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.givePokemonFromCatalog,
      initialParameters: const {'speciesId': 'bird', 'formId': 'base', 'level': '8', 'moveIds': '["removed","tackle"]'},
      options: {NarrativeCommandParameterKind.species: const [SceneActionPickerOption(id: 'bird', label: 'Bird')],
        NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: 'base', formIds: ['base'])])});
    await tester.pumpAndSettle();
    expect(_submitButton(tester).onPressed, isNull);
    final picker = tester.widget<PokeMapDropdownField<String>>(find.byKey(const ValueKey('scene-gift-move-0')));
    expect(picker.value, 'removed');
    expect(picker.items.singleWhere((item) => item.value == 'removed').label, contains('introuvable'));
    picker.onChanged('surf');
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('gift move catalogue rejects a late response after project replacement', (tester) async {
    final pending = Completer<Map<String, String>>();
    const parameters = {'speciesId': 'bird', 'formId': 'base', 'level': '8', 'moveIds': '["tackle"]'};
    final options = {NarrativeCommandParameterKind.species: const [SceneActionPickerOption(id: 'bird', label: 'Bird')],
      NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: 'base', formIds: ['base'])])};
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.givePokemonFromCatalog, initialParameters: parameters, options: options, loadMoves: () => pending.future);
    expect(_submitButton(tester).onPressed, isNull);
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.givePokemonFromCatalog, initialParameters: parameters, options: options, loadMoves: () async => {'surf': 'Surf'});
    await tester.pumpAndSettle();
    pending.complete({'tackle': 'Ancien projet'});
    await tester.pumpAndSettle();
    expect(_submitButton(tester).onPressed, isNull);
    final picker = tester.widget<PokeMapDropdownField<String>>(find.byKey(const ValueKey('scene-gift-move-0')));
    expect(picker.value, 'tackle');
    expect(picker.items.singleWhere((item) => item.value == 'tackle').label, contains('introuvable'));
    expect(tester.takeException(), isNull);
  });

  for (final primaryFormId in ['base', 'bronze']) {
  testWidgets('catalog gift builder offers only the resolved primary form $primaryFormId', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester,
      initialCommandId: NarrativeCommandIds.givePokemonFromCatalog,
      initialParameters: {'speciesId': 'bird', 'formId': primaryFormId, 'level': '5'},
      onSubmit: (payload) => submitted = payload,
      options: {
        NarrativeCommandParameterKind.species: [const SceneActionPickerOption(id: 'bird', label: 'Bird')],
        NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([
          SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: primaryFormId, formIds: ['sunny', primaryFormId]),
        ]),
      },
    );
    final form = tester.widget<PokeMapDropdownField<String>>(find.byWidgetPredicate((widget) => widget is PokeMapDropdownField<String> && widget.label == 'Forme'));
    expect(form.items.map((item) => item.value), [primaryFormId]);
    expect(_submitButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    expect((submitted as SceneActionPayload).consequence, SceneConsequence.givePokemonFromCatalog(speciesId: 'bird', formId: primaryFormId, level: 5));
  });
  }

  testWidgets('catalog gift builder refuses forms without resolved primary metadata', (tester) async {
    await _pumpBuilder(tester,
      initialCommandId: NarrativeCommandIds.givePokemonFromCatalog,
      initialParameters: const {'speciesId': 'bird', 'formId': 'base', 'level': '5'},
      onSubmit: (_) => fail('Unresolved primary form must not submit'),
      options: {
        NarrativeCommandParameterKind.species: [const SceneActionPickerOption(id: 'bird', label: 'Bird')],
        NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([
          const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', formIds: ['base']),
        ]),
      },
    );
    expect(_submitButton(tester).onPressed, isNull);
    expect(find.byWidgetPredicate((widget) => widget is PokeMapDropdownField<String> && widget.label == 'Forme'), findsNothing);
  });

  testWidgets('catalog gift builder repairs an unsupported initial form through its primary picker', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester,
      initialCommandId: NarrativeCommandIds.givePokemonFromCatalog,
      initialParameters: const {'speciesId': 'bird', 'formId': 'sunny', 'level': '5'},
      onSubmit: (payload) => submitted = payload,
      options: {
        NarrativeCommandParameterKind.species: [const SceneActionPickerOption(id: 'bird', label: 'Bird')],
        NarrativeCommandParameterKind.speciesForm: buildScenePokemonFormPickerOptions([
          const SceneConsequenceCatalogOption(id: 'bird', label: 'Bird', primaryFormId: 'bronze', formIds: ['sunny', 'bronze']),
        ]),
      },
    );
    expect(_submitButton(tester).onPressed, isNull);
    final form = tester.widget<PokeMapDropdownField<String>>(find.byWidgetPredicate((widget) => widget is PokeMapDropdownField<String> && widget.label == 'Forme'));
    expect(form.items.map((item) => item.value), ['', 'bronze']);
    form.onChanged('bronze');
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    expect((submitted as SceneActionPayload).consequence, SceneConsequence.givePokemonFromCatalog(speciesId: 'bird', formId: 'bronze', level: 5));
  });

  testWidgets('route wait uses a native map picker and submits only its exact reference', (tester) async {
    SceneNodePayload? submitted;
    const project = ProjectManifest(name: 'Barrier', maps: [ProjectMapEntry(id: 'port', name: 'Port', relativePath: 'maps/port.json')], tilesets: []);
    await _pumpBuilder(tester, initialCommandId: 'waitForActorRoutes', project: project,
      initialParameters: const {'mapId': 'port'}, onSubmit: (p) => submitted = p);
    expect(find.text('Attendre les déplacements'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    expect((submitted as SceneActionPayload).interactiveCommand!.toJson(), {'kind': 'waitForActorRoutes', 'mapId': 'port'});
  });
  testWidgets('route wait guide refuses 3D and forged or ambiguous map options', (tester) async {
    const entry = ProjectMapEntry(id: 'port', name: 'Port', relativePath: 'maps/port.json');
    for (final project in [
      const ProjectManifest(name: 'Absent', maps: [], tilesets: []),
      const ProjectManifest(name: 'Ambiguous', maps: [entry, entry], tilesets: []),
      const ProjectManifest(name: '3D', settings: ProjectSettings(dimension: ProjectDimension.threeD), maps: [entry], tilesets: []),
    ]) {
      await _pumpBuilder(tester, initialCommandId: 'waitForActorRoutes', project: project,
        initialParameters: const {'mapId': 'port'}, options: const {NarrativeCommandParameterKind.map: [SceneActionPickerOption(id: 'port', label: 'Forged')]},
        onSubmit: (_) => fail('Invalid barrier must not submit'));
      expect(_submitButton(tester).onPressed, isNull);
    }
  });
  testWidgets('3D and missing contexts preserve but cannot apply 2D presentation drafts', (tester) async {
    for (final project in <ProjectManifest?>[null,
      const ProjectManifest(name: '3D', maps: [], tilesets: [],
        settings: ProjectSettings(dimension: ProjectDimension.threeD))]) {
      for (final command in [
        SceneInteractiveCommand.wait(durationMs: 400),
        SceneInteractiveCommand.worldTone(red: -255, green: 0, blue: 0, gray: 0, durationMs: 300),
        SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: .8),
      ]) {
        await _pumpBuilder(tester, initialCommandId: command.kind.name,
          project: project, options: _soundOptions,
          initialPayload: SceneActionPayload.interactive(command),
          onSubmit: (_) => fail('Presentation requires a known 2D project'));
        final picker = tester.widget<PokeMapDropdownField<String>>(
          find.byWidgetPredicate((w) => w is PokeMapDropdownField<String> && w.label == 'Type de commande'));
        for (final id in ['wait', 'worldTone', 'playSoundEffect']) {
          expect(picker.items.any((item) => item.value == id), isFalse, reason: id);
        }
        expect(_submitButton(tester).onPressed, isNull);
        final parameter = command is ScenePlaySoundEffectInteractiveCommand ? 'volume' : 'durationMs';
        final expected = command.toJson()[parameter].toString();
        final input = find.byKey(ValueKey('scene-action-parameter-$parameter'));
        expect(tester.widget<EditableText>(find.descendant(of: input,
            matching: find.byType(EditableText))).controller.text, expected);
      }
    }
  });

  testWidgets('world wait accepts zero and refuses malformed durations', (tester) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.wait,
        project: const ProjectManifest(name: '2D', maps: [], tilesets: []),
        onSubmitResult: (v) => result = v);
    final input = find.byKey(const ValueKey('scene-action-parameter-durationMs'));
    expect(tester.widget<EditableText>(find.descendant(of: input, matching: find.byType(EditableText))).controller.text, '0');
    expect(_submitButton(tester).onPressed, isNotNull);
    for (final invalid in ['', '-1', '0.5', '2147483648', 'NaN']) {
      await tester.enterText(input, invalid);
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNull, reason: invalid);
    }
    await tester.enterText(input, '0');
    await tester.pump();
    _submitButton(tester).onPressed!();
    await tester.pump();
    expect((result!.payload as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.wait(durationMs: 0));
  });

  test('sound picker helper filters the real project media inventory', () {
    final options = buildSceneSoundMediaPickerOptions(_mediaProject());
    expect(options.map((option) => option.id), ['door', 'bell']);
    expect(options.map((option) => option.label), ['Porte', 'Cloche']);
    expect(options.every((option) => option.parameters.isEmpty), isTrue);
    expect(
      buildSceneSoundMediaPickerOptions(
        _mediaProject().copyWith(cinematicMediaAssets: []),
      ),
      isEmpty,
    );
  });

  testWidgets('tone numbers are editable and neutral defaults submit', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.worldTone,
      commandCatalog: _presentationCommandCatalog(),
      onSubmitResult: (value) => result = value,
    );
    expect(find.byType(PokeMapTextField), findsNWidgets(5));
    expect(find.textContaining('Aucun Rouge'), findsNothing);
    final submit = _submitButton(tester);
    expect(submit.onPressed, isNotNull);
    submit.onPressed!();
    await tester.pump();
    expect(
      (result!.payload as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.worldTone(
        red: 0,
        green: 0,
        blue: 0,
        gray: 0,
        durationMs: 0,
      ),
    );
  });

  testWidgets(
    'tone editing round trips finite fractional and boundary values',
    (tester) async {
      SceneActionBuildResult? result;
      const parameters = {
        'red': '-255',
        'green': '255',
        'blue': '-12.5',
        'gray': '25.25',
        'durationMs': '2147483647',
      };
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.worldTone,
        commandCatalog: _presentationCommandCatalog(),
        initialParameters: parameters,
        onSubmitResult: (value) => result = value,
      );
      expect(_submitButton(tester).onPressed, isNotNull);
      _submitButton(tester).onPressed!();
      await tester.pump();
      expect(result!.parameters, parameters);
      expect(
        (result!.payload as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.worldTone(
          red: -255,
          green: 255,
          blue: -12.5,
          gray: 25.25,
          durationMs: 2147483647,
        ),
      );
    },
  );

  testWidgets('tone rejects invalid numbers and duration without clamp', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.worldTone,
      commandCatalog: _presentationCommandCatalog(),
      onSubmit: (_) => fail('Invalid tone must not submit'),
    );
    for (final parameter in ['red', 'green', 'blue', 'gray', 'durationMs']) {
      final input = find.byKey(ValueKey('scene-action-parameter-$parameter'));
      for (final invalid
          in parameter == 'durationMs'
              ? ['', '-1', '0.5', '2147483648', '1e3']
              : [
                  '',
                  'NaN',
                  'Infinity',
                  '1e999',
                  '255.01',
                  parameter == 'gray' ? '-0.1' : '-255.01',
                ]) {
        await tester.ensureVisible(input);
        await tester.enterText(input, invalid);
        await tester.pump();
        expect(
          _submitButton(tester).onPressed,
          isNull,
          reason: '$parameter=$invalid',
        );
        expect(tester.widget<TextField>(input).controller!.text, invalid);
      }
      await tester.enterText(input, '0');
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);
    }
  });

  testWidgets('sound uses a picker and fractional volume round trips', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playSoundEffect,
      commandCatalog: _presentationCommandCatalog(),
      options: _soundOptions,
      initialParameters: const {'mediaAssetId': 'bell', 'volume': '0.35'},
      onSubmitResult: (value) => result = value,
    );
    expect(find.byType(PokeMapTextField), findsOneWidget);
    expect(_picker(tester, 'Effet sonore').value, 'bell');
    expect(
      find.byKey(const ValueKey('scene-action-parameter-mediaAssetId')),
      findsNothing,
    );
    expect(_submitButton(tester).onPressed, isNotNull);
    _submitButton(tester).onPressed!();
    await tester.pump();
    expect(result!.parameters, {'mediaAssetId': 'bell', 'volume': '0.35'});
    expect(
      (result!.payload as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.playSoundEffect(
        mediaAssetId: 'bell',
        volume: 0.35,
      ),
    );
  });

  testWidgets('sound volume is finite and bounded with zero allowed', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playSoundEffect,
      commandCatalog: _presentationCommandCatalog(),
      options: _soundOptions,
    );
    final input = find.byKey(const ValueKey('scene-action-parameter-volume'));
    expect(tester.widget<TextField>(input).controller!.text, '1');
    expect(_submitButton(tester).onPressed, isNotNull);
    for (final invalid in ['', '-0.1', '1.1', 'NaN', 'Infinity', '1e999']) {
      await tester.enterText(input, invalid);
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNull, reason: invalid);
      expect(tester.widget<TextField>(input).controller!.text, invalid);
    }
    for (final valid in ['0', '0.8', '1']) {
      await tester.enterText(input, valid);
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull, reason: valid);
    }
  });

  testWidgets('missing sound reference remains visible and blocks submit', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playSoundEffect,
      commandCatalog: _presentationCommandCatalog(),
      options: _soundOptions,
      initialParameters: const {'mediaAssetId': 'deleted', 'volume': '0.8'},
    );
    expect(find.textContaining('deleted'), findsOneWidget);
    expect(find.textContaining('n’existe plus'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNull);
  });

  for (final duplicateKind in [
    CinematicMediaAssetKind.music,
    CinematicMediaAssetKind.sound,
  ]) {
    testWidgets(
      'ambiguous sound ${duplicateKind.name} blocks submit after registry change',
      (tester) async {
        final manifest = _mediaProject().copyWith(
          cinematicMediaAssets: [
            ..._mediaProject().cinematicMediaAssets,
            CinematicMediaAsset(
              id: 'door',
              label: 'Autre porte',
              kind: duplicateKind,
              relativePath: 'media/other-door.wav',
            ),
          ],
        );
        expect(
          ProjectManifest.fromJson(
            manifest.toJson(),
          ).cinematicMediaAssets.where((media) => media.id == 'door'),
          hasLength(2),
        );
        final options = buildSceneSoundMediaPickerOptions(manifest);
        expect(options.map((option) => option.id), ['bell']);
        await _pumpBuilder(
          tester,
          initialCommandId: NarrativeCommandIds.playSoundEffect,
          commandCatalog: _presentationCommandCatalog(),
          options: _soundOptions,
          initialParameters: const {'mediaAssetId': 'door', 'volume': '0.8'},
        );
        expect(_submitButton(tester).onPressed, isNotNull);
        await _pumpBuilder(
          tester,
          initialCommandId: NarrativeCommandIds.playSoundEffect,
          commandCatalog: _presentationCommandCatalog(),
          options: {NarrativeCommandParameterKind.soundMediaReference: options},
          initialParameters: const {'mediaAssetId': 'door', 'volume': '0.8'},
          onSubmit: (_) => fail('Ambiguous sound must not submit'),
        );
        expect(_submitButton(tester).onPressed, isNull);
        expect(find.textContaining('door'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        SceneActionBuildResult? valid;
        await _pumpBuilder(
          tester,
          initialCommandId: NarrativeCommandIds.playSoundEffect,
          commandCatalog: _presentationCommandCatalog(),
          options: {NarrativeCommandParameterKind.soundMediaReference: options},
          initialParameters: const {'mediaAssetId': 'bell', 'volume': '0.8'},
          onSubmitResult: (value) => valid = value,
        );
        expect(_submitButton(tester).onPressed, isNotNull);
        _submitButton(tester).onPressed!();
        await tester.pump();
        expect(
          (valid!.payload as SceneActionPayload).interactiveCommand,
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'bell',
            volume: 0.8,
          ),
        );
      },
    );
  }

  testWidgets('empty sound inventory blocks instead of accepting raw IDs', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playSoundEffect,
      commandCatalog: _presentationCommandCatalog(),
    );
    expect(find.textContaining('Aucun Effet sonore'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNull);
  });

  testWidgets(
    'warp loads an inactive destination through the supplied map loader',
    (tester) async {
      final requested = <String>[];
      SceneNodePayload? submitted;
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.warp,
        initialParameters: const {'destinationMapId': 'forest'},
        options: {
          ..._warpOptions,
          NarrativeCommandParameterKind.warp: const [
            SceneActionPickerOption(
              id: 'port_arrival',
              label: 'Port · Arrivée',
              parentId: 'port',
            ),
          ],
        },
        loadWarpMap: (id) async {
          requested.add(id);
          return _warpMap(id);
        },
        onSubmit: (payload) => submitted = payload,
      );
      expect(requested, ['forest']);
      final arrival = _picker(tester, 'Point d’arrivée');
      expect(arrival.items.map((item) => item.value), ['forest_arrival']);
      final submit = find.byKey(const ValueKey('scene-action-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      expect(
        (submitted! as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.warp(
          destinationMapId: 'forest',
          warpId: 'forest_arrival',
        ),
      );
    },
  );

  testWidgets('warp ignores a late response from the previous destination', (
    tester,
  ) async {
    final port = Completer<MapData?>(), forest = Completer<MapData?>();
    final requested = <String>[];
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      loadWarpMap: (id) {
        requested.add(id);
        return id == 'port' ? port.future : forest.future;
      },
      onSubmit: (payload) => submitted = payload,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
    _picker(tester, 'Carte de destination').onChanged('forest');
    await tester.pump();
    forest.complete(_warpMap('forest'));
    await tester.pump();
    port.complete(_warpMap('port'));
    await tester.pump();
    expect(requested, ['port', 'forest']);
    final arrival = _picker(tester, 'Point d’arrivée');
    expect(arrival.items.map((item) => item.value), ['', 'forest_arrival']);
    expect(arrival.value, isEmpty);
    arrival.onChanged('forest_arrival');
    await tester.pump();
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
      ),
    );
  });

  testWidgets(
    'warp picker keeps a passive Scene arrival point without inventing an outgoing warp',
    (tester) async {
      SceneNodePayload? submitted;
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.warp,
        initialParameters: const {'destinationMapId': 'forest'},
        options: _warpOptions,
        loadWarpMap: (id) async => _warpMap(id).copyWith(
          warps: [
            MapWarp(
              id: 'scene-arrival',
              pos: const GridPos(x: 2, y: 3),
              targetMapId: id,
              targetPos: const GridPos(x: 2, y: 3),
              triggerMode: MapWarpTriggerMode.sceneOnly,
            ),
          ],
        ),
        onSubmit: (payload) => submitted = payload,
      );
      final arrival = _picker(tester, 'Point d’arrivée');
      expect(arrival.items.map((item) => item.value), ['scene-arrival']);
      expect(_submitButton(tester).onPressed, isNotNull);
      _submitButton(tester).onPressed!();
      await tester.pump();
      expect(
        (submitted! as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.warp(
          destinationMapId: 'forest',
          warpId: 'scene-arrival',
        ),
      );
    },
  );

  for (final failure in ['missing', 'wrongIdentity', 'throws']) {
    testWidgets(
      'warp map loader refuses $failure without using stale options',
      (tester) async {
        await _pumpBuilder(
          tester,
          initialCommandId: NarrativeCommandIds.warp,
          options: _warpOptions,
          loadWarpMap: (id) async => switch (failure) {
            'missing' => null,
            'wrongIdentity' => _warpMap('other'),
            _ => throw StateError('Unavailable destination'),
          },
        );
        expect(
          tester
              .widget<PokeMapButton>(
                find.byKey(const ValueKey('scene-action-submit')),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('Points d’arrivée indisponibles'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('warp map response after disposal has no effect', (tester) async {
    final pending = Completer<MapData?>();
    final requested = <String>[];
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      loadWarpMap: (id) {
        requested.add(id);
        return pending.future;
      },
    );
    expect(requested, ['port']);
    await tester.pumpWidget(const SizedBox());
    pending.complete(_warpMap('port'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('warp defaults preserve facing and use the map transition', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      onSubmit: (payload) => submitted = payload,
    );
    expect(find.text('Conserver la direction'), findsOneWidget);
    expect(find.text('Transition de la carte'), findsOneWidget);
    expect(_picker(tester, 'Point d’arrivée').items.map((item) => item.label), [
      'Port · Arrivée',
    ]);
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'port',
        warpId: 'port_arrival',
      ),
    );
  });

  testWidgets('warp map change clears the arrival and filters its owner', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      onSubmit: (payload) => submitted = payload,
    );
    _picker(tester, 'Carte de destination').onChanged('forest');
    await tester.pump();
    final arrival = _picker(tester, 'Point d’arrivée');
    expect(arrival.items.map((item) => item.label), [
      'Choisir un point d’arrivée',
      'Forêt · Arrivée',
    ]);
    expect(arrival.value, isEmpty);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
    arrival.onChanged('forest_arrival');
    await tester.pump();
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
      ),
    );
  });

  testWidgets('warp editing preserves explicit facing and no transition', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      initialParameters: const {
        'destinationMapId': 'forest',
        'warpId': 'forest_arrival',
        'arrivalFacing': 'north',
        'transition': 'none',
      },
      onSubmit: (payload) => submitted = payload,
    );
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
        arrivalFacing: EntityFacing.north,
        transition: SceneWarpTransition.none,
      ),
    );
  });

  for (final invalid in const [
    {'arrivalFacing': 'diagonal'},
    {'transition': 'fade'},
    {'arrivalFacing': ' north '},
    {'transition': ' none '},
    {'arrivalFacing': ' '},
    {'transition': ' '},
  ]) {
    testWidgets('warp refuses unknown option $invalid before submit', (
      tester,
    ) async {
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.warp,
        options: _warpOptions,
        initialParameters: invalid,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
    });
  }

  testWidgets('warp scopes identical arrival IDs to one destination map', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: {
        ..._warpOptions,
        NarrativeCommandParameterKind.warp: const [
          SceneActionPickerOption(
            id: 'arrival',
            label: 'Forêt · Arrivée',
            parentId: 'forest',
          ),
          SceneActionPickerOption(
            id: 'arrival',
            label: 'Port · Arrivée',
            parentId: 'port',
          ),
        ],
      },
    );
    expect(_picker(tester, 'Point d’arrivée').items.map((item) => item.label), [
      'Port · Arrivée',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moveNpc retains its independent arrival picker', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.moveNpc,
      options: {
        ..._warpOptions,
        NarrativeCommandParameterKind.npc: const [
          SceneActionPickerOption(id: 'port::sailor', label: 'Marin'),
        ],
      },
      onSubmit: (payload) => submitted = payload,
      loadWarpMap: (_) async => fail('moveNpc must not load a Warp destination'),
    );
    expect(_picker(tester, 'Destination').items.map((item) => item.label), [
      'Forêt · Arrivée',
      'Port · Arrivée',
    ]);
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.moveNpc(
        mapId: 'port',
        entityId: 'sailor',
        warpId: 'forest_arrival',
      ),
    );
  });

  testWidgets('platform action uses guided platform and motion pickers', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.movePlatform,
        options: const {NarrativeCommandParameterKind.movingPlatform: [
          SceneActionPickerOption(id: 'gym::bridge', label: 'Arène · Plateforme centrale'),
        ]}, onSubmit: (payload) => submitted = payload);
    expect(find.text('Arène · Plateforme centrale'), findsOneWidget);
    expect(find.text('Avancer'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect((submitted! as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.movePlatform(mapId: 'gym', platformId: 'bridge', motion: MovingPlatformMotion.forward));
  });
  testWidgets('guided gift action exposes received and bagFull without raw IDs', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.giveItemGift,
      options: const {NarrativeCommandParameterKind.item: [SceneActionPickerOption(id: 'tm23', label: 'CT23') ]},
      onSubmit: (payload) => submitted = payload);
    expect(find.text('Interactif'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    final payload = submitted! as SceneActionPayload;
    expect(payload.consequence, isNull);
    expect(payload.interactiveCommand, SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1));
    expect(payload.interactiveCommand!.outputPortIds, ['received', 'bagFull']);
  });
  testWidgets('builds a persistent action from guided picker values', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    SceneActionBuildResult? submittedResult;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.giveItem,
      options: {
        NarrativeCommandParameterKind.item: const [
          SceneActionPickerOption(id: 'potion', label: 'Potion'),
        ],
      },
      onSubmit: (payload) => submitted = payload,
      onSubmitResult: (result) => submittedResult = result,
    );

    expect(find.text('Persistant'), findsOneWidget);
    expect(find.text('FG-083'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('scene-action-parameter-quantity')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    final action = submitted! as SceneActionPayload;
    expect(
      action.consequence,
      SceneConsequence.giveItem(itemId: 'potion', quantity: 2),
    );
    expect(submittedResult!.command.id, NarrativeCommandIds.giveItem);
    expect(submittedResult!.parameters, {'itemId': 'potion', 'quantity': '2'});
  });

  testWidgets(
    'empty guided picker blocks publication without asking for an ID',
    (tester) async {
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.giveItem,
      );

      expect(find.textContaining('Aucun Objet disponible'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(PokeMapTextField), findsOneWidget);
    },
  );

  testWidgets('static encounter uses the dedicated guided contract picker', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.staticEncounter,
      options: const {
        NarrativeCommandParameterKind.staticEncounter: [
          SceneActionPickerOption(
            id: 'static:trainer_lighthouse_guardian',
            label: 'Gardien du phare',
            parameters: {
              'trainerId': 'trainer_lighthouse_guardian',
              'battleTemplateId': 'battle_lighthouse_pokemon',
            },
          ),
        ],
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Gardien du phare'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      submitted,
      SceneBattlePayload(
        battleKind: 'static',
        trainerId: 'trainer_lighthouse_guardian',
        battleTemplateId: 'battle_lighthouse_pokemon',
        declaredOutcomes: const ['victory', 'defeat'],
      ),
    );
  });

  testWidgets('canonical heal command is authorable without raw parameters', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Persistant'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (submitted! as SceneActionPayload).consequence,
      SceneConsequence.healParty(),
    );
  });

  testWidgets('Pokemon form picker follows the selected species', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.givePokemon,
      initialParameters: const {'speciesId': 'sproutle', 'formId': 'sunny'},
      options: const {
        NarrativeCommandParameterKind.species: [
          SceneActionPickerOption(id: 'sproutle', label: 'Sproutle'),
          SceneActionPickerOption(id: 'shellby', label: 'Shellby'),
        ],
        NarrativeCommandParameterKind.speciesForm: [
          SceneActionPickerOption(
            id: 'base',
            label: 'Forme de base',
            parentId: 'sproutle',
          ),
          SceneActionPickerOption(
            id: 'sunny',
            label: 'Sunny',
            parentId: 'sproutle',
          ),
          SceneActionPickerOption(
            id: 'shell',
            label: 'Shell',
            parentId: 'shellby',
          ),
        ],
      },
      onSubmitResult: (value) => result = value,
    );

    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Shell'), findsNothing);

    final speciesPicker = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Espèce');
    speciesPicker.onChanged('shellby');
    await tester.pump();

    expect(find.text('Sunny'), findsNothing);
    expect(find.text('Shell'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(result!.parameters['speciesId'], 'shellby');
    expect(result!.parameters['formId'], 'shell');
    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.givePokemon(
        speciesId: 'shellby',
        formId: 'shell',
        level: 1,
        currentHp: 1,
      ),
    );
  });

  testWidgets('custom animation uses actor definition and direction pickers', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playCharacterAnimation,
      options: const {
        NarrativeCommandParameterKind.actor: [
          SceneActionPickerOption(id: 'player', label: 'Joueur'),
        ],
        NarrativeCommandParameterKind.customAnimationDefinition: [
          SceneActionPickerOption(
            id: 'wave',
            label: 'Saluer',
            parameters: {'animationMode': 'directional'},
          ),
        ],
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Joueur'), findsOneWidget);
    expect(find.text('Saluer'), findsOneWidget);
    expect(find.text('Direction'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-actorId')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    final command =
        (submitted! as SceneActionPayload).interactiveCommand!
            as SceneCharacterCustomAnimationInteractiveCommand;
    expect(command.runtimeCommand.actorId, 'player');
    expect(command.runtimeCommand.definitionId, 'wave');
    expect(command.runtimeCommand.direction, EntityFacing.south);
    expect(
      command.runtimeCommand.playback,
      CharacterCustomAnimationPlayback.once(),
    );
  });

  testWidgets('RailJourney uses guided journey and transition pickers', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.railJourney,
      runtimeCommandIds: const <String>{NarrativeCommandIds.railJourney},
      options:
          const <NarrativeCommandParameterKind, List<SceneActionPickerOption>>{
            NarrativeCommandParameterKind.railJourney:
                <SceneActionPickerOption>[
                  SceneActionPickerOption(id: 'T1', label: 'Hanazuki → Aohara'),
                ],
          },
      initialParameters: const <String, String>{
        'commandId': 'scene.rail.begin',
        'operation': 'begin',
      },
      onSubmitResult: (value) => result = value,
    );

    expect(find.text('Hanazuki → Aohara'), findsOneWidget);
    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Aller'), findsOneWidget);
    expect(find.text('Porte ouest'), findsOneWidget);
    expect(find.text('Étape'), findsNothing);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-journeyId')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (result!.payload as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.railJourney(
        commandId: 'scene.rail.begin',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.begin,
        direction: RailJourneyDirection.outbound,
        doorSide: RailJourneyDoorSide.west,
      ),
    );
  });

  testWidgets('badge and field ability use project-owned guided pickers', (
    tester,
  ) async {
    SceneNodePayload? badgePayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmit: (payload) => badgePayload = payload,
    );

    expect(find.text('Badge Marée'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (badgePayload! as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );

    SceneNodePayload? fieldPayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.unlockFieldAbility,
      options: const {
        NarrativeCommandParameterKind.fieldAbility: [
          SceneActionPickerOption(id: 'surf', label: 'Surf'),
        ],
      },
      onSubmit: (payload) => fieldPayload = payload,
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (fieldPayload! as SceneActionPayload).consequence,
      SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    );
  });

  testWidgets(
    'NPC state uses a guided project picker without raw identifiers',
    (tester) async {
      SceneActionBuildResult? result;
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.setNpcPresence,
        runtimeCommandIds: const {NarrativeCommandIds.setNpcPresence},
        options: const {
          NarrativeCommandParameterKind.npc: [
            SceneActionPickerOption(
              id: 'map_port::npc_sailor',
              label: 'Port · Marin',
            ),
          ],
        },
        initialParameters: const {'present': 'false'},
        onSubmitResult: (value) => result = value,
      );

      expect(find.text('Port · Marin'), findsOneWidget);
      expect(find.text('PNJ'), findsOneWidget);
      expect(find.byType(PokeMapDropdownField<String>), findsNWidgets(3));
      expect(find.byType(PokeMapTextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      await tester.pump();

      expect(
        (result!.payload as SceneActionPayload).consequence,
        SceneConsequence.setNpcPresence(
          mapId: 'map_port',
          entityId: 'npc_sailor',
          present: false,
        ),
      );
    },
  );

  testWidgets('pause menu visibility uses a guided picker without Resume', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.setPauseMenuEntryVisibility,
      runtimeCommandIds: const {
        NarrativeCommandIds.setPauseMenuEntryVisibility,
      },
      initialParameters: const {'visible': 'false'},
      onSubmitResult: (value) => result = value,
    );

    final actionField = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Entrée du menu');
    expect(actionField.items.map((item) => item.label), contains('Pokédex'));
    expect(
      actionField.items.map((item) => item.label),
      isNot(contains('Reprendre')),
    );
    final visibilityField = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Visibilité');
    expect(visibilityField.items.map((item) => item.label), <String>[
      'Afficher',
      'Masquer',
    ]);

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.setPauseMenuEntryVisibility(
        actionId: ProjectPauseActionId.party,
        visible: false,
      ),
    );
  });

  testWidgets('deleted picker target is kept visible and blocks editing', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_deleted'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
    );

    expect(find.textContaining('badge_deleted'), findsOneWidget);
    expect(find.textContaining('n’existe plus'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('editing preserves an existing non-default picker target', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_tide'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_leaf', label: 'Badge Feuille'),
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmitResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(result!.parameters['badgeId'], 'badge_tide');
    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );
  });

  testWidgets('commands absent from the current runtime stay hidden', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      runtimeCommandIds: const {NarrativeCommandIds.healParty},
    );

    expect(find.text('Soigner l’équipe'), findsOneWidget);
    expect(find.text('Donner un badge'), findsNothing);
    expect(find.text('Modifier la présence d’un PNJ'), findsNothing);
  });

  testWidgets('Finish Game uses friendly fields and guided policy pickers', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.finishGame,
      runtimeCommandIds: const {NarrativeCommandIds.finishGame},
      initialParameters: const {
        'endingName': 'Selbrume sauvée',
        'resultTitle': 'Selbrume est sauvée',
        'resultSummary': 'La brume se retire.',
        'includeCredits': 'false',
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Issue de la partie'), findsOneWidget);
    expect(find.text('Après la fin'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-endingId')),
      findsNothing,
    );

    final finishSubmit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(finishSubmit);
    final finishButton = tester.widget<PokeMapButton>(finishSubmit);
    expect(finishButton.onPressed, isNotNull);
    finishButton.onPressed!();
    await tester.pump();

    final consequence =
        (submitted! as SceneActionPayload).consequence!
            as SceneFinishGameConsequence;
    expect(consequence.endingId, 'ending.selbrume-sauvee');
    expect(consequence.credits, isNull);
    expect(consequence.postGamePolicy, ScenePostGamePolicy.continueGame);
  });
}

const _warpOptions = {
  NarrativeCommandParameterKind.map: [
    SceneActionPickerOption(id: 'port', label: 'Port'),
    SceneActionPickerOption(id: 'forest', label: 'Forêt'),
  ],
  NarrativeCommandParameterKind.warp: [
    SceneActionPickerOption(
      id: 'forest_arrival',
      label: 'Forêt · Arrivée',
      parentId: 'forest',
    ),
    SceneActionPickerOption(
      id: 'port_arrival',
      label: 'Port · Arrivée',
      parentId: 'port',
    ),
  ],
};

MapData _warpMap(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 4, height: 4),
  warps: [
    MapWarp(
      id: '${id}_arrival',
      pos: const GridPos(x: 1, y: 1),
      targetMapId: id,
      targetPos: const GridPos(x: 1, y: 1),
    ),
  ],
);

PokeMapDropdownField<String> _picker(WidgetTester tester, String label) =>
    tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == label);

Future<void> _pumpBuilder(
  WidgetTester tester, {
  required String initialCommandId,
  Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>> options =
      const {},
  ValueChanged<SceneNodePayload>? onSubmit,
  ValueChanged<SceneActionBuildResult>? onSubmitResult,
  Map<String, String> initialParameters = const {},
  Set<String>? runtimeCommandIds,
  Future<MapData?> Function(String)? loadWarpMap,
  Future<Map<String, String>> Function()? loadMoves,
  NarrativeCommandCatalog? commandCatalog,
  ProjectManifest? project = const ProjectManifest(name: '2D UI fixture', maps: [], tilesets: []),
  SceneActionPayload? initialPayload,
}) async {
  tester.view.physicalSize = const Size(900, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneActionBuilder(
            key: ValueKey('builder-$initialCommandId'),
            initialCommandId: initialCommandId,
            project: project,
            initialPayload: initialPayload,
            commandCatalog: commandCatalog,
            pickerOptions: options,
            initialParameters: initialParameters,
            runtimeCommandIds: runtimeCommandIds,
            loadWarpMap: loadWarpMap,
            loadMoves: loadMoves ?? _loadGiftMoves,
            onSubmit: onSubmit ?? (_) {},
            onSubmitResult: onSubmitResult,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PokeMapButton _submitButton(WidgetTester tester) => tester
    .widget<PokeMapButton>(find.byKey(const ValueKey('scene-action-submit')));

Future<Map<String, String>> _loadGiftMoves() async => {'exceptional': 'Capacité exceptionnelle', 'tackle': 'Charge', 'growl': 'Rugissement', 'surf': 'Surf', 'fly': 'Vol'};

const _soundOptions = {
  NarrativeCommandParameterKind.soundMediaReference: [
    SceneActionPickerOption(id: 'door', label: 'Porte'),
    SceneActionPickerOption(id: 'bell', label: 'Cloche'),
  ],
};

NarrativeCommandCatalog _presentationCommandCatalog() {
  final catalog = NarrativeCommandCatalog.canonical();
  for (var index = 0; index < catalog.commands.length; index++) {
    final command = catalog.commands[index];
    if (command.id != NarrativeCommandIds.worldTone &&
        command.id != NarrativeCommandIds.playSoundEffect &&
        command.id != NarrativeCommandIds.wait) {
      continue;
    }
    catalog.commands[index] = NarrativeCommandDescriptor(
      id: command.id,
      label: command.label,
      description: command.description,
      backend: command.backend,
      capabilities: const NarrativeCommandCapabilities.supported(),
      fgLotId: command.fgLotId,
      wireId: command.wireId,
      parameters: command.parameters,
      isPersistent: command.isPersistent,
      isAwaitable: command.isAwaitable,
    );
  }
  return catalog;
}

ProjectManifest _mediaProject() => ProjectManifest(
  name: 'Présentation du monde',
  maps: [],
  tilesets: [],
  cinematicMediaAssets: [
    for (final id in ['door', 'bell', 'loop', 'music', 'fx'])
      CinematicMediaAsset(
        id: id,
        label: switch (id) {
          'door' => 'Porte',
          'bell' => 'Cloche',
          'loop' => 'Ambiance en boucle',
          'music' => 'Musique',
          _ => 'Effet visuel',
        },
        kind: switch (id) {
          'music' => CinematicMediaAssetKind.music,
          'fx' => CinematicMediaAssetKind.cinematicFx,
          _ => CinematicMediaAssetKind.sound,
        },
        relativePath: 'media/$id.wav',
        loopByDefault: id == 'loop',
      ),
  ],
);
