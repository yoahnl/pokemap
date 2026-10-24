import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_character_presentation_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_character_import.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_healing_display_binding.dart';
import 'package:avelune_converter_adapters/src/source_party_trade_binding.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/declared_program_fixture.dart';
import 'support/literal_tile_fixture.dart';

List<Map<String, dynamic>> _programs(Set<String> families) =>
    (jsonDecode(jsonEncode(fixtureSourceInterpretationProfile
            .toJson()['declaredPrograms'])) as List)
        .cast<Map<String, dynamic>>()
        .where((b) => families.contains(b['family']))
        .toList();

SourceInterpretationProfile _profile(List<Map<String, dynamic>> programs,
        Map<String, Object?>? presentation) =>
    SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'declaredPrograms': programs,
      if (presentation != null) 'presentationBindings': presentation
    });

Map<String, Object?> _pin(String path, List<int> bytes) =>
    {'relativePath': path, 'sha256': crypto.sha256.convert(bytes).toString()};

void main() {
  test('character case alias requires its exact admitted Windows source contract', () {
    final profile = syntheticSourceInterpretationProfile;
    final imageHash = Sha256Hash('c' * 64);
    SourceSnapshot snapshot({bool knownEngine = true, bool includeEngine = true,
        bool matchingScripts = true, bool duplicate = false,
        SourceScanState state = SourceScanState.complete,
        String path = 'Graphics/Characters/requested.png'}) => SourceSnapshot(
      logicalProjectNamespace: ConverterId('character-case-alias'),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: [
        SourceFileEntry(fileId: ConverterId('case-image'), relativePath: path,
            kind: SourceNodeKind.file, byteLength: 4, sha256: imageHash,
            format: 'raster', family: 'graphics'),
        if (duplicate) SourceFileEntry(fileId: ConverterId('case-duplicate'),
            relativePath: 'Graphics/Characters/Requested.png',
            kind: SourceNodeKind.file, byteLength: 4, sha256: imageHash,
            format: 'raster', family: 'graphics'),
        SourceFileEntry(fileId: ConverterId('case-scripts'),
            relativePath: 'Data/Scripts.rxdata', kind: SourceNodeKind.file,
            byteLength: 1, sha256: matchingScripts ? profile.scriptsArchiveHash
                : Sha256Hash('d' * 64), format: 'marshal', family: 'scripts'),
        if (includeEngine) SourceFileEntry(fileId: ConverterId('case-engine'),
            relativePath: 'Game.exe', kind: SourceNodeKind.file,
            byteLength: 14732288, sha256: Sha256Hash(knownEngine
                ? '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04'
                : 'e' * 64), format: 'binary', family: 'engine'),
      ], diagnostics: [], excludedPaths: [], profileEvidence: [],
      state: state);
    SourceCharacterPresentationBinding? resolve(SourceSnapshot source,
        {SourceInterpretationProfile? selected}) =>
        resolveSourceCharacterPresentation(snapshot: source,
            profile: selected ?? profile, charsetName: 'Requested');
    final binding = resolve(snapshot())!;
    expect(binding.requestedCharset, 'Requested');
    expect(binding.actualCharsetName, 'requested');
    expect(binding.actualSourceFile.relativePath, 'Graphics/Characters/requested.png');
    expect(binding.actualSourceFile.sha256, imageHash);
    expect(binding.substitution, isNull);
    expect(binding.toJson()['sourceVisualParity'], isTrue);
    expect(resolve(snapshot(knownEngine: false)), isNull);
    expect(resolve(snapshot(includeEngine: false)), isNull);
    expect(resolve(snapshot(matchingScripts: false)), isNull);
    expect(resolve(snapshot(state: SourceScanState.partial)), isNull);
    expect(resolve(snapshot(), selected: SourceInterpretationProfile.fromJson({
      ...profile.toJson(), 'capabilities': ['events'],
    })), isNull);
    expect(resolveSourceCharacterPresentation(snapshot: snapshot(),
        profile: null, charsetName: 'Requested'), isNull);
    expect(resolve(snapshot(path: 'Graphics/Characters/Other.png')), isNull);
    expect(() => snapshot(duplicate: true), throwsA(isA<ContractError>().having(
        (error) => error.code, 'code', 'source.snapshot_collision')));
    final declared = _profile([], {'characterSubstitutions': [{
      'requestedCharset': 'Requested', 'actualCharset': 'Available',
      'targetSha256': imageHash.value, 'reason': 'Selected artwork',
    }]});
    expect(resolve(snapshot(path: 'Graphics/Characters/available.png'),
        selected: declared), isNull);
  });

  test('character path lookup preserves exact priority and strict failures', () {
    final pin = Sha256Hash('a' * 64);
    final profile = _profile([], {
      'characterSubstitutions': [
        {
          'requestedCharset': 'Requested',
          'actualCharset': 'Available',
          'targetSha256': pin.value,
          'reason': 'Selected artwork',
        }
      ]
    });
    SourceSnapshot snapshot(List<(String, SourceNodeKind, Sha256Hash?)> files) =>
        SourceSnapshot(
            logicalProjectNamespace: ConverterId('character-index'),
            policyHash: Sha256Hash('b' * 64),
            entries: [
              for (var index = 0; index < files.length; index++)
                SourceFileEntry(fileId: ConverterId('character-file-$index'),
                    relativePath: files[index].$1, kind: files[index].$2,
                    byteLength: files[index].$2 == SourceNodeKind.file ? 4 : 0,
                    sha256: files[index].$3, format: 'png', family: 'image')
            ],
            diagnostics: [], excludedPaths: [], profileEvidence: [],
            state: SourceScanState.partial);
    SourceCharacterPresentationBinding? resolve(
            List<(String, SourceNodeKind, Sha256Hash?)> files,
            {String charset = 'Requested'}) =>
        resolveSourceCharacterPresentation(snapshot: snapshot(files),
            profile: profile, charsetName: charset);
    final alternate = ('Graphics/Characters/Available.png', SourceNodeKind.file, pin);

    final exact = resolve([
      ('Graphics/Characters/Requested.png', SourceNodeKind.file, Sha256Hash('c' * 64)),
      alternate,
    ])!;
    expect(exact.substitution, isNull);
    expect(exact.actualSourceFile.sha256, Sha256Hash('c' * 64));
    expect(resolve([alternate])!.substitution, isNotNull);
    for (final invalid in [
      [('Graphics/Characters/requested.PNG', SourceNodeKind.file, pin), alternate],
      [('Graphics/Characters/Requested.png', SourceNodeKind.directory, null), alternate],
      [('Graphics/Characters/Requested.png', SourceNodeKind.file, null), alternate],
      [('Graphics/Characters/Requested.png', SourceNodeKind.file, pin),
        ('Graphics/Characters/requested.PNG', SourceNodeKind.file, pin), alternate],
      [('Graphics/Characters/available.PNG', SourceNodeKind.file, pin)],
      [('Graphics/Characters/Available.png', SourceNodeKind.file, Sha256Hash('d' * 64))],
      [('Graphics/Characters/Available.png', SourceNodeKind.directory, null)],
      [('Graphics/Characters/Available.png', SourceNodeKind.file, null)],
    ]) {
      expect(resolve(invalid), isNull, reason: '$invalid');
    }
    expect(resolve([
      ('Graphics/Characters/Cafe\u0301.png', SourceNodeKind.file, pin),
    ], charset: 'Café'), isNull);
    expect(() => resolve([alternate], charset: '../escape'), throwsFormatException);
  });

  test(
      'explicit character substitution is strict by default and preserves declared trade presentation in two projects',
      () async {
    for (final mapId in [17, 91]) {
      final programs = _programs({'partyTrade'});
      final requested = 'RequestedActor$mapId', actual = 'AvailableActor$mapId';
      final pages = (programs.single['pages'] as Map)
          .values
          .cast<Map<String, dynamic>>()
          .toList();
      pages.single['graphic']['character_name'] = requested;
      final imageBytes = literalFixtureAtlas();
      final presentation = <String, Object?>{
        'characterSubstitutions': [
          {
            'requestedCharset': requested,
            'actualCharset': actual,
            'targetSha256': crypto.sha256.convert(imageBytes).toString(),
            'reason': 'Selected alternate artwork'
          }
        ]
      };
      Future<({NormalizedSourceProject source, LiteralFixtureFiles files})>
          fixture(
                  {bool selected = true,
                  bool includeRequested = false,
                  bool wrongPin = false}) =>
              createDeclaredProgramFixture(
                  namespace: 'presentation-$mapId',
                  profile: _profile(
                      programs,
                      selected
                          ? {
                              ...presentation,
                              if (wrongPin)
                                'characterSubstitutions': [
                                  {
                                    ...(presentation['characterSubstitutions']
                                            as List)
                                        .single as Map,
                                    'targetSha256': 'f' * 64
                                  }
                                ]
                            }
                          : null),
                  maps: {
                    mapId: [
                      DeclaredProgramFixtureEvent(
                          id: 23,
                          name: 'Exchange $mapId',
                          x: 4,
                          y: 4,
                          pages: pages)
                    ]
                  },
                  extraFiles: {
                    'Graphics/Characters/$actual.png': imageBytes,
                    if (includeRequested)
                      'Graphics/Characters/$requested.png': imageBytes
                  });
      final plain = await fixture(selected: false);
      expect(
          resolveSourceCharacterPresentation(
              snapshot: plain.source.snapshot,
              profile: plain.source.interpretationProfile,
              charsetName: requested),
          isNull);
      final wrong = await fixture(wrongPin: true);
      expect(
          resolveSourceCharacterPresentation(
              snapshot: wrong.source.snapshot,
              profile: wrong.source.interpretationProfile,
              charsetName: requested),
          isNull);
      final exact = await fixture(includeRequested: true);
      expect(
          resolveSourceCharacterPresentation(
                  snapshot: exact.source.snapshot,
                  profile: exact.source.interpretationProfile,
                  charsetName: requested)!
              .substitution,
          isNull);
      final selected = await fixture();
      final source = selected.source;
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      final event = analysis.eventAt(mapId, 23)!;
      final trade = const SourcePartyTradeBindingResolver().resolve(
          source: source,
          analysis: analysis,
          sourceMapId: mapId,
          sourceEventId: 23)!;
      expect(trade.visualAdaptation!.actualCharsetName, actual);
      final imported = await const SourceEventCharacterImporter().read(
          snapshot: source.snapshot,
          files: selected.files,
          charsetName: trade.visualAdaptation!.actualCharsetName,
          sourcePattern: 0,
          sourceDirection: 6);
      expect(imported.evidence['sourcePixelsResampled'], isFalse);
      final map = MapData(
          id: 'native-$mapId',
          name: 'Exchange',
          size: const GridSize(width: 64, height: 64),
          layers: [
            MapLayer.collision(
                id: 'collision',
                name: 'Collision',
                collisions: List.filled(4096, false))
          ]);
      final projected = const SourceEventProjector()
          .project(source: source, analysis: analysis, nativeMaps: {
        mapId: map
      }, partyTradeBinding: {
        event.identity: trade
      }, characterBindings: {
        sourceEventCharacterBindingKey(
            characterName: requested,
            pattern: 0,
            direction: 6): imported.binding
      });
      expect(projected.scenes, hasLength(1));
      expect(projected.nativeMaps[mapId]!.entities.single.npc!.characterId,
          imported.character.id);
      selected.files.overrides['Graphics/Characters/$actual.png'] = [
        ...imageBytes
      ]..[imageBytes.length - 1] ^= 1;
      await expectLater(
          const SourceEventCharacterImporter().read(
              snapshot: source.snapshot,
              files: selected.files,
              charsetName: actual,
              sourcePattern: 0,
              sourceDirection: 6),
          throwsA(isA<ContractError>()));
    }
  });

  test(
      'healing sheets rectangles and cadence are selected data with exact byte attestation',
      () async {
    for (final mapId in [19, 82]) {
      final programs = _programs({'centerNurse', 'healingDisplay'});
      final display =
          programs.singleWhere((b) => b['family'] == 'healingDisplay');
      final bytes = literalFixtureAtlas();
      final path = 'Graphics/Characters/Display$mapId.png';
      final declaration = <String, Object?>{
        'healingDisplay': {
          'sheets': [
            {
              'asset': _pin(path, bytes),
              'pixelWidth': 256,
              'pixelHeight': 64,
              'tileWidth': 32,
              'tileHeight': 16
            }
          ],
          'variants': [
            for (var count = 1; count <= 6; count++)
              {
                'count': count,
                'sheetIndex': 0,
                'frames': [
                  {
                    'x': count,
                    'y': 1,
                    'width': 1,
                    'height': 1,
                    'durationMs': 73 + count
                  },
                  {
                    'x': count,
                    'y': 2,
                    'width': 1,
                    'height': 1,
                    'durationMs': 101 + count
                  }
                ]
              }
          ]
        }
      };
      Future<({NormalizedSourceProject source, LiteralFixtureFiles files})>
          fixture({Map<String, Object?>? presentation}) =>
              createDeclaredProgramFixture(
                  namespace: 'healing-$mapId',
                  profile: _profile(programs, presentation),
                  maps: {
                    mapId: [
                      for (final b in programs)
                        DeclaredProgramFixtureEvent(
                            id: b == display ? 4 : 9,
                            name: 'Service',
                            x: 4,
                            y: 4,
                            pages: (b['pages'] as Map)
                                .values
                                .map((v) => Map<String, Object?>.from(v as Map))
                                .toList())
                    ]
                  },
                  extraFiles: {
                    path: bytes
                  });
      Future<SourceHealingDisplayBinding?> bind(
              ({
                NormalizedSourceProject source,
                LiteralFixtureFiles files
              }) fixture) =>
          const SourceHealingDisplayBindingResolver().read(
              source: fixture.source,
              analysis: SourceEventAnalyzer.forProject(fixture.source,
                      profile: SourceEventProfile.forProject(fixture.source))
                  .analyze(),
              sourceMapId: mapId,
              sourceEventId: 4,
              files: fixture.files);
      final plain = await fixture();
      await expectLater(
          bind(plain),
          throwsA(isA<SourceHealingDisplayBindingUnavailable>().having(
              (e) => e.reason, 'reason', 'source_image_unqualified')));
      final selected = await fixture(presentation: declaration);
      final binding = (await bind(selected))!;
      expect(binding.artifacts, hasLength(1));
      expect(binding.elements, hasLength(6));
      expect(binding.elements.first.frames.first.source,
          const TilesetSourceRect(x: 1, y: 1));
      expect(binding.elements.first.frames.first.durationMs, 74);
      expect(binding.elements.last.frames.last.durationMs, 107);
      expect(binding.mutations.first.parameters['tileWidth'], 32);
      expect(binding.evidence['declaredPresentation'],
          declaration['healingDisplay']);
      expect(binding.artifacts.single.bytes, bytes);
      await expectLater(
          const SourceHealingDisplayBindingResolver().read(
              source: selected.source,
              analysis: SourceEventAnalyzer.forProject(selected.source,
                      profile: SourceEventProfile.forProject(selected.source))
                  .analyze(),
              sourceMapId: mapId,
              sourceEventId: 4,
              files: selected.files,
              limits: const NativeWriteLimits(maxMutations: 7)),
          throwsA(isA<NativeWriteException>()));
      selected.files.overrides[path] = [...bytes]..[bytes.length - 1] ^= 1;
      await expectLater(bind(selected), throwsA(isA<ContractError>()));
      final wrong = jsonDecode(jsonEncode(declaration)) as Map<String, dynamic>;
      wrong['healingDisplay']['sheets'][0]['asset']['sha256'] = 'e' * 64;
      await expectLater(bind(await fixture(presentation: wrong)),
          throwsA(isA<SourceHealingDisplayBindingUnavailable>()));
    }
  });
}
