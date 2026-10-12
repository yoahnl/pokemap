import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as path;

import '../test/support/literal_tile_fixture.dart';
import '../test/support/native_writer_fixture.dart';

const ac14CatalogReferenceLimits = NativeWriteLimits(maxArtifacts: 128);
const ac14CatalogReferenceNamespace = 'original-ac14-catalog-reference';

final class Ac14CatalogReferenceComposition {
  Ac14CatalogReferenceComposition({
    required this.rootPath,
    required this.sourceFixture,
    required this.catalogs,
    required this.sourceScriptsPath,
    required Map<String, String> sourceHashes,
  }) : sourceHashes = Map.unmodifiable(sourceHashes);

  final String rootPath;
  final LiteralTileFixture sourceFixture;
  final SourceCatalogStudyComposition catalogs;
  final String sourceScriptsPath;
  final Map<String, String> sourceHashes;

  NativeProjectDraft get draft => catalogs.draft;
}

final class Ac14CatalogReferenceFixture {
  Ac14CatalogReferenceFixture({
    required this.manifestPath,
    required this.projectFilePath,
    required Map<String, Object?> evidence,
  }) : evidence = Map.unmodifiable(evidence);

  final String manifestPath;
  final String projectFilePath;
  final Map<String, Object?> evidence;
}

