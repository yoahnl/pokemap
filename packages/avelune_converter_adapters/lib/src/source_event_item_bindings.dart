import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';

enum SourceEventItemUseParity { qualified, partial, unqualified }

final class SourceEventMachineMoveBinding {
  const SourceEventMachineMoveBinding._({
    required this.sourceSymbol,
    required this.name,
    required this.file,
    required this.headerLocator,
    required this.nameLocator,
    required this.sourceSnapshotHash,
    required this.nativeMoveId,
    required this.nativeCatalogEvidence,
  });

  final String sourceSymbol;
  final String name;
  final SourceFileEntry file;
  final SourceLocator headerLocator;
  final SourceLocator nameLocator;
  final Sha256Hash sourceSnapshotHash;
  final String? nativeMoveId;
  final Map<String, Object?>? nativeCatalogEvidence;

  Map<String, Object?> toJson() => {
        'sourceSymbol': sourceSymbol,
        'name': name,
        'file': file.toJson(),
        'headerLocator': headerLocator.toJson(),
        'nameLocator': nameLocator.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'scope': nativeMoveId == null
            ? 'sourceMachinePickupDisplayNameOnly'
            : 'attestedSourceIdentityToAveluneNativeMove',
        'nativeMoveId': nativeMoveId,
        'nativeCatalogEvidence': nativeCatalogEvidence,
        'sourceBattleRulesImported': false,
        'fullMachineUseParityQualified': false,
      };
}

final class SourceEventItemBindingLimits {
  const SourceEventItemBindingLimits({
    this.maxCatalogBytes = 4194304,
    this.maxRequestedSymbols = 64,
    this.maxCatalogEntries = 4096,
    this.maxNodes = 200000,
    this.maxTextCodeUnits = 4096,
  });

  final int maxCatalogBytes;
  final int maxRequestedSymbols;
  final int maxCatalogEntries;
  final int maxNodes;
  final int maxTextCodeUnits;

  void validate() {
    final values = [
      (maxCatalogBytes, 16777216),
      (maxRequestedSymbols, 4096),
      (maxCatalogEntries, 65536),
      (maxNodes, 1000000),
      (maxTextCodeUnits, 65536),
    ];
    if (values.any((v) => v.$1 <= 0 || v.$1 > v.$2)) {
      throw ContractError('source.event_items.limits_invalid', r'$',
          'Item binding limits must be positive and bounded.');
    }
  }
}

final class SourceEventItemBinding {
  SourceEventItemBinding._({
    required this.sourceSymbol,
    required this.definition,
    required this.itemReference,
    required this.sourceCatalogPath,
    required Map<String, SourcePreservedData> fieldReferences,
    required this.sourcePocketIndex,
    required this.portionName,
    required this.portionNamePlural,
    required List<String> flags,
    required this.isKeyItem,
    required this.isMachine,
    required this.isImportant,
    required this.moveSymbol,
    required this.sourceMachineMove,
    required this.sourceConsumable,
    required this.sourceSnapshotHash,
    required this.pickupQualified,
    required this.interpretationProfile,
    required this.useParity,
    required List<String> useGaps,
  })  : fieldReferences = Map.unmodifiable(fieldReferences),
        flags = List.unmodifiable(flags),
        useGaps = List.unmodifiable(useGaps);

  final String sourceSymbol;
  final ProjectItemDefinition definition;
  final SourcePreservedData itemReference;
  final String sourceCatalogPath;
  final Map<String, SourcePreservedData> fieldReferences;
  final int sourcePocketIndex;
  final String portionName;
  final String portionNamePlural;
  final List<String> flags;
  final bool isKeyItem;
  final bool isMachine;
  final bool isImportant;
  final String? moveSymbol;
  final SourceEventMachineMoveBinding? sourceMachineMove;
  final bool sourceConsumable;
  final Sha256Hash sourceSnapshotHash;
  final bool pickupQualified;
  final SourceInterpretationProfile? interpretationProfile;
  final SourceEventItemUseParity useParity;
  final List<String> useGaps;
  bool get fullPickupParityQualified => false;
  String get pickupQualificationScope =>
      'sourceItemBallCatalogAndUnitBagAddOnly';
  String get useQualificationScope =>
      definition.uses.any((use) => use.target == ProjectItemTargetKind.world)
          ? 'nativeOverworldEffectAndConsumptionOnly'
          : 'bagMechanicalEffectAndConsumptionOnly';

