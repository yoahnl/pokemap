import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/player_catalog.dart';
import '../../l10n/player_catalog_en.dart';
import '../../l10n/player_catalog_fr.dart';

abstract interface class PokeMapPlayerLocalizations implements PlayerCatalog {
  Locale get locale;

  static const supportedLocales = PlayerCatalog.supportedLocales;

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _PokeMapPlayerLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static final _english = _EnglishPlayerLocalizations();
  static final _french = _FrenchPlayerLocalizations();

  static PokeMapPlayerLocalizations of(BuildContext context) =>
      Localizations.of<PokeMapPlayerLocalizations>(
        context,
        PokeMapPlayerLocalizations,
      ) ??
      _english;

  static PokeMapPlayerLocalizations lookup(Locale locale) =>
      locale.languageCode == 'fr' ? _french : _english;

  String estimatedTimeRemaining(String duration);
  String shortSeconds(int seconds);
  String shortMinutes(int minutes);
  String battleMoveType(String typeId);
  String? battleMoveCategory(String? metadata);
  String shopStock(int quantity);
  String shopOwned(int quantity);
  String shopTotal(int amount);
  String installedGameCount(int count);
  String diagnosticsToReview(int count);
  String levelLabel(int level);
  String hpLabel(int current, int maximum);
  String hpFraction(int current, int maximum);
  String experienceProgressLabel(int percent);
  String postBattleProgress(int current, int total);
  String confirmOverwriteUnusable(String reason);
  String? saveUnavailableReason(String code);
}

mixin _PlayerLocalizationHelpers on PlayerCatalog
    implements PokeMapPlayerLocalizations {
  @override
  Locale get locale => Locale(localeName);

  @override
  String estimatedTimeRemaining(String duration) =>
      estimatedTimeRemainingMessage(duration: duration);

  @override
  String shortSeconds(int seconds) => shortSecondsMessage(seconds: seconds);

  @override
  String shortMinutes(int minutes) => shortMinutesMessage(minutes: minutes);

  @override
  String battleMoveType(String typeId) {
    final normalized = typeId.trim().toLowerCase();
    return battleMoveTypeMessage(
      type: normalized,
      fallback: normalized.toUpperCase(),
    );
  }

  @override
  String? battleMoveCategory(String? metadata) {
    final normalized = metadata?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.contains('special') || normalized.contains('spécial')) {
      return battleMoveCategorySpecial;
    }
    if (normalized.contains('physical') || normalized.contains('physique')) {
      return battleMoveCategoryPhysical;
    }
    if (normalized.contains('status') || normalized.contains('statut')) {
      return battleMoveCategoryStatus;
    }
    return null;
  }

  @override
  String shopStock(int quantity) => shopStockMessage(quantity: quantity);

  @override
  String shopOwned(int quantity) => shopOwnedMessage(quantity: quantity);

  @override
  String shopTotal(int amount) => shopTotalMessage(amount: amount);

  @override
  String installedGameCount(int count) =>
      installedGameCountMessage(count: count);

  @override
  String diagnosticsToReview(int count) =>
      diagnosticsToReviewMessage(count: count);

  @override
  String levelLabel(int level) => levelLabelMessage(level: level);

  @override
  String hpLabel(int current, int maximum) =>
      hpLabelMessage(current: current, maximum: maximum);

  @override
  String hpFraction(int current, int maximum) =>
      hpFractionMessage(current: current, maximum: maximum);

  @override
  String experienceProgressLabel(int percent) =>
      experienceProgressMessage(percent: percent);

  @override
  String postBattleProgress(int current, int total) =>
      postBattleProgressMessage(current: current, total: total);

  @override
  String confirmOverwriteUnusable(String reason) =>
      confirmOverwriteUnusableMessage(reason: reason);

  @override
  String? saveUnavailableReason(String code) => switch (code) {
    'postGameContinuationRefused' => saveUnavailablePostGameContinuationRefused,
    'migrationRequired' => saveUnavailableMigrationRequired,
    'incompatibleVersion' => saveUnavailableIncompatibleVersion,
    'corrupt' => saveUnavailableCorrupt,
    'missing' => saveUnavailableMissing,
    'temporarilyUnavailable' => saveUnavailableTemporarilyUnavailable,
    _ => null,
  };
}

final class _EnglishPlayerLocalizations extends PlayerCatalogEn
    with _PlayerLocalizationHelpers {}

final class _FrenchPlayerLocalizations extends PlayerCatalogFr
    with _PlayerLocalizationHelpers {}

extension PokeMapPlayerLocalizationContext on BuildContext {
  PokeMapPlayerLocalizations get playerL10n =>
      PokeMapPlayerLocalizations.of(this);
}

final class _PokeMapPlayerLocalizationsDelegate
    extends LocalizationsDelegate<PokeMapPlayerLocalizations> {
  const _PokeMapPlayerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => PlayerCatalog.delegate.isSupported(locale);

  @override
  Future<PokeMapPlayerLocalizations> load(Locale locale) =>
      SynchronousFuture(PokeMapPlayerLocalizations.lookup(locale));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<PokeMapPlayerLocalizations> old,
  ) => false;
}
