part of 'pokedex_workspace_page.dart';

// Helpers de formatage et de parsing propres au workspace.
//
// Ces fonctions servent seulement à convertir le texte des formulaires UI vers
// les objets applicatifs déjà existants, et inversement. Elles ne remplacent pas
// les validations métier des use cases.

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

List<String> _orderedLocaleKeys(Map<String, String> values) {
  final locales = values.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false);

  // On garde un ordre stable et lisible dans la UI :
  // - `fr` puis `en` si présents, car ce sont les locales déjà privilégiées
  //   ailleurs dans le Pokédex ;
  // - puis le reste en ordre alphabétique pour éviter tout mouvement arbitraire
  //   des champs entre deux rebuilds.
  locales.sort((left, right) {
    final leftPriority = switch (left) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final rightPriority = switch (right) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final priorityCompare = leftPriority.compareTo(rightPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return left.compareTo(right);
  });

  return locales;
}

List<String> _splitNonEmptyLines(String raw) {
  return LineSplitter.split(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _formatLineList(List<String> values) {
  return values.join('\n');
}

String _formatLearnsetLevelUpEntries(
  List<PokemonLearnsetLevelUpEntry> entries,
) {
  return entries
      .map(
        (entry) =>
            '${entry.moveId}|${entry.level}|${entry.source}|${entry.versionGroup}',
      )
      .join('\n');
}

String _formatLearnsetMoveEntries(List<PokemonLearnsetMoveEntry> entries) {
  return entries
      .map((entry) => '${entry.moveId}|${entry.versionGroup}')
      .join('\n');
}

List<PokemonLearnsetLevelUpEntry> _parseLearnsetLevelUpEntries(String raw) {
  final entries = <PokemonLearnsetLevelUpEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} must use moveId|level|source|versionGroup',
      );
    }

    final level = int.tryParse(parts[1].trim());
    if (level == null) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} level must be an integer',
      );
    }

    entries.add(
      PokemonLearnsetLevelUpEntry(
        moveId: parts[0].trim(),
        level: level,
        source: parts[2].trim(),
        versionGroup: parts[3].trim(),
      ),
    );
  }

  return entries;
}

List<PokemonLearnsetMoveEntry> _parseLearnsetMoveEntries(
  String raw, {
  required String label,
}) {
  final entries = <PokemonLearnsetMoveEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 2) {
      throw EditorValidationException(
        'Pokemon learnset $label line ${index + 1} must use moveId|versionGroup',
      );
    }

    entries.add(
      PokemonLearnsetMoveEntry(
        moveId: parts[0].trim(),
        versionGroup: parts[1].trim(),
      ),
    );
  }

  return entries;
}

String _formatEvolutionEntries(List<PokemonEvolutionEntry> entries) {
  return entries
      .map(
        (entry) => [
          entry.targetSpeciesId,
          entry.method,
          entry.minLevel?.toString() ?? '',
          entry.itemId ?? '',
          entry.requiredMoveId ?? '',
          entry.conditionText['fr'] ?? '',
          entry.conditionText['en'] ?? '',
        ].join('|'),
      )
      .join('\n');
}

List<PokemonEvolutionEntry> _parseEvolutionEntries(String raw) {
  final entries = <PokemonEvolutionEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length < 2 || parts.length > 7) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} must use targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn',
      );
    }

    while (parts.length < 7) {
      parts.add('');
    }

    final rawLevel = parts[2].trim();
    final minLevel = rawLevel.isEmpty ? null : int.tryParse(rawLevel);
    if (rawLevel.isNotEmpty && minLevel == null) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} minLevel must be an integer',
      );
    }

    final conditionText = <String, String>{};
    final fr = parts[5].trim();
    final en = parts[6].trim();
    if (fr.isNotEmpty) {
      conditionText['fr'] = fr;
    }
    if (en.isNotEmpty) {
      conditionText['en'] = en;
    }

    entries.add(
      PokemonEvolutionEntry(
        targetSpeciesId: parts[0].trim(),
        method: parts[1].trim(),
        minLevel: minLevel,
        itemId: _trimmedOrNull(parts[3]),
        requiredMoveId: _trimmedOrNull(parts[4]),
        conditionText: conditionText,
      ),
    );
  }

  return entries;
}

String _formatMediaVariantEntries(Map<String, PokemonMediaVariant> variants) {
  return variants.entries
      .map(
        (entry) => [
          entry.key,
          entry.value.frontStatic ?? '',
          entry.value.backStatic ?? '',
          entry.value.frontShinyStatic ?? '',
          entry.value.backShinyStatic ?? '',
          entry.value.icon ?? '',
          entry.value.party ?? '',
          entry.value.overworld ?? '',
          entry.value.portrait ?? '',
          entry.value.cry ?? '',
        ].join('|'),
      )
      .join('\n');
}

String _formatMediaAnimationEntries(Map<String, PokemonMediaVariant> variants) {
  final lines = <String>[];
  for (final entry in variants.entries) {
    for (final animation in entry.value.animations.entries) {
      lines.add(
        [
          entry.key,
          animation.key,
          animation.value.sheet,
          animation.value.animationId,
        ].join('|'),
      );
    }
  }
  return lines.join('\n');
}

Map<String, PokemonMediaVariant> _parseMediaVariants(String raw) {
  final variants = <String, PokemonMediaVariant>{};
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length > 10) {
      throw EditorValidationException(
        'Pokemon media variant line ${index + 1} must use variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry',
      );
    }

    while (parts.length < 10) {
      parts.add('');
    }

    variants[parts[0].trim()] = PokemonMediaVariant(
      frontStatic: _trimmedOrNull(parts[1]),
      backStatic: _trimmedOrNull(parts[2]),
      frontShinyStatic: _trimmedOrNull(parts[3]),
      backShinyStatic: _trimmedOrNull(parts[4]),
      icon: _trimmedOrNull(parts[5]),
      party: _trimmedOrNull(parts[6]),
      overworld: _trimmedOrNull(parts[7]),
      portrait: _trimmedOrNull(parts[8]),
      cry: _trimmedOrNull(parts[9]),
    );
  }

  return variants;
}

void _applyMediaAnimationEntries(
  Map<String, PokemonMediaVariant> variants,
  String raw,
) {
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} must use variantId|animationKey|sheet|animationId',
      );
    }

    final variantId = parts[0].trim();
    if (variantId.isEmpty) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} variantId cannot be empty',
      );
    }

    final currentVariant = variants[variantId] ?? const PokemonMediaVariant();
    final animations = <String, PokemonMediaAnimationRef>{
      ...currentVariant.animations,
      parts[1].trim(): PokemonMediaAnimationRef(
        sheet: parts[2].trim(),
        animationId: parts[3].trim(),
      ),
    };

    variants[variantId] = PokemonMediaVariant(
      frontStatic: currentVariant.frontStatic,
      backStatic: currentVariant.backStatic,
      frontShinyStatic: currentVariant.frontShinyStatic,
      backShinyStatic: currentVariant.backShinyStatic,
      icon: currentVariant.icon,
      party: currentVariant.party,
      overworld: currentVariant.overworld,
      portrait: currentVariant.portrait,
      cry: currentVariant.cry,
      animations: animations,
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
}

/// Carte de base réutilisée pour "pas de projet", "vide" et "erreur".
///
/// On mutualise uniquement la présentation visuelle commune, sans introduire un
/// système d'état générique plus large que le besoin du lot 13.
