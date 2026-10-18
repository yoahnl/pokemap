part of '../avelune_converter_core.dart';

enum SourceEventAdaptationKind {
  resetHealingDisplayTarget,
  omitInvalidEventTileGraphic,
}

enum SourceAdaptationClassification {
  sourceDefect,
  missingBinding,
  unsupported,
  appliedAdaptation,
}

final class SourceSemanticFile {
  SourceSemanticFile._(this.original, MarshalDocument? adapted,
      List<SourceEventAdaptation> decisions)
      : document = adapted ?? original.document,
        adaptations = List.unmodifiable(decisions.where(
            (value) => value.locator.file == original.entry.relativePath));

  final SourceArchivedFile original;
  final MarshalDocument document;
  final List<SourceEventAdaptation> adaptations;
  SourceFileEntry get entry => original.entry;
  ConverterId get fileId => original.fileId;
  Sha256Hash get contentHash => original.contentHash;
  List<int> get rawBytes => original.rawBytes;
  bool get isAdapted => !identical(document, original.document);
  Sha256Hash get semanticContextHash => canonicalHashOf({
        'originalFileSha256': contentHash.value,
        'adaptations': adaptations.map((value) => value.toJson()).toList(),
      });
  Map<String, Object?> toJson() => {
        'fileId': fileId.value,
        'originalFileSha256': contentHash.value,
        'semanticContextHash': semanticContextHash.value,
        'adaptations': adaptations.map((value) => value.toJson()).toList(),
      };
}

final class SourceEventAdaptation {
  SourceEventAdaptation._(
      this.kind,
      this.sourceSnapshotHash,
      this.sourceFileSha256,
      this.originalPageHash,
      this.locator,
      this.expectedBefore,
      this.newValue,
      this.reason);

