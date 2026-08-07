import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/app/di/appearance_dependencies_provider.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// An appearance notifier wired to test doubles, plus the container owning it.
///
/// Mirrors [DashboardHarness]: overriding
/// [aveluneAppearanceDependenciesProvider] swaps both dependencies at once, so
/// no test needs to know about the repository providers underneath.
final class AppearanceHarness {
  AppearanceHarness._(this.container, this.notifier);

  final ProviderContainer container;
  final AveluneAppearanceNotifier notifier;

  AveluneAppearanceState get state =>
      container.read(aveluneAppearanceNotifierProvider);

  /// Wraps a widget so it resolves providers from **this** container.
  Widget wrap(Widget child) => UncontrolledProviderScope(
        container: container,
        child: child,
      );

  /// Records every status the notifier publishes, in order.
  List<AveluneAppearanceControllerStatus> observeStatuses() {
    final observed = <AveluneAppearanceControllerStatus>[];
    container.listen<AveluneAppearanceState>(
      aveluneAppearanceNotifierProvider,
      (_, next) => observed.add(next.status),
    );
    return observed;
  }

  void dispose() => container.dispose();
}

AppearanceHarness buildAppearanceHarness({
  required AveluneAppearanceRepositoryInterface store,
  required AveluneCustomBackgroundGateway customBackground,
}) {
  final container = ProviderContainer(
    overrides: [
      aveluneAppearanceDependenciesProvider.overrideWith(
        (ref) async => AveluneAppearanceDependencies(
          store: store,
          customBackground: customBackground,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return AppearanceHarness._(
    container,
    container.read(aveluneAppearanceNotifierProvider.notifier),
  );
}
