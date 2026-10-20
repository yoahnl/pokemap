import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';

Future<int> runConverterCli(List<String> arguments,
    {StringSink? output,
    StringSink? error,
    Stream<void>? cancellationSignals}) async {
  final out = output ?? stdout;
  final err = error ?? stderr;
  ArgParser common() => ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('offline',
        negatable: false, help: 'Exécution locale sans réseau ni IA.')
    ..addFlag('json', negatable: false, help: 'Résultat JSON sur stdout.')
    ..addFlag('progress',
        negatable: false, help: 'Phases et compteurs sur stderr.');
  ArgParser sourceArguments() => common()
    ..addOption('source', help: 'Dossier source absolu, lu sans modification.')
    ..addMultiOption('reference-source', splitCommas: false, help: 'Dossier de référence absolu explicitement sélectionné (quatre au maximum).')
    ..addOption('namespace',
        help: 'Identifiant logique stable du projet source.');
  final scan = sourceArguments();
  final inspectAdaptations = sourceArguments()..addOption('maps', help: 'Cartes source à examiner.');
  final plan = sourceArguments()
    ..addOption('destination',
        help: 'Nouveau dossier natif absolu ; son parent doit exister.')
    ..addOption('maps', help: 'IDs de cartes source séparés par des virgules.')
    ..addMultiOption('atlas-binding',
        splitCommas: false,
        help: 'Association explicite Référence=PNG source du même dossier.')
    ..addOption('missing-item-bindings', help: 'Liste JSON fermée des associations explicites d’entrées absentes.')
    ..addOption('source-adaptations', help: 'Liste JSON fermée des décisions explicites issues de l’inventaire.')
    ..addOption('name', help: 'Nom du projet natif.')
    ..addOption('interpretation-profile', help: 'Profil JSON explicite prioritaire ; absent : détection des archives connues.')
    ..addFlag('literal', negatable: false,
        help: 'Conserver une étude littérale sans profil, même pour une archive connue.')
    ..addOption('mode', defaultsTo: 'study', allowed: ['study'])
    ..addOption('content', defaultsTo: 'full', allowed: ['world', 'full'],
        help: 'Monde explorable seul, ou monde et interactions.')
    ..addOption('plan',
        help: 'Nouveau fichier .json de recette, hors source et projet natif.')
    ..addFlag('ack-profile',
        negatable: false,
        help: 'Accepter explicitement le profil observé pour une étude.')
    ..addFlag('allow-first-frame-autotiles', negatable: false);
  final convert = common()
    ..addOption('plan',
        help: 'Recette .json à rescanner et recomposer exactement.')
    ..addOption('approve-plan',
        help: 'SHA-256 exact du plan approuvé après sa revue.');
  final verify = common()
    ..addOption('project',
        help: 'Projet natif absolu à vérifier sans écriture.');
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addCommand('inspect-adaptations', inspectAdaptations)
    ..addCommand('scan', scan)
    ..addCommand('plan', plan)
    ..addCommand('convert', convert)
    ..addCommand('verify', verify);
  final commands = {
    'scan': scan,
    'inspect-adaptations': inspectAdaptations,
    'plan': plan,
    'convert': convert,
    'verify': verify
  };
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
    final selected = parsed.command?.name;
    out.writeln('Avelune Converter — étude locale hors ligne\n'
        'scan --source SOURCE --namespace ID --offline [--json]\n'
        'plan --source SOURCE --namespace ID --maps 1,2 --name NOM '
        '--destination DEST --plan RECETTE.json --ack-profile [--content world|full] [--interpretation-profile PROFIL.json] --offline\n'
        'convert --plan RECETTE.json --approve-plan SHA256 --offline\n'
        'verify --project DEST --offline\n'
        'Les chemins sont absolus. Code 0 d’étude ne certifie pas un jeu complet.\n');
    if (selected != null) out.writeln(commands[selected]!.usage);
    return 0;
  }
  final command = parsed.command;
  if (command == null ||
      parsed.rest.isNotEmpty ||
      command.rest.isNotEmpty ||
      command['offline'] != true) {
    return invalid();
  }
  bool absolute(String? value) =>
      value != null &&
      value.startsWith('/') &&
      value.length <= 4096 &&
      !value.contains('\u0000');
  ConverterSourceSelection? selection;
  Sha256Hash? approvedHash;
  List<int> selectedMaps = const [];
  String? parentPath;
  String? folderName;
  try {
    if (command.name == 'scan' || command.name == 'plan' || command.name == 'inspect-adaptations') {
      final sourcePath = command['source'] as String?;
      final namespace = command['namespace'] as String?;
      if (!absolute(sourcePath) || namespace == null) return invalid();
      selection = ConverterSourceSelection(
          rootPath: sourcePath!,
          supplementalRootPaths: command['reference-source'] as List<String>,
          logicalProjectNamespace: ConverterId(namespace));
    }
    if (command.name == 'plan') {
      final destination = command['destination'] as String?;
      final planPath = command['plan'] as String?;
      final name = command['name'] as String?;
      final maps = command['maps'] as String?;
      if (!absolute(destination) ||
          !absolute(planPath) ||
          name == null ||
          maps == null ||
          command['ack-profile'] != true ||
          destination!.endsWith('/')) {
        return invalid();
      }
      final slash = destination.lastIndexOf('/');
      if (slash <= 0) return invalid();
      parentPath = destination.substring(0, slash);
      folderName = destination.substring(slash + 1);
      selectedMaps = maps.split(',').map(int.parse).toList();
      if (selectedMaps.isEmpty ||
          selectedMaps.length > 2048 ||
          selectedMaps.any((id) => id <= 0 || id > 2147483647) ||
          selectedMaps.toSet().length != selectedMaps.length) {
        return invalid();
      }
      final bindings = command['atlas-binding'] as List<String>;
      if (bindings.length > 256 ||
          bindings.any((value) => value.length > 8193)) {
        return invalid();
      }
      SourceImageBinding.canonicalize([
        for (final binding in bindings.map(_atlasImagePaths))
          SourceImageBinding(
            expectedReferencePath: binding.expected,
            sourceRelativePath: binding.selected,
            sourceSha256: Sha256Hash('0' * 64),
          ),
      ]);
    } else if (command.name == 'convert') {
      if (!absolute(command['plan'] as String?) ||
          command['approve-plan'] == null) {
        return invalid();
      }
      approvedHash = Sha256Hash(command['approve-plan'] as String);
    } else if (command.name == 'verify') {
      if (!absolute(command['project'] as String?)) return invalid();
    }
  } on Object {
    return invalid();
  }

  final workflow = ConverterWorkflow();
  final cancellation = ScanCancellation();
  final cancelSubscription = cancellationSignals?.listen((_) {
    cancellation.cancel();
    workflow.cancelCurrentJob();
  });
  final progressSubscription = command['progress'] == true
      ? workflow.events.listen((event) {
          final state = event.state;
          final progress = state.progress;
          if (state.phase != null && progress != null) {
            err.writeln(
                '${state.phase!.name}: ${progress.done}/${progress.total ?? "?"} ${progress.unit.name}');
          }
        })
      : null;
  try {
    cancellation.check();
    if (selection != null) {
      if (await FileSystemEntity.type(selection.rootPath, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const ConverterWorkflowFailure('source.root_invalid',
            'La source doit être un dossier existant sans lien symbolique.');
      }
      cancellation.check();
      final snapshot = await workflow.scanSource(selection);
      cancellation.check();
      if (command.name == 'inspect-adaptations') {
        final maps = command['maps'] as String?;
        if (maps == null) return invalid();
        final tree = await SupplementedSourceTree.open(selection.rootPath,
            supplementalRootPaths: selection.supplementalRootPaths);
        try {
          final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot,
              policy: selection.policy, cancellation: cancellation);
          final normalized = await const RmxpSourceNormalizer().normalize(snapshot: snapshot,
              files: files, selectedMapIds: maps.split(',').map(int.parse).toSet(), cancellation: cancellation);
          final inventory = await SourceAdaptationInventory.inspect(source: normalized, files: files, cancellation: cancellation);
          out.writeln(jsonEncode(inventory.toJson()));
        } finally { await tree.close(); }
        return 0;
      }
      if (command.name == 'scan') {
        if (command['json'] == true) {
          out.writeln(jsonEncode(snapshot.toJson()));
        } else {
          final files = snapshot.entries
              .where((e) => e.kind == SourceNodeKind.file)
              .length;
          out.writeln(
              'Inventaire ${snapshot.state.name} : $files fichiers, ${snapshot.excludedPaths.length} exclusions, ${snapshot.diagnostics.length} diagnostics.');
          out.writeln('SHA-256 : ${snapshot.canonicalHash.value}');
          out.writeln('Profil Essentials : ${snapshot.profile.state.name}');
          if (snapshot.profile.version != null) {
            out.writeln('Version observée : ${snapshot.profile.version}');
          }
        }
        if (snapshot.state == SourceScanState.cancelled) return 130;
        if (snapshot.state != SourceScanState.complete) {
          err.writeln(
              'Inventaire incomplet : ${snapshot.diagnostics.map((d) => '${d.code}: ${d.message}').join('; ')}');
          return 3;
        }
        return 0;
      }
      workflow.updateSettings(ConverterStudySettings(
          contentScope: ConverterContentScope.values.byName(command['content'] as String),
          interpretationProfile: command['interpretation-profile'] != null
              ? await const LocalSourceInterpretationProfileStore().read(command['interpretation-profile'] as String)
              : command['literal'] == true ? null : detectBuiltinSourceInterpretationProfile(snapshot),
          missingItemBindings: command['missing-item-bindings'] == null ? const [] :
              await _readMissingItemBindings(command['missing-item-bindings'] as String),
          sourceAdaptations: command['source-adaptations'] == null ? const [] :
              await _readSourceAdaptations(command['source-adaptations'] as String),
          imageBindings: [
            for (final raw in command['atlas-binding'] as List<String>)
              _sourceImageBinding(raw, snapshot),
          ],
          projectName: command['name'] as String,
          parentPath: parentPath!,
          folderName: folderName!,
          selectedSourceMapIds: selectedMaps,
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason:
                  'CLI --ack-profile: étude hors ligne du profil observé, sans certification de jeu complet.'),
          allowFirstFrameAutotiles:
              command['allow-first-frame-autotiles'] == true));
      await workflow.prepareStudy();
      cancellation.check();
      final recipe = workflow.exportStudyPlanRecipe();
      await const LocalStudyPlanStore()
          .writeNew(recipe, command['plan'] as String);
      if (command['json'] == true) {
        out.writeln(jsonEncode(recipe.toJson()));
      } else {
        out.writeln('Plan d’étude sauvegardé : ${command['plan']}');
        out.writeln('Approbation requise : ${recipe.approvedPlanHash.value}');
        out.writeln('Recette : ${recipe.canonicalHash.value}');
      }
      return 0;
    }
    if (command.name == 'convert') {
      final recipe =
          await const LocalStudyPlanStore().read(command['plan'] as String);
      cancellation.check();
      if (recipe.approvedPlanHash != approvedHash) {
        throw const ConverterWorkflowFailure('workflow.stale_approval',
            '--approve-plan doit correspondre exactement au hash du plan revu.');
      }
      final fresh = await workflow.restoreStudyPlanRecipe(recipe);
      cancellation.check();
      final approval = workflow.approvePrepared(
          sessionRevision: fresh.sessionRevision,
          preparationHash: fresh.preparationHash,
          humanConfirmed: true);
      if (approval.approvedPlanHash != approvedHash) {
        throw const ConverterWorkflowFailure('workflow.stale_approval',
            'Le plan fraîchement recomposé diffère de l’approbation.');
      }
      final result = await workflow.writeApproved(approval);
      final json = {
        'kind': 'converterStudyResult',
        'version': 1,
        'projectPath': result.projectPath,
        'published': result.published,
        'verified': result.receipt.verified,
        'playableCertified': result.playableCertified,
        'sourceUnchanged': result.sourceUnchanged,
        'nativeRevision': result.receipt.nativeRevision,
        'approvedPlanHash': result.approvedPlanHash.value,
        'preparationHash': result.preparationHash.value,
        'sourceSnapshotHash': result.sourceSnapshotHash.value,
        'journalPath': result.publication.journalPath,
        'stagingPath': result.receipt.stagingRoot
      };
      if (command['json'] == true) {
        out.writeln(jsonEncode(json));
      } else {
        out.writeln(
            'Étude native publiée et vérifiée : ${result.projectPath}\nJournal : ${result.publication.journalPath}');
      }
      return 0;
    }
    final projectPath = command['project'] as String;
    final result = await const NativeStudyVerifier().verify(
        projectPath: projectPath,
        allowedParentPath: Directory(projectPath).parent.path,
        cancellation: cancellation);
    if (command['json'] == true) {
      out.writeln(jsonEncode(result.toJson()));
    } else {
      out.writeln(
          'Projet natif vérifié en lecture seule : ${result.mapCount} cartes, ${result.assetCount} assets.\nRévision : ${result.nativeRevision}');
    }
    return 0;
  } on ConverterWorkflowFailure catch (failure) {
    await progressSubscription?.cancel();
    final json = {
      'code': failure.code,
      'message': failure.message,
      if (failure.locator != null) 'locator': failure.locator,
      if (failure.stagingPath != null) 'stagingPath': failure.stagingPath,
      if (failure.journalPath != null) 'journalPath': failure.journalPath,
      if (failure.destinationPath != null)
        'destinationPath': failure.destinationPath,
      'promotionMayHaveOccurred': failure.promotionMayHaveOccurred
    };
    err.writeln(command['json'] == true
        ? jsonEncode(json)
        : '${failure.code} : ${failure.message}'
            '${failure.journalPath == null ? "" : "\nJournal : ${failure.journalPath}"}'
            '${failure.stagingPath == null ? "" : "\nStaging : ${failure.stagingPath}"}'
            '${failure.destinationPath == null ? "" : "\nDestination : ${failure.destinationPath}"}'
            '${failure.promotionMayHaveOccurred ? "\nLa promotion peut avoir eu lieu ; vérifier le journal avant toute reprise." : ""}');
    return converterCliExitCode(failure.code);
  } on ContractError catch (failure) {
    await progressSubscription?.cancel();
    err.writeln('${failure.code} : ${failure.message}');
    return converterCliExitCode(failure.code);
  } on FileSystemException {
    await progressSubscription?.cancel();
    err.writeln('source.io : le fichier ou dossier demandé est indisponible.');
    return command.name == 'verify' ? 5 : 3;
  } on Object {
    await progressSubscription?.cancel();
    err.writeln('workflow.failed : l’opération locale n’a pas pu se terminer.');
    return 5;
  } finally {
    await cancelSubscription?.cancel();
    await progressSubscription?.cancel();
    await workflow.dispose();
  }
}

