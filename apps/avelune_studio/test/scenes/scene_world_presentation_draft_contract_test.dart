import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

SceneActionDraft _draft({
  ProjectManifest? project,
  SceneActionPayload? current,
  bool custom = true,
}) {
  final draft = SceneActionDraft(
    project: project ?? _project(),
    current: current,
    changed: () {},
    commandCatalog: custom ? _supportedCommands() : null,
  );
  addTearDown(draft.dispose);
  return draft;
}

void _configure(SceneActionDraft draft, ProjectManifest project) =>
    draft.configure(
      project: project,
      current: draft.current,
      loadMap: draft.loadMap,
      loadMoves: draft.loadMoves,
      loadItems: draft.loadItems,
      loadSpecies: draft.loadSpecies,
      commandCatalog: draft.commandCatalog,
    );

void main() {
  test('local command catalogues preserve global capabilities and canonical availability', () {
    final before = {
      for (final command in NarrativeCommandCatalog.canonical().commands)
        command.id: [
          command.capabilities.model,
          command.capabilities.editor,
          command.capabilities.runtime,
        ],
    };
    final custom = _draft();
    expect(
      custom.commands.map((command) => command.id),
      containsAll([
        NarrativeCommandIds.worldTone,
        NarrativeCommandIds.playSoundEffect,
        NarrativeCommandIds.playMusicEffect,
      ]),
    );
    final canonical = _draft(custom: false);
    for (final id in [
      NarrativeCommandIds.worldTone,
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.playMusicEffect,
    ]) {
      final descriptor = NarrativeCommandCatalog.canonical().byId(id)!;
      expect(
        canonical.commands.any((command) => command.id == id),
        descriptor.isPublishable,
      );
      expect([
        descriptor.capabilities.model,
        descriptor.capabilities.editor,
        descriptor.capabilities.runtime,
      ], before[id]);
    }
  });

  test(
    '3D retains existing 2D presentation commands while refusing application',
    () {
      final project = _project().copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      );
      for (final command in [
        SceneInteractiveCommand.wait(durationMs: 400),
        SceneInteractiveCommand.worldTone(
          red: -255,
          green: 0,
          blue: 0,
          gray: 0,
          durationMs: 300,
        ),
        SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: 'door',
          volume: .8,
        ),
      ]) {
        final original = SceneActionPayload.interactive(command);
        final draft = _draft(project: project, current: original);
        expect(draft.valid, isFalse);
        expect(draft.current, same(original));
      }
    },
  );

  test('wait uses zero defaults and canonical integer duration bounds', () {
    final draft = _draft()..choose(NarrativeCommandIds.wait);
    expect(draft.values['durationMs'], '0');
    expect(draft.valid, isTrue);
    expect(
      (draft.buildPayload() as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.wait(durationMs: 0),
    );
    for (final invalid in ['', '-1', '1.5', '1e3', '2147483648', 'NaN']) {
      draft.changeParameter('durationMs', invalid);
      expect(draft.valid, isFalse, reason: invalid);
      expect(draft.values['durationMs'], invalid);
    }
    draft.changeParameter('durationMs', '2147483647');
    expect(draft.valid, isTrue);
  });

  test(
    'tone preserves neutral defaults fractions and exact boundary values',
    () {
      final draft = _draft()..choose(NarrativeCommandIds.worldTone);
      expect(
        (draft.buildPayload() as SceneActionPayload).interactiveCommand!
            .toJson(),
        {
          'kind': 'worldTone',
          'red': 0.0,
          'green': 0.0,
          'blue': 0.0,
          'gray': 0.0,
          'durationMs': 0,
        },
      );
      for (final entry in {
        'red': '-255',
        'green': '255',
        'blue': '-12.5',
        'gray': '255',
        'durationMs': '2147483647',
      }.entries) {
        draft.changeParameter(entry.key, entry.value);
      }
      expect(draft.valid, isTrue);
      expect(
        (draft.buildPayload() as SceneActionPayload).interactiveCommand!
            .toJson(),
        {
          'kind': 'worldTone',
          'red': -255.0,
          'green': 255.0,
          'blue': -12.5,
          'gray': 255.0,
          'durationMs': 2147483647,
        },
      );
    },
  );

  test(
    'tone rejects invalid channels and duration without clamping or coercion',
    () {
      final draft = _draft()..choose(NarrativeCommandIds.worldTone);
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
          draft.changeParameter(parameter, invalid);
          expect(draft.valid, isFalse, reason: '$parameter=$invalid');
          expect(draft.values[parameter], invalid);
          expect(draft.presentationFieldError(parameter), isNotNull);
        }
        draft.changeParameter(parameter, '0');
        expect(draft.valid, isTrue);
      }
      for (final invalid in ['', '-1', '1.5', '1e3', '2147483648', 'NaN']) {
        draft.changeParameter('durationMs', invalid);
        expect(draft.valid, isFalse, reason: invalid);
      }
      for (final valid in ['0', '300']) {
        draft.changeParameter('durationMs', valid);
        expect(draft.valid, isTrue);
      }
    },
  );

  test('tone sound and ME edits retain opaque action and nested metadata', () {
    for (final current in [
      SceneActionPayload.interactive(
        SceneInteractiveCommand.worldTone(
          red: -128.5,
          green: 255,
          blue: 12.25,
          gray: 25.5,
          durationMs: 300,
        ),
        actionKind: 'authored-tone',
        parameters: const {'label': 'Crépuscule'},
      ),
      SceneActionPayload.interactive(
        SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: 'bell',
          volume: .35,
        ),
        actionKind: 'authored-sound',
        parameters: const {'label': 'Annonce'},
      ),
      SceneActionPayload.interactive(
        SceneInteractiveCommand.playMusicEffect(
          mediaAssetId: 'bell',
          volume: .35,
          bgmInterruption: DialogueBgmInterruption(
            fadeOutMs: 240,
            fadeInMs: 420,
          ),
        ),
        actionKind: 'authored-ME',
        parameters: const {'label': 'Récompense'},
      ),
    ]) {
      final draft = _draft(current: current);
      expect(draft.valid, isTrue);
      expect(draft.buildPayload(), current);
      expect(draft.current, same(current));
    }
  });

  test('ME keeps its role and bounded BGM interruption', () {
    final draft = _draft()..choose(NarrativeCommandIds.playMusicEffect);
    draft.changeParameter('mediaAssetId', 'door');
    for (final id in ['fadeOutMs', 'fadeInMs']) {
      expect(draft.values[id], '0');
      for (final invalid in ['', '-1', '0.5', '60001', 'NaN']) {
        draft.changeParameter(id, invalid);
        expect(draft.valid, isFalse, reason: '$id=$invalid');
      }
      draft.changeParameter(id, '200');
    }
    draft.changeParameter('volume', '0.8');
    expect(draft.valid, isTrue);
    expect(
      (draft.buildPayload() as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.playMusicEffect(
        mediaAssetId: 'door',
        volume: .8,
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 200, fadeInMs: 200),
      ),
    );
  });

  test('sound inventory excludes looping media and rejects invalid volume', () {
    final draft = _draft()..choose(NarrativeCommandIds.playSoundEffect);
    expect(draft.options(NarrativeCommandParameterKind.soundMediaReference), {
      'door': 'Porte',
      'bell': 'Cloche',
    });
    expect(draft.valid, isFalse);
    draft.changeParameter('mediaAssetId', 'door');
    for (final invalid in ['', '-0.1', '1.01', 'NaN', 'Infinity', '1e999']) {
      draft.changeParameter('volume', invalid);
      expect(draft.valid, isFalse);
      expect(draft.values['volume'], invalid);
    }
    for (final valid in ['0', '1']) {
      draft.changeParameter('volume', valid);
      expect(draft.valid, isTrue);
      expect(
        (draft.buildPayload() as SceneActionPayload).interactiveCommand!
            .toJson()['volume'],
        double.parse(valid),
      );
    }
  });

  test(
    'removed unavailable and ambiguous sounds remain retained until repaired',
    () {
      for (final unavailable in ['deleted', 'loop', 'music', 'fx']) {
        final current = SceneActionPayload.interactive(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: unavailable,
            volume: .8,
          ),
        );
        final draft = _draft(current: current);
        expect(draft.valid, isFalse);
        expect(draft.current, same(current));
        expect(draft.values['mediaAssetId'], unavailable);
      }
      for (final duplicateKind in [
        CinematicMediaAssetKind.music,
        CinematicMediaAssetKind.sound,
      ]) {
        final current = SceneActionPayload.interactive(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'door',
            volume: .8,
          ),
        );
        final draft = _draft(current: current);
        expect(draft.valid, isTrue);
        _configure(
          draft,
          _project().copyWith(
            cinematicMediaAssets: [
              ..._project().cinematicMediaAssets,
              CinematicMediaAsset(
                id: 'door',
                label: 'Autre porte',
                kind: duplicateKind,
                relativePath: 'media/other-door.wav',
              ),
            ],
          ),
        );
        expect(draft.valid, isFalse);
        expect(
          draft.options(NarrativeCommandParameterKind.soundMediaReference),
          {'bell': 'Cloche'},
        );
        expect(draft.values['mediaAssetId'], 'door');
        draft.changeParameter('mediaAssetId', 'bell');
        expect(draft.valid, isTrue);
        expect(
          (draft.buildPayload() as SceneActionPayload).interactiveCommand,
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'bell',
            volume: .8,
          ),
        );
      }
      final current = SceneActionPayload.interactive(
        SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: 'door',
          volume: .8,
        ),
      );
      final draft = _draft(current: current);
      _configure(draft, _project(media: []));
      expect(draft.valid, isFalse);
      expect(
        draft.options(NarrativeCommandParameterKind.soundMediaReference),
        isEmpty,
      );
      expect(draft.current, same(current));
    },
  );
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
