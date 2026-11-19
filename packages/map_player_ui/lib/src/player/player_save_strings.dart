import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';

final class PlayerSaveStrings {
  const PlayerSaveStrings._(this._strings);

  factory PlayerSaveStrings.of(BuildContext context) =>
      PlayerSaveStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get title => _strings.saveTitle;
  String get confirm => _strings.save;
  String get cancel => _strings.cancel;
  String get saving => _strings.saveSaving;
  String get success => _strings.saveSuccess;
  String get failure => _strings.saveFailure;
  String get retry => _strings.retry;
  String get back => _strings.back;
  String get exitTitle => _strings.saveExitTitle;
  String get stay => _strings.saveStay;
  String get discard => _strings.saveDiscard;
  String get saveAndExit => _strings.saveSaveAndExit;
  String get exiting => _strings.saveExiting;
  String get exitFailure => _strings.saveExitFailure;
  String get exitWarning => _strings.saveExitWarning;
  String get discardUnavailable => _strings.saveDiscardUnavailable;
  String get saveUnavailable => _strings.saveSaveUnavailable;
  String get saveAndExitUnavailable => _strings.saveSaveAndExitUnavailable;
  String get missingReceipt => _strings.saveMissingReceipt;
  String get unexpectedFailure => _strings.saveUnexpectedFailure;
  String player(String name) => _strings.savePlayer(name: name);
  String location(String name) => _strings.saveLocation(name: name);
  String playtime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
    return _strings.savePlaytime(minutes: minutes, hours: hours);
  }

  String lastSave(String date, String time) =>
      _strings.saveLastSave(date: date, time: time);

  String target(RuntimePlayerSaveAddress address) =>
      _strings.saveTarget(profile: address.profileId, slot: address.slotId);

  String saved(RuntimePlayerSaveReceipt receipt) => _strings.saveSaved(
    profile: receipt.address.profileId,
    slot: receipt.address.slotId,
  );
}
