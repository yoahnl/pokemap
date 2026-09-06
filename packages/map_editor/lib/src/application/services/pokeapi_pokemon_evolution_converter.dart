import '../errors/application_errors.dart';
import 'package:map_core/map_core.dart';

/// Convertit une payload PokeAPI de type `/evolution-chain/{id}` vers
/// [PokemonEvolutionFile] pour une espèce donnée.
///
/// Cette fondation couvre seulement le lot 32 :
/// - parcours d'une chaîne d'évolution locale ;
/// - extraction de la pré-évolution et des évolutions directes ;
/// - mapping vers le contrat interne existant.
///
/// Non-objectifs explicites :
/// - pas de réseau ;
/// - pas d'écriture workspace ;
/// - pas de modélisation exhaustive de toutes les conditions PokeAPI.
class PokeApiPokemonEvolutionConverter {
  const PokeApiPokemonEvolutionConverter();

  PokemonEvolutionFile convert({
    required String speciesId,
    required Map<String, dynamic> payload,
  }) {
    final normalizedSpeciesId = _normalizeSpeciesId(speciesId);
    if (normalizedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI evolution speciesId cannot be empty',
      );
    }

    final rawChain = payload['chain'];
    if (rawChain is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI evolution payload must contain a chain object',
      );
    }

    final located = _findChainNode(
      rawChain.cast<String, dynamic>(),
      targetSpeciesId: normalizedSpeciesId,
      parentSpeciesId: null,
    );

    if (located == null) {
      throw EditorValidationException(
        'PokeAPI evolution chain does not include species "$normalizedSpeciesId"',
      );
    }

    final evolutions = <PokemonEvolutionEntry>[];
    final rawChildren = located.node['evolves_to'];
    if (rawChildren is! List) {
      throw const EditorPersistenceException(
        'PokeAPI evolution chain nodes must contain an evolves_to list',
      );
    }

    for (var childIndex = 0; childIndex < rawChildren.length; childIndex++) {
      final rawChild = rawChildren[childIndex];
      if (rawChild is! Map) {
        throw EditorPersistenceException(
          'PokeAPI evolution child at index $childIndex must be an object',
        );
      }
      final child = rawChild.cast<String, dynamic>();
      final targetSpeciesId = _normalizeSpeciesId(
        _readNamedResourceId(
          child['species'],
          field: 'chain.evolves_to[$childIndex].species',
        ),
      );

      final rawDetails = child['evolution_details'];
      if (rawDetails is! List) {
        throw EditorPersistenceException(
          'PokeAPI evolution child "$targetSpeciesId" must define '
          'evolution_details',
        );
      }

      if (rawDetails.isEmpty) {
        if (normalizedSpeciesId == 'phione' && targetSpeciesId == 'manaphy') {
          continue;
        }
        evolutions.add(
          PokemonEvolutionEntry(
            targetSpeciesId: targetSpeciesId,
            method: 'unknown',
            conditionText: const <String, String>{
              'en': 'Evolution condition unspecified in source payload.',
            },
          ),
        );
        continue;
      }

      for (
        var detailIndex = 0;
        detailIndex < rawDetails.length;
        detailIndex++
      ) {
        final rawDetail = rawDetails[detailIndex];
        if (rawDetail is! Map) {
          throw EditorPersistenceException(
            'PokeAPI evolution detail for "$targetSpeciesId" at index '
            '$detailIndex must be an object',
          );
        }

        final detail = rawDetail.cast<String, dynamic>();
        evolutions.add(
          PokemonEvolutionEntry(
            targetSpeciesId: targetSpeciesId,
            method: _readMethod(detail),
            minLevel: (detail['min_level'] as num?)?.toInt(),
            minFriendship: (detail['min_happiness'] as num?)?.toInt(),
            itemId: _readOptionalMoveId(detail['item']),
            // Le modèle supporte déjà `requiredMoveId`, donc on n'abandonne pas
            // cette information dans `conditionText`.
            requiredMoveId: _readOptionalMoveId(detail['known_move']),
            conditionText: _buildConditionText(detail),
          ),
        );
      }
    }

    final file = PokemonEvolutionFile(
      speciesId: normalizedSpeciesId,
      preEvolution: normalizedSpeciesId == 'manaphy' && located.parentSpeciesId == 'phione'
          ? null : located.parentSpeciesId,
      evolutions: _sortEvolutions(evolutions),
    );
    return file;
  }

  _LocatedChainNode? _findChainNode(
    Map<String, dynamic> node, {
    required String targetSpeciesId,
    required String? parentSpeciesId,
  }) {
    final currentSpeciesId = _normalizeSpeciesId(
      _readNamedResourceId(node['species'], field: 'chain.species'),
    );

    if (currentSpeciesId == targetSpeciesId) {
      return _LocatedChainNode(node: node, parentSpeciesId: parentSpeciesId);
    }

    final rawChildren = node['evolves_to'];
    if (rawChildren is! List) {
      throw const EditorPersistenceException(
        'PokeAPI evolution chain nodes must contain an evolves_to list',
      );
    }

    for (final rawChild in rawChildren) {
      if (rawChild is! Map) {
        throw const EditorPersistenceException(
          'PokeAPI evolution chain child must be an object',
        );
      }

      final located = _findChainNode(
        rawChild.cast<String, dynamic>(),
        targetSpeciesId: targetSpeciesId,
        parentSpeciesId: currentSpeciesId,
      );
      if (located != null) {
        return located;
      }
    }

    return null;
  }

  String _readMethod(Map<String, dynamic> detail) {
    final trigger = _readOptionalNamedResourceId(detail['trigger']);
    if (trigger == null || trigger.isEmpty) {
      return 'unknown';
    }

    final additional = detail.entries.where(
      (entry) =>
          !const {
            'trigger',
            'min_level',
            'min_happiness',
            'item',
            'known_move',
          }.contains(entry.key) &&
          _hasConditionValue(entry.value),
    );
    if (additional.isNotEmpty ||
        (trigger == 'use-item' &&
            (detail['min_happiness'] != null ||
                detail['known_move'] != null))) {
      return 'conditional';
    }
    return switch (trigger) {
      'level-up'
          when detail['min_happiness'] != null &&
              detail['known_move'] != null =>
        'conditional',
      'level-up' when detail['min_happiness'] != null => 'friendship',
      'level-up' when detail['known_move'] != null => 'known_move',
      'level-up' => 'level_up',
      'use-item' => 'use_item',
      _ => trigger.replaceAll('-', '_'),
    };
  }

  bool _hasConditionValue(Object? value) =>
      value != null &&
      value != false &&
      value != '' &&
      (value is! List || value.isNotEmpty) &&
      (value is! Map || value.isNotEmpty);

  Map<String, String> _buildConditionText(Map<String, dynamic> detail) {
    final parts = <String>[];
    if (_readMethod(detail) == 'conditional') {
      parts.add('Trigger: ${_readOptionalNamedResourceId(detail['trigger'])}');
    }

    final minHappiness = (detail['min_happiness'] as num?)?.toInt();
    if (minHappiness != null) {
      parts.add('Happiness >= $minHappiness');
    }

    final minAffection = (detail['min_affection'] as num?)?.toInt();
    if (minAffection != null) {
      parts.add('Affection >= $minAffection');
    }

    final minBeauty = (detail['min_beauty'] as num?)?.toInt();
    if (minBeauty != null) {
      parts.add('Beauty >= $minBeauty');
    }

    final timeOfDay = (detail['time_of_day'] as String?)?.trim();
    if (timeOfDay != null && timeOfDay.isNotEmpty) {
      parts.add('Time: $timeOfDay');
    }

    final locationId = _readOptionalNamedResourceId(detail['location']);
    if (locationId != null && locationId.isNotEmpty) {
      parts.add('Location: $locationId');
    }

    final heldItemId = _readOptionalNamedResourceId(detail['held_item']);
    if (heldItemId != null && heldItemId.isNotEmpty) {
      parts.add('Hold item: $heldItemId');
    }

    final tradeSpeciesId = _readOptionalNamedResourceId(
      detail['trade_species'],
    );
    if (tradeSpeciesId != null && tradeSpeciesId.isNotEmpty) {
      parts.add('Trade species: $tradeSpeciesId');
    }

    final partySpeciesId = _readOptionalNamedResourceId(
      detail['party_species'],
    );
    if (partySpeciesId != null && partySpeciesId.isNotEmpty) {
      parts.add('Party species: $partySpeciesId');
    }

    final partyTypeId = _readOptionalNamedResourceId(detail['party_type']);
    if (partyTypeId != null && partyTypeId.isNotEmpty) {
      parts.add('Party type: $partyTypeId');
    }

    final knownMoveTypeId = _readOptionalNamedResourceId(
      detail['known_move_type'],
    );
    if (knownMoveTypeId != null && knownMoveTypeId.isNotEmpty) {
      parts.add('Known move type: $knownMoveTypeId');
    }

    final gender = (detail['gender'] as num?)?.toInt();
    if (gender != null) {
      parts.add(switch (gender) {
        1 => 'Gender: female',
        2 => 'Gender: male',
        _ => 'Gender: $gender',
      });
    }

    final relativePhysicalStats = (detail['relative_physical_stats'] as num?)
        ?.toInt();
    if (relativePhysicalStats != null) {
      parts.add(switch (relativePhysicalStats) {
        1 => 'Attack greater than Defense',
        0 => 'Attack equal to Defense',
        -1 => 'Attack lower than Defense',
        _ => 'Relative physical stats: $relativePhysicalStats',
      });
    }

    if (detail['needs_overworld_rain'] == true) {
      parts.add('Needs overworld rain');
    }

    if (detail['turn_upside_down'] == true) {
      parts.add('Turn system upside down');
    }

    const describedFields = {
      'trigger',
      'min_level',
      'min_happiness',
      'item',
      'known_move',
      'min_affection',
      'min_beauty',
      'time_of_day',
      'location',
      'held_item',
      'trade_species',
      'party_species',
      'party_type',
      'known_move_type',
      'gender',
      'relative_physical_stats',
      'needs_overworld_rain',
      'turn_upside_down',
    };
    for (final entry in detail.entries) {
      if (!describedFields.contains(entry.key) &&
          _hasConditionValue(entry.value)) {
        parts.add('${entry.key}: ${entry.value}');
      }
    }

    if (parts.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{'en': parts.join('. ')};
  }

  List<PokemonEvolutionEntry> _sortEvolutions(
    List<PokemonEvolutionEntry> entries,
  ) {
    final sorted = List<PokemonEvolutionEntry>.from(entries);
    sorted.sort((left, right) {
      final targetCompare = left.targetSpeciesId.compareTo(
        right.targetSpeciesId,
      );
      if (targetCompare != 0) return targetCompare;

      final methodCompare = left.method.compareTo(right.method);
      if (methodCompare != 0) return methodCompare;

      final levelCompare = (left.minLevel ?? -1).compareTo(
        right.minLevel ?? -1,
      );
      if (levelCompare != 0) return levelCompare;

      final itemCompare = (left.itemId ?? '').compareTo(right.itemId ?? '');
      if (itemCompare != 0) return itemCompare;

      final moveCompare = (left.requiredMoveId ?? '').compareTo(
        right.requiredMoveId ?? '',
      );
      if (moveCompare != 0) return moveCompare;

      return (left.conditionText['en'] ?? '').compareTo(
        right.conditionText['en'] ?? '',
      );
    });
    return sorted;
  }

  String _readNamedResourceId(Object? raw, {required String field}) {
    if (raw is! Map) {
      throw EditorPersistenceException(
        'PokeAPI field "$field" must be a named resource object',
      );
    }

    final name = (raw['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw EditorValidationException(
        'PokeAPI field "$field" must define a non-empty name',
      );
    }
    return name;
  }

  String _normalizeSpeciesId(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String? _readOptionalNamedResourceId(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI optional named resource field must be an object',
      );
    }

    final name = (raw['name'] as String?)?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  String? _readOptionalMoveId(Object? raw) {
    final name = _readOptionalNamedResourceId(raw);
    if (name == null || name.isEmpty) {
      return null;
    }
    final separated = name.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }
}

class _LocatedChainNode {
  const _LocatedChainNode({required this.node, required this.parentSpeciesId});

  final Map<String, dynamic> node;
  final String? parentSpeciesId;
}
