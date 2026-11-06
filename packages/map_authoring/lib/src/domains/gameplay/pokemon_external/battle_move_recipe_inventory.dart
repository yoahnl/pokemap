import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../../ports/project_file_reader.dart';
import '../../../ports/transaction_file_gateway.dart';
import '../../../workspace/project_open_service.dart';
import '../../../workspace/workspace_handle_store.dart';
import 'avelune_catalog_release.dart';
import 'battle_move_recipe_selection.dart';

enum BattleMoveRecipeInventoryStatus { eligible, custom, uncertain }

enum BattleMoveRecipeInventoryReason {
  ready,
  custom,
  invalidIdentity,
  duplicateIdentity,
  unknownIdentity,
  uncertainProvenance,
  invalidBinding,
}

final class BattleMoveRecipeInventoryEntry {
  const BattleMoveRecipeInventoryEntry({
    required this.index,
    required this.projectMoveId,
    required this.catalogMoveId,
    required this.status,
    required this.reason,
    required this.existing,
    this.bindingRevision,
  });

  final int index;
  final String? projectMoveId;
  final String? catalogMoveId;
  final BattleMoveRecipeInventoryStatus status;
  final BattleMoveRecipeInventoryReason reason;
  final BattleRecipeProjectBinding? existing;
  final String? bindingRevision;
}

final class BattleMoveRecipeInventory {
  BattleMoveRecipeInventory({
    required this.catalogRelease,
    required this.moves,
    int? total,
    this.movesPath,
    this.movesRevision,
  }) : total = total ?? moves.length;

  final String catalogRelease;
  final List<BattleMoveRecipeInventoryEntry> moves;
  final int total;
  final String? movesPath;
  final String? movesRevision;

  Future<BattleMoveRecipeSelection> select(BattleMoveRecipeInventoryEntry entry,
      BattleMoveRecipeCatalogSource source,
      {void Function()? check}) async {
    if (!moves.any((move) => identical(move, entry)) ||
        source.media.release != catalogRelease) {
      throw StateError('Inventory and source do not match.');
    }
    if (entry.status == BattleMoveRecipeInventoryStatus.custom) {
      return const BattleMoveRecipeSelection(
          BattleMoveRecipeSelectionStatus.custom);
    }
    if (entry.status == BattleMoveRecipeInventoryStatus.uncertain) {
      return const BattleMoveRecipeSelection(
          BattleMoveRecipeSelectionStatus.uncertain);
    }
    final id = entry.projectMoveId;
    if (id == null || battleRecipeCatalogMoveId(id) != entry.catalogMoveId) {
      throw StateError('Move identity changed.');
    }
    final candidates = await source.list(id, check: check);
    return selectBattleMoveRecipe(candidates, existing: entry.existing);
  }
}

final class BattleMoveRecipeInventoryReader {
  const BattleMoveRecipeInventoryReader(this.openService);

  final ProjectOpenService openService;

