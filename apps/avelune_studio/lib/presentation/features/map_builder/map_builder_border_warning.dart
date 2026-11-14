import 'package:avelune_studio/l10n/app_localizations.dart';

String? mapBuilderBorderWarning(AppLocalizations l10n, Set<String> codes) {
  if (codes.isEmpty) return null;
  if (codes.contains('border.spatial.face_base_mismatch')) {
    return l10n.mapBorderWarningBuried;
  }
  if (codes.contains('border.spatial.face_crown_mismatch')) {
    return l10n.mapBorderWarningCrown;
  }
  return l10n.mapBorderWarningOther;
}
