import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Identité canonique d'une écriture Smart Tile déclenchée par un geste.
///
/// Le journal d'idempotence vit sur le disque du projet et survit à l'app. Une
/// identité construite sur un compteur en mémoire repart donc à zéro à chaque
/// démarrage : le premier geste d'une session rejoue la clé du premier geste
/// de la session précédente, avec une autre charge, et le journal la refuse
/// (`idempotency.payload_conflict`). [sessionToken] casse cette répétition
/// sans rien coûter au chemin chaud — aucune lecture de révision, aucun aller
/// au disque.
///
/// À l'intérieur d'une session, la clé reste stable pour un même geste : deux
/// tentatives identiques se rejouent, deux gestes distincts ne se confondent
/// pas.
String smartTileMutationIdentity({
  required String purpose,
  required String sessionToken,
  required Map<String, Object?> values,
}) {
  final digest = sha256
      .convert(utf8.encode('$purpose|$sessionToken|${jsonEncode(values)}'))
      .toString();
  return '$purpose-${digest.substring(0, 24)}';
}

/// Jeton d'une session d'édition, tiré une fois au démarrage.
///
/// L'horloge seule ne suffit pas : deux fenêtres ouvertes dans la même
/// microseconde partageraient leur jeton.
String newSmartTileMutationSessionToken() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final salt = math.Random().nextInt(1 << 32);
  return '${now.toRadixString(36)}-${salt.toRadixString(36)}';
}
