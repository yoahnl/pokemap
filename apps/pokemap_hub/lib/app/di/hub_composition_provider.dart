import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';

/// Bridges the widget tree to the composition root.
///
/// Ordering note: [HubComposition] still owns the ChangeNotifier controllers,
/// so it cannot be deleted until lots 20-21 turn them into Notifiers. What
/// changes here is where its inputs come from — the support root and the
/// platform adapter are resolved from providers, so a test overriding
/// [supportRootProvider] relocates the entire app.
final hubCompositionProvider = FutureProvider<HubAppComposition>((ref) async {
  final composition = await HubComposition.create(
    dashboardNotifier: ref.watch(hubDashboardNotifierProvider.notifier),
    appearanceNotifier: ref.watch(aveluneAppearanceNotifierProvider.notifier),
    platformAdapter: ref.watch(hubPlatformAdapterProvider),
    supportRoot: await ref.watch(supportRootProvider.future),
  );
  ref.onDispose(composition.dispose);
  return composition;
});
