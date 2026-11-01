import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'game_package_export_profile.dart';

final class Gen5BattleSourceExportPlan {
  Gen5BattleSourceExportPlan._(this._bindings)
      : exactPaths = Set.unmodifiable({
          for (final item in _bindings.entries) ...{
            item.key,
            item.value.binding.bundlePath,
          },
        });

  factory Gen5BattleSourceExportPlan.fromBindingCandidates(
    Map<String, List<int>> candidates,
  ) {
    final bindings =
        <String, ({Gen5BattleSourceBinding binding, String digest})>{};
    for (final entry in candidates.entries) {
      if (!isBindingCandidate(entry.key)) continue;
      Object? value;
      try {
        value = jsonDecode(utf8.decode(entry.value));
      } on FormatException {
        continue;
      }
      if (value is! Map ||
          value['kind'] != 'avelune.gen5-battle-source-binding') {
        continue;
      }
      try {
        final species = value['projectSpeciesId'];
        final dex = value['nationalDex'];
        if (species is! String || dex is! int) {
          throw const FormatException('Missing binding identity');
        }
        final bytes = Uint8List.fromList(entry.value);
        final digest = sha256.convert(bytes).toString();
        final binding = Gen5BattleSourceBinding.decode(
          bytes,
          expectedSha256: digest,
          expectedProjectSpeciesId: species,
          expectedProjectNationalDex: dex,
        );
        if (entry.key != binding.bindingPath) {
          throw const FormatException(
              'Binding path does not match its identity');
        }
        bindings[entry.key] = (binding: binding, digest: digest);
      } on FormatException catch (error) {
        throw GamePackageExportException(
          code: 'gen5_battle_source.invalid_binding',
          path: entry.key,
          message: 'Gen 5 source binding is malformed or misplaced.',
          cause: error,
        );
      }
    }
    return Gen5BattleSourceExportPlan._(Map.unmodifiable(bindings));
  }

  static const _bindingDirectory = 'data/pokemon/gen5_battle_sources/bindings/';
  final Map<String, ({Gen5BattleSourceBinding binding, String digest})>
      _bindings;
  final Set<String> exactPaths;

  static bool isBindingCandidate(String path) =>
      path.startsWith(_bindingDirectory) &&
      !path.substring(_bindingDirectory.length).contains('/') &&
      path.endsWith('.json');

  void validate({
    required Map<String, List<int>> files,
    required Iterable<({String id, int nationalDex})> projectSpecies,
  }) {
    final species = <String, List<int>>{};
    for (final item in projectSpecies) {
      (species[item.id] ??= []).add(item.nationalDex);
    }
    for (final entry in _bindings.entries) {
      final path = entry.key;
      final binding = entry.value.binding;
      final numbers = species[binding.projectSpeciesId];
      if (numbers == null ||
          numbers.length != 1 ||
          numbers.single != binding.nationalDex) {
        throw GamePackageExportException(
          code: 'gen5_battle_source.identity_mismatch',
          path: path,
          message: 'Gen 5 source binding does not match one project species.',
        );
      }
      final currentBinding = files[path];
      if (currentBinding == null ||
          sha256.convert(currentBinding).toString() != entry.value.digest) {
        throw GamePackageExportException(
          code: 'gen5_battle_source.invalid_binding',
          path: path,
          message: 'Gen 5 source binding changed during export.',
        );
      }
      final bundle = files[binding.bundlePath];
      if (bundle == null) {
        throw GamePackageExportException(
          code: 'gen5_battle_source.invalid_bundle',
          path: binding.bundlePath,
          message: 'Gen 5 source bundle is missing.',
        );
      }
      try {
        binding.resolve(
          Uint8List.fromList(bundle),
          expectedProjectSpeciesId: binding.projectSpeciesId,
          expectedProjectNationalDex: numbers.single,
        );
      } on FormatException catch (error) {
        throw GamePackageExportException(
          code: 'gen5_battle_source.invalid_bundle',
          path: binding.bundlePath,
          message: 'Gen 5 source bundle is incomplete or corrupted.',
          cause: error,
        );
      }
    }
  }
}