  factory SourceEventAdaptation.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {
      'kind',
      'version',
      'adaptation',
      'sourceSnapshotHash',
      'sourceFileSha256',
      'originalPageHash',
      'locator',
      'expectedBefore',
      'newValue',
      'reason',
    });
    _require(json['kind'] == 'sourceEventAdaptation' && json['version'] == 1,
        'source_adaptation.shape', r'$', 'Invalid source adaptation schema.');
    final kind = SourceEventAdaptationKind.values
        .where((item) => item.name == json['adaptation'])
        .singleOrNull;
    _require(kind != null, 'source_adaptation.kind', r'$',
        'Unsupported source adaptation.');
    final rawLocator = _interpretationObject(json['locator']);
    _interpretationKeys(rawLocator,
        const {'file', 'mapId', 'eventId', 'pageIndex', 'commandIndex'});
    final mapId = _presentationInt(rawLocator['mapId'], 1, 2147483647);
    final path = _interpretationString(rawLocator['file']);
    _require(path == _sourceTrainerPath(mapId), 'source_adaptation.locator',
        r'$', 'Adaptations require the exact source map path.');
    final command = rawLocator['commandIndex'];
    _require(
        kind == SourceEventAdaptationKind.resetHealingDisplayTarget
            ? command is int && command >= 0 && command < 2000000
            : command == null,
        'source_adaptation.locator',
        r'$',
        'Invalid adaptation command locator.');
    final before = json['expectedBefore'], after = json['newValue'];
    _require(
        kind == SourceEventAdaptationKind.resetHealingDisplayTarget
            ? before is String &&
                after is String &&
                RegExp(r'^get_character\([1-9][0-9]{0,8}\)\.pattern = 0$')
                    .hasMatch(before) &&
                RegExp(r'^get_character\([1-9][0-9]{0,8}\)\.pattern = 0$')
                    .hasMatch(after) &&
                before != after
            : before is int && before >= 384 && before <= 65535 && after == 0,
        'source_adaptation.value',
        r'$',
        'Only closed healing resets or omission of invalid tile graphics are supported.');
    final reason = _interpretationString(json['reason']);
    _require(
        reason.trim().isNotEmpty && reason.length <= 1024,
        'source_adaptation.reason',
        r'$',
        'An explicit bounded adaptation reason is required.');
    return SourceEventAdaptation._(
        kind!,
        Sha256Hash(_interpretationString(json['sourceSnapshotHash'])),
        Sha256Hash(_interpretationString(json['sourceFileSha256'])),
        Sha256Hash(_interpretationString(json['originalPageHash'])),
        _adaptationLocator(
            path,
            mapId,
            _presentationInt(rawLocator['eventId'], 1, 2147483647),
            _presentationInt(rawLocator['pageIndex'], 0, 2047),
            command as int?),
        before!,
        after!,
        reason);
  }

  static List<SourceEventAdaptation> canonicalize(
      Iterable<SourceEventAdaptation> values) {
    final result = values.toList();
    final targets = <String>{};
    for (final value in result) {
      _require(
          result.length <= 256 && targets.add(value.targetKey),
          'source_adaptation.duplicate',
          value.locator.file,
          'Source adaptations must have unique targets and remain bounded.');
    }
    result.sort((a, b) => a.targetKey.compareTo(b.targetKey));
    return List.unmodifiable(result);
  }

  final SourceEventAdaptationKind kind;
  final Sha256Hash sourceSnapshotHash, sourceFileSha256, originalPageHash;
  final SourceLocator locator;
  final Object expectedBefore, newValue;
  final String reason;
  String get targetKey =>
      '${locator.file}:${locator.eventId}:${locator.pageIndex}:${locator.commandIndex ?? "graphic"}';
  Map<String, Object?> toJson() => {
        'kind': 'sourceEventAdaptation',
        'version': 1,
        'adaptation': kind.name,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceFileSha256': sourceFileSha256.value,
        'originalPageHash': originalPageHash.value,
        'locator': {
          'file': locator.file,
          'mapId': locator.mapId,
          'eventId': locator.eventId,
          'pageIndex': locator.pageIndex,
          'commandIndex': locator.commandIndex
        },
        'expectedBefore': expectedBefore,
        'newValue': newValue,
        'reason': reason,
      };
}

final class SourceAdaptationIssue {
  SourceAdaptationIssue._(this.classification, this.code, this.locator,
      this.message, this.action, this._fileId, this._nodeId);
  final SourceAdaptationClassification classification;
  final String code, message;
  final SourceLocator locator;
  final SourceEventAdaptation? action;
  final ConverterId? _fileId;
  final int? _nodeId;
  Map<String, Object?> toJson() => {
        'classification': classification.name,
        'code': code,
        'locator': locator.toJson(),
        'message': message,
        'allowedAction': action?.toJson(),
        if (action?.kind ==
            SourceEventAdaptationKind.omitInvalidEventTileGraphic)
          'sourceVisualParity': false,
      };
}

final class SourceAdaptationInventory {
  SourceAdaptationInventory._(this.source, List<SourceAdaptationIssue> issues)
      : issues = List.unmodifiable(issues
          ..sort((a, b) => canonicalJsonOf(a.toJson())
              .compareTo(canonicalJsonOf(b.toJson()))));
  final NormalizedSourceProject source;
  final List<SourceAdaptationIssue> issues;

