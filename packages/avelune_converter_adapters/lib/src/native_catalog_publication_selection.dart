import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_psdk_trainer_bundle.dart';

final class NativeCatalogPublicationSelection {
  NativeCatalogPublicationSelection._(this.speciesIds, this.moveIds);

  factory NativeCatalogPublicationSelection.select(
      NativePsdkCatalog catalog, Iterable<String> roots) {
    final speciesIds = <String>{};
    final moveIds = <String>{...nativeQualifiedFieldMoveSourceHashes.keys};
    final queue = roots.toSet().toList()..sort();
    if (queue.length > 2048) _invalid('quota', r'$.species');
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final id = queue[cursor];
      if (!speciesIds.add(id)) continue;
      if (speciesIds.length > 2048) _invalid('quota', id);
      final species = catalog.speciesById[id];
      final learnset = catalog.learnsetsBySpeciesId[id];
      final evolution = catalog.evolutionsBySpeciesId[id];
      final media = catalog.mediaBySpeciesId[id];
      if (species == null ||
          learnset == null ||
          evolution == null ||
          media == null) {
        _invalid('species_missing', id);
      }
      queue.add(species.forms.baseFormId);
      for (final form in species.forms.otherForms) {
        final number = int.tryParse(form);
        if (number == null || number < 0) _invalid('form_identity', id);
        queue.add(nativePsdkFormSpeciesId(species.forms.baseFormId, number));
      }
      if (evolution.preEvolution case final ancestor?) queue.add(ancestor);
      for (final rule in evolution.evolutions) {
        queue.add(rule.targetSpeciesId);
        final partner = rule.tradeRequirements?.requiredPartnerSpeciesId;
        if (partner != null) queue.add(partner);
        if (rule.requiredMoveId case final move?) moveIds.add(move);
      }
      moveIds.addAll([
        ...learnset.startingMoves,
        ...learnset.relearnMoves,
        ...learnset.levelUp.map((entry) => entry.moveId),
        for (final group in [
          learnset.tm,
          learnset.hm,
          learnset.tutor,
          learnset.egg,
          learnset.event,
          learnset.transfer
        ])
          ...group.map((entry) => entry.moveId),
      ]);
    }
    if (moveIds.length > 4096) _invalid('quota', r'$.moves');
    for (final id in moveIds) {
      if (!catalog.movesById.containsKey(id)) _invalid('move_missing', id);
    }
    return NativeCatalogPublicationSelection._(
        Set.unmodifiable(speciesIds), Set.unmodifiable(moveIds));
  }

  final Set<String> speciesIds;
  final Set<String> moveIds;

  Map<String, Object?> toJson() => {
        'kind': 'nativeCatalogPublicationSelection',
        'version': 1,
        'speciesIds': speciesIds.toList()..sort(),
        'moveIds': moveIds.toList()..sort(),
        'selectionPolicy': 'nativeDependencyClosureFromProjectReferences',
      };
}

List<String> sourceDeclaredNativeSpecies(
    SourcePbsProject source, NativePsdkCatalog catalog) {
  final names = <String>{};
  for (final entry in source.entries) {
    if (entry.family != SourcePbsFamily.species || entry.identity?.form != 0) {
      continue;
    }
    final fields = entry.fieldsNamed('Name');
    if (fields.length == 1 && fields.single.values.length == 1) {
      names.add(_orthography(fields.single.values.single));
    }
  }
  return [
    for (final species in catalog.speciesById.values)
      if (species.forms.formId == '0' &&
          species.names['en'] != null &&
          names.contains(_orthography(species.names['en']!)))
        species.id,
  ]..sort();
}

List<String> nativeSpeciesReferences(Iterable<Object?> documents) {
  final ids = <String>{};
  var count = 0;
  void visit(Object? value, int depth) {
    if (++count > 4000000 || depth > 64) _invalid('quota', r'$.references');
    if (value is Map) {
      for (final entry in value.entries) {
        if (const {
              'speciesId',
              'targetSpeciesId',
              'requiredSpeciesId',
              'requiredPartnerSpeciesId'
            }.contains(entry.key) &&
            entry.value is String) {
          ids.add(entry.value as String);
          if (ids.length > 2048) _invalid('quota', r'$.references');
        }
        visit(entry.value, depth + 1);
      }
    } else if (value is List) {
      for (final entry in value) {
        visit(entry, depth + 1);
      }
    }
  }

  for (final document in documents) {
    visit(document, 0);
  }
  return ids.toList()..sort();
}

String _orthography(String value) => value.replaceAll('\u2019', "'");

Never _invalid(String code, String locator) => throw ContractError(
    'native_catalog.publication_$code',
    locator,
    'The requested project requires a complete bounded native Pokemon dependency closure.');
