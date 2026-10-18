import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/source_town_map_original_fixture.dart';

final class _SourceFiles implements SourceFilePort {
  const _SourceFiles(this.source, this.root);
  final NormalizedSourceProject source;
  final String root;
  @override
  Future<List<int>> read(ConverterId id) {
    final file =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == id);
    validateSourceRelativePath(file.relativePath);
    return File('$root/${file.relativePath}').readAsBytes();
  }
}

final class _ReattestedFiles implements SourceFilePort {
  const _ReattestedFiles(this.delegate, this.fileId, this.bytes);
  final SourceFilePort delegate;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) =>
      id == fileId ? Future.value(List.of(bytes)) : delegate.read(id);
}

Future<(NormalizedSourceProject, SourceFilePort)>
    _sourceWithOverlappingBookshelf(
        NormalizedSourceProject source, SourceFilePort files) async {
  final entry = source.snapshot.entries
      .singleWhere((entry) => entry.relativePath == 'Data/Map102.rxdata');
  final archived = source.archive.files[entry.fileId]!;
  final document = archived.document;
  MarshalNode field(MarshalNode node, String name) =>
      document.node(node.instanceVariables
          .singleWhere((pair) => document.node(pair.key).name == name)
          .value);
  final events = field(document.node(document.rootId), '@events');
  final book = document.node(events.pairs
      .singleWhere(
          (pair) => document.node(pair.key).integerValue == BigInt.from(5))
      .value);
  final bytes = List<int>.of(archived.rawBytes);
  for (final change in [('@x', 6), ('@y', 4)]) {
    final node = field(book, change.$1);
    final offset = node.location.byteOffset;
    if (node.kind != MarshalKind.integer ||
        bytes[offset] != 0x69 ||
        bytes[offset + 1] != node.integerValue!.toInt() + 5) {
      throw StateError('Expected an exact small integer field.');
    }
    bytes[offset + 1] = change.$2 + 5;
  }
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      policyHash: source.snapshot.policyHash,
      entries: [
        for (final current in source.snapshot.entries)
          if (current.fileId != entry.fileId)
            current
          else
            SourceFileEntry(
                fileId: entry.fileId,
                relativePath: entry.relativePath,
                kind: entry.kind,
                byteLength: bytes.length,
                sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
                format: entry.format,
                family: entry.family)
      ],
      diagnostics: source.snapshot.diagnostics,
      excludedPaths: source.snapshot.excludedPaths,
      profileEvidence: source.snapshot.profileEvidence,
      state: source.snapshot.state);
  final reattested = _ReattestedFiles(files, entry.fileId, bytes);
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: reattested,
      selectedMapIds: {102},
      includeEventSystem: true);
  return (normalized, reattested);
}