({String expected, String selected}) _atlasImagePaths(String raw) {
  final separator = RegExp(r'=(?=Graphics/(?:Tilesets|Autotiles)/)',
          caseSensitive: false)
          .firstMatch(raw)
          ?.start ??
      -1;
  if (separator <= 0 || separator == raw.length - 1) {
    throw const ConverterWorkflowFailure('workflow.selection.invalid',
        'Une association d’atlas doit utiliser Référence=Graphics/Tilesets/Image.png ou Référence=Graphics/Autotiles/Image.png.');
  }
  return (
    expected: raw.substring(0, separator),
    selected: raw.substring(separator + 1)
  );
}

SourceImageBinding _sourceImageBinding(String raw, SourceSnapshot snapshot) {
  final paths = _atlasImagePaths(raw);
  final expected = paths.expected;
  final selected = paths.selected;
  final matches = snapshot.entries
      .where((entry) =>
          entry.relativePath == selected &&
          entry.kind == SourceNodeKind.file &&
          entry.sha256 != null &&
          entry.format == 'raster' &&
          entry.relativePath.toLowerCase().endsWith('.png'))
      .toList();
  if (matches.length != 1) {
    throw const ConverterWorkflowFailure('workflow.selection.invalid',
        'L’image choisie doit être un PNG régulier du projet source.');
  }
  return SourceImageBinding(
      expectedReferencePath: expected,
      sourceRelativePath: selected,
      sourceSha256: matches.single.sha256!);
}

