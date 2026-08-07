import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';

/// Everything [AveluneAppearanceNotifier] needs, resolved as one unit.
///
/// Same rationale as the dashboard bundle: both dependencies hang off the async
/// support root while the state is synchronous, and a test overriding one
/// provider replaces both.
final class AveluneAppearanceDependencies {
  const AveluneAppearanceDependencies({
    required this.store,
    required this.customBackground,
  });

  final AveluneAppearanceRepositoryInterface store;
  final AveluneCustomBackgroundGateway customBackground;
}
