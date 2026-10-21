import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final supportedCommands = _supportedCommands();

  Future<void> pump(
    WidgetTester tester, {
    ProjectManifest? project,
    SceneNodePayload? current,
    bool useTestCatalog = true,
    required ValueChanged<SceneNodePayload> onApply,
  }) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 440,
            child: SceneActionForm(
              project: project ?? _project(),
              current: current,
              commandCatalog: useTestCatalog ? supportedCommands : null,
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder select(String label) => find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );

  Future<void> pick(WidgetTester tester, String label, String value) async {
    await tester.tap(
      find.descendant(
        of: select(label),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    if (find.text(value).evaluate().isEmpty) {
      await tester.scrollUntilVisible(find.text(value), 200,
        scrollable: find.byType(Scrollable).last);
    }
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  Finder field(String command, String parameter) => find.descendant(
    of: find.byKey(ValueKey('action-$command-$parameter')),
    matching: find.byType(TextField),
  );

  Future<void> enter(
    WidgetTester tester,
    String command,
    String parameter,
    String value,
  ) async {
    await tester.enterText(field(command, parameter), value);
    await tester.pump();
  }

  StudioButton apply(WidgetTester tester) => tester.widget<StudioButton>(
    find.byWidgetPredicate(
      (widget) =>
          widget is StudioButton &&
          (widget.label == 'Ajouter l’action' ||
              widget.label == 'Appliquer l’action'),
    ),
  );

  test('the form accepts a local command catalogue for presentation tests', () {
    final originalCapabilities = {
      for (final command in NarrativeCommandCatalog.canonical().commands)
        command.id: [
          command.capabilities.model,
          command.capabilities.editor,
          command.capabilities.runtime,
        ],
    };
    expect(
      () => Function.apply(SceneActionForm.new, const [], {
        #project: _project(),
        #current: null,
        #onApply: (SceneNodePayload _) {},
        #commandCatalog: _supportedCommands(),
      }),
      returnsNormally,
    );
    for (final id in [
      NarrativeCommandIds.worldTone,
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.playMusicEffect,
    ]) {
      final capabilities = NarrativeCommandCatalog.canonical()
          .byId(id)!
          .capabilities;
      expect([
        capabilities.model,
        capabilities.editor,
        capabilities.runtime,
      ], originalCapabilities[id]);
    }
  });

  testWidgets('the default form follows canonical command capabilities', (
    tester,
  ) async {
    await pump(tester, useTestCatalog: false, onApply: (_) {});
    final commands = tester.widget<StudioSelect>(select('Commande')).options;
    for (final id in [
      NarrativeCommandIds.worldTone,
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.playMusicEffect,
    ]) {
      expect(
        commands.containsKey(id),
        NarrativeCommandCatalog.canonical().byId(id)!.isPublishable,
      );
    }
  });

  testWidgets('3D projects cannot choose or apply 2D presentation drafts', (tester) async {
    final project = _project().copyWith(settings: const ProjectSettings(dimension: ProjectDimension.threeD));
    for (final command in [
      SceneInteractiveCommand.wait(durationMs: 400),
      SceneInteractiveCommand.worldTone(red: -255, green: 0, blue: 0, gray: 0, durationMs: 300),
      SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: .8),
    ]) {
      await pump(tester, project: project, useTestCatalog: false,
        current: SceneActionPayload.interactive(command),
        onApply: (_) => fail('3D presentation command must not apply'));
      final options = tester.widget<StudioSelect>(select('Commande')).options;
      for (final id in ['wait', 'worldTone', 'playSoundEffect']) {
        expect(options.containsKey(id), isFalse, reason: id);
      }
      expect(apply(tester).onPressed, isNull);
    }
  });

  testWidgets('world wait uses zero defaults and rejects invalid durations', (tester) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, useTestCatalog: false, onApply: applied.add);
    await pick(tester, 'Commande', 'Attendre');
    expect(tester.widget<TextField>(field('wait', 'durationMs')).controller!.text, '0');
    expect(apply(tester).onPressed, isNotNull);
    for (final invalid in ['', '-1', '0.5', '2147483648', 'NaN']) {
      await enter(tester, 'wait', 'durationMs', invalid);
      expect(apply(tester).onPressed, isNull, reason: invalid);
    }
    await enter(tester, 'wait', 'durationMs', '0');
    await tester.tap(find.text('Ajouter l’action'));
    expect((applied.single as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.wait(durationMs: 0));
  });

  testWidgets('tone has guided numeric fields and valid neutral defaults', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, onApply: applied.add);
    await pick(tester, 'Commande', 'Changer le ton du monde');
    expect(find.byType(StudioDraftField), findsNWidgets(5));
    expect(find.text('Entre -255 et 255.'), findsNWidgets(3));
    expect(find.text('Entre 0 et 255.'), findsOneWidget);
    expect(
      find.text('Millisecondes entières, de 0 à 2147483647.'),
      findsOneWidget,
    );
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Ajouter l’action'));
    expect(
      (applied.single as SceneActionPayload).interactiveCommand!.toJson(),
      {
        'kind': 'worldTone',
        'red': 0.0,
        'green': 0.0,
        'blue': 0.0,
        'gray': 0.0,
        'durationMs': 0,
      },
    );
  });

  testWidgets('tone accepts fractional channels and exact boundary values', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, onApply: applied.add);
    await pick(tester, 'Commande', 'Changer le ton du monde');
    for (final entry in {
      'red': '-255',
      'green': '255',
      'blue': '-12.5',
      'gray': '255',
      'durationMs': '2147483647',
    }.entries) {
      await enter(tester, 'worldTone', entry.key, entry.value);
    }
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Ajouter l’action'));
    expect(
      (applied.single as SceneActionPayload).interactiveCommand!.toJson(),
      {
        'kind': 'worldTone',
        'red': -255.0,
        'green': 255.0,
        'blue': -12.5,
        'gray': 255.0,
        'durationMs': 2147483647,
      },
    );
  });

  testWidgets('invalid tone channels block applying without clamping input', (
    tester,
  ) async {
    await pump(tester, onApply: (_) => fail('Invalid tone must not apply'));
    await pick(tester, 'Commande', 'Changer le ton du monde');
    for (final parameter in ['red', 'green', 'blue', 'gray']) {
      for (final invalid in [
        '',
        'NaN',
        'Infinity',
        '-Infinity',
        '1e999',
        'nope',
        '255.01',
        parameter == 'gray' ? '-0.01' : '-255.01',
      ]) {
        await enter(tester, 'worldTone', parameter, invalid);
        expect(apply(tester).onPressed, isNull, reason: '$parameter=$invalid');
        expect(
          tester
              .widget<TextField>(field('worldTone', parameter))
              .controller!
              .text,
          invalid,
        );
        expect(
          tester
              .widget<TextField>(field('worldTone', parameter))
              .decoration!
              .errorText,
          isNotNull,
        );
      }
      await enter(tester, 'worldTone', parameter, '0');
      expect(apply(tester).onPressed, isNotNull);
    }
  });

  testWidgets('tone duration is a nonnegative int32 with no coercion', (
    tester,
  ) async {
    await pump(tester, onApply: (_) => fail('Invalid duration must not apply'));
    await pick(tester, 'Commande', 'Changer le ton du monde');
    for (final invalid in ['', '-1', '1.5', '1e3', '2147483648', 'NaN']) {
      await enter(tester, 'worldTone', 'durationMs', invalid);
      expect(apply(tester).onPressed, isNull, reason: invalid);
    }
    for (final valid in ['0', '300']) {
      await enter(tester, 'worldTone', 'durationMs', valid);
      expect(apply(tester).onPressed, isNotNull, reason: valid);
    }
  });

  testWidgets('editing tone preserves fractions and opaque action metadata', (
    tester,
  ) async {
    final current = SceneActionPayload.interactive(
      SceneInteractiveCommand.worldTone(
        red: -128.5,
        green: 255,
        blue: 12.25,
        gray: 25.5,
        durationMs: 300,
      ),
      actionKind: 'authored-tone',
      parameters: const {'label': 'Crépuscule'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: current, onApply: applied.add);
    expect(find.textContaining('paramètres avancés'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    expect(applied, isEmpty);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, current);
  });

  testWidgets('ME picker preserves its distinct role and bounded BGM interruption', (tester) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, onApply: applied.add);
    await pick(tester, 'Commande', 'Jouer une fanfare');
    await pick(tester, 'Fanfare', 'Porte');
    for (final id in ['fadeOutMs', 'fadeInMs']) {
      expect(tester.widget<TextField>(field('playMusicEffect', id)).controller!.text, '0');
      for (final invalid in ['', '-1', '0.5', '60001', 'NaN']) {
        await enter(tester, 'playMusicEffect', id, invalid);
        expect(apply(tester).onPressed, isNull, reason: '$id=$invalid');
      }
      await enter(tester, 'playMusicEffect', id, '200');
    }
    await enter(tester, 'playMusicEffect', 'volume', '0.8');
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Ajouter l’action'));
    expect((applied.single as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.playMusicEffect(mediaAssetId: 'door', volume: .8,
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 200, fadeInMs: 200)));
  });

  testWidgets('editing ME preserves nested interruption and opaque action metadata', (tester) async {
    final current = SceneActionPayload.interactive(
      SceneInteractiveCommand.playMusicEffect(mediaAssetId: 'bell', volume: .35,
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 240, fadeInMs: 420)),
      actionKind: 'authored-ME', parameters: const {'label': 'Récompense'});
    final applied = <SceneNodePayload>[];
    await pump(tester, useTestCatalog: false, current: current, onApply: applied.add);
    expect(tester.widget<TextField>(field('playMusicEffect', 'fadeOutMs')).controller!.text, '240');
    expect(tester.widget<TextField>(field('playMusicEffect', 'fadeInMs')).controller!.text, '420');
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, current);
  });

  testWidgets('sound picker uses only non-looping sound inventory', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, onApply: applied.add);
    await pick(tester, 'Commande', 'Jouer un effet sonore');
    final sound = tester.widget<StudioSelect>(select('Effet sonore'));
    expect(sound.options, {'door': 'Porte', 'bell': 'Cloche'});
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('door'), findsNothing);
    expect(find.text('Entre 0 et 1.'), findsOneWidget);
    expect(apply(tester).onPressed, isNull);
    await pick(tester, 'Effet sonore', 'Porte');
    expect(apply(tester).onPressed, isNotNull);
    await enter(tester, 'playSoundEffect', 'volume', '0.8');
    await tester.tap(find.text('Ajouter l’action'));
    expect(
      (applied.single as SceneActionPayload).interactiveCommand!.toJson(),
      {'kind': 'playSoundEffect', 'mediaAssetId': 'door', 'volume': 0.8},
    );
  });

  testWidgets(
    'volume rejects nonfinite and out-of-range values without clamp',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await pump(tester, onApply: applied.add);
      await pick(tester, 'Commande', 'Jouer un effet sonore');
      await pick(tester, 'Effet sonore', 'Porte');
      for (final invalid in ['', '-0.1', '1.01', 'NaN', 'Infinity', '1e999']) {
        await enter(tester, 'playSoundEffect', 'volume', invalid);
        expect(apply(tester).onPressed, isNull, reason: invalid);
        expect(
          tester
              .widget<TextField>(field('playSoundEffect', 'volume'))
              .controller!
              .text,
          invalid,
        );
      }
      for (final valid in ['0', '1']) {
        await enter(tester, 'playSoundEffect', 'volume', valid);
        expect(apply(tester).onPressed, isNotNull);
        await tester.tap(find.text('Ajouter l’action'));
        expect(
          (applied.last as SceneActionPayload).interactiveCommand!
              .toJson()['volume'],
          double.parse(valid),
        );
      }
    },
  );

  testWidgets('editing sound round trips its reference volume and metadata', (
    tester,
  ) async {
    final current = SceneActionPayload.interactive(
      SceneInteractiveCommand.playSoundEffect(
        mediaAssetId: 'bell',
        volume: 0.35,
      ),
      actionKind: 'authored-sound',
      parameters: const {'label': 'Annonce'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: current, onApply: applied.add);
    expect(find.text('Cloche'), findsOneWidget);
    expect(find.textContaining('paramètres avancés'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, current);
  });

  for (final unavailable in ['deleted', 'loop', 'music', 'fx']) {
    testWidgets(
      'unavailable sound $unavailable stays visible and blocks apply',
      (tester) async {
        final current = SceneActionPayload.interactive(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: unavailable,
            volume: 0.8,
          ),
        );
        await pump(
          tester,
          current: current,
          onApply: (_) => fail('Unavailable sound must not apply'),
        );
        expect(
          find.text('Référence introuvable : $unavailable'),
          findsOneWidget,
        );
        expect(apply(tester).onPressed, isNull);
        expect(
          current.interactiveCommand!.toJson()['mediaAssetId'],
          unavailable,
        );
      },
    );
  }

  testWidgets('removing a selected sound from the project blocks applying', (
    tester,
  ) async {
    await pump(tester, onApply: (_) {});
    await pick(tester, 'Commande', 'Jouer un effet sonore');
    await pick(tester, 'Effet sonore', 'Porte');
    expect(apply(tester).onPressed, isNotNull);
    await pump(
      tester,
      project: _project(media: []),
      onApply: (_) {},
    );
    expect(find.text('Référence introuvable : door'), findsOneWidget);
    expect(apply(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final duplicateKind in [
    CinematicMediaAssetKind.music,
    CinematicMediaAssetKind.sound,
  ]) {
    testWidgets(
      'ambiguous sound ${duplicateKind.name} blocks apply after registry change',
      (tester) async {
        final current = SceneActionPayload.interactive(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'door',
            volume: 0.8,
          ),
        );
        final applied = <SceneNodePayload>[];
        await pump(tester, current: current, onApply: applied.add);
        expect(apply(tester).onPressed, isNotNull);
        final changed = _project().copyWith(
          cinematicMediaAssets: [
            ..._project().cinematicMediaAssets,
            CinematicMediaAsset(
              id: 'door',
              label: 'Autre porte',
              kind: duplicateKind,
              relativePath: 'media/other-door.wav',
            ),
          ],
        );
        expect(
          ProjectManifest.fromJson(changed.toJson()).cinematicMediaAssets
              .where((media) => media.id == 'door'),
          hasLength(2),
        );
        await pump(
          tester,
          project: changed,
          current: current,
          onApply: applied.add,
        );
        expect(apply(tester).onPressed, isNull);
        expect(tester.widget<StudioSelect>(select('Effet sonore')).options, {
          'bell': 'Cloche',
        });
        expect(find.text('Référence introuvable : door'), findsOneWidget);
        expect(applied, isEmpty);
        expect(tester.takeException(), isNull);
        await pick(tester, 'Effet sonore', 'Cloche');
        expect(apply(tester).onPressed, isNotNull);
        await tester.tap(find.text('Appliquer l’action'));
        expect(
          (applied.single as SceneActionPayload).interactiveCommand,
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'bell',
            volume: 0.8,
          ),
        );
      },
    );
  }

  testWidgets('empty sound inventory provides feedback without an ID field', (
    tester,
  ) async {
    await pump(
      tester,
      project: _project(media: []),
      onApply: (_) {},
    );
    await pick(tester, 'Commande', 'Jouer un effet sonore');
    expect(
      tester.widget<StudioSelect>(select('Effet sonore')).options,
      isEmpty,
    );
    expect(
      find.textContaining('Aucune référence effet sonore'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(apply(tester).onPressed, isNull);
  });
}

List<NarrativeCommandDescriptor> _supportedCommands() => [
  for (final command in NarrativeCommandCatalog.canonical().commands)
    if (command.id == NarrativeCommandIds.worldTone ||
        command.id == NarrativeCommandIds.playSoundEffect ||
        command.id == NarrativeCommandIds.playMusicEffect ||
        command.id == NarrativeCommandIds.wait)
      NarrativeCommandDescriptor(
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
      ),
];

ProjectManifest _project({List<CinematicMediaAsset>? media}) => ProjectManifest(
  name: 'Présentation du monde',
  maps: [],
  tilesets: [],
  cinematicMediaAssets:
      media ??
      [
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