  Map<String, Object?> toJson() => _freeze({
        'sourceSymbol': sourceSymbol,
        'definition': definition.toJson(),
        'itemReference': itemReference.toJson(),
        'sourceCatalogOrigin': {
          'selectedRelativePath': sourceCatalogPath,
          'originalRelativePath':
              sourceCatalogPath.startsWith('_converter_sources/')
                  ? 'Data/items.dat'
                  : sourceCatalogPath,
          'fileId': itemReference.fileId.value,
          'sha256': itemReference.contentHash.value
        },
        'fieldReferences': {
          for (final field in fieldReferences.entries)
            field.key: field.value.toJson(),
        },
        'sourcePocketIndex': sourcePocketIndex,
        'portionName': portionName,
        'portionNamePlural': portionNamePlural,
        'flags': flags,
        'isKeyItem': isKeyItem,
        'isMachine': isMachine,
        'isImportant': isImportant,
        'moveSymbol': moveSymbol,
        'sourceMachineMove': sourceMachineMove?.toJson(),
        if (isMachine) 'nativeProjectMoveMachine': definition.machine?.toJson(),
        if (isMachine) 'fullMachineUseParityQualified': false,
        'sourceConsumable': sourceConsumable,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'pickupQualified': pickupQualified,
        'pickupQualificationScope': pickupQualificationScope,
        'fullPickupParityQualified': fullPickupParityQualified,
        'useParity': useParity.name,
        'useQualificationScope': useQualificationScope,
        'fullUseParityQualified': false,
        'useGaps': useGaps,
        'unprojectedSourceFlags': flags,
        if (definition.heldEffectId ==
            PokemonPassiveHeldEffect.preventEvolution.id)
          'passiveHeldEffect': {
            'sourceSymbol': sourceSymbol,
            'nativeEffectId': definition.heldEffectId,
            'physicalItemId': definition.id,
            'sourceOracle': {
              'archiveSha256': interpretationProfile?.scriptsArchiveHash.value,
              '273_Pokemon':
                  '2cc5db14ec402faedd355afddca951743a7723d1dc0724c45d3f230c2cb116ec',
              'lines': '1036-1037'
            },
            'evolutionScope': ['trade', 'levelUp', 'itemUse'],
            'nativeCombatPolicy': 'explicitPassiveNeutral',
            'consumedByEvolutionPrevention': false,
            'sourceScriptsExecuted': 0,
            'otherSourceHeldEffectsQualified': false,
          },
      }) as Map<String, Object?>;
}

final class SourceEventItemBindings {
  SourceEventItemBindings._({
    required Map<String, SourceEventItemBinding> bindings,
    required Map<String, List<String>> quarantinedSymbols,
    required this.archive,
    required this.sourceSnapshotHash,
    required this.eventProfile,
  })  : bindings = Map.unmodifiable(bindings),
        quarantinedSymbols = Map.unmodifiable({
          for (final row in quarantinedSymbols.entries)
            row.key: List<String>.unmodifiable(row.value),
        });

  final Map<String, SourceEventItemBinding> bindings;
  final Map<String, List<String>> quarantinedSymbols;
  final SourceArchive archive;
  final Sha256Hash sourceSnapshotHash;
  final SourceEventProfile? eventProfile;

  Map<String, Object?> get evidence => _freeze({
        'kind': 'sourceEventItemBindings',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'eventProfile': eventProfile?.toJson(),
        'archiveHash': archive.canonicalHash.value,
        'bindings': {
          for (final row in bindings.entries) row.key: row.value.toJson()
        },
        'quarantinedSymbols': quarantinedSymbols,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'fullPickupParityQualified': false,
        'sourceOracleWitnessRequired': eventProfile?.isQualified ?? false,
        'requiredPickupIntegrationProof': [
          'sourceBoundCatalogInFinalNativeProject',
          'nativeUnitGrantTransaction',
          'helperMessagesAndMedia',
          'selfSwitchCommitOnlyOnSuccess',
          'saveReloadNoDuplicate',
        ],
        'oracleSections': {
          '000':
              'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f',
          '127':
              'b280015f15e892754c90728bdbf23a77c280ebb86413cb51c64793e0b997757a',
          '241':
              'c96fe00962737e464754800079f8b1c43a9d2d88ea446c0357211e40383093b6',
          '264':
              '9f5bb1a5663c6ca9d34fc256f577a7918f5def7e76b2426a37116348af0bf1bc',
          '270':
              '1ec9a83206e82546b286d5524b764942795119ac0b26e26049b9ac66dbbaf2aa',
        },
        'explorationPolicy': {
          'sourceScriptsArchive': eventProfile?.scriptsArchiveHash?.value,
          'itemEffectsSection': 264,
          'itemEffectsSectionHash':
              '9f5bb1a5663c6ca9d34fc256f577a7918f5def7e76b2426a37116348af0bf1bc',
          'sourceLines': {
            'repel': '123-169',
            'escapeRope': '207-229',
            'bicycle': '266-278',
            'fishing': '280-319',
          },
          'runtime': 'avelune',
          'sourceHandlersExecuted': false,
          'sourcePluginsReproduced': false,
          'fullSourceExplorationParityQualified': false,
        },
      }) as Map<String, Object?>;

