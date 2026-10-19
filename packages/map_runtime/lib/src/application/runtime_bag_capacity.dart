import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

String runtimeBagGrantFailureMessage(BagOperationFailure failure) =>
    switch (failure) {
      BagOperationFailure.pocketFull =>
        'Cette poche du sac est pleine. Libérez une place avant de réessayer.',
      BagOperationFailure.stackFull =>
        'La quantité maximale de cet objet dans le sac est atteinte.',
      BagOperationFailure.quantityOverflow =>
        'Le sac ne peut pas recevoir cette quantité d’objets.',
      BagOperationFailure.missingItemCatalog ||
      BagOperationFailure.unknownItem => 'La définition de cet objet ne permet pas de vérifier la place dans le sac.',
      BagOperationFailure.invalidItemId ||
      BagOperationFailure.invalidQuantity ||
      BagOperationFailure.itemMissing ||
      BagOperationFailure.insufficientQuantity ||
      BagOperationFailure.protectedKeyItem =>
        'Cet objet ne peut pas être ajouté au sac.',
    };

void ensureRuntimeBagCapacity({
  required GameState state,
  required ProjectBagCapacity capacity,
  required ItemCatalogSnapshot itemCatalog,
}) {
  final issues = validateBagCapacity(
    bag: state.bag,
    capacity: capacity,
    itemCatalog: itemCatalog.catalog,
  );
  if (issues.isEmpty) return;
  final invalidCatalog = issues.any(
    (issue) =>
        issue.code == 'bag.capacity.missingItemCatalog' ||
        issue.code == 'bag.capacity.invalidItemCatalog' ||
        issue.code == 'bag.capacity.unknownItem',
  );
  throw StateError(
    invalidCatalog
        ? 'Le catalogue des objets ne permet pas de vérifier le sac.'
        : 'Le sac dépasse les limites de capacité du projet.',
  );
}