SourceEventDefinition _replaceEvent(SourceEventDefinition event,
        {String? name, int? x, List<SourceEventPageAnalysis>? pages}) =>
    SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        identity: event.identity,
        sourceFileId: event.sourceFileId,
        locator: event.locator,
        name: name ?? event.name,
        x: x ?? event.x,
        y: event.y,
        pages: pages ?? event.pages);

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original healing display source projection', () {
    late SourceEventStudyComposition composition;
    late Directory output;
    late SourceEventAnalysis analysis;
    late SourceHealingDisplayBinding binding;
    late SourceCenterRecoveryBinding recovery;
    late SourceEventCharacterImport nurseCharacter;
    late MapData cleanMap;
    Map<String, SourceEventCharacterBinding> getCharacters() => {
          sourceEventCharacterBindingKey(
              characterName: 'NPC_FRLG_NURSE',
              pattern: 0,
              direction: 2): nurseCharacter.binding,
        };
    SourceEventProjection project(
            {bool bind = true,
            bool bindNurse = true,
            bool bindRecovery = true,
            MapData? nativeMap,
            SourceEventAnalysis? sourceAnalysis}) =>
        const SourceEventProjector().project(
            source: composition.draft.source,
            analysis: sourceAnalysis ?? analysis,
            nativeMaps: {102: nativeMap ?? cleanMap},
            healingDisplayBinding: bind ? binding : null,
            centerRecoveryBinding: bindRecovery ? recovery : null,
            characterBindings: bindNurse ? getCharacters() : const {});
    Map displayEvidence(SourceEventProjection projection) =>
        (projection.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) =>
                row['sourceIdentity'] ==
                composition.draft.source.eventIdentity(102, 4).value);

    setUpAll(() async {
      output = await Directory.systemTemp.createTemp('source-healing-display-');
      composition = await composeOriginalTownMapSource(
          archivePath: archive!,
          sourceRoot: root!,
          outputParentPath: output.path,
          limits:
              const NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048));
      final source = composition.draft.source;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      analysis = SourceEventAnalysis(
          profile: full.profile,
          events: [full.eventAt(102, 2)!, full.eventAt(102, 4)!],
          diagnostics: const []);
      final files = _SourceFiles(source, root);
      binding = (await const SourceHealingDisplayBindingResolver()
          .read(source: source, analysis: analysis, files: files))!;
      recovery = await const SourceCenterRecoveryResolver()
          .read(source: source, files: files);
      nurseCharacter = await const SourceEventCharacterImporter().read(
          snapshot: source.snapshot,
          files: files,
          charsetName: 'NPC_FRLG_NURSE',
          sourcePattern: 0,
          sourceDirection: 2);
      cleanMap = composition.projection.nativeMaps[102]!
          .copyWith(entities: const [], events: const []);
    });
    tearDownAll(() async {
      if (await output.exists()) await output.delete(recursive: true);
    });
    test('real seven-page object is admitted as one nonblocking native display',
        () {
      final projection = composition.projection;
      final identity = composition.draft.source.eventIdentity(102, 4).value;
      final row = (projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == identity);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final map = projection.nativeMaps[102]!;
      final display =
          map.entities.singleWhere((entity) => entity.healingDisplay != null);
      expect(display.pos, const GridPos(x: 7, y: 4));
      expect(display.kind, MapEntityKind.custom);
      expect(display.blocksMovement, false);
      expect(display.npc, isNull);
      expect(display.healingDisplay!.variantElementIds, hasLength(6));
      expect(
          map.layers
              .whereType<CollisionLayer>()
              .any((layer) => layer.collisions[4 * map.size.width + 7]),
          true);
      expect(projection.facts.where((fact) => fact.id.contains('variable_6')),
          isEmpty);
      expect(
          projection.scenes.where(
              (scene) => scene.metadata['sourceEventIdentity'] == identity),
          isEmpty);
      expect(row['nativeHealingDisplay'],
          containsPair('sourceVariable6Executed', false));
    });
    test('native assets and object precede the accepted nurse service consumer',
        () {
      final mutations = composition.draft.mutations;
      final object = mutations.indexWhere((mutation) =>
          mutation.actionId == 'entity.upsert' &&
          (mutation.parameters['entity'] as Map?)?['healingDisplay'] != null);
      expect(object, greaterThanOrEqualTo(0));
      final displayId = (mutations[object].parameters['entity'] as Map)['id'];
      final variants = mutations.asMap().entries.where((entry) =>
          entry.value.actionId == 'element.upsert' &&
          ((entry.value.parameters['element'] as Map)['id'] as String)
              .startsWith('source_healing_'));
      expect(variants, hasLength(6));
      expect(variants.every((entry) => entry.key < object), true);
      final nurseId = composition.draft.source.eventIdentity(102, 2).value;
      final nurse = composition.projection.scenes.singleWhere(
          (scene) => scene.metadata['sourceEventIdentity'] == nurseId);
      final heal = nurse.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneOpenHealInteractiveCommand>()
          .single;
      expect(heal.displayEntityId, displayId);
      expect(heal.requiresConfirmation, false);
      final sceneIndex = mutations.indexWhere((mutation) =>
          mutation.actionId == 'scene.upsert' &&
          (mutation.parameters['scene'] as Map?)?['id'] == nurse.id);
      expect(sceneIndex, greaterThan(object));
      expect(
          (composition.draft.compositionEvidence['sourceEvents']
              as Map)['healingDisplay'],
          isNotNull);
    });
    test('binding, recovery and actually admitted nurse are all required', () {
      for (final result in [
        project(bind: false),
        project(bindNurse: false),
        project(bindRecovery: false)
      ]) {
        expect(displayEvidence(result)['status'], 'quarantinedWholeEvent');
        expect(
            result.nativeMaps[102]!.entities
                .where((entity) => entity.healingDisplay != null),
            isEmpty);
      }
      final nurse = analysis.eventAt(102, 2)!;
      final changed = SourceEventAnalysis(profile: analysis.profile, events: [
        _replaceEvent(nurse, name: 'Other nurse'),
        analysis.eventAt(102, 4)!
      ], diagnostics: const []);
      expect(displayEvidence(project(sourceAnalysis: changed))['gaps'],
          contains('sourceHealingDisplayNurseNotAdmitted'));
    });
    test(
        'native healing remains available without the optional display binding',
        () {
      final result = project(bind: false);
      final commands = result.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneOpenHealInteractiveCommand>();
      expect(commands, hasLength(1));
      expect(commands.single.displayEntityId, isNull);
      expect(commands.single.requiresConfirmation, false);
    });
    test('source machine collision and complete native collision must agree',
        () {
      final collision = cleanMap.layers.whereType<CollisionLayer>().single;
      final cleared = List<bool>.of(collision.collisions)
        ..[4 * cleanMap.size.width + 7] = false;
      for (final values in [cleared, collision.collisions.sublist(1)]) {
        final map = cleanMap.copyWith(layers: [
          MapLayer.collision(
              id: collision.id, name: collision.name, collisions: values)
        ]);
        expect(displayEvidence(project(nativeMap: map))['gaps'],
            contains('sourceHealingDisplayMachineCollisionUnqualified'));
      }
    });
    test(
        'overlapping native footprint refuses the display without moving the object',
        () {
      final map = cleanMap.copyWith(entities: [
        MapEntity(
            id: 'occupied',
            name: 'occupied',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 6, y: 4),
            size: const GridSize(width: 2, height: 1),
            blocksMovement: true)
      ]);
      final result = project(nativeMap: map);
      expect(displayEvidence(result)['gaps'],
          contains('sourceHealingDisplayAnchorOccupied'));
      expect(
          result.nativeMaps[102]!.entities
              .where((entity) => entity.healingDisplay != null),
          isEmpty);
    });
    test('spatial representation and altered source position stay quarantined',
        () {
      expect(
          displayEvidence(project(
              nativeMap:
                  cleanMap.copyWith(version: ProjectVersion.v9)))['gaps'],
          contains('sourceHealingDisplaySpatialUnsupported'));
      final changed = SourceEventAnalysis(profile: analysis.profile, events: [
        analysis.eventAt(102, 2)!,
        _replaceEvent(analysis.eventAt(102, 4)!, x: 8)
      ], diagnostics: const []);
      expect(displayEvidence(project(sourceAnalysis: changed))['gaps'],
          contains('sourceHealingDisplaySourceBindingInvalid'));
    });
    test(
        'a freshly reattested source footprint covering the machine refuses the display',
        () async {
      final original = composition.draft.source;
      final (changed, files) = await _sourceWithOverlappingBookshelf(
          original, _SourceFiles(original, root!));
      final changedAnalysis = SourceEventAnalyzer.forProject(changed,
              profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      final book = changedAnalysis.eventAt(102, 5)!;
      expect((book.x, book.y), (6, 4));
      expect(book.name, 'Bookshelf size(2,1)');
      expect(changed.snapshot.canonicalHash,
          isNot(original.snapshot.canonicalHash));
      final display = (await const SourceHealingDisplayBindingResolver()
          .read(source: changed, analysis: changedAnalysis, files: files))!;
      final recovery = await const SourceCenterRecoveryResolver()
          .read(source: changed, files: files);
      final character = await const SourceEventCharacterImporter().read(
          snapshot: changed.snapshot,
          files: files,
          charsetName: 'NPC_FRLG_NURSE',
          sourcePattern: 0,
          sourceDirection: 2);
      final result = const SourceEventProjector().project(
          source: changed,
          analysis: changedAnalysis,
          nativeMaps: {102: cleanMap},
          healingDisplayBinding: display,
          centerRecoveryBinding: recovery,
          characterBindings: {
            sourceEventCharacterBindingKey(
                characterName: 'NPC_FRLG_NURSE',
                pattern: 0,
                direction: 2): character.binding
          });
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) =>
              row['sourceIdentity'] == changed.eventIdentity(102, 4).value);
      expect(row['gaps'], contains('sourceHealingDisplayAnchorOccupied'));
      expect(
          result.nativeMaps[102]!.entities
              .where((entity) => entity.healingDisplay != null),
          isEmpty);
    });
    test('the native display is excluded from the character import candidates',
        () {
      final candidates = const SourceEventProjector().characterImportCandidates(
          source: composition.draft.source,
          analysis: analysis,
          nativeMaps: {102: cleanMap},
          healingDisplayBinding: binding,
          centerRecoveryBinding: recovery);
      expect(candidates.map((event) => event.sourceEventId), [2]);
      final result = project();
      expect(result.facts, isEmpty);
      expect(result.scenes, hasLength(1));
      expect(
          result.registry.records
              .where((record) => record.definitionOrNull != null),
          hasLength(1));
    });
  },
      skip: archive == null || root == null
          ? 'Original source archive/root required.'
          : false);
}
