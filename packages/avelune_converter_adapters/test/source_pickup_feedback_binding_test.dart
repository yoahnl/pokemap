import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_item_bindings.dart';
import 'package:avelune_converter_adapters/src/source_pickup_feedback_binding.dart';
import 'package:avelune_converter_adapters/src/source_map_music_binding.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart'
    show
        LiteralTileComposer,
        SourceSemanticStudyComposer,
        SourceEventStudyComposer;
import 'package:map_authoring/map_authoring.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';
import 'support/native_writer_fixture.dart';

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

final class _Object {
  const _Object(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

List<int> _packed(int value) {
  if (value == 0) return [0];
  if (value > 0 && value < 123) return [value + 5];
  if (value < 0 && value > -124) return [(value - 5) & 255];
  var width = 1;
  while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
    width++;
  }
  return [
    value >= 0 ? width : (-width) & 255,
    for (var i = 0; i < width; i++) (value >> (i * 8)) & 255
  ];
}

List<int> _value(Object? v) {
  if (v == null) return [0x30];
  if (v is bool) return [v ? 0x54 : 0x46];
  if (v is int) return [0x69, ..._packed(v)];
  if (v is _Symbol) {
    final s = utf8.encode(v.value);
    return [0x3a, ..._packed(s.length), ...s];
  }
  if (v is String) {
    final s = utf8.encode(v);
    return [0x22, ..._packed(s.length), ...s];
  }
  if (v is List) {
    return [0x5b, ..._packed(v.length), for (final x in v) ..._value(x)];
  }
  if (v is Map) {
    return [
      0x7b,
      ..._packed(v.length),
      for (final p in v.entries) ...[..._value(p.key), ..._value(p.value)]
    ];
  }
  if (v is _Object) {
    return [
      0x6f,
      ..._value(_Symbol(v.className)),
      ..._packed(v.fields.length),
      for (final p in v.fields.entries) ...[
        ..._value(_Symbol(p.key)),
        ..._value(p.value)
      ]
    ];
  }
  throw StateError('$v');
}

Map<String, Object?> _item(String symbol,
        {Map<String, Object?> patch = const {}}) =>
    {
      '@id': _Symbol(symbol),
      '@real_name': symbol == 'BURNHEAL'
          ? 'Burn Heal'
          : symbol == 'ETHER'
              ? 'Ether'
              : symbol,
      '@real_name_plural': symbol == 'BURNHEAL'
          ? 'Burn Heals'
          : symbol == 'ETHER'
              ? 'Ethers'
              : '${symbol}s',
      '@real_portion_name': null,
      '@real_portion_name_plural': null,
      '@pocket': 2,
      '@price': symbol == 'BURNHEAL' ? 200 : 600,
      '@sell_price': symbol == 'BURNHEAL' ? 50 : 300,
      '@bp_price': 1,
      '@field_use': 1,
      '@battle_use': symbol == 'ETHER' ? 2 : 1,
      '@flags': ['Fling_30'],
      '@consumable': true,
      '@show_quantity': null,
      '@move': null,
      '@real_description': 'Source description',
      '@pbs_file_suffix': '',
      ...patch
    };

const _audioPath = 'Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).wav';
const _machineAudioPath =
    'Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2)).wav';
const _skinPath = 'Graphics/Windowskins/speech hgss 1.png';
const _iconPath = 'Graphics/Icons/bagPocket2.png';

List<int> _dump(Object? value) => [4, 8, ..._value(value)];
List<int> _png(int width, int height,
    {bool dark = false, bool transparent = false}) {
  final raster = image.Image(width: width, height: height, numChannels: 4);
  raster.clear(image.ColorRgba8(
      dark ? 0 : 248, dark ? 0 : 248, dark ? 0 : 248, transparent ? 0 : 255));
  raster.setPixelRgba(0, 0, 1, 2, 3, 127);
  return image.encodePng(raster);
}

List<int> _wav() {
  final bytes = Uint8List(44 + 16000);
  final view = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, ascii.encode(value));
  text(0, 'RIFF');
  view.setUint32(4, bytes.length - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, 8000, Endian.little);
  view.setUint32(28, 16000, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  text(36, 'data');
  view.setUint32(40, 16000, Endian.little);
  return bytes;
}

final class _Fixture {
  const _Fixture(this.source, this.files, this.items);
  final NormalizedSourceProject source;
  final LiteralFixtureFiles files;
  final SourceEventItemBindings items;
}

Future<_Fixture> _fixture(
    {List<int>? scripts,
    int region = 1,
    bool dark = false,
    bool transparent = false,
    bool activeBgm = false,
    bool unknownBgm = false,
    int skinWidth = 96,
    int skinHeight = 48,
    Map<String, Object?> patch = const {},
    bool machine = false,
    String? movePbs,
    bool missingMetadata = false,
    bool missingIcon = false,
    bool missingAudio = false,
    bool duplicateAudio = false,
    List<int>? metadataBytes,
    List<int>? iconBytes,
    List<int>? audioBytes}) async {
  final original =
      await LiteralTileFixture.create(scriptsBytes: scripts, extraFiles: {
    'Data/items.dat': _dump({
      for (final symbol in machine ? ['TM101'] : ['BURNHEAL', 'ETHER'])
        _Symbol(symbol): _Object('GameData::Item', _item(symbol, patch: patch))
    }),
    if (movePbs != null) 'PBS/moves.txt': utf8.encode(movePbs),
    if (!missingMetadata)
      'Data/map_metadata.dat': metadataBytes ??
          _dump({
            1: _Object('GameData::MapMetadata', {
              '@id': 1,
              '@town_map_position': [region, 16, 5],
              '@real_name': 'Route 9'
            })
          }),
    if (!missingIcon) _iconPath: iconBytes ?? _png(18, 32),
    if (machine && !missingIcon)
      'Graphics/Icons/bagPocket4.png': iconBytes ?? _png(18, 32),
    _skinPath:
        _png(skinWidth, skinHeight, dark: dark, transparent: transparent),
    if (!missingAudio)
      (machine ? _machineAudioPath : _audioPath): audioBytes ?? _wav(),
    if (duplicateAudio)
      'Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).ogg': _wav(),
  });
  final bytes = {...original.sourceBytes};
  if (activeBgm || unknownBgm) {
    const mapPath = 'Data/Map001.rxdata';
    final raw = List<int>.from(bytes[mapPath]!);
    final doc = const MarshalDecoder().decode(raw, sourcePath: mapPath);
    final field = doc
        .node(doc.rootId)
        .instanceVariables
        .singleWhere((pair) => doc.node(pair.key).name == '@autoplay_bgm');
    raw[doc.node(field.value).location.byteOffset] = activeBgm ? 0x54 : 0x30;
    bytes[mapPath] = raw;
  }
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: original.snapshot.logicalProjectNamespace,
      policyHash: original.snapshot.policyHash,
      entries: [
        for (final entry in original.snapshot.entries)
          SourceFileEntry(
              fileId: entry.fileId,
              relativePath: entry.relativePath,
              kind: entry.kind,
              byteLength: bytes[entry.relativePath]!.length,
              sha256: literalFixtureHash(bytes[entry.relativePath]!),
              format: entry.format,
              family: entry.family)
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: original.snapshot.profileEvidence,
      state: SourceScanState.complete);
  final files = LiteralFixtureFiles(snapshot, bytes);
  final source = await const RmxpSourceNormalizer()
      .normalize(snapshot: snapshot, files: files);
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: snapshot,
      files: files,
      symbols: machine ? ['TM101'] : ['BURNHEAL', 'ETHER'],
      eventProfile: SourceEventProfile.kantoForProject(source));
  files.reads.clear();
  return _Fixture(source, files, items);
}

