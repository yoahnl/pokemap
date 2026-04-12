import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

// Projection ultra légère d'une espèce pour l'écran Pokédex in-game.
// On ne charge que ce qu'il faut pour la liste et la fiche simple phase 10.
class RuntimePokedexEntry {
  const RuntimePokedexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.isEnabledInProject,
    this.flavorText,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final bool isEnabledInProject;
  final String? flavorText;
}

// Le host runtime ne dépend pas du package editor.
// On relit donc les JSON espèces du projet directement depuis le manifest pour
// construire une petite vue lecture seule adaptée à la phase 10.
// Le contrat de lecture ici doit suivre le schéma réellement consolidé du repo,
// pas un ancien shape supposé du côté editor.
Future<List<RuntimePokedexEntry>> loadRuntimePokedexEntries({
  required String projectFilePath,
}) async {
  final projectFile = File(projectFilePath);
  final projectJson =
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(projectJson);
  if (!manifest.pokemon.enabled) {
    return const <RuntimePokedexEntry>[];
  }

  final projectRootUri = projectFile.parent.uri;
  final speciesDirectoryUri = projectRootUri.resolve(
    '${manifest.pokemon.speciesDir}/',
  );
  final speciesDirectory = Directory.fromUri(speciesDirectoryUri);
  if (!await speciesDirectory.exists()) {
    return const <RuntimePokedexEntry>[];
  }

  final entries = <RuntimePokedexEntry>[];
  await for (final entity in speciesDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) {
      continue;
    }
    final speciesJson =
        jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
    entries.add(_parseRuntimePokedexEntry(speciesJson));
  }

  entries.sort((left, right) {
    final dexCompare = left.nationalDex.compareTo(right.nationalDex);
    if (dexCompare != 0) {
      return dexCompare;
    }
    return left.id.compareTo(right.id);
  });

  return List<RuntimePokedexEntry>.unmodifiable(entries);
}

// Cette normalisation garde la logique simple :
// on lit l'id, le dex, le nom principal, les types et quelques métadonnées
// visibles, sans essayer de reconstruire toute la fiche Pokédex de l'éditeur.
// Les types viennent du shape actuel `typing.types`.
// On garde leur ordre source et on retire seulement les valeurs vides pour ne
// pas propager de bruit dans l'UI runtime.
RuntimePokedexEntry _parseRuntimePokedexEntry(Map<String, dynamic> json) {
  final id = (json['id'] as String?)?.trim() ?? '';
  final nationalDex = (json['nationalDex'] as num?)?.toInt() ?? 0;
  final names = _readStringMap(json['names']);
  final types = _readTypes(json['typing']);
  final classification = (json['classification'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
  final dexContent = (json['dexContent'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};

  return RuntimePokedexEntry(
    id: id,
    nationalDex: nationalDex,
    primaryName: _pickPrimaryName(names) ?? id,
    types: List<String>.unmodifiable(types),
    isEnabledInProject: (classification['isEnabledInProject'] as bool?) ?? true,
    flavorText: _readTrimmedString(dexContent['flavorText']),
  );
}

// Le loader runtime reste volontairement minimal et indépendant de `map_editor`.
// Il lit donc directement le bloc `typing` tel qu'il est stocké dans les JSON
// espèces du projet, avec le shape consolidé `typing.types`.
// Le mini-fix ne conserve pas de fallback `primary/secondary`, parce que
// l'audit du repo n'a trouvé que le schéma consolidé `types` côté species.
List<String> _readTypes(Object? rawTyping) {
  final typing = rawTyping as Map<String, dynamic>?;
  final rawTypes = typing?['types'];
  if (rawTypes is! List) {
    return const <String>[];
  }

  final normalized = <String>[];
  for (final rawType in rawTypes) {
    final type = _readTrimmedString(rawType);
    if (type == null) {
      continue;
    }
    normalized.add(type);
  }
  return List<String>.unmodifiable(normalized);
}

// Les names du JSON peuvent contenir des clés ou valeurs vides.
// On les nettoie ici pour éviter de propager des chaînes inutilisables à l'UI.
Map<String, String> _readStringMap(Object? raw) {
  if (raw is! Map) {
    return const <String, String>{};
  }
  final normalized = <String, String>{};
  for (final entry in raw.entries) {
    final key = _readTrimmedString(entry.key);
    final value = _readTrimmedString(entry.value);
    if (key == null || value == null) {
      continue;
    }
    normalized[key] = value;
  }
  return normalized;
}

// On garde une priorité de lecture simple et explicite pour l'écran in-game.
// Si le projet fournit `en`, on l'affiche d'abord ; sinon `fr` ; sinon le
// premier nom exploitable restant.
String? _pickPrimaryName(Map<String, String> names) {
  for (final preferredKey in const <String>['en', 'fr']) {
    final value = names[preferredKey];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  for (final value in names.values) {
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

// Helper commun de trim pour éviter de répéter la même hygiène de lecture
// à chaque champ texte issu du JSON.
String? _readTrimmedString(Object? raw) {
  final value = raw as String?;
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