Future<Ac14CatalogReferenceComposition> composeAc14CatalogReferenceFixture({
  required String sourceScriptsPath,
  String? outputParentPath,
  bool largePbsWitness = false,
  bool largeProjectionEvidence = false,
  bool highMutationCount = false,
  bool includeBrokenReferences = true,
  String trainerCall = 'TrainerBattle.start(:CAMPER, "Jo", 2)',
  NativeWriteLimits limits = ac14CatalogReferenceLimits,
}) async {
  _require(
      path.isAbsolute(sourceScriptsPath), 'The archive path must be absolute');
  _require(
    await FileSystemEntity.type(sourceScriptsPath, followLinks: false) ==
        FileSystemEntityType.file,
    'The archive must be a regular file',
  );
  final archive = File(sourceScriptsPath);
  final archiveStat = await archive.stat();
  _require(archiveStat.size > 0 && archiveStat.size <= 16 * 1024 * 1024,
      'The archive exceeds its bounded profile');
  final scripts = await archive.readAsBytes();
  _require(_hash(scripts) == SourceEventProfile.kantoScriptsArchiveSha256,
      'The source profile requires the exact inert Kanto archive');
  final parent = outputParentPath == null
      ? Directory.systemTemp
      : Directory(outputParentPath);
  _require(path.isAbsolute(parent.path), 'The output parent must be absolute');
  final root = await parent.createTemp('ac14-catalog-reference-');
  final sourceRoot = Directory(path.join(root.path, 'original-source'));
  final destination =
      await Directory(path.join(root.path, 'native-output')).create();
  final padding = largePbsWitness || highMutationCount
      ? List.filled(highMutationCount ? 1700 : 280,
              '# ${List.filled(4090, 'x').join()}\n')
          .join()
      : '';
  final unknownFields = largeProjectionEvidence || highMutationCount
      ? [
          for (var index = 0; index < 40; index++)
            'OriginalUnknown${index.toString().padLeft(2, '0')} = ${List.filled(16384, 'x').join()}\n'
        ].join()
      : '';
  final fixture = await LiteralTileFixture.create(
    namespace: ac14CatalogReferenceNamespace,
    sourceRootPath: sourceRoot.path,
    scriptsBytes: scripts,
    includeEventSystem: true,
    selectedMapIds: includeBrokenReferences ? const {98, 99} : const {98},
    maps: [
      LiteralFixtureMap(
        id: 98,
        name: 'Original catalogue route',
        width: 5,
        height: 4,
        layers: [List.filled(20, 384), List.filled(20, 0), List.filled(20, 0)],
        events: [
          LiteralFixtureEvent(
            id: 1,
            x: 1,
            y: 1,
            name: 'Original trainer seed',
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalActor',
                commands: [
                  LiteralFixtureEventCommand(355, [trainerCall]),
                ],
              ),
            ],
          ),
          const LiteralFixtureEvent(
            id: 2,
            x: 3,
            y: 1,
            name: 'Original item seed',
            pages: [
              LiteralFixtureEventPage(
                characterName: 'OriginalActor',
                commands: [
                  LiteralFixtureEventCommand(
                      355, ['pbReceiveItem(:ORIGINALCURE)']),
                ],
              ),
            ],
          ),
        ],
      ),
      if (includeBrokenReferences)
        LiteralFixtureMap(
          id: 99,
          name: 'Original missing reference route',
          width: 4,
          height: 4,
          layers: [
            List.filled(16, 384),
            List.filled(16, 0),
            List.filled(16, 0)
          ],
          events: const [
            LiteralFixtureEvent(
              id: 1,
              x: 1,
              y: 1,
              name: 'Incomplete original trainer seed',
              pages: [
                LiteralFixtureEventPage(
                  characterName: 'OriginalActor',
                  commands: [
                    LiteralFixtureEventCommand(
                        355, ['pbTrainerBattle(:CAMPER, "Incomplete")']),
                  ],
                ),
              ],
            ),
          ],
        ),
    ],
    extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
      'Graphics/Characters/OriginalPlayer.png': _characterPng(48),
      'Graphics/Characters/OriginalActor.png': _characterPng(144),
      'PBS/pokemon.txt': utf8.encode(
          '$padding${_species('REEDLING', evolution: 'REEDWING')}$unknownFields${_species('REEDWING')}'),
      'PBS/pokemon_forms.txt': utf8.encode('''[REEDLING,1]
FormName = Shared name
Types = NORMAL
BaseStats = 32,42,52,62,72,82
'''),
      'PBS/types.txt': utf8.encode('[NORMAL]\nName = Normal\n'),
      'PBS/abilities.txt': utf8.encode(
          '[RUNAWAY]\nName = Run Away\nDescription = Original ability\n'),
      'PBS/moves.txt': utf8.encode('''[TACKLE]
Name = Tackle
Type = NORMAL
Category = Physical
Power = 40
Accuracy = 100
TotalPP = 35
Target = NearOther
FunctionCode = None
[ORIGINALMOVE]
Name = Original move
Type = NORMAL
Category = Physical
Power = 63
Accuracy = 91
TotalPP = 17
Priority = 1
Target = NearOther
FunctionCode = OriginalUnqualifiedEffect
'''),
      'PBS/items.txt': utf8.encode('''[ORIGINALCURE]
Name = Original cure
Pocket = 2
Price = 321
SellPrice = 123
Description = Original data without a qualified use
'''),
      'PBS/trainer_types.txt': utf8.encode('[CAMPER]\nName = Camper\n'),
      'PBS/trainers.txt': utf8.encode('''[CAMPER,Jo,2]
Pokemon = REEDLING,15
Moves = TACKLE,ORIGINALMOVE
${includeBrokenReferences ? '[CAMPER,Incomplete]\nItems = ORIGINALCURE\n' : ''}'''),
      'PBS/encounters.txt': utf8.encode(
          '[098]\nLand,11\n80,REEDLING,14,17\n70,REEDWING,13,17\n${includeBrokenReferences ? '[099]\nLand,19\n100,MISSING,7,9\n' : ''}'),
      'Data/species.dat': _marshal({
        for (final symbol in ['UNSELECTED', 'REEDWING', 'REEDLING'])
          _Symbol(symbol): _Object('GameData::Species', {
            '@id': _Symbol(symbol),
            '@species': _Symbol(symbol),
            '@form': 0,
          }),
        const _Symbol('REEDLING_1'): const _Object('GameData::Species', {
          '@id': _Symbol('REEDLING_1'),
          '@species': _Symbol('REEDLING'),
          '@form': 1,
        }),
      }),
    },
  );
  final sourceHashes = await ac14CatalogDirectoryHashes(sourceRoot.path);
  final literal = await const LiteralTileComposer().compose(
    source: fixture.source,
    files: fixture.files,
    selectedSourceMapIds: includeBrokenReferences ? const [98, 99] : const [98],
    projectName: 'Original catalogue conversion reference',
    parentPath: destination.path,
    folderName: 'converted-catalogues',
    sourceRootPath: sourceRoot.path,
    limits: limits,
  );
  final semantic = await const SourceSemanticStudyComposer().compose(
      source: fixture.source,
      base: literal,
      files: fixture.files,
      limits: limits);
  _require(semantic != null, 'The source semantics must qualify');
  final events = await const SourceEventStudyComposer().compose(
      source: fixture.source,
      base: semantic!,
      files: fixture.files,
      limits: limits);
  final catalogs = await const SourceCatalogStudyComposer().compose(
    source: fixture.source,
    base: events?.draft ?? semantic,
    files: fixture.files,
    limits: limits,
  );
  _require(catalogs != null, 'The source catalogue study must compose');
  _require(
      archiveStat.size == (await archive.stat()).size &&
          archiveStat.modified == (await archive.stat()).modified &&
          _hash(await archive.readAsBytes()) == _hash(scripts),
      'The external inert archive must remain unchanged');
  return Ac14CatalogReferenceComposition(
    rootPath: root.path,
    sourceFixture: fixture,
    catalogs: catalogs!,
    sourceScriptsPath: sourceScriptsPath,
    sourceHashes: sourceHashes,
  );
}

