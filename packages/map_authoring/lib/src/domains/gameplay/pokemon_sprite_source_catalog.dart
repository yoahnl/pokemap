import 'package:map_core/map_core.dart';

final class PokemonSpriteSourceIdentity {
  const PokemonSpriteSourceIdentity({
    required this.id,
    required this.nationalDex,
    required this.formNumber,
    required this.formName,
  });

  final String id;
  final int nationalDex;
  final int formNumber;
  final String formName;

  Map<String, Object?> toJson() => {
        'sourceId': id,
        'nationalDex': nationalDex,
        'formNumber': formNumber,
        'formName': formName,
      };
}

final class PokemonSpriteSourceMatch {
  const PokemonSpriteSourceMatch({
    required this.identity,
    required this.reason,
  });

  final PokemonSpriteSourceIdentity identity;
  final String reason;
}

final class PokemonSpriteSourceCatalog {
  PokemonSpriteSourceCatalog.fromJson(Map<String, dynamic> source) {
    final parsed = <PokemonSpriteSourceIdentity>[];
    for (final entry in source.entries) {
      final value = entry.value;
      if (value is! Map || value['num'] is! int) {
        throw const FormatException('Invalid sprite source identity.');
      }
      final nationalDex = value['num'] as int;
      if (nationalDex <= 0) continue;
      final form = value['formeNum'];
      if (form is! int ||
          form < 0 ||
          form >= 32 ||
          value['forme'] is! String ||
          entry.key != 's${nationalDex * 32 + form}' ||
          value['sid'] != entry.key) {
        throw const FormatException('Inconsistent sprite source identity.');
      }
      parsed.add(PokemonSpriteSourceIdentity(
        id: entry.key,
        nationalDex: nationalDex,
        formNumber: form,
        formName: value['forme'] as String,
      ));
    }
    parsed.sort((a, b) {
      final dex = a.nationalDex.compareTo(b.nationalDex);
      return dex == 0 ? a.formNumber.compareTo(b.formNumber) : dex;
    });
    identities = List.unmodifiable(parsed);
    _byId = {for (final entry in identities) entry.id: entry};
  }

  late final List<PokemonSpriteSourceIdentity> identities;
  late final Map<String, PokemonSpriteSourceIdentity> _byId;

  PokemonSpriteSourceMatch? match({
    required int nationalDex,
    required String formId,
    required String baseFormId,
  }) {
    final isBase = formId == baseFormId;
    final explicit = switch ((nationalDex, isBase, formId)) {
      (666, _, 'icysnow') => 's21312',
      (666, _, 'highplains') => 's21322',
      (676, _, 'lareine') => 's21639',
      (741, _, 'pau') => 's23714',
      (718, _, '10') || (718, _, '10-percent') => 's22977',
      (774, _, 'meteor') => 's24768',
      _ => null,
    };
    if (explicit != null) {
      final identity = _byId[explicit];
      return identity == null
          ? null
          : PokemonSpriteSourceMatch(
              identity: identity, reason: 'explicit-form-mapping');
    }
    final namedMatches = identities.where((entry) =>
        entry.nationalDex == nationalDex &&
        entry.formName.isNotEmpty &&
        _formKey(entry.formName) == _formKey(formId));
    if (namedMatches.isNotEmpty) {
      return namedMatches.length == 1
          ? PokemonSpriteSourceMatch(
              identity: namedMatches.single, reason: 'exact-national-form-key')
          : null;
    }
    if (nationalDex == 718 && isBase) {
      final identity = _byId['s22976'];
      return identity == null
          ? null
          : PokemonSpriteSourceMatch(
              identity: identity, reason: 'explicit-form-mapping');
    }
    final matches = identities.where((entry) =>
        entry.nationalDex == nationalDex &&
        (isBase
            ? entry.formName.isEmpty
            : _formKey(entry.formName) == _formKey(formId)));
    if (matches.length != 1) return null;
    return PokemonSpriteSourceMatch(
      identity: matches.single,
      reason: isBase ? 'source-semantic-default' : 'exact-national-form-key',
    );
  }

  List<Map<String, Object?>> qualify({
    required Iterable<PokemonSpeciesFile> species,
    required Map<String, PokemonMediaFile> media,
  }) {
    final result = <Map<String, Object?>>[];
    final ordered = species.toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final entry in ordered) {
      final document = media[entry.id];
      final defaultForm = document?.defaultFormId ?? entry.forms.formId;
      final forms = <String>{
        defaultForm,
        entry.forms.formId,
        ...?document?.variants.keys,
        ...entry.forms.otherForms,
      }.toList()
        ..sort();
      for (final form in forms) {
        final match = this.match(
          nationalDex: entry.nationalDex,
          formId: form,
          baseFormId: entry.forms.formId,
        );
        result.add({
          'speciesId': entry.id,
          'nationalDex': entry.nationalDex,
          'formId': form,
          'defaultFormId': defaultForm,
          'isDefault': form == defaultForm,
          'sourceId': match?.identity.id,
          'decision': match == null ? 'unsupported' : 'matched',
          'reason': match?.reason ?? 'no-unique-explicit-source',
        });
      }
    }
    return List.unmodifiable(result);
  }

  static String homeMediaIdentity(String sourceId) => switch (sourceId) {
        's22978' => 's22977',
        's24769' ||
        's24770' ||
        's24771' ||
        's24772' ||
        's24773' ||
        's24774' =>
          's24768',
        _ => sourceId,
      };
}

String _formKey(String value) => value.toLowerCase().replaceAll(' ', '-');
