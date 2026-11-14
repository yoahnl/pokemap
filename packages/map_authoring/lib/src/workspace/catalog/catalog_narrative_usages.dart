import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'catalog_derivable_indexes.dart';
import 'catalog_narrative_owner_analysis.dart';
import 'catalog_narrative_usage_index.dart';

export 'catalog_narrative_usage_index.dart'
    show
        CatalogNarrativeUsageRead,
        CatalogNarrativeUsageEntries,
        CatalogNarrativeUsagesPreparationRequired;

abstract final class CatalogNarrativeUsages {
  static const preparationScope = 'narrativeUsages';

  static const factUsers =
      CatalogNarrativeUsageIndex('narrativeFactUsers', 64, 2, _factFacets);

  static const mapElementOwners = CatalogNarrativeUsageIndex(
      'narrativeMapElementOwners', 128, 1, _mapElementFacets);

  static const indexes = [factUsers, mapElementOwners];

  static const coverage = {
    'owners': ['scene', 'worldRule', 'storyline', 'cinematic', 'event'],
    'analysis': 'mapCoreNarrativeDependencyIndexPerDocument',
    'factRole':
        'write for Scene consequence Fact targets and Scene input-to-Fact commands; cite for storyline scene-link outcome effects, which neither map_runtime nor map_story executes; read otherwise',
    'notCovered': [
      'maps',
      'mapAppearanceVariants',
      'decorationVisibilityConditions',
      'dialogueTextFacts',
      'dialogueDefinitions',
      'presentationCinematics',
      'legacyFlagAliasesUnderAliasId',
      'legacyEventClaims',
      'legacyScenarios',
      'projectSettings',
    ],
  };

  static String mapElementFacet(String mapId, String elementId) =>
      jsonEncode([mapId, elementId]);

  static Future<CatalogNarrativeUsageRead> readFactUsers(
          CatalogSnapshot snapshot, String factId) =>
      factUsers.read(snapshot, factId);

  static Future<CatalogNarrativeUsageRead> readMapElementOwners(
          CatalogSnapshot snapshot, String mapId, String elementId) =>
      mapElementOwners.read(snapshot, mapElementFacet(mapId, elementId));

  static Future<CatalogDerivedPatch> prepare(CatalogSnapshot snapshot) async {
    final result = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    for (final index in indexes) {
      result.upserts.addAll((await index.prepare(snapshot)).upserts);
    }
    return result;
  }

  static Iterable<(String, Map<String, Object?>)> _factFacets(
          CatalogNarrativeOwnerReferences references, int version) =>
      [
        for (final fact in references.facts)
          (
            fact.factId,
            {
              'kind': references.owner.kind,
              'id': references.owner.id,
              'role': version < 2 && fact.role == 'cite' ? 'write' : fact.role
            }
          ),
      ];

  static Iterable<(String, Map<String, Object?>)> _mapElementFacets(
          CatalogNarrativeOwnerReferences references, int version) =>
      [
        for (final element in references.mapElements)
          (
            mapElementFacet(element.mapId, element.elementId),
            {
              'kind': references.owner.kind,
              'id': references.owner.id,
              'sourceKind': element.sourceKind
            }
          ),
      ];
}
