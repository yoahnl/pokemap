import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

final class PlayerSaveStrings {
  const PlayerSaveStrings._(this._languageCode);

  factory PlayerSaveStrings.of(BuildContext context) =>
      PlayerSaveStrings._(Localizations.localeOf(context).languageCode);

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get title => _isFrench ? 'Sauvegarder la partie ?' : 'Save game?';
  String get confirm => _isFrench ? 'Sauvegarder' : 'Save';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';

  String target(RuntimePlayerSaveAddress address) => _isFrench
      ? 'Profil « ${address.profileId} », slot « ${address.slotId} ».'
      : 'Profile “${address.profileId}”, slot “${address.slotId}”.';

  String saved(RuntimePlayerSaveReceipt receipt) => _isFrench
      ? 'Partie sauvegardée — profil « ${receipt.address.profileId} », '
          'slot « ${receipt.address.slotId} ».'
      : 'Game saved — profile “${receipt.address.profileId}”, '
          'slot “${receipt.address.slotId}”.';
}