Future<SourcePickupFeedbackBinding> _read(_Fixture f,
        {String symbol = 'BURNHEAL',
        int sourceMapId = 1,
        NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation}) =>
    const SourcePickupFeedbackResolver().read(
        source: f.source,
        files: f.files,
        item: f.items.bindings[symbol]!,
        sourceMapId: sourceMapId,
        limits: limits,
        cancellation: cancellation);
Matcher _unavailable(String reason) =>
    throwsA(isA<SourcePickupBindingUnavailable>()
        .having((error) => error.reason, 'reason', reason));
Matcher _contract(String code) =>
    throwsA(isA<ContractError>().having((error) => error.code, 'code', code));

Future<_Fixture> _musicFixture(SourceMapMusicOracle oracle,
    {String namespace = 'pickup-music-fixture',
    bool includeSecondMusicMap = false}) async {
  final fixture = await SourceMapMusicFixture.create(
      oracle: oracle,
      namespace: namespace,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(
            id: 1,
            width: 4,
            height: 4,
            layers: [
              List.filled(16, 384),
              List.filled(16, 0),
              List.filled(16, 0)
            ],
            autoplayBgm: true,
            bgmName: 'Original Route',
            events: const [
              LiteralFixtureEvent(
                  id: 14,
                  x: 1,
                  y: 1,
                  name: 'HiddenItem',
                  pages: [
                    LiteralFixtureEventPage(through: true, commands: [
                      LiteralFixtureEventCommand(
                          111, [12, 'pbItemBall(:ETHER)']),
                      LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                      LiteralFixtureEventCommand(0, [], indent: 1),
                      LiteralFixtureEventCommand(412, []),
                      LiteralFixtureEventCommand(0, []),
                    ]),
                    LiteralFixtureEventPage(
                        selfSwitch: 'A',
                        through: true,
                        commands: [LiteralFixtureEventCommand(0, [])]),
                  ]),
            ]),
        if (includeSecondMusicMap)
          LiteralFixtureMap(
              id: 2, autoplayBgm: true, bgmName: 'Original Route'),
      ],
      extraFiles: {
        'Data/items.dat': _dump(
            {_Symbol('ETHER'): _Object('GameData::Item', _item('ETHER'))}),
        'Data/map_metadata.dat': _dump({
          1: _Object('GameData::MapMetadata', {
            '@id': 1,
            '@town_map_position': [1, 16, 5],
            '@real_name': 'Original Route'
          })
        }),
        _skinPath: _png(96, 48),
        _iconPath: _png(18, 32),
        _audioPath: _wav(),
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
        'Graphics/Characters/OriginalPlayer.png': _png(128, 192),
      });
  final items = await const SourceEventItemBindingResolver().read(
      snapshot: fixture.snapshot,
      files: fixture.files,
      symbols: ['ETHER'],
      eventProfile: SourceEventProfile.kantoForProject(fixture.source));
  return _Fixture(fixture.source, fixture.files, items);
}

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  List<int>? scripts;
  SourceMapMusicOracle? musicOracle;
  setUpAll(() async {
    if (scriptsPath != null) scripts = await File(scriptsPath).readAsBytes();
    if (scriptsPath != null) {
      musicOracle = await SourceMapMusicOracle.read(scriptsPath);
    }
  });

  group('qualified active map music', () {
    test('two source maps share one exact imported music asset', () async {
      final f = await _musicFixture(musicOracle!, includeSecondMusicMap: true);
      final temporary =
          await Directory.systemTemp.createTemp('ac13-shared-music-writer-');
      addTearDown(() => temporary.delete(recursive: true));
      final literal = await const LiteralTileComposer().compose(
          source: f.source,
          files: f.files,
          selectedSourceMapIds: [1, 2],
          projectName: 'Original shared music',
          parentPath: temporary.path,
          folderName: 'project');
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: f.source, files: f.files, base: literal))!;
      final composed = (await const SourceEventStudyComposer()
          .compose(source: f.source, files: f.files, base: semantic))!;
      final music = composed.musicBindings[1]!;
      expect(composed.musicBindings[2]!.mapMusicPath, music.mapMusicPath);
      expect(
          composed.draft.mutations.where((mutation) =>
              mutation.actionId == 'asset.import' &&
              mutation.parameters['logicalPath'] == music.mapMusicPath),
          hasLength(1));
      expect(
          composed.draft.mutations
              .where((mutation) => mutation.actionId == 'map.audio.update'),
          hasLength(2));
      final approval = approveNativeFixtureDraft(composed.draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, composed.draft);
      expect(receipt.verified, isTrue);
      for (final mapId in composed.draft.mapIds.values) {
        final json = jsonDecode(
            await File('${receipt.projectPath}/maps/$mapId.json')
                .readAsString()) as Map<String, dynamic>;
        final metadata = MapData.fromJson(json).mapMetadata;
        expect(metadata.musicPath, music.mapMusicPath);
        expect(metadata.musicVolume, closeTo(0.64, 0.000000001));
      }
    });

    test('pickup requires the exact map music binding and emits a music effect',
        () async {
      final f = await _musicFixture(musicOracle!);
      await expectLater(_read(f, symbol: 'ETHER'),
          _unavailable('pickup.feedback.bgm_active'));
      final music = (await const SourceMapMusicResolver()
          .read(source: f.source, files: f.files, sourceMapId: 1))!;
      final feedback = await const SourcePickupFeedbackResolver().read(
          source: f.source,
          files: f.files,
          item: f.items.bindings['ETHER']!,
          sourceMapId: 1,
          music: music);
      final cue = feedback.foundFeedback(cueId: 'found-ether').audioCue!;
      expect(cue.volume, closeTo(0.64, 0.000000001));
      expect(cue.role, DialogueAudioCueRole.musicEffect);
      expect(cue.bgmInterruption,
          DialogueBgmInterruption(fadeOutMs: 200, fadeInMs: 1000));
      expect(feedback.evidence['sourceBgmAutoplay'], isTrue);
      expect(feedback.evidence['sourceAudioGain'], 0.8);
      expect(feedback.evidence['nativeAudioGain'], music.nativeVolume);
      expect(feedback.evidence['sourceEngineAudioGainQualified'], isTrue);
      expect(feedback.evidence['sourceAudioPauseResumeQualified'], isFalse);
      expect(feedback.evidence['mapMusicBinding'], music.evidence);
    });

    test('a music binding from another snapshot cannot qualify a pickup',
        () async {
      final a = await _musicFixture(musicOracle!, namespace: 'music-a');
      final b = await _musicFixture(musicOracle!, namespace: 'music-b');
      final music = (await const SourceMapMusicResolver()
          .read(source: a.source, files: a.files, sourceMapId: 1))!;
      await expectLater(
          const SourcePickupFeedbackResolver().read(
              source: b.source,
              files: b.files,
              item: b.items.bindings['ETHER']!,
              sourceMapId: 1,
              music: music),
          _contract('source.pickup_feedback.music_binding'));
    });

    test(
        'native composition imports exact music after map save and refuses an altered gain',
        () async {
      final f = await _musicFixture(musicOracle!);
      final temporary =
          await Directory.systemTemp.createTemp('ac13-active-music-writer-');
      addTearDown(() => temporary.delete(recursive: true));
      final literal = await const LiteralTileComposer().compose(
          source: f.source,
          files: f.files,
          selectedSourceMapIds: [1],
          projectName: 'Original active music',
          parentPath: temporary.path,
          folderName: 'project');
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: f.source, files: f.files, base: literal))!;
      final composed = (await const SourceEventStudyComposer()
          .compose(source: f.source, files: f.files, base: semantic))!;
      final draft = composed.draft;
      final music = composed.musicBindings[1]!;
      expect(composed.projection.semanticEvidence['qualifiedEventCount'], 1,
          reason: jsonEncode(composed.projection.semanticEvidence));
      expect(composed.projection.semanticEvidence['quarantinedEventCount'], 0);
      final audioIndex =
          draft.mutations.indexWhere((m) => m.actionId == 'map.audio.update');
      expect(
          audioIndex,
          greaterThan(
              draft.mutations.indexWhere((m) => m.actionId == 'map.save')));
      expect(
          audioIndex,
          greaterThan(draft.mutations.indexWhere((m) =>
              m.actionId == 'asset.import' &&
              m.parameters['logicalPath'] == music.mapMusicPath)));
      final approved = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter()
          .write(approved.plan, approved.context, draft);
      expect(receipt.verified, isTrue);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final loaded = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        final map = loaded.mapById(draft.mapIds[1]!)!;
        expect(map.mapMetadata.musicPath, music.mapMusicPath);
        expect(map.mapMetadata.musicVolume, closeTo(0.64, 0.000000001));
        expect(
            await File('${receipt.projectPath}/${music.mapMusicPath}')
                .readAsBytes(),
            music.artifacts.single.bytes);
        final cue = loaded.manifest.scenes
            .expand((s) => s.graph.nodes)
            .map((n) => n.payload)
            .whereType<SceneYarnDialoguePayload>()
            .expand((p) => p.linePolicies)
            .map((p) => p.feedback.audioCue)
            .whereType<DialogueAudioCue>()
            .single;
        expect(cue.role, DialogueAudioCueRole.musicEffect);
        expect(cue.bgmInterruption,
            DialogueBgmInterruption(fadeOutMs: 200, fadeInMs: 1000));
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      final altered = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          compositionEvidence: draft.compositionEvidence,
          mutations: draft.mutations
              .map((m) => m.actionId == 'map.audio.update'
                  ? NativeMutation(
                      operationId: m.operationId,
                      actionId: m.actionId,
                      sourceEntityIds: m.sourceEntityIds,
                      targetEntityIds: m.targetEntityIds,
                      parameters: {...m.parameters, 'musicVolume': 1.0})
                  : m)
              .toList());
      final changedApproval = approveNativeFixtureDraft(altered);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (s, _, __) => stages.add(s))
              .write(changedApproval.plan, changedApproval.context, altered),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'native.semantics.regeneration')));
      expect(stages, isEmpty);
    });
  }, skip: scriptsPath == null || !Platform.isMacOS);

  test('unqualified scripts never invent pickup feedback', () async {
    final f = await _fixture();
    await expectLater(
        _read(f), _unavailable('pickup.feedback.profile_unqualified'));
    expect(f.files.reads, isEmpty);
  });

  group('qualified original script profile', () {
    test(
        'reproduces found and bag segments with attested cadence and canonical imports',
        () async {
      final f = await _fixture(scripts: scripts);
      final r = await _read(f);
      final found = r.foundFeedback(cueId: 'event-1-found');
      expect(found.plainText, 'You found a Burn Heal!');
      expect(found.revealIntervalMicros, 25000);
      expect(found.advance, DialogueLineAdvancePolicy.autoAfterReveal(2000000));
      expect(found.audioCue!.mediaAssetId, r.mediaId);
      expect(found.audioCue!.cueId, 'event-1-found');
      expect(found.audioCue!.volume, 0.8);
      expect(
          (found.segments[1] as DialogueTextSegment).style,
          DialogueSegmentStyle(
              colorArgb: 0xff0070f8, shadowColorArgb: 0xff78b8e8));
      expect(r.bagFeedback.plainText,
          "You put the Burn Heal in\nyour Bag's \uFFFCMedicine pocket.");
      expect(r.bagFeedback.advance, const DialogueLineAdvancePolicy.confirm());
      expect(r.bagFeedback.revealIntervalMicros, 25000);
      expect(r.bagFeedback.audioCue, isNull);
      final icon =
          r.bagFeedback.segments.whereType<DialogueIconSegment>().single;
      expect((icon.widthPx, icon.heightPx), (18, 32));
      expect(icon.assetId, r.iconTilesetId);
      expect(r.artifacts, hasLength(2));
      expect(r.artifacts.first.bytes, f.files.bytes[_iconPath]);
      expect(r.artifacts.last.bytes, f.files.bytes[_audioPath]);
      expect(r.mutations.map((m) => m.actionId),
          ['tileset.import_image', 'scene.dialogue.audioMedia.import']);
      expect(r.mutations.first.parameters['tileWidth'], 1);
      expect(r.mutations.first.parameters['tileHeight'], 1);
      expect(r.mutations.last.parameters['mediaId'], r.mediaId);
      expect(r.mutations.last.parameters['artifactHandle'],
          r.artifacts.last.handle);
      expect(r.mutations.every((m) => m.sourceEntityIds.isNotEmpty), isTrue);
      expect(r.metadataReference.contentHash, r.metadataFile.sha256);
      expect(r.evidence['requiredRuntimeContext'],
          'freshGameDefaultOptionsAndNoActiveBgm');
      expect(r.evidence['sourceScriptsExecuted'], 0);
      expect(() => r.evidence['changed'] = true, throwsUnsupportedError);
    });
    test(
        'uses the source ASCII vowel article and shares media operations across items',
        () async {
      final f = await _fixture(scripts: scripts);
      final b = await _read(f), e = await _read(f, symbol: 'ETHER');
      expect(e.foundFeedback(cueId: 'event-2-found').plainText,
          'You found an Ether!');
      expect(b.mutations.map((m) => m.operationId),
          e.mutations.map((m) => m.operationId));
      expect(canonicalHashOf(b.evidence),
          canonicalHashOf((await _read(f)).evidence));
    });
    test(
        'derives dark-skin colors from the sampled bitmap and reverses source color1',
        () async {
      final f = await _fixture(scripts: scripts, dark: true);
      final r = await _read(f);
      final texts = r
          .foundFeedback(cueId: 'dark')
          .segments
          .whereType<DialogueTextSegment>()
          .toList();
      expect(
          texts.first.style,
          DialogueSegmentStyle(
              colorArgb: 0xfff8f8f8, shadowColorArgb: 0xff485058));
      expect(
          texts[1].style,
          DialogueSegmentStyle(
              colorArgb: 0xff78b8e8, shadowColorArgb: 0xff0070f8));
    });
    test('transparent background samples select the exact source dark fallback',
        () async {
      final f = await _fixture(scripts: scripts, transparent: true);
      final r = await _read(f);
      expect(
          (r.foundFeedback(cueId: 'transparent').segments.first
                  as DialogueTextSegment)
              .style!
              .colorArgb,
          0xfff8f8f8);
    });
    test('refuses regions outside the bounded region1 contract', () async {
      final f = await _fixture(scripts: scripts, region: 0);
      await expectLater(
          _read(f), _unavailable('pickup.feedback.region_unsupported'));
    });
    test('missing metadata is a quarantinable source dependency', () async {
      final f = await _fixture(scripts: scripts, missingMetadata: true);
      await expectLater(
          _read(f), _unavailable('pickup.feedback.metadata_missing'));
    });
    test('malformed compiled region data is unavailable without extrapolation',
        () async {
      final f = await _fixture(
          scripts: scripts,
          metadataBytes: _dump({
            1: _Object('GameData::MapMetadata',
                {'@id': 1, '@town_map_position': '1,16,5'})
          }));
      await expectLater(
          _read(f), _unavailable('pickup.feedback.metadata_invalid'));
    });
    test(
        'active or unknown source autoplay BGM cannot qualify the no-BGM domain',
        () async {
      final active = await _fixture(scripts: scripts, activeBgm: true);
      await expectLater(
          _read(active), _unavailable('pickup.feedback.bgm_active'));
      final unknown = await _fixture(scripts: scripts, unknownBgm: true);
      await expectLater(
          _read(unknown), _unavailable('pickup.feedback.bgm_unqualified'));
    });
    test('key and machine items never receive ordinary item feedback',
        () async {
      final key = await _fixture(scripts: scripts, patch: {
        '@flags': ['KeyItem']
      });
      await expectLater(
          _read(key), _unavailable('pickup.feedback.item_unsupported'));
      final machine = await _fixture(
          scripts: scripts,
          patch: {'@field_use': 3, '@move': const _Symbol('AERIALACE')});
      await expectLater(
          _read(machine), _unavailable('pickup.feedback.item_unsupported'));
    });
    test('machine pickup feedback includes its attested source move name',
        () async {
      final f = await _fixture(
          scripts: scripts,
          machine: true,
          movePbs: '[AERIALACE]\nName = Aerial Ace\n',
          patch: {
            '@pocket': 4,
            '@field_use': 3,
            '@battle_use': 0,
            '@move': const _Symbol('AERIALACE'),
            '@consumable': false
          });
      final result = await _read(f, symbol: 'TM101');
      final found = result.foundFeedback(cueId: 'tm101-found');
      expect(found.plainText, 'You found TM101 Aerial Ace!');
      expect(found.advance, DialogueLineAdvancePolicy.autoAfterReveal(3500000));
      expect(result.bagFeedback.plainText,
          "You put the TM101 in\nyour Bag's \uFFFCTMs & HMs pocket.");
      expect(result.item.definition.machine, isNull);
      expect(result.item.useParity, SourceEventItemUseParity.unqualified);
      expect(result.audioFile.relativePath, _machineAudioPath);
      expect((result.evidence['bagFullFoundFeedback'] as Map)['segments'],
          isNotEmpty);
      expect(
          DialogueLineFeedback.fromJson(Map<String, dynamic>.from(
                  result.evidence['bagFullFoundFeedback'] as Map))
              .plainText,
          'You found TM101 Aerial Ace!');
      final full = DialogueLineFeedback.fromJson(
          Map<String, dynamic>.from(result.evidence['bagFullFeedback'] as Map));
      expect(full.plainText, 'But your Bag is full...');
      expect(full.advance, const DialogueLineAdvancePolicy.confirm());
      expect(full.audioCue, isNull);
      expect(result.evidence['nativeProjectMoveMachine'], isNull);
      expect(result.evidence['sourceMachineMove'],
          result.item.toJson()['sourceMachineMove']);
      expect(result.evidence['fullMachineUseParityQualified'], isFalse);
    });
    test('machine feedback refuses absent or injected move name witnesses',
        () async {
      for (final movePbs in <String?>[
        null,
        '[FLY]\nName = Fly\n',
        r'[AERIALACE]' '\n' r'Name = Aerial Ace\me[anything]' '\n',
      ]) {
        final f = await _fixture(
            scripts: scripts,
            machine: true,
            movePbs: movePbs,
            patch: {
              '@pocket': 4,
              '@field_use': 3,
              '@battle_use': 0,
              '@move': const _Symbol('AERIALACE'),
              '@consumable': false
            });
        await expectLater(_read(f, symbol: 'TM101'),
            _unavailable('pickup.feedback.machine_move_unqualified'));
        expect(f.files.reads, isEmpty);
      }
    });
    test('missing and ambiguous audio dependencies are quarantinable',
        () async {
      final missing = await _fixture(scripts: scripts, missingAudio: true);
      await expectLater(
          _read(missing), _unavailable('pickup.feedback.audio_missing'));
      final ambiguous = await _fixture(scripts: scripts, duplicateAudio: true);
      await expectLater(
          _read(ambiguous), _unavailable('pickup.feedback.audio_ambiguous'));
    });
    test('invalid original audio is unavailable after finite-duration probing',
        () async {
      final f = await _fixture(scripts: scripts, audioBytes: [1, 2, 3]);
      await expectLater(
          _read(f), _unavailable('pickup.feedback.audio_invalid'));
    });
    test('source byte and pixel quotas fail globally without invented feedback',
        () async {
      final f = await _fixture(scripts: scripts);
      await expectLater(
          _read(f, limits: const NativeWriteLimits(maxArtifactBytes: 16)),
          _contract('source.pickup_feedback.quota'));
      expect(f.files.reads, isEmpty);
      await expectLater(
          _read(f, limits: const NativeWriteLimits(maxImagePixels: 32)),
          _contract('source.pickup_feedback.quota'));
    });
    test('compiled metadata entry quotas are global failures', () async {
      final f = await _fixture(
          scripts: scripts,
          metadataBytes: _dump({
            for (var id = 0; id <= 4096; id++)
              id: _Object('GameData::MapMetadata', {
                '@id': id,
                '@town_map_position': [1, 16, 5]
              })
          }));
      await expectLater(_read(f), _contract('source.pickup_feedback.quota'));
    });
    test(
        'missing and malformed icon dependencies never produce invented pixels',
        () async {
      final missing = await _fixture(scripts: scripts, missingIcon: true);
      await expectLater(
          _read(missing), _unavailable('pickup.feedback.icon_missing'));
      final invalid = await _fixture(scripts: scripts, iconBytes: [1, 2, 3]);
      await expectLater(
          _read(invalid), _unavailable('pickup.feedback.icon_invalid'));
    });
    test('unsupported skin geometry remains a declared dependency gap',
        () async {
      final f =
          await _fixture(scripts: scripts, skinWidth: 128, skinHeight: 128);
      await expectLater(
          _read(f), _unavailable('pickup.feedback.skin_unsupported'));
    });
    test('source bytes changed after inventory fail globally', () async {
      final f = await _fixture(scripts: scripts);
      f.files.overrides[_iconPath] = [1, 2, 3];
      await expectLater(
          _read(f), _contract('source.pickup_feedback.source_changed'));
    });
    test(
        'artifact and mutation quotas are checked before dependent source reads',
        () async {
      final f = await _fixture(scripts: scripts);
      await expectLater(
          _read(f, limits: const NativeWriteLimits(maxArtifacts: 1)),
          _contract('source.pickup_feedback.quota'));
      expect(f.files.reads, isEmpty);
      await expectLater(
          _read(f, limits: const NativeWriteLimits(maxMutations: 1)),
          _contract('source.pickup_feedback.quota'));
      expect(f.files.reads, isEmpty);
    });
    test('cancelled reads never consume source dependencies', () async {
      final f = await _fixture(scripts: scripts);
      final cancellation = ScanCancellation()..cancel();
      await expectLater(
          _read(f, cancellation: cancellation), _contract('source.cancelled'));
      expect(f.files.reads, isEmpty);
    });
    test('a binding from another snapshot is rejected before dependency reads',
        () async {
      final first = await _fixture(scripts: scripts),
          second = await _fixture(scripts: scripts, dark: true);
      await expectLater(
          const SourcePickupFeedbackResolver().read(
              source: second.source,
              files: second.files,
              item: first.items.bindings['BURNHEAL']!,
              sourceMapId: 1),
          _contract('source.pickup_feedback.item_binding'));
      expect(second.files.reads, isEmpty);
    });
  },
      skip: scriptsPath == null
          ? 'Requires the read-only original Scripts.rxdata oracle via AVELUNE_AC13_SOURCE_SCRIPTS.'
          : false);
}
