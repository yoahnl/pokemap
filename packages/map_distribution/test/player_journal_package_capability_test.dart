import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  final clue = StorylineJournalClue(
    id: 'tracks',
    factId: 'saw_tracks',
    text: SceneLocalizedText(fallback: 'Des traces au nord.'),
  );
  final journalProject = ProjectManifest(
    name: 'Journal package',
    maps: [],
    tilesets: [],
    facts: [NarrativeFactDefinition(id: 'saw_tracks', label: 'Traces')],
    storylines: [
      StorylineAsset(
        id: 'main',
        type: StorylineType.main,
        title: 'Trame',
        chapters: [
          StorylineChapter(
            id: 'c1',
            title: 'Un',
            order: 0,
            steps: [
              StorylineStep(
                id: 'm1',
                title: 'Rival',
                order: 0,
                journal: StorylineMilestoneJournal(
                  title: SceneLocalizedText(fallback: 'Le rival'),
                  text: SceneLocalizedText(fallback: 'Il attend au labo.'),
                ),
              ),
            ],
          ),
        ],
        journalClues: [clue],
      ),
    ],
  );
  final plainProject = journalProject.copyWith(
    storylines: [
      StorylineAsset(
        id: 'main',
        type: StorylineType.main,
        title: 'Trame',
        chapters: [
          StorylineChapter(
            id: 'c1',
            title: 'Un',
            order: 0,
            steps: [StorylineStep(id: 'm1', title: 'Rival', order: 0)],
          ),
        ],
      ),
    ],
  );

  for (final portable in [false, true]) {
    Map<String, List<int>> payload(ProjectManifest value) {
      if (!portable) {
        return {
          'project/project.json': utf8.encode(jsonEncode(value.toJson())),
        };
      }
      final publication = PortableCatalogPublication.encodeProject(value);
      return {
        'project/project.json': utf8.encode(jsonEncode(publication.descriptor)),
        for (final object in publication.storage.objects.entries)
          'project/catalog/objects/${object.key}.json': object.value,
      };
    }

    List<String> base() => ['map@1', if (portable) 'catalog.partitioned@2'];

    test('journal data requires its capability portable=$portable', () {
      final files = payload(journalProject);
      final originals = {
        for (final entry in files.entries) entry.key: List<int>.of(entry.value),
      };

      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest(base()),
          payloadFiles: files,
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains(PlayerJournalCapabilities.capabilityId),
          ),
        ),
      );
      expect(files, originals);
    });

    test(
        'a declared journal installs on this Player and is refused by an '
        'older one portable=$portable', () {
      final built = const GamePackageBuilder().build(
        manifest: _manifest([
          ...base(),
          PlayerJournalCapabilities.capabilityId,
        ]),
        payloadFiles: payload(journalProject),
      );
      final host = AveluneRuntimeCompatibility.host();
      final older = GamePackageHostCompatibility(
        hubVersion: host.hubVersion,
        runtimeApiVersion: host.runtimeApiVersion,
        supportedRuntimeApiVersions: host.supportedRuntimeApiVersions,
        capabilities: host.capabilities.difference({
          PlayerJournalCapabilities.capabilityId,
        }),
        supportedProjectFormats: host.supportedProjectFormats,
        currentProjectFormat: host.currentProjectFormat,
        currentProjectFormats: host.currentProjectFormats,
        supportedSaveFormats: host.supportedSaveFormats,
      );
      final bytes = List<int>.of(built.packageBytes);

      expect(
        GamePackageInspector(
          hostCompatibility: host,
        ).inspect(built.packageBytes).compatibility?.decision,
        GamePackageCompatibilityDecision.accept,
      );
      expect(
        () => GamePackageInspector(
          hostCompatibility: older,
        ).inspect(built.packageBytes),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'capabilityUnsupported',
          ),
        ),
      );
      expect(
        const GamePackageCompatibilityEvaluator()
            .evaluate(built.manifest, older)
            .missingCapabilities,
        [PlayerJournalCapabilities.capabilityId],
      );
      expect(built.packageBytes, bytes);
      final restored = _project(built.manifest, built.packageBytes);
      expect(restored.storylines, journalProject.storylines);
    });

    test(
        'a project without journal keeps its historical capabilities '
        'portable=$portable', () {
      final built = const GamePackageBuilder().build(
        manifest: _manifest(base()),
        payloadFiles: payload(plainProject),
      );

      expect(
        GamePackageInspector(
          hostCompatibility: AveluneRuntimeCompatibility.host(),
        ).inspect(built.packageBytes).compatibility?.decision,
        GamePackageCompatibilityDecision.accept,
      );
      expect(
        built.manifest.compatibility.requiredCapabilities,
        isNot(contains(PlayerJournalCapabilities.capabilityId)),
      );
      expect(
        PlayerJournalCapabilities.requiresCapability(plainProject),
        isFalse,
      );
    });

    test('a clue note on a missing fact is refused portable=$portable', () {
      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest([
            ...base(),
            PlayerJournalCapabilities.capabilityId,
          ]),
          payloadFiles: payload(journalProject.copyWith(facts: const [])),
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains('unknown Fact saw_tracks'),
          ),
        ),
      );
    });
  }
}

ProjectManifest _project(GamePackageManifest manifest, List<int> bytes) {
  final files = {
    for (final file in ZipDecoder().decodeBytes(bytes).files)
      if (file.name != 'game-manifest.json') file.name: file.content,
  };
  return const GamePackageProjectValidator(GamePackageSecurityPolicy())
      .validate(
    manifest,
    Uint8List.fromList(files['project/project.json']!),
    payloadPaths: files.keys.toSet(),
    readPayload: (path) => files[path],
  );
}

GamePackageManifest _manifest(List<String> capabilities) {
  final json = spatialManifest(capabilities: capabilities).toJson();
  (json['compatibility'] as Map).addAll(<String, Object?>{
    'projectFormat': 'v8',
    'minHubVersion': '0.1.0',
    'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
  });
  return const GamePackageManifestCodec().decodeJson(json);
}
