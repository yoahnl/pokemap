import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

Future<({SourceInterpretationProfile profile, Map<String, Object?> evidence})>
    deriveLot6RoutedDoorPatterns({
  required SourceSnapshot snapshot,
  required SourceFilePort files,
  required SourceInterpretationProfile profile,
  ScanCancellation? cancellation,
}) =>
        deriveSourceRoutedDoorPatterns(
          snapshot: snapshot,
          files: files,
          profile: profile,
          cancellation: cancellation,
        );