  Sha256Hash get canonicalHash => canonicalHashOf(evidence);
}

final class SourceEventItemBindingResolver {
  const SourceEventItemBindingResolver();

  Future<Map<String, List<SourceMissingItemBinding>>> suggestMissingBindings({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    required Iterable<String> symbols,
    required SourceEventProfile eventProfile,
    ScanCancellation? cancellation,
  }) async {
    if (!eventProfile.isQualified) return const {};
    final token = cancellation ?? ScanCancellation();
    final base = await read(
        snapshot: snapshot,
        files: files,
        symbols: symbols,
        eventProfile: eventProfile,
        cancellation: token);
    final missing = base.quarantinedSymbols.entries
        .where((entry) =>
            entry.value.length == 1 &&
            entry.value.single == 'item.symbol_missing')
        .map((entry) => entry.key)
        .toSet();
    if (missing.isEmpty) return const {};
    final options = <String, List<SourceMissingItemBinding>>{};
    final catalogs = snapshot.entries
        .where((entry) => RegExp(r'^_converter_sources/[1-4]/Data/items\.dat$')
            .hasMatch(entry.relativePath))
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    for (final entry in catalogs) {
      token.check();
      if (entry.kind != SourceNodeKind.file ||
          entry.sha256 == null ||
          entry.byteLength > 4194304) continue;
      final bytes = await files.read(entry.fileId);
      token.check();
      if (bytes.length != entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw ContractError(
            'source.event_items.source_changed',
            entry.relativePath,
            'The supplemental catalog changed after admission.');
      }
      final MarshalDocument document;
      try {
        document = const MarshalDecoder().decode(bytes,
            limits: const MarshalDecodeLimits(
                maxInputBytes: 4194304, maxNodes: 200000),
            sourcePath: entry.relativePath);
      } on BinaryDecodeError {
        continue;
      }
      final root = document.node(document.rootId);
      if (root.kind != MarshalKind.hash || root.pairs.length > 4096) continue;
      final counts = <String, int>{};
      for (final pair in root.pairs) {
        final key = document.node(pair.key);
        if (key.kind == MarshalKind.symbol && missing.contains(key.name)) {
          counts.update(key.name!, (value) => value + 1, ifAbsent: () => 1);
        }
      }
      final candidates = [
        for (final symbol in missing)
          if (counts[symbol] == 1)
            SourceMissingItemBinding.fromJson({
              'kind': 'sourceMissingItemBinding',
              'version': 1,
              'sourceSymbol': symbol,
              'sourceSnapshotHash': snapshot.canonicalHash.value,
              'sourceFileId': entry.fileId.value,
              'sourceRelativePath': entry.relativePath,
              'sourceSha256': entry.sha256!.value,
              'reason':
                  'Associer explicitement l’entrée absente au catalogue source sélectionné ; conserver sa provenance.',
              'humanConfirmed': true,
            })
      ];
      if (candidates.isEmpty) continue;
      final qualified = await read(
          snapshot: snapshot,
          files: files,
          symbols: candidates.map((value) => value.sourceSymbol),
          eventProfile: eventProfile,
          missingItemBindings: candidates,
          cancellation: token);
      for (final candidate in candidates) {
        if (qualified.bindings[candidate.sourceSymbol]?.pickupQualified ==
                true &&
            !qualified.quarantinedSymbols.containsKey(candidate.sourceSymbol)) {
          options.putIfAbsent(candidate.sourceSymbol, () => []).add(candidate);
        }
      }
    }
    return Map.unmodifiable({
      for (final entry in options.entries)
        entry.key: List<SourceMissingItemBinding>.unmodifiable(entry.value)
    });
  }

