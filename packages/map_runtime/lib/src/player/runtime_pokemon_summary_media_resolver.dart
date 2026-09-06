import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_pokemon_summary.dart';

final class RuntimePokemonSummaryMediaResolver {
  RuntimePokemonSummaryMediaResolver({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;
  final Map<String, Future<PokemonMediaFile?>> _media = {};

  Future<RuntimePokemonSummaryMediaSnapshot> resolve(
    RuntimePokemonMediaIdentity identity,
  ) async {
    if (!pokemonConfig.enabled) {
      return const RuntimePokemonSummaryMediaSnapshot();
    }
    final mediaId = identity.mediaRef?.trim() ?? identity.speciesId.trim();
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(mediaId)) {
      return const RuntimePokemonSummaryMediaSnapshot();
    }
    final media = await _media.putIfAbsent(mediaId, () => _loadMedia(mediaId));
    if (media == null) return const RuntimePokemonSummaryMediaSnapshot();
    final explicitForm = identity.formId?.trim();
    final speciesDefaultForm = identity.defaultFormId?.trim();
    final formId = explicitForm != null && explicitForm.isNotEmpty
        ? explicitForm
        : speciesDefaultForm != null && speciesDefaultForm.isNotEmpty
            ? speciesDefaultForm
            : media.defaultFormId;
    final variant = media.variants[formId];
    if (variant == null) return const RuntimePokemonSummaryMediaSnapshot();
    if (identity.isShiny) {
      final shiny = await _image(
        variant.frontShinyStatic,
        ProjectMenuImageSampling.pixelArt,
      );
      return RuntimePokemonSummaryMediaSnapshot(
        thumbnail: shiny,
        illustration: shiny,
      );
    }
    final party = await _image(variant.party, ProjectMenuImageSampling.smooth);
    final icon = await _image(variant.icon, ProjectMenuImageSampling.smooth);
    final portrait =
        await _image(variant.portrait, ProjectMenuImageSampling.smooth);
    final front =
        await _image(variant.frontStatic, ProjectMenuImageSampling.pixelArt);
    return RuntimePokemonSummaryMediaSnapshot(
      thumbnail: party ?? icon ?? portrait ?? front,
      illustration: portrait ?? front ?? party ?? icon,
    );
  }

  Future<PokemonMediaFile?> _loadMedia(String mediaId) async {
    try {
      final path = await _existingLocalPath(
        '${pokemonConfig.mediaDir}/$mediaId.json',
      );
      if (path == null) return null;
      final decoded = jsonDecode(await File(path).readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final media = PokemonMediaFile.fromJson(decoded);
      return media.speciesId == mediaId ? media : null;
    } on Object {
      return null;
    }
  }

  Future<RuntimePokemonLocalImageSnapshot?> _image(
    String? relativePath,
    ProjectMenuImageSampling sampling,
  ) async {
    final path = await _existingLocalPath(relativePath);
    return path == null
        ? null
        : RuntimePokemonLocalImageSnapshot(
            absoluteFilePath: path,
            sampling: sampling,
          );
  }

  Future<String?> _existingLocalPath(String? rawPath) async {
    final relativePath = rawPath?.trim().replaceAll('\\', '/');
    if (relativePath == null ||
        relativePath.isEmpty ||
        p.posix.isAbsolute(relativePath) ||
        p.windows.isAbsolute(relativePath) ||
        p.posix.split(relativePath).contains('..') ||
        Uri.tryParse(relativePath)?.hasScheme == true) {
      return null;
    }
    try {
      final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
      final file = File(p.join(root, relativePath));
      if (!await file.exists()) return null;
      final resolved = await file.resolveSymbolicLinks();
      return p.isWithin(root, resolved) ? resolved : null;
    } on FileSystemException {
      return null;
    }
  }
}