Future<Ac14CatalogReferenceFixture> buildAc14CatalogReferenceFixture({
  required String sourceScriptsPath,
  String? outputParentPath,
  bool largePbsWitness = false,
  bool largeProjectionEvidence = false,
  bool highMutationCount = false,
  String trainerCall = 'TrainerBattle.start(:CAMPER, "Jo", 2)',
}) async {
  final composition = await composeAc14CatalogReferenceFixture(
    sourceScriptsPath: sourceScriptsPath,
    outputParentPath: outputParentPath,
    largePbsWitness: largePbsWitness,
    largeProjectionEvidence: largeProjectionEvidence,
    highMutationCount: highMutationCount,
    trainerCall: trainerCall,
  );
  final draft = composition.draft;
  final approval = approveNativeFixtureDraft(draft);
  final receipt = await const NativeProjectWriter().write(
      approval.plan, approval.context, draft,
      limits: ac14CatalogReferenceLimits);
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final loader = ProjectSnapshotLoader(handles: handles);
  final opened = await opener.openProject(receipt.projectPath);
  late Map<String, Object?> validation;
  try {
    final native = await loader.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    _require(native.loadDiagnostics.isEmpty,
        'The generated native project must reopen strictly');
    validation =
        (await AuthoringReadApi(openService: opener, snapshotLoader: loader)
                .validateProject(opened.projectHandle))
            .toJson();
    _require(validation['valid'] == true,
        'The generated catalogue documents must validate canonically');
    for (final document in composition.catalogs.projection.documents) {
      final written = jsonDecode(
          await File(path.join(receipt.projectPath, document.relativePath))
              .readAsString());
      _require(canonicalJsonOf(written) == canonicalJsonOf(document.document),
          'Every generated catalogue document must match its projection');
    }
    _require(
        canonicalJsonOf(native.manifest.encounterTables
                .map((e) => e.toJson())
                .toList()) ==
            canonicalJsonOf(composition.catalogs.projection.encounterTables
                .map((e) => e.toJson())
                .toList()),
        'The written encounter inventory must match the projected slice');
    _require(
        canonicalJsonOf(
                native.manifest.trainers.map((e) => e.toJson()).toList()) ==
            canonicalJsonOf(composition.catalogs.projection.trainers
                .map((e) => e.toJson())
                .toList()),
        'The written trainer inventory must match the projected slice');
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
  final sourceHashesAfter = await ac14CatalogDirectoryHashes(
      composition.sourceFixture.sourceRootPath!);
  _require(
      canonicalJsonOf(composition.sourceHashes) ==
          canonicalJsonOf(sourceHashesAfter),
      'The original source must remain unchanged');
  _require(
      _hash(await File(sourceScriptsPath).readAsBytes()) ==
          SourceEventProfile.kantoScriptsArchiveSha256,
      'The external inert archive must remain unchanged after native writing');
  final projectFilePath = path.join(receipt.projectPath, 'project.json');
  final evidence = <String, Object?>{
    'kind': 'originalSourceConvertedCatalogReference',
    'version': 1,
    'projectFilePath': projectFilePath,
    'sourceRootPath': composition.sourceFixture.sourceRootPath,
    'sourceSnapshotHash':
        composition.sourceFixture.snapshot.canonicalHash.value,
    'sourceScriptsArchiveHash': SourceEventProfile.kantoScriptsArchiveSha256,
    'sourceHashesBefore': composition.sourceHashes,
    'sourceHashesAfter': sourceHashesAfter,
    'nativeHashes': await ac14CatalogDirectoryHashes(receipt.projectPath),
    'nativeDraftHash': draft.canonicalHash.value,
    'nativeRevision': receipt.nativeRevision,
    'nativeMutationCount': draft.mutations.length,
    'nativeArtifactCount':
        draft.artifacts.length + draft.sourceArtifacts.length,
    'nativeJsonArtifactMaxBytes': draft.artifacts
        .where((artifact) => artifact.reference.mediaType == 'application/json')
        .fold<int>(
            0,
            (maximum, artifact) => artifact.bytes.length > maximum
                ? artifact.bytes.length
                : maximum),
    'projectionByteLength': utf8
        .encode(canonicalJsonOf(composition.catalogs.projection.toJson()))
        .length,
    'sourceCatalogs': draft.compositionEvidence['sourceCatalogs'],
    'projection': composition.catalogs.projection.toJson(),
    'validation': validation,
    'largePbsWitness': largePbsWitness,
    'largeProjectionEvidence': largeProjectionEvidence,
    'highMutationCount': highMutationCount,
    'trainerCall': trainerCall,
    'sourceBattleScriptsExecuted': false,
    'battleAuthority': 'aveluneNative',
    'gameplayCertified': false,
    'aiCalls': 0,
  };
  final manifestPath =
      path.join(composition.rootPath, 'reference-manifest.json');
  await File(manifestPath).writeAsString(jsonEncode(evidence));
  return Ac14CatalogReferenceFixture(
      manifestPath: manifestPath,
      projectFilePath: projectFilePath,
      evidence: evidence);
}

Future<Map<String, String>> ac14CatalogDirectoryHashes(String root) async {
  final hashes = <String, String>{};
  await for (final entity
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      hashes[path.relative(entity.path, from: root)] =
          _hash(await entity.readAsBytes());
    }
  }
  final names = hashes.keys.toList()..sort();
  return {for (final name in names) name: hashes[name]!};
}