  Future<SourceEventItemBindings> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    required Iterable<String> symbols,
    SourceEventProfile? eventProfile,
    List<SourceMissingItemBinding> missingItemBindings = const [],
    SourceEventItemBindingLimits limits = const SourceEventItemBindingLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    if (snapshot.state != SourceScanState.complete) {
      throw ContractError('source.event_items.snapshot_incomplete', r'$',
          'Item bindings require a complete source snapshot.');
    }
    if (eventProfile != null &&
        eventProfile.sourceSnapshotHash != snapshot.canonicalHash) {
      throw ContractError('source.event_items.profile_binding', r'$',
          'Item semantics require the exact event source snapshot.');
    }
    final scriptEntries = snapshot.entries
        .where((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    if (eventProfile != null &&
        scriptEntries.isNotEmpty &&
        eventProfile.scriptsArchiveHash != scriptEntries.single.sha256) {
      throw ContractError('source.event_items.profile_binding', r'$',
          'The event profile must identify the inventoried scripts archive.');
    }
    final requested = <String>{};
    var requestCount = 0;
    for (final symbol in symbols) {
      cancel.check();
      requestCount++;
      if (requestCount > limits.maxRequestedSymbols * 4) {
        throw ContractError('source.event_items.symbol_limit', r'$',
            'The raw item request stream exceeds its bounded quota.');
      }
      if (!RegExp(r'^[A-Z][A-Z0-9_]{0,127}$').hasMatch(symbol)) {
        throw ContractError('source.event_items.symbol_invalid', r'$',
            'Requested items must name literal source symbols.');
      }
      requested.add(symbol);
      if (requested.length > limits.maxRequestedSymbols) {
        throw ContractError('source.event_items.symbol_limit', r'$',
            'The requested item count exceeds its quota.');
      }
    }
    final explicitBindings =
        SourceMissingItemBinding.canonicalize(missingItemBindings);
    for (final binding in explicitBindings) {
      binding.verifySnapshot(snapshot);
    }
    final ordered = requested.toList()..sort();
    final archive = SourceArchive(
        limits: SourceArchiveLimits(
      maxFiles: 5,
      maxFileBytes: limits.maxCatalogBytes,
      maxTotalBytes: limits.maxCatalogBytes,
      maxTotalNodes: limits.maxNodes,
      maxTotalEntries: limits.maxNodes * 4,
      maxTotalLocationCodeUnits: 8388608,
      maxEncodedCodeUnits: limits.maxCatalogBytes * 2 + 4194304,
      maxReferences: limits.maxRequestedSymbols * 65,
    ));
    final bindings = <String, SourceEventItemBinding>{};
    final quarantine = <String, List<String>>{};
    SourceEventItemBindings finish() {
      archive.seal();
      return SourceEventItemBindings._(
          bindings: bindings,
          quarantinedSymbols: quarantine,
          archive: archive,
          sourceSnapshotHash: snapshot.canonicalHash,
          eventProfile: eventProfile);
    }

    if (ordered.isEmpty) return finish();
    const path = 'Data/items.dat';
    final entries = snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) ==
        sourcePathCollisionKey(path));
    if (entries.length != 1 || entries.single.relativePath != path) {
      throw ContractError('source.event_items.catalog_missing', path,
          'The exact compiled item catalog is absent from the snapshot.');
    }
    final entry = entries.single;
    if (entry.kind != SourceNodeKind.file || entry.sha256 == null) {
      throw ContractError('source.event_items.catalog_unattested', path,
          'The compiled item catalog must be an attested regular file.');
    }
    if (entry.byteLength > limits.maxCatalogBytes) {
      throw ContractError('source.event_items.catalog_limit', path,
          'The compiled item catalog exceeds its byte quota.');
    }
    final bytes = await files.read(entry.fileId);
    cancel.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('source.event_items.source_changed', path,
          'The catalog bytes differ from the source snapshot.');
    }
    final archived = archive.add(entry, bytes);
    final document = archived.document;
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.hash) {
      throw ContractError('source.event_items.catalog_shape', path,
          'The compiled item catalog must be an inert symbol hash.');
    }
    if (root.pairs.length > limits.maxCatalogEntries) {
      throw ContractError('source.event_items.catalog_limit', path,
          'The compiled item count exceeds its quota.');
    }
    final selected = <String, List<int>>{};
    for (final pair in root.pairs) {
      cancel.check();
      final key = document.node(pair.key);
      if (key.kind != MarshalKind.symbol || key.name == null) {
        throw ContractError('source.event_items.catalog_shape', path,
            'Compiled item identities must be source symbols.');
      }
      if (requested.contains(key.name) ||
          explicitBindings.any((value) => value.sourceSymbol == key.name)) {
        selected.putIfAbsent(key.name!, () => []).add(pair.value);
      }
    }
    for (final binding in explicitBindings) {
      if ((selected[binding.sourceSymbol] ?? const <int>[]).isNotEmpty) {
        throw ContractError('source.event_items.binding_override', path,
            'Explicit bindings can fill only symbols absent from the canonical catalog.');
      }
    }
    final extraCatalogs =
        <ConverterId, (SourceArchivedFile, Map<String, List<int>>)>{};
    var catalogBytes = entry.byteLength;
    Future<(SourceArchivedFile, Map<String, List<int>>)> supplemental(
        SourceMissingItemBinding binding) async {
      if (extraCatalogs.containsKey(binding.sourceFileId))
        return extraCatalogs[binding.sourceFileId]!;
      final candidate = snapshot.entries
          .singleWhere((value) => value.fileId == binding.sourceFileId);
      if (candidate.byteLength > limits.maxCatalogBytes - catalogBytes) {
        throw ContractError(
            'source.event_items.catalog_limit',
            candidate.relativePath,
            'Combined source catalog bytes exceed the quota.');
      }
      catalogBytes += candidate.byteLength;
      final data = await files.read(candidate.fileId);
      cancel.check();
      if (data.length != candidate.byteLength ||
          crypto.sha256.convert(data).toString() != candidate.sha256!.value) {
        throw ContractError(
            'source.event_items.source_changed',
            candidate.relativePath,
            'The selected catalog changed after admission.');
      }
      final archivedCandidate = archive.add(candidate, data);
      final candidateDoc = archivedCandidate.document;
      final root = candidateDoc.node(candidateDoc.rootId);
      if (root.kind != MarshalKind.hash ||
          root.pairs.length > limits.maxCatalogEntries) {
        throw ContractError(
            'source.event_items.catalog_shape',
            candidate.relativePath,
            'The selected catalog must be a bounded inert symbol hash.');
      }
      final selected = <String, List<int>>{};
      for (final pair in root.pairs) {
        final key = candidateDoc.node(pair.key);
        if (key.kind != MarshalKind.symbol || key.name == null) {
          throw ContractError(
              'source.event_items.catalog_shape',
              candidate.relativePath,
              'Catalog keys must be exact source symbols.');
        }
        if (requested.contains(key.name))
          selected.putIfAbsent(key.name!, () => []).add(pair.value);
      }
      return extraCatalogs[candidate.fileId] = (archivedCandidate, selected);
    }

    SourcePbsProject? moveCatalog;
    NativePsdkCatalog? nativeMoveCatalog;
    Future<SourceEventMachineMoveBinding?> machineMove(String symbol) async {
      final pbs = moveCatalog ??= await const SourcePbsParser().read(
          snapshot: snapshot,
          files: files,
          families: const {SourcePbsFamily.moves},
          limits: SourcePbsLimits(
              maxDocuments: 8,
              maxFileBytes: limits.maxCatalogBytes,
              maxTotalBytes: limits.maxCatalogBytes,
              maxLines: limits.maxNodes,
              maxLineCodeUnits: limits.maxTextCodeUnits,
              maxEntries: limits.maxCatalogEntries,
              maxFields: limits.maxNodes,
              maxTokens: limits.maxNodes * 4,
              maxDiagnostics: limits.maxNodes),
          cancellation: cancel);
      final move = pbs.lookup(SourcePbsIdentity(
          namespace: snapshot.logicalProjectNamespace,
          family: SourcePbsFamily.moves,
          sourceSymbol: symbol));
      if (move == null || move.fieldsNamed('Name').length != 1) return null;
      final field = move.field('Name')!;
      if (field.values.length != 1) return null;
      final name = field.values.single;
      if (name.trim().isEmpty ||
          name.length > limits.maxTextCodeUnits ||
          RegExp(r'[\\<>\x00-\x1f]').hasMatch(name)) {
        return null;
      }
      final document = pbs.documents
          .where((document) => document.entries.contains(move))
          .single;
      final native = nativeMoveCatalog ??= NativePsdkCatalogManifest.builtin();
      String identity(String value) => value.replaceAll('_', '').toUpperCase();
      final candidates = native.movesById.values
          .where((value) =>
              identity(value.id) == identity(symbol) &&
              (value.name == name ||
                  symbol == 'DOUBLEEDGE' &&
                      name == 'Double-Edge' &&
                      value.name == 'Double Edge'))
          .toList();
      final target = candidates.length == 1 ? candidates.single : null;
      return SourceEventMachineMoveBinding._(
          nativeMoveId: target?.id,
          nativeCatalogEvidence: target == null
              ? null
              : {
                  'catalogManifestHash':
                      NativePsdkCatalogManifest.builtinManifestHash,
                  'nativeMoveHash': canonicalHashOf(target.toJson()).value,
                  'identityPolicy': 'uniqueExactSymbolAndKnownOrthography',
                  'sourceMoveName': name,
                  'nativeMoveName': target.name,
                  'battleRules': 'aveluneNative',
                },
          sourceSymbol: symbol,
          name: name,
          file: document.file,
          headerLocator: move.headerLocator,
          nameLocator: field.locator,
          sourceSnapshotHash: snapshot.canonicalHash);
    }

    for (final symbol in ordered) {
      cancel.check();
      var matches = selected[symbol] ?? const <int>[];
      var itemEntry = entry;
      var itemDocument = document;
      final explicit = explicitBindings
          .where((value) => value.sourceSymbol == symbol)
          .singleOrNull;
      if (explicit != null) {
        final selectedCatalog = await supplemental(explicit);
        matches = selectedCatalog.$2[symbol] ?? const <int>[];
        itemEntry = selectedCatalog.$1.entry;
        itemDocument = selectedCatalog.$1.document;
        if (matches.length != 1) {
          throw ContractError(
              'source.event_items.binding_target_invalid',
              explicit.sourceRelativePath,
              'The explicit supplemental symbol must exist exactly once.');
        }
      }
      if (matches.length != 1) {
        quarantine[symbol] = [
          matches.isEmpty ? 'item.symbol_missing' : 'item.symbol_ambiguous'
        ];
        continue;
      }
      try {
        final reader = _ItemReader(itemDocument, matches.single, limits);
        final fields = reader.fields();
        final id = reader.symbol(fields, '@id');
        if (id != symbol) throw const _ItemInvalid('item.identity_mismatch');
        final name = reader.text(fields, '@real_name')!;
        final plural = reader.text(fields, '@real_name_plural')!;
        final portion =
            reader.text(fields, '@real_portion_name', nullable: true) ?? name;
        final portionPlural =
            reader.text(fields, '@real_portion_name_plural', nullable: true) ??
                plural;
        final pocket = reader.integer(fields, '@pocket', 1, 8);
        final price = reader.integer(fields, '@price', 0, 2147483647);
        final sell = reader.integer(fields, '@sell_price', 0, 2147483647);
        reader.integer(fields, '@bp_price', 0, 2147483647);
        final fieldUse = reader.integer(fields, '@field_use', 0, 5);
        final battleUse = reader.integer(fields, '@battle_use', 0, 5);
        final flags = reader.flags(fields);
        final consumable = reader.boolean(fields, '@consumable');
        reader.boolean(fields, '@show_quantity', nullable: true);
        final move = reader.symbol(fields, '@move', nullable: true);
        final description = reader.text(fields, '@real_description');
        reader.text(fields, '@pbs_file_suffix', allowEmpty: true);
        if (name.trim().isEmpty ||
            plural.trim().isEmpty ||
            portion.trim().isEmpty ||
            portionPlural.trim().isEmpty) {
          throw const _ItemInvalid('item.name_empty');
        }
        final unknown = fields.keys
            .where((key) => !_knownFields.contains(key))
            .toList()
          ..sort();
        final reasons = [
          for (final field in unknown) 'item.field_unknown:$field'
        ];
        if (reasons.isNotEmpty) quarantine[symbol] = reasons;
        final qualified =
            (eventProfile?.isQualified ?? false) && reasons.isEmpty;
        final isKey = flags.any((flag) => flag.toLowerCase() == 'keyitem');
        final isMachine = const [3, 4, 5].contains(fieldUse);
        final sourceMachineMove = qualified &&
                isMachine &&
                pocket == 4 &&
                battleUse == 0 &&
                !isKey &&
                move != null
            ? await machineMove(move)
            : null;
        final uses = <ProjectItemUseDefinition>[];
        final useGaps = <String>[];
        var useParity = SourceEventItemUseParity.unqualified;
        final explorationUse = qualified
            ? _nativeExplorationUse(symbol,
                pocket: pocket,
                fieldUse: fieldUse,
                battleUse: battleUse,
                consumable: consumable!,
                isKey: isKey,
                move: move,
                flags: flags)
            : null;
        if (!qualified) {
          useGaps
              .addAll(reasons.isEmpty ? ['item.profile_unqualified'] : reasons);
        } else if (explorationUse != null) {
          uses.add(explorationUse);
          useParity = SourceEventItemUseParity.partial;
          useGaps.addAll([
            'item.use.native_exploration_adaptation',
            'item.use.source_messages_and_plugins_not_reproduced',
            switch (explorationUse.effect) {
              ProjectItemRepelEffectDefinition() =>
                'item.use.native_repel_terrain_and_renewal_policy',
              ProjectItemEscapeRopeEffectDefinition() =>
                'item.use.source_escape_point_replaced_by_native_dungeon_entry',
              ProjectItemBicycleEffectDefinition() =>
                'item.use.native_bicycle_map_terrain_and_animation_policy',
              _ =>
                'item.use.source_fishing_minigame_replaced_by_native_fishing',
            },
          ]);
        } else if (symbol == 'BURNHEAL' &&
            pocket == 2 &&
            fieldUse == 1 &&
            battleUse == 1 &&
            consumable! &&
            !isKey &&
            move == null) {
          uses.add(const ProjectItemUseDefinition(
            contexts: {
              ProjectItemUseContext.overworld,
              ProjectItemUseContext.battle
            },
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.cureStatus(
                mode: ProjectItemStatusCureMode.listed, statusIds: {'burn'}),
          ));
          useParity = SourceEventItemUseParity.qualified;
        } else if (symbol == 'ETHER' &&
            pocket == 2 &&
            fieldUse == 1 &&
            battleUse == 2 &&
            consumable! &&
            !isKey &&
            move == null) {
          uses.add(const ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.restorePp(
                mode: ProjectItemAmountMode.flat, amount: 10),
          ));
          useGaps.add('item.use.battle_restore_pp');
          useParity = SourceEventItemUseParity.partial;
        } else if (isMachine) {
          if (sourceMachineMove?.nativeMoveId != null &&
              consumable != null &&
              (fieldUse == 5 ? consumable : !consumable)) {
            useParity = SourceEventItemUseParity.partial;
            useGaps.add('item.use.source_move_rules_adapted_to_avelune');
          } else {
            useGaps.add('item.use.machine_native_identity_unqualified');
          }
        } else {
          useGaps.add('item.use.source_handler_unqualified');
        }
        final identity = canonicalHashOf({
          'namespace': snapshot.logicalProjectNamespace.value,
          'sourceSymbol': symbol,
        }).value.substring(0, 24);
        final definition = ProjectItemDefinition(
          id: 'source-item-$identity',
          displayName: name,
          pocketId: _pockets[pocket - 1],
          description: description,
          buyPrice: price,
          sellPrice: isKey || const [3, 4].contains(fieldUse) ? null : sell,
          tags: {'source-imported', if (isKey) 'key-item'},
          heldEffectId: qualified && symbol == 'EVERSTONE'
              ? PokemonPassiveHeldEffect.preventEvolution.id
              : null,
          uses: uses,
          machine: sourceMachineMove?.nativeMoveId != null &&
                  useParity == SourceEventItemUseParity.partial
              ? ProjectMoveMachineItemDefinition(
                  moveId: sourceMachineMove!.nativeMoveId!,
                  kind: fieldUse == 4
                      ? ProjectMoveMachineKind.hm
                      : ProjectMoveMachineKind.tm,
                  consumable: consumable!)
              : null,
        ).normalized();
        final references = <String, SourcePreservedData>{};
        final fieldNames = fields.keys.toList()..sort();
        for (final field in fieldNames) {
          references[field] = archive.reference(
              fileId: itemEntry.fileId, nodeId: fields[field]!);
        }
        bindings[symbol] = SourceEventItemBinding._(
          interpretationProfile: eventProfile?.interpretationProfile,
          sourceSymbol: symbol,
          definition: definition,
          sourceCatalogPath: itemEntry.relativePath,
          itemReference: archive.reference(
              fileId: itemEntry.fileId, nodeId: matches.single),
          fieldReferences: references,
          sourcePocketIndex: pocket,
          portionName: portion,
          portionNamePlural: portionPlural,
          flags: flags,
          isKeyItem: isKey,
          isMachine: isMachine,
          isImportant: isKey || const [3, 4].contains(fieldUse),
          moveSymbol: move,
          sourceMachineMove: sourceMachineMove,
          sourceConsumable: consumable!,
          sourceSnapshotHash: snapshot.canonicalHash,
          pickupQualified: qualified,
          useParity: useParity,
          useGaps: useGaps,
        );
      } on _ItemInvalid catch (error) {
        quarantine[symbol] = [error.reason];
      }
    }
    return finish();
  }
}

