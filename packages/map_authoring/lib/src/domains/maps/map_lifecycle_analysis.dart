import '../../contracts/json_contract_support.dart';

final class MapLifecycleAnalysis {
  MapLifecycleAnalysis({
    required this.canApply,
    this.noChange = false,
    this.errorCode,
    this.message,
    Map<String, Object?> preview = const {},
    Map<String, Object?> referenceImpact = const {},
    Map<String, Object?> details = const {},
  })  : preview = freezeContractJsonObject(preview, field: 'preview'),
        referenceImpact =
            freezeContractJsonObject(referenceImpact, field: 'referenceImpact'),
        details = freezeContractJsonObject(details, field: 'details');

  final bool canApply;
  final bool noChange;
  final String? errorCode;
  final String? message;
  final Map<String, Object?> preview;
  final Map<String, Object?> referenceImpact;
  final Map<String, Object?> details;
}
