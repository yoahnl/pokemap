import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'source_event_item_bindings.dart';

String sourceShopBindingKey(SourceShopProgramNode program) =>
    canonicalHashOf(program.toJson()).value;

final class SourceShopBinding {
  SourceShopBinding._(this.program, this.shop, this.items, this.eventIdentity,
      this.sourceHash, this.normalizationHash, this.profileHash);

  final SourceShopProgramNode program;
  final ShopDefinition shop;
  final Map<String, SourceEventItemBinding> items;
  final ConverterId eventIdentity;
  final Sha256Hash sourceHash, normalizationHash, profileHash;

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (source.snapshot.canonicalHash != sourceHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        event.identity != eventIdentity ||
        !_qualifiedShopOracles(source, analysis.profile)) {
      return false;
    }
    return sourceShopEventMatchesSource(
            source: source, analysis: analysis, event: event) &&
        sourceShopPrograms(event).any((entry) =>
            sourceShopBindingKey(entry) == sourceShopBindingKey(program));
  }

  Map<String, Object?> get evidence => {
        'kind': 'literalPokemonMartNativeBinding',
        'program': program.toJson(),
        'sourceSnapshotHash': sourceHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'shop': shop.toJson(),
        'items': [for (final item in items.values) item.toJson()],
        'sourceBonusPolicy': 'floorPurchasedBallQuantityDividedByTenBestEffort',
        'sourcePurchasePolicy': 'allOrNothingPrincipalWithOwnedQuantityLimit',
        'presentationAdaptation': 'nativeAveluneShopBuySellCancelLoop',
        'sourceUiPresentationParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

bool sourceShopEventMatchesSource(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash ||
      analysis.profile.canonicalHash !=
          SourceEventProfile.forProject(source).canonicalHash ||
      sourceShopPrograms(event).isEmpty) {
    return false;
  }
  final fresh =
      SourceEventAnalyzer.forProject(source, profile: analysis.profile)
          .analyzeEventAt(event.sourceMapId, event.sourceEventId);
  return fresh != null &&
      !fresh.isQuarantined &&
      _sourceShopEventShape(fresh) == _sourceShopEventShape(event);
}

Sha256Hash _sourceShopEventShape(SourceEventDefinition event) =>
    canonicalHashOf({
      'identity': event.identity.value,
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'fileId': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'diagnostics': page.diagnostics
                .map((diagnostic) => diagnostic.toJson())
                .toList(),
            'bodySpan': page.body.span.toJson(),
            'bodyDiagnostics': page.body.diagnostics
                .map((diagnostic) => diagnostic.toJson())
                .toList(),
            'graphic': page.graphic == null
                ? null
                : [
                    page.graphic!.tileId,
                    page.graphic!.characterName,
                    page.graphic!.hue,
                    page.graphic!.direction,
                    page.graphic!.pattern,
                    page.graphic!.opacity,
                    page.graphic!.blendType,
                    page.graphic!.moveType,
                    page.graphic!.moveSpeed,
                    page.graphic!.moveFrequency,
                    page.graphic!.walkAnime,
                    page.graphic!.stepAnime,
                    page.graphic!.directionFix,
                    page.graphic!.through,
                    page.graphic!.alwaysOnTop,
                    page.graphic!.moveRouteNodeId
                  ],
          }
      ],
      'shops':
          sourceShopPrograms(event).map((program) => program.toJson()).toList(),
    });

bool _qualifiedShopOracles(
    NormalizedSourceProject source, SourceEventProfile profile) {
  if (!profile.isQualified ||
      source.interpretationProfile == null ||
      canonicalHashOf(source.interpretationProfile!.toJson()) !=
          canonicalHashOf(profile.interpretationProfile!.toJson())) {
    return false;
  }
  const witnesses = {
    'events.PokeMart': (
      312,
      'UI_PokeMart',
      '484315201c01010b3978bcac6968834b2a60c7a8d6b348abd83b4c1a4c234b53'
    ),
    'events.Settings': (
      0,
      'Settings',
      'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f'
    ),
    'events.Item': (
      127,
      'Item',
      'b280015f15e892754c90728bdbf23a77c280ebb86413cb51c64793e0b997757a'
    ),
  };
  return witnesses.entries.every((entry) {
    final actual = profile.interpretationProfile!.sections[entry.key];
    return actual?['index'] == entry.value.$1 &&
        actual?['name'] == entry.value.$2 &&
        actual?['sha256'] == entry.value.$3;
  });
}

