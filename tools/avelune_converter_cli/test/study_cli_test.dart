import '../../../packages/avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_cli/avelune_converter_cli.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';
import '../../../packages/avelune_converter_adapters/test/support/builtin_profile_source_fixture.dart';

void main() {
  late Directory root;
  late Directory output;
  late LiteralTileFixture fixture;
  late String planPath;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac16-cli-original-');
    output = Directory(await Directory('${root.path}/output')
        .create()
        .then((d) => d.resolveSymbolicLinks()));
    fixture =
        await LiteralTileFixture.create(sourceRootPath: '${root.path}/source');
    planPath = '${root.path}/original-plan.json';
  });
  tearDown(() async => root.delete(recursive: true));

  Future<({int code, String out, String err})> invoke(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runConverterCli(args, output: out, error: err);
    return (code: code, out: out.toString(), err: err.toString());
  }

  List<String> planArgs() => [
        'plan',
        '--source',
        fixture.sourceRootPath!,
        '--namespace',
        'original-ac16-cli',
        '--destination',
        '${output.path}/native-study',
        '--maps',
        '1',
        '--name',
        'Original offline CLI fixture',
        '--plan',
        planPath,
        '--ack-profile',
        '--offline',
        '--json'
      ];

  final knownArchivePath = Platform.environment['AVELUNE_KNOWN_SCRIPTS_ARCHIVE'];
  test('CLI detects the known source without a profile JSON and preserves literal opt out', () async {
    fixture = await builtinProfileSourceFixture(
        scriptsBytes: await File(knownArchivePath!).readAsBytes(),
        sourceRootPath: '${root.path}/known-source');
    final result = await invoke(planArgs());
    expect(result.code, 0, reason: result.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(recipe.settings.interpretationProfile?.profileId.value,
        'essentials-static-walking-events-items');
    final workflow = ConverterWorkflow();
    try {
      final prepared = await workflow.restoreStudyPlanRecipe(recipe);
      final events = prepared.nativeDraft!.compositionEvidence['sourceEvents'] as Map;
      final row = ((events['projection'] as Map)['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics');
      expect(row['gaps'], isEmpty);
      expect(prepared.previewPlan!.operations.any((op) => op.targetActionId == 'scene.upsert'), isTrue);
      expect(prepared.previewPlan!.approvedByHuman, isFalse);
      expect(await output.list().toList(), isEmpty);
    } finally {
      await workflow.dispose();
    }
    await File(planPath).delete();
    final literal = await invoke([...planArgs(), '--literal']);
    expect(literal.code, 0, reason: literal.err);
    expect((await const LocalStudyPlanStore().read(planPath)).settings.interpretationProfile, isNull);
    await File(planPath).delete();
    final explicit = File('${root.path}/explicit-profile.json');
    await explicit.writeAsString(jsonEncode({
      ...recipe.settings.interpretationProfile!.toJson(),
      'profileId': 'explicit-same-archive',
    }));
    final manual = await invoke([...planArgs(), '--literal',
        '--interpretation-profile', await explicit.resolveSymbolicLinks()]);
    expect(manual.code, 0, reason: manual.err);
    expect((await const LocalStudyPlanStore().read(planPath)).settings.interpretationProfile!.profileId.value,
        'explicit-same-archive');
  }, skip: !Platform.isMacOS || knownArchivePath == null);

  test('CLI content scope defaults to full and persists explicit world plans', () async {
    final planned = await invoke([...planArgs(), '--content', 'world']);
    expect(planned.code, 0, reason: planned.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(recipe.settings.contentScope, ConverterContentScope.world);
    final converted = await invoke(['convert', '--plan', planPath, '--approve-plan',
      recipe.approvedPlanHash.value, '--offline', '--json']);
    expect(converted.code, 0, reason: converted.err);
    expect(jsonDecode(converted.out)['sourceUnchanged'], isTrue);
    await File(planPath).delete();
    final full = await invoke([...planArgs(), '--destination', '${output.path}/full-study']);
    expect(full.code, 0, reason: full.err);
    expect((await const LocalStudyPlanStore().read(planPath)).settings.contentScope,
      ConverterContentScope.full);
    final invalid = await invoke([...planArgs(), '--content', 'partial']);
    expect(invalid.code, 2);
  }, skip: !Platform.isMacOS);

  test('CLI refuses item bindings in world scope without writing a plan', () async {
    final bindings = File('${root.path}/world-item-bindings.json');
    await bindings.writeAsString(jsonEncode([{
      'kind': 'sourceMissingItemBinding', 'version': 1, 'sourceSymbol': 'ETHER',
      'sourceSnapshotHash': '1' * 64, 'sourceFileId': 'original-donor-items',
      'sourceRelativePath': '_converter_sources/1/Data/items.dat',
      'sourceSha256': '2' * 64, 'reason': 'Explicit incompatible item choice',
      'humanConfirmed': true,
    }]));
    final result = await invoke([...planArgs(), '--content', 'world',
      '--missing-item-bindings', bindings.path]);
    expect(result.code, 2, reason: result.err);
    expect(result.err, contains('workflow.content_scope.item_bindings'));
    expect(File(planPath).existsSync(), isFalse);
    expect(Directory('${output.path}/native-study').existsSync(), isFalse);
  }, skip: !Platform.isMacOS);

  test('CLI inventories explicit source defects and replays their closed decisions', () async {
    fixture = await LiteralTileFixture.create(sourceRootPath: '${root.path}/defect-source', maps: [
      LiteralFixtureMap(id: 1, events: [const LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
        LiteralFixtureEventPage(tileId: 511, commands: [LiteralFixtureEventCommand(0, [])]),
      ])]),
    ]);
    final inspected = await invoke(['inspect-adaptations', '--source', fixture.sourceRootPath!,
      '--namespace', 'original-ac16-cli', '--maps', '1', '--offline', '--json']);
    expect(inspected.code, 0, reason: inspected.err);
    final inventory = jsonDecode(inspected.out) as Map;
    final issue = (inventory['issues'] as List).singleWhere((value) => value['allowedAction'] != null);
    final manifest = File('${root.path}/source-adaptations.json');
    await manifest.writeAsString(jsonEncode([issue['allowedAction']]));
    final planned = await invoke([...planArgs(), '--source-adaptations', manifest.path]);
    expect(planned.code, 0, reason: planned.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(recipe.settings.sourceAdaptations.single.kind, SourceEventAdaptationKind.omitInvalidEventTileGraphic);
    final converted = await invoke(['convert', '--plan', planPath, '--approve-plan',
      recipe.approvedPlanHash.value, '--offline', '--json']);
    expect(converted.code, 0, reason: converted.err);
    expect(jsonDecode(converted.out)['sourceUnchanged'], true);
  }, skip: !Platform.isMacOS);

  test('CLI explicitly selects persists and replays a source interpretation profile', () async {
    final profile = SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(), 'capabilities': ['events']});
    fixture = await LiteralTileFixture.create(sourceRootPath: '${root.path}/profile-source',
      scriptsBytes: syntheticInterpretationArchive, interpretationProfile: profile, includeEventSystem: true);
    final file = File('${root.path}/selected-profile.json');
    await file.writeAsString(jsonEncode(profile.toJson()));
    final planned = await invoke([...planArgs(), '--interpretation-profile', await file.resolveSymbolicLinks()]);
    expect(planned.code, 0, reason: planned.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(recipe.settings.interpretationProfile!.canonicalHash, profile.canonicalHash);
    await file.delete();
    final converted = await invoke(['convert', '--plan', planPath, '--approve-plan',
      recipe.approvedPlanHash.value, '--offline', '--json']);
    expect(converted.code, 0, reason: converted.err);
    expect(jsonDecode(converted.out)['sourceUnchanged'], isTrue);
  }, skip: !Platform.isMacOS);
  test('CLI rejects a mismatched selected profile without writing a plan or native project', () async {
    final file = File('${root.path}/selected-profile.json');
    await file.writeAsString(jsonEncode(syntheticSourceInterpretationProfile.toJson()));
    final planned = await invoke([...planArgs(), '--interpretation-profile', await file.resolveSymbolicLinks()]);
    expect(planned.code, 2, reason: planned.err);
    expect(planned.err, contains('interpretation_profile.source_mismatch'));
    expect(await File(planPath).exists(), isFalse);
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('CLI plans and publishes an explicit missing atlas image binding',
      () async {
    const original = 'Graphics/Tilesets/OriginalAtlas1.png';
    const backup = 'Graphics/Tilesets/OriginalAtlas1_backup.png';
    await File('${fixture.sourceRootPath}/$original')
        .rename('${fixture.sourceRootPath}/$backup');
    final planned = await invoke([
      ...planArgs(),
      '--atlas-binding',
      'Graphics/Tilesets/OriginalAtlas1=$backup',
    ]);
    expect(planned.code, 0, reason: planned.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(recipe.settings.imageBindings.single.sourceRelativePath, backup);
    final converted = await invoke([
      'convert',
      '--plan',
      planPath,
      '--approve-plan',
      recipe.approvedPlanHash.value,
      '--offline',
      '--json',
    ]);
    expect(converted.code, 0, reason: converted.err);
    expect(jsonDecode(converted.out)['published'], isTrue);
    expect(jsonDecode(converted.out)['sourceUnchanged'], isTrue);
    expect(await File('${fixture.sourceRootPath}/$original').exists(), isFalse);
  }, skip: !Platform.isMacOS);

  for (final directory in ['Graphics/Tilesets', 'graphics/tilesets']) {
    test('CLI preserves equals signs in atlas names under $directory',
        () async {
      const expected = 'Graphics/Tilesets/Terrain=Night';
      final backup = '$directory/Terrain=Night_backup.png';
      fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/equals-source',
        tilesets: [
          LiteralFixtureTileset(
            id: 1,
            imageName: 'Terrain=Night',
            imagePresent: false,
          ),
        ],
        extraFiles: {backup: literalFixtureAtlas()},
      );
      final planned = await invoke([
        ...planArgs(),
        '--atlas-binding',
        '$expected=$backup',
      ]);
      expect(planned.code, 0, reason: planned.err);
      final recipe = await const LocalStudyPlanStore().read(planPath);
      expect(recipe.settings.imageBindings.single.expectedReferencePath, expected);
      expect(recipe.settings.imageBindings.single.sourceRelativePath, backup);
    }, skip: !Platform.isMacOS);
  }

  test('CLI refuses invalid atlas bindings without creating a plan or project',
      () async {
    for (final value in [
      'no separator',
      '../Terrain=Graphics/Tilesets/OriginalAtlas1.png',
      'Graphics/Tilesets/OriginalAtlas1=/tmp/image.png',
      'Graphics/Tilesets/OriginalAtlas1=Graphics/Tilesets/absent.png',
    ]) {
      final result = await invoke([...planArgs(), '--atlas-binding', value]);
      expect(result.code, 2, reason: result.err);
      expect(await File(planPath).exists(), isFalse);
      expect(await output.list().toList(), isEmpty);
    }
    final duplicate = await invoke([
      ...planArgs(),
      for (var i = 0; i < 2; i++) ...[
        '--atlas-binding',
        'Graphics/Tilesets/OriginalAtlas1=Graphics/Tilesets/OriginalAtlas1.png',
      ],
    ]);
    expect(duplicate.code, 2);
    expect(await File(planPath).exists(), isFalse);
  }, skip: !Platform.isMacOS);

  test('plan convert verify use a saved exact offline workflow plan', () async {
    final planned = await invoke(planArgs());
    expect(planned.code, 0, reason: planned.err);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    expect(await Directory('${output.path}/native-study').exists(), isFalse);
    expect(recipe.settings.writeLimits.maxArtifacts, 4096);
    expect(recipe.settings.writeLimits.maxMutations, 32768);
    final restored = ConverterStudyPlanRecipe.fromJson(jsonDecode(planned.out));
    expect(restored.canonicalHash, recipe.canonicalHash);
    expect(restored.settings.writeLimits.maxArtifacts, 4096);
    expect(jsonDecode(planned.out)['approvedPlanHash'],
        recipe.approvedPlanHash.value);
    final converted = await invoke([
      'convert',
      '--plan',
      planPath,
      '--approve-plan',
      recipe.approvedPlanHash.value,
      '--offline',
      '--json'
    ]);
    expect(converted.code, 0, reason: converted.err);
    final native = jsonDecode(converted.out) as Map;
    expect(native['published'], isTrue);
    expect(native['playableCertified'], isFalse);
    expect(native['approvedPlanHash'], recipe.approvedPlanHash.value);
    final verified = await invoke([
      'verify',
      '--project',
      native['projectPath'] as String,
      '--offline',
      '--json'
    ]);
    expect(verified.code, 0, reason: verified.err);
    expect(
        jsonDecode(verified.out)['nativeRevision'], native['nativeRevision']);
    expect(await File('${fixture.sourceRootPath}/Data/Scripts.rxdata').exists(),
        isFalse);
  }, skip: !Platform.isMacOS);

  test('convert refuses a mismatched approval hash before native writes',
      () async {
    expect((await invoke(planArgs())).code, 0);
    final result = await invoke([
      'convert',
      '--plan',
      planPath,
      '--approve-plan',
      '0' * 64,
      '--offline'
    ]);
    expect(result.code, 7);
    expect(result.err, contains('workflow.stale_approval'));
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('convert rejects changed source and leaves destination untouched',
      () async {
    expect((await invoke(planArgs())).code, 0);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    await File('${fixture.sourceRootPath}/README.md')
        .writeAsString('Changed original fixture');
    final result = await invoke([
      'convert',
      '--plan',
      planPath,
      '--approve-plan',
      recipe.approvedPlanHash.value,
      '--offline'
    ]);
    expect(result.code, 7);
    expect(result.err, contains('workflow.source_changed'));
    expect(await output.list().toList(), isEmpty);
  }, skip: !Platform.isMacOS);

  test('cooperative interruption preserves native recovery paths and exits 130',
      () async {
    expect((await invoke(planArgs())).code, 0);
    final recipe = await const LocalStudyPlanStore().read(planPath);
    final signals = StreamController<void>();
    var interrupted = false;
    final err = _ObservedSink((line) {
      if (!interrupted && line.startsWith('writeNative: 1/')) {
        interrupted = true;
        signals.add(null);
      }
    });
    final out = StringBuffer();
    try {
      final code = await runConverterCli([
        'convert',
        '--plan',
        planPath,
        '--approve-plan',
        recipe.approvedPlanHash.value,
        '--offline',
        '--json',
        '--progress'
      ], output: out, error: err, cancellationSignals: signals.stream);
      expect(interrupted, isTrue);
      expect(code, 130);
      expect(out.toString(), isEmpty);
      final failure =
          jsonDecode(err.buffer.toString().trim().split('\n').last) as Map;
      expect(failure['code'], 'workflow.cancelled');
      expect(failure['promotionMayHaveOccurred'], isFalse);
      expect(await File(failure['journalPath'] as String).exists(), isTrue);
      expect(
          await Directory(failure['stagingPath'] as String).exists(), isTrue);
      expect(await Directory('${output.path}/native-study').exists(), isFalse);
    } finally {
      await signals.close();
    }
  }, skip: !Platform.isMacOS);

  test(
      'typed exit codes distinguish source blockers security stale native and cancellation',
      () {
    for (final entry in {
      'source.root_invalid': 3,
      'workflow.blocked': 4,
      'native.verify.failed': 5,
      'publication.destination.protected': 6,
      'source.platform_unsupported': 6,
      'workflow.source_changed': 7,
      'publication.destination.exists': 7,
      'workflow.cancelled': 130,
      'workflow.recipe.invalid': 2,
      'workflow.content_scope.item_bindings': 2,
      'workflow.content_scope.review': 2,
    }.entries) {
      expect(converterCliExitCode(entry.key), entry.value, reason: entry.key);
    }
  });

  test('each command requires explicit offline mode and refuses secret argv',
      () async {
    for (final args in [
      planArgs().where((arg) => arg != '--offline').toList(),
      ['convert', '--plan', planPath, '--approve-plan', '0' * 64],
      ['verify', '--project', output.path],
      [
        'verify',
        '--project',
        output.path,
        '--offline',
        '--api-key=synthetic-secret-never-echo'
      ]
    ]) {
      final result = await invoke(args);
      expect(result.code, 2);
      expect('${result.out}${result.err}',
          isNot(contains('synthetic-secret-never-echo')));
    }
  });
}

final class _ObservedSink implements StringSink {
  _ObservedSink(this.observe);
  final void Function(String) observe;
  final StringBuffer buffer = StringBuffer();
  @override
  void write(Object? value) => buffer.write(value);
  @override
  void writeln([Object? value = '']) {
    buffer.writeln(value);
    observe(value.toString());
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      buffer.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);
}