ProjectItemUseDefinition? _nativeExplorationUse(String symbol,
    {required int pocket,
    required int fieldUse,
    required int battleUse,
    required bool consumable,
    required bool isKey,
    required String? move,
    required List<String> flags}) {
  if (fieldUse != 2 || battleUse != 0 || move != null) return null;
  final effect = switch (symbol) {
    'REPEL' => const ProjectItemEffectDefinition.repel(steps: 100),
    'SUPERREPEL' => const ProjectItemEffectDefinition.repel(steps: 200),
    'MAXREPEL' => const ProjectItemEffectDefinition.repel(steps: 250),
    'ESCAPEROPE' => const ProjectItemEffectDefinition.escapeRope(),
    'BICYCLE' => const ProjectItemEffectDefinition.bicycle(),
    'OLDROD' => const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.oldRod),
    'GOODROD' => const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.goodRod),
    'SUPERROD' => const ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.superRod),
    _ => null,
  };
  if (effect == null) return null;
  final keyEffect = effect is ProjectItemBicycleEffectDefinition ||
      effect is ProjectItemFishingEffectDefinition;
  final expectedFlags = keyEffect
      ? const {'KeyItem'}
      : effect is ProjectItemRepelEffectDefinition
          ? const {'Repel', 'Fling_30'}
          : const <String>{};
  if (pocket != (keyEffect ? 8 : 1) ||
      isKey != keyEffect ||
      consumable == keyEffect ||
      flags.length != expectedFlags.length ||
      !flags.toSet().containsAll(expectedFlags)) {
    return null;
  }
  return ProjectItemUseDefinition(
    contexts: const {ProjectItemUseContext.overworld},
    target: ProjectItemTargetKind.world,
    consumption: keyEffect
        ? ProjectItemConsumptionPolicy.never
        : ProjectItemConsumptionPolicy.onApplied,
    effect: effect,
  );
}