Map<String, SourceShopBinding> sourceShopBindings({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
  required Iterable<SourceEventDefinition> events,
  required Map<String, SourceEventItemBinding> itemBindings,
}) {
  if (!_qualifiedShopOracles(source, analysis.profile)) return const {};
  final result = <String, SourceShopBinding>{};
  for (final event in events.where((entry) => !entry.isQuarantined)) {
    for (final program in sourceShopPrograms(event)) {
      final items = <String, SourceEventItemBinding>{};
      var qualified =
          program.sourceSnapshotHash == source.snapshot.canonicalHash &&
              program.normalizationHash == source.canonicalHash &&
              program.profileHash == analysis.profile.canonicalHash;
      for (final symbol in program.sourceItemSymbols) {
        final item = itemBindings[symbol];
        if (!_qualifiedItem(item, source, analysis.profile) ||
            item!.definition.buyPrice == null ||
            item.definition.buyPrice! <= 0) {
          qualified = false;
          break;
        }
        items[symbol] = item;
      }
      final hasBonus = items.values.any(_isBall);
      final bonus = itemBindings['PREMIERBALL'];
      if (hasBonus) {
        if (!_qualifiedItem(bonus, source, analysis.profile)) {
          qualified = false;
        } else {
          items['PREMIERBALL'] = bonus!;
        }
      }
      if (!qualified) continue;
      final key = sourceShopBindingKey(program);
      final shop = ShopDefinition(
          id: 'source-shop-${key.substring(0, 24)}',
          label: 'Boutique',
          sellPolicy: ShopSellPolicy.catalogPrices,
          entries: [
            for (final symbol in program.sourceItemSymbols)
              ShopEntryDefinition(
                  itemId: items[symbol]!.definition.id,
                  price: items[symbol]!.definition.buyPrice!,
                  sellPrice: (items[symbol]!.definition.sellPrice ?? 0) > 0
                      ? items[symbol]!.definition.sellPrice
                      : null,
                  maximumOwnedQuantity: items[symbol]!.isImportant ? 1 : 999,
                  purchaseBonus: _isBall(items[symbol]!)
                      ? ShopPurchaseBonus(
                          itemId: bonus!.definition.id,
                          everyQuantity: 10,
                          quantity: 1,
                          maximumOwnedQuantity: 999)
                      : null)
          ]).normalized(
          knownItemIds: items.values.map((item) => item.definition.id).toSet());
      result[key] = SourceShopBinding._(
          program,
          shop,
          Map.unmodifiable(items),
          event.identity,
          source.snapshot.canonicalHash,
          source.canonicalHash,
          analysis.profile.canonicalHash);
    }
  }
  return Map.unmodifiable(result);
}

bool _isBall(SourceEventItemBinding item) => item.flags
    .any((flag) => const {'pokeball', 'snagball'}.contains(flag.toLowerCase()));

bool _qualifiedItem(SourceEventItemBinding? item,
        NormalizedSourceProject source, SourceEventProfile profile) =>
    item != null &&
    item.pickupQualified &&
    item.sourceSnapshotHash == source.snapshot.canonicalHash &&
    item.interpretationProfile != null &&
    canonicalHashOf(item.interpretationProfile!.toJson()) ==
        canonicalHashOf(profile.interpretationProfile!.toJson());

Iterable<SourceShopProgramNode> sourceShopPrograms(
    SourceEventDefinition event) sync* {
  for (final page in event.pages) {
    yield* _shops(page.body);
  }
}

Iterable<SourceShopProgramNode> _shops(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    switch (node) {
      case SourceShopProgramNode():
        yield node;
      case SourceConditionalNode():
        yield* _shops(node.whenTrue);
        yield* _shops(node.whenFalse);
      case SourceTextNode():
        if (node.followingChoice case final choice?) {
          for (final branch in choice.branches) {
            yield* _shops(branch.body);
          }
          if (choice.cancelBranch case final branch?) yield* _shops(branch);
        }
      case SourceChoiceNode():
        for (final branch in node.branches) {
          yield* _shops(branch.body);
        }
        if (node.cancelBranch case final branch?) yield* _shops(branch);
      default:
        break;
    }
  }
}