  static Future<SourceAdaptationInventory> inspect({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    ScanCancellation? cancellation,
  }) async {
    final token = cancellation ?? ScanCancellation();
    final issues = <SourceAdaptationIssue>[];
    for (final decision in source.sourceAdaptations) {
      issues.add(SourceAdaptationIssue._(
          SourceAdaptationClassification.appliedAdaptation,
          'source_adaptation.${decision.kind.name}',
          decision.locator,
          decision.reason,
          decision,
          null,
          null));
    }
    final dimensions = <ConverterId, (int, int)?>{};
    for (final map in source.maps) {
      token.check();
      final file = source.sourceFiles[map.map.sourceFileId]!;
      if (file.entry.relativePath != _sourceTrainerPath(map.map.sourceMapId)) {
        issues.add(SourceAdaptationIssue._(
            SourceAdaptationClassification.unsupported,
            'source_adaptation.noncanonical_map_path',
            SourceLocator._(Map.unmodifiable({
              'file': file.entry.relativePath,
              'mapId': map.map.sourceMapId,
              'eventId': null,
              'pageIndex': null,
              'commandIndex': null,
              'tileId': null,
              'line': null,
            })),
            'Les corrections explicites exigent le chemin canonique de la carte source.',
            null,
            null,
            null));
        continue;
      }
      final doc = file.document;
      for (final event in map.map.events) {
        final pages = <Map<String, Object?>>[];
        try {
          for (final page in event.pages) {
            final ref = source.archive.references[page.rawDataRef]!;
            pages.add(Map<String, Object?>.from(
                _ExternalWarpRawValue(doc).read(ref.nodeId) as Map));
          }
        } on Object {
          continue;
        }
        final pending = <(int, int, int, String, String)>[];
        final correctedPages = jsonDecode(jsonEncode(pages)) as List;
        for (final page in event.pages) {
          final ref = source.archive.references[page.rawDataRef]!;
          final fields = _eventFields(doc, ref.nodeId, 'RPG::Event::Page');
          final commands = pages[page.originalPageIndex]['list'] as List;
          final routes = commands
              .whereType<Map>()
              .where((command) => command['code'] == 209)
              .map((command) => command['parameters'] as List)
              .where((parameters) =>
                  parameters.length == 2 &&
                  parameters.first is int &&
                  (parameters.first as int) > 0)
              .toList();
          final displays = routes
              .where((parameters) =>
                  parameters[1] is Map &&
                  (parameters[1] as Map)['list'] is List &&
                  canonicalJsonOf((parameters[1] as Map)['list']) ==
                      canonicalJsonOf([
                        {
                          '__class__': 'RPG::MoveCommand',
                          'code': 33,
                          'parameters': []
                        },
                        {
                          '__class__': 'RPG::MoveCommand',
                          'code': 0,
                          'parameters': []
                        },
                      ]))
              .map((parameters) => parameters.first as int)
              .toSet();
          if (displays.length == 1) {
            final display = displays.single;
            final target = map.map.events
                .where((value) => value.sourceEventId == display)
                .singleOrNull;
            final targetPages = <Object?>[];
            if (target != null) {
              for (final targetPage in target.pages) {
                final targetRef =
                    source.archive.references[targetPage.rawDataRef]!;
                targetPages
                    .add(_ExternalWarpRawValue(doc).read(targetRef.nodeId));
              }
            }
            final displayBinding = _automaticCenterServiceBinding(targetPages);
            if (displayBinding?.family ==
                SourceDeclaredProgramFamily.healingDisplay) {
              final rawCommands =
                  doc.node(_eventField(fields, '@list')).elements;
              for (final command in page.commands) {
                if (command.code != 355 ||
                    command.parameters.length != 1 ||
                    command.parameters.single is! String) {
                  continue;
                }
                final before = command.parameters.single as String;
                final matched =
                    RegExp(r'^get_character\(([1-9][0-9]{0,8})\)\.pattern = 0$')
                        .firstMatch(before);
                if (matched == null ||
                    int.parse(matched.group(1)!) == display) {
                  continue;
                }
                final after = 'get_character($display).pattern = 0';
                final rawCommand = _eventFields(doc,
                    rawCommands[command.originalIndex], 'RPG::EventCommand');
                final parameters =
                    doc.node(_eventField(rawCommand, '@parameters')).elements;
                (correctedPages[page.originalPageIndex]['list']
                    as List)[command.originalIndex]['parameters'] = [after];
                pending.add((
                  page.originalPageIndex,
                  command.originalIndex,
                  parameters.single,
                  before,
                  after
                ));
              }
            }
          }
          final graphic = pages[page.originalPageIndex]['graphic'];
          if (graphic is! Map ||
              graphic['character_name'] != '' ||
              graphic['tile_id'] is! int ||
              (graphic['tile_id'] as int) < 384) {
            continue;
          }
          final tile = graphic['tile_id'] as int;
          final tileset = source.tilesets
              .where(
                  (value) => value.sourceTilesetId == map.map.sourceTilesetId)
              .singleOrNull;
          final image = tileset?.images
              .where((value) => value.role == 'tileset')
              .singleOrNull
              ?.sourceFile;
          if (tileset == null ||
              image == null ||
              image.sha256 == null ||
              image.byteLength > 33554432) {
            continue;
          }
          if (!dimensions.containsKey(image.fileId)) {
            final bytes = await files.read(image.fileId);
            token.check();
            _require(
                bytes.length == image.byteLength &&
                    Sha256Hash(sha256.convert(bytes).toString()) ==
                        image.sha256,
                'source_adaptation.source_changed',
                image.relativePath,
                'The graphic source changed after admission.');
            dimensions[image.fileId] = bytes.length >= 24 &&
                    canonicalJsonOf(bytes.take(8).toList()) ==
                        '[137,80,78,71,13,10,26,10]'
                ? (
                    ByteData.sublistView(
                            Uint8List.fromList(bytes.take(24).toList()))
                        .getUint32(16, Endian.big),
                    ByteData.sublistView(
                            Uint8List.fromList(bytes.take(24).toList()))
                        .getUint32(20, Endian.big)
                  )
                : null;
          }
          final size = dimensions[image.fileId];
          if (size == null ||
              size.$1 != 256 ||
              size.$2 < 32 ||
              size.$2 % 32 != 0 ||
              tile < 384 + (size.$1 ~/ 32) * (size.$2 ~/ 32)) {
            continue;
          }
          final graphicFields = _eventFields(doc,
              _eventField(fields, '@graphic'), 'RPG::Event::Page::Graphic');
          final decision = _candidate(
              source,
              file,
              pages[page.originalPageIndex],
              _adaptationLocator(file.entry.relativePath, map.map.sourceMapId,
                  event.sourceEventId, page.originalPageIndex),
              SourceEventAdaptationKind.omitInvalidEventTileGraphic,
              tile,
              0,
              'Omettre explicitement le calque graphique hors atlas ; conserver le service natif et le fond de carte. Fidélité visuelle source non qualifiée.');
          issues.add(SourceAdaptationIssue._(
              SourceAdaptationClassification.sourceDefect,
              'source_defect.event_tile_outside_image',
              decision.locator,
              'Le calque utilise la tuile $tile, hors image ${size.$1} × ${size.$2}. Son omission est une adaptation visuelle explicite.',
              decision,
              file.fileId,
              _eventField(graphicFields, '@tile_id')));
        }
        if (pending.isNotEmpty &&
            _automaticCenterServiceBinding(correctedPages)?.family ==
                SourceDeclaredProgramFamily.centerNurse) {
          for (final correction in pending) {
            final decision = _candidate(
                source,
                file,
                pages[correction.$1],
                _adaptationLocator(file.entry.relativePath, map.map.sourceMapId,
                    event.sourceEventId, correction.$1, correction.$2),
                SourceEventAdaptationKind.resetHealingDisplayTarget,
                correction.$4,
                correction.$5,
                'Aligner la remise à zéro sur l’événement de soin déjà ciblé par les routes reconnues.');
            issues.add(SourceAdaptationIssue._(
                SourceAdaptationClassification.sourceDefect,
                'source_defect.healing_reset_target',
                decision.locator,
                'La remise à zéro cible un autre événement que les routes de soin reconnues.',
                decision,
                file.fileId,
                correction.$3));
          }
        }
      }
    }
    for (final diagnostic in source.diagnostics) {
      if (diagnostic.code == 'normalization.unknown_data_preserved') continue;
      issues.add(SourceAdaptationIssue._(
          diagnostic.code.contains('missing') ||
                  diagnostic.code.contains('ambiguous')
              ? SourceAdaptationClassification.missingBinding
              : SourceAdaptationClassification.unsupported,
          diagnostic.code,
          diagnostic.locator,
          diagnostic.message,
          null,
          null,
          null));
    }
    final profile = SourceEventProfile.forProject(source);
    if (profile.isQualified) {
      for (final diagnostic
          in SourceEventAnalyzer.forProject(source, profile: profile)
              .analyze()
              .diagnostics) {
        issues.add(SourceAdaptationIssue._(
            SourceAdaptationClassification.unsupported,
            diagnostic.code,
            diagnostic.locator,
            'Le comportement source reste conservé et non qualifié pour une exécution native.',
            null,
            null,
            null));
      }
    }
    return SourceAdaptationInventory._(source, issues);
  }