Future<void> main() async {
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  _require(scripts != null, 'AVELUNE_AC13_SOURCE_SCRIPTS is required');
  final fixture = await buildAc14CatalogReferenceFixture(
    sourceScriptsPath: scripts!,
    outputParentPath: Platform.environment['AVELUNE_AC14_REFERENCE_OUTPUT'],
    largePbsWitness: Platform.environment['AVELUNE_AC14_LARGE_PBS'] == '1',
    largeProjectionEvidence:
        Platform.environment['AVELUNE_AC14_LARGE_PROJECTION'] == '1',
    highMutationCount:
        Platform.environment['AVELUNE_AC14_HIGH_MUTATION_COUNT'] == '1',
  );
  stdout.writeln(jsonEncode({
    'manifestPath': fixture.manifestPath,
    'projectFilePath': fixture.projectFilePath,
    'battleAuthority': fixture.evidence['battleAuthority'],
    'gameplayCertified': fixture.evidence['gameplayCertified'],
  }));
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

String _hash(List<int> bytes) => crypto.sha256.convert(bytes).toString();

String _species(String symbol, {String? evolution}) => '''[$symbol]
Name = Shared name
Types = NORMAL
BaseStats = 31,41,51,61,71,81
GenderRatio = Female50Percent
GrowthRate = Medium
BaseExp = 59
CatchRate = 173
Happiness = 53
Abilities = RUNAWAY
Moves = 1,TACKLE,5,ORIGINALMOVE
EggGroups = Field
HatchSteps = 3840
Generation = 1
${evolution == null ? '' : 'Evolutions = $evolution,Level,20'}
''';

List<int> _characterPng(int red) {
  final raster = image.Image(width: 128, height: 128, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var y = 8; y < 32; y++) {
        for (var x = 8; x < 24; x++) {
          raster.setPixelRgba(column * 32 + x, row * 32 + y, red + column * 8,
              40 + row * 32, 112, 255);
        }
      }
    }
  }
  return image.encodePng(raster);
}

final class _Symbol {
  const _Symbol(this.value);
  final String value;
}

final class _Object {
  const _Object(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

List<int> _marshal(Object? value) => [4, 8, ..._value(value)];

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

List<int> _value(Object? value) {
  if (value == null) return [0x30];
  if (value is bool) return [value ? 0x54 : 0x46];
  if (value is int) return [0x69, ..._packed(value)];
  if (value is _Symbol || value is String) {
    final bytes = utf8.encode(value is _Symbol ? value.value : value as String);
    return [value is _Symbol ? 0x3a : 0x22, ..._packed(bytes.length), ...bytes];
  }
  if (value is List) {
    return [
      0x5b,
      ..._packed(value.length),
      for (final entry in value) ..._value(entry)
    ];
  }
  if (value is Map) {
    return [
      0x7b,
      ..._packed(value.length),
      for (final entry in value.entries) ...[
        ..._value(entry.key),
        ..._value(entry.value)
      ]
    ];
  }
  if (value is _Object) {
    return [
      0x6f,
      ..._value(_Symbol(value.className)),
      ..._packed(value.fields.length),
      for (final entry in value.fields.entries) ...[
        ..._value(_Symbol(entry.key)),
        ..._value(entry.value)
      ]
    ];
  }
  throw StateError('Unsupported original Marshal value: $value');
}