final class _ItemInvalid implements Exception {
  const _ItemInvalid(this.reason);
  final String reason;
}

const _knownFields = {
  '@id',
  '@real_name',
  '@real_name_plural',
  '@real_portion_name',
  '@real_portion_name_plural',
  '@pocket',
  '@price',
  '@sell_price',
  '@bp_price',
  '@field_use',
  '@battle_use',
  '@flags',
  '@consumable',
  '@show_quantity',
  '@move',
  '@real_description',
  '@pbs_file_suffix',
};
const _pockets = [
  'items',
  'medicine',
  'balls',
  'machines',
  'berries',
  'mail',
  'battle-items',
  'key-items',
];

final class _ItemReader {
  const _ItemReader(this.document, this.nodeId, this.limits);
  final MarshalDocument document;
  final int nodeId;
  final SourceEventItemBindingLimits limits;

  Map<String, int> fields() {
    final node = document.node(nodeId);
    if (node.kind != MarshalKind.object ||
        node.className != 'GameData::Item' ||
        node.instanceVariables.length > 64) {
      throw const _ItemInvalid('item.object_invalid');
    }
    final result = <String, int>{};
    for (final pair in node.instanceVariables) {
      final key = document.node(pair.key);
      if (key.kind != MarshalKind.symbol ||
          key.name == null ||
          result.containsKey(key.name)) {
        throw const _ItemInvalid('item.fields_invalid');
      }
      result[key.name!] = pair.value;
    }
    return result;
  }