int converterCliExitCode(String code) {
  if (code.contains('cancelled')) return 130;
  if (code.contains('platform') ||
      code.contains('protected') ||
      code.contains('outsideRoots') ||
      code.contains('overlap') ||
      code == 'native.verify.policy' ||
      code.startsWith('security.')) {
    return 6;
  }
  if (code.contains('stale') ||
      code.contains('changed') ||
      code.contains('conflict') ||
      code == 'publication.destination.exists') {
    return 7;
  }
  if (code.startsWith('native.verify.') ||
      code.startsWith('publication.native.')) {
    return 5;
  }
  if (code.startsWith('source.') ||
      code.startsWith('marshal.') ||
      code.startsWith('source_archive.') ||
      code.startsWith('normalization.') ||
      code == 'workflow.incomplete') {
    return 3;
  }
  if (code.startsWith('interpretation_profile.') ||
      code.startsWith('workflow.content_scope.') ||
      code == 'workflow.recipe.invalid' ||
      code == 'workflow.recipe.store_invalid' ||
      code == 'workflow.recipe.quota' ||
      code == 'workflow.destination.invalid' ||
      code == 'workflow.selection.invalid' ||
      code == 'workflow.quota.selection') {
    return 2;
  }
  if (code == 'workflow.blocked' ||
      code == 'workflow.recipe.unavailable' ||
      code == 'workflow.profile_ack' ||
      code.startsWith('literal.') ||
      code.startsWith('asset.')) {
    return 4;
  }
  return 5;
}

