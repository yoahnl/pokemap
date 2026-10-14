import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> tone({
    double red = -255,
    double green = -255,
    double blue = -255,
    double gray = 0,
    int durationMs = 300,
  }) => {
    'kind': 'worldTone',
    'red': red,
    'green': green,
    'blue': blue,
    'gray': gray,
    'durationMs': durationMs,
  };
  Map<String, dynamic> sound({double volume = 0.8}) => {
    'kind': 'playSoundEffect',
    'mediaAssetId': 'door-sound',
    'volume': volume,
  };
  Map<String, String> parameters(Map<String, dynamic> wire) => {
    for (final entry in wire.entries)
      if (entry.key != 'kind') entry.key: entry.value.toString(),
  };

  test('world tone preserves every component and duration through JSON', () {
    final wire = tone(
      red: -124.5,
      green: 12.25,
      blue: 254.75,
      gray: 60.5,
      durationMs: 2147483647,
    );
    expect(() => SceneInteractiveCommand.fromJson(wire), returnsNormally);
    final command = SceneInteractiveCommand.fromJson(wire);
    expect(command.runtimeType.toString(), 'SceneWorldToneInteractiveCommand');
    expect(command.toJson(), wire);
    expect(
      SceneInteractiveCommand.fromJson(
        jsonDecode(jsonEncode(command.toJson())) as Map<String, dynamic>,
      ),
      command,
    );
    expect(command.outputPortIds, ['completed', 'blocked']);
  });

  test(
    'world tone accepts inclusive component bounds and immediate changes',
    () {
      for (final wire in [
        tone(red: -255, green: 255, blue: 0, gray: 255, durationMs: 0),
        tone(red: 255, green: -255, blue: -255, gray: 0),
      ]) {
        expect(() => SceneInteractiveCommand.fromJson(wire), returnsNormally);
        expect(SceneInteractiveCommand.fromJson(wire).toJson(), wire);
      }
    },
  );

  test(
    'direct native presentation factories enforce the same bounded data',
    () {
      expect(
        SceneInteractiveCommand.worldTone(
          red: -255,
          green: 255,
          blue: 0,
          gray: 0,
          durationMs: 0,
        ),
        isA<SceneWorldToneInteractiveCommand>(),
      );
      expect(
        SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: 'door-sound',
          volume: 0,
        ),
        isA<ScenePlaySoundEffectInteractiveCommand>(),
      );
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -256.0,
        256.0,
      ]) {
        expect(
          () => SceneInteractiveCommand.worldTone(
            red: value,
            green: 0,
            blue: 0,
            gray: 0,
            durationMs: 0,
          ),
          throwsArgumentError,
        );
      }
      for (final value in [-1, 2147483648]) {
        expect(
          () => SceneInteractiveCommand.worldTone(
            red: 0,
            green: 0,
            blue: 0,
            gray: 0,
            durationMs: value,
          ),
          throwsArgumentError,
        );
      }
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -0.01,
        1.01,
      ]) {
        expect(
          () => SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'door-sound',
            volume: value,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: ' ',
          volume: 1,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'world tone numeric fields refuse non finite and out of range values',
    () {
      for (final field in ['red', 'green', 'blue', 'gray']) {
        for (final value in <Object?>[
          double.nan,
          double.infinity,
          double.negativeInfinity,
          255.001,
          field == 'gray' ? -0.001 : -255.001,
          true,
          '0',
          null,
          [],
        ]) {
          expect(
            () => SceneInteractiveCommand.fromJson({...tone(), field: value}),
            throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
            reason: '$field=$value',
          );
        }
      }
    },
  );

  test('world tone duration is a required nonnegative int32', () {
    for (final value in <Object?>[
      -1,
      2147483648,
      0.0,
      double.nan,
      double.infinity,
      true,
      '300',
      null,
    ]) {
      expect(
        () =>
            SceneInteractiveCommand.fromJson({...tone(), 'durationMs': value}),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        reason: 'durationMs=$value',
      );
    }
    for (final field in ['red', 'green', 'blue', 'gray', 'durationMs']) {
      expect(
        () => SceneInteractiveCommand.fromJson(Map.of(tone())..remove(field)),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        reason: 'missing $field',
      );
    }
  });

  test(
    'world tone refuses unrepresented fields instead of silently dropping them',
    () {
      for (final field in ['alpha', 'waitForCompletion', 'persist', 'pitch']) {
        expect(
          () => SceneInteractiveCommand.fromJson({...tone(), field: 1}),
          throwsFormatException,
          reason: field,
        );
      }
    },
  );

  test('world tone identity includes all its components and duration', () {
    expect(() => SceneInteractiveCommand.fromJson(tone()), returnsNormally);
    final commands = {
      SceneInteractiveCommand.fromJson(tone()),
      SceneInteractiveCommand.fromJson(tone(red: -254)),
      SceneInteractiveCommand.fromJson(tone(green: -254)),
      SceneInteractiveCommand.fromJson(tone(blue: -254)),
      SceneInteractiveCommand.fromJson(tone(gray: 1)),
      SceneInteractiveCommand.fromJson(tone(durationMs: 301)),
    };
    expect(commands, hasLength(6));
    expect(commands.contains(SceneInteractiveCommand.fromJson(tone())), isTrue);
  });

  test('sound effect preserves its native media reference and volume', () {
    final wire = sound();
    expect(() => SceneInteractiveCommand.fromJson(wire), returnsNormally);
    final command = SceneInteractiveCommand.fromJson(wire);
    expect(
      command.runtimeType.toString(),
      'ScenePlaySoundEffectInteractiveCommand',
    );
    expect(command.toJson(), wire);
    expect(
      SceneInteractiveCommand.fromJson(
        jsonDecode(jsonEncode(command.toJson())) as Map<String, dynamic>,
      ),
      command,
    );
    expect(command.outputPortIds, ['completed', 'blocked']);
    expect({
      command,
      SceneInteractiveCommand.fromJson(sound(volume: 0.5)),
      SceneInteractiveCommand.fromJson({
        ...wire,
        'mediaAssetId': 'other-sound',
      }),
    }, hasLength(3));
  });

  test(
    'sound effect accepts silence and full volume without converting units',
    () {
      for (final volume in [0.0, 1.0]) {
        expect(
          () => SceneInteractiveCommand.fromJson(sound(volume: volume)),
          returnsNormally,
        );
        expect(
          SceneInteractiveCommand.fromJson(sound(volume: volume)).toJson(),
          sound(volume: volume),
        );
      }
    },
  );

  test('sound effect refuses invalid media references and volumes', () {
    for (final value in <Object?>['', ' ', 1, true, null, []]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          ...sound(),
          'mediaAssetId': value,
        }),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
    for (final value in <Object?>[
      -0.001,
      1.001,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      true,
      '0.8',
      null,
      [],
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({...sound(), 'volume': value}),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
    for (final field in ['mediaAssetId', 'volume']) {
      expect(
        () => SceneInteractiveCommand.fromJson(Map.of(sound())..remove(field)),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
  });

  test('sound effect refuses pitch and unknown unrepresented fields', () {
    for (final field in [
      'pitch',
      'waitForCompletion',
      'persist',
      'soundName',
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({...sound(), field: 100}),
        throwsFormatException,
        reason: field,
      );
    }
  });

  test(
    'native presentation descriptors are publishable with editor and runtime consumers',
    () {
      final catalog = NarrativeCommandCatalog.canonical();
      for (final id in ['worldTone', 'playSoundEffect']) {
        final descriptor = catalog.byId(id);
        expect(descriptor, isNotNull, reason: id);
        expect(descriptor!.wireId, 'SceneInteractiveCommand.$id');
        expect(
          descriptor.backend,
          NarrativeCommandBackend.interactiveRuntimeCommand,
        );
        expect(descriptor.isPersistent, isFalse);
        expect(descriptor.isPublishable, isTrue);
        expect(
          descriptor.capabilities.model,
          NarrativeCommandCapabilityStatus.supported,
        );
        expect(
          descriptor.capabilities.editor,
          NarrativeCommandCapabilityStatus.supported,
        );
        expect(
          descriptor.capabilities.runtime,
          NarrativeCommandCapabilityStatus.supported,
        );
        expect(descriptor.capabilities.reason, contains('2D'));
        expect(
          descriptor.parameters.every((parameter) => parameter.required),
          isTrue,
        );
      }
      final toneDescriptor = catalog.byId('worldTone')!;
      expect(toneDescriptor.parameters.map((parameter) => parameter.id), [
        'red',
        'green',
        'blue',
        'gray',
        'durationMs',
      ]);
      expect(
        toneDescriptor.parameters.map((parameter) => parameter.kind.name),
        ['number', 'number', 'number', 'number', 'integer'],
      );
      final soundDescriptor = catalog.byId('playSoundEffect')!;
      expect(soundDescriptor.parameters.map((parameter) => parameter.id), [
        'mediaAssetId',
        'volume',
      ]);
      expect(
        soundDescriptor.parameters.map((parameter) => parameter.kind.name),
        ['soundMediaReference', 'number'],
      );
      expect(
        catalog.publishable.any(
          (command) => ['worldTone', 'playSoundEffect'].contains(command.id),
        ),
        isTrue,
      );
    },
  );

  test(
    'no-code payload builder preserves presentation values without defaults',
    () {
      for (final wire in [
        tone(red: -18.5, green: 23, blue: 45, gray: 70, durationMs: 0),
        sound(volume: 0),
      ]) {
        expect(
          () => buildScenePayloadForNarrativeCommand(
            commandId: wire['kind'] as String,
            parameters: parameters(wire),
          ),
          returnsNormally,
        );
        final payload =
            buildScenePayloadForNarrativeCommand(
                  commandId: wire['kind'] as String,
                  parameters: parameters(wire),
                )
                as SceneActionPayload;
        expect(payload.interactiveCommand!.toJson(), wire);
        expect(
          SceneNodePayload.fromJson(
            jsonDecode(jsonEncode(payload.toJson())) as Map<String, dynamic>,
          ),
          payload,
        );
        expect(
          diagnoseInteractiveCommand(
            command: payload.interactiveCommand!,
            project: const ProjectManifest(name: 'QA', maps: [], tilesets: []),
          ).any((diagnostic) => diagnostic.code == NarrativeCommandDiagnosticCode.unsupportedCommand),
          isFalse,
        );
      }
    },
  );

  test(
    'no-code presentation values refuse malformed missing and unknown inputs',
    () {
      for (final wire in [tone(), sound()]) {
        final values = parameters(wire);
        for (final key in values.keys) {
          expect(
            () => buildScenePayloadForNarrativeCommand(
              commandId: wire['kind'] as String,
              parameters: Map.of(values)..remove(key),
            ),
            throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
          );
        }
        for (final value in ['invalid', 'NaN', 'Infinity']) {
          expect(
            () => buildScenePayloadForNarrativeCommand(
              commandId: wire['kind'] as String,
              parameters: {
                ...values,
                wire['kind'] == 'worldTone' ? 'red' : 'volume': value,
              },
            ),
            throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
          );
        }
        expect(
          () => buildScenePayloadForNarrativeCommand(
            commandId: wire['kind'] as String,
            parameters: {...values, 'pitch': '100'},
          ),
          throwsFormatException,
        );
      }
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: 'worldTone',
          parameters: {...parameters(tone()), 'durationMs': '300.0'},
        ),
        throwsFormatException,
      );
    },
  );

  test('existing warp and item payloads retain their defaults and wires', () {
    final warp = SceneInteractiveCommand.warp(
      destinationMapId: 'centre',
      warpId: 'arrival',
    );
    expect(SceneInteractiveCommand.fromJson(warp.toJson()), warp);
    expect(warp.toJson()['transition'], 'mapDefault');
    expect(warp.toJson().containsKey('arrivalFacing'), isFalse);
    final gift = SceneInteractiveCommand.giveItem(
      itemId: 'potion',
      quantity: 1,
    );
    expect(SceneInteractiveCommand.fromJson(gift.toJson()), gift);
    expect(gift.outputPortIds, ['received', 'bagFull']);
  });
}