  static SourceEventAdaptation _candidate(
          NormalizedSourceProject source,
          SourceSemanticFile file,
          Map<String, Object?> page,
          SourceLocator locator,
          SourceEventAdaptationKind kind,
          Object before,
          Object after,
          String reason) =>
      SourceEventAdaptation._(
          kind,
          source.snapshot.canonicalHash,
          file.contentHash,
          canonicalHashOf(page),
          locator,
          before,
          after,
          reason);

  Map<ConverterId, MarshalDocument> _apply(
      List<SourceEventAdaptation> decisions) {
    final nodes = <ConverterId, List<MarshalNode>>{};
    final changed = <(ConverterId, int)>{};
    for (final decision in decisions) {
      final matches = issues
          .where((issue) =>
              issue.classification ==
                  SourceAdaptationClassification.sourceDefect &&
              issue.action?.targetKey == decision.targetKey)
          .toList();
      _require(
          matches.length == 1 &&
              canonicalJsonOf(
                      {...matches.single.action!.toJson()}..remove('reason')) ==
                  canonicalJsonOf({...decision.toJson()}..remove('reason')),
          'source_adaptation.stale',
          decision.locator.file,
          'The adaptation is stale, out of scope, or does not match an exact supported source defect.');
      final issue = matches.single;
      final fileId = issue._fileId!, nodeId = issue._nodeId!;
      _require(
          changed.add((fileId, nodeId)),
          'source_adaptation.conflict',
          decision.locator.file,
          'Multiple adaptations address the same decoded source node.');
      final document = source.sourceFiles[fileId]!.document;
      final original = document.node(nodeId);
      final references = document.nodes.fold<int>(
          0,
          (count, node) =>
              count +
              node.elements.where((value) => value == nodeId).length +
              node.instanceVariables
                  .where((value) => value.value == nodeId)
                  .length +
              node.pairs
                  .where(
                      (value) => value.key == nodeId || value.value == nodeId)
                  .length);
      _require(
          references == 1,
          'source_adaptation.aliased_node',
          decision.locator.file,
          'A correction cannot change a shared source value.');
      final fileNodes =
          nodes.putIfAbsent(fileId, () => document.nodes.toList());
      fileNodes[nodeId] = MarshalNode._(
          kind: original.kind,
          location: original.location,
          integerValue: decision.newValue is int
              ? BigInt.from(decision.newValue as int)
              : original.integerValue,
          bytes: decision.newValue is String
              ? utf8.encode(decision.newValue as String)
              : original.bytes,
          encoding: original.encoding,
          instanceVariables: original.instanceVariables,
          extensions: original.extensions,
          userClass: original.userClass);
    }
    return Map.unmodifiable(nodes.map((id, values) {
      final doc = source.sourceFiles[id]!.document;
      return MapEntry(
          id,
          MarshalDocument._(
              rootId: doc.rootId,
              nodes: values,
              objectCount: doc.objectCount,
              symbolCount: doc.symbolCount,
              bytesRead: doc.bytesRead));
    }));
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceAdaptationInventory',
        'version': 1,
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'normalizationHash': source.canonicalHash.value,
        'sourceScriptsExecuted': 0,
        'issues': issues.map((value) => value.toJson()).toList(),
      };
}