Future<List<SourceEventAdaptation>> _readSourceAdaptations(String filePath) async {
  if (!filePath.startsWith('/') || filePath.length > 4096 || filePath.contains('\u0000')) {
    throw const FormatException('An absolute adaptation manifest path is required.');
  }
  final file = File(filePath);
  if (await file.length() > 1048576) throw const FormatException('Adaptation manifest exceeds its quota.');
  final json = jsonDecode(await file.readAsString());
  if (json is! List || json.length > 256) throw const FormatException('A bounded adaptation list is required.');
  return SourceEventAdaptation.canonicalize(json.map(SourceEventAdaptation.fromJson));
}

Future<List<SourceMissingItemBinding>> _readMissingItemBindings(String filePath) async {
  if (!filePath.startsWith('/') || filePath.length > 4096 || filePath.contains('\u0000')) {
    throw const FormatException('An absolute item binding manifest path is required.');
  }
  final file = File(filePath);
  if (await file.length() > 1048576) throw const FormatException('Item binding manifest exceeds its quota.');
  final json = jsonDecode(await file.readAsString());
  if (json is! List || json.length > 128) throw const FormatException('A bounded item binding list is required.');
  return SourceMissingItemBinding.canonicalize(json.map(SourceMissingItemBinding.fromJson));
}
