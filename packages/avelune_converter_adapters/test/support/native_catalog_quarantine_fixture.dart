import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'literal_tile_fixture.dart';

Future<SourceCatalogStudyComposition> composeNativeCatalogQuarantineFixture({
  required String sourceRoot,
  required String outputParentPath,
  bool includeNativeTrainerConsumers = false,
}) async {
  final bundle = NativePsdkTrainerBundle.builtin();
  final extra = <String, List<int>>{};
  for (final name in [
    'pokemon',
    'pokemon_forms',
    'types',
    'abilities',
    'moves',
    'items',
    'trainer_types',
    'trainers',
    'metadata',
    'encounters',
  ]) {
    final path = 'PBS/$name.txt';
    extra[path] = await File('$sourceRoot/$path').readAsBytes();
  }
  final pbsFiles =
      await Directory('$sourceRoot/PBS').list(followLinks: false).toList();
  for (final file in pbsFiles.whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.endsWith('.txt')) extra['PBS/$name'] = await file.readAsBytes();
  }
  const oracle =
      'Plugins/[DBK_009] Animated Pokemon System/[008] Deluxe Bitmap.rb';
  for (final path in [
    oracle,
    'Data/species.dat',
    'Graphics/Characters/player_M.png'
  ]) {
    extra[path] = await File('$sourceRoot/$path').readAsBytes();
  }
  for (final species in bundle.speciesById.values
      .where((species) => species.forms.isBaseForm)) {
    for (final side in ['Front', 'Back']) {
      final path = 'Graphics/Pokemon/$side/${species.id.toUpperCase()}.png';
      extra[path] = await File('$sourceRoot/$path').readAsBytes();
    }
  }
  final keys = [
    ...(bundle.evidence['sourceTrainerKeys'] as List).cast<String>(),
    'FRLG_HIKER,Lenny',
    'FRLG_HIKER,Oliver',
    'FRLG_HIKER,Lucas',
    'FRLG_PICNICKER,Dana',
  ];
  final fixture = await LiteralTileFixture.create(
    namespace: 'native-catalog-quarantine',
    scriptsBytes: await File('$sourceRoot/Data/Scripts.rxdata').readAsBytes(),
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 98, width: 17, height: 2, layers: [
        List.filled(34, 384),
        List.filled(34, 0),
        List.filled(34, 0),
      ], events: [
        for (var index = 0; index < keys.length; index++)
          LiteralFixtureEvent(id: index + 1, x: index, y: 0, pages: [
            LiteralFixtureEventPage(commands: [
              LiteralFixtureEventCommand(111, [
                12,
                'TrainerBattle.start(:${keys[index].split(',').first}, "${keys[index].split(',').last}")',
              ]),
            ]),
          ]),
      ]),
      for (final id in [166, 205])
        LiteralFixtureMap(id: id, width: 2, height: 2, layers: [
          List.filled(4, 384),
          List.filled(4, 0),
          List.filled(4, 0),
        ]),
    ],
    extraFiles: extra,
  );
  final limits = sourceCatalogStudyWriteLimitsFor(3);
  final literal = await const LiteralTileComposer().compose(
    source: fixture.source,
    files: fixture.files,
    selectedSourceMapIds: [98, 166, 205],
    projectName: 'Native catalog quarantine fixture',
    parentPath: outputParentPath,
    folderName: 'native-catalog-quarantine',
    limits: limits,
  );
  final semantics = await const SourceSemanticStudyComposer().compose(
    source: fixture.source,
    base: literal,
    files: fixture.files,
    limits: limits,
  );
  var base = semantics!;
  if (includeNativeTrainerConsumers) {
    final consumers = <NativeMutation>[];
    for (var index = 0; index < 11; index++) {
      final key = keys[index].split(',');
      final trainerId = SourcePbsIdentity(
              namespace: fixture.snapshot.logicalProjectNamespace,
              family: SourcePbsFamily.trainers,
              trainerType: key.first,
              trainerName: key.last)
          .sourceId
          .value;
      final entity = MapEntity(
          id: 'native-trainer-$index',
          kind: MapEntityKind.npc,
          pos: GridPos(x: index, y: 1),
          npc: MapEntityNpcData(displayName: key.last, trainerId: trainerId));
      final scene = SceneAsset(
          id: 'native-battle-$index',
          name: 'Native battle',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'battle',
                kind: SceneNodeKind.battle,
                payload: SceneBattlePayload(
                    battleKind: 'trainer',
                    trainerId: trainerId,
                    declaredOutcomes: const ['victory', 'defeat'])),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: [
            SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'battle',
                kind: SceneEdgeKind.defaultFlow),
            SceneEdge(
                id: 'won',
                fromNodeId: 'battle',
                fromPortId: 'victory',
                toNodeId: 'end',
                kind: SceneEdgeKind.battleVictory),
            SceneEdge(
                id: 'lost',
                fromNodeId: 'battle',
                fromPortId: 'defeat',
                toNodeId: 'end',
                kind: SceneEdgeKind.battleDefeat),
          ]));
      final parameters = [
        (
          'entity.upsert',
          <String, Object?>{
            'mapId': base.mapIds[98]!,
            'entity': entity.toJson()
          }
        ),
        ('scene.upsert', <String, Object?>{'scene': scene.toJson()}),
      ];
      for (final value in index.isEven ? parameters : parameters.reversed) {
        consumers.add(NativeMutation(
            operationId: ConverterId('native-consumer-$index-${value.$1}'),
            actionId: value.$1,
            sourceEntityIds: base.mutations.first.sourceEntityIds,
            targetEntityIds: [ConverterId('native-consumer-$index')],
            parameters: value.$2,
            limits: limits));
      }
    }
    base = NativeProjectDraft(
        source: base.source,
        projectName: base.projectName,
        parentPath: base.parentPath,
        folderName: base.folderName,
        sourceRootPath: base.sourceRootPath,
        mapIds: base.mapIds,
        artifacts: base.artifacts,
        sourceArtifacts: base.sourceArtifacts,
        mutations: [...base.mutations, ...consumers],
        compositionEvidence: base.compositionEvidence,
        defaultMapWidth: base.defaultMapWidth,
        defaultMapHeight: base.defaultMapHeight,
        limits: limits);
  }
  return (await const SourceCatalogStudyComposer().compose(
    source: fixture.source,
    base: base,
    files: fixture.files,
    limits: limits,
  ))!;
}
