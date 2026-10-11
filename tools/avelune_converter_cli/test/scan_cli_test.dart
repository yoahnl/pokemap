import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_cli/avelune_converter_cli.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Future<({int exitCode, String output, String error})> invoke(
    List<String> arguments) async {
  final output = StringBuffer();
  final error = StringBuffer();
  final exitCode =
      await runConverterCli(arguments, output: output, error: error);
  return (
    exitCode: exitCode,
    output: output.toString(),
    error: error.toString()
  );
}

Future<Map<String, String>> sourceFingerprint(Directory source) async {
  final fingerprint = <String, String>{};
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    final path = entity.path.substring(source.path.length + 1);
    final kind = await FileSystemEntity.type(entity.path, followLinks: false);
    if (kind == FileSystemEntityType.directory) {
      fingerprint[path] = 'directory';
    } else if (kind == FileSystemEntityType.link) {
      fingerprint[path] = 'link:${await Link(entity.path).target()}';
    } else if (kind == FileSystemEntityType.file) {
      fingerprint[path] =
          'file:${canonicalHashOf(await File(entity.path).readAsBytes()).value}';
    } else {
      fingerprint[path] = kind.toString();
    }
  }
  return fingerprint;
}

void main() {
  late Directory temporary;
  late Directory source;

  setUp(() async {
    final created =
        await Directory.systemTemp.createTemp('avelune_converter_cli_test_');
    temporary = Directory(await created.resolveSymbolicLinks());
    source = await Directory('${temporary.path}/source').create();
    await Directory('${source.path}/Data').create();
    await Directory('${source.path}/Empty').create();
    await File('${source.path}/Data/Map001.rxdata').writeAsString('hello');
    await File('${source.path}/.env')
        .writeAsString('private-canary-not-for-output');
  });

  tearDown(() async {
    if (await temporary.exists()) {
      await temporary.delete(recursive: true);
    }
  });

  List<String> scanArguments({String? path, bool json = true}) => [
        'scan',
        '--source',
        path ?? source.path,
        '--namespace',
        'fixture-project',
        '--offline',
        if (json) '--json',
      ];

  for (final arguments in [
    ['--help'],
    ['scan', '--help'],
  ]) {
    test('${arguments.join(' ')} succeeds without scanning', () async {
      final before = await sourceFingerprint(source);
      final result = await invoke(arguments);

      expect(result.exitCode, 0);
      expect(result.output, isNotEmpty);
      expect(result.output.toLowerCase(), contains('scan'));
      expect(result.error, isEmpty);
      expect(await sourceFingerprint(source), before);
    });
  }

  final invalidArguments = <String, List<String> Function()>{
    'missing command': () => [],
    'unknown command': () => ['extract'],
    'missing source and namespace': () => ['scan', '--offline'],
    'missing source': () =>
        ['scan', '--namespace', 'fixture-project', '--offline'],
    'missing namespace': () => ['scan', '--source', source.path, '--offline'],
    'missing offline mode': () =>
        ['scan', '--source', source.path, '--namespace', 'fixture-project'],
    'relative source': () => [
          'scan',
          '--source',
          'relative-source',
          '--namespace',
          'fixture-project',
          '--offline'
        ],
    'invalid namespace': () => [
          'scan',
          '--source',
          source.path,
          '--namespace',
          'invalid namespace',
          '--offline'
        ],
    'unknown option': () => [...scanArguments(), '--unknown-option'],
    'unexpected positional argument': () => [...scanArguments(), 'extra'],
  };
  for (final arguments in invalidArguments.entries) {
    test('${arguments.key} returns usage error without source mutation',
        () async {
      final before = await sourceFingerprint(source);
      final result = await invoke(arguments.value());

      expect(result.exitCode, 2);
      expect(result.error, isNotEmpty);
      expect(await sourceFingerprint(source), before);
    });
  }

  for (final joined in [false, true]) {
    test('API key option is refused without echoing its value ($joined)',
        () async {
      const secret = 'synthetic-key-do-not-echo-9f37';
      final result = await invoke([
        ...scanArguments(),
        if (joined) '--api-key=$secret' else '--api-key',
        if (!joined) secret,
      ]);

      expect(result.exitCode, 2);
      expect(result.error, isNotEmpty);
      expect('${result.output}${result.error}', isNot(contains(secret)));
    });
  }

  test('a complete JSON scan leaves source bytes and directories unchanged',
      () async {
    final before = await sourceFingerprint(source);
    final result = await invoke(scanArguments());

    expect(result.exitCode, Platform.isMacOS ? 0 : 3);
    expect(await sourceFingerprint(source), before);
    expect('${result.output}${result.error}',
        isNot(contains('private-canary-not-for-output')));
    if (!Platform.isMacOS) {
      return;
    }
    expect(result.error, isEmpty);
    final snapshot = jsonDecode(result.output) as Map<String, dynamic>;
    expect(snapshot['state'], 'complete');
    expect(snapshot['logicalProjectNamespace'], 'fixture-project');
    expect(snapshot['canonicalHash'], matches(RegExp(r'^[a-f0-9]{64}$')));
    final entries = snapshot['entries'] as List;
    final map = entries
        .cast<Map>()
        .singleWhere((entry) => entry['relativePath'] == 'Data/Map001.rxdata');
    expect(map['sha256'],
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');
    expect(entries.cast<Map>().map((entry) => entry['relativePath']),
        containsAll(['Data', 'Empty', 'Data/Map001.rxdata']));
    expect(snapshot['excludedPaths'], contains('.env'));
  });

  test('a plain scan prints a compact readable summary', () async {
    final before = await sourceFingerprint(source);
    final result = await invoke(scanArguments(json: false));

    expect(result.exitCode, Platform.isMacOS ? 0 : 3);
    expect(await sourceFingerprint(source), before);
    if (!Platform.isMacOS) {
      return;
    }
    expect(result.error, isEmpty);
    expect(result.output, isNotEmpty);
    expect(result.output, contains('complete'));
    expect(result.output.trimLeft().startsWith('{'), isFalse);
    expect(result.output, isNot(contains('private-canary-not-for-output')));
  });

  test('an absent source directory is a scan failure', () async {
    final result = await invoke(
        scanArguments(path: '${temporary.path}/directory-that-does-not-exist'));

    expect(result.exitCode, 3);
    expect(result.error, isNotEmpty);
  });

  test('a file cannot be scanned as a source root', () async {
    final result =
        await invoke(scanArguments(path: '${source.path}/Data/Map001.rxdata'));

    expect(result.exitCode, 3);
    expect(result.error, isNotEmpty);
  });

  test('a linked source root is refused without changing the target', () async {
    final before = await sourceFingerprint(source);
    final linked = Link('${temporary.path}/linked-source');
    await linked.create(source.path);
    final result = await invoke(scanArguments(path: linked.path));

    expect(result.exitCode, 3);
    expect(result.error, isNotEmpty);
    expect(await sourceFingerprint(source), before);
  },
      skip: Platform.isWindows
          ? 'Symlink setup requires Windows privileges.'
          : false);

  test('an unsupported link inside the source produces a partial scan failure',
      () async {
    final outside = await Directory('${temporary.path}/outside').create();
    await File('${outside.path}/canary').writeAsString('outside-canary');
    await Link('${source.path}/outside-link').create(outside.path);
    final before = await sourceFingerprint(source);
    final result = await invoke(scanArguments());

    expect(result.exitCode, 3);
    expect(await sourceFingerprint(source), before);
    expect(
        await File('${outside.path}/canary').readAsString(), 'outside-canary');
    expect(
        '${result.output}${result.error}', isNot(contains('outside-canary')));
    if (!Platform.isMacOS) {
      return;
    }
    final snapshot = jsonDecode(result.output) as Map;
    expect(snapshot['state'], 'partial');
    expect(snapshot['diagnostics'], isNotEmpty);
  },
      skip: Platform.isWindows
          ? 'Symlink setup requires Windows privileges.'
          : false);

  test(
      'contradictory observed versions do not turn inventory into certification',
      () async {
    await File('${source.path}/README.md')
        .writeAsString('Pokemon Essentials v21.1\n');
    await Directory('${source.path}/Data/Scripts').create();
    await File('${source.path}/Data/Scripts/001_Settings.rb')
        .writeAsString('ESSENTIALS_VERSION = "22"\n');
    final before = await sourceFingerprint(source);
    final result = await invoke(scanArguments());

    expect(result.exitCode, Platform.isMacOS ? 0 : 3);
    expect(await sourceFingerprint(source), before);
    if (!Platform.isMacOS) {
      return;
    }
    final snapshot = jsonDecode(result.output) as Map;
    expect(snapshot['state'], 'complete');
    expect(
        (snapshot['profileEvidence'] as List)
            .cast<Map>()
            .map((evidence) => evidence['version'])
            .toSet(),
        {'21.1', '22'});
    expect(result.output.toLowerCase(), isNot(contains('certified')));
  });

  test('non-macOS scans report native adapter unavailability', () async {
    final result = await invoke(scanArguments());

    expect(result.exitCode, 3);
    expect(result.error, isNotEmpty);
  },
      skip: Platform.isMacOS
          ? 'The current host has the native macOS adapter.'
          : false);

  test('the executable forwards scan exit code and JSON stdout', () async {
    final before = await sourceFingerprint(source);
    final result = await Process.run(
      'dart',
      ['run', 'bin/avelune_converter.dart', ...scanArguments()],
      workingDirectory: Directory.current.path,
    ).timeout(const Duration(seconds: 20));

    expect(result.exitCode, Platform.isMacOS ? 0 : 3);
    expect(await sourceFingerprint(source), before);
    expect('${result.stdout}${result.stderr}',
        isNot(contains('private-canary-not-for-output')));
    if (!Platform.isMacOS) {
      return;
    }
    expect(result.stderr, isEmpty);
    expect((jsonDecode(result.stdout as String) as Map)['state'], 'complete');
  });
}
