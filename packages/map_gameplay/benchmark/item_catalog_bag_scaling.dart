import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print(
      'Usage: dart run benchmark/item_catalog_bag_scaling.dart '
      '[--definitions=5000] [--stacks=500] [--warmup=20] '
      '[--iterations=100]',
    );
    return;
  }
  final definitions = _positiveOption(args, 'definitions', 5000);
  final stacks = _positiveOption(args, 'stacks', 500);
  final warmup = _nonNegativeOption(args, 'warmup', 20);
  final iterations = _positiveOption(args, 'iterations', 100);
  if (definitions < 3) {
    throw const FormatException('--definitions must be at least 3');
  }
  if (stacks < 2 || stacks > definitions) {
    throw const FormatException(
      '--stacks must be between 2 and --definitions',
    );
  }

  final fixture = _fixture(definitions: definitions, stacks: stacks);
  for (var index = 0; index < warmup; index++) {
    _runIteration(fixture);
  }

  final samples = <int>[];
  var checksum = 0;
  for (var index = 0; index < iterations; index++) {
    final stopwatch = Stopwatch()..start();
    checksum += _runIteration(fixture);
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  final p95 = samples[((samples.length - 1) * 0.95).ceil()];
  print(
    'definitions=$definitions stacks=$stacks warmup=$warmup '
    'iterations=$iterations median_us=$median p95_us=$p95 '
    'catalog_lookups=4 capability_resolutions=4 bag_operations=4 '
    'checksum=$checksum',
  );
}

int _runIteration(_Fixture fixture) {
  final snapshot = ItemCatalogSnapshot.fromCatalog(fixture.catalog);
  final resolver = ItemCapabilityResolver(snapshot);
  final firstId = _itemId(0);
  final middleId = _itemId(fixture.catalog.entries.length ~/ 2);
  final lastId = _itemId(fixture.catalog.entries.length - 1);

  final first = snapshot.definitionFor(firstId);
  final middle = snapshot.definitionFor(middleId);
  final last = snapshot.definitionFor(lastId);
  final missing = snapshot.definitionFor('missing');
  if (first?.id != firstId ||
      middle?.id != middleId ||
      last?.id != lastId ||
      missing != null) {
    throw StateError('Catalog lookup workload returned invalid results');
  }

  final resolutions = <ItemUseCapabilityResolution>[
    resolver.resolveUse(
      itemId: firstId,
      context: ProjectItemUseContext.overworld,
    ),
    resolver.resolveUse(
      itemId: middleId,
      context: ProjectItemUseContext.overworld,
    ),
    resolver.resolveUse(
      itemId: lastId,
      context: ProjectItemUseContext.overworld,
    ),
    resolver.resolveUse(
      itemId: 'missing',
      context: ProjectItemUseContext.overworld,
    ),
  ];
  if (resolutions.take(3).any((resolution) => !resolution.isAvailable) ||
      resolutions.last.failure != ItemUseCapabilityFailure.unknownDefinition) {
    throw StateError('Capability resolution workload returned invalid results');
  }

  const operations = BagOperations();
  final given = operations.give(
    BagGiveRequest(
      bag: fixture.bag,
      itemId: _itemId(fixture.bag.entries.length - 1),
      quantity: 1,
    ),
  );
  final taken = operations.take(
    BagTakeRequest(
      bag: given.bag,
      itemId: _itemId(fixture.bag.entries.length ~/ 2),
      quantity: 1,
    ),
  );
  final consumed = operations.consume(
    BagConsumeRequest(
      bag: taken.bag,
      itemId: firstId,
      quantity: 1,
      reason: ItemConsumptionReason.appliedEffect,
    ),
  );
  final refused = operations.consume(
    BagConsumeRequest(
      bag: consumed.bag,
      itemId: _itemId(1),
      quantity: 4,
      reason: ItemConsumptionReason.appliedEffect,
    ),
  );
  if (!given.isSuccess ||
      given.quantityBefore != 3 ||
      given.quantityAfter != 4 ||
      !taken.isSuccess ||
      taken.quantityBefore != 3 ||
      taken.quantityAfter != 2 ||
      !consumed.isSuccess ||
      consumed.consumptionReceipt !=
          ItemConsumptionReceipt(
            itemId: firstId,
            quantity: 1,
            quantityBefore: 3,
            quantityAfter: 2,
            reason: ItemConsumptionReason.appliedEffect,
          ) ||
      refused.failure != BagOperationFailure.insufficientQuantity ||
      !identical(refused.bag, consumed.bag) ||
      refused.consumptionReceipt != null) {
    throw StateError('Bag operation workload returned invalid results');
  }

  return first!.id.length +
      middle!.id.length +
      last!.id.length +
      given.quantityAfter +
      taken.quantityAfter +
      consumed.quantityAfter;
}

_Fixture _fixture({required int definitions, required int stacks}) {
  const use = ProjectItemUseDefinition(
    contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
    target: ProjectItemTargetKind.partyMember,
    consumption: ProjectItemConsumptionPolicy.onApplied,
    effect: ProjectItemEffectDefinition.healHp(
      mode: ProjectItemAmountMode.flat,
      amount: 20,
    ),
  );
  return _Fixture(
    catalog: ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        for (var index = 0; index < definitions; index++)
          ProjectItemDefinition(
            id: _itemId(index),
            displayName: 'Synthetic Item $index',
            pocketId: 'items',
            uses: const <ProjectItemUseDefinition>[use],
          ),
      ],
    ),
    bag: Bag(
      entries: <BagEntry>[
        for (var index = 0; index < stacks; index++)
          BagEntry(itemId: _itemId(index), quantity: 3),
      ],
    ),
  );
}

String _itemId(int index) => 'item_${index.toString().padLeft(5, '0')}';

int _positiveOption(List<String> args, String name, int fallback) {
  final value = _integerOption(args, name, fallback);
  if (value <= 0) {
    throw FormatException('--$name must be positive');
  }
  return value;
}

int _nonNegativeOption(List<String> args, String name, int fallback) {
  final value = _integerOption(args, name, fallback);
  if (value < 0) {
    throw FormatException('--$name must be non-negative');
  }
  return value;
}

int _integerOption(List<String> args, String name, int fallback) {
  final prefix = '--$name=';
  final raw = args.where((arg) => arg.startsWith(prefix));
  if (raw.isEmpty) return fallback;
  final parsed = int.tryParse(raw.last.substring(prefix.length));
  if (parsed == null) {
    throw FormatException('--$name must be an integer');
  }
  return parsed;
}

final class _Fixture {
  const _Fixture({required this.catalog, required this.bag});

  final ProjectItemCatalog catalog;
  final Bag bag;
}
