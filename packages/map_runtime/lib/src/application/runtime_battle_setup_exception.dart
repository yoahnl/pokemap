/// Exception levée quand le runtime ne peut pas construire un setup battle
/// honnête à partir des vraies données projet/save.
///
/// M5 l'extrait du mapper pour partager le même contrat d'erreur entre :
/// - le seam runtime spécialisé du catalogue moves ;
/// - le mapper runtime -> battle ;
/// - les call sites Flame qui doivent afficher une erreur métier claire.
///
/// Cela évite un cycle sale où le loader dépendrait du mapper uniquement pour
/// récupérer ce type d'erreur.
class RuntimeBattleSetupException implements Exception {
  const RuntimeBattleSetupException(
    this.message, {
    this.debugDetails,
  });

  final String message;
  final String? debugDetails;

  @override
  String toString() {
    final details = debugDetails?.trim();
    if (details == null || details.isEmpty) {
      return message;
    }
    return '$message ($details)';
  }
}
