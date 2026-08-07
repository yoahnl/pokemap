/// Total fixe vers lequel les poids d'une règle Smart Tile sont normalisés.
///
/// Une part se lit donc en pour mille : 10 vaut 1 %. Cette résolution suffit
/// pour régler une densité à l'œil et garde chaque poids dans la bande que le
/// reste de l'éditeur accepte déjà.
const int kSmartTileVariantWeightTotal = 1000;

/// Ramène [weights] à [kSmartTileVariantWeightTotal] sans changer les parts.
///
/// Les entrées nulles restent nulles. Le reliquat d'arrondi va aux plus forts
/// restes, puis toute entrée non nulle tombée à zéro est remontée à 1 aux
/// dépens de la plus grosse.
Map<String, int> normaliseSmartTileVariantWeights(Map<String, int> weights) {
  return _distribute(weights, budget: kSmartTileVariantWeightTotal);
}

/// Pose [targetPermille] sur [targetId] et repartage le reste entre les autres
/// en conservant leurs rapports.
///
/// La cible réellement posée peut être plus basse que demandé : chaque autre
/// variante encore positive garde au moins 1 pour mille, sinon « rare »
/// deviendrait « jamais » par simple arrondi. Et quand [targetId] est la seule
/// variante positive, elle reste à [kSmartTileVariantWeightTotal] — il n'y a
/// rien pour compenser une baisse. L'appelant lit la table retournée, jamais
/// la valeur demandée.
Map<String, int> rescaleSmartTileVariantWeights({
  required Map<String, int> weights,
  required String targetId,
  required int targetPermille,
}) {
  if (targetPermille < 0 || targetPermille > kSmartTileVariantWeightTotal) {
    throw ArgumentError.value(
      targetPermille,
      'targetPermille',
      'La part visée doit tenir dans [0, $kSmartTileVariantWeightTotal].',
    );
  }
  if (!weights.containsKey(targetId)) {
    throw ArgumentError.value(targetId, 'targetId', 'Candidat inconnu.');
  }

  final others = <String, int>{
    for (final entry in weights.entries)
      if (entry.key != targetId) entry.key: entry.value,
  };
  final positiveOtherCount =
      others.values.where((value) => value > 0).length;
  final int effectivePermille;
  if (positiveOtherCount == 0) {
    effectivePermille = kSmartTileVariantWeightTotal;
  } else {
    final ceiling = kSmartTileVariantWeightTotal - positiveOtherCount;
    effectivePermille = targetPermille > ceiling
        ? (ceiling < 0 ? 0 : ceiling)
        : targetPermille;
  }
  final distributed = _distribute(
    others,
    budget: kSmartTileVariantWeightTotal - effectivePermille,
  );
  return <String, int>{
    for (final key in weights.keys)
      key: key == targetId ? effectivePermille : distributed[key]!,
  };
}

/// Répartit [budget] entre [weights] proportionnellement, au plus fort reste.
Map<String, int> _distribute(Map<String, int> weights, {required int budget}) {
  final result = <String, int>{for (final key in weights.keys) key: 0};
  if (budget <= 0) return result;

  final positive = <String, int>{
    for (final entry in weights.entries)
      if (entry.value > 0) entry.key: entry.value,
  };
  if (positive.isEmpty) return result;

  final total = positive.values.reduce((a, b) => a + b);
  final remainders = <MapEntry<String, double>>[];
  var assigned = 0;
  for (final entry in positive.entries) {
    final exact = entry.value * budget / total;
    final floor = exact.floor();
    result[entry.key] = floor;
    assigned += floor;
    remainders.add(MapEntry<String, double>(entry.key, exact - floor));
  }

  remainders.sort((a, b) {
    final byRemainder = b.value.compareTo(a.value);
    return byRemainder != 0 ? byRemainder : a.key.compareTo(b.key);
  });
  for (var index = 0; assigned < budget; index += 1, assigned += 1) {
    final key = remainders[index % remainders.length].key;
    result[key] = result[key]! + 1;
  }

  _floorPositiveEntries(result, positive.keys);
  return result;
}

/// Remonte à 1 toute entrée voulue non nulle tombée à zéro, en prenant sur la
/// plus grosse. Sans ça, « rare » deviendrait « jamais » par simple arrondi.
void _floorPositiveEntries(Map<String, int> result, Iterable<String> intended) {
  for (final key in intended) {
    if (result[key]! > 0) continue;
    final donor = result.entries
        .where((entry) => entry.value > 1)
        .fold<MapEntry<String, int>?>(
          null,
          (best, entry) =>
              best == null || entry.value > best.value ? entry : best,
        );
    if (donor == null) return;
    result[donor.key] = donor.value - 1;
    result[key] = 1;
  }
}