  MarshalNode field(Map<String, int> fields, String key) {
    final id = fields[key];
    if (id == null) throw _ItemInvalid('item.field_missing:$key');
    return document.node(id);
  }

  String? text(Map<String, int> fields, String key,
      {bool nullable = false, bool allowEmpty = false}) {
    final node = field(fields, key);
    if (nullable && node.kind == MarshalKind.nil) return null;
    if (node.kind != MarshalKind.string) {
      throw _ItemInvalid('item.field_invalid:$key');
    }
    final value = node.text().text;
    if (value == null ||
        value.length > limits.maxTextCodeUnits ||
        (!allowEmpty && value.isEmpty)) {
      throw _ItemInvalid('item.field_invalid:$key');
    }
    return value;
  }

  String? symbol(Map<String, int> fields, String key, {bool nullable = false}) {
    final node = field(fields, key);
    if (nullable && node.kind == MarshalKind.nil) return null;
    if (node.kind != MarshalKind.symbol ||
        node.name == null ||
        !RegExp(r'^[A-Z][A-Z0-9_]{0,127}$').hasMatch(node.name!)) {
      throw _ItemInvalid('item.field_invalid:$key');
    }
    return node.name;
  }

  int integer(Map<String, int> fields, String key, int minimum, int maximum) {
    final node = field(fields, key);
    final value = node.integerValue;
    if (node.kind != MarshalKind.integer ||
        value == null ||
        value < BigInt.from(minimum) ||
        value > BigInt.from(maximum)) {
      throw _ItemInvalid('item.field_invalid:$key');
    }
    return value.toInt();
  }

  bool? boolean(Map<String, int> fields, String key, {bool nullable = false}) {
    final node = field(fields, key);
    if (nullable && node.kind == MarshalKind.nil) return null;
    if (node.kind != MarshalKind.boolean || node.booleanValue == null) {
      throw _ItemInvalid('item.field_invalid:$key');
    }
    return node.booleanValue;
  }

  List<String> flags(Map<String, int> fields) {
    final node = field(fields, '@flags');
    if (node.kind != MarshalKind.array || node.elements.length > 64) {
      throw const _ItemInvalid('item.field_invalid:@flags');
    }
    final result = <String>[];
    for (final id in node.elements) {
      final flag = document.node(id);
      final text = flag.kind == MarshalKind.string ? flag.text().text : null;
      if (text == null || text.isEmpty || text.length > 128) {
        throw const _ItemInvalid('item.field_invalid:@flags');
      }
      result.add(text);
    }
    return result;
  }
}

Object? _freeze(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final row in value.entries) row.key as String: _freeze(row.value),
    });
  }
  if (value is Iterable) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}