SourceLocator _adaptationLocator(
        String file, int mapId, int eventId, int pageIndex,
        [int? commandIndex]) =>
    SourceLocator._(Map.unmodifiable({
      'file': file,
      'mapId': mapId,
      'eventId': eventId,
      'pageIndex': pageIndex,
      'commandIndex': commandIndex,
      'tileId': null,
      'line': null,
    }));

final class SourceMissingItemBinding {
  SourceMissingItemBinding._(
      this.sourceSymbol,
      this.sourceSnapshotHash,
      this.sourceFileId,
      this.sourceRelativePath,
      this.sourceSha256,
      this.reason);

  factory SourceMissingItemBinding.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {
      'kind',
      'version',
      'sourceSymbol',
      'sourceSnapshotHash',
      'sourceFileId',
      'sourceRelativePath',
      'sourceSha256',
      'reason',
      'humanConfirmed'
    });
    final symbol = _interpretationString(json['sourceSymbol']);
    final path = _interpretationString(json['sourceRelativePath']);
    final reason = _interpretationString(json['reason']);
    _require(
        json['kind'] == 'sourceMissingItemBinding' &&
            json['version'] == 1 &&
            json['humanConfirmed'] == true &&
            RegExp(r'^[A-Z][A-Z0-9_]{0,127}$').hasMatch(symbol) &&
            RegExp(r'^_converter_sources/[1-4]/Data/items\.dat$')
                .hasMatch(path) &&
            reason.trim().isNotEmpty &&
            reason.length <= 1024,
        'source_adaptation.item_binding',
        r'$',
        'Missing item bindings require an explicit exact supplemental catalog and reason.');
    return SourceMissingItemBinding._(
        symbol,
        Sha256Hash(_interpretationString(json['sourceSnapshotHash'])),
        ConverterId(_interpretationString(json['sourceFileId'])),
        path,
        Sha256Hash(_interpretationString(json['sourceSha256'])),
        reason);
  }

  static List<SourceMissingItemBinding> canonicalize(
      Iterable<SourceMissingItemBinding> values) {
    final result = values.toList();
    _require(
        result.length <= 128 &&
            result.map((value) => value.sourceSymbol).toSet().length ==
                result.length,
        'source_adaptation.item_binding_duplicate',
        r'$',
        'Missing item bindings must be unique and bounded.');
    result.sort((a, b) => a.sourceSymbol.compareTo(b.sourceSymbol));
    return List.unmodifiable(result);
  }

  void verifySnapshot(SourceSnapshot snapshot) {
    final matches =
        snapshot.entries.where((value) => value.fileId == sourceFileId);
    _require(
        sourceSnapshotHash == snapshot.canonicalHash &&
            matches.length == 1 &&
            matches.single.relativePath == sourceRelativePath &&
            matches.single.sha256 == sourceSha256 &&
            matches.single.kind == SourceNodeKind.file,
        'source_adaptation.item_binding_stale',
        sourceRelativePath,
        'The item binding must match the exact admitted supplemental source.');
  }

  final String sourceSymbol, sourceRelativePath, reason;
  final Sha256Hash sourceSnapshotHash, sourceSha256;
  final ConverterId sourceFileId;
  Map<String, Object?> toJson() => {
        'kind': 'sourceMissingItemBinding',
        'version': 1,
        'sourceSymbol': sourceSymbol,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceFileId': sourceFileId.value,
        'sourceRelativePath': sourceRelativePath,
        'sourceSha256': sourceSha256.value,
        'reason': reason,
        'humanConfirmed': true,
      };
}
