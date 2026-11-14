part of 'pokemon_document_transaction.dart';

extension _PokemonDocumentWrites on PokemonDocumentTransaction {
  Future<
    ({
      List<Map<String, Object?>> writes,
      Set<String> changedPaths,
      List<PokemonDocumentReadDependency> dependencies,
    })
  >
  _plannedWrites(
    List<PokemonDocumentWriteRequest> documents, {
    required List<PokemonDocumentReadDependency> expectedDependencies,
    required bool migrateMedia,
  }) async {
    final writes = <Map<String, Object?>>[];
    final changedPaths = <String>{};
    final dependencies = [...expectedDependencies];
    for (final item in documents) {
      final currentBytes = await _readOptional(item.relativePath);
      if (!_sameBytes(currentBytes, item.beforeBytes)) {
        throw PokemonWorkspaceFailure(
          'Le document ${item.relativePath} a changé sur le disque. '
          'Votre brouillon reste ouvert.',
        );
      }
      final kind = switch (item.family) {
        PokemonDocumentFamily.species => PokemonDocumentKind.species,
        PokemonDocumentFamily.learnset => PokemonDocumentKind.learnset,
        PokemonDocumentFamily.evolution => PokemonDocumentKind.evolution,
        PokemonDocumentFamily.media => PokemonDocumentKind.media,
      };
      final json = PokemonJsonDocument.fromJson(kind, item.document).toJson();
      final after = utf8.encode(
        '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      );
      if (currentBytes != null && _sameBytes(currentBytes, after)) {
        final identity = switch (item.family) {
          PokemonDocumentFamily.species => pokemonSpeciesResourceIdentity(
            json['id'] as String,
          ),
          PokemonDocumentFamily.media => pokemonMediaResourceIdentity(
            json['speciesId'] as String,
          ),
          PokemonDocumentFamily.learnset =>
            'pokemonLearnset:${item.relativePath}',
          PokemonDocumentFamily.evolution =>
            'pokemonEvolution:${item.relativePath}',
        };
        dependencies.add((
          resourceIdentity: identity,
          relativePath: item.relativePath,
          beforeBytes: currentBytes,
        ));
        continue;
      }
      changedPaths.add(item.relativePath);
      writes.add({
        'actionId': 'pokemon.${item.family.name}.write',
        'parameters': {
          'relativePath': item.relativePath,
          'document': item.document,
          if (migrateMedia) 'migrateSchema': true,
          if (item.beforeBytes != null)
            'beforeBytesBase64': base64Encode(item.beforeBytes!),
        },
      });
    }
    return (
      writes: writes,
      changedPaths: changedPaths,
      dependencies: dependencies,
    );
  }

  Future<List<int>?> _readOptional(String path) async {
    final probe = reader;
    if (probe is ProjectResourceProbeReader) {
      final result = await (probe as ProjectResourceProbeReader).probeResource(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (result.status == ProjectResourceProbeStatus.missing) return null;
      if (result.status != ProjectResourceProbeStatus.exists) {
        throw PokemonWorkspaceFailure('Document inaccessible : $path');
      }
    }
    return reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: path,
    );
  }

  bool _sameBytes(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