  Future<BattleMoveRecipeInventory> read(ProjectHandle projectHandle,
      {int startIndex = 0, int? limit}) async {
    if (startIndex < 0 || (limit != null && limit < 1)) {
      throw const FormatException('Invalid move inventory bounds.');
    }
    final reader = await openService
        .catalogProject(projectHandle, metadataFields: const {'pokemon'});
    if (reader == null) {
      throw const FormatException('A working project catalog is required.');
    }
    return reader.read((catalog) async {
      final pokemon = catalog.projectMetadata.pokemon;
      final movesPath = pokemon.catalogFiles['moves'];
      if (!pokemon.enabled || movesPath == null) {
        throw const FormatException('Move catalog is unavailable.');
      }
      final revisions = <String, String?>{};
      Future<List<int>?> capture(String path, int limit) async {
        validateProjectRelativePath(path);
        final payload = await reader.store.gateway.captureResourcePayload(path);
        revisions[path] = payload?.resourceRevision;
        if (payload == null) return null;
        try {
          if (payload.byteLength > limit) {
            throw const FormatException(
                'Move inventory dependency is too large.');
          }
          return await payload.readBytes();
        } finally {
          await payload.release();
        }
      }

      final bytes = await capture(movesPath, 16 * 1024 * 1024);
      if (bytes == null) {
        throw const FormatException('Move catalog is missing.');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> || decoded['entries'] is! List) {
        throw const FormatException('Invalid move catalog.');
      }
      final file = PokemonCatalogFile.fromJson(decoded);
      if (file.catalog != 'moves') {
        throw const FormatException('Invalid move catalog identity.');
      }
      final rows = decoded['entries'] as List;
      if (startIndex > rows.length) {
        throw const FormatException(
            'Move inventory starts beyond the catalog.');
      }
      final counts = <String, int>{};
      final catalogCounts = <String, int>{};
      for (final row in rows) {
        final id = row is Map ? row['id'] : null;
        if (id is String) {
          counts[id] = (counts[id] ?? 0) + 1;
          final source = row is Map ? row['source'] : null;
          if (source is! String || source.trim() != 'project_custom') {
            final catalogId = battleRecipeCatalogMoveId(id);
            if (catalogId != null) {
              catalogCounts[catalogId] = (catalogCounts[catalogId] ?? 0) + 1;
            }
          }
        }
      }
      final entries = <BattleMoveRecipeInventoryEntry>[];
      final bindings = <String, BattleRecipeProjectBinding?>{};
      final invalidBindings = <String>{};
      final validId = RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$');
      final end = limit == null
          ? rows.length
          : (startIndex + limit).clamp(0, rows.length);
      for (var index = startIndex; index < end; index++) {
        final raw = rows[index];
        final id =
            raw is Map && raw['id'] is String ? raw['id'] as String : null;
        final source = raw is Map && raw['source'] is String
            ? (raw['source'] as String).trim()
            : '';
        BattleRecipeProjectBinding? existing;
        if (id != null && validId.hasMatch(id) && id.length <= 128) {
          if (!bindings.containsKey(id)) {
            try {
              final data = await capture(battleRecipeBindingPath(id), 65536);
              if (data != null) {
                final value = jsonDecode(utf8.decode(data));
                if (value is! Map<String, dynamic>) {
                  throw const FormatException('Invalid move binding.');
                }
                final binding = BattleRecipeProjectBinding.fromJson(value);
                if (binding.binding.projectMoveId != id) {
                  throw const FormatException(
                      'Binding belongs to another move.');
                }
                bindings[id] = binding;
              } else {
                bindings[id] = null;
              }
            } on FormatException {
              invalidBindings.add(id);
              bindings[id] = null;
            } on TypeError {
              invalidBindings.add(id);
              bindings[id] = null;
            }
          }
          existing = bindings[id];
        }
        final catalogId = id == null ? null : battleRecipeCatalogMoveId(id);
        final refs = raw is Map ? raw['sourceRefs'] : null;
        final showdownId = refs is Map ? refs['showdownMoveId'] : null;
        final provenanceValid = source == 'heartgold-fr-rom' ||
            (source == 'showdown' &&
                catalogId != null &&
                showdownId == catalogId.replaceAll('-', ''));
        final reason = source == 'project_custom'
            ? BattleMoveRecipeInventoryReason.custom
            : id == null || id.length > 128 || !validId.hasMatch(id)
                ? BattleMoveRecipeInventoryReason.invalidIdentity
                : counts[id] != 1 ||
                        (catalogId != null && catalogCounts[catalogId] != 1)
                    ? BattleMoveRecipeInventoryReason.duplicateIdentity
                    : catalogId == null
                        ? BattleMoveRecipeInventoryReason.unknownIdentity
                        : !provenanceValid
                            ? BattleMoveRecipeInventoryReason
                                .uncertainProvenance
                            : invalidBindings.contains(id)
                                ? BattleMoveRecipeInventoryReason.invalidBinding
                                : BattleMoveRecipeInventoryReason.ready;
        entries.add(BattleMoveRecipeInventoryEntry(
          index: index,
          projectMoveId: id,
          catalogMoveId: catalogId,
          status: switch (reason) {
            BattleMoveRecipeInventoryReason.ready =>
              BattleMoveRecipeInventoryStatus.eligible,
            BattleMoveRecipeInventoryReason.custom =>
              BattleMoveRecipeInventoryStatus.custom,
            _ => BattleMoveRecipeInventoryStatus.uncertain,
          },
          reason: reason,
          existing: existing,
          bindingRevision:
              id != null && validId.hasMatch(id) && id.length <= 128
                  ? revisions[battleRecipeBindingPath(id)]
                  : null,
        ));
      }
      for (final entry in revisions.entries) {
        if (await reader.store.gateway.readResourceRevision(entry.key) !=
            entry.value) {
          throw StateError('Move inventory changed while being read.');
        }
      }
      return BattleMoveRecipeInventory(
        catalogRelease: pokemon.catalogRelease ?? aveluneCatalogRelease,
        moves: List.unmodifiable(entries),
        total: rows.length,
        movesPath: movesPath,
        movesRevision: revisions[movesPath],
      );
    });
  }
}
