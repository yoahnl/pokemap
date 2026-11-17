import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  final document =
      const YarnDialogueCompiler().compile('title: Start\n---\nBonjour\n===\n');
  final localization = DialogueLocalization(sourceLocale: 'fr', units: [
    DialogueTextUnit(
        id: 'greeting',
        binding: '/Start/0',
        kind: DialogueTextKind.line,
        source: 'Bonjour'),
  ]).translate('greeting', 'en', 'Hello');
  for (final spatial in [false, true]) {
    Map<String, List<int>> payload(
        {DialogueLocalization? catalog, Object? compiled}) {
      final files = spatial ? spatialPayload() : <String, List<int>>{};
      final source = spatial
          ? ProjectManifest.fromJson(
              jsonDecode(utf8.decode(files['project/project.json']!))
                  as Map<String, dynamic>)
          : ProjectManifest(name: 'Localized package', maps: [], tilesets: []);
      final project = source.copyWith(
        name: 'Localized package',
        dialogues: [
          ProjectDialogueEntry(
              id: 'talk',
              name: 'Accueil',
              relativePath: 'dialogues/talk.json',
              localization: catalog ?? localization)
        ],
      );
      return {
        ...files,
        'project/project.json': utf8.encode(jsonEncode(project.toJson())),
        'project/dialogues/talk.json':
            utf8.encode(jsonEncode(compiled ?? document.toJson())),
      };
    }

    GamePackageManifest manifest({bool capability = true}) {
      final json = spatialManifest(capabilities: [
        spatial ? 'map3d@1' : 'map@1',
        if (capability) dialogueLocalizationCapability,
      ]).toJson();
      (json['compatibility'] as Map).addAll(<String, Object?>{
        'projectFormat': spatial ? 'v9' : 'v8',
        'minHubVersion': '0.1.0',
        'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
      });
      json['locales'] = {
        'default': 'fr',
        'supported': ['fr', 'en', 'es']
      };
      return const GamePackageManifestCodec().decodeJson(json);
    }

    test('localized content requires its declared capability, spatial=$spatial',
        () {
      final files = payload();
      final original = jsonEncode(files);
      expect(
          () => const GamePackageBuilder().build(
              manifest: manifest(capability: false), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'code',
              'dialogueLocalizationCapabilityMissing')));
      expect(jsonEncode(files), original);
    });

    test(
        'current Player accepts variants and an older host rejects intact bytes, spatial=$spatial',
        () {
      final built = const GamePackageBuilder()
          .build(manifest: manifest(), payloadFiles: payload());
      final original = List<int>.of(built.packageBytes);
      final host = AveluneRuntimeCompatibility.host();
      final older = GamePackageHostCompatibility(
        hubVersion: host.hubVersion,
        runtimeApiVersion: host.runtimeApiVersion,
        supportedRuntimeApiVersions: host.supportedRuntimeApiVersions,
        capabilities:
            host.capabilities.difference({dialogueLocalizationCapability}),
        supportedProjectFormats: host.supportedProjectFormats,
        currentProjectFormat: host.currentProjectFormat,
        currentProjectFormats: host.currentProjectFormats,
        supportedSaveFormats: host.supportedSaveFormats,
      );
      expect(
          GamePackageInspector(hostCompatibility: host)
              .inspect(built.packageBytes)
              .compatibility
              ?.decision,
          GamePackageCompatibilityDecision.accept);
      expect(
          () => GamePackageInspector(hostCompatibility: older)
              .inspect(built.packageBytes),
          throwsA(isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'capabilityUnsupported')));
      expect(built.packageBytes, original);
    });

    test(
        'unknown compiled format and incoherent text bindings are refused, spatial=$spatial',
        () {
      for (final files in [
        payload(compiled: {...document.toJson(), 'format': 99}),
        payload(
            catalog: localization.withUnits([
          localization.units.single.copyWith(binding: '/Missing/0'),
        ])),
        payload(
            catalog: localization.withUnits([
          localization.units.single.copyWith(source: 'Changed'),
        ])),
        payload(
            catalog:
                localization.translate('greeting', 'en', '{{ fact.missing }}')),
        for (final feedback in [
          DialogueLineFeedback(segments: [
            DialogueTextSegment('Bon'),
            DialogueTextSegment('jour'),
          ]),
          DialogueLineFeedback(
              audioCue: DialogueAudioCue(
                  mediaAssetId: 'fanfare', cueId: 'item', revealOffset: 6)),
        ])
          payload(
              compiled: RuntimeDialogueDocument(nodes: [
            RuntimeDialogueNode(title: 'Start', steps: [
              RuntimeDialogueLine('Bonjour', feedback: feedback),
            ]),
          ]).toJson()),
      ]) {
        final before = jsonEncode(files);
        expect(
            () => const GamePackageBuilder()
                .build(manifest: manifest(), payloadFiles: files),
            throwsA(isA<GamePackageFormatException>().having(
                (error) => error.code, 'code', 'invalidDialogueLocalization')));
        expect(jsonEncode(files), before);
      }
    });
  }
}
