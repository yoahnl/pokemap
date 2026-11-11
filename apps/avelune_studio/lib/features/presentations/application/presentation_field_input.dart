import 'package:map_core/map_core_domain.dart';

const presentationDocumentDurationField = 'documentDuration';
const presentationDefaultTransitionUs = 500000;

Object? parsePresentationFieldText(
  String text,
  String key, {
  required bool numeric,
  double factor = 1,
}) {
  if (!numeric) return text;
  final parsed = double.tryParse(text.replaceAll(',', '.'));
  if (parsed == null || !parsed.isFinite) return null;
  final scaled = parsed * factor;
  return key.endsWith('Us') ? scaled.round() : scaled;
}

Map<String, Object?> presentationFieldPatch(
  String key,
  Object? value, {
  Map<String, Object?>? group,
  String? groupKey,
}) => groupKey == null
    ? {key: value}
    : {
        groupKey: {...?group, key: value},
      };

bool commitPresentationField(
  Set<String> invalidFields,
  String fieldId,
  Object? value,
  bool Function(Object value) apply,
) {
  final valid = value != null && apply(value);
  if (valid) {
    invalidFields.remove(fieldId);
  } else {
    invalidFields.add(fieldId);
  }
  return valid;
}

bool presentationFieldsCommitted(Set<String>? invalidFields) =>
    invalidFields?.isEmpty ?? true;

int? parsePresentationDocumentDurationUs(String text) {
  final seconds = double.tryParse(text.replaceAll(',', '.'));
  if (seconds == null || !seconds.isFinite || seconds <= 0) return null;
  return (seconds * 1000000).round();
}

Map<String, Object?> presentationDurationUpdate(
  PresentationCinematicAsset asset,
  int durationUs,
) => {
  'title': asset.title,
  'description': asset.description,
  'durationUs': durationUs,
};

Map<String, Object?> presentationTransitionPatch(
  PresentationClip clip,
  String side,
  String kind,
) => {
  side: {
    'kind': kind,
    'durationUs': kind == 'none'
        ? 0
        : (clip.durationUs < presentationDefaultTransitionUs
              ? clip.durationUs
              : presentationDefaultTransitionUs),
  },
};

Map<String, Object?> presentationFontFamilyPatch(
  PresentationTextClip clip,
  String choice,
) => {
  'style': {
    ...Map<String, Object?>.from(encodePresentationClip(clip)['style']! as Map),
    'fontFamily': choice.isEmpty ? null : choice,
  },
};
