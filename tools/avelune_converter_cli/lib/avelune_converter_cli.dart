import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<int> runConverterCli(List<String> arguments,
    {StringSink? output, StringSink? error}) async {
  final out = output ?? stdout;
  final err = error ?? stderr;
  final scan = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addOption('source', help: 'Dossier source absolu, lu sans modification.')
    ..addOption('namespace',
        help: 'Identifiant logique stable du projet source.')
    ..addFlag('offline',
        negatable: false, help: 'Exécuter uniquement les opérations locales.')
    ..addFlag('json',
        negatable: false,
        help: 'Émettre le snapshot JSON sur la sortie standard.');
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addCommand('scan', scan);
  final usage = 'Avelune Converter — inventaire local\n'
      'dart run bin/avelune_converter.dart scan '
      '--source DOSSIER_ABSOLU --namespace IDENTIFIANT --offline [--json]\n\n'
      '${scan.usage}';
  int invalid() {
    err.writeln('Arguments invalides. Utiliser --help.');
    return 2;
  }

  final ArgResults parsed;
  try {
    parsed = parser.parse(arguments);
  } on FormatException {
    return invalid();
  }
  if (parsed['help'] == true || parsed.command?['help'] == true) {
    out.writeln(usage);
    return 0;
  }
  final command = parsed.command;
  if (command == null ||
      command.name != 'scan' ||
      parsed.rest.isNotEmpty ||
      command.rest.isNotEmpty ||
      command['offline'] != true) {
    return invalid();
  }
  final sourcePath = command['source'] as String?;
  final namespace = command['namespace'] as String?;
  if (sourcePath == null ||
      !sourcePath.startsWith('/') ||
      sourcePath.contains('\u0000') ||
      namespace == null) {
    return invalid();
  }
  final ConverterId projectId;
  try {
    projectId = ConverterId(namespace);
  } on ContractError {
    return invalid();
  }
  MacOsSourceTree? source;
  try {
    if (await FileSystemEntity.type(sourcePath, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw ContractError('source.root_invalid', r'$',
          'La source doit être un dossier existant sans lien symbolique.');
    }
    source = await MacOsSourceTree.open(sourcePath);
    final snapshot = await SourceScanner()
        .scan(source: source, logicalProjectNamespace: projectId);
    if (command['json'] == true) {
      out.writeln(jsonEncode(snapshot.toJson()));
    } else {
      final files = snapshot.entries
          .where((entry) => entry.kind == SourceNodeKind.file)
          .length;
      out.writeln('Inventaire ${snapshot.state.name} : $files fichiers, '
          '${snapshot.excludedPaths.length} exclusions, '
          '${snapshot.diagnostics.length} diagnostics.');
      out.writeln('SHA-256 : ${snapshot.canonicalHash.value}');
      out.writeln('Profil Essentials : ${snapshot.profile.state.name}');
      final version = snapshot.profile.version;
      if (version != null) out.writeln('Version observée : $version');
    }
    if (snapshot.state == SourceScanState.cancelled) return 130;
    if (snapshot.state != SourceScanState.complete) {
      err.writeln('Inventaire incomplet : consulter les diagnostics.');
      return 3;
    }
    return 0;
  } on ContractError catch (failure) {
    err.writeln('${failure.code} : ${failure.message}');
    return 3;
  } on FileSystemException {
    err.writeln('source.io : la source est indisponible.');
    return 3;
  } finally {
    await source?.close();
  }
}
